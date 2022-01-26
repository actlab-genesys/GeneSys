//
// Interface for WBUF and BBUF
//

`timescale 1ns/1ps
module parambuf_interface #(
  // Internal Parameters
    parameter integer  WBUF_MEM_ID                  = 0,
    parameter integer  BBUF_MEM_ID					= 3,
    parameter integer  NUM_BASE_LOOPS				= 7,
    
//    parameter integer  BASE_ID_IBUF				    = 1,
//    parameter integer  BASE_ID_OBUF				    = 2,
//    parameter integer  BASE_ID_BBUF				    = 3,
    
//    parameter integer  STORE_ENABLED                = MEM_ID == 2 ? 1 : 0,
    parameter integer  MEM_REQ_W                    = 16,
    // LD Base ADDR
    parameter integer  ADDR_WIDTH                   = 8,
    parameter integer  LOOP_ITER_W                  = 16,
    parameter integer  ADDR_STRIDE_W                = 32,
    parameter integer  LOOP_ID_W                    = 6,
    parameter integer  BUF_TYPE_W                   = 2,
    parameter integer  NUM_BUF_TYPE					= 2**(BUF_TYPE_W),
    parameter integer  NUM_TAGS                     = 2,
    parameter integer  TAG_W                        = $clog2(NUM_TAGS),
    parameter integer  TAG_REUSE_COUNTER_W          = 3,

    parameter integer  WGT_DATA_WIDTH               = 8,
    parameter integer  BIAS_DATA_WIDTH				= 32,
    
  // AXI
    parameter integer  AXI_ADDR_WIDTH               = 42,
    parameter integer  AXI_ID_WIDTH                 = 1,
    parameter integer  AXI_DATA_WIDTH               = 64,
    parameter integer  AXI_BURST_WIDTH              = 8,
    parameter integer  WSTRB_W                      = AXI_DATA_WIDTH/8,

  // Buffer
    parameter integer  ARRAY_N                      = 32,
    parameter integer  ARRAY_M                      = 32,
    parameter integer  WBUF_ADDR_W                  = 16,
    parameter integer  BBUF_ADDR_W					= 16,
   
    parameter integer  TAG_WBUF_ADDR_W              = WBUF_ADDR_W + TAG_W,
    parameter integer  TAG_BBUF_ADDR_W  			= BBUF_ADDR_W + TAG_W,
   
    parameter integer  WBUF_REQ_WIDTH 				= $clog2(ARRAY_M) + 1, 
    parameter integer  WBUF_WRITE_GROUP_SIZE		= AXI_DATA_WIDTH / WGT_DATA_WIDTH,
    parameter integer  NUM_WBUF_WRITE_GROUPS		= ARRAY_N / WBUF_WRITE_GROUP_SIZE,
    
    parameter integer  BBUF_WRITE_DATA_W		    = ARRAY_M * BIAS_DATA_WIDTH,
    parameter integer  BBUF_WRITE_ADDR_W			= ARRAY_M * TAG_BBUF_ADDR_W,
    parameter integer  BBUF_WRITE_REQ_W				= ARRAY_M,
    
    parameter integer BBUF_WRITE_GROUP_SIZE			= AXI_DATA_WIDTH / BIAS_DATA_WIDTH,
    parameter integer NUM_BBUF_WRITE_GROUPS			= ARRAY_M / BBUF_WRITE_GROUP_SIZE,
    
    parameter integer INST_GROUP_ID_W               = 4   ,
    parameter integer  STORE_ENABLED                = 0,
    parameter integer  GROUP_ENABLED                = 0
 ) (
    input  wire                                         clk,
    input  wire                                         reset,

    input  wire                                         tag_req,
    input  wire                                         wbuf_tag_reuse,
    input  wire											                    bbuf_tag_reuse,
    input  wire                                         tag_bias_prev_sw,
    input  wire                                         tag_ddr_pe_sw,
    output wire                                         parambuf_tag_ready,
    output wire                                         wbuf_tag_done,
    output wire                                         bbuf_tag_done,
    input  wire                                         compute_done,
    input  wire                                         block_done,
    
    input  wire	 [ ADDR_WIDTH           -1 : 0 ]        tag_base_wbuf_ld_addr,
    input  wire  [ ADDR_WIDTH           -1 : 0 ]        tag_base_bbuf_ld_addr,
    
    input  wire                                         wbuf_base_addr_v,
    input  wire                                         bbuf_base_addr_v,

    output wire                                         parambuf_compute_ready,
    // This signal will be used for the base address generator to generate the right base address for loading wbuf/bbuf
    output wire                                         parambuf_next_group_ld_id,
    // TODO: Not sure about the usage of below signals
    output wire                                         wbuf_compute_bias_prev_sw,
    output wire											bbuf_compute_bias_prev_sw,
  // Programming    
    input  wire                                         cfg_loop_stride_v,
    input  wire  [ 2                    -1 : 0 ]        cfg_loop_stride_type,
    input  wire  [ ADDR_STRIDE_W        -1 : 0 ]        cfg_loop_stride,
    input  wire  [ LOOP_ID_W            -1 : 0 ]        cfg_loop_stride_loop_id,
    input  wire  [ BUF_TYPE_W           -1 : 0 ]        cfg_loop_stride_id,
    input  wire											cfg_loop_stride_segment,    

    input  wire                                         cfg_loop_iter_v,
    input  wire  [ LOOP_ITER_W          -1 : 0 ]        cfg_loop_iter,
    input  wire  [ LOOP_ID_W            -1 : 0 ]        cfg_loop_iter_loop_id,
    input  wire  [ LOOP_ID_W            -1 : 0 ]		cfg_loop_iter_level,

    input  wire                                         cfg_mem_req_v,
    input  wire  [ BUF_TYPE_W           -1 : 0 ]        cfg_mem_req_id,
    input  wire  [ MEM_REQ_W            -1 : 0 ]        cfg_mem_req_size,
    input  wire  [ LOOP_ID_W            -1 : 0 ]        cfg_mem_req_loop_id,
    input  wire  [ 2                    -1 : 0 ]        cfg_mem_req_type,
    
// The Group instructions for filling WBUF/BBUF for fused conv/fc layers   
    input wire   [ INST_GROUP_ID_W       -1 : 0 ]       inst_group_id,
    input wire                                          inst_group_type,
    input wire                                          inst_group_s_e,
    input wire                                          inst_group_v,
    input wire   [ LOOP_ID_W             -1 : 0 ]       inst_group_sa_loop_id,
    input wire                                          inst_group_last,
    

  // Systolic Array
  // RD signals go to SA to read from WBUF
    input  wire                                         wbuf_read_req,
    input  wire  [ WBUF_ADDR_W           -1 : 0 ]       wbuf_read_addr,  
    output wire                                         wbuf_read_req_out,
    output wire  [ TAG_WBUF_ADDR_W       -1 : 0 ]       wbuf_read_addr_out,
  // Write to Wbuf
    output wire  [ WBUF_REQ_WIDTH*ARRAY_N -1 : 0 ]      wbuf_write_req_out,
    output wire  [ TAG_WBUF_ADDR_W*ARRAY_N -1 : 0 ]     wbuf_write_addr_out,
    output wire  [ WGT_DATA_WIDTH*ARRAY_N     -1 : 0 ]  wbuf_write_data_out,
  // RD signals get augmented with the compute tag and then go to SA for syncronization. From there they will go BBUF to read data
    input  wire   										bbuf_read_req,
    input  wire  [ BBUF_ADDR_W           -1 : 0 ]		bbuf_read_addr,
    output wire  										bbuf_read_req_out,
    output wire  [ TAG_BBUF_ADDR_W 	     -1 : 0 ]		bbuf_read_addr_out,
    
    output wire  [ BBUF_WRITE_REQ_W		 -1 : 0 ]       bbuf_write_req_out,
    output wire  [ BBUF_WRITE_ADDR_W     -1 : 0 ]       bbuf_write_addr_out,
    output wire  [ BBUF_WRITE_DATA_W     -1 : 0 ]       bbuf_write_data_out,
    
    
 // TODO: double check and make sure this is correct
  // CL_wrapper -> DDR AXI4 interface
    // Master Interface Write Address
    output wire  [ AXI_ADDR_WIDTH       -1 : 0 ]        mws_awaddr,
    output wire  [ AXI_BURST_WIDTH      -1 : 0 ]        mws_awlen,
//    output wire  [ 3                    -1 : 0 ]        mws_awsize,
//    output wire  [ 2                    -1 : 0 ]        mws_awburst,
    output wire                                         mws_awvalid,
    input  wire                                         mws_awready,
    // Master Interface Write Data
    output wire  [ AXI_DATA_WIDTH       -1 : 0 ]        mws_wdata,
    output wire  [ WSTRB_W              -1 : 0 ]        mws_wstrb,
    output wire                                         mws_wlast,
    output wire                                         mws_wvalid,
    input  wire                                         mws_wready,
    // Master Interface Write Response
//    input  wire  [ 2                    -1 : 0 ]        mws_bresp,
    input  wire                                         mws_bvalid,
    output wire                                         mws_bready,
    // Master Interface Read Address
    output wire  [ AXI_ADDR_WIDTH       -1 : 0 ]        mws_araddr,
//    output wire  [ AXI_ID_WIDTH         -1 : 0 ]        mws_arid,
    output wire  [ AXI_BURST_WIDTH      -1 : 0 ]        mws_arlen,
//    output wire  [ 3                    -1 : 0 ]        mws_arsize,
//    output wire  [ 2                    -1 : 0 ]        mws_arburst,
    output wire                                         mws_arvalid,
    input  wire                                         mws_arready,
    // Master Interface Read Data
    input  wire  [ AXI_DATA_WIDTH       -1 : 0 ]        mws_rdata,
//    input  wire  [ AXI_ID_WIDTH         -1 : 0 ]        mws_rid,
//    input  wire  [ 2                    -1 : 0 ]        mws_rresp,
    input  wire                                         mws_rlast,
    input  wire                                         mws_rvalid,
    output wire                                         mws_rready,
    input  wire                                         last_store_en
);

//==============================================================================
// Localparams
//==============================================================================
    localparam integer  LDMEM_IDLE                   = 0;
    localparam integer  LDMEM_CHECK_RAW              = 1;
    localparam integer  LDMEM_BUSY                   = 2;
    localparam integer  LDMEM_WAIT_0                 = 3;
    localparam integer  LDMEM_WAIT_1                 = 4;
    localparam integer  LDMEM_WAIT_2                 = 5;
    localparam integer  LDMEM_WAIT_3                 = 6;
    localparam integer  LDMEM_DONE                   = 7;

    localparam integer  STMEM_IDLE                   = 0;
    localparam integer  STMEM_DDR                    = 1;
    localparam integer  STMEM_WAIT_0                 = 2;
    localparam integer  STMEM_WAIT_1                 = 3;
    localparam integer  STMEM_WAIT_2                 = 4;
    localparam integer  STMEM_WAIT_3                 = 5;
    localparam integer  STMEM_DONE                   = 6;
    localparam integer  STMEM_PU                     = 7;

    localparam integer  MEM_LD                       = 0;
    localparam integer  MEM_ST                       = 1;
    
    localparam integer      SA_GROUP                 = 0;
    localparam integer      SIMD_GROUP               = 1;
    localparam integer      GROUP_START              = 0;
    localparam integer      GROUP_END                = 1;
	
	localparam integer  COUNTER_GROUP_WIDTH			 = $clog2(NUM_WBUF_WRITE_GROUPS) + 1;
	localparam integer  COUNTER_COL_WIDTH			 = $clog2(ARRAY_M);
	
	localparam integer  COUNTER_BBUF_GROUP_WIDTH     = $clog2(NUM_BBUF_WRITE_GROUPS) + 1;

	
//==============================================================================

//==============================================================================
// Wires/Regs
//==============================================================================
    wire                                        wbuf_compute_tag_done;
    wire                                        wbuf_compute_tag_reuse;
    wire                                        wbuf_compute_tag_ready;
    wire [ TAG_W                -1 : 0 ]        wbuf_compute_tag;
    wire [ TAG_W                -1 : 0 ]        wbuf_compute_tag_delayed;

    wire                                        wbuf_ldmem_tag_ready;
    wire [ TAG_W                -1 : 0 ]        wbuf_ldmem_tag;
    wire                                        wbuf_stmem_tag_done;
    wire                                        wbuf_stmem_tag_ready;
    wire [ TAG_W                -1 : 0 ]        wbuf_wbuf_stmem_tag;
    wire                                        wbuf_stmem_ddr_pe_sw;
	

    wire                                        bbuf_compute_tag_done;
    wire                                        bbuf_compute_tag_reuse;
    wire                                        bbuf_compute_tag_ready;
    wire [ TAG_W                -1 : 0 ]        bbuf_compute_tag;
    wire [ TAG_W                -1 : 0 ]        bbuf_compute_tag_delayed;
    wire                                        bbuf_ldmem_tag_done;
    wire                                        bbuf_ldmem_tag_ready;
    wire [ TAG_W                -1 : 0 ]        bbuf_ldmem_tag;
    wire                                        bbuf_stmem_tag_done;
    wire                                        bbuf_stmem_tag_ready;
    wire [ TAG_W                -1 : 0 ]        bbuf_stmem_tag;
    wire                                        bbuf_stmem_ddr_pe_sw;
	
	// Local tag sync signals
	wire										wbuf_tag_ready;
	wire										bbuf_tag_ready;
  wire                    axi_rd_ready;



    reg  [ 4                    -1 : 0 ]        wbuf_ldmem_state_d;
    reg  [ 4                    -1 : 0 ]        wbuf_ldmem_state_q,wbuf_ldmem_state_qq;

    reg  [ 3                    -1 : 0 ]        wbuf_stmem_state_d;
    reg  [ 3                    -1 : 0 ]        wbuf_stmem_state_q;

    reg  [ 4                    -1 : 0 ]        bbuf_ldmem_state_d;
    reg  [ 4                    -1 : 0 ]        bbuf_ldmem_state_q,bbuf_ldmem_state_qq;

    reg  [ 3                    -1 : 0 ]        bbuf_stmem_state_d;
    reg  [ 3                    -1 : 0 ]        bbuf_stmem_state_q;

    wire                                        wbuf_ld_mem_req_v;
    wire                                        wbuf_st_mem_req_v;

    wire                                        bbuf_ld_mem_req_v;
    wire                                        bbuf_st_mem_req_v;


    wire [ TAG_W                -1 : 0 ]        wbuf_tag;
    wire [ TAG_W                -1 : 0 ]        bbuf_tag;

    reg                                         ld_iter_v_q;
    reg  [ LOOP_ITER_W          -1 : 0 ]        iter_q;
	reg  [ LOOP_ID_W            -1 : 0 ]		loop_id_q;
	reg  [ LOOP_ID_W            -1 : 0 ]		loop_level_q;
	
	wire [ LOOP_ID_W            -1: 0 ]         wbuf_cfg_mws_ld_loop_id;
    wire [ LOOP_ID_W            -1: 0 ]         bbuf_cfg_mws_ld_loop_id;

    wire [ LOOP_ID_W            -1 : 0 ]        wbuf_mws_ld_loop_iter_loop_id;
    wire [ LOOP_ITER_W          -1 : 0 ]        wbuf_mws_ld_loop_iter;
    wire                                        wbuf_mws_ld_loop_iter_v;
	wire  [ LOOP_ID_W            -1 : 0 ]		wbuf_mws_ld_loop_iter_loop_level;
    wire                                        wbuf_mws_ld_start;
    wire                                        wbuf_mws_ld_done;
    wire                                        wbuf_mws_ld_stall;
    wire                                        wbuf_mws_ld_init;
    wire                                        wbuf_mws_ld_enter;
    wire                                        wbuf_mws_ld_exit;
    wire [ LOOP_ID_W            -1 : 0 ]        wbuf_mws_ld_index;
    wire                                        wbuf_mws_ld_index_valid;
    wire                                        wbuf_mws_ld_step;
    
    wire [ INST_GROUP_ID_W      -1 : 0 ]        wbuf_cfg_mws_ld_stride_group_id;
    wire [ INST_GROUP_ID_W      -1 : 0 ]        wbuf_cfg_mws_ld_loop_group_id;
    wire [ INST_GROUP_ID_W      -1 : 0 ]        wbuf_mws_ld_group_id ;
    
    wire [ LOOP_ID_W            -1 : 0 ]        bbuf_mws_ld_loop_iter_loop_id;
    wire [ LOOP_ITER_W          -1 : 0 ]        bbuf_mws_ld_loop_iter;
    wire                                        bbuf_mws_ld_loop_iter_v;
	wire  [ LOOP_ID_W            -1 : 0 ]		bbuf_mws_ld_loop_iter_loop_level;
    wire                                        bbuf_mws_ld_start;
    wire                                        bbuf_mws_ld_done;
    wire                                        bbuf_mws_ld_stall;
    wire                                        bbuf_mws_ld_init;
    wire                                        bbuf_mws_ld_enter;
    wire                                        bbuf_mws_ld_exit;
    wire [ LOOP_ID_W            -1 : 0 ]        bbuf_mws_ld_index;
    wire                                        bbuf_mws_ld_index_valid;
    wire                                        bbuf_mws_ld_step;
    
    wire [ INST_GROUP_ID_W      -1 : 0 ]        bbuf_cfg_mws_ld_stride_group_id;
    wire [ INST_GROUP_ID_W      -1 : 0 ]        bbuf_cfg_mws_ld_loop_group_id;
    wire [ INST_GROUP_ID_W      -1 : 0 ]        bbuf_mws_ld_group_id ;   
    
    reg  [ INST_GROUP_ID_W      -1 : 0 ]        curr_cfg_loop_stride_group_id;



    wire                                        wbuf_ld_stride_v;
	wire										bbuf_ld_stride_v;
    wire [ ADDR_STRIDE_W        -1 : 0 ]        ld_stride;
	wire 										ld_stride_segment;

    wire [ ADDR_WIDTH           -1 : 0 ]        ld_addr;
    wire                                        ld_addr_v;

    wire [ ADDR_WIDTH           -1 : 0 ]        wbuf_ld_addr;
    wire [ ADDR_WIDTH           -1 : 0 ]        wbuf_mws_ld_base_addr;
    wire                                        wbuf_ld_addr_v;

    wire [ ADDR_WIDTH           -1 : 0 ]        bbuf_ld_addr;
    wire [ ADDR_WIDTH           -1 : 0 ]        bbuf_mws_ld_base_addr;
    wire                                        bbuf_ld_addr_v;

    reg  [ MEM_REQ_W             -1 : 0 ]        ld_req_size;
    reg  [ MEM_REQ_W             -1 : 0 ]        wbuf_ld_req_size;
    reg  [ MEM_REQ_W             -1 : 0 ]        bbuf_ld_req_size;


//    wire                                        ld_req_valid_d;
//    reg                                         ld_req_valid_q;

    wire                                        wbuf_ld_req_valid_d;
    reg                                         wbuf_ld_req_valid_q;

    wire                                        bbuf_ld_req_valid_d;
    reg                                         bbuf_ld_req_valid_q;
	
	

    reg  [ ADDR_WIDTH           -1 : 0 ]        wbuf_tag_ld_addr[0:NUM_TAGS-1];
    reg  [ ADDR_WIDTH           -1 : 0 ]        bbuf_tag_ld_addr[0:NUM_TAGS-1];
	
    reg  [ ADDR_WIDTH           -1 : 0 ]        ld_req_addr;
    reg  [ ADDR_WIDTH           -1 : 0 ]        wbuf_ld_req_addr;
    reg  [ ADDR_WIDTH           -1 : 0 ]        bbuf_ld_req_addr;


    wire                                        axi_rd_req;
    wire                                        axi_rd_done;
    reg  [ (MEM_REQ_W*2)            -1 : 0 ]        axi_rd_req_size;
    reg  [ AXI_ADDR_WIDTH       -1 : 0 ]        axi_rd_addr;

    wire                                        axi_wr_req;
    wire [ (MEM_REQ_W*2)            -1 : 0 ]        axi_wr_req_size;
    wire                                        axi_wr_ready;
    wire [ AXI_ADDR_WIDTH       -1 : 0 ]        axi_wr_addr;
    wire                                        axi_wr_data_v;

    wire                                        mem_write_req;
    wire [ AXI_DATA_WIDTH       -1 : 0 ]        mem_write_data;

    wire                                        mem_write_ready;
	
	
    // Mem reads disabled
    wire [ AXI_DATA_WIDTH       -1 : 0 ]        mem_read_data;

//==============================================================================
    localparam NUM_MAX_LOOPS = ( 1<< LOOP_ID_W);
    wire [ NUM_MAX_LOOPS :0] wbuf_fsm_iter_done,bbuf_fsm_iter_done;
    wire [ LOOP_ITER_W * NUM_MAX_LOOPS-1:0] wbuf_current_iters,bbuf_current_iters;
//==============================================================================
//=============== Wires and Regs for BBUF tag_sync============
  	wire										bbuf_tag_req;
  	//wire										bbuf_tag_done;
    wire [ TAG_W                -1 : 0 ]        bbuf_raw_stmem_tag;
    wire                                        bbuf_raw_stmem_tag_ready;  	
 
  
  	wire										bbuf_ldmem_tag_done_d;
  	reg											bbuf_ldmem_tag_done_q;
 //=============== Wires and Regs for WBUF tag_sync============
  	wire										wbuf_tag_req;
    wire										wbuf_tag_bias_prev_sw;
  	wire										wbuf_tag_ddr_pe_sw;
  	//wire										wbuf_tag_done;
    wire [ TAG_W                -1 : 0 ]        wbuf_raw_stmem_tag;
    wire                                        wbuf_raw_stmem_tag_ready;  	
  	wire										wbuf_ldmem_tag_done;
 
  	wire										param_ldmem_tag_done;

    wire [ TAG_W                -1 : 0 ]		wbuf_stmem_tag;
  
  	wire										wbuf_ldmem_tag_done_d;
  	reg											wbuf_ldmem_tag_done_q;
// Counting maximum number of group during decode // Current Group ID
//==============================================================================
    wire                                             sa_group_v;  
    reg     [ INST_GROUP_ID_W           - 1 : 0 ]    max_groups_counter;
    
    
      reg  [ TAG_W             -1 : 0 ]    next_tag_req_counter;
  wire                                 ld_param_buf_start;
  reg  [ INST_GROUP_ID_W   -1 : 0 ]    next_ld_group_id_counter;
  wire  [ INST_GROUP_ID_W   -1 : 0 ]    next_ld_group_id;
  
    assign  sa_group_v = (inst_group_type == SA_GROUP && inst_group_s_e == GROUP_START && inst_group_v);
    
    always @(posedge clk) begin
       if (reset || block_done)
          max_groups_counter <= 0;
      else if (sa_group_v)
          max_groups_counter <= max_groups_counter + 1'b1;
    end
    
    always @(posedge clk) begin
       if (reset)
         curr_cfg_loop_stride_group_id <= 0;
      else if (sa_group_v)
         curr_cfg_loop_stride_group_id <= inst_group_id;
    end
    
//==============================================================================
// Walker stride configurations for WBUF / BBUF
//==============================================================================
    assign ld_stride = cfg_loop_stride;
	assign ld_stride_segment = cfg_loop_stride_segment;
	 
	assign wbuf_cfg_mws_ld_loop_id = cfg_loop_stride_loop_id;
    assign bbuf_cfg_mws_ld_loop_id = cfg_loop_stride_loop_id;
	
    assign wbuf_ld_stride_v = cfg_loop_stride_v && (cfg_loop_stride_loop_id > NUM_BASE_LOOPS - 1) && cfg_loop_stride_type == MEM_LD && cfg_loop_stride_id == WBUF_MEM_ID;
	assign bbuf_ld_stride_v = cfg_loop_stride_v && (cfg_loop_stride_loop_id > NUM_BASE_LOOPS - 1) && cfg_loop_stride_type == MEM_LD && cfg_loop_stride_id == BBUF_MEM_ID;
	
	assign wbuf_cfg_mws_ld_stride_group_id = curr_cfg_loop_stride_group_id;
	assign bbuf_cfg_mws_ld_stride_group_id = curr_cfg_loop_stride_group_id;

    assign wbuf_mws_ld_base_addr = wbuf_tag_ld_addr[wbuf_ldmem_tag];
    assign bbuf_mws_ld_base_addr = bbuf_tag_ld_addr[bbuf_ldmem_tag];	


//==============================================================================

//==============================================================================
// Address generator for LOAD DATA from Offchip to WBUF
//==============================================================================
    assign wbuf_mws_ld_stall = ~wbuf_ldmem_tag_ready || ~axi_rd_ready;
    // assign wbuf_mws_ld_step = wbuf_mws_ld_index_valid && !wbuf_mws_ld_stall;
    
    // TODO: These walkers need to be updated such that they receive loop-id and also receove group id and can swithc to the next group
  
  mem_walker_stride_group #(
    .ADDR_WIDTH                     ( ADDR_WIDTH                     ),
    .ADDR_STRIDE_W                  ( ADDR_STRIDE_W                  ),
    .LOOP_ID_W                      ( LOOP_ID_W                      ),
    .GROUP_ID_W                     ( INST_GROUP_ID_W                ),
    .GROUP_ENABLED                  ( GROUP_ENABLED                  )
  ) mws_ld_wbuf (
    .clk                            ( clk                            ), //input
    .reset                          ( reset                          ), //input
    
    .base_addr                      ( wbuf_mws_ld_base_addr          ), //input
    .iter_done                      ( wbuf_fsm_iter_done             ), //input
    .start                          ( wbuf_mws_ld_start              ), //input
    .stall                          ( wbuf_mws_ld_stall              ),
    .block_done                     ( block_done                     ),
    .base_addr_v                    ( wbuf_mws_ld_start              ), //input
    
    .cfg_loop_id                    ( wbuf_cfg_mws_ld_loop_id        ), //input
    .cfg_addr_stride_v              ( wbuf_ld_stride_v               ), //input
    .cfg_addr_stride                ( ld_stride                      ), //input
    // NEW

    .cfg_loop_group_id              ( wbuf_cfg_mws_ld_stride_group_id     ), //input
    .loop_group_id                  ( next_ld_group_id                    ), //input
    
    //
    .addr_out                       ( wbuf_ld_addr                   ), //output
    .addr_out_valid                 ( wbuf_ld_addr_v                 )  //output
  );
//==============================================================================

//=============================================================
// Loop controller for WBUF
//=============================================================
  always @(posedge clk)
  begin
    if (reset)
      ld_iter_v_q <= 1'b0;
    else begin
      if (cfg_loop_iter_v && (cfg_loop_iter_loop_id > NUM_BASE_LOOPS - 1))
        ld_iter_v_q <= 1'b1;
      else if (cfg_loop_iter_v || wbuf_ld_stride_v || bbuf_ld_stride_v)
        ld_iter_v_q <= 1'b0;
    end
  end
  
  always @(posedge clk)
  begin
    if (reset) begin
      iter_q <= 0;
      loop_id_q <= 0;
      loop_level_q <= 0;
    end
    else if (cfg_loop_iter_v && (cfg_loop_iter_loop_id > NUM_BASE_LOOPS - 1)) begin
      iter_q <= cfg_loop_iter;
	  loop_id_q <= cfg_loop_iter_loop_id;
	  loop_level_q <= cfg_loop_iter_level; 
    end
  end

  
// We are assuming that first the loop instructions come and then the stride instructions come
    assign wbuf_mws_ld_start = (wbuf_ldmem_state_q == LDMEM_BUSY)&& (wbuf_ldmem_state_qq != LDMEM_BUSY);
    assign wbuf_mws_ld_loop_iter_v =  ld_iter_v_q && (loop_id_q == cfg_loop_stride_loop_id) && wbuf_ld_stride_v;
    assign wbuf_mws_ld_loop_iter = iter_q;
    assign wbuf_mws_ld_loop_iter_loop_id = loop_id_q;
  	// assign wbuf_mws_ld_loop_iter_loop_level = loop_level_q;
  	
  
  controller_fsm_group #(
    .LOOP_ID_W                      ( LOOP_ID_W                      ),
    .LOOP_ITER_W                    ( LOOP_ITER_W                    ),
    .GROUP_ID_W                     ( INST_GROUP_ID_W                ),
    .GROUP_ENABLED                  ( GROUP_ENABLED                  )
  ) mws_ld_ctrl_wbuf (
    .clk                            ( clk                            ), //input
    .reset                          ( reset                          ), //input
    
    .start                          ( wbuf_mws_ld_start                   ), //input
    .block_done                     ( block_done                          ), //input
    .done                           ( wbuf_mws_ld_done                    ), //output
    .stall                          ( wbuf_mws_ld_stall                   ), //input
    
    .cfg_loop_iter_v                ( wbuf_mws_ld_loop_iter_v             ), //input
    .cfg_loop_iter                  ( wbuf_mws_ld_loop_iter               ), //input
    .cfg_loop_iter_loop_id          ( wbuf_mws_ld_loop_iter_loop_id       ), //input
    
    .cfg_loop_group_id              ( wbuf_cfg_mws_ld_stride_group_id     ), //input
    .loop_group_id                  ( next_ld_group_id                    ), //input

    .iter_done                      ( wbuf_fsm_iter_done                  ),
    .current_iters                  ( wbuf_current_iters                  )
  );
//=============================================================
// Logic to Determine the next group ID for LD
//=============================================================

  
  assign ld_param_buf_start = wbuf_mws_ld_start; //(wbuf_ldmem_state_q == LDMEM_BUSY)  && (wbuf_ldmem_state_qq != LDMEM_BUSY);
  assign next_ld_group_id = next_ld_group_id_counter;
  

  always @(posedge clk) begin
      if (reset) begin
         next_tag_req_counter <= 0;
     end
     else if (ld_param_buf_start) begin
         if (next_tag_req_counter == NUM_TAGS - 1'b1)
            next_tag_req_counter <= 0;
         else
            next_tag_req_counter <= next_tag_req_counter + 1'b1;   
     end
  end 


  always @(posedge clk) begin
     if (reset) begin
        next_ld_group_id_counter <= 'd0;
     end
    else if (ld_param_buf_start && (next_tag_req_counter == NUM_TAGS - 1'b1)) begin
        if (next_ld_group_id_counter == max_groups_counter - 1)
            next_ld_group_id_counter <= 0;
        else
            next_ld_group_id_counter <= next_ld_group_id_counter + 1'b1;     
    end
  end

  assign parambuf_next_group_ld_id = next_ld_group_id_counter;

//=============================================================

//==============================================================================
// Address generator for LOAD DATA from Offchip to BBUF
//==============================================================================
    assign bbuf_mws_ld_stall = ~bbuf_ldmem_tag_ready || ~axi_rd_ready;
    // assign bbuf_mws_ld_step = bbuf_mws_ld_index_valid && !bbuf_mws_ld_stall;
  mem_walker_stride_group #(
    .ADDR_WIDTH                     ( ADDR_WIDTH                     ),
    .ADDR_STRIDE_W                  ( ADDR_STRIDE_W                  ),
    .LOOP_ID_W                      ( LOOP_ID_W                      ),
	.GROUP_ID_W                     ( INST_GROUP_ID_W                ),
    .GROUP_ENABLED                  ( GROUP_ENABLED                  )
  ) mws_ld_bbuf (
    .clk                            ( clk                            ), //input
    .reset                          ( reset                          ), //input
    
    .base_addr                      ( bbuf_mws_ld_base_addr          ), //input
    .iter_done                      ( bbuf_fsm_iter_done             ), //input
    .start                          ( bbuf_mws_ld_start              ), //input
    .stall                          ( bbuf_mws_ld_stall              ),
    .block_done                     ( block_done                     ), //input
    .base_addr_v                    ( bbuf_mws_ld_start              ), //input
    
    .cfg_loop_id                    ( bbuf_cfg_mws_ld_loop_id        ), //input
    .cfg_addr_stride_v              ( bbuf_ld_stride_v               ), //input
    .cfg_addr_stride                ( ld_stride                      ), //input
    // NEW
    .cfg_loop_group_id              ( bbuf_cfg_mws_ld_stride_group_id     ), //input
    .loop_group_id                  ( next_ld_group_id                    ), //input
    //
    .addr_out                       ( bbuf_ld_addr                   ), //output
    .addr_out_valid                 ( bbuf_ld_addr_v                 )  //output
  );
//==============================================================================

//=============================================================
// Loop controller for BBUF
//=============================================================


// We are assuming that first the loop instructions come and then the stride instructions come
    assign bbuf_mws_ld_start = (bbuf_ldmem_state_q == LDMEM_BUSY) && (bbuf_ldmem_state_qq != LDMEM_BUSY);
    assign bbuf_mws_ld_loop_iter_v =  ld_iter_v_q && (loop_id_q == cfg_loop_stride_loop_id) && bbuf_ld_stride_v;
    assign bbuf_mws_ld_loop_iter = iter_q;
    assign bbuf_mws_ld_loop_iter_loop_id = loop_id_q;
  	assign bbuf_mws_ld_loop_iter_loop_level = loop_level_q;


  controller_fsm_group #(
    .LOOP_ID_W                      ( LOOP_ID_W                      ),
    .LOOP_ITER_W                    ( LOOP_ITER_W                    ),
    .GROUP_ID_W                     ( INST_GROUP_ID_W                ),
    .GROUP_ENABLED                  ( GROUP_ENABLED                  )
  ) mws_ld_ctrl_bbuf (
    .clk                            ( clk                            ), //input
    .reset                          ( reset                          ), //input
    
    .start                          ( bbuf_mws_ld_start                   ), //input
    .block_done                     ( block_done                          ), //input
    .done                           ( bbuf_mws_ld_done                    ), //output
    .stall                          ( bbuf_mws_ld_stall                   ), //input
    
    .cfg_loop_iter_v                ( bbuf_mws_ld_loop_iter_v             ), //input
    .cfg_loop_iter                  ( bbuf_mws_ld_loop_iter               ), //input
    .cfg_loop_iter_loop_id          ( bbuf_mws_ld_loop_iter_loop_id       ), //input
    
    .cfg_loop_group_id              ( bbuf_cfg_mws_ld_stride_group_id     ), //input
    .loop_group_id                  ( next_ld_group_id                    ), //input

    .iter_done                      ( bbuf_fsm_iter_done                  ),
    .current_iters                  ( bbuf_current_iters                  )
  );
//=============================================================


//==============================================================================
// Memory Request generation for WBUF/BBUF
//==============================================================================
    assign wbuf_ld_mem_req_v = cfg_mem_req_v && (cfg_mem_req_loop_id >  NUM_BASE_LOOPS - 1) && cfg_mem_req_type == MEM_LD && cfg_mem_req_id == WBUF_MEM_ID;
  
  always @(posedge clk)
  begin
    if (reset) begin
      wbuf_ld_req_size <= 1'b0;
    end
    else if (wbuf_ld_mem_req_v) begin
      wbuf_ld_req_size <= cfg_mem_req_size;
    end
  end


    assign bbuf_ld_mem_req_v = cfg_mem_req_v && (cfg_mem_req_loop_id >  NUM_BASE_LOOPS - 1) && cfg_mem_req_type == MEM_LD && cfg_mem_req_id == BBUF_MEM_ID;
  
  always @(posedge clk)
  begin
    if (reset) begin
      bbuf_ld_req_size <= 1'b0;
    end
    else if (bbuf_ld_mem_req_v) begin
      bbuf_ld_req_size <= cfg_mem_req_size;
    end
  end
  

    assign wbuf_ld_req_valid_d = wbuf_ld_addr_v;

  always @(posedge clk)
  begin
    if (reset) begin
      wbuf_ld_req_valid_q <= 1'b0;
      wbuf_ld_req_addr <= 1'b0;
    end
    else begin
      wbuf_ld_req_valid_q <= wbuf_ld_req_valid_d;
      wbuf_ld_req_addr <= wbuf_ld_addr;
    end
  end



    assign bbuf_ld_req_valid_d = bbuf_ld_addr_v;

  always @(posedge clk)
  begin
    if (reset) begin
      bbuf_ld_req_valid_q <= 1'b0;
      bbuf_ld_req_addr <= 1'b0;
    end
    else begin
      bbuf_ld_req_valid_q <= bbuf_ld_req_valid_d;
      bbuf_ld_req_addr <= bbuf_ld_addr;
    end
  end


  always @(posedge clk)
  begin
    if (reset) begin
      wbuf_tag_ld_addr[0] <= 0;
      wbuf_tag_ld_addr[1] <= 0;
    end
//    if (tag_req && wbuf_tag_ready) begin
    if (wbuf_base_addr_v) begin
      wbuf_tag_ld_addr[wbuf_tag] <= tag_base_wbuf_ld_addr;
    end
  end
  

  // Fixing the tag_bbuf_base_addr issue (tag_alloc not being synchronized with bbuf_tag_req (delayed after WBUF LD))
  reg  [ TAG_W                -1 : 0 ]        _bbuf_tag_alloc;
  always @(posedge clk) begin
    if (reset || block_done)
       _bbuf_tag_alloc <= 0;
    else if (bbuf_base_addr_v) begin
      if (_bbuf_tag_alloc == NUM_TAGS - 1)
         _bbuf_tag_alloc <= 0;
      else
         _bbuf_tag_alloc <= _bbuf_tag_alloc + 1; 
    end
  end


  always @(posedge clk)
  begin
    if (reset) begin
      bbuf_tag_ld_addr[0] <= 0;
      bbuf_tag_ld_addr[1] <= 0;
    end
//    if (bbuf_tag_req && bbuf_tag_ready) begin
    if (bbuf_base_addr_v) begin
      bbuf_tag_ld_addr[_bbuf_tag_alloc] <= tag_base_bbuf_ld_addr;
    end
  end  
//==============================================================================


  wire wbuf_ldmem_tag_ready_sm;
 assign wbuf_ldmem_tag_ready_sm = bbuf_ldmem_state_q == LDMEM_IDLE ? wbuf_ldmem_tag_ready : 1'b0;
//==============================================================================
// Tag-based synchronization for double buffering / WBUFF
//==============================================================================
  always @(*)
  begin
    wbuf_ldmem_state_d = wbuf_ldmem_state_q;
    case(wbuf_ldmem_state_q)
      LDMEM_IDLE: begin
        if (wbuf_ldmem_tag_ready_sm) begin
          wbuf_ldmem_state_d = LDMEM_BUSY;
        end
      end
      LDMEM_BUSY: begin
        //if (wbuf_mws_ld_done)
          wbuf_ldmem_state_d = LDMEM_WAIT_0;
      end
      LDMEM_WAIT_0: begin
        wbuf_ldmem_state_d = LDMEM_WAIT_1;
      end
      LDMEM_WAIT_1: begin
        wbuf_ldmem_state_d = LDMEM_WAIT_2;
      end
      LDMEM_WAIT_2: begin
        wbuf_ldmem_state_d = LDMEM_WAIT_3;
      end
      LDMEM_WAIT_3: begin
        if (axi_rd_done)
          wbuf_ldmem_state_d = LDMEM_DONE;
      end
      LDMEM_DONE: begin
	      //if (wbuf_ldmem_tag_done_q)
        wbuf_ldmem_state_d = LDMEM_IDLE;
      end
    endcase
  end


  always @(posedge clk)
  begin
    if (reset)
      wbuf_ldmem_state_q <= LDMEM_IDLE;
    else
      wbuf_ldmem_state_q <= wbuf_ldmem_state_d;
  end

    always @(posedge clk)
        wbuf_ldmem_state_qq <= wbuf_ldmem_state_q;

// There is no store for WBUFF
  always @(*)
  begin
    wbuf_stmem_state_d = wbuf_stmem_state_q;
    case(wbuf_stmem_state_q)
      STMEM_IDLE: begin
        if (wbuf_stmem_tag_ready) begin
            wbuf_stmem_state_d = STMEM_DONE;
        end
      end
      STMEM_DONE: begin
        wbuf_stmem_state_d = STMEM_IDLE;
      end
    endcase
  end

  always @(posedge clk)
  begin
    if (reset)
      wbuf_stmem_state_q <= STMEM_IDLE;
    else
      wbuf_stmem_state_q <= wbuf_stmem_state_d;
  end
//


   
    assign wbuf_raw_stmem_tag = 0;
  	assign param_ldmem_tag_done = wbuf_ldmem_tag_done_q && bbuf_ldmem_tag_done_d;
    // added the _d signal to make it high for one cycle
    assign wbuf_ldmem_tag_done_d = wbuf_ldmem_state_q == LDMEM_DONE && wbuf_ldmem_state_d == LDMEM_IDLE;
    assign bbuf_ldmem_tag_done_d = bbuf_ldmem_state_q == LDMEM_DONE && bbuf_ldmem_state_d == LDMEM_IDLE;
  
    always @(posedge clk)
    begin
      if (reset)
         wbuf_ldmem_tag_done_q <= 1'b0;
      else
         wbuf_ldmem_tag_done_q <= wbuf_ldmem_tag_done_d;
    end 
    

  	assign wbuf_tag_req = tag_req;
  	assign wbuf_tag_bias_prev_sw = tag_bias_prev_sw;
  	assign wbuf_tag_ddr_pe_sw = tag_ddr_pe_sw;
  	assign wbuf_compute_tag_done = compute_done;
    assign wbuf_stmem_tag_done = wbuf_stmem_state_q == STMEM_DONE;

  tag_sync  #(
    .NUM_TAGS                       ( NUM_TAGS                       ),
    .STORE_ENABLED					( STORE_ENABLED                  ),
    .TAG_REUSE_COUNTER_W            ( TAG_REUSE_COUNTER_W            )
  )
  mws_tag_wbuf (
    .clk                            ( clk                            ),
    .reset                          ( reset                          ),
    .block_done                     ( block_done                     ),
    .tag_req                        ( wbuf_tag_req                        ),
    .tag_reuse                      ( wbuf_tag_reuse                      ),
    .tag_bias_prev_sw               ( wbuf_tag_bias_prev_sw               ),
    .tag_ddr_pe_sw                  ( wbuf_tag_ddr_pe_sw                  ), //input
    .tag_ready                      ( wbuf_tag_ready                      ),
    .tag                            ( wbuf_tag                            ),
    .tag_done                       ( wbuf_tag_done                       ),
    .raw_stmem_tag                  ( wbuf_raw_stmem_tag                  ),
    .raw_stmem_tag_ready            ( wbuf_raw_stmem_tag_ready            ),
    .compute_tag_done               ( wbuf_compute_tag_done               ),
    .compute_tag_ready              ( wbuf_compute_tag_ready              ),
    .compute_bias_prev_sw           ( wbuf_compute_bias_prev_sw           ),
    .compute_tag                    ( wbuf_compute_tag                    ),
    .ldmem_tag_done                 ( wbuf_ldmem_tag_done_d                 ),
    .ldmem_tag_ready                ( wbuf_ldmem_tag_ready                ),
    .ldmem_tag                      ( wbuf_ldmem_tag                      ),
    .stmem_ddr_pe_sw                ( wbuf_stmem_ddr_pe_sw                ),
    .stmem_tag_done                 ( wbuf_stmem_tag_done                 ),
    .stmem_tag_ready                ( wbuf_stmem_tag_ready                ),
    .stmem_tag                      ( wbuf_stmem_tag                      ),
    .last_store_en                  (last_store_en                        )
  );
//==============================================================================

wire bbuf_ldmem_tag_ready_sm;
assign bbuf_ldmem_tag_ready_sm = wbuf_ldmem_state_q == LDMEM_DONE ? bbuf_ldmem_tag_ready : 'b0;
//==============================================================================
// Tag-based synchronization for double buffering / BBUFF
//==============================================================================
  always @(*)
  begin
    bbuf_ldmem_state_d = bbuf_ldmem_state_q;
    case(bbuf_ldmem_state_q)
      LDMEM_IDLE: begin
        if (bbuf_ldmem_tag_ready_sm) begin
          bbuf_ldmem_state_d = LDMEM_BUSY;
        end
      end
      LDMEM_BUSY: begin
        //if (bbuf_mws_ld_done)
          bbuf_ldmem_state_d = LDMEM_WAIT_0;
      end
      LDMEM_WAIT_0: begin
        bbuf_ldmem_state_d = LDMEM_WAIT_1;
      end
      LDMEM_WAIT_1: begin
        bbuf_ldmem_state_d = LDMEM_WAIT_2;
      end
      LDMEM_WAIT_2: begin
        bbuf_ldmem_state_d = LDMEM_WAIT_3;
      end
      LDMEM_WAIT_3: begin
        if (axi_rd_done)
          bbuf_ldmem_state_d = LDMEM_DONE;
      end
      LDMEM_DONE: begin
	      //if (bbuf_ldmem_tag_done_d)
        bbuf_ldmem_state_d = LDMEM_IDLE;
      end
    endcase
  end


  always @(posedge clk)
  begin
    if (reset)
      bbuf_ldmem_state_q <= LDMEM_IDLE;
    else
      bbuf_ldmem_state_q <= bbuf_ldmem_state_d;
  end

    always @(posedge clk)
      if (reset)
        bbuf_ldmem_state_qq <= 0;
      else
        bbuf_ldmem_state_qq <= bbuf_ldmem_state_q;

// There is no store for BBUFF
  always @(*)
  begin
    bbuf_stmem_state_d = bbuf_stmem_state_q;
    case(bbuf_stmem_state_q)
      STMEM_IDLE: begin
        if (bbuf_stmem_tag_ready) begin
            bbuf_stmem_state_d = STMEM_DONE;
        end
      end
      STMEM_DONE: begin
        bbuf_stmem_state_d = STMEM_IDLE;
      end
    endcase
  end

  always @(posedge clk)
  begin
    if (reset)
      bbuf_stmem_state_q <= STMEM_IDLE;
    else
      bbuf_stmem_state_q <= bbuf_stmem_state_d;
  end
//


    //wire bbuf_tag_reuse_qq;
    //register_sync #(1) bbuf_tag_reuse_reg (clk, reset, bbuf_tag_reuse_q, bbuf_tag_reuse_qq);
    
    assign bbuf_raw_stmem_tag = 0;
  
    //assign bbuf_ldmem_tag_done_d = bbuf_ldmem_state_q == LDMEM_DONE;

    //always @(posedge clk)
    //begin
    //  if (reset)
    //     bbuf_ldmem_tag_done_q <= 1'b0;
    //  else if (~bbuf_tag_reuse_qq)
    //     bbuf_ldmem_tag_done_q <= bbuf_ldmem_tag_done_d;
    //end wbuf_ldmem_tag_done_d
    
    // TODO: Make sure that these do not need to be registered
    assign parambuf_tag_ready = wbuf_tag_ready && bbuf_tag_ready;
    assign parambuf_compute_ready = wbuf_compute_tag_ready && bbuf_compute_tag_ready;
    //assign parambuf_tag_done = wbuf_tag_done && bbuf_tag_done;

  	// It seems like the following signals are useless, I don't think the value of these signals is important here
    wire										bbuf_tag_bias_prev_sw;
  	wire										bbuf_tag_ddr_pe_sw;
    //
    
      
  	assign bbuf_compute_tag_done = compute_done;
    assign bbuf_stmem_tag_done = bbuf_stmem_state_q == STMEM_DONE;
    

  // Added double buffering (one in controller) since the reuse for the second tile is already set in the controller. So, need another reg
  // to only sample it when the first tile is fetched. Else, the state machine does not fetch the first tile and gets struck
    //reg bbuf_tag_reuse_q;
    //wire bbuf_tag_reuse_w;

    //always @(posedge clk) begin
    //  if (reset)
    //    bbuf_tag_reuse_q <= 1'b0;
    //  else if (param_ldmem_tag_done && wbuf_ldmem_state_q == LDMEM_DONE)
    //    bbuf_tag_reuse_q <= bbuf_tag_reuse;
    //end

  
  register_sync #(1) bbuf_tag_req_reg (clk, reset, tag_req, bbuf_tag_req_d);
  register_sync #(1) bbuf_tag_reuse_reg (clk, reset, bbuf_tag_reuse, bbuf_tag_reuse_d);
  
  //assign bbuf_tag_reuse_w = bbuf_tag_reuse & ~bbuf_tag_reuse_d;
  
  //assign bbuf_tag_reuse_pulse = bbuf_tag_reuse_w;

  tag_sync  #(
    .NUM_TAGS                       ( NUM_TAGS                       ),
    .STORE_ENABLED					( STORE_ENABLED                  ),
    .TAG_REUSE_COUNTER_W            ( TAG_REUSE_COUNTER_W            )
  )
  mws_tag_bbuf (
    .clk                            ( clk                            ),
    .reset                          ( reset                          ),
    .block_done                     ( block_done                     ),
    .tag_req                        ( bbuf_tag_req_d                        ),
    .tag_reuse                      ( bbuf_tag_reuse_d                      ),
    .tag_bias_prev_sw               ( bbuf_tag_bias_prev_sw               ),
    .tag_ddr_pe_sw                  ( bbuf_tag_ddr_pe_sw                  ), //input
    .tag_ready                      ( bbuf_tag_ready                      ),
    .tag                            ( bbuf_tag                            ),
    .tag_done                       ( bbuf_tag_done                       ),
    .raw_stmem_tag                  ( bbuf_raw_stmem_tag                  ),
    .raw_stmem_tag_ready            ( bbuf_raw_stmem_tag_ready            ),
    .compute_tag_done               ( bbuf_compute_tag_done               ),
    .compute_tag_ready              ( bbuf_compute_tag_ready              ),
    .compute_bias_prev_sw           ( bbuf_compute_bias_prev_sw           ),
    .compute_tag                    ( bbuf_compute_tag                    ),
    .ldmem_tag_done                 ( bbuf_ldmem_tag_done_d                 ),
    .ldmem_tag_ready                ( bbuf_ldmem_tag_ready                ),
    .ldmem_tag                      ( bbuf_ldmem_tag                      ),
    .stmem_ddr_pe_sw                ( bbuf_stmem_ddr_pe_sw                ),
    .stmem_tag_done                 ( bbuf_stmem_tag_done                 ),
    .stmem_tag_ready                ( bbuf_stmem_tag_ready                ),
    .stmem_tag                      ( bbuf_stmem_tag                      ),
    .last_store_en                  (last_store_en                        )
  );
//==============================================================================
//==============================================================================
// AXI4 Memory Mapped interface
//==============================================================================
    assign mem_write_ready = 1'b1;
    assign mem_read_data = 0;
    assign axi_wr_data_v = 1'b0;
    
    reg 						wbuf_write_en_q;
    wire						wbuf_write_en_d;
 
    reg 						bbuf_write_en_q;
    wire						bbuf_write_en_d;
    


    
    assign wbuf_write_en_d = (wbuf_ldmem_state_q == LDMEM_BUSY) || (wbuf_ldmem_state_q == LDMEM_WAIT_0) || (wbuf_ldmem_state_q == LDMEM_WAIT_1) || (wbuf_ldmem_state_q == LDMEM_WAIT_2) || (wbuf_ldmem_state_q == LDMEM_WAIT_3);   
    always @(posedge clk) begin
	    if (reset)
		   wbuf_write_en_q <= 1'b0;
	    else
		    wbuf_write_en_q <= wbuf_write_en_d;
	end
 
 
    assign bbuf_write_en_d = (bbuf_ldmem_state_q == LDMEM_BUSY) || (bbuf_ldmem_state_q == LDMEM_WAIT_0) || (bbuf_ldmem_state_q == LDMEM_WAIT_1) || (bbuf_ldmem_state_q == LDMEM_WAIT_2) || (bbuf_ldmem_state_q == LDMEM_WAIT_3);   
    always @(posedge clk) begin
	    if (reset)
		   bbuf_write_en_q <= 1'b0;
	    else
		    bbuf_write_en_q <= bbuf_write_en_d;
	end
 
 
    
  
    assign axi_rd_req = wbuf_ld_req_valid_q || bbuf_ld_req_valid_q;
    
    always @(*) begin
       axi_rd_req_size = 0;
	     axi_rd_addr = 0;
	   
     if (wbuf_ld_req_valid_q) begin
       // rohan temp fix
		   //axi_rd_req_size = wbuf_ld_req_size * (ARRAY_N * ARRAY_M * WGT_DATA_WIDTH) / 8;
       axi_rd_req_size = wbuf_ld_req_size * ARRAY_N * ARRAY_M;
	   	   axi_rd_addr = wbuf_ld_req_addr;
	   end
	   else if (bbuf_ld_req_valid_q) begin
		   //axi_rd_req_size = bbuf_ld_req_size * (ARRAY_M * BIAS_DATA_WIDTH) / 8;
	     axi_rd_req_size = bbuf_ld_req_size * ARRAY_M;
       axi_rd_addr = bbuf_ld_req_addr;
	   end
	end
 
    assign axi_wr_req = 1'b0;
    assign axi_wr_req_id = 1'b0;
    assign axi_wr_req_size = 0;
    assign axi_wr_addr = 0;
  
  ddr_memory_interface_control_m_axi #(
    .C_XFER_SIZE_WIDTH                  ( MEM_REQ_W*2                      ),
    .C_M_AXI_DATA_WIDTH                 ( AXI_DATA_WIDTH                 ),
    .C_M_AXI_ADDR_WIDTH                 ( AXI_ADDR_WIDTH                 )
  ) u_axi_mm_master (
    .clk                            ( clk                            ),
    .reset                          ( reset                          ),
    .kernel_clk                     ( clk                            ),                    
    .kernel_rst                     ( reset                          ),
    .m_axi_awaddr                   ( mws_awaddr                     ),
    .m_axi_awlen                    ( mws_awlen                      ),
//    .m_axi_awsize                   ( mws_awsize                     ),
//    .m_axi_awburst                  ( mws_awburst                    ),
    .m_axi_awvalid                  ( mws_awvalid                    ),
    .m_axi_awready                  ( mws_awready                    ),
    .m_axi_wdata                    ( mws_wdata                      ),
    .m_axi_wstrb                    ( mws_wstrb                      ),
    .m_axi_wlast                    ( mws_wlast                      ),
    .m_axi_wvalid                   ( mws_wvalid                     ),
    .m_axi_wready                   ( mws_wready                     ),
//    .m_axi_bresp                    ( mws_bresp                      ),
    .m_axi_bvalid                   ( mws_bvalid                     ),
    .m_axi_bready                   ( mws_bready                     ),
    .m_axi_araddr                   ( mws_araddr                     ),
//    .m_axi_arid                     ( mws_arid                       ),
    .m_axi_arlen                    ( mws_arlen                      ),
//    .m_axi_arsize                   ( mws_arsize                     ),
//    .m_axi_arburst                  ( mws_arburst                    ),
    .m_axi_arvalid                  ( mws_arvalid                    ),
    .m_axi_arready                  ( mws_arready                    ),
    .m_axi_rdata                    ( mws_rdata                      ),
//    .m_axi_rid                      ( mws_rid                        ),
//    .m_axi_rresp                    ( mws_rresp                      ),
    .m_axi_rlast                    ( mws_rlast                      ),
    .m_axi_rvalid                   ( mws_rvalid                     ),
    .m_axi_rready                   ( mws_rready                     ),
    
     // Buffer
    .ap_start_rd                    ( axi_rd_req                     ),
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

//==============================================================================
// WBUF Offchip-Systolic Interface
//==============================================================================

// Systolic Buffer Read
  assign wbuf_compute_tag_delayed = wbuf_compute_tag;

  // assign tag_wbuf_read_addr = {wbuf_compute_tag_delayed, wbuf_read_addr};
  assign wbuf_read_addr_out = {wbuf_compute_tag_delayed, wbuf_read_addr};
  
  assign wbuf_read_req_out = wbuf_read_req;
//


  reg [ COUNTER_GROUP_WIDTH     -1 : 0 ] 		wbuf_counter_group;
  reg [ WBUF_ADDR_W				-1 : 0 ]		wbuf_counter_write_addr;
  reg [ COUNTER_COL_WIDTH		-1 : 0 ]        wbuf_counter_write_col;
  
  wire [ WBUF_ADDR_W             -1 : 0 ]        _wbuf_write_addr;
  wire [ TAG_WBUF_ADDR_W         -1 : 0 ]        tag_wbuf_write_addr;
  wire [ WBUF_WRITE_GROUP_SIZE*TAG_WBUF_ADDR_W-1 : 0]  group_tag_wbuf_write_addr;
  wire [ WBUF_WRITE_GROUP_SIZE*WBUF_REQ_WIDTH-1 : 0]  group_wbuf_write_req;
  
  wire [ WBUF_REQ_WIDTH         -1 : 0 ]		wbuf_req_id;



// Systolic Buffer Write
// counters for write gorups, write addresses
//
   always @(posedge clk)
  begin
      if (reset)
          wbuf_counter_group <= 0;
      else if (mem_write_req && wbuf_write_en_q) begin
         if (wbuf_counter_group == NUM_WBUF_WRITE_GROUPS - 1)
             wbuf_counter_group <= 0;
         else
             wbuf_counter_group <= wbuf_counter_group + 1'b1;
      end
  end
//

  always @(posedge clk)
  begin
      if (reset)
          wbuf_counter_write_col <= ARRAY_M - 1;
      else if (mem_write_req && wbuf_write_en_q && (wbuf_counter_group == NUM_WBUF_WRITE_GROUPS - 1)) begin
          if (wbuf_counter_write_col == 0)
              wbuf_counter_write_col <= ARRAY_M - 1;
          else
              wbuf_counter_write_col <= wbuf_counter_write_col - 1'b1;
      end
  end
 //

//
  always @(posedge clk)
  begin
      if (reset)
          wbuf_counter_write_addr <= 0;
      else begin 
          if (mem_write_req && wbuf_write_en_q && (wbuf_counter_group == NUM_WBUF_WRITE_GROUPS - 1) && (wbuf_counter_write_col == 0)) 
            wbuf_counter_write_addr <= wbuf_counter_write_addr + 1'b1;
          else if (wbuf_ldmem_state_q == LDMEM_DONE)
            wbuf_counter_write_addr <= 0;
      end
  end
//
//

// ASSIGNs

//Assign Data out
  assign wbuf_write_data_out = {NUM_WBUF_WRITE_GROUPS{mem_write_data}};
  
  
//Assign Address out  
  assign  _wbuf_write_addr = wbuf_counter_write_addr;
  assign tag_wbuf_write_addr = {wbuf_ldmem_tag, _wbuf_write_addr};
  
  genvar i;
  generate
  	for (i=0; i<WBUF_WRITE_GROUP_SIZE; i=i+1) begin
	  	assign group_tag_wbuf_write_addr[(i+1)*TAG_WBUF_ADDR_W-1: i*TAG_WBUF_ADDR_W] = tag_wbuf_write_addr;  	
  	end
  endgenerate
  
  assign wbuf_write_addr_out = {NUM_WBUF_WRITE_GROUPS{group_tag_wbuf_write_addr}};
  
  
//Assign Address Req Out
  assign wbuf_req_id = (wbuf_write_en_q && mem_write_req) ? (wbuf_counter_write_col + 1'b1) : 0;

  genvar j;
  generate
	  for (j=0; j<WBUF_WRITE_GROUP_SIZE; j=j+1) begin
	  	  assign group_wbuf_write_req[(j+1)*WBUF_REQ_WIDTH-1: j*WBUF_REQ_WIDTH] = wbuf_req_id;
	  end
  endgenerate
  
  genvar k;
  generate
	  for (k=0; k<NUM_WBUF_WRITE_GROUPS; k=k+1) begin
			  assign wbuf_write_req_out[(k+1)*WBUF_WRITE_GROUP_SIZE*WBUF_REQ_WIDTH-1: (k)*WBUF_WRITE_GROUP_SIZE*WBUF_REQ_WIDTH] = (wbuf_counter_group == k) ? group_wbuf_write_req : 0;
	  end
  endgenerate

//==============================================================================


//==============================================================================
// BBUF Offchip-Systolic Interface
//==============================================================================

// Systolic Buffer Read for BBUF
  assign bbuf_compute_tag_delayed = bbuf_compute_tag;

  // assign tag_bbuf_read_addr = {bbuf_compute_tag_delayed, bbuf_read_addr};
  assign bbuf_read_addr_out = {bbuf_compute_tag_delayed, bbuf_read_addr};
  
  assign bbuf_read_req_out = bbuf_read_req;
//


  reg [ COUNTER_BBUF_GROUP_WIDTH     -1 : 0 ]   bbuf_counter_group;
  reg [ BBUF_ADDR_W				-1 : 0 ]		bbuf_counter_write_addr;
  
  wire [ BBUF_ADDR_W             -1 : 0 ]        _bbuf_write_addr;
  wire [ TAG_BBUF_ADDR_W         -1 : 0 ]        tag_bbuf_write_addr;
  wire [ BBUF_WRITE_GROUP_SIZE*TAG_BBUF_ADDR_W-1 : 0]  group_tag_bbuf_write_addr;
  wire [ BBUF_WRITE_GROUP_SIZE   -1 : 0]               group_bbuf_write_req;
  wire											_bbuf_write_req;
  

// Systolic Buffer Write---BBUF
// counters for write gorups, write addresses
//
  always @(posedge clk)
  begin
	  if (reset)
		  bbuf_counter_group <= 0;
	  else if (mem_write_req && bbuf_write_en_q) begin
		  if (bbuf_counter_group == NUM_BBUF_WRITE_GROUPS -1)
			  bbuf_counter_group <= 0;
		  else
			  bbuf_counter_group <= bbuf_counter_group + 1'b1;
	  end
  end
 //

//
  always @(posedge clk)
  begin
	  if (reset)
		  bbuf_counter_write_addr <= 0;
	  else begin 
		  if (mem_write_req && bbuf_write_en_q && bbuf_counter_group == NUM_BBUF_WRITE_GROUPS - 1)  
		  	bbuf_counter_write_addr <= bbuf_counter_write_addr + 1'b1;
		  else if (bbuf_ldmem_state_q == LDMEM_DONE)
			bbuf_counter_write_addr <= 0;
	  end
  end
//


// ASSIGNs

//Assign Data out
  assign bbuf_write_data_out = {NUM_BBUF_WRITE_GROUPS{mem_write_data}};
  
  
//Assign Address out  
  assign  _bbuf_write_addr = bbuf_counter_write_addr;
  assign tag_bbuf_write_addr = {bbuf_ldmem_tag, _bbuf_write_addr};
  
  generate
  	for (i=0; i<BBUF_WRITE_GROUP_SIZE; i=i+1) begin
	  	assign group_tag_bbuf_write_addr[(i+1)*TAG_BBUF_ADDR_W-1: i*TAG_BBUF_ADDR_W] = tag_bbuf_write_addr;  	
  	end
  endgenerate
  
  assign bbuf_write_addr_out = {NUM_BBUF_WRITE_GROUPS{group_tag_bbuf_write_addr}};
  
  
//Assign Address Req Out
  assign _bbuf_write_req = (bbuf_write_en_q && mem_write_req) ? 1'b1 : 1'b0;

  
  generate
	  for (k=0; k<NUM_BBUF_WRITE_GROUPS; k=k+1) begin
			  assign bbuf_write_req_out[(k+1)*BBUF_WRITE_GROUP_SIZE-1: (k)*BBUF_WRITE_GROUP_SIZE] = (bbuf_counter_group == k) ? {BBUF_WRITE_GROUP_SIZE{_bbuf_write_req}} :0;
	  end
  endgenerate

//==============================================================================

endmodule