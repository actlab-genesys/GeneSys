////////////////////////////////////////////////////////////////////////////////
// default_nettype of none prevents implicit wire declaration.
`default_nettype none

module ddr_memory_interface_control_m_axi_fifo #(
  parameter integer C_M_AXI_ADDR_WIDTH       = 64 ,
  parameter integer C_M_AXI_DATA_WIDTH       = 512,
  parameter integer C_XFER_SIZE_WIDTH        = 32,
  parameter integer C_ADDER_BIT_WIDTH        = 32,
  parameter integer NUM_BANKS                = 64
)
(
  // System Signals
  input wire                                    clk               ,
  input wire                                    reset             ,
  // Extra clocks
  input wire                                    kernel_clk         ,
  input wire                                    kernel_rst         ,
  // AXI4 master interface
  output wire                                   m_axi_awvalid      ,
  input wire                                    m_axi_awready      ,
  output wire [C_M_AXI_ADDR_WIDTH-1:0]          m_axi_awaddr       ,
  output wire [8-1:0]                           m_axi_awlen        ,
  output wire                                   m_axi_wvalid       ,
  input wire                                    m_axi_wready       ,
  output wire [C_M_AXI_DATA_WIDTH-1:0]          m_axi_wdata        ,
  output wire [C_M_AXI_DATA_WIDTH/8-1:0]        m_axi_wstrb        ,
  output wire                                   m_axi_wlast        ,
  output wire                                   m_axi_arvalid      ,
  input wire                                    m_axi_arready      ,
  output wire [C_M_AXI_ADDR_WIDTH-1:0]          m_axi_araddr       ,
  output wire [8-1:0]                           m_axi_arlen        ,
  input wire                                    m_axi_rvalid       ,
  output wire                                   m_axi_rready       ,
  input wire [C_M_AXI_DATA_WIDTH-1:0]           m_axi_rdata        ,
  input wire                                    m_axi_rlast        ,
  input wire                                    m_axi_bvalid       ,
  output wire                                   m_axi_bready       ,
  input wire                                    ap_start_rd        ,
  input wire                                    ap_start_wr        ,
  output wire                                   ap_done_rd         ,
  output wire                                   ap_done_wr         ,
  input wire [C_M_AXI_ADDR_WIDTH-1:0]           ctrl_addr_offset_rd   ,
  input wire [C_XFER_SIZE_WIDTH-1:0]            ctrl_xfer_size_in_bytes_rd,
  input wire [C_M_AXI_ADDR_WIDTH-1:0]           ctrl_addr_offset_wr   ,
  input wire [C_XFER_SIZE_WIDTH-1:0]            ctrl_xfer_size_in_bytes_wr,
  //input wire [C_ADDER_BIT_WIDTH-1:0]            ctrl_constant,

  // Data signals for AXI Read Interface 
  // exporting signals received from AXI to some memory like OBUF/IMEM
  output wire                                       rd_tvalid          ,
  input  wire                                       rd_tready          ,   // drive from state machine
  output wire [C_M_AXI_DATA_WIDTH-1:0]              rd_tdata           ,
  output wire [C_M_AXI_DATA_WIDTH/8-1:0]            rd_tkeep           ,
  output wire                                       rd_tlast           ,
  output wire                                       rd_addr_arready    ,             
  
  // data signals for AXI write interface. These are driven from SIMD and state machine
  input wire                                        wr_tvalid,
  output wire                                       wr_tready,
  input wire  [C_M_AXI_DATA_WIDTH-1:0]              wr_tdata,
  output wire                                       req_fifo_empty,
  output wire                                       read_buf_data,
  output wire                                       req_fifo_full,
  output wire                                       rd_req_fifo_full,
  //input wire                                        st_fifo_almost_full
  input wire                                        st_data_fifo_rd_ready,
  input wire                             stmem_state_start,
  input wire                             stmem_state_done
  
);

timeunit 1ps;
timeprecision 1ps;


///////////////////////////////////////////////////////////////////////////////
// Local Parameters
///////////////////////////////////////////////////////////////////////////////
localparam integer LP_DW_BYTES             = C_M_AXI_DATA_WIDTH/8;
localparam integer LP_AXI_BURST_LEN        = 4096/LP_DW_BYTES < 256 ? 4096/LP_DW_BYTES : 256;
localparam integer LP_LOG_BURST_LEN        = $clog2(LP_AXI_BURST_LEN);
localparam integer LP_BRAM_DEPTH           = 512;
localparam integer LP_RD_MAX_OUTSTANDING   = LP_BRAM_DEPTH / LP_AXI_BURST_LEN;
localparam integer LP_WR_MAX_OUTSTANDING   = 32;

///////////////////////////////////////////////////////////////////////////////
// Wires and Variables
///////////////////////////////////////////////////////////////////////////////

// Control logic
logic                          done = 1'b0;
// AXI read master stage
logic                          read_done;
//logic                          rd_tvalid;
//logic                          rd_tready;
//logic                          rd_tlast;
//logic [C_M_AXI_DATA_WIDTH-1:0] rd_tdata;
// Adder stage
//logic                          adder_tvalid;
//logic                          adder_tready;
//logic [C_M_AXI_DATA_WIDTH-1:0] adder_tdata;

// AXI write master stage
logic                          write_done;
logic                          m_axi_req_ready;
// rohan added
assign rd_addr_arready = m_axi_arready && m_axi_req_ready;
///////////////////////////////////////////////////////////////////////////////
// Begin RTL
///////////////////////////////////////////////////////////////////////////////

// AXI4 Read Master, output format is an AXI4-Stream master, one stream per thread.
control_m_axi_read_master_fifo #(
  .C_M_AXI_ADDR_WIDTH  ( C_M_AXI_ADDR_WIDTH    ) ,
  .C_M_AXI_DATA_WIDTH  ( C_M_AXI_DATA_WIDTH    ) ,
  .C_XFER_SIZE_WIDTH   ( C_XFER_SIZE_WIDTH     ) ,
  .C_MAX_OUTSTANDING   ( LP_RD_MAX_OUTSTANDING ) ,
  .C_INCLUDE_DATA_FIFO ( 0                     )
)
inst_axi_read_master (
  .aclk                    ( clk                     ) ,
  .areset                  ( reset                   ) ,
  .ctrl_start              ( ap_start_rd             ) ,
  .ctrl_done               ( ap_done_rd              ) ,
  .ctrl_addr_offset        ( ctrl_addr_offset_rd     ) ,
  .ctrl_xfer_size_in_bytes ( ctrl_xfer_size_in_bytes_rd) ,
  .m_axi_arvalid           ( m_axi_arvalid           ) ,
  .m_axi_arready           ( m_axi_arready           ) ,
  .m_axi_araddr            ( m_axi_araddr            ) ,
  .m_axi_arlen             ( m_axi_arlen             ) ,
  .m_axi_rvalid            ( m_axi_rvalid            ) ,
  .m_axi_rready            ( m_axi_rready            ) ,
  .m_axi_rdata             ( m_axi_rdata             ) ,
  .m_axi_rlast             ( m_axi_rlast             ) ,
  .m_axis_aclk             ( kernel_clk              ) ,
  .m_axis_areset           ( kernel_rst              ) ,
  .m_axis_tvalid           ( rd_tvalid               ) ,
  .m_axis_tready           ( rd_tready               ) ,
  .m_axis_tlast            ( rd_tlast                ) ,
  .m_axis_tdata            ( rd_tdata                ) ,
  .m_axi_req_ready         ( m_axi_req_ready         ),
  .rd_req_fifo_full        (rd_req_fifo_full         )
    
);

// AXI4 Write Master
control_m_axi_write_master_fifo #(
  .C_M_AXI_ADDR_WIDTH  ( C_M_AXI_ADDR_WIDTH    ) ,
  .C_M_AXI_DATA_WIDTH  ( C_M_AXI_DATA_WIDTH    ) ,
  .C_XFER_SIZE_WIDTH   ( C_XFER_SIZE_WIDTH     ) ,
  .C_MAX_OUTSTANDING   ( LP_WR_MAX_OUTSTANDING ) ,
  .C_INCLUDE_DATA_FIFO ( 1                     ),
  .NUM_BANKS           (NUM_BANKS              )
)
inst_axi_write_master (
  .aclk                    ( clk                     ) ,
  .areset                  ( reset                   ) ,
  .ctrl_start              ( ap_start_wr             ) ,
  .ctrl_done               ( ap_done_wr              ) ,
  .ctrl_addr_offset        ( ctrl_addr_offset_wr     ) ,
  .ctrl_xfer_size_in_bytes ( ctrl_xfer_size_in_bytes_wr) ,
  .m_axi_awvalid           ( m_axi_awvalid           ) ,
  .m_axi_awready           ( m_axi_awready           ) ,
  .m_axi_awaddr            ( m_axi_awaddr            ) ,
  .m_axi_awlen             ( m_axi_awlen             ) ,
  .m_axi_wvalid            ( m_axi_wvalid            ) ,
  .m_axi_wready            ( m_axi_wready            ) ,
  .m_axi_wdata             ( m_axi_wdata             ) ,
  .m_axi_wstrb             ( m_axi_wstrb             ) ,
  .m_axi_wlast             ( m_axi_wlast             ) ,
  .m_axi_bvalid            ( m_axi_bvalid            ) ,
  .m_axi_bready            ( m_axi_bready            ) ,
  .s_axis_aclk             ( kernel_clk              ) ,
  .s_axis_areset           ( kernel_rst              ) ,
  .s_axis_tvalid           ( wr_tvalid               ) ,
  .s_axis_tready           ( wr_tready               ) ,
  .s_axis_tdata            ( wr_tdata                ) ,
  .read_buf_data           (read_buf_data            ) ,
  .req_fifo_full           (req_fifo_full            ),
  .st_data_fifo_rd_ready   (st_data_fifo_rd_ready    ),
  .stmem_state_start       (stmem_state_start        ),
  .stmem_state_done        (stmem_state_done	     )

  //.st_fifo_almost_full     (st_fifo_almost_full      ) 
);

//assign ap_done = write_done || read_done;

endmodule : ddr_memory_interface_control_m_axi_fifo
`default_nettype wire
