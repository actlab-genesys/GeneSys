//
// The Input Buffer interface with Offchip memory and SIMD array
// The IBUF itslef is another sperate module



`timescale 1ns/1ps
module ibuf_interface #(
  // Internal Parameters
    parameter integer  MEM_ID                       = 1,
    parameter integer  NUM_BASE_LOOPS				= 7,
    parameter integer  MEM_REQ_W                    = 16,
    parameter integer  ADDR_WIDTH                   = 8,
    parameter integer  DATA_WIDTH                   = 8,
    parameter integer  LOOP_ITER_W                  = 16,
    parameter integer  ADDR_STRIDE_W                = 32,
    parameter integer  LOOP_ID_W                    = 6,
    parameter integer  BUF_TYPE_W                   = 2,
    parameter integer  NUM_BUF_TYPE					= 2**(BUF_TYPE_W),
    parameter integer  NUM_TAGS                     = 2,
    parameter integer  TAG_W                        = $clog2(NUM_TAGS),
    parameter integer  TAG_REUSE_COUNTER_W          = 3,
    parameter integer  INST_GROUP_ID_W				= 4,
    
  // AXI
    parameter integer  AXI_ADDR_WIDTH               = 42,
    parameter integer  AXI_ID_WIDTH                 = 1,
    parameter integer  AXI_DATA_WIDTH               = 64,
    parameter integer  AXI_DATA_WIDTH_BYTES         = AXI_DATA_WIDTH/8,
    parameter integer  AXI_DATA_WIDTH_LOG_BYTES     = $clog2(AXI_DATA_WIDTH/8),
    parameter integer  AXI_BURST_WIDTH              = 8,
    parameter integer  WSTRB_W                      = AXI_DATA_WIDTH/8,

    parameter integer IBUF_WRITE_WIDTH              = 8,
    parameter integer IBUF_WRITE_ADDR_WIDTH         = 8,
    parameter integer IBUF_READ_WIDTH              = 8,
    parameter integer IBUF_READ_ADDR_WIDTH         = 8,

  // Buffer
    parameter integer  ARRAY_N                      = 32,
    parameter integer  BUF_ADDR_W                   = 16,
    parameter integer  TAG_BUF_ADDR_W               = BUF_ADDR_W + TAG_W,
    parameter integer  BUF_WRITE_GROUP_SIZE_EXT		= AXI_DATA_WIDTH / DATA_WIDTH,
    parameter integer  BUF_WRITE_GROUP_SIZE_ARRAY_EXT = ARRAY_N < BUF_WRITE_GROUP_SIZE_EXT ? ARRAY_N : BUF_WRITE_GROUP_SIZE_EXT ,  
    parameter integer  BUF_WRITE_NUM_GROUP_EXT		= ARRAY_N < BUF_WRITE_GROUP_SIZE_EXT ? 1 : ARRAY_N / BUF_WRITE_GROUP_SIZE_EXT,
    parameter integer  COUNTER_BUF_WRITE_GROUP_W    = $clog2(BUF_WRITE_NUM_GROUP_EXT) + 1,
    // The default case is that we use the maximum available on-chip bandwdith and write to all ARRAY_N number of IBUF banks!
    parameter integer  BUF_WRITE_GROUP_SIZE_SIMD	= ARRAY_N,
    // todo: rohan change accordingly
    parameter integer  BUF_WRITE_NUM_GROUP_SIMD 	= ARRAY_N / BUF_WRITE_GROUP_SIZE_SIMD,
    parameter integer  GROUP_ENABLED                = 0,
    parameter integer  PC_DATA_WIDTH                = 64



) (
    input  wire                                         clk,
    input  wire                                         reset,

    input  wire                                         tag_req,
    input  wire                                         tag_reuse,
    input  wire                                         tag_bias_prev_sw,
    input  wire                                         tag_ddr_pe_sw,
    output wire                                         tag_ready,
    output wire                                         tag_done,
    input  wire                                         compute_done,

    input  wire  [ ADDR_WIDTH           -1 : 0 ]        tag_base_ld_addr,
    input  wire                                         base_ld_addr_v,
    
    input  wire                                         block_done,
    
    // We use this signal as the valid signal for compute group base addr
    output wire                                         compute_ready,
    output wire                                         compute_bias_prev_sw,

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
    
 // The Group instructions for filling IBUF for fused conv/fc layers   
    input wire	 [ INST_GROUP_ID_W       -1 : 0 ]		inst_group_id,
    input wire											inst_group_type,
    input wire  										inst_group_s_e,
    input wire											inst_group_v,
    input wire	 [ LOOP_ID_W			 -1 : 0 ]		inst_group_sa_loop_id,
    input wire											inst_group_last,
    
    output wire                                         buf_ld_first_group,
    output wire  [ INST_GROUP_ID_W       -1 : 0 ]       compute_group_id,

    
    
  // Data from SIMD Array
    input  wire  [ ARRAY_N              -1 : 0 ]        simd_ibuf_write_req,
    input  wire  [ ARRAY_N*BUF_ADDR_W   -1 : 0 ]        simd_ibuf_write_addr,
    input  wire  [ARRAY_N*DATA_WIDTH    -1 : 0 ]        simd_ibuf_write_data,

  // Systolic Array reading from IBUF, 
    input  wire                                         buf_read_req,
    input  wire  [ BUF_ADDR_W           -1 : 0 ]        buf_read_addr,
    output  wire                                        buf_read_req_out,
    output  wire  [ TAG_BUF_ADDR_W      -1 : 0 ]        buf_read_addr_out,
    
  // Write to IBUF
    output	wire  [ ARRAY_N 			 -1 : 0 ]		buf_write_req_out,
    output  wire  [ ARRAY_N*IBUF_WRITE_ADDR_WIDTH -1 : 0 ]		buf_write_addr_out,
    output  wire  [ ARRAY_N*IBUF_WRITE_WIDTH   -1 : 0 ]		buf_write_data_out,

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
    output wire  [ AXI_BURST_WIDTH      -1 : 0 ]        mws_arlen,
//    output wire  [ 3                    -1 : 0 ]        mws_arsize,
//    output wire  [ 2                    -1 : 0 ]        mws_arburst,
    output wire                                         mws_arvalid,
//    output wire  [ AXI_ID_WIDTH         -1 : 0 ]        mws_arid,
    input  wire                                         mws_arready,
    // Master Interface Read Data
    input  wire  [ AXI_DATA_WIDTH       -1 : 0 ]        mws_rdata,
//    input  wire  [ 2                    -1 : 0 ]        mws_rresp,
    input  wire                                         mws_rlast,
    input  wire                                         mws_rvalid,
//    input  wire  [ AXI_ID_WIDTH         -1 : 0 ]        mws_rid,
    output wire                                         mws_rready,
    input  wire                                         last_store_en,
    // perf counter
    output wire [PC_DATA_WIDTH - 1 : 0]                 pc_ibuf_num_tiles,
    output wire [PC_DATA_WIDTH - 1 : 0]                 pc_ibuf_tot_cycles,  
    output wire [PC_DATA_WIDTH - 1 : 0]                 pc_ibuf_tot_requests,
    output wire [PC_DATA_WIDTH - 1 : 0]                 pc_ibuf_size_per_requests 
);

//==============================================================================
// Localparams
//==============================================================================
    localparam integer  LDMEM_IDLE                   = 0;
    localparam integer  LDMEM_BUSY_EXT               = 1;
	localparam integer	LDMEM_BUSY_SIMD 			 = 2;
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

    localparam integer  SPLIT_LD_REQ_IDLE            = 0;
    localparam integer  SPLIT_LD_REQ_A               = 1;
    localparam integer  SPLIT_LD_REQ_A_WAIT          = 2;
    localparam integer  SPLIT_LD_REQ_B               = 3;
    localparam integer  SPLIT_LD_REQ_B_WAIT          = 4;
    localparam integer  SPLIT_LD_DONE                = 5;    

    localparam integer  MEM_LD                       = 0;
    localparam integer  MEM_ST                       = 1;
    
    localparam integer      SA_GROUP                 = 0;
    localparam integer      SIMD_GROUP               = 1;
    localparam integer      GROUP_START              = 0;
    localparam integer      GROUP_END                = 1;

//==============================================================================

//==============================================================================
// Wires/Regs
//==============================================================================

    wire                                        compute_tag_done;
    wire                                        compute_tag_reuse;
    wire                                        compute_tag_ready;
    wire [ TAG_W                -1 : 0 ]        compute_tag;
    wire                                        ldmem_tag_done;
    wire                                        ldmem_tag_ready;
    wire [ TAG_W                -1 : 0 ]        ldmem_tag;
    wire                                        stmem_tag_done;
    wire                                        stmem_tag_ready;
    wire [ TAG_W                -1 : 0 ]        stmem_tag;
    wire                                        stmem_ddr_pe_sw;

    reg  [ 4                    -1 : 0 ]        ldmem_state_d;
    reg  [ 4                    -1 : 0 ]        ldmem_state_q,ldmem_state_qq;

    reg  [ 3                    -1 : 0 ]        stmem_state_d;
    reg  [ 3                    -1 : 0 ]        stmem_state_q;
    
    wire                                        ld_first_group;
    
    

    wire                                        ld_mem_req_v;
    wire                                        st_mem_req_v;

    wire [ TAG_W                -1 : 0 ]        tag;


    reg                                         ld_iter_v_q;
    reg  [ LOOP_ITER_W          -1 : 0 ]        iter_q;
	reg  [ LOOP_ID_W            -1 : 0 ]		loop_id_q;
	reg  [ LOOP_ID_W            -1 : 0 ]		loop_level_q;

    wire [ LOOP_ID_W            -1 : 0 ]        mws_ld_loop_id;

    wire [ LOOP_ID_W            -1 : 0 ]        mws_ld_loop_iter_loop_id;
    wire [ LOOP_ITER_W          -1 : 0 ]        mws_ld_loop_iter;
    wire                                        mws_ld_loop_iter_v;
	wire  [ LOOP_ID_W            -1 : 0 ]		mws_ld_loop_iter_loop_level;
    wire                                        mws_ld_start;
    wire                                        mws_ld_done;
    wire                                        mws_ld_stall;
    wire                                        mws_ld_init;
    wire                                        mws_ld_enter;
    wire                                        mws_ld_exit;
    wire [ LOOP_ID_W            -1 : 0 ]        mws_ld_index;
    wire                                        mws_ld_index_valid;
    wire                                        mws_ld_step;


    wire                                        ld_stride_v;
    wire [ ADDR_STRIDE_W        -1 : 0 ]        ld_stride;
	wire 										ld_stride_segment;


    wire [ ADDR_WIDTH           -1 : 0 ]        ld_addr;
    wire [ ADDR_WIDTH           -1 : 0 ]        mws_ld_base_addr;
    wire                                        ld_addr_v;


    reg  [ MEM_REQ_W            -1 : 0 ]        ld_req_size;
    wire  [ MEM_REQ_W            -1 : 0 ]        total_ld_req_size;
    wire                                        ld_req_valid_d;
    reg                                         ld_req_valid_q;
    reg  [ ADDR_WIDTH           -1 : 0 ]        ld_req_addr;

    reg  [ ADDR_WIDTH           -1 : 0 ]        tag_ld_addr[0:NUM_TAGS-1];






    wire                                        ld_ibuf_ext_simd_done;
    wire                                        ld_ibuf_simd_done;
    wire                                        ld_last_group;
    wire                                        ld_ibuf_simd_start;
    wire                                        ld_ibuf_simd_last_iter;
    
    wire                                        ld_ibuf_group_start;
    
    reg  [ INST_GROUP_ID_W           - 1 : 0 ]    next_ld_group_id_counter;  
    reg  [ INST_GROUP_ID_W           - 1 : 0 ]    curr_group_ld_id_counter;
    reg  [ TAG_W                     - 1 : 0 ]    next_tag_req_counter;
    reg  [ TAG_W                     - 1 : 0 ]    curr_tag_counter;
    
    
    

    wire                                        _tag_ldmem_done;
    wire                                        _tag_compute_done;
   
    
    wire                                        axi_rd_req;
    wire                                        axi_rd_done;
    wire  [ (MEM_REQ_W*2)            -1 : 0 ]   axi_rd_req_size;
    wire  [ (MEM_REQ_W*2)            -1 : 0 ]   rd_req_size_coefficient;
    wire [ AXI_ADDR_WIDTH       -1 : 0 ]        axi_rd_addr;

    wire                                        axi_wr_req;
    wire [ (MEM_REQ_W*2)            -1 : 0 ]        axi_wr_req_size;
    wire                                        axi_wr_ready;
    wire [ AXI_ADDR_WIDTH       -1 : 0 ]        axi_wr_addr;
    wire                                        axi_wr_data_v;

    wire                                        mem_write_req;
    wire [ AXI_DATA_WIDTH       -1 : 0 ]        mem_write_data;
    wire                                        mem_write_req_fifo;
    wire [ AXI_DATA_WIDTH       -1 : 0 ]        mem_write_data_fifo;

    wire                                        mem_write_ready;
//    wire [ AXI_ID_WIDTH         -1 : 0 ]        mem_write_id;	
	
    wire [ AXI_DATA_WIDTH       -1 : 0 ]        mem_read_data;
    
    // to account for a single loop with single iteration given the control_fsm_group does not work for this case and does not generate done
    wire                                        single_ld_iter_flag;
    reg [2*LOOP_ITER_W - 1 : 0]                 ld_iter_cntr;
    wire                                        rd_req_fifo_full;
    
    //==============================================================================
// WIRE and REGs
//==============================================================================
  reg  [ COUNTER_BUF_WRITE_GROUP_W     -1 : 0 ]   buf_write_ext_counter_group; 
  reg  [ IBUF_WRITE_ADDR_WIDTH -TAG_W  -1 : 0 ]          _buf_ext_write_addr;

  wire [ IBUF_WRITE_ADDR_WIDTH -TAG_W  -1 : 0 ]          buf_ext_write_addr;
  wire [ IBUF_WRITE_ADDR_WIDTH         -1 : 0 ]          tag_buf_ext_write_addr;
  //wire [ BUF_WRITE_GROUP_SIZE_EXT*IBUF_WRITE_ADDR_WIDTH-1 : 0]  group_tag_buf_ext_write_addr;
  wire [ ARRAY_N*IBUF_WRITE_ADDR_WIDTH-1 : 0]  group_tag_buf_ext_write_addr;
  
  wire [ ARRAY_N*IBUF_WRITE_ADDR_WIDTH -1 : 0 ]         buf_ext_write_addr_out;
  wire [ ARRAY_N                -1 : 0 ]                buf_ext_write_req_out;
  wire [ ARRAY_N*IBUF_WRITE_WIDTH     -1 : 0 ]          buf_ext_write_data_out;
  
  wire [ ARRAY_N*TAG_BUF_ADDR_W -1 : 0 ]          buf_simd_write_addr_out;
  wire [ ARRAY_N                -1 : 0 ]          buf_simd_write_req_out;
  wire [ ARRAY_N*DATA_WIDTH     -1 : 0 ]          buf_simd_write_data_out;  
  
  
  
  //wire [ BUF_WRITE_GROUP_SIZE_EXT   -1 : 0]       group_buf_ext_write_req;
  wire                                            buf_ext_write_req;
  
  reg                                             buf_simd_write_v;
  reg                                             buf_ext_write_v;
  
  
  wire [ TAG_W                      -1: 0 ]       compute_tag_delayed;
  wire [ TAG_BUF_ADDR_W             -1: 0 ]       tag_buf_read_addr;



  // Read-after-write
    reg                                         raw;
    wire [ TAG_W                -1 : 0 ]        raw_stmem_tag;
    wire                                        raw_stmem_tag_ready;
    wire [ ADDR_WIDTH           -1 : 0 ]        raw_stmem_st_addr;


    wire                                        ldmem_ready;
    
    localparam NUM_MAX_LOOPS = ( 1<< LOOP_ID_W);
    wire [ NUM_MAX_LOOPS :0] fsm_iter_done;
    wire [ LOOP_ID_W * NUM_MAX_LOOPS-1:0] fsm_loop_ids;
//==============================================================================
// Counting maximum number of group during decode
//==============================================================================
    wire                                             sa_group_v;  
    reg     [ INST_GROUP_ID_W           - 1 : 0 ]    max_groups_counter;
    wire                                             ld_group_loop_v;
    
    assign  sa_group_v = (inst_group_type == SA_GROUP && inst_group_s_e == GROUP_START && inst_group_v);
    
    always @(posedge clk) begin
       if (reset || block_done)
          max_groups_counter <= 0;
      else if (sa_group_v)
          max_groups_counter <= max_groups_counter + 1'b1;
    end
    
    // For IBUF, just the first group (layer) load data from offchip
    assign ld_group_loop_v = (max_groups_counter == 1);
//==============================================================================
// Walker stride configurations for IBUF to LD from Offchip
//==============================================================================
    assign ld_stride = cfg_loop_stride;
	assign ld_stride_segment = cfg_loop_stride_segment;	
    assign ld_stride_v = ld_group_loop_v && cfg_loop_stride_v && (cfg_loop_stride_loop_id > NUM_BASE_LOOPS - 1) && cfg_loop_stride_type == MEM_LD && cfg_loop_stride_id == MEM_ID;
    assign mws_ld_loop_id = cfg_loop_stride_loop_id;
    
    assign mws_ld_base_addr = tag_ld_addr[ldmem_tag];



//==============================================================================

//==============================================================================
// Address generators
//==============================================================================
    //assign mws_ld_stall = ~ldmem_tag_ready || (ldmem_tag_ready && ~ld_first_group) || ~axi_rd_ready || (axi_rd_ready && (ldmem_split_state_q != SPLIT_LD_REQ_IDLE)) || rd_req_fifo_full;
    assign mws_ld_stall = ~ldmem_tag_ready || (ldmem_tag_ready && ~ld_first_group) || ~axi_rd_ready || rd_req_fifo_full;
    
//    assign mws_ld_step = mws_ld_index_valid && !mws_ld_stall;
    
    
    // The walker and the controller fsm needs to be programmed only with the loop IDs associated with the first instrcution group.
    // The assumption is that the systolic instructions of a group are after group start and end instructions       
  
  mem_walker_stride_group #(
    .ADDR_WIDTH                     ( ADDR_WIDTH                     ),
    .ADDR_STRIDE_W                  ( ADDR_STRIDE_W                  ),
    .LOOP_ID_W                      ( LOOP_ID_W                      ),
	.GROUP_ID_W                     ( INST_GROUP_ID_W                ),
    .GROUP_ENABLED                  ( GROUP_ENABLED                  )
  ) mws_ld (
    .clk                            ( clk                            ), //input
    .reset                          ( reset                          ), //input
    
    .base_addr                      ( mws_ld_base_addr               ), //input
    .iter_done                      ( fsm_iter_done                  ), //input
    .start                          ( mws_ld_start                   ), //input
    .stall                          ( mws_ld_stall                   ),
 
    .block_done                     ( block_done                     ),
    .base_addr_v                    ( mws_ld_start                   ), //input

    .cfg_loop_id                    ( mws_ld_loop_id                 ), //input
    .cfg_addr_stride_v              ( ld_stride_v                    ), //input
    .cfg_addr_stride                ( ld_stride                      ), //input
    // NEW
    .cfg_loop_group_id		        ( inst_group_id                  ), //input
    .loop_group_id          		( next_ld_group_id_counter       ), //input
    //
    .addr_out                       ( ld_addr                        ), //output
    .addr_out_valid                 ( ld_addr_v                      )  //output
  );
//==============================================================================

//=============================================================
// Loop controller for IBUF
//=============================================================

  always @(posedge clk)
  begin
    if (reset)
      ld_iter_v_q <= 1'b0;
    else begin
      if (cfg_loop_iter_v && (cfg_loop_iter_loop_id > 2 * NUM_BASE_LOOPS - 1))
        ld_iter_v_q <= 1'b1;
      else if (cfg_loop_iter_v || ld_stride_v)
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
    else if (cfg_loop_iter_v && (cfg_loop_iter_loop_id > 2 * NUM_BASE_LOOPS - 1)) begin
      iter_q <= cfg_loop_iter;
	  loop_id_q <= cfg_loop_iter_loop_id;
	  loop_level_q <= cfg_loop_iter_level; 
    end
  end


// We are assuming that first the loop instructions come and then the stride instructions come
    assign mws_ld_start = (ldmem_state_q == LDMEM_BUSY_EXT) && (ldmem_state_qq != LDMEM_BUSY_EXT);
    assign mws_ld_loop_iter_v = ld_iter_v_q && (loop_id_q == cfg_loop_stride_loop_id) && ld_stride_v;
    assign mws_ld_loop_iter = iter_q;
    assign mws_ld_loop_iter_loop_id = loop_id_q;
//  	assign mws_ld_loop_iter_loop_level = loop_level_q;

// TODO: This can be later updated with a controller that supports groups and layer fusion, but we actually do not need it for here in IBUF!
   
  controller_fsm_group #(
    .LOOP_ID_W                      ( LOOP_ID_W                      ),
    .LOOP_ITER_W                    ( LOOP_ITER_W                    ),
    .GROUP_ID_W                     ( INST_GROUP_ID_W                ),
    .GROUP_ENABLED                  ( GROUP_ENABLED                  )
  ) mws_ld_ctrl (
    .clk                            ( clk                            ), //input
    .reset                          ( reset                          ), //input
    
    .start                          ( mws_ld_start                   ), //input
    .block_done                     ( block_done                     ),
    .done                           ( mws_ld_done                    ), //output
    .stall                          ( mws_ld_stall                   ), //input
    
    .cfg_loop_iter_v                ( mws_ld_loop_iter_v             ), //input
    .cfg_loop_iter                  ( mws_ld_loop_iter               ), //input
    .cfg_loop_iter_loop_id          ( mws_ld_loop_iter_loop_id       ), //input
    
    .cfg_loop_group_id              ( inst_group_id                  ), //input
    .loop_group_id                  ( next_ld_group_id_counter       ), //input

    .iter_done                      ( fsm_iter_done                  ),
    .current_iters                  (                                )
  );
//=============================================================

  reg             last_ld_iter;
  always @(posedge clk) begin
    if (reset)
      last_ld_iter <= 1'b0;
    else if (mws_ld_done)
      last_ld_iter <= 1'b1;
    else if (ldmem_state_q == LDMEM_DONE)
      last_ld_iter <= 1'b0;
  end


  always @(posedge clk) begin
    if (reset || block_done)
      ld_iter_cntr <= 1;
    else if (mws_ld_loop_iter_v)
      ld_iter_cntr <= ld_iter_cntr * (mws_ld_loop_iter + 1);
  end

  assign single_ld_iter_flag = ld_iter_cntr == 1; 

//==============================================================================
// Memory Request generation
//==============================================================================
    assign ld_mem_req_v = ld_group_loop_v && cfg_mem_req_v && (cfg_mem_req_loop_id > 2 * NUM_BASE_LOOPS - 1) && cfg_mem_req_type == MEM_LD && cfg_mem_req_id == MEM_ID;
  always @(posedge clk)
  begin
    if (reset) begin
      ld_req_size <= 0;
    end
    else if (ld_mem_req_v) begin
      ld_req_size <= cfg_mem_req_size;
    end
  end

    assign ld_req_valid_d = ld_addr_v;

  always @(posedge clk)
  begin
    if (reset) begin
      ld_req_valid_q <= 1'b0;
      ld_req_addr <= 0;
    end
    else begin
      ld_req_valid_q <= ld_req_valid_d;
      ld_req_addr <= ld_addr;
    end
  end

// TODO: (controller): In the controller it needs to be managed in a way that the base address for LD just be generated for the first group (fused layer)
// To make sure, we only accept the base address, when next tag is gonna be used for the first group
  always @(posedge clk)
  begin
//    if (tag_req && tag_ready && next_ld_group_id_counter == 0) begin
      if(base_ld_addr_v) begin
      tag_ld_addr[tag] <= tag_base_ld_addr;
    end
  end

//==============================================================================

//==============================================================================
// Tag-based synchronization for double buffering
//==============================================================================
    assign raw_stmem_tag = 0;
    
  
  assign ld_ibuf_group_start = (ldmem_tag_ready && ld_first_group && ldmem_state_q == LDMEM_IDLE) || ld_ibuf_simd_start;
  // TODO: this part might not be correct, the axi_rd_done might get valid for the previous requests?!
  // TODO: whenever we add the FIFO to the AXI, we need an empty signal from the FIFO here too and it should be ANDed!
  //assign ld_ibuf_ext_simd_done = (single_ld_iter_flag ? axi_rd_done : (axi_rd_done && last_ld_iter)) || ld_ibuf_simd_done;
  
  //assign ld_ibuf_ext_simd_done = (single_ld_iter_flag ? axi_rd_done : (last_ld_iter && ld_received_data_flag)) || ld_ibuf_simd_done;
  assign ld_ibuf_ext_simd_done = (single_ld_iter_flag ? (ld_received_data_flag && axi_rd_done_d) : (last_ld_iter && ld_received_data_flag)) || ld_ibuf_simd_done;
  
  // rohan: this is needed otherwise axi_rd_done is set 2 cycles before ld_received_data_flag for single iteration which then
  // makes the state machine stuck 
  


  reg axi_rd_done_d;
  reg mws_rlast_d ;
  reg axi_rd_last_pulse_d;
  
  always @(posedge clk) begin
    if (reset)
      mws_rlast_d <= 0;
    else if (ldmem_state_q == LDMEM_BUSY_EXT)
      mws_rlast_d <= mws_rlast;
  end

  assign axi_rd_last_pulse = mws_rlast && ~mws_rlast_d;
  
  always @(posedge clk) begin
    axi_rd_last_pulse_d <= axi_rd_last_pulse;
  end
  
//  always @(posedge clk) begin
//    if (reset)
//      axi_rd_last_pulse_flag <= 0;
//    else if (~axi_rd_last_pulse_flag && axi_rd_last_pulse)
//      axi_rd_last_pulse_flag <= 1;
//    else if ( axi_rd_last_pulse_flag && axi_rd_done_d)
//      axi_rd_last_pulse_flag <= 0;
//  end

  always @(posedge clk) begin
    if (reset || ld_ibuf_ext_simd_done)
      axi_rd_done_d <= 0;
    else if (ldmem_state_q == LDMEM_BUSY_EXT &&  axi_rd_last_pulse_d )
      axi_rd_done_d <= axi_rd_done;
  end

  always @(posedge clk) begin
      if (reset) begin
         next_tag_req_counter <= 0;
     end
     else if (ld_ibuf_group_start) begin
         if (next_tag_req_counter == NUM_TAGS - 1'b1)
            next_tag_req_counter <= 0;
         else
            next_tag_req_counter <= next_tag_req_counter + 1'b1;   
     end
  end 


 always @(posedge clk) begin
     if (reset) begin
        next_ld_group_id_counter <= 0;
     end
    else if (ld_ibuf_group_start && next_tag_req_counter == NUM_TAGS - 1'b1) begin
        if (next_ld_group_id_counter == max_groups_counter - 1)
            next_ld_group_id_counter <= 0;
        else
            next_ld_group_id_counter <= next_ld_group_id_counter + 1'b1;     
    end
  end

  assign ld_first_group = next_ld_group_id_counter == 0;
  assign buf_ld_first_group = ld_first_group;


  always @(posedge clk) begin
     if (reset)
        curr_tag_counter <= 0;
     else if (ldmem_tag_done) begin
        if (curr_tag_counter == NUM_TAGS)
            curr_tag_counter <= 1;
        else
            curr_tag_counter <= curr_tag_counter + 1'b1;  
    end
  end
  
  always @(posedge clk) begin
     if (reset)
         curr_group_ld_id_counter <= 0;
     else if (ldmem_tag_done && curr_tag_counter == NUM_TAGS)
         if (curr_group_ld_id_counter == max_groups_counter - 1)
             curr_group_ld_id_counter <= 0;
         else
             curr_group_ld_id_counter <= curr_group_ld_id_counter + 1'b1;
  end
  
   always @(posedge clk)
      if (reset)
        ldmem_state_qq <= 0;
      else
        ldmem_state_qq <= ldmem_state_q;
 

  always @(*)
  begin
    ldmem_state_d = ldmem_state_q;
    case(ldmem_state_q)
      LDMEM_IDLE: begin
        if (ldmem_tag_ready && ld_first_group) begin
            ldmem_state_d = LDMEM_BUSY_EXT;
        end
      else if (ldmem_tag_ready && ~ld_first_group && ld_ibuf_simd_start) begin
            ldmem_state_d = LDMEM_BUSY_SIMD;
      end
      end
      LDMEM_BUSY_EXT: begin
        //if (mws_ld_done)
        if (ld_ibuf_ext_simd_done) begin
            ldmem_state_d = LDMEM_DONE;
        end  
      end
      LDMEM_BUSY_SIMD: begin
        if (ld_ibuf_ext_simd_done) begin
            ldmem_state_d = LDMEM_DONE;
        end 
      end
//      LDMEM_WAIT_0: begin
//        ldmem_state_d = LDMEM_WAIT_1;
//      end
//      LDMEM_WAIT_1: begin
//        ldmem_state_d = LDMEM_WAIT_2;
//      end
//      LDMEM_WAIT_2: begin
//        ldmem_state_d = LDMEM_WAIT_3;
//      end
//      LDMEM_WAIT_3: begin
//        if (ld_ibuf_ext_simd_done) begin
//            ldmem_state_d = LDMEM_DONE;
//        end  
//      end
      LDMEM_DONE: begin
        ldmem_state_d = LDMEM_IDLE;
      end
    endcase
  end



  always @(posedge clk)
  begin
    if (reset)
      ldmem_state_q <= LDMEM_IDLE;
    else
      ldmem_state_q <= ldmem_state_d;
  end


  always @(*)
  begin
    stmem_state_d = stmem_state_q;
    case(stmem_state_q)
      STMEM_IDLE: begin
        if (stmem_tag_ready) begin
          stmem_state_d = STMEM_DONE;
        end
      end
      STMEM_DONE: begin
        stmem_state_d = STMEM_IDLE;
      end
    endcase
  end

  always @(posedge clk)
  begin
    if (reset)
      stmem_state_q <= STMEM_IDLE;
    else
      stmem_state_q <= stmem_state_d;
  end


// counter to count number of ibuf load done

  wire ld_ibuf_ext_simd_done_q, ld_ibuf_ext_simd_done_pulse;
  reg [7:0] num_ibuf_loads;
  register_sync #(1) sa_compute_req_pulse_reg (clk, reset, ld_ibuf_ext_simd_done, ld_ibuf_ext_simd_done_q);
  assign ld_ibuf_ext_simd_done_pulse = ld_ibuf_ext_simd_done & ~ld_ibuf_ext_simd_done_q;
  always @(posedge clk) begin
    if (reset)
      num_ibuf_loads <= 0;
    else if (ld_ibuf_ext_simd_done_pulse == 1)
      num_ibuf_loads <= num_ibuf_loads + 1;
  end

/*
  ila_0 ibuf_ila (
  .clk(clk),
  // 1 bit width
  .probe0(tag_req),
  .probe1(tag_ready),
  .probe2(ld_received_data_flag),
  .probe3(ld_ibuf_ext_simd_done),
  .probe4(axi_rd_req),
  .probe5(axi_rd_done),
  // 8 bit width
  .probe6(ldmem_state_q),
  .probe7(num_ibuf_loads),
  .probe8(),
  .probe9(0),
  .probe10(0),
  // 32 bit width
  .probe11(axi_rd_addr[31:0]),
  .probe12(axi_rd_addr[63:32]),
  .probe13(axi_rd_req_size),
  .probe14(0),
  .probe15(0),
  .probe16(0),
  .probe17(0),
  .probe18(0),
  .probe19(0)
  );
*/

    assign ldmem_tag_done = ldmem_state_q == LDMEM_DONE;
    assign compute_tag_done = compute_done;
    
    // We need to also send the appropriate group that is ready for the compute to address generator to use right set of loops
    assign compute_ready = compute_tag_ready;
    assign compute_group_id = curr_group_ld_id_counter;



    assign ldmem_ready = ldmem_tag_ready;
  // assign ldmem_tag_done = mws_ld_done;

    assign stmem_tag_done = stmem_state_q == STMEM_DONE;

  tag_sync  #(
    .NUM_TAGS                       ( NUM_TAGS                       ),
    .STORE_ENABLED                  ( 0                              )
  )
  mws_tag (
    .clk                            ( clk                            ),
    .reset                          ( reset                          ),
    .block_done                     ( block_done                     ),
    .tag_req                        ( tag_req                        ),
    .tag_reuse                      ( tag_reuse                      ),
    .tag_bias_prev_sw               ( tag_bias_prev_sw               ),
    .tag_ddr_pe_sw                  ( tag_ddr_pe_sw                  ), //input
    .tag_ready                      ( tag_ready                      ),
    .tag                            ( tag                            ),
    .tag_done                       ( tag_done                       ),
    .raw_stmem_tag                  ( raw_stmem_tag                  ),
    .raw_stmem_tag_ready            ( raw_stmem_tag_ready            ), 
    .compute_tag_done               ( compute_tag_done               ),  
    .compute_tag_ready              ( compute_tag_ready              ), 
    .compute_bias_prev_sw           ( compute_bias_prev_sw           ),
    .compute_tag                    ( compute_tag                    ), 
    .ldmem_tag_done                 ( ldmem_tag_done                 ),
    .ldmem_tag_ready                ( ldmem_tag_ready                ),
    .ldmem_tag                      ( ldmem_tag                      ),    
    .stmem_ddr_pe_sw                ( stmem_ddr_pe_sw                ),
    .stmem_tag_done                 ( stmem_tag_done                 ),
    .stmem_tag_ready                ( stmem_tag_ready                ),
    .stmem_tag                      ( stmem_tag                      ),
    .last_store_en                  (last_store_en                   )
  );
//==============================================================================

//==============================================================================
// AXI4 Memory Mapped interface
//==============================================================================
    wire axi_rd_ready;

    /*
    wire                                  split_ld_req_v;
    wire    [ ADDR_WIDTH      -1 : 0 ]    prev_4k_aligned_addr;
    wire    [ ADDR_WIDTH      -1 : 0 ]    next_4k_aligned_addr;       
    reg     [ ADDR_WIDTH      -1 : 0 ]    split_a_ld_req_addr; 
    reg     [ ADDR_WIDTH      -1 : 0 ]    split_b_ld_req_addr; 
    reg     [ MEM_REQ_W  -1 : 0 ]         split_a_ld_req_size;
    reg     [ MEM_REQ_W  -1 : 0 ]         split_b_ld_req_size;  
    reg  [ 3                    -1 : 0 ]        ldmem_split_state_d;
    reg  [ 3                    -1 : 0 ]        ldmem_split_state_q;    
    reg  [ 3                    -1 : 0 ]        ldmem_split_state_qq; 

    // logic to identify if we need to split the request, currently assuming that each split is at 64B * n
    assign total_ld_req_size = ld_req_size * rd_req_size_coefficient;
    assign prev_4k_aligned_addr = {ld_req_addr[ADDR_WIDTH-1:12], 12'b0};
    assign next_4k_aligned_addr = prev_4k_aligned_addr + {1,12'b0};
    assign split_ld_req_v = ((total_ld_req_size + ld_req_addr) > next_4k_aligned_addr) && ld_req_valid_q;

    always @(posedge clk) begin
      if (reset) begin
         split_a_ld_req_addr <= 0;
         split_b_ld_req_addr <= 0;
         split_a_ld_req_size <= 0;
         split_b_ld_req_size <= 0;
      end
      else if (split_ld_req_v) begin
         split_a_ld_req_addr <= ld_req_addr;
         split_b_ld_req_addr <= next_4k_aligned_addr;
         split_a_ld_req_size <= (next_4k_aligned_addr - ld_req_addr);
         split_b_ld_req_size <= (ld_req_size - (next_4k_aligned_addr - ld_req_addr));
      end
    end

  always @(*)
  begin
    ldmem_split_state_d = ldmem_split_state_q;
    case(ldmem_split_state_q)
      SPLIT_LD_REQ_IDLE: begin
        if (split_ld_req_v) begin
          ldmem_split_state_d = SPLIT_LD_REQ_A;
        end
      end
      SPLIT_LD_REQ_A: begin
        ldmem_split_state_d = SPLIT_LD_REQ_A_WAIT;
      end
      SPLIT_LD_REQ_A_WAIT: begin
        if (axi_rd_ready)
          ldmem_split_state_d = SPLIT_LD_REQ_B; 
      end
      SPLIT_LD_REQ_B: begin
        ldmem_split_state_d = SPLIT_LD_REQ_B_WAIT;
      end
      SPLIT_LD_REQ_B_WAIT: begin
        if (axi_rd_ready)
          ldmem_split_state_d = SPLIT_LD_DONE;
      end
      SPLIT_LD_DONE: begin
        ldmem_split_state_d = SPLIT_LD_REQ_IDLE;
      end
    endcase
  end

  always @(posedge clk)
  begin
    if (reset) begin
      ldmem_split_state_d <= SPLIT_LD_REQ_IDLE;
      ldmem_split_state_q <= SPLIT_LD_REQ_IDLE;
    end else
      ldmem_split_state_q <= ldmem_split_state_d;
  end

  always @(posedge clk) begin
    if (reset)
        ldmem_split_state_qq <= 0;
    else
       ldmem_split_state_qq <= ldmem_split_state_q;
  end



    
    assign axi_rd_req = (ld_req_valid_q && ~split_ld_req_v) || (ldmem_split_state_q == SPLIT_LD_REQ_A) || (ldmem_split_state_q == SPLIT_LD_REQ_B);
    // rohan
    assign rd_req_size_coefficient = (ARRAY_N * DATA_WIDTH) / 8;
    assign axi_rd_req_size = (ld_req_valid_q && ~split_ld_req_v) ? (ld_req_size * rd_req_size_coefficient) : (ldmem_split_state_q == SPLIT_LD_REQ_A) ? split_a_ld_req_size * rd_req_size_coefficient : split_b_ld_req_size * rd_req_size_coefficient;
  
    assign axi_rd_addr = (ld_req_valid_q && ~split_ld_req_v) ? ld_req_addr : (ldmem_split_state_q == SPLIT_LD_REQ_A) ? split_a_ld_req_addr : split_b_ld_req_addr;
  */
    assign axi_rd_req = ld_req_valid_q;
    assign rd_req_size_coefficient = (ARRAY_N * DATA_WIDTH) / 8;
    assign axi_rd_req_size = ld_req_valid_q ? ld_req_size * rd_req_size_coefficient : 'b0;
    assign axi_rd_addr = ld_req_valid_q ? ld_req_addr : 'b0;
  
    assign axi_wr_req = 1'b0;
    assign axi_wr_data_v = 1'b0;
    assign axi_wr_req_size = 0;
    assign axi_wr_addr = 0;

    //assign mem_write_ready = 1'b1;
    assign mem_read_data = 0;


///////////////////////////////////////// 
// Logic to count requested vs received data packets

reg  [31:0] sent_ld_requests, ld_axi_req_size;
wire [63:0] expected_packets;
reg  [63:0] received_packets;
wire        ld_received_data_flag;

localparam integer  LDMEM_PKTS_SM_IDLE         = 0;
localparam integer  LDMEM_TO_SEND_PKTS         = 1;
localparam integer  LDMEM_SENT_PKTS            = 2;
localparam integer  LDMEM_PKTS_DONE            = 3;

  reg ld_received_data_flag_temp;
  reg [3:0] ldmem_pkt_done_state_d;
  reg [3:0] ldmem_pkt_done_state_q;  

always @(posedge clk) begin
  if (reset || ldmem_tag_done) begin
    sent_ld_requests <= 'b0;
    ld_axi_req_size <= 'b0;
  end
  else if (ld_req_valid_q) begin
    sent_ld_requests <= sent_ld_requests + 1'b1;
    ld_axi_req_size <= axi_rd_req_size;
  end
end

// WSTRB_W is essentially AXI_DATA_WIDTH in bytes
always @(posedge clk) begin
  if (reset || ldmem_tag_done)
    received_packets <= 'b0;
  else if (mem_write_req)
    received_packets <= received_packets + WSTRB_W;
end


assign expected_packets = sent_ld_requests * ld_axi_req_size;
assign ld_received_data_flag = ld_received_data_flag_temp;



  always @(*)
  begin
    ldmem_pkt_done_state_d = ldmem_pkt_done_state_q;
    ld_received_data_flag_temp = 0;
    case(ldmem_pkt_done_state_q)
      LDMEM_PKTS_SM_IDLE: begin
        if (ldmem_state_q == LDMEM_BUSY_EXT) begin
          ldmem_pkt_done_state_d = LDMEM_TO_SEND_PKTS;
        end
      end
      LDMEM_TO_SEND_PKTS: begin
        if (last_ld_iter || single_ld_iter_flag)
          ldmem_pkt_done_state_d = LDMEM_SENT_PKTS;
      end
      LDMEM_SENT_PKTS: begin
        if (expected_packets == received_packets)
          ldmem_pkt_done_state_d = LDMEM_PKTS_DONE;
      end
      LDMEM_PKTS_DONE: begin
          ld_received_data_flag_temp = 1;
          ldmem_pkt_done_state_d = LDMEM_PKTS_SM_IDLE;
        end
    endcase
  end

  always @(posedge clk)
  begin
    if (reset)
      ldmem_pkt_done_state_q <= LDMEM_PKTS_SM_IDLE;
    else
      ldmem_pkt_done_state_q <= ldmem_pkt_done_state_d;
  end

//==============================================================================
// AXI4 LD FIFO
//==============================================================================

   parameter integer FIFO_READ_LATENCY = 1;
   parameter integer LD_FIFO_WRITE_DEPTH = 32;
   parameter integer LD_PROG_EMPTY_THRESH = 3;
   parameter integer LD_PROG_FULL_THRESH = LD_FIFO_WRITE_DEPTH - 4;

   //parameter integer LD_READ_DATA_WIDTH = (ARRAY_N * DATA_WIDTH) > AXI_DATA_WIDTH ? AXI_DATA_WIDTH : (ARRAY_N * DATA_WIDTH);
   // Because we have asymmetric memory banks for IBUF which can sustain larger width write
   parameter integer LD_READ_DATA_WIDTH = AXI_DATA_WIDTH;
   parameter integer LD_WRITE_DATA_WIDTH = AXI_DATA_WIDTH;
   parameter integer LD_FIFO_READ_DEPTH =  LD_FIFO_WRITE_DEPTH*LD_WRITE_DATA_WIDTH/LD_READ_DATA_WIDTH;
   parameter integer LD_RD_DATA_COUNT_WIDTH = $clog2(LD_FIFO_READ_DEPTH)+1;
   parameter integer LD_WR_DATA_COUNT_WIDTH = $clog2(LD_FIFO_WRITE_DEPTH)+1;

   wire                                   ld_fifo_almost_empty;
   wire                                   ld_fifo_almost_full;
   wire                                   ld_fifo_data_valid;
   wire  [LD_READ_DATA_WIDTH - 1 : 0]     ld_fifo_dout;
   wire                                   ld_fifo_empty;
   wire                                   ld_fifo_full;
   wire                                   ld_fifo_overflow;
   wire                                   ld_fifo_prog_empty;
   wire                                   ld_fifo_prog_full;
   wire  [LD_RD_DATA_COUNT_WIDTH - 1 : 0] ld_fifo_rd_data_count;
   wire                                   ld_fifo_rd_rst_busy;
   wire                                   ld_fifo_underflow;
   wire                                   ld_fifo_wr_ack;
   wire  [LD_WR_DATA_COUNT_WIDTH - 1 : 0] ld_fifo_wr_data_count;
   wire                                   ld_fifo_wr_rst_busy;
   wire  [LD_WRITE_DATA_WIDTH - 1 : 0]    ld_fifo_din;
   reg                                    ld_fifo_rd_en;
   wire                                   ld_fifo_sleep;
   wire                                   ld_fifo_wr_en;

  // FIFO Inputs
  assign ld_fifo_din    = mem_write_data_fifo;
  assign ld_fifo_wr_en  = mem_write_req_fifo;
  assign ld_fifo_sleep = 1'b0;    // used for low power design

  // FIFO Outputs - todo: should we use just full
  assign mem_write_ready = ~ld_fifo_prog_full && ~ld_fifo_wr_rst_busy;

  assign mem_write_data = ld_fifo_dout;
  assign mem_write_req = ld_fifo_data_valid;

  // Control logic for FIFO signals
  // register to make one cycle delay between read and write
  always @(clk) begin
    if (reset)
      ld_fifo_rd_en <= 1'b0;
    else begin
      if (~ld_fifo_empty && ~ld_fifo_rd_rst_busy) begin
        ld_fifo_rd_en <= 1'b1;
      end
      else begin
        ld_fifo_rd_en <= 1'b0;
      end
    end
  end

  asymmetric_fifo_xpm #(
   .FIFO_READ_LATENCY     (FIFO_READ_LATENCY  ),
   .FIFO_WRITE_DEPTH      (LD_FIFO_WRITE_DEPTH   ),
   .PROG_EMPTY_THRESH     (LD_PROG_EMPTY_THRESH  ),
   .PROG_FULL_THRESH      (LD_PROG_FULL_THRESH   ),
   .READ_DATA_WIDTH       (LD_READ_DATA_WIDTH    ),
   .WRITE_DATA_WIDTH      (LD_WRITE_DATA_WIDTH   ),
   .FIFO_READ_DEPTH       (LD_FIFO_READ_DEPTH    ),
   .RD_DATA_COUNT_WIDTH   (LD_RD_DATA_COUNT_WIDTH),
   .WR_DATA_COUNT_WIDTH   (LD_WR_DATA_COUNT_WIDTH)
  ) axi_ld_fifo (
   .wr_clk        (clk                  ),
   .rst           (reset                ),
   .almost_empty  (ld_fifo_almost_empty ),
   .almost_full   (ld_fifo_almost_full  ),
   .data_valid    (ld_fifo_data_valid   ),
   .dout          (ld_fifo_dout         ),
   .empty         (ld_fifo_empty        ),
   .full          (ld_fifo_full         ),
   .overflow      (ld_fifo_overflow     ),
   .prog_empty    (ld_fifo_prog_empty   ),
   .prog_full     (ld_fifo_prog_full    ),
   .rd_data_count (ld_fifo_rd_data_count),
   .rd_rst_busy   (ld_fifo_rd_rst_busy  ),
   .underflow     (ld_fifo_underflow    ),
   .wr_ack        (ld_fifo_wr_ack       ),
   .wr_data_count (ld_fifo_wr_data_count),
   .wr_rst_busy   (ld_fifo_wr_rst_busy  ),
   .din           (ld_fifo_din          ),
   .rd_en         (ld_fifo_rd_en        ),
   .sleep         (ld_fifo_sleep        ),
   .wr_en         (ld_fifo_wr_en        )                                 
  );

////////////////////////////////////////////////////////////////////////


/////// AXI Interface
 ddr_memory_interface_control_m_axi_fifo #(
    .C_XFER_SIZE_WIDTH                  ( MEM_REQ_W * 2                  ),
    .C_M_AXI_DATA_WIDTH                 ( AXI_DATA_WIDTH                 ),
    .C_M_AXI_ADDR_WIDTH                 ( AXI_ADDR_WIDTH                 )
  ) u_axi_mm_master (
    .clk                            ( clk                            ),
    .reset                          ( reset                          ),
    
    .kernel_clk                      ( clk                            ),
    .kernel_rst                      ( reset                          ),
    
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
        
    .rd_tvalid                      ( mem_write_req_fifo             ),
    // Currently theere is no FIFO in the design that stores the extra data. this is the currnet limitation: 512 <= num_banks * data_width
    .rd_tready                      ( mem_write_ready                ),
    .rd_tdata                       ( mem_write_data_fifo                 ),
    .rd_tkeep                       (                                ),
    // We are using the done signal not the last!
    .rd_tlast                       (                                ),
    .rd_addr_arready                ( axi_rd_ready                   ),
    
    .wr_tvalid                      ( axi_wr_data_v                  ),
    .wr_tready                      ( axi_wr_ready                   ),
    .wr_tdata                       ( mem_read_data                  ),
    .rd_req_fifo_full               (rd_req_fifo_full                   )
  );    
/////////////////////////////////////////    
    
 
//==============================================================================
// Loading through SIMD Array


    
  assign ld_ibuf_simd_start = simd_ibuf_write_req[0] && &(~simd_ibuf_write_req[ARRAY_N-1:1]);
  assign ld_ibuf_simd_last_iter = (~simd_ibuf_write_req[0]) && (&simd_ibuf_write_req[ARRAY_N-1:1]);
  
  //assign ld_ibuf_simd_done = simd_ibuf_write_req[ARRAY_N-1] && &(~simd_ibuf_write_req[ARRAY_N-2:0]);
  // todo: uncomment above line when SIMD is added
  assign ld_ibuf_simd_done = 0;
  
 
//=============================================================
 // Systolic Buffer Write---IBUF from EXT Memory
// ============================================================
  always @(posedge clk)
  begin
      if (reset)
          buf_write_ext_counter_group <= 0;
      else if (mem_write_req) begin
          if (buf_write_ext_counter_group == BUF_WRITE_NUM_GROUP_EXT - 1)
              buf_write_ext_counter_group <= 0;
          else
              buf_write_ext_counter_group <= buf_write_ext_counter_group + 1'b1;
      end
  end
 //

//
  always @(posedge clk)
  begin
      if (reset)
          _buf_ext_write_addr <= 0;
      else begin 
          if (mem_write_req && buf_write_ext_counter_group == BUF_WRITE_NUM_GROUP_EXT - 1)  
            _buf_ext_write_addr <= _buf_ext_write_addr + 1'b1;
          else if (ldmem_state_q == LDMEM_DONE)
            _buf_ext_write_addr <= 0;
      end
  end
//

// ASSIGNs
//Assign Data out
  assign buf_ext_write_data_out = {BUF_WRITE_NUM_GROUP_EXT{mem_write_data}};
   
//Assign Address out  
  assign  buf_ext_write_addr = _buf_ext_write_addr;
  assign  tag_buf_ext_write_addr = {ldmem_tag, buf_ext_write_addr};
    
  genvar i;
  generate
    for (i=0; i<ARRAY_N; i=i+1) begin
        assign group_tag_buf_ext_write_addr[(i+1)*IBUF_WRITE_ADDR_WIDTH-1: i*IBUF_WRITE_ADDR_WIDTH] = tag_buf_ext_write_addr;     
    end
  endgenerate
  
  assign buf_ext_write_addr_out = {BUF_WRITE_NUM_GROUP_EXT{group_tag_buf_ext_write_addr}};
  
  
//Assign Address Req Out
  assign buf_ext_write_req = mem_write_req;

  
  genvar k;
  generate
      for (k=0; k<BUF_WRITE_NUM_GROUP_EXT; k=k+1) begin
             assign buf_ext_write_req_out[(k+1)*BUF_WRITE_GROUP_SIZE_ARRAY_EXT-1: (k)*BUF_WRITE_GROUP_SIZE_ARRAY_EXT] = (buf_write_ext_counter_group == k )? {BUF_WRITE_GROUP_SIZE_ARRAY_EXT{buf_ext_write_req}} :0;
      end
  endgenerate
  
//=============================================================================
   // Systolic Buffer Write---IBUF from SIMD ARRAY
//==============================================================================
  genvar l;
  generate
      for (l=0; l<ARRAY_N; l=l+1) begin
          assign buf_simd_write_addr_out[(l+1)*TAG_BUF_ADDR_W-1 : l*TAG_BUF_ADDR_W] = {ldmem_tag, simd_ibuf_write_addr[(l+1)*BUF_ADDR_W-1 : l*BUF_ADDR_W]};
      end      
  endgenerate
  assign buf_simd_write_data_out = simd_ibuf_write_data;
  assign buf_simd_write_req_out = simd_ibuf_write_req;
//==============================================================================

//===========================================================
// Selecting the write signals out from EXT MEM or SIMD ARRAY
//===========================================================
  always @(posedge clk) begin
    if (reset)
       buf_ext_write_v <= 1'b0;
    else if (ldmem_state_q == LDMEM_BUSY_EXT) 
       buf_ext_write_v <= 1'b1;
    else if (ldmem_state_q == LDMEM_DONE)
       buf_ext_write_v <= 1'b0;
  end  
  
  
  always @(posedge clk) begin
    if (reset)
       buf_simd_write_v <= 1'b0;
    else if (ldmem_state_q == LDMEM_BUSY_SIMD) 
       buf_simd_write_v <= 1'b1;
    else if (ldmem_state_q == LDMEM_DONE)
       buf_simd_write_v <= 1'b0;
  end    
  
  
  
  reg [ ARRAY_N*IBUF_WRITE_ADDR_WIDTH -1 : 0 ]          _buf_write_addr_out;
  reg [ ARRAY_N                -1 : 0 ]          _buf_write_req_out;
  reg [ ARRAY_N*IBUF_WRITE_WIDTH     -1 : 0 ]    _buf_write_data_out;  
   
  always @(*) begin
    // reseting values so that latches are not inferred.
    _buf_write_req_out = 0;
    _buf_write_addr_out = 0;
    _buf_write_data_out = 0;
     if (buf_ext_write_v) begin
         _buf_write_addr_out = buf_ext_write_addr_out;
         _buf_write_req_out = buf_ext_write_req_out;
         _buf_write_data_out = buf_ext_write_data_out;
     end
    else if (buf_simd_write_v) begin
         _buf_write_addr_out = buf_simd_write_addr_out;
         _buf_write_req_out = buf_simd_write_req_out;
         _buf_write_data_out = buf_simd_write_data_out;       
    end  
 end
 
 assign buf_write_addr_out = _buf_write_addr_out;
 assign buf_write_req_out = _buf_write_req_out;
 assign buf_write_data_out = _buf_write_data_out;

//===========================================================
// Systolic Buffer Read / IBUF
//===========================================================

// Systolic Buffer Read
  assign compute_tag_delayed = compute_tag;
  assign tag_buf_read_addr = {compute_tag_delayed, buf_read_addr};
  
  assign buf_read_addr_out = tag_buf_read_addr; 
  assign buf_read_req_out = buf_read_req;
//
//==============================================================================


//=========================== PERF COUNTER ====================

// Perf Counter Enables
wire pc_ibuf_num_tiles_en, pc_ibuf_tot_cycles_en, pc_ibuf_tot_requests_en, pc_ibuf_size_per_requests_en;

assign pc_ibuf_num_tiles_en = ldmem_state_q ==  LDMEM_IDLE && ldmem_state_d == LDMEM_BUSY_EXT;
assign pc_ibuf_tot_cycles_en = ldmem_state_q == LDMEM_BUSY_EXT;
assign pc_ibuf_tot_requests_en = ld_addr_v;
assign pc_ibuf_size_per_requests_en = ld_req_valid_q;
//assign pc_ibuf_load_latency_en = 

// Number of Tiles
perf_counter #(
    .DATA_WIDTH (PC_DATA_WIDTH)
) pc_decode
  (
    .clk (clk),
    .en (pc_ibuf_num_tiles_en),
    .rst (reset),
    .out (pc_ibuf_num_tiles)
  );

// ibuf total cycles
perf_counter #(
    .DATA_WIDTH (PC_DATA_WIDTH)
) pc_end2end
  (
    .clk (clk),
    .en (pc_ibuf_tot_cycles_en),
    .rst (reset),
    .out (pc_ibuf_tot_cycles)
  );

// ibuf total requests
perf_counter #(
    .DATA_WIDTH (PC_DATA_WIDTH)
) pc_tot_requests
  (
    .clk (clk),
    .en (pc_ibuf_tot_requests_en),
    .rst (reset),
    .out (pc_ibuf_tot_requests)
  );

// ibuf size per request
perf_counter #(
    .DATA_WIDTH (PC_DATA_WIDTH),
    .STEP(0)
) pc_size_per_req
  (
    .clk (clk),
    .en (pc_ibuf_size_per_requests_en),
    .rst (reset),
    .step(axi_rd_req_size),
    .out (pc_ibuf_size_per_requests)
  );



//=============================================================
endmodule
