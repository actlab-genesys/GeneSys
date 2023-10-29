////////////////////////////////////////////////////////////////////////////////

// Description:
// This is an AXI4 read master module example. The module demonstrates how to
// issue AXI read transactions to a memory mapped slave.  Given a starting
// address offset and a transfer size in bytes, it will issue one or more AXI
// transactions and return the data over an AXI4-Stream interface.
//
// Theory of operation:
// It uses a minimum subset of the AXI4 protocol by omitting AXI4 signals that
// are not used.  When packaged as a kernel or IP, this allows for
// optimizations to occur within the AXI Interconnect system to increase Fmax,
// potentially increase performance, and reduce latency/area. When
// C_INCLUDE_DATA_FIFO is set to 1, a data FIFO is included and configured so
// that all transactions that are issued can fit into the FIFO.  This allows
// for m_axi_rready to be tied high, and ensures that an unexpected stall
// internally does not cause the AXI Interconnect system to become
// inadvertantly deadlocked or cause head of line blocking to other AXI masters
// in the system.
//
// When ctrl_start is asserted, the ctrl_addr_offset (assumed 4kb aligned) and
// the transfer size in bytes is registered into the module.  the The bulk of the
// logic consists of counters to track how many transfers/transactions have been
// issued.  When the transfer size is reached, and all transactions are
// committed, then done is asserted.
//
// Usage:
// 1) assign ctrl_addr_offset to a 4kB aligned starting address.
// 2) assign ctrl_xfer_size_in_bytes to the size in bytes of the requested transfer.
//    This value will be rounded up to the nearest multiple of the interface width.
//    For example a request of 100 bytes will be rounded up to 128 bytes on a 64 byte
//    (512 bits) wide interface.
// 3) Assert ctrl_start for once cycle.  At the posedge, the ctrl_addr_offset and
//    ctrl_xfer_size_in_bytes will be registered in the module, and will start
//    issue read address transfers.  If the the transfer size is larger than 4096
//    bytes, multiple transactions will be issued.  There may be up to the
//    C_MAX_OUTSTANDING issued in succession.  Once the limit is hit
//    no more read address transfers on the AR channel will be issued until
//    R channel transactions have completed as indicated by the RLAST signal.
// 4) Read Data will appear on the AXI4-Stream interface (m_axis) as signalled by
//    an assertion of the m_axis_tvalid signal.
// 5) When the final R-channel transaction has completed, the module will assert
//    the ctrl_done signal for one cycle.  If a data FIFO is present, data may
//    still be present in the FIFO.
// 6) Jump to step 1.
////////////////////////////////////////////////////////////////////////////////

