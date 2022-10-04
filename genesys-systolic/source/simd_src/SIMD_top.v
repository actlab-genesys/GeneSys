`timescale 1ps / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/02/2020 11:42:19 AM
// Design Name: 
// Module Name: SIMD_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module SIMD_top #(
    parameter OBUF_ISA_NS_INDEX = 0,
    parameter IBUF_ISA_NS_INDEX = 1,
    parameter VMEM1_ISA_NS_INDEX = 2,
    parameter VMEM2_ISA_NS_INDEX = 3,
    parameter IMM_ISA_NS_INDEX = 4,

	parameter NS_ID_BITS 			=	3,
	parameter NS_INDEX_ID_BITS 		=	5,
	parameter OPCODE_BITS 			=	4,
	parameter FUNCTION_BITS 		=	4,
	parameter INSTRUCTION_WIDTH 	= 	OPCODE_BITS + FUNCTION_BITS + 3*(NS_ID_BITS + NS_INDEX_ID_BITS),

	parameter IMEM_ADDR_WIDTH		= 10,
	
	parameter NUM_ELEM              = 4,
	
	parameter DATA_WIDTH = 32,
	
	parameter DATA_BUS_WIDTH    = DATA_WIDTH*NUM_ELEM,
	parameter VMEM_DATA_WIDTH   = DATA_WIDTH,
	parameter IMM_DATA_WIDTH    = DATA_WIDTH,
	parameter IMMEDIATE_WIDTH   = 16,
	
	parameter VMEM_ADDR_WIDTH   = 32,
	parameter IMM_ADDR_WIDTH    = 6,
	parameter BASE_STRIDE_WIDTH = 4*(NS_INDEX_ID_BITS + NS_ID_BITS),
	parameter OBUF_ADDR_WIDTH   = BASE_STRIDE_WIDTH,
	parameter IBUF_ADDR_WIDTH   = BASE_STRIDE_WIDTH,
	
	parameter GROUP_ID_W = 4,
	parameter MAX_NUM_GROUPS = (1<<GROUP_ID_W),

    parameter MEM_REQ_W           = 16,
    parameter BASE_ADDR_WIDTH     = 32,
    parameter BASE_ADDR_SEGMENT_W = 16,
    parameter NUM_TAGS  = 1,
    parameter integer TAG_W     = $clog2(NUM_TAGS),
    parameter VMEM_TAG_BUF_ADDR_W = TAG_W + VMEM_ADDR_WIDTH,
    parameter LD_ST_LOW_DATA_WIDTH = 8,
    
    // AXI
    parameter integer C_M_AXI_ADDR_WIDTH       = 64,
    parameter integer C_M_AXI_DATA_WIDTH       = 512,
    parameter integer C_XFER_SIZE_WIDTH        = 32,
    parameter integer C_ADDER_BIT_WIDTH        = 32,
    parameter AXI_BURST_WIDTH = 8,
    parameter WSTRB_W         = C_M_AXI_DATA_WIDTH / 8,

	parameter INTERLEAVE = 1,

    parameter PC_DATA_WIDTH = 64
)(
    input                       clk,
    input                       reset,
    
    input                       start,
    input                       in_fusion,
    input [GROUP_ID_W-1:0]      group_id_s,
    output                      ready,
    output                      simd_tiles_done,
    
    input                       block_done,
    
    input                                        imem_wr_req,
    input   [IMEM_ADDR_WIDTH-1:0]                imem_wr_addr,
    input   [INSTRUCTION_WIDTH-1:0]              imem_wr_data,
    
    input   [DATA_BUS_WIDTH -1:0]                obuf_data,
    output  [OBUF_ADDR_WIDTH*NUM_ELEM-1:0]       obuf_rd_addr,
    output  [NUM_ELEM-1:0]                       obuf_rd_req,

    output  [DATA_BUS_WIDTH -1:0]                ibuf_wr_data,
    output  [IBUF_ADDR_WIDTH*NUM_ELEM-1:0]       ibuf_wr_addr,
    output  [NUM_ELEM-1:0]                       ibuf_wr_req,

    output                                       buf_done,
    output                                       done,
    output  [3:0]                                group_id,
 
    output wire  [ C_M_AXI_ADDR_WIDTH   -1 : 0 ]        mws_awaddr,
    output wire  [ AXI_BURST_WIDTH      -1 : 0 ]        mws_awlen,
    output wire                                         mws_awvalid,
    input  wire                                         mws_awready,
// Master Interface Write Data
    output wire  [ C_M_AXI_DATA_WIDTH   -1 : 0 ]        mws_wdata,
    output wire  [ WSTRB_W              -1 : 0 ]        mws_wstrb,
    output wire                                         mws_wlast,
    output wire                                         mws_wvalid,
    input  wire                                         mws_wready,
// Master Interface Write Response
    input  wire                                         mws_bvalid,
    output wire                                         mws_bready,
// Master Interface Read Address
    output wire  [ C_M_AXI_ADDR_WIDTH   -1 : 0 ]        mws_araddr,
    output wire  [ AXI_BURST_WIDTH      -1 : 0 ]        mws_arlen,
    output wire                                         mws_arvalid,
    input  wire                                         mws_arready,
// Master Interface Read Data
    input  wire  [ C_M_AXI_DATA_WIDTH   -1 : 0 ]        mws_rdata,
    input  wire                                         mws_rlast,
    input  wire                                         mws_rvalid,
    output wire                                         mws_rready,
    input wire   [ C_M_AXI_ADDR_WIDTH   -1 : 0 ]        simd_base_offset,

// Performance Counter
    output wire [PC_DATA_WIDTH - 1 : 0]                 pc_simd_ld_num_tiles_vmem1,
    output wire [PC_DATA_WIDTH - 1 : 0]                 pc_simd_ld_num_tiles_vmem2,
    output wire [PC_DATA_WIDTH - 1 : 0]                 pc_simd_ld_tot_cycles_vmem1,  
    output wire [PC_DATA_WIDTH - 1 : 0]                 pc_simd_ld_tot_requests_vmem1,
    output wire [PC_DATA_WIDTH - 1 : 0]                 pc_simd_ld_size_per_requests_vmem1,
    output wire [PC_DATA_WIDTH - 1 : 0]                 pc_simd_ld_tot_cycles_vmem2,  
    output wire [PC_DATA_WIDTH - 1 : 0]                 pc_simd_ld_tot_requests_vmem2,
    output wire [PC_DATA_WIDTH - 1 : 0]                 pc_simd_ld_size_per_requests_vmem2,
    output wire [PC_DATA_WIDTH - 1 : 0]                 pc_simd_st_num_tiles_vmem1,
    output wire [PC_DATA_WIDTH - 1 : 0]                 pc_simd_st_num_tiles_vmem2,
    output wire [PC_DATA_WIDTH - 1 : 0]                 pc_simd_st_tot_cycles,  
    output wire [PC_DATA_WIDTH - 1 : 0]                 pc_simd_st_tot_requests,
    output wire [PC_DATA_WIDTH - 1 : 0]                 pc_simd_st_size_per_requests,
    output wire [PC_DATA_WIDTH - 1 : 0]                 pc_simd_tot_compute
);
    
/*************************************************/   
localparam ENABLE_PIPELINE_AFTER_NAMESPACE_MUX = 1;


wire  [VMEM_ADDR_WIDTH*NUM_ELEM-1:0]    vmem_rd_addr1,vmem_wr_addr1;
wire  [VMEM_ADDR_WIDTH*NUM_ELEM-1:0]    vmem_rd_addr2,vmem_wr_addr2;
wire  [NUM_ELEM-1:0] vmem_rd_req1,vmem_wr_req1;
wire  [NUM_ELEM-1:0] vmem_rd_req2,vmem_wr_req2;
wire  [ DATA_WIDTH*NUM_ELEM  -1 : 0 ]   vmem_data1,vmem_wr_data1;
wire  [ DATA_WIDTH*NUM_ELEM  -1 : 0 ]   vmem_data2,vmem_wr_data2;

wire  [IMM_ADDR_WIDTH-1:0]     imm_rd_addr,imm_wr_addr;
wire  imm_rd_req,imm_wr_req;
wire  [ IMM_DATA_WIDTH  -1 : 0 ] imm_mem_out;
wire  [ IMM_DATA_WIDTH*NUM_ELEM  -1 : 0 ] imm_data;
wire  [ IMM_DATA_WIDTH  -1 : 0 ] imm_wr_data;
wire  [ 15 : 0 ] imm_wr_data_w;


wire [IMEM_ADDR_WIDTH-1:0] imem_rd_address;
wire imem_rd_req;
wire [INSTRUCTION_WIDTH-1:0] imem_rd_data;

wire [OPCODE_BITS-1 : 0] opcode,opcode_compute;
wire [FUNCTION_BITS-1 : 0] fn,fn_compute;
wire [NS_ID_BITS-1 : 0] dest_ns_id, src1_ns_id, src2_ns_id;
wire [NS_INDEX_ID_BITS-1 : 0] dest_ns_index_id, src1_ns_index_id, src2_ns_index_id;

wire  [ DATA_WIDTH*NUM_ELEM  -1 : 0 ] src1_muxed,src2_muxed;

reg [DATA_WIDTH-1 : 0] src1_data[0:NUM_ELEM-1];
reg [DATA_WIDTH-1 : 0] src2_data[0:NUM_ELEM-1];
wire [DATA_WIDTH-1 : 0] data_compute_out[0:NUM_ELEM-1];
wire [DATA_WIDTH*NUM_ELEM-1:0] compute_out_bus;

wire cond_move_inst,in_nested_loop, in_single_loop;
reg in_nested_loop_d, in_nested_loop_d2, in_nested_loop_d3, in_nested_loop_d4, in_nested_loop_d5, in_nested_loop_d6, in_nested_loop_d7;
reg in_single_loop_d, in_single_loop_d2, in_single_loop_d3, in_single_loop_d4, in_single_loop_d5;
//////////////////////////////////////////////////////
 
//////////////////////////////////
wire [5:0]						iterator_read_req;
wire [5:0]						iterator_write_req_base;
wire [5:0]						iterator_write_req_stride;
wire [5:0]						buffer_write_req;
wire [5:0]						buffer_read_req;
//wire [5:0]						mem_bypass;

//////////////////////////////////
wire [NS_INDEX_ID_BITS-1 :0] iterator_read_addr_out_src0;
wire [NS_INDEX_ID_BITS-1 :0] iterator_read_addr_out_src1;
wire [NS_INDEX_ID_BITS-1 :0] iterator_read_addr_out_dest;

//////////////////////////////////
wire [NS_INDEX_ID_BITS-1 :0] 		iterator_read_addr_0;
wire [NS_INDEX_ID_BITS-1 :0] 		iterator_write_addr_base_0;
wire [BASE_STRIDE_WIDTH-1 : 0]		iterator_data_base_0;
wire [NS_INDEX_ID_BITS-1 :0] 		iterator_write_addr_stride_0;
wire [BASE_STRIDE_WIDTH-1 : 0]		iterator_data_stride_0;
wire [BASE_STRIDE_WIDTH-1 : 0]		base_plus_stride_0;

//////////////////////////////////
wire [NS_INDEX_ID_BITS-1 :0] 		iterator_read_addr_1;
wire [NS_INDEX_ID_BITS-1 :0] 		iterator_write_addr_base_1;
wire [BASE_STRIDE_WIDTH-1 : 0]		iterator_data_base_1;
wire [NS_INDEX_ID_BITS-1 :0] 		iterator_write_addr_stride_1;
wire [BASE_STRIDE_WIDTH-1 : 0]		iterator_data_stride_1;
wire [BASE_STRIDE_WIDTH-1 : 0]		base_plus_stride_1;

//////////////////////////////////
wire [NS_INDEX_ID_BITS-1 :0] 		iterator_read_addr_2;
wire [NS_INDEX_ID_BITS-1 :0] 		iterator_write_addr_base_2;
wire [BASE_STRIDE_WIDTH-1 : 0]		iterator_data_base_2;
wire [NS_INDEX_ID_BITS-1 :0] 		iterator_write_addr_stride_2;
wire [BASE_STRIDE_WIDTH-1 : 0]		iterator_data_stride_2;
wire [BASE_STRIDE_WIDTH-1 : 0]		base_plus_stride_2;

//////////////////////////////////
wire [NS_INDEX_ID_BITS-1 :0] 		iterator_read_addr_3;
wire [NS_INDEX_ID_BITS-1 :0] 		iterator_write_addr_base_3;
wire [BASE_STRIDE_WIDTH-1 : 0]		iterator_data_base_3;
wire [NS_INDEX_ID_BITS-1 :0] 		iterator_write_addr_stride_3;
wire [BASE_STRIDE_WIDTH-1 : 0]		iterator_data_stride_3;
wire [BASE_STRIDE_WIDTH-1 : 0]		base_plus_stride_3;

//////////////////////////////////
wire [NS_INDEX_ID_BITS-1 :0] 		iterator_read_addr_4;
wire [NS_INDEX_ID_BITS-1 :0] 		iterator_write_addr_base_4;
wire [BASE_STRIDE_WIDTH-1 : 0]		iterator_data_base_4;
wire [NS_INDEX_ID_BITS-1 :0] 		iterator_write_addr_stride_4;
wire [BASE_STRIDE_WIDTH-1 : 0]		iterator_data_stride_4;
wire [BASE_STRIDE_WIDTH-1 : 0]		base_plus_stride_4;

//////////////////////////////////
wire [NS_INDEX_ID_BITS-1 :0] 		iterator_read_addr_5;
wire [NS_INDEX_ID_BITS-1 :0] 		iterator_write_addr_base_5;
wire [BASE_STRIDE_WIDTH-1 : 0]		iterator_data_base_5;
wire [NS_INDEX_ID_BITS-1 :0] 		iterator_write_addr_stride_5;
wire [BASE_STRIDE_WIDTH-1 : 0]		iterator_data_stride_5;
wire [BASE_STRIDE_WIDTH-1 : 0]		base_plus_stride_5;
//////////////////////////////////

wire   [FUNCTION_BITS + OPCODE_BITS-1:0]      opcode_fn,opcode_fn_to_iter_mem,opcode_fn_to_mem_stage,opcode_fn_to_mux_stage,opcode_fn_to_compute_stage;
wire   [IMMEDIATE_WIDTH-1:0]      immediate_to_iter_mem,immediate_to_mem_stage,immediate_to_mux_stage,immediate_to_compute_stage,immediate_final;
wire   [7:0]      dest_integer_bits_to_iter_mem, dest_integer_bits_to_mem_stage, dest_integer_bits_to_mux_stage, dest_integer_bits_to_compute_stage;
wire   [7:0]      src1_integer_bits_to_iter_mem, src1_integer_bits_to_mem_stage, src1_integer_bits_to_mux_stage, src1_integer_bits_to_compute_stage;
wire   [7:0]      src2_integer_bits_to_iter_mem, src2_integer_bits_to_mem_stage, src2_integer_bits_to_mux_stage, src2_integer_bits_to_compute_stage;
wire  [NS_ID_BITS-1:0]            src1_ns_id_to_iter_mem,src1_ns_id_to_mem_stage,src1_ns_id_to_mux_stage;
wire  [NS_ID_BITS-1:0]            src2_ns_id_to_iter_mem,src2_ns_id_to_mem_stage,src2_ns_id_to_mux_stage;
wire  [NS_ID_BITS-1:0]            dest_ns_id_to_iter_mem,dest_ns_id_to_mem_stage;
wire  [NS_INDEX_ID_BITS-1:0]      dest_ns_index_id_to_iter_mem, dest_ns_index_id_to_mem_stage, src1_ns_index_id_to_iter_mem,src2_ns_index_id_to_iter_mem;
wire [5:0]						buffer_write_req_to_mem_stage,buffer_write_req_to_mux_stage,buffer_write_req_to_compute_stage, buffer_write_req_to_compute_stage_final;
reg [5:0]                      buffer_write_req_to_compute_stage_d, buffer_write_req_to_compute_stage_d2;
wire [5:0]						buffer_read_req_to_mem_stage, buffer_read_req_to_mem_stage_d, buffer_read_req_to_mem_stage_d_final;
wire [BASE_STRIDE_WIDTH-1 : 0]	    iterator_stride_0;
wire [BASE_STRIDE_WIDTH-1 : 0]	    buffer_address_0_read;
wire [BASE_STRIDE_WIDTH-1 : 0]	    buffer_address_0_write;
wire [BASE_STRIDE_WIDTH-1 : 0]	    iterator_stride_1;
wire [BASE_STRIDE_WIDTH-1 : 0]	    buffer_address_1_read;
wire [BASE_STRIDE_WIDTH-1 : 0]	    buffer_address_1_write;
wire [BASE_STRIDE_WIDTH-1 : 0]	    iterator_stride_2;
wire [BASE_STRIDE_WIDTH-1 : 0]	    buffer_address_2_read;
wire [BASE_STRIDE_WIDTH-1 : 0]	    buffer_address_2_write;
wire [BASE_STRIDE_WIDTH-1 : 0]	    iterator_stride_3;
wire [BASE_STRIDE_WIDTH-1 : 0]	    buffer_address_3_read;
wire [BASE_STRIDE_WIDTH-1 : 0]	    buffer_address_3_write;
wire [BASE_STRIDE_WIDTH-1 : 0]	    iterator_stride_4;
wire [BASE_STRIDE_WIDTH-1 : 0]	    buffer_address_4_read;
wire [BASE_STRIDE_WIDTH-1 : 0]	    buffer_address_4_write;
wire [BASE_STRIDE_WIDTH-1 : 0]	    iterator_stride_5;
wire [BASE_STRIDE_WIDTH-1 : 0]	    buffer_address_5_read;
wire [BASE_STRIDE_WIDTH-1 : 0]	    buffer_address_5_write;
wire [BASE_STRIDE_WIDTH-1 : 0]      buffer_address_read_op1;
wire [BASE_STRIDE_WIDTH-1 : 0]      buffer_address_read_op2; 
wire [BASE_STRIDE_WIDTH-1 : 0]	    buffer_address_write_general;
localparam BUFFERS_WR_ADDR_WIDTH = BASE_STRIDE_WIDTH;
reg [BUFFERS_WR_ADDR_WIDTH-1:0] buffers_wr_addr;
wire [BUFFERS_WR_ADDR_WIDTH*6-1:0] buffers_rd_addr;
wire [BUFFERS_WR_ADDR_WIDTH-1:0] buffers_wr_addr_to_mux_stage,buffers_wr_addr_to_compute_stage,buffers_wr_addr_final;

wire [BASE_STRIDE_WIDTH-1:0] buf_wr_addr_interleaved[0:NUM_ELEM-1];
wire [BASE_STRIDE_WIDTH*6-1:0] buf_rd_addr_interleaved[0:NUM_ELEM-1];
wire [IMM_DATA_WIDTH-1:0] imm_data_interleaved[0:NUM_ELEM-1];
wire [5:0] buf_wr_req_interleaved[NUM_ELEM-1:0];
wire [5:0] buf_rd_req_interleaved[NUM_ELEM-1:0];
reg  [2:0] src1_ns_id_interleaved[NUM_ELEM-1:0];
reg  [2:0] src2_ns_id_interleaved[NUM_ELEM-1:0];

wire nested_loop_done, nested_loop_done_final;
reg  nested_loop_done_d, nested_loop_done_d2, nested_loop_done_d3;

wire                                        stall;
wire                                        ld_mem_simd_done;
wire                                        st_mem_simd_done;                                      
wire [GROUP_ID_W                -1:0]       ld_st_group_id;
wire [MAX_NUM_GROUPS            -1:0]       ld_config_done;
wire [MAX_NUM_GROUPS            -1:0]       st_config_done;    

wire                                        data_shuffle_done;
wire                                        in_ld_st; 
wire                                        in_shuffle;
wire                                        mws_ld_base_vmem1_has_start;
wire                                        mws_ld_base_vmem2_has_start;

wire  [NUM_ELEM        -1:0]               ld_st_vmem1_write_req;
wire  [NUM_ELEM*VMEM_TAG_BUF_ADDR_W-1:0]   ld_st_vmem1_write_addr;
wire  [NUM_ELEM*DATA_WIDTH -1:0]           ld_st_vmem1_write_data;
wire  [NUM_ELEM        -1:0]               ld_st_vmem1_read_req;
wire  [NUM_ELEM*VMEM_TAG_BUF_ADDR_W-1:0]   ld_st_vmem1_read_addr;
wire  [NUM_ELEM*DATA_WIDTH -1:0]           ld_st_vmem1_read_data;

wire  [NUM_ELEM        -1:0]               ld_st_vmem2_write_req;
wire  [NUM_ELEM*VMEM_TAG_BUF_ADDR_W-1:0]   ld_st_vmem2_write_addr;
wire  [NUM_ELEM*DATA_WIDTH -1:0]           ld_st_vmem2_write_data;
wire  [NUM_ELEM        -1:0]               ld_st_vmem2_read_req;
wire  [NUM_ELEM*VMEM_TAG_BUF_ADDR_W-1:0]   ld_st_vmem2_read_addr;
wire  [NUM_ELEM*DATA_WIDTH -1:0]           ld_st_vmem2_read_data;

wire  [NUM_ELEM        -1:0]               shuffle_vmem1_write_req;
wire  [NUM_ELEM*VMEM_TAG_BUF_ADDR_W-1:0]   shuffle_vmem1_write_addr;
wire  [NUM_ELEM*DATA_WIDTH -1:0]           shuffle_vmem1_write_data;
wire  [NUM_ELEM        -1:0]               shuffle_vmem1_read_req;
wire  [NUM_ELEM*VMEM_TAG_BUF_ADDR_W-1:0]   shuffle_vmem1_read_addr;
wire  [NUM_ELEM*DATA_WIDTH -1:0]           shuffle_vmem1_read_data;

wire  [NUM_ELEM        -1:0]               shuffle_vmem2_write_req;
wire  [NUM_ELEM*VMEM_TAG_BUF_ADDR_W-1:0]   shuffle_vmem2_write_addr;
wire  [NUM_ELEM*DATA_WIDTH -1:0]           shuffle_vmem2_write_data;
wire  [NUM_ELEM        -1:0]               shuffle_vmem2_read_req;
wire  [NUM_ELEM*VMEM_TAG_BUF_ADDR_W-1:0]   shuffle_vmem2_read_addr;
wire  [NUM_ELEM*DATA_WIDTH -1:0]           shuffle_vmem2_read_data;

wire  [VMEM_ADDR_WIDTH*NUM_ELEM-1:0]     _vmem_rd_addr1,_vmem_wr_addr1;
wire  [VMEM_ADDR_WIDTH*NUM_ELEM-1:0]     _vmem_rd_addr2,_vmem_wr_addr2;
wire  [NUM_ELEM-1:0] _vmem_rd_req1,_vmem_wr_req1;
wire  [NUM_ELEM-1:0] _vmem_rd_req2,_vmem_wr_req2;
wire  [ DATA_WIDTH*NUM_ELEM  -1 : 0 ] _vmem_data1,_vmem_wr_data1;
wire  [ DATA_WIDTH*NUM_ELEM  -1 : 0 ] _vmem_data2,_vmem_wr_data2;

wire  [(3*NS_ID_BITS + 3*NS_INDEX_ID_BITS)-1:0] current_iterations;

///////////////////////////////////////// Stage 0 ///////////////////////////
///////////////////////////////////////// Instruction Memory ///////////////////////////
ram #(
  .DATA_WIDTH(INSTRUCTION_WIDTH),
  .ADDR_WIDTH(IMEM_ADDR_WIDTH )
) instruction_memory (
  .clk		   (    clk                 ),
  .reset       (	reset               ),

  .read_req    (    imem_rd_req	        ),
  .read_addr   (	imem_rd_address     ),
  .read_data   (	imem_rd_data        ),

  .write_req   (	imem_wr_req         ),
  .write_addr  (	imem_wr_addr        ),
  .write_data  (	imem_wr_data        )
);

//=========================== GROUP START ADDR Buffer=====================
localparam integer INST_GROUP_OPCODE        = 10;
localparam integer INST_GROUP_START         = 0;
localparam integer INST_GROUP_END           = 1;
localparam integer INST_GROUP_SA            = 0;
localparam integer INST_GROUP_SIMD          = 1;

wire                                        group_mem_rd_req;
wire  [ GROUP_ID_W             -1: 0]       group_mem_rd_addr;
wire  [ IMEM_ADDR_WIDTH        -1: 0]       group_mem_rd_data;

wire                                        group_mem_wr_req;
wire  [ GROUP_ID_W             -1: 0]       group_mem_wr_addr;
wire  [ IMEM_ADDR_WIDTH        -1: 0]       group_mem_wr_data;

reg                                         _group_mem_wr_req;
reg  [ GROUP_ID_W             -1: 0]        _group_mem_wr_addr;
reg  [ IMEM_ADDR_WIDTH        -1: 0]        _group_mem_wr_data;

wire                                        group_mem_rd_v;
reg                                         _group_mem_rd_v;

wire                                        inst_group_v;
wire                                        inst_group_id;

assign inst_group_v = imem_wr_req && (imem_wr_data[31:28] == INST_GROUP_OPCODE && imem_wr_data[27] == INST_GROUP_SIMD && imem_wr_data[26] == INST_GROUP_START);
assign inst_group_id = imem_wr_data[25:22];

always @(posedge clk) begin
   if (reset) begin
       _group_mem_wr_req <= 1'b0;
       _group_mem_wr_addr <= 0;
       _group_mem_wr_data <= 0;
   end 
   else begin
       _group_mem_wr_req <= inst_group_v;
       _group_mem_wr_addr <= inst_group_id;
       _group_mem_wr_data <= imem_wr_addr;    
   end 
end

assign group_mem_wr_req = _group_mem_wr_req;
assign group_mem_wr_addr = _group_mem_wr_addr;
assign group_mem_wr_data = _group_mem_wr_data;

ram #(
  .DATA_WIDTH(IMEM_ADDR_WIDTH),
  .ADDR_WIDTH(GROUP_ID_W )
) group_start_addr_memory (
  .clk         (    clk                 ),
  .reset       (    reset               ),

  .read_req    (    group_mem_rd_req         ),
  .read_addr   (    group_mem_rd_addr        ),
  .read_data   (    group_mem_rd_data        ),

  .write_req   (    group_mem_wr_req         ),
  .write_addr  (    group_mem_wr_addr        ),
  .write_data  (    group_mem_wr_data        )
);

always @(posedge clk) begin
   if (reset) 
       _group_mem_rd_v <= 1'b0;
   else
       _group_mem_rd_v <= group_mem_rd_req;
end
assign group_mem_rd_v = _group_mem_rd_v;
///////////////////////////////////////// Stage 1 ///////////////////////////
///////////////////////////////////////// Instruction Decode ///////////////////////////

/* Splits the instruction, processes loop instruction and generates rd address */
SIMD_instruction_decoder #(   
    .NS_ID_BITS         ( NS_ID_BITS            ), 
    .NS_INDEX_ID_BITS   ( NS_INDEX_ID_BITS      ),
    .OPCODE_BITS        ( OPCODE_BITS           ),
    .FUNCTION_BITS      ( FUNCTION_BITS         ),
    .GROUP_ID_W         ( GROUP_ID_W            ),
    .INSTRUCTION_WIDTH  ( INSTRUCTION_WIDTH     ),
    
    .IMEM_ADDR_WIDTH    ( IMEM_ADDR_WIDTH       ),
    .PC_DATA_WIDTH      (PC_DATA_WIDTH)
       
) SIMD_inst_decoder (
	.clk				(	clk          	    ),
	.reset              (	reset        	    ),

	.start              (	start        	    ),
    .in_fusion          (   in_fusion           ),
	
	.group_id_s         (   group_id_s          ),
	
    .data_shuffle_done  (   data_shuffle_done   ),
	.in_ld_st           (   in_ld_st            ),
    .in_shuffle         (   in_shuffle          ),

	.instruction_in     (	imem_rd_data	    ),
	.instruction_in_v   (	1'b1         	    ),
	
	.group_buf_rd_data  (   group_mem_rd_data   ),
	.group_buf_rd_v     (   group_mem_rd_v      ),
	.group_buf_rd_req   (   group_mem_rd_req    ),
	.group_buf_rd_addr  (   group_mem_rd_addr   ),

    .mws_ld_base_vmem1_has_start        ( mws_ld_base_vmem1_has_start ),
    .mws_ld_base_vmem2_has_start        ( mws_ld_base_vmem2_has_start ),  
	.ld_mem_simd_done   (   ld_mem_simd_done    ),
	.st_mem_simd_done   (   st_mem_simd_done    ),
    .simd_tiles_done    (   simd_tiles_done     ),

	.ld_config_done     (   ld_config_done      ),
	.st_config_done     (   st_config_done      ),
	.ld_st_group_id     (   ld_st_group_id      ),
	
	.stall              (   stall               ),
	
	.ready              (   ready               ),
	
	.imem_rd_address    (	imem_rd_address	    ),
	.imem_rd_req        (	imem_rd_req  	    ),

	.opcode             (	opcode           	),
	.fn                 (	fn               	),

	.dest_ns_id         (	dest_ns_id      	),
	.dest_ns_index_id   (	dest_ns_index_id	),

	.src1_ns_id         (	src1_ns_id      	),
	.src1_ns_index_id   (	src1_ns_index_id	),

	.src2_ns_id         (	src2_ns_id      	),
	.src2_ns_index_id   (	src2_ns_index_id	),
	
	.dest_integer_bits  (   dest_integer_bits_to_iter_mem   ),
    .src1_integer_bits  (   src1_integer_bits_to_iter_mem   ),
    .src2_integer_bits  (   src2_integer_bits_to_iter_mem   ),
	
	.nested_loop_done       (   nested_loop_done        ),
	.nested_loop_done_final (   nested_loop_done_final  ),
	
	.in_nested_loop     (   in_nested_loop             ),
    .in_single_loop     (   in_single_loop             ),
    .buf_done           (   buf_done            ),
	.done               (   done                ),
	.group_id           (   group_id            ),

    .current_iterations (current_iterations),
    .pc_simd_tot_compute (pc_simd_tot_compute)
);

always @(posedge clk) begin
    in_single_loop_d <= in_single_loop;
    in_single_loop_d2 <= in_single_loop_d;
    in_single_loop_d3 <= in_single_loop_d2;
    in_single_loop_d4 <= in_single_loop_d3;
    in_single_loop_d5 <= in_single_loop_d4;

    in_nested_loop_d <= in_nested_loop;
    in_nested_loop_d2 <= in_nested_loop_d;
    in_nested_loop_d3 <= in_nested_loop_d2;
    in_nested_loop_d4 <= in_nested_loop_d3;
    in_nested_loop_d5 <= in_nested_loop_d4;
    in_nested_loop_d6 <= in_nested_loop_d5;
    in_nested_loop_d7 <= in_nested_loop_d6;
end

// ************ SIMD LD/ST Interface *******************

simd_ld_st_interface_flexible #(
    .NUM_TAGS                           ( NUM_TAGS              ),
    .SIMD_DATA_WIDTH                    ( DATA_WIDTH            ),
    .LD_ST_LOW_DATA_WIDTH               ( LD_ST_LOW_DATA_WIDTH  ),
    .AXI_ADDR_WIDTH                     ( C_M_AXI_ADDR_WIDTH    ),
    .AXI_DATA_WIDTH                     ( C_M_AXI_DATA_WIDTH    ),
    .AXI_BURST_WIDTH                    ( AXI_BURST_WIDTH       ),
    .WSTRB_W                            ( WSTRB_W               ),
    .NUM_SIMD_LANES                     ( NUM_ELEM              ),
    .VMEM_BUF_ADDR_W                    ( VMEM_ADDR_WIDTH       ),
    .BASE_ADDR_SEGMENT_W                ( BASE_ADDR_SEGMENT_W   ),
    .ADDR_WIDTH                         ( BASE_ADDR_WIDTH       ),
    .PC_DATA_WIDTH                      (PC_DATA_WIDTH          )
) ld_st_interface_inst (
    .clk                                ( clk                   ),
    .reset                              ( reset                 ),    
    .block_done                         ( block_done            ),
    
    .opcode                             ( opcode                ),
    .fn                                 ( fn                    ),
    .dest_ns_id                         ( dest_ns_id            ),
    .dest_ns_index_id                   ( dest_ns_index_id      ),
    .src1_ns_id                         ( src1_ns_id            ),
    .src1_ns_index_id                   ( src1_ns_index_id      ),
    .src2_ns_id                         ( src2_ns_id            ),
    .src2_ns_index_id                   ( src2_ns_index_id      ),
    
    .ld_config_done                     ( ld_config_done        ),
    .st_config_done                     ( st_config_done        ),
    .ld_st_group_id                     ( ld_st_group_id        ),
    .ld_mem_simd_done                   ( ld_mem_simd_done      ),
    .st_mem_simd_done                   ( st_mem_simd_done      ),
    
    .vmem1_write_req                    ( ld_st_vmem1_write_req ),
    .vmem1_write_addr                   ( ld_st_vmem1_write_addr),
    .vmem1_write_data                   ( ld_st_vmem1_write_data),
    .vmem1_read_req                     ( ld_st_vmem1_read_req  ),
    .vmem1_read_addr                    ( ld_st_vmem1_read_addr ),
    .vmem1_read_data                    ( ld_st_vmem1_read_data ),
    
    .vmem2_write_req                    ( ld_st_vmem2_write_req ),
    .vmem2_write_addr                   ( ld_st_vmem2_write_addr),
    .vmem2_write_data                   ( ld_st_vmem2_write_data),
    .vmem2_read_req                     ( ld_st_vmem2_read_req  ),
    .vmem2_read_addr                    ( ld_st_vmem2_read_addr ),
    .vmem2_read_data                    ( ld_st_vmem2_read_data ),    
    
    .simd_tiles_done                    ( simd_tiles_done       ),
    .mws_ld_base_vmem1_has_start        ( mws_ld_base_vmem1_has_start ),
    .mws_ld_base_vmem2_has_start        ( mws_ld_base_vmem2_has_start ),    

    .mws_awaddr                         ( mws_awaddr            ),
    .mws_awlen                          ( mws_awlen             ),
    .mws_awvalid                        ( mws_awvalid           ),
    .mws_awready                        ( mws_awready           ),
    .mws_wdata                          ( mws_wdata             ),
    .mws_wstrb                          ( mws_wstrb             ),
    .mws_wlast                          ( mws_wlast             ),
    .mws_wvalid                         ( mws_wvalid            ),
    .mws_wready                         ( mws_wready            ),
    .mws_bvalid                         ( mws_bvalid            ),
    .mws_bready                         ( mws_bready            ),
    .mws_araddr                         ( mws_araddr            ),
    .mws_arlen                          ( mws_arlen             ),
    .mws_arvalid                        ( mws_arvalid           ),
    .mws_arready                        ( mws_arready           ),
    .mws_rdata                          ( mws_rdata             ),
    .mws_rlast                          ( mws_rlast             ),
    .mws_rvalid                         ( mws_rvalid            ),
    .mws_rready                         ( mws_rready            ),
    .simd_base_offset                   (simd_base_offset       ),

    .pc_simd_ld_num_tiles_vmem1         (pc_simd_ld_num_tiles_vmem1),
    .pc_simd_ld_num_tiles_vmem2         (pc_simd_ld_num_tiles_vmem2),
    .pc_simd_ld_tot_cycles_vmem1        (pc_simd_ld_tot_cycles_vmem1),  
    .pc_simd_ld_tot_requests_vmem1      (pc_simd_ld_tot_requests_vmem1),
    .pc_simd_ld_size_per_requests_vmem1 (pc_simd_ld_size_per_requests_vmem1),
    .pc_simd_ld_tot_cycles_vmem2        (pc_simd_ld_tot_cycles_vmem2),  
    .pc_simd_ld_tot_requests_vmem2      (pc_simd_ld_tot_requests_vmem2),
    .pc_simd_ld_size_per_requests_vmem2 (pc_simd_ld_size_per_requests_vmem2),

    .pc_simd_st_num_tiles_vmem1         (pc_simd_st_num_tiles_vmem1),
    .pc_simd_st_num_tiles_vmem2         (pc_simd_st_num_tiles_vmem2),
    .pc_simd_st_tot_cycles              (pc_simd_st_tot_cycles),  
    .pc_simd_st_tot_requests            (pc_simd_st_tot_requests),
    .pc_simd_st_size_per_requests       (pc_simd_st_size_per_requests)
);

iterator_address_gen_new #(
    .NS_ID_BITS         ( NS_ID_BITS            ), 
    .NS_INDEX_ID_BITS   ( NS_INDEX_ID_BITS      ),
    .OPCODE_BITS        ( OPCODE_BITS           ),
    .FUNCTION_BITS      ( FUNCTION_BITS         )
) iterator_address_gen_inst (
	.clk				(	clk          	    ),
	.reset              (	reset        	    ),

	.opcode             (	opcode           	),
	.fn                 (	fn               	),

	.dest_ns_id         (	dest_ns_id      	),
	.dest_ns_index_id   (	dest_ns_index_id	),

	.src1_ns_id         (	src1_ns_id      	),
	.src1_ns_index_id   (	src1_ns_index_id	),

	.src2_ns_id         (	src2_ns_id      	),
	.src2_ns_index_id   (	src2_ns_index_id	),
	
    .in_single_loop     (   in_single_loop             ),
	
	.iterator_stride_0		            (	iterator_stride_0		        ),
    .iterator_base_0		            (	buffer_address_0_read	        ),

    .iterator_stride_1		            (	iterator_stride_1		        ),
    .iterator_base_1		            (	buffer_address_1_read	        ),

    .iterator_stride_2		            (	iterator_stride_2		        ),
    .iterator_base_2		            (	buffer_address_2_read	        ),

    .iterator_stride_3		            (	iterator_stride_3		        ),
    .iterator_base_3		            (	buffer_address_3_read	        ),

    .iterator_stride_4		            (	iterator_stride_4		        ),
    .iterator_base_4		            (	buffer_address_4_read	        ),

    .iterator_stride_5		            (	iterator_stride_5		        ),
    .iterator_base_5		            (	buffer_address_5_read	        ),
	
    ////////////////////////////////// outputs  ////////////////////////    
    .iterator_read_req_out              (	iterator_read_req               ),
    .iterator_write_req_base_out        (	iterator_write_req_base         ),
    .iterator_write_req_stride_out      (	iterator_write_req_stride       ),

    .buffer_write_req                   (	buffer_write_req                ),
    .buffer_read_req                    (	buffer_read_req                 ),
    //.mem_bypass                         (	mem_bypass                      ),

    .iterator_read_addr_out_src0        (   iterator_read_addr_out_src0     ),
    .iterator_read_addr_out_src1        (   iterator_read_addr_out_src1     ),
    .iterator_read_addr_out_dest        (   iterator_read_addr_out_dest     ),

    .iterator_write_addr_base_out_0     (	iterator_write_addr_base_0      ),
    .iterator_data_in_base_out_0        (	iterator_data_base_0            ),
    .iterator_write_addr_stride_out_0   (	iterator_write_addr_stride_0    ),
    .iterator_data_in_stride_out_0      (	iterator_data_stride_0          ),
    .base_plus_stride_out_0             (	base_plus_stride_0              ),

    .iterator_write_addr_base_out_1     (	iterator_write_addr_base_1      ),
    .iterator_data_in_base_out_1        (	iterator_data_base_1            ),
    .iterator_write_addr_stride_out_1   (	iterator_write_addr_stride_1    ),
    .iterator_data_in_stride_out_1      (	iterator_data_stride_1          ),
    .base_plus_stride_out_1             (	base_plus_stride_1              ),

    .iterator_write_addr_base_out_2     (	iterator_write_addr_base_2      ),
    .iterator_data_in_base_out_2        (	iterator_data_base_2            ),
    .iterator_write_addr_stride_out_2   (	iterator_write_addr_stride_2    ),
    .iterator_data_in_stride_out_2      (	iterator_data_stride_2          ),
    .base_plus_stride_out_2             (	base_plus_stride_2              ),

    .iterator_write_addr_base_out_3     (	iterator_write_addr_base_3      ),
    .iterator_data_in_base_out_3        (	iterator_data_base_3            ),
    .iterator_write_addr_stride_out_3   (	iterator_write_addr_stride_3    ),
    .iterator_data_in_stride_out_3      (	iterator_data_stride_3          ),
    .base_plus_stride_out_3             (	base_plus_stride_3              ),

    .iterator_write_addr_base_out_4     (	iterator_write_addr_base_4      ),
    .iterator_data_in_base_out_4        (	iterator_data_base_4            ),
    .iterator_write_addr_stride_out_4	(	iterator_write_addr_stride_4    ),
    .iterator_data_in_stride_out_4      (	iterator_data_stride_4          ),
    .base_plus_stride_out_4             (   base_plus_stride_4              ),

    .iterator_write_addr_base_out_5     (	iterator_write_addr_base_5      ),
    .iterator_data_in_base_out_5        (	iterator_data_base_5            ),
    .iterator_write_addr_stride_out_5	(	iterator_write_addr_stride_5    ),
    .iterator_data_in_stride_out_5      (	iterator_data_stride_5          ),
    .base_plus_stride_out_5             (   base_plus_stride_5              ),
	
    .immediate_out                      (   immediate_to_iter_mem           )
);

assign opcode_fn = {opcode,fn};

pipeline #( .NUM_BITS	( FUNCTION_BITS + OPCODE_BITS	), .NUM_STAGES	( 1	), .EN_RESET   ( 0 ) ) opcode_fn_delay1 (
    .clk		(	clk		    ), .rst		(	reset		), .data_in	(	opcode_fn	), .data_out	(	opcode_fn_to_iter_mem    ) );

pipeline #( .NUM_BITS	( NS_ID_BITS	), .NUM_STAGES	( 1	), .EN_RESET   ( 0 ) ) dest_ns_id_delay1 (
    .clk		(	clk		    ), .rst		(	reset		), .data_in	(	dest_ns_id	), .data_out	(	dest_ns_id_to_iter_mem    ) );

pipeline #( .NUM_BITS	( NS_ID_BITS	), .NUM_STAGES	( 1	), .EN_RESET   ( 0 ) ) src1_sel_delay1 (
    .clk		(	clk		    ), .rst		(	reset		), .data_in	(	src1_ns_id	), .data_out	(	src1_ns_id_to_iter_mem    ) );

pipeline #( .NUM_BITS	( NS_ID_BITS	), .NUM_STAGES	( 1	), .EN_RESET   ( 0 ) ) src2_sel_delay1 (
    .clk		(	clk		    ), .rst		(	reset		), .data_in	(	src2_ns_id	), .data_out	(	src2_ns_id_to_iter_mem    ) );

pipeline #( .NUM_BITS	( NS_INDEX_ID_BITS	), .NUM_STAGES	( 1	), .EN_RESET   ( 0 ) ) dest_ns_index_id_delay (
   .clk		(	clk		    ), .rst		(	reset		), .data_in	(	dest_ns_index_id	), .data_out	(	dest_ns_index_id_to_iter_mem    ) );

pipeline #( .NUM_BITS	( NS_INDEX_ID_BITS	), .NUM_STAGES	( 2	), .EN_RESET   ( 0 ) ) dest_ns_index_id_delay_4 (
   .clk		(	clk		    ), .rst		(	reset		), .data_in	(	dest_ns_index_id	), .data_out	(	dest_ns_index_id_to_mem_stage   ) );

pipeline #( .NUM_BITS	( NS_INDEX_ID_BITS	), .NUM_STAGES	( 1	), .EN_RESET   ( 0 ) ) src1_index_id_delay (
   .clk		(	clk		    ), .rst		(	reset		), .data_in	(	src1_ns_index_id	), .data_out	(	src1_ns_index_id_to_iter_mem    ) );

pipeline #( .NUM_BITS	( NS_INDEX_ID_BITS	), .NUM_STAGES	( 1	), .EN_RESET   ( 0 ) ) src2_index_id_delay (
   .clk		(	clk		    ), .rst		(	reset		), .data_in	(	src2_ns_index_id	), .data_out	(	src2_ns_index_id_to_iter_mem    ) );       


///////////////////////////////////////// Stage 2 ///////////////////////////
///////////////////////////////////////// Iterator memories ///////////////////////////
// iterator_memories #(
iterator_memories_flexible_ns #(
    .NUM_ELEM           ( NUM_ELEM              ),
    .NS_ID_BITS         ( NS_ID_BITS            ), 
    .NS_INDEX_ID_BITS   ( NS_INDEX_ID_BITS      ),
    .OPCODE_BITS        ( OPCODE_BITS           ),
    .FUNCTION_BITS      ( FUNCTION_BITS         ),
    .IMMEDIATE_WIDTH    ( IMMEDIATE_WIDTH       )
) iterator_memory_inst (
	.clk				(	clk          	    ),
	.reset              (	reset        	    ),

    .opcode             (   opcode_fn_to_iter_mem[FUNCTION_BITS+:OPCODE_BITS]  ),
    .fn                 (   opcode_fn_to_iter_mem[FUNCTION_BITS-1 : 0]  ),

    .dest_ns_id         (	dest_ns_id_to_iter_mem      	),
	.dest_ns_index_id   (	dest_ns_index_id_to_iter_mem	),

	.src1_ns_id         (	src1_ns_id_to_iter_mem      	),
	.src1_ns_index_id   (	src1_ns_index_id_to_iter_mem	),

	.src2_ns_id         (	src2_ns_id_to_iter_mem      	),
	.src2_ns_index_id   (	src2_ns_index_id_to_iter_mem	),

    .loop_id            (   dest_ns_id_to_iter_mem          ),
    .immediate          (   immediate_to_iter_mem           ),
    .iterator_read_req					(	iterator_read_req				),
    .iterator_write_req_base            (	iterator_write_req_base         ),
    .iterator_write_req_stride          (	iterator_write_req_stride       ),
    //.mem_bypass                         (	mem_bypass                      ),
    
    .in_nested_loop     (   in_nested_loop || in_nested_loop_d5 ),
    .in_single_loop     (   in_single_loop                      ),
    .current_iterations (   current_iterations                  ),
    
    .iterator_read_addr_out_src0(iterator_read_addr_out_src0),
    .iterator_read_addr_out_src1(iterator_read_addr_out_src1),
    .iterator_read_addr_out_dest(iterator_read_addr_out_dest),

    //.iterator_read_addr_in_0            (	iterator_read_addr_0            ),
    .iterator_write_addr_base_in_0      (	iterator_write_addr_base_0      ),
    .iterator_data_in_base_in_0         (	iterator_data_base_0            ),
    .iterator_write_addr_stride_in_0    (	iterator_write_addr_stride_0    ),
    .iterator_data_in_stride_in_0       (	iterator_data_stride_0          ),
    .base_plus_stride_in_0              (	base_plus_stride_0              ),
    
    //.iterator_read_addr_in_1            (	iterator_read_addr_1            ),
    .iterator_write_addr_base_in_1      (	iterator_write_addr_base_1      ),
    .iterator_data_in_base_in_1         (	iterator_data_base_1            ),
    .iterator_write_addr_stride_in_1    (	iterator_write_addr_stride_1    ),
    .iterator_data_in_stride_in_1       (	iterator_data_stride_1          ),
    .base_plus_stride_in_1              (	base_plus_stride_1              ),
    
    //.iterator_read_addr_in_2            (	iterator_read_addr_2            ),
    .iterator_write_addr_base_in_2      (	iterator_write_addr_base_2      ),
    .iterator_data_in_base_in_2         (	iterator_data_base_2            ),
    .iterator_write_addr_stride_in_2    (	iterator_write_addr_stride_2    ),
    .iterator_data_in_stride_in_2       (	iterator_data_stride_2          ),
    .base_plus_stride_in_2              (	base_plus_stride_2              ),
    
    //.iterator_read_addr_in_3            (	iterator_read_addr_3            ),
    .iterator_write_addr_base_in_3      (	iterator_write_addr_base_3      ),
    .iterator_data_in_base_in_3         (	iterator_data_base_3            ),
    .iterator_write_addr_stride_in_3    (	iterator_write_addr_stride_3    ),
    .iterator_data_in_stride_in_3       (	iterator_data_stride_3          ),
    .base_plus_stride_in_3              (	base_plus_stride_3              ),
    
    //.iterator_read_addr_in_4            (	iterator_read_addr_4            ),
    .iterator_write_addr_base_in_4      (	iterator_write_addr_base_4      ),
    .iterator_data_in_base_in_4         (	iterator_data_base_4            ),
    .iterator_write_addr_stride_in_4    (	iterator_write_addr_stride_4    ),
    .iterator_data_in_stride_in_4       (	iterator_data_stride_4          ),
    .base_plus_stride_in_4              (	base_plus_stride_4              ),
     
    //.iterator_read_addr_in_5            (	iterator_read_addr_5            ),
    .iterator_write_addr_base_in_5      (	iterator_write_addr_base_5      ),
    .iterator_data_in_base_in_5         (	iterator_data_base_5            ),
    .iterator_write_addr_stride_in_5    (	iterator_write_addr_stride_5    ),
    .iterator_data_in_stride_in_5       (	iterator_data_stride_5          ),
    .base_plus_stride_in_5              (	base_plus_stride_5              ),       
    
    /////////////////////////////outputs
    .iterator_stride_0                  (	iterator_stride_0               ),
    .iterator_stride_1                  (	iterator_stride_1               ),
    .iterator_stride_2                  (	iterator_stride_2               ),
    .iterator_stride_3                  (	iterator_stride_3               ),
    .iterator_stride_4                  (	iterator_stride_4               ),
	.iterator_stride_5                  (	iterator_stride_5               ),

    .buffer_address_0_read              (	buffer_address_0_read           ),
    .buffer_address_1_read              (	buffer_address_1_read           ),
    .buffer_address_2_read              (	buffer_address_2_read           ),
    .buffer_address_3_read              (	buffer_address_3_read           ),
    .buffer_address_4_read              (	buffer_address_4_read           ),
    .buffer_address_5_read              (	buffer_address_5_read           ),

    .buffer_address_0_write             (	buffer_address_0_write          ),
    .buffer_address_1_write             (	buffer_address_1_write          ),
    .buffer_address_2_write             (	buffer_address_2_write          ),
    .buffer_address_3_write             (	buffer_address_3_write          ),
    .buffer_address_4_write             (	buffer_address_4_write          ),
    .buffer_address_5_write             (	buffer_address_5_write          ),

    .buffer_address_read_op1            (   buffer_address_read_op1         ),
    .buffer_address_read_op2            (   buffer_address_read_op2         ),
    .buffer_address_write_general       (   buffer_address_write_general    ),

    .loop_done_out                      (   nested_loop_done                ),
    .loop_done_final                    (   nested_loop_done_final          )
);

pipeline #( .NUM_BITS	( FUNCTION_BITS + OPCODE_BITS	), .NUM_STAGES	( 1	), .EN_RESET   ( 0 ) ) opcode_fn_delay2 (
    .clk		(	clk		    ), .rst		(	reset		), .data_in	(	opcode_fn_to_iter_mem	), .data_out	(	opcode_fn_to_mem_stage    ) );

pipeline #( .NUM_BITS	( NS_ID_BITS	), .NUM_STAGES	( 1	), .EN_RESET   ( 0 ) ) dest_ns_id_delay2 (
    .clk		(	clk		    ), .rst		(	reset		), .data_in	(	dest_ns_id_to_iter_mem	), .data_out	(	dest_ns_id_to_mem_stage    ) );

pipeline #( .NUM_BITS	( NS_ID_BITS	), .NUM_STAGES	( 1	), .EN_RESET   ( 0 ) ) src1_ns_id_delay2 (
    .clk		(	clk		    ), .rst		(	reset		), .data_in	(	src1_ns_id_to_iter_mem	), .data_out	(	src1_ns_id_to_mem_stage    ) );

pipeline #( .NUM_BITS	( NS_ID_BITS	), .NUM_STAGES	( 1	), .EN_RESET   ( 0 ) ) src2_ns_id_delay2 (
    .clk		(	clk		    ), .rst		(	reset		), .data_in	(	src2_ns_id_to_iter_mem	), .data_out	(	src2_ns_id_to_mem_stage    ) );

pipeline #( .NUM_BITS	( IMMEDIATE_WIDTH	), .NUM_STAGES	( 1	), .EN_RESET   ( 0 ) ) immediate_delay2 (
    .clk		(	clk		    ), .rst		(	reset		), .data_in	(	immediate_to_iter_mem	), .data_out	(	immediate_to_mem_stage    ) );

pipeline #( .NUM_BITS	( 6	), .NUM_STAGES	( 1	), .EN_RESET   ( 0 ) ) buffer_wr_req_delay (
    .clk		(	clk		    ), .rst		(	reset		), .data_in	(	buffer_write_req	), .data_out	(	buffer_write_req_to_mem_stage    ) );

pipeline #( .NUM_BITS	( 6	), .NUM_STAGES	( 1	), .EN_RESET   ( 0 ) ) buffer_rd_req_delay (
    .clk		(	clk		    ), .rst		(	reset		), .data_in	(	buffer_read_req	), .data_out	(	buffer_read_req_to_mem_stage    ) );

pipeline #( .NUM_BITS	( 6	), .NUM_STAGES	( 1	), .EN_RESET   ( 0 ) ) buffer_rd_req_delay2 (
    .clk		(	clk		    ), .rst		(	reset		), .data_in	(	buffer_read_req_to_mem_stage	), .data_out	(	buffer_read_req_to_mem_stage_d    ) );

pipeline #( .NUM_BITS	( 8	), .NUM_STAGES	( 1	), .EN_RESET   ( 0 ) ) dest_integer_bits_delay2 (
    .clk		(	clk		    ), .rst		(	reset		), .data_in	(	dest_integer_bits_to_iter_mem	), .data_out	(	dest_integer_bits_to_mem_stage    ) );

pipeline #( .NUM_BITS	( 8	), .NUM_STAGES	( 1	), .EN_RESET   ( 0 ) ) src1_integer_bits_delay2 (
    .clk		(	clk		    ), .rst		(	reset		), .data_in	(	src1_integer_bits_to_iter_mem	), .data_out	(	src1_integer_bits_to_mem_stage    ) );

pipeline #( .NUM_BITS	( 8	), .NUM_STAGES	( 1	), .EN_RESET   ( 0 ) ) src2_integer_bits_delay2 (
    .clk		(	clk		    ), .rst		(	reset		), .data_in	(	src2_integer_bits_to_iter_mem	), .data_out	(	src2_integer_bits_to_mem_stage    ) );


///////////////////////////////////////// Stage 3 ///////////////////////////
///////////////////////////////////////// memories ///////////////////////////

// Special Logic to handle nested loop read/write delay to vmems
////////////////////////////////////////////
////////////////////////////////////////////
wire [5:0] nested_loop_read_flag;
assign nested_loop_read_flag = {6{~nested_loop_done_d}};

always @(posedge clk) begin
    nested_loop_done_d <= nested_loop_done;
    nested_loop_done_d2 <= nested_loop_done_d;
    nested_loop_done_d3 <= nested_loop_done_d2;
end
assign buffer_read_req_to_mem_stage_d_final = buffer_read_req_to_mem_stage_d & nested_loop_read_flag;

wire [5:0] nested_loop_write_flag;
assign nested_loop_write_flag = {6{~nested_loop_done_d3}};
assign buffer_write_req_to_compute_stage_final = buffer_write_req_to_compute_stage_d2 & nested_loop_write_flag;
////////////////////////////////////////////
////////////////////////////////////////////
////////////////////////////////////////////

assign buffers_rd_addr = {buffer_address_5_read,buffer_address_4_read,buffer_address_3_read,buffer_address_2_read,buffer_address_1_read,buffer_address_0_read}; // same clock cycle as buffer_rd_req
generate 
for(genvar i = 0 ; i< NUM_ELEM ; i=i+1) begin : SIMD_RD
    reg [5:0] buf_rd_req;
    reg [BASE_STRIDE_WIDTH*6-1:0] buf_rd_addr;
    reg [IMM_DATA_WIDTH-1:0] imm_data_w;
    if(INTERLEAVE == 0) begin
        always @(*) begin
            buf_rd_req = buffer_read_req_to_mem_stage_d_final; // DEBUG (in_single_loop || in_single_loop_d3 || in_nested_loop || in_nested_loop_d5) ? buffer_read_req_to_mem_stage_d : buffer_read_req_to_mem_stage;
            buf_rd_addr = buffers_rd_addr;
            imm_data_w = imm_mem_out;
        end
    end
    else begin
        if( i == 0) begin
            always @(*) begin
                buf_rd_req = buffer_read_req_to_mem_stage_d_final; // DEBUG (in_single_loop || in_single_loop_d3 || in_nested_loop || in_nested_loop_d5) ? buffer_read_req_to_mem_stage_d : buffer_read_req_to_mem_stage;
                buf_rd_addr = buffers_rd_addr;
                imm_data_w = imm_mem_out;
            end
        end else begin
            always @(posedge clk) begin
                buf_rd_req <= SIMD_RD[i-1].buf_rd_req;
                buf_rd_addr <= SIMD_RD[i-1].buf_rd_addr;
                imm_data_w <= SIMD_RD[i-1].imm_data_w;
            end
        end
    end
    assign buf_rd_addr_interleaved[i] = buf_rd_addr;
    assign buf_rd_req_interleaved[i] = buf_rd_req;
    assign imm_data_interleaved[i] = imm_data_w;
end
endgenerate

/*
wire  [63:0]                obuf_data_test [31:0];
wire  [63:0]                obuf_rd_addr_test [31:0];
wire  [63:0]                obuf_rd_req_test;
*/

generate // Not sure about the implmentation here, what if the VMEM and OBUF Width is different, will the bits collide?
    for(genvar i = 0; i< NUM_ELEM; i= i+1) begin
        // assign obuf_rd_addr_test[i] = buf_rd_addr_interleaved[i][BASE_STRIDE_WIDTH*OBUF_ISA_NS_INDEX+: OBUF_ADDR_WIDTH];
        assign obuf_rd_addr[OBUF_ADDR_WIDTH*i+: OBUF_ADDR_WIDTH] = buf_rd_addr_interleaved[i][BASE_STRIDE_WIDTH*OBUF_ISA_NS_INDEX+: OBUF_ADDR_WIDTH];
        assign vmem_rd_addr1[VMEM_ADDR_WIDTH*i+: VMEM_ADDR_WIDTH] = buf_rd_addr_interleaved[i][BASE_STRIDE_WIDTH*VMEM1_ISA_NS_INDEX+: VMEM_ADDR_WIDTH];
        assign vmem_rd_addr2[VMEM_ADDR_WIDTH*i+: VMEM_ADDR_WIDTH] = buf_rd_addr_interleaved[i][BASE_STRIDE_WIDTH*VMEM2_ISA_NS_INDEX+: VMEM_ADDR_WIDTH];
        assign imm_data[IMM_DATA_WIDTH*i+: IMM_DATA_WIDTH] = imm_data_interleaved[i];
        
        // assign obuf_rd_req_test[i] = buf_rd_req_interleaved[i][OBUF_ISA_NS_INDEX];
        assign obuf_rd_req[i] = buf_rd_req_interleaved[i][OBUF_ISA_NS_INDEX];
        assign vmem_rd_req1[i] = buf_rd_req_interleaved[i][VMEM1_ISA_NS_INDEX];
        assign vmem_rd_req2[i] = buf_rd_req_interleaved[i][VMEM2_ISA_NS_INDEX];
    end
endgenerate

// This need to be delayed, buffer_address_0 has the same clock cycle with buffer_wr_req not buffer_write_req_to_mem_stage
always @(*) begin
    case(dest_ns_id_to_mem_stage)
        3'b000: buffers_wr_addr = buffer_address_0_write;
        3'b001: buffers_wr_addr = buffer_address_1_write;
        3'b010: buffers_wr_addr = buffer_address_2_write;
        3'b011: buffers_wr_addr = buffer_address_3_write;
        3'b100: buffers_wr_addr = buffer_address_4_write;
        default: buffers_wr_addr = buffer_address_5_write;
    endcase
end

///////////////////// Vector_Memory and IMM Memory /////////////////////////
///////////////////// Vector_Memory and IMM Memory /////////////////////////
///////////////////// Vector_Memory and IMM Memory /////////////////////////
///////////////////// Vector_Memory and IMM Memory /////////////////////////
///////////////////// Vector_Memory and IMM Memory /////////////////////////
///////////////////// Vector_Memory and IMM Memory /////////////////////////

assign _vmem_rd_req1 = in_ld_st ? ld_st_vmem1_read_req : in_shuffle ? shuffle_vmem1_read_req :  vmem_rd_req1;
assign _vmem_rd_addr1 =  in_ld_st ? ld_st_vmem1_read_addr : in_shuffle ? shuffle_vmem1_read_addr : vmem_rd_addr1; 
assign vmem_data1 = _vmem_data1;
assign ld_st_vmem1_read_data = _vmem_data1;
assign shuffle_vmem1_read_data = _vmem_data1;

assign _vmem_wr_req1 = in_ld_st ? ld_st_vmem1_write_req : in_shuffle ? shuffle_vmem1_write_req : vmem_wr_req1;
assign _vmem_wr_addr1 = in_ld_st ? ld_st_vmem1_write_addr : in_shuffle ? shuffle_vmem1_write_addr : vmem_wr_addr1;
assign _vmem_wr_data1 = in_ld_st ? ld_st_vmem1_write_data : in_shuffle ? shuffle_vmem1_write_data : vmem_wr_data1;

assign _vmem_rd_req2 = in_ld_st ? ld_st_vmem2_read_req : in_shuffle ? shuffle_vmem2_read_req : vmem_rd_req2;
assign _vmem_rd_addr2 =  in_ld_st ? ld_st_vmem2_read_addr : in_shuffle ? shuffle_vmem2_read_addr : vmem_rd_addr2;
assign vmem_data2 = _vmem_data2;
assign ld_st_vmem2_read_data = _vmem_data2;
assign shuffle_vmem2_read_data = _vmem_data2;

assign _vmem_wr_req2 = in_ld_st ? ld_st_vmem2_write_req : in_shuffle ? shuffle_vmem2_write_req : vmem_wr_req2;
assign _vmem_wr_addr2 = in_ld_st ? ld_st_vmem2_write_addr : in_shuffle ? shuffle_vmem2_write_addr : vmem_wr_addr2;
assign _vmem_wr_data2 = in_ld_st ? ld_st_vmem2_write_data : in_shuffle ? shuffle_vmem2_write_data : vmem_wr_data2;

vector_memory #(
    .ADDR_WIDTH         ( VMEM_ADDR_WIDTH       ),
    .DATA_WIDTH         ( VMEM_DATA_WIDTH       ),
    .NUM_ELEM           ( NUM_ELEM              )
) vector_mem_inst1 (
	.clk				(	clk          	    ),
	.reset              (	reset        	    ),
	
	.read_req           (   _vmem_rd_req1       ),
    .read_addr          (	_vmem_rd_addr1      ),
    .read_data          (	_vmem_data1         ),

    .write_req          (	_vmem_wr_req1       ),
    .write_addr         (	_vmem_wr_addr1      ),
    .write_data         (	_vmem_wr_data1      )
);

vector_memory #(
    .ADDR_WIDTH         ( VMEM_ADDR_WIDTH       ),
    .DATA_WIDTH         ( VMEM_DATA_WIDTH       ),
    .NUM_ELEM           ( NUM_ELEM              )
) vector_mem_inst2 (
	.clk				(	clk          	    ),
	.reset              (	reset        	    ),
	
	.read_req           (   _vmem_rd_req2       ),
    .read_addr          (	_vmem_rd_addr2      ),
    .read_data          (	_vmem_data2         ),

    .write_req          (	_vmem_wr_req2       ),
    .write_addr         (	_vmem_wr_addr2      ),
    .write_data         (	_vmem_wr_data2      )
);

assign imm_wr_data = immediate_to_mem_stage;
assign imm_wr_addr = dest_ns_index_id_to_mem_stage; //DEBUG buffers_wr_addr[IMM_ADDR_WIDTH-1:0];
assign imm_wr_req = buffer_write_req_to_compute_stage[IMM_ISA_NS_INDEX];    

ram #(
    .DATA_WIDTH           (IMM_DATA_WIDTH ),
    .ADDR_WIDTH           (IMM_ADDR_WIDTH )
) immediate_memory (
    .clk		          ( clk                 ),
    .reset                (	reset               ),
    
    .read_req             ( buffer_read_req_to_mem_stage_d[IMM_ISA_NS_INDEX]	        ),
    .read_addr            (	buffer_address_4_read[IMM_ADDR_WIDTH-1:0]         ),
    .read_data            (	imm_mem_out            ),
    
    .write_req            (	imm_wr_req          ),
    .write_addr           (	imm_wr_addr         ),
    .write_data           (	imm_wr_data         )
);

pipeline #( .NUM_BITS	( BUFFERS_WR_ADDR_WIDTH	), .NUM_STAGES	( 1	), .EN_RESET   ( 0 ) ) buffers_wr_address_delay (
    .clk		(	clk		    ), .rst		(	reset		), .data_in	(	buffers_wr_addr	), .data_out	(	buffers_wr_addr_to_mux_stage    ) );

pipeline #( .NUM_BITS	( NS_ID_BITS	), .NUM_STAGES	( 1	), .EN_RESET   ( 0 ) ) src1_sel_delay (
    .clk		(	clk		    ), .rst		(	reset		), .data_in	(	src1_ns_id_to_mem_stage	), .data_out	(	src1_ns_id_to_mux_stage    ) );

pipeline #( .NUM_BITS	( NS_ID_BITS	), .NUM_STAGES	( 1	), .EN_RESET   ( 0 ) ) src2_sel_delay (
    .clk		(	clk		    ), .rst		(	reset		), .data_in	(	src2_ns_id_to_mem_stage	), .data_out	(	src2_ns_id_to_mux_stage    ) );

pipeline #( .NUM_BITS	( 6	), .NUM_STAGES	( 1	), .EN_RESET   ( 0 ) ) buffer_wr_req_delay2 (
    .clk		(	clk		    ), .rst		(	reset		), .data_in	(	buffer_write_req	), .data_out	(	buffer_write_req_to_mux_stage    ) );
    
pipeline #( .NUM_BITS	( FUNCTION_BITS + OPCODE_BITS	), .NUM_STAGES	( 1	), .EN_RESET   ( 0 ) ) opcode_fn_delay3 (
    .clk		(	clk		    ), .rst		(	reset		), .data_in	(	opcode_fn_to_mem_stage	), .data_out	(	opcode_fn_to_mux_stage    ) );

pipeline #( .NUM_BITS	( 8 ), .NUM_STAGES	( 1	), .EN_RESET   ( 0 ) ) dest_integer_bits_delay3 (
    .clk		(	clk		    ), .rst		(	reset		), .data_in	(	dest_integer_bits_to_mem_stage	), .data_out	(	dest_integer_bits_to_mux_stage    ) );

pipeline #( .NUM_BITS	( 8 ), .NUM_STAGES	( 1	), .EN_RESET   ( 0 ) ) src1_integer_bits_delay3 (
    .clk		(	clk		    ), .rst		(	reset		), .data_in	(	src1_integer_bits_to_mem_stage	), .data_out	(	src1_integer_bits_to_mux_stage    ) );

pipeline #( .NUM_BITS	( 8 ), .NUM_STAGES	( 1	), .EN_RESET   ( 0 ) ) src2_integer_bits_delay3 (
    .clk		(	clk		    ), .rst		(	reset		), .data_in	(	src2_integer_bits_to_mem_stage	), .data_out	(	src2_integer_bits_to_mux_stage    ) );
///////////////////////////////////////// Stage 4 ///////////////////////////
///////////////////////////////////////// namespace mux ///////////////////////////

generate 
for(genvar i = 0 ; i< NUM_ELEM ; i=i+1) begin : MUX
    if(INTERLEAVE == 0) begin
        always @(*) begin
            src1_ns_id_interleaved[i] = src1_ns_id_to_mux_stage;
            src2_ns_id_interleaved[i] = src2_ns_id_to_mux_stage;
       end
    end else begin
        if( i == 0) begin
            always @(*) begin
                src1_ns_id_interleaved[i] = src1_ns_id_to_mux_stage;
                src2_ns_id_interleaved[i] = src2_ns_id_to_mux_stage;
            end
        end else begin
            always @(posedge clk) begin
                src1_ns_id_interleaved[i] <= src1_ns_id_interleaved[i-1];
                src2_ns_id_interleaved[i] <= src2_ns_id_interleaved[i-1];
            end
        end
    end
    
    namespace_mux #(
      .DATA_WIDTH       ( DATA_WIDTH    )
    ) src1_mux (   
        .obuf_data      (   obuf_data[i*DATA_WIDTH+:DATA_WIDTH]     ),
        .ibuf_data      (   'd0                                     ),
        .vmem_data1     (   vmem_data1[i*DATA_WIDTH+:DATA_WIDTH]    ),
        .vmem_data2     (   vmem_data2[i*DATA_WIDTH+:DATA_WIDTH]    ),
        .imm_data       (   imm_data[i*DATA_WIDTH+:DATA_WIDTH]      ),
        .ext_data       (   'b0  ),
        
        .data_sel       (   src1_ns_id_interleaved[i]               ),
        
        .data_out       (   src1_muxed[i*DATA_WIDTH+:DATA_WIDTH]    )
    );
        
    namespace_mux #(
      .DATA_WIDTH       ( DATA_WIDTH    )
    ) src2_mux (   
        .obuf_data      (   obuf_data[i*DATA_WIDTH+:DATA_WIDTH]     ),
        .ibuf_data      (   'd0                                     ),
        .vmem_data1     (   vmem_data1[i*DATA_WIDTH+:DATA_WIDTH]    ),
        .vmem_data2     (   vmem_data2[i*DATA_WIDTH+:DATA_WIDTH]    ),
        .imm_data       (   imm_data[i*DATA_WIDTH+:DATA_WIDTH]      ),
        .ext_data       (   'b0  ),
        
        .data_sel       (   src2_ns_id_interleaved[i]               ),
        
        .data_out       (   src2_muxed[i*DATA_WIDTH+:DATA_WIDTH]    )
    );
   
end
endgenerate   

generate 
for(genvar i = 0 ; i< NUM_ELEM ; i=i+1) begin : mux_out
    if(ENABLE_PIPELINE_AFTER_NAMESPACE_MUX == 1) begin
        always @(posedge clk) begin
            src1_data[i] <= src1_muxed[DATA_WIDTH*i +: DATA_WIDTH];
            src2_data[i] <= src2_muxed[DATA_WIDTH*i +: DATA_WIDTH];
        end
    end
    else begin
        always @(*) begin
            src1_data[i] = src1_muxed[DATA_WIDTH*i +: DATA_WIDTH];
            src2_data[i] = src2_muxed[DATA_WIDTH*i +: DATA_WIDTH];
        end
    end
end
endgenerate

//localparam extra_stages = 4;
//localparam extra_stages = 1;
localparam extra_stages = 1;

if( ENABLE_PIPELINE_AFTER_NAMESPACE_MUX == 1) begin 
    pipeline #( .NUM_BITS	( BUFFERS_WR_ADDR_WIDTH	), .NUM_STAGES	( extra_stages	), .EN_RESET   ( 0 ) ) buffers_wr_address_delay_ns (
        .clk		(	clk		    ), .rst		(	reset		), .data_in	(	buffers_wr_addr_to_mux_stage	), .data_out	(	buffers_wr_addr_to_compute_stage    ) );

    pipeline #( .NUM_BITS	( 6	), .NUM_STAGES	( extra_stages	), .EN_RESET   ( 0 ) ) buffer_wr_req_delay_ns (
        .clk		(	clk		    ), .rst		(	reset		), .data_in	(	buffer_write_req_to_mux_stage	), .data_out	(	buffer_write_req_to_compute_stage    ) );
    
    pipeline #( .NUM_BITS	( FUNCTION_BITS + OPCODE_BITS	), .NUM_STAGES	( extra_stages	), .EN_RESET   ( 0 ) ) opcode_fn_delay4 (
        .clk		(	clk		    ), .rst		(	reset		), .data_in	(	opcode_fn_to_mux_stage	), .data_out	(	opcode_fn_to_compute_stage    ) );

    pipeline #( .NUM_BITS	( 8	), .NUM_STAGES	( 1	), .EN_RESET   ( 0 ) ) dest_integer_bits_delay4 (
        .clk		(	clk		    ), .rst		(	reset		), .data_in	(   dest_integer_bits_to_mux_stage	), .data_out	(	dest_integer_bits_to_compute_stage    ) );

    pipeline #( .NUM_BITS	( 8	), .NUM_STAGES	( 1	), .EN_RESET   ( 0 ) ) src1_integer_bits_delay4 (
    .clk		(	clk		    ), .rst		(	reset		), .data_in	(	src1_integer_bits_to_mux_stage	), .data_out	(	src1_integer_bits_to_compute_stage    ) );

    pipeline #( .NUM_BITS	( 8	), .NUM_STAGES	( 1	), .EN_RESET   ( 0 ) ) src2_integer_bits_delay4 (
    .clk		(	clk		    ), .rst		(	reset		), .data_in	(	src2_integer_bits_to_mux_stage	), .data_out	(	src2_integer_bits_to_compute_stage    ) );

end else begin
    assign buffer_write_req_to_compute_stage = buffer_write_req_to_mux_stage;
    assign opcode_fn_to_compute_stage = opcode_fn_to_mux_stage;
    assign buffers_wr_addr_to_compute_stage = buffers_wr_addr_to_mux_stage;
end
    
always @(posedge clk) begin
    buffer_write_req_to_compute_stage_d <= buffer_write_req_to_compute_stage;
    buffer_write_req_to_compute_stage_d2 <= buffer_write_req_to_compute_stage_d;
end

///////////////////////////////////////// Stage 5 ///////////////////////////
///////////////////////////////////////// compute ///////////////////////////
assign fn_compute = opcode_fn_to_compute_stage[FUNCTION_BITS-1:0];
assign opcode_compute = opcode_fn_to_compute_stage[OPCODE_BITS+FUNCTION_BITS-1:FUNCTION_BITS];

reg [BASE_STRIDE_WIDTH-1 : 0] buffer_address_write_general_d, buffer_address_read_op1_d, buffer_address_read_op2_d;
wire acc_reset;
reg  reduction_flag, reduction_dim;
reg  acc_reset_d;

always @(posedge clk ) begin
    if (reset) begin
        acc_reset_d <= 0;
        buffer_address_read_op1_d <= {BASE_STRIDE_WIDTH{1'b1}} ;
        buffer_address_read_op2_d <= {BASE_STRIDE_WIDTH{1'b1}} ;
        buffer_address_write_general_d <= {BASE_STRIDE_WIDTH{1'b1}} ;
    end 
    else  begin
        acc_reset_d <= acc_reset;
        buffer_address_read_op1_d <= buffer_address_read_op1;
        buffer_address_read_op2_d <= buffer_address_read_op2;
        buffer_address_write_general_d <= buffer_address_write_general;
    end
end

// DEBUG fused
always @(posedge clk) begin
    if (reset) begin
        reduction_flag <= 1'b0;
    end else if ( (!in_ld_st) && (buffer_address_write_general_d == buffer_address_write_general) && ((buffer_address_read_op1_d == buffer_address_read_op1) || (buffer_address_read_op2_d == buffer_address_read_op2))) begin
        reduction_flag <= 1'b1;
    end else begin
        reduction_flag <= 1'b0;
    end
end

always @(posedge clk) begin
    if (reset) begin
        reduction_dim <= 1'b0;
    end else if (buffer_address_read_op2_d == buffer_address_read_op2) begin
        reduction_dim <= 1'b1;
    end else begin
        reduction_dim <= 1'b0;
    end
end

assign acc_reset = (buffer_address_write_general_d != buffer_address_write_general) ;

/// CONDITIONAL MOVE
assign cond_move_inst = (fn_compute[FUNCTION_BITS-1:1] == 3'b101) && (opcode_compute == 4'b0000); 

simd_data_shuffler #(
    .VMEM1_MEM_ID(VMEM1_ISA_NS_INDEX),
    .VMEM2_MEM_ID(VMEM2_ISA_NS_INDEX),
    .LOOP_ITER_W(IMMEDIATE_WIDTH),
    .ADDR_STRIDE_W(IMMEDIATE_WIDTH),
    .BASE_ADDR_W(BASE_ADDR_WIDTH), 
    .LOOP_ID_W(NS_INDEX_ID_BITS),
    .NUM_TAGS(NUM_TAGS),
    .TAG_W(TAG_W),
    .SIMD_DATA_WIDTH(DATA_WIDTH),
    .NUM_SIMD_LANES(NUM_ELEM),
    .VMEM_BUF_ADDR_W(VMEM_ADDR_WIDTH),
    .VMEM_TAG_BUF_ADDR_W(VMEM_TAG_BUF_ADDR_W),
    .GROUP_ID_W(GROUP_ID_W),
    .MAX_NUM_GROUPS(MAX_NUM_GROUPS),
    .NS_ID_BITS(NS_ID_BITS),
    .NS_INDEX_ID_BITS(NS_INDEX_ID_BITS),
    .OPCODE_BITS(OPCODE_BITS),
    .FUNCTION_BITS(FUNCTION_BITS),
    .INSTRUCTION_WIDTH(INSTRUCTION_WIDTH)
) shuffler_inst (
    .clk                        (   clk                 ),
    .reset                      (   reset               ),
    .block_done                 (   block_done          ),
    .group_id                   (   group_id            ),
    .opcode                     (   opcode              ),
    .fn                         (   fn                  ),
    .dest_ns_id                 (   dest_ns_id          ),
    .dest_ns_index_id           (   dest_ns_index_id    ),  
    .src1_ns_id                 (   src1_ns_id          ),
    .src1_ns_index_id           (   src1_ns_index_id    ),    
    .src2_ns_id                 (   src2_ns_id          ),
    .src2_ns_index_id           (   src2_ns_index_id    ),
    .data_shuffle_done          (   data_shuffle_done   ),

    // VMEM1
    .vmem1_write_req            (   shuffle_vmem1_write_req     ),
    .vmem1_write_addr           (   shuffle_vmem1_write_addr    ),
    .vmem1_write_data           (   shuffle_vmem1_write_data    ),
    .vmem1_read_req             (   shuffle_vmem1_read_req      ),
    .vmem1_read_addr            (   shuffle_vmem1_read_addr     ),
    .vmem1_read_data            (   shuffle_vmem1_read_data     ),

    // VMEM2
    .vmem2_write_req            (   shuffle_vmem2_write_req     ),
    .vmem2_write_addr           (   shuffle_vmem2_write_addr    ),
    .vmem2_write_data           (   shuffle_vmem2_write_data    ),
    .vmem2_read_req             (   shuffle_vmem2_read_req      ),
    .vmem2_read_addr            (   shuffle_vmem2_read_addr     ),
    .vmem2_read_data            (   shuffle_vmem2_read_data     )
);

generate 
for(genvar i = 0 ; i< NUM_ELEM ; i=i+1) begin : SIMD

    assign compute_out_bus[DATA_WIDTH*i +: DATA_WIDTH] = data_compute_out[i];
    
    reg [FUNCTION_BITS-1:0] fn_in;
    wire [FUNCTION_BITS-1:0] fn_q;
    reg [OPCODE_BITS-1:0] opcode_in;
    wire [OPCODE_BITS-1:0] opcode_q;
    reg [5:0] buf_wr_req, buf_wr_req_default_from_buffer;
    wire [5:0] buf_wr_req_q;
    reg [BASE_STRIDE_WIDTH-1:0] buf_wr_addr;
    wire [BASE_STRIDE_WIDTH-1:0] buf_wr_addr_q;
    reg cond_move;
    reg disable_write;
    reg acc_reset_local;
    reg reduction_flag_local;
    reg reduction_dim_local;

    if(INTERLEAVE == 0) begin
        always @(*) begin
            fn_in = fn_compute;
            opcode_in = opcode_compute;
            cond_move = cond_move_inst;
            disable_write = cond_move && !(fn_in[0] ^ src2_data[i][0]);
       end

       always @(posedge clk) begin
            buf_wr_req <= buffer_write_req_to_compute_stage & {6{~disable_write}};
            buf_wr_addr <= buffers_wr_addr_to_compute_stage;
            acc_reset_local <= acc_reset_d;
            reduction_flag_local <= reduction_flag;
            reduction_dim_local <= reduction_dim;
        end
    end else begin
        if( i == 0) begin
            always @(*) begin
                fn_in = fn_compute;
                opcode_in = opcode_compute;
                cond_move = cond_move_inst;
                disable_write = cond_move && !(fn_in[0] ^ src2_data[i][0]);
           end

           always @(posedge clk) begin
                buf_wr_req_default_from_buffer <= buffer_write_req_to_compute_stage_final; // DEBUG (in_single_loop || in_single_loop_d5 || in_nested_loop || in_nested_loop_d7) ? buffer_write_req_to_compute_stage_d2 : buffer_write_req_to_compute_stage_d;
                buf_wr_req <= buffer_write_req_to_compute_stage_final; // DEBUG (in_single_loop || in_single_loop_d5 || in_nested_loop || in_nested_loop_d7) ? buffer_write_req_to_compute_stage_d2 : buffer_write_req_to_compute_stage_d;
                buf_wr_addr <= buffers_wr_addr_to_compute_stage;
                acc_reset_local <= acc_reset_d;
                reduction_flag_local <= reduction_flag;
                reduction_dim_local <= reduction_dim;
            end
        end else begin
            always @(*) begin
                disable_write = cond_move && !(fn_in[0] ^ src2_data[i][0]);
            end
            always @(posedge clk) begin
                fn_in <= SIMD[i-1].fn_in;
                opcode_in <= SIMD[i-1].opcode_in;
                cond_move <= SIMD[i-1].cond_move;

                if ( i == 1) begin
                    buf_wr_req_default_from_buffer <= buffer_write_req_to_compute_stage_final; // DEBUG (in_single_loop || in_single_loop_d5 || in_nested_loop || in_nested_loop_d7) ? buffer_write_req_to_compute_stage_d2 : buffer_write_req_to_compute_stage_d;
                end else begin
                    buf_wr_req_default_from_buffer <= SIMD[i-1].buf_wr_req_default_from_buffer;
                end 

                buf_wr_req <= buf_wr_req_default_from_buffer & {6{~disable_write}};
                buf_wr_addr <= SIMD[i-1].buf_wr_addr;
                acc_reset_local <= SIMD[i-1].acc_reset_local;
                reduction_flag_local <= SIMD[i-1].reduction_flag_local;
                reduction_dim_local <= SIMD[i-1].reduction_dim_local;
            end
        end
    end

    execute_control_pipelines #(
        .OPCODE_BITS(OPCODE_BITS), 		
	    .FUNCTION_BITS(FUNCTION_BITS), 	
        .NS_ID_BITS(NS_ID_BITS), 		
	    .NS_INDEX_ID_BITS(NS_INDEX_ID_BITS), 	
        .BASE_STRIDE_WIDTH(BASE_STRIDE_WIDTH)     
    ) i_exe_cntl_pipes (
        .clk(clk),
        .reset(reset),
        .fn(fn_in),
        .opcode(opcode_in),                              
        .buf_wr_req_in(buf_wr_req),
        .buf_wr_addr_in(buf_wr_addr),
        .in_loop_in(in_single_loop || in_nested_loop),
        .fn_out(fn_q),
        .opcode_out(opcode_q),
        .buf_wr_req_out(buf_wr_req_q),
        .buf_wr_addr_out(buf_wr_addr_q)
    );

    assign buf_wr_addr_interleaved[i] = buf_wr_addr_q;
    assign buf_wr_req_interleaved[i] = buf_wr_req_q;
    
    if (i==0) begin
    compute_unit_test #(
        .OPCODE_BITS(OPCODE_BITS),
        .FUNCTION_BITS(FUNCTION_BITS),
        .BASE_STRIDE_WIDTH(BASE_STRIDE_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) compute_inst_test  (
    .clk            (   clk       ),
    .reset          (   reset     ),

    .data_in0       (   src1_data[i]  ),
    .data_in1       (   src2_data[i]  ),
    
    .acc_reset      (   acc_reset_local ),
    .reduction_flag (   reduction_flag_local ),
    .reduction_dim  (   reduction_dim_local   ),
    
    .dest_integer_bits  (   dest_integer_bits_to_compute_stage    ),
    .src1_integer_bits  (   src1_integer_bits_to_compute_stage    ),
    .src2_integer_bits  (   src2_integer_bits_to_compute_stage    ),

    .data_out       (   data_compute_out[i]   ),

    .opcode         (   opcode_q     ),
    .fn             (   fn_q         )
    );
    end 
    else begin 
    compute_unit #(
        .OPCODE_BITS(OPCODE_BITS),
        .FUNCTION_BITS(FUNCTION_BITS),
        .BASE_STRIDE_WIDTH(BASE_STRIDE_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) compute_inst  (
    .clk            (   clk       ),
    .reset          (   reset     ),

    .data_in0       (   src1_data[i]  ),
    .data_in1       (   src2_data[i]  ),
    
    .acc_reset      (   acc_reset_local ),
    .reduction_flag (   reduction_flag_local ),
    .reduction_dim  (   reduction_dim_local   ),
    
    .dest_integer_bits  (   dest_integer_bits_to_compute_stage    ),
    .src1_integer_bits  (   src1_integer_bits_to_compute_stage    ),
    .src2_integer_bits  (   src2_integer_bits_to_compute_stage    ),

    .data_out       (   data_compute_out[i]   ),

    .opcode         (   opcode_q     ),
    .fn             (   fn_q         )
    );
    end
    
end
endgenerate
    
assign ibuf_wr_data = compute_out_bus;
assign vmem_wr_data1 = compute_out_bus;
assign vmem_wr_data2 = compute_out_bus;

generate
    for(genvar i = 0; i< NUM_ELEM; i= i+1) begin
        assign ibuf_wr_addr[IBUF_ADDR_WIDTH*i+: IBUF_ADDR_WIDTH] = buf_wr_addr_interleaved[i][IBUF_ADDR_WIDTH-1:0];
        assign vmem_wr_addr1[VMEM_ADDR_WIDTH*i+: VMEM_ADDR_WIDTH] = buf_wr_addr_interleaved[i][VMEM_ADDR_WIDTH-1:0];
        assign vmem_wr_addr2[VMEM_ADDR_WIDTH*i+: VMEM_ADDR_WIDTH] = buf_wr_addr_interleaved[i][VMEM_ADDR_WIDTH-1:0];
        
        assign ibuf_wr_req[i] = buf_wr_req_interleaved[i][IBUF_ISA_NS_INDEX];
        assign vmem_wr_req1[i] = buf_wr_req_interleaved[i][VMEM1_ISA_NS_INDEX];
        assign vmem_wr_req2[i] = buf_wr_req_interleaved[i][VMEM2_ISA_NS_INDEX];
    end
endgenerate
/*
ila_0 simd_ila (
  .clk(clk),
// 1 bit width
  .probe0(_vmem_rd_req1[0]),
 //1 bit width
  .probe1(obuf_rd_req[0])
  
 );
 
*/

endmodule
