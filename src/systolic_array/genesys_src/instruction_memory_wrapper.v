//
// Wrapper for instruction memory
//


`timescale 1ns/1ps
module instruction_memory_wrapper #(
  // Internal Parameters
    parameter integer  MEM_ID                       = 0,
    parameter integer  MEM_REQ_W                    = 16,

  // AXI
    parameter integer  AXI_ADDR_WIDTH               = 42,
    parameter integer  AXI_ID_WIDTH                 = 1,
    parameter integer  AXI_DATA_WIDTH               = 64,
    parameter integer  AXI_BURST_WIDTH              = 8,
    parameter integer  WSTRB_W                      = AXI_DATA_WIDTH/8,


    ////
    parameter integer  INST_DATA_WIDTH              = 32,
    parameter integer  NUM_INST_IN                  = AXI_DATA_WIDTH / INST_DATA_WIDTH,
    parameter integer  INST_ADDR_WIDTH              = 10
) (
    input  wire                                         clk,
    input  wire                                         reset,
    input  wire 										start,
	
    input  wire                                         imem_rd_req,
    input  wire  [ INST_ADDR_WIDTH      -1 : 0 ]        imem_rd_addr,
	input  wire											imem_rd_block_done,
		
    output wire  [ INST_DATA_WIDTH      -1 : 0 ]        imem_rd_data,
    output wire  								        imem_rd_valid,
    output wire                                         imem_block_ready,
  // CL_wrapper -> DDR AXI4 interface
    // Master Interface Write Address
    output wire  [ AXI_ADDR_WIDTH       -1 : 0 ]        imem_awaddr,
    output wire  [ AXI_BURST_WIDTH      -1 : 0 ]        imem_awlen,
//    output wire  [ 3                    -1 : 0 ]        imem_awsize,
//    output wire  [ 2                    -1 : 0 ]        imem_awburst,
    output wire                                         imem_awvalid,
    input  wire                                         imem_awready,
    // Master Interface Write Data
    output wire  [ AXI_DATA_WIDTH       -1 : 0 ]        imem_wdata,
    output wire  [ WSTRB_W              -1 : 0 ]        imem_wstrb,
    output wire                                         imem_wlast,
    output wire                                         imem_wvalid,
    input  wire                                         imem_wready,
    // Master Interface Write Response
//    input  wire  [ 2                    -1 : 0 ]        imem_bresp,
    input  wire                                         imem_bvalid,
    output wire                                         imem_bready,
    // Master Interface Read Address
    output wire  [ AXI_ADDR_WIDTH       -1 : 0 ]        imem_araddr,
    output wire  [ AXI_BURST_WIDTH      -1 : 0 ]        imem_arlen,
//    output wire  [ 3                    -1 : 0 ]        imem_arsize,
//    output wire  [ 2                    -1 : 0 ]        imem_arburst,
    output wire                                         imem_arvalid,
//    output wire  [ AXI_ID_WIDTH         -1 : 0 ]        imem_arid,
    input  wire                                         imem_arready,
    // Master Interface Read Data
    input  wire  [ AXI_DATA_WIDTH       -1 : 0 ]        imem_rdata,
//    input  wire  [ 2                    -1 : 0 ]        imem_rresp,
    input  wire                                         imem_rlast,
    input  wire                                         imem_rvalid,
//    input  wire  [ AXI_ID_WIDTH         -1 : 0 ]        imem_rid,
    output wire                                         imem_rready,
    
    input  wire [ AXI_ADDR_WIDTH       -1 : 0 ]        slave_ld_addr,
    input  wire [ MEM_REQ_W            -1 : 0 ]        slave_ld_req_size,
    input  wire                                        slave_ld_req_in,
    
    input  wire [ AXI_ADDR_WIDTH       -1 : 0 ]        decoder_ld_addr,
    input  wire [ MEM_REQ_W            -1 : 0 ]        decoder_ld_req_size,
    input  wire                                        decoder_ld_req_in
);

//==============================================================================
// Localparams
//==============================================================================
    //localparam integer  LDMEM_IDLE                   = 0;

//==============================================================================

    
    reg                                        axi_rd_req;
    wire                                        axi_rd_done;
    reg [ MEM_REQ_W            -1 : 0 ]        axi_rd_req_size;
    reg [ AXI_ADDR_WIDTH       -1 : 0 ]        axi_rd_addr;

    wire                                        axi_wr_req;
    wire [ MEM_REQ_W            -1 : 0 ]        axi_wr_req_size;
    wire                                        axi_wr_ready;
    wire [ AXI_ADDR_WIDTH       -1 : 0 ]        axi_wr_addr;

    wire                                        mem_write_req;
    wire [ AXI_DATA_WIDTH       -1 : 0 ]        mem_write_data;

    wire                                        mem_write_ready;
    wire [ AXI_DATA_WIDTH       -1 : 0 ]        mem_read_data;
    wire                                        axi_wr_data_v;

    
    
    wire slave_ld_req,decoder_ld_req;
    reg  slave_ld_req_in_d,decoder_ld_req_in_d;
    wire imem_wr_start,axi_rd_req_final;
    
    wire imem_wr_done;
    
    wire [INST_DATA_WIDTH-1:0] imem_write_data;
    wire imem_wr_data_valid;
	wire [ NUM_INST_IN*INST_DATA_WIDTH-1 : 0 ]		imem_wr_data;
    wire                                            axi_rd_ready;  
//==============================================================================

//==============================================================================
// Assigns
//==============================================================================




    assign axi_wr_req = 1'b0;
    assign axi_wr_req_size = 0;
    assign axi_wr_addr = 0;                     
    assign axi_wr_data_v = 1'b0;
//==============================================================================

always @(posedge clk)
    if(reset) begin
        slave_ld_req_in_d <= 1'b0;
        decoder_ld_req_in_d <= 1'b0;
    end
    else begin
        slave_ld_req_in_d <= slave_ld_req_in;
        decoder_ld_req_in_d <= decoder_ld_req_in;
    end
        
assign slave_ld_req = slave_ld_req_in  ^ slave_ld_req_in_d;
assign decoder_ld_req = decoder_ld_req_in  ^ decoder_ld_req_in_d;

always @(posedge clk) begin
    if(reset) begin
        axi_rd_addr <= 'd0;
        axi_rd_req_size <= 'd0;
        axi_rd_req <= 1'b0;
    end
    else if( slave_ld_req   ) begin
        axi_rd_addr <= slave_ld_addr;
        axi_rd_req_size <= slave_ld_req_size;
        axi_rd_req <= 1'b1;
    end
    else if( decoder_ld_req   ) begin
        axi_rd_addr <= decoder_ld_addr;
        axi_rd_req_size <= decoder_ld_req_size;
        axi_rd_req <= 1'b1;
    end
    else if( axi_rd_req_final ) begin
        axi_rd_req <= 1'b0;
    end
end

reg axi_rd_req_q;

always @(posedge clk)
    if(reset) begin
        axi_rd_req_q <= 1'b0;
    end
    else begin
        axi_rd_req_q <= axi_rd_req;
    end


// Rohan: to make axi_rd_req go high for one cycle. Else, AXI was sending multiple instrcutions and reading same value multiple times
assign axi_rd_req_final =  (axi_rd_req & ~axi_rd_req_q) & imem_wr_start;

assign imem_wr_done = axi_rd_done;
assign imem_wr_data_valid = mem_write_req;
assign imem_wr_data = mem_write_data;

instruction_memory
#(
    .INST_DATA_WIDTH   (	INST_DATA_WIDTH ),
    .INST_ADDR_WIDTH   (	INST_ADDR_WIDTH ),
    .NUM_INST_IN       (    NUM_INST_IN     )
) inst_memory (

	.clk					(	clk					),
	.reset                  (	reset				),

	.start                  (	start				),

	.imem_rd_req            (	imem_rd_req			),
	.imem_rd_addr           (	imem_rd_addr		),
	.imem_rd_block_done     (	imem_rd_block_done	),
	.imem_block_ready       (	imem_block_ready	),

	.imem_rd_data           (	imem_rd_data		),
	.imem_rd_valid          (	imem_rd_valid		),

	.imem_wr_start          (	imem_wr_start		),
	.imem_wr_done           (	imem_wr_done		),

	.imem_wr_data_valid     (	imem_wr_data_valid	),
	.imem_wr_data           (	imem_wr_data		)
);

//==============================================================================
// AXI4 Memory Mapped interface
//==============================================================================
    assign mem_write_ready = 1'b1;
    assign mem_read_data = 0;
  ddr_memory_interface_control_m_axi #(
    .C_XFER_SIZE_WIDTH                  ( MEM_REQ_W                      ),
    .C_M_AXI_DATA_WIDTH                 ( AXI_DATA_WIDTH                 ),
    .C_M_AXI_ADDR_WIDTH                 ( AXI_ADDR_WIDTH                 )
  ) u_axi_mm_master (
    .clk                            ( clk                            ),
    .reset                          ( reset                          ),
    .kernel_clk                     ( clk                            ),                    
    .kernel_rst                     ( reset                          ),
    .m_axi_awaddr                   ( imem_awaddr                     ),
    .m_axi_awlen                    ( imem_awlen                      ),
//    .m_axi_awsize                   ( imem_awsize                     ),
//    .m_axi_awburst                  ( imem_awburst                    ),
    .m_axi_awvalid                  ( imem_awvalid                    ),
    .m_axi_awready                  ( imem_awready                    ),
    .m_axi_wdata                    ( imem_wdata                      ),
    .m_axi_wstrb                    ( imem_wstrb                      ),
    .m_axi_wlast                    ( imem_wlast                      ),
    .m_axi_wvalid                   ( imem_wvalid                     ),
    .m_axi_wready                   ( imem_wready                     ),
//    .m_axi_bresp                    ( imem_bresp                      ),
    .m_axi_bvalid                   ( imem_bvalid                     ),
    .m_axi_bready                   ( imem_bready                     ),
    .m_axi_araddr                   ( imem_araddr                     ),
//    .m_axi_arid                     ( imem_arid                       ),
    .m_axi_arlen                    ( imem_arlen                      ),
//    .m_axi_arsize                   ( imem_arsize                     ),
//    .m_axi_arburst                  ( imem_arburst                    ),
    .m_axi_arvalid                  ( imem_arvalid                    ),
    .m_axi_arready                  ( imem_arready                    ),
    .m_axi_rdata                    ( imem_rdata                      ),
//    .m_axi_rid                      ( imem_rid                        ),
//    .m_axi_rresp                    ( imem_rresp                      ),
    .m_axi_rlast                    ( imem_rlast                      ),
    .m_axi_rvalid                   ( imem_rvalid                     ),
    .m_axi_rready                   ( imem_rready                     ),
    
    // Buffer
    .ap_start_rd                    ( axi_rd_req_final                     ),
    .ap_start_wr                    ( axi_wr_req                     ),
    .ap_done_rd                     ( axi_rd_done                    ),
    .ap_done_wr                     (                                ),                   
    
    .ctrl_addr_offset_rd            ( axi_rd_addr                    ),
    .ctrl_xfer_size_in_bytes_rd     ( axi_rd_req_size                ),
    .ctrl_addr_offset_wr            ( axi_wr_addr                    ),
    .ctrl_xfer_size_in_bytes_wr     ( axi_wr_req_size                ),
        
    .rd_tvalid                      ( mem_write_req                  ),
    // Currently theere is no FIFO in the design that stores the extra data. this is the currnet limitation: 512 <= num_banks * data_width
    .rd_tready                      ( mem_write_ready                ),
    .rd_tdata                       ( mem_write_data                 ),
    .rd_tkeep                       (                                ),
    // We are using the done signal not the last!
    .rd_tlast                       (                                ),
    .rd_addr_arready                ( axi_rd_ready                   ),
    
    .wr_tvalid                      ( axi_wr_data_v                  ),
    .wr_tready                      ( axi_wr_ready                   ),
    .wr_tdata                       ( mem_read_data                  )    
    
  );
//==============================================================================



endmodule