// default_nettype of none prevents implicit wire declaration.
`default_nettype none

module control_m_axi_read_master_fifo #(
  // Set to the address width of the interface
  parameter integer C_M_AXI_ADDR_WIDTH  = 64,

  // Set the data width of the interface
  // Range: 32, 64, 128, 256, 512, 1024
  parameter integer C_M_AXI_DATA_WIDTH  = 32,

  // Width of the ctrl_xfer_size_in_bytes input
  // Range: 16:C_M_AXI_ADDR_WIDTH
  parameter integer C_XFER_SIZE_WIDTH   = C_M_AXI_ADDR_WIDTH,

  // Specifies the maximum number of AXI4 transactions that may be outstanding.
  // Affects FIFO depth if data FIFO is enabled.
  parameter integer C_MAX_OUTSTANDING   = 16,

  // Includes a data fifo between the AXI4 read channel master and the AXI4-Stream
  // master.  It will be sized to hold C_MAX_OUTSTANDING transactions. If no
  // FIFO is instantiated then the AXI4 read channel is passed through to the
  // AXI4-Stream slave interface.
  // Range: 0, 1
  parameter integer C_INCLUDE_DATA_FIFO = 1,

  // the depth of AXI request FIFO 
  parameter AXI_REQ_FIFO_ADDR_WIDTH = 4
)
(
  // System signals
  input  wire                          aclk,
  input  wire                          areset,

  // Control signals
  input  wire                          ctrl_start,              // Pulse high for one cycle to begin reading
  output wire                          ctrl_done,               // Pulses high for one cycle when transfer request is complete

  // The following ctrl signals are sampled when ctrl_start is asserted
  input  wire [C_M_AXI_ADDR_WIDTH-1:0] ctrl_addr_offset,        // Starting Address offset
  input  wire [C_XFER_SIZE_WIDTH-1:0]  ctrl_xfer_size_in_bytes, // Length in number of bytes, limited by the address width.

  // AXI Request signals
  output wire                          m_axi_req_ready,

  // AXI4 master interface (read only)
  output wire                          m_axi_arvalid,
  input  wire                          m_axi_arready,
  output wire [C_M_AXI_ADDR_WIDTH-1:0] m_axi_araddr,
  output wire [8-1:0]                  m_axi_arlen,

  input  wire                          m_axi_rvalid,
  output wire                          m_axi_rready,
  input  wire [C_M_AXI_DATA_WIDTH-1:0] m_axi_rdata,
  input  wire                          m_axi_rlast,

  // AXI4-Stream master interface
  input  wire                          m_axis_aclk,
  input  wire                          m_axis_areset,
  output wire                          m_axis_tvalid,
  input  wire                          m_axis_tready,
  output wire [C_M_AXI_DATA_WIDTH-1:0] m_axis_tdata,
  output wire                          m_axis_tlast,
  output wire                          rd_req_fifo_full
);

timeunit 1ps;
timeprecision 1ps;
///////////////////////////////////////////////////////////////////////////////
// functions
///////////////////////////////////////////////////////////////////////////////
function integer f_max (
  input integer a,
  input integer b
);
  f_max = (a > b) ? a : b;
endfunction

function integer f_min (
  input integer a,
  input integer b
);
  f_min = (a < b) ? a : b;
endfunction

///////////////////////////////////////////////////////////////////////////////
// Local Parameters
///////////////////////////////////////////////////////////////////////////////
localparam integer LP_DW_BYTES                   = C_M_AXI_DATA_WIDTH/8;
localparam integer LP_LOG_DW_BYTES               = $clog2(LP_DW_BYTES);
localparam integer LP_MAX_BURST_LENGTH           = 256;   // Max AXI Protocol burst length
localparam integer LP_MAX_BURST_BYTES            = 4096;  // Max AXI Protocol burst size in bytes
localparam integer LP_AXI_BURST_LEN              = f_min(LP_MAX_BURST_BYTES/LP_DW_BYTES, LP_MAX_BURST_LENGTH);
localparam integer LP_LOG_BURST_LEN              = $clog2(LP_AXI_BURST_LEN);
localparam integer LP_OUTSTANDING_CNTR_WIDTH     = $clog2(C_MAX_OUTSTANDING+1);
localparam integer LP_TOTAL_LEN_WIDTH            = C_XFER_SIZE_WIDTH-LP_LOG_DW_BYTES;
localparam integer LP_TRANSACTION_CNTR_WIDTH     = LP_TOTAL_LEN_WIDTH-LP_LOG_BURST_LEN;
localparam [C_M_AXI_ADDR_WIDTH-1:0] LP_ADDR_MASK = LP_DW_BYTES*LP_AXI_BURST_LEN - 1;
// FIFO Parameters
localparam integer LP_FIFO_DEPTH                 = 2**($clog2(LP_AXI_BURST_LEN*C_MAX_OUTSTANDING)); // Ensure power of 2
localparam integer LP_FIFO_READ_LATENCY          = 2; // 2: Registered output on BRAM, 1: Registered output on LUTRAM
localparam integer LP_FIFO_COUNT_WIDTH           = $clog2(LP_FIFO_DEPTH)+1;

///////////////////////////////////////////////////////////////////////////////
// Variables
///////////////////////////////////////////////////////////////////////////////
// Control logic
logic                                     done = '0;
logic                                     has_partial_bursts;
logic                                     start_d1 = 1'b0;
logic [C_M_AXI_ADDR_WIDTH-1:0]            addr_offset_r;
logic                                     start    = 1'b0;
logic [LP_TOTAL_LEN_WIDTH-1:0]            total_len_r;
logic [LP_TRANSACTION_CNTR_WIDTH-1:0]     num_transactions;
logic [LP_LOG_BURST_LEN-1:0]              final_burst_len;
logic                                     single_transaction;
logic                                     ar_idle = 1'b1;
logic                                     ar_done;
// AXI Read Address Channel
logic                                     arxfer;
logic                                     arvalid_r = 1'b0;
logic [C_M_AXI_ADDR_WIDTH-1:0]            addr;
logic [LP_TRANSACTION_CNTR_WIDTH-1:0]     ar_transactions_to_go;
logic                                     ar_final_transaction;
logic                                     stall_ar;
// AXI Data Channel
logic                                     rxfer;
logic                                     r_completed;
logic                                     decr_r_transaction_cntr;
logic [LP_TRANSACTION_CNTR_WIDTH-1:0]     r_transactions_to_go;
logic                                     r_final_transaction;
logic [LP_OUTSTANDING_CNTR_WIDTH-1:0]     outstanding_vacancy_count;
// AXI Request Fifo 
logic                                     pop_request;
logic                                     cur_req_sent;
wire [C_M_AXI_ADDR_WIDTH-1:0]             cur_req_addr_offset_fifo;        // the actual request addr need to be sent out
wire [C_XFER_SIZE_WIDTH-1:0]              cur_req_xfer_size_in_bytes_fifo; // teh actual request lengh 
wire [C_M_AXI_ADDR_WIDTH-1:0]             cur_req_addr_offset;        // the actual request addr need to be sent out
wire [C_XFER_SIZE_WIDTH-1:0]              cur_req_xfer_size_in_bytes; // teh actual request lengh                          
logic                                     axi_req_fifo_read_ready;
logic                                     axi_req_fifo_almost_full;
logic                                     axi_req_fifo_almost_empty;
//logic [LP_FIFO_COUNT_WIDTH:0]             accelerator_req_counter;
logic                                     ctrl_start_fifo, ctrl_start_d_fifo;
logic                                     rd_address_valid_flag;
logic                                     fifo_empty, fifo_full;
// req split logic
logic split_sm_complete;
logic split_sm_running;
logic                                     pop_request_w;
logic                                     pop_request_fifo;
logic                                     pop_request_splitter;
logic                                     addr_in_valid;
logic                                     addr_out_valid;
logic                                     split_first_sent;

///////////////////////////////////////////////////////////////////////////////
// AXI request fifo and logic
///////////////////////////////////////////////////////////////////////////////

fifo #(  // Parameters
  .DATA_WIDTH(C_M_AXI_ADDR_WIDTH + C_XFER_SIZE_WIDTH + 1'b1),
  .ADDR_WIDTH(7)
) AXI_REQ_FIFO (
  .clk(aclk),
  .reset(areset),
  .s_write_req(ctrl_start), // other signal driven by ctrl_start need to modified
  .s_read_req(pop_request_fifo),
  .s_write_data({ctrl_addr_offset,ctrl_xfer_size_in_bytes, ctrl_start}),
  .s_read_data({cur_req_addr_offset_fifo, cur_req_xfer_size_in_bytes_fifo, ctrl_start_fifo}),
  .s_read_ready(axi_req_fifo_read_ready),
  .s_write_ready(m_axi_req_ready),
  .almost_full(axi_req_fifo_almost_full),
  .almost_empty(axi_req_fifo_almost_empty),
  .full(fifo_full),
  .empty(fifo_empty)
);


always @(posedge aclk) begin
  addr_in_valid <= pop_request_fifo;
end
// request split logic to split unaligned 4k requests into 2 requests
mem_request_splitter #(
      .ADDR_WIDTH(C_M_AXI_ADDR_WIDTH),
      .REQ_SIZE_WIDTH(C_XFER_SIZE_WIDTH)
  )
  i_mem_request_splitter
  (
      .clk(aclk),
      .reset(areset),
      .addr_in(cur_req_addr_offset_fifo),
      .addr_in_valid(addr_in_valid),
      .input_req_size_bytes(cur_req_xfer_size_in_bytes_fifo),
      .pop_request(pop_request_splitter),
      .axi_wr_ready(m_axi_arready),
      .addr_out(cur_req_addr_offset),
      .addr_out_valid(addr_out_valid),
      .output_req_size_bytes(cur_req_xfer_size_in_bytes),
      .split_sm_running(split_sm_running), 
      .split_sm_complete(split_sm_complete),
      .request_valid(pop_request),
      .split_first_sent(split_first_sent) 
  );

// Logic to decide when to read from request fifo
always @(posedge aclk) begin
  if (areset)
    cur_req_sent <= 1'b0;
  else if (fifo_empty && ~split_sm_running)
    cur_req_sent <= 1'b1;
  else
    cur_req_sent <= ar_final_transaction;
  end

assign rd_req_fifo_full = axi_req_fifo_almost_full;
/*
syncFlipFlop_Enable #(.DATA_WIDTH(C_M_AXI_ADDR_WIDTH + C_XFER_SIZE_WIDTH + 1'b1)) cur_req_reg (
    .clk(aclk),
    .rst_n(~areset), 
    .en(m_axi_arready),
    .D({cur_req_addr_offset_fifo, cur_req_xfer_size_in_bytes_fifo, ctrl_start_d_fifo}), 
    .Q({cur_req_addr_offset, cur_req_xfer_size_in_bytes, ctrl_start_fifo})
    );


always @(posedge aclk) begin
if (arvalid_r || fifo_empty)
    rd_address_valid_flag <= 1'b1;
else
    rd_address_valid_flag <= 1'b0;
end
*/

assign rd_address_valid_flag = (arvalid_r || fifo_empty) ? 1'b1 : 1'b0;
/*
always @(posedge aclk) begin
  if (areset)
    pop_request <= 1'b0;
  else
    pop_request <= axi_req_fifo_read_ready && cur_req_sent && m_axi_arready && rd_address_valid_flag;
end
*/
  logic fifo_empty_d;
  always @(posedge aclk) begin
    if (areset)
      fifo_empty_d <= 1'b0;
    else
      fifo_empty_d <= fifo_empty;
  end

  

  //assign pop_request_w = fifo_empty_d ? (split_sm_running ?  (cur_req_sent && m_axi_arready) : (axi_req_fifo_read_ready && cur_req_sent && m_axi_arready)) : (arvalid_r ?  axi_req_fifo_read_ready && cur_req_sent && m_axi_arready : 1'b0); 
  // Rohan: adding done signal might have issues
  //assign pop_request_w = fifo_empty_d ? (split_sm_running ? (split_first_sent ? (cur_req_sent && m_axi_arready && done) : 1'b0): (axi_req_fifo_read_ready && cur_req_sent && m_axi_arready)) : (arvalid_r ?  axi_req_fifo_read_ready && cur_req_sent && m_axi_arready : 1'b0); 
  assign pop_request_w = fifo_empty_d ? (split_sm_running ? (split_first_sent ? (m_axi_arready && done) : 1'b0): (axi_req_fifo_read_ready && cur_req_sent && m_axi_arready)) : (arvalid_r ?  axi_req_fifo_read_ready && cur_req_sent && m_axi_arready : 1'b0); 
  assign pop_request_fifo = ~split_sm_running ?  pop_request_w : 1'b0;
  assign pop_request_splitter = split_sm_running ?  pop_request_w : 1'b0; 

/*
always @(posedge clk) begin
  if (areset || )
    accelerator_req_counter <= 'b0;
  else if (ctrl_start)
    accelerator_req_counter <= accelerator_req_counter + 1'b1;
  else if (pop_request)
    accelerator_req_counter <= accelerator_req_counter - 1'b1;
end
*/



///////////////////////////////////////////////////////////////////////////////
// Control Logic
///////////////////////////////////////////////////////////////////////////////

always @(posedge aclk) begin
  done <= rxfer & m_axi_rlast & r_final_transaction ? 1'b1 : ctrl_done ? 1'b0 : done;
  //done <= !axi_req_fifo_read_ready & rxfer & m_axi_rlast & r_final_transaction ? 1'b1 : ctrl_done ? 1'b0 : done;   // Don't quite follow the logic here
end

assign ctrl_done = done;

// might need to delay the pop_request
always @(posedge aclk) begin
  //start_d1 <= ctrl_start;
  start_d1 <= pop_request;
end

// Store the address and transfer size after some pre-processing.
always @(posedge aclk) begin
  if (addr_out_valid) begin
    // Round transfer size up to integer value of the axi interface data width. Convert to axi_arlen format which is length -1.
    /*
    total_len_r <= ctrl_xfer_size_in_bytes[0+:LP_LOG_DW_BYTES] > 0
                      ? ctrl_xfer_size_in_bytes[LP_LOG_DW_BYTES+:LP_TOTAL_LEN_WIDTH]
                      : ctrl_xfer_size_in_bytes[LP_LOG_DW_BYTES+:LP_TOTAL_LEN_WIDTH] - 1'b1;
    */
    total_len_r <= cur_req_xfer_size_in_bytes[0+:LP_LOG_DW_BYTES] > 0
                  ? cur_req_xfer_size_in_bytes[LP_LOG_DW_BYTES+:LP_TOTAL_LEN_WIDTH]
                  : cur_req_xfer_size_in_bytes[LP_LOG_DW_BYTES+:LP_TOTAL_LEN_WIDTH] - 1'b1;
    
    // Align transfer to 4kB to avoid AXI protocol issues if starting address is not correctly aligned.
    //addr_offset_r <= ctrl_addr_offset & ~LP_ADDR_MASK; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! Changed !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    addr_offset_r <= cur_req_addr_offset;
  end
end

// Determine how many full burst to issue and if there are any partial bursts.
assign num_transactions = total_len_r[LP_LOG_BURST_LEN+:LP_TRANSACTION_CNTR_WIDTH];
assign has_partial_bursts = total_len_r[0+:LP_LOG_BURST_LEN] == {LP_LOG_BURST_LEN{1'b1}} ? 1'b0 : 1'b1;

// might need to delay the pop_request
always @(posedge aclk) begin
  start <= start_d1;      
  final_burst_len <=  total_len_r[0+:LP_LOG_BURST_LEN];
end

// Special case if there is only 1 AXI transaction.
assign single_transaction = (num_transactions == {LP_TRANSACTION_CNTR_WIDTH{1'b0}}) ? 1'b1 : 1'b0;

///////////////////////////////////////////////////////////////////////////////
// AXI Read Address Channel
///////////////////////////////////////////////////////////////////////////////
assign m_axi_arvalid = arvalid_r;
assign m_axi_araddr = addr;
assign m_axi_arlen  = ar_final_transaction || (start & single_transaction) ? final_burst_len : LP_AXI_BURST_LEN - 1;

assign arxfer = m_axi_arvalid & m_axi_arready;

always @(posedge aclk) begin
  if (areset) begin
    arvalid_r <= 1'b0;
  end
  else begin
    arvalid_r <= ~ar_idle & ~stall_ar & ~arvalid_r ? 1'b1 :
                 m_axi_arready ? 1'b0 : arvalid_r;
  end
end

// When ar_idle, there are no transactions to issue.
always @(posedge aclk) begin
  if (areset) begin
    ar_idle <= 1'b1;
  end
  else begin
    ar_idle <= start   ? 1'b0 :
               ar_done ? 1'b1 :
                         ar_idle;
  end
end

// Increment to next address after each transaction is issued.
always @(posedge aclk) begin
  addr <= start ? addr_offset_r :
          arxfer     ? addr + LP_AXI_BURST_LEN*C_M_AXI_DATA_WIDTH/8 :
                       addr;
end

// Counts down the number of transactions to send.
control_m_axi_write_master_counter #(
  .C_WIDTH ( LP_TRANSACTION_CNTR_WIDTH         ) ,
  .C_INIT  ( {LP_TRANSACTION_CNTR_WIDTH{1'b0}} )
)
inst_ar_transaction_cntr (
  .clk        ( aclk                   ) ,
  .clken      ( 1'b1                   ) ,
  .rst        ( areset                 ) ,
  .load       ( start                  ) ,
  .incr       ( 1'b0                   ) ,
  .decr       ( arxfer                 ) ,
  .load_value ( num_transactions       ) ,
  .count      ( ar_transactions_to_go  ) ,
  .is_zero    ( ar_final_transaction   )
);

assign ar_done = ar_final_transaction && arxfer;


// Keeps track of the number of outstanding transactions. Stalls
// when the value is reached so that the FIFO won't overflow.
// If no FIFO present, then just limit at max outstanding transactions.
control_m_axi_write_master_counter #(
  .C_WIDTH ( LP_OUTSTANDING_CNTR_WIDTH                       ) ,
  .C_INIT  ( C_MAX_OUTSTANDING[0+:LP_OUTSTANDING_CNTR_WIDTH] )
)
inst_ar_to_r_transaction_cntr (
  .clk        ( aclk                              ) ,
  .clken      ( 1'b1                              ) ,
  .rst        ( areset                            ) ,
  .load       ( 1'b0                              ) ,
  .incr       ( r_completed                       ) ,
  .decr       ( arxfer                            ) ,
  .load_value ( {LP_OUTSTANDING_CNTR_WIDTH{1'b0}} ) ,
  .count      ( outstanding_vacancy_count         ) ,
  .is_zero    ( stall_ar                          )
);


///////////////////////////////////////////////////////////////////////////////
// AXI Read Channel
///////////////////////////////////////////////////////////////////////////////
generate
if (C_INCLUDE_DATA_FIFO == 1) begin : gen_fifo

  // xpm_fifo_sync: Synchronous FIFO
  // Xilinx Parameterized Macro, Version 2017.4
  xpm_fifo_sync # (
    .FIFO_MEMORY_TYPE    ( "auto"               ) , // string; "auto", "block", "distributed", or "ultra";
    .ECC_MODE            ( "no_ecc"             ) , // string; "no_ecc" or "en_ecc";
    .FIFO_WRITE_DEPTH    ( LP_FIFO_DEPTH        ) , // positive integer
    .WRITE_DATA_WIDTH    ( C_M_AXI_DATA_WIDTH+1 ) , // positive integer
    .WR_DATA_COUNT_WIDTH ( LP_FIFO_COUNT_WIDTH  ) , // positive integer, not used
    .PROG_FULL_THRESH    ( 10                   ) , // positive integer, not used
    .FULL_RESET_VALUE    ( 1                    ) , // positive integer; 0 or 1
    .USE_ADV_FEATURES    ( "1F1F"               ) , // string; "0000" to "1F1F";
    .READ_MODE           ( "fwft"               ) , // string; "std" or "fwft";
    .FIFO_READ_LATENCY   ( LP_FIFO_READ_LATENCY ) , // positive integer;
    .READ_DATA_WIDTH     ( C_M_AXI_DATA_WIDTH+1 ) , // positive integer
    .RD_DATA_COUNT_WIDTH ( LP_FIFO_COUNT_WIDTH  ) , // positive integer, not used
    .PROG_EMPTY_THRESH   ( 10                   ) , // positive integer, not used
    .DOUT_RESET_VALUE    ( "0"                  ) , // string, don't care
    .WAKEUP_TIME         ( 0                    ) // positive integer; 0 or 2;
  )
  inst_rd_xpm_fifo_sync (
    .sleep         ( 1'b0                        ) ,
    .rst           ( areset                      ) ,
    .wr_clk        ( aclk                        ) ,
    .wr_en         ( m_axi_rvalid                ) ,
    .din           ( {m_axi_rlast,m_axi_rdata}   ) ,
    .full          (                             ) ,
    .overflow      (                             ) ,
    .prog_full     (                             ) ,
    .wr_data_count (                             ) ,
    .almost_full   (                             ) ,
    .wr_ack        (                             ) ,
    .wr_rst_busy   (                             ) ,
    .rd_en         ( m_axis_tready               ) ,
    .dout          ( {m_axis_tlast,m_axis_tdata} ) ,
    .empty         (                             ) ,
    .prog_empty    (                             ) ,
    .rd_data_count (                             ) ,
    .almost_empty  (                             ) ,
    .data_valid    ( m_axis_tvalid               ) ,
    .underflow     (                             ) ,
    .rd_rst_busy   (                             ) ,
    .injectsbiterr ( 1'b0                        ) ,
    .injectdbiterr ( 1'b0                        ) ,
    .sbiterr       (                             ) ,
    .dbiterr       (                             )
  ) ;

  assign m_axi_rready = 1'b1;
end
else begin : gen_no_fifo

  // All signals pass through.
  assign m_axis_tvalid = m_axi_rvalid;
  assign m_axis_tdata  = m_axi_rdata;
  assign m_axi_rready  = m_axis_tready;
  assign m_axis_tlast  = m_axi_rlast;

end
endgenerate

assign rxfer = m_axi_rready & m_axi_rvalid;

assign r_completed = m_axis_tvalid & m_axis_tready & m_axis_tlast;

always_comb begin
  decr_r_transaction_cntr = rxfer & m_axi_rlast;
end

control_m_axi_write_master_counter #(
  .C_WIDTH ( LP_TRANSACTION_CNTR_WIDTH         ) ,
  .C_INIT  ( {LP_TRANSACTION_CNTR_WIDTH{1'b0}} )
)
inst_r_transaction_cntr (
  .clk        ( aclk                          ) ,
  .clken      ( 1'b1                          ) ,
  .rst        ( areset                        ) ,
  .load       ( start                         ) ,
  .incr       ( 1'b0                          ) ,
  .decr       ( decr_r_transaction_cntr       ) ,
  .load_value ( num_transactions              ) ,
  .count      ( r_transactions_to_go          ) ,
  .is_zero    ( r_final_transaction           )
);

endmodule : control_m_axi_read_master_fifo

`default_nettype wire

