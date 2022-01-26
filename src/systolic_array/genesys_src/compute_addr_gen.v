//
// Compute address generator
//

`timescale 1ns/1ps
module compute_addr_gen #(
  // Internal Parameters
  parameter integer  NUM_BASE_LOOPS               = 7,
  parameter integer  WBUF_MEM_ID                  = 0,
  parameter integer  IBUF_MEM_ID                  = 1,
  parameter integer  OBUF_MEM_ID                  = 2,
  parameter integer  BBUF_MEM_ID                  = 3,
  
  parameter integer  MIN_COMPUTE_LOOP_RANGE       = 6,
  parameter integer  MAX_COMPUTE_LOOP_RANGE       = 14,

  parameter integer  IBUF_ADDR_WIDTH              = 8,
  parameter integer  WBUF_ADDR_WIDTH              = 8,
  parameter integer  OBUF_ADDR_WIDTH              = 8,
  parameter integer  BBUF_ADDR_WIDTH              = 8,
  parameter integer  LOOP_ITER_W                  = 16,
  parameter integer  ADDR_STRIDE_W                = 32,
  parameter integer  LOOP_ID_W                    = 6,
  parameter integer  NUM_MAX_LOOPS                = (1 << LOOP_ID_W),
  parameter integer  INST_GROUP_ID_W              = 4,
  parameter integer  NUM_MAX_GROUPS               = (1 << INST_GROUP_ID_W),
  parameter integer  BUF_TYPE_W                   = 2,
  parameter integer  GROUP_ENABLED                = 0
) (
  input  wire                                         clk,
  input  wire                                         reset,

  input  wire                                         start,
  output wire                                         done,
  input  wire                                         block_done,
  
  input  wire  [ INST_GROUP_ID_W      -1 : 0 ]        cfg_curr_group_id,
  input  wire  [ INST_GROUP_ID_W      -1 : 0 ]        next_group_id,

  input  wire                                         stall,

  // Programming LOOP Iter
  input  wire                                         cfg_loop_iter_v,
  input  wire  [ LOOP_ITER_W          -1 : 0 ]        cfg_loop_iter,
  input  wire  [ LOOP_ID_W            -1 : 0 ]        cfg_loop_iter_loop_id,

  input  wire                                         cfg_set_specific_loop_v,
  input  wire  [ LOOP_ID_W            -1 : 0 ]        cfg_set_specific_loop_loop_id,
  input  wire  [ 2                       : 0 ]		  cfg_set_specific_loop_loop_param,

  // Programming Stride
  input  wire                                         cfg_loop_stride_v,
  input  wire  [ ADDR_STRIDE_W        -1 : 0 ]        cfg_loop_stride,
  input  wire  [ LOOP_ID_W            -1 : 0 ]        cfg_loop_stride_loop_id,
  input  wire  [ BUF_TYPE_W           -1 : 0 ]        cfg_loop_stride_id,
  input  wire  [ 2                    -1 : 0 ]        cfg_loop_stride_type,
  
  // Prgramming Group
  input  wire  [ INST_GROUP_ID_W       -1 : 0 ]       inst_group_id,
  input  wire                                         inst_group_type,
  input  wire                                         inst_group_s_e,
  input  wire                                         inst_group_v,
  input  wire                                         inst_group_last,
  
  // Address - OBUF RD/WR
  input  wire  [ OBUF_ADDR_WIDTH      -1 : 0 ]        obuf_base_addr,
  output wire  [ OBUF_ADDR_WIDTH      -1 : 0 ]        obuf_rd_addr,
  output wire                                         obuf_rd_addr_v,
  output wire  [ OBUF_ADDR_WIDTH      -1 : 0 ]        obuf_wr_addr,
  output wire                                         obuf_wr_addr_v,
  // Address - IBUF RD
  input  wire  [ IBUF_ADDR_WIDTH      -1 : 0 ]        ibuf_base_addr,
  output wire  [ IBUF_ADDR_WIDTH      -1 : 0 ]        ibuf_rd_addr,
  output wire                                         ibuf_rd_addr_v,
  // Address - WBUF RD
  input  wire  [ WBUF_ADDR_WIDTH      -1 : 0 ]        wbuf_base_addr,
  output wire  [ WBUF_ADDR_WIDTH      -1 : 0 ]        wbuf_rd_addr,
  output wire                                         wbuf_rd_addr_v,
  // Address - BIAS RD
  input  wire  [ BBUF_ADDR_WIDTH      -1 : 0 ]        bbuf_base_addr,
  output wire  [ BBUF_ADDR_WIDTH      -1 : 0 ]        bbuf_rd_addr,
  output wire                                         bbuf_rd_addr_v,
  
  input  wire                                         obuf_base_addr_v,
  input  wire                                         wbuf_base_addr_v, 
  input  wire                                         ibuf_base_addr_v,
  input  wire                                         bbuf_base_addr_v,

  output wire                                         bias_prev_sw,
  input wire                                          sa_compute_done_delayed,
  input wire                                          obuf_first_ic_outer_loop_ld

);


//==============================================================================
// Local Params
//==============================================================================
  localparam integer  LD                            = 0;
  localparam integer  ST                            = 1; 
  localparam integer  RD                            = 2;
  localparam integer  WR                            = 3;
  
  localparam integer  IC_INNER_LOOP_PARAM           = 0;
  localparam integer  KW_INNER_LOOP_PARAM           = 1;
  localparam integer  KH_INNER_LOOP_PARAM           = 2;
//==============================================================================
// Wires/Regs
//==============================================================================
  // Programming - Base loop
  wire                                        cfg_base_loop_iter_v;
  wire [ LOOP_ITER_W          -1 : 0 ]        cfg_base_loop_iter;
  wire [ LOOP_ID_W            -1 : 0 ]        cfg_base_loop_id;
  
  
    
  wire  [ (1<<LOOP_ID_W)        : 0 ]         iter_done;



  wire                                        base_loop_stall;
  wire [ LOOP_ITER_W*NUM_MAX_LOOPS-1:0]       curr_base_loop_iters;


  wire                                        cfg_base_stride_v;
  // Programming - OBUF LD/ST
  wire                                        cfg_obuf_stride_v;
  wire [ ADDR_STRIDE_W        -1 : 0 ]        obuf_stride;
  wire [ LOOP_ID_W            -1 : 0 ]        cfg_obuf_stride_loop_id;
  // Programming - Bias
  wire                                        cfg_bbuf_stride_v;
  wire [ ADDR_STRIDE_W        -1 : 0 ]        bbuf_stride;
  wire [ LOOP_ID_W            -1 : 0 ]        cfg_bbuf_stride_loop_id;
  // Programming - OBUF ST
  wire                                        cfg_ibuf_stride_v;
  wire [ ADDR_STRIDE_W        -1 : 0 ]        ibuf_stride;
  wire [ LOOP_ID_W            -1 : 0 ]        cfg_ibuf_stride_loop_id;
  // Programming - OBUF ST
  wire                                        cfg_wbuf_stride_v;
  wire [ ADDR_STRIDE_W        -1 : 0 ]        wbuf_stride;
  wire [ LOOP_ID_W            -1 : 0 ]        cfg_wbuf_stride_loop_id;

  wire [ OBUF_ADDR_WIDTH      -1 : 0 ]        obuf_addr;
  wire                                        obuf_addr_v;
  wire [ WBUF_ADDR_WIDTH      -1 : 0 ]        wbuf_addr;
  wire                                        wbuf_addr_v;
  wire [ IBUF_ADDR_WIDTH      -1 : 0 ]        ibuf_addr;
  wire                                        ibuf_addr_v;
  wire [ BBUF_ADDR_WIDTH      -1 : 0 ]        bbuf_addr;
  wire                                        bbuf_addr_v;
  wire                                        start_pulse;              

//==============================================================================

//==============================================================================
// Assigns
//==============================================================================
// Assumption: All the walkers use a similar set of loops and strides. In the compiler it has already been handled that the stride for those loops that are not used for a buffer is set to zero.

  assign cfg_base_stride_v = cfg_loop_stride_v && (cfg_loop_stride_loop_id > MIN_COMPUTE_LOOP_RANGE && cfg_loop_stride_loop_id < MAX_COMPUTE_LOOP_RANGE);

  assign obuf_stride = cfg_loop_stride;
  assign cfg_obuf_stride_v = cfg_base_stride_v && cfg_loop_stride_type == RD && cfg_loop_stride_id == OBUF_MEM_ID;
  assign cfg_obuf_stride_loop_id = cfg_loop_stride_loop_id;

  assign wbuf_stride = cfg_loop_stride;
  assign cfg_wbuf_stride_v = cfg_base_stride_v && cfg_loop_stride_type == RD && cfg_loop_stride_id == WBUF_MEM_ID;
  assign cfg_wbuf_stride_loop_id = cfg_loop_stride_loop_id;  

  assign ibuf_stride = cfg_loop_stride;
  assign cfg_ibuf_stride_v = cfg_base_stride_v && cfg_loop_stride_type == RD && cfg_loop_stride_id == IBUF_MEM_ID;
  assign cfg_ibuf_stride_loop_id = cfg_loop_stride_loop_id;

  assign bbuf_stride = cfg_loop_stride;
  assign cfg_bbuf_stride_v = cfg_base_stride_v && cfg_loop_stride_type == RD && cfg_loop_stride_id == BBUF_MEM_ID;
  assign cfg_bbuf_stride_loop_id = cfg_loop_stride_loop_id;




  assign cfg_base_loop_iter_v = cfg_loop_iter_v && (cfg_loop_iter_loop_id > MIN_COMPUTE_LOOP_RANGE && cfg_loop_iter_loop_id < MAX_COMPUTE_LOOP_RANGE);
  assign cfg_base_loop_iter = cfg_loop_iter;
  assign cfg_base_loop_id = cfg_loop_iter_loop_id;
//==============================================================================
 
//==============================================================================
// Address generators
//==============================================================================
  mem_walker_stride_group #(
    .ADDR_WIDTH                     ( OBUF_ADDR_WIDTH                     ),
    .ADDR_STRIDE_W                  ( ADDR_STRIDE_W                  ),
    .LOOP_ID_W                      ( LOOP_ID_W                      ),
    .GROUP_ID_W                     ( INST_GROUP_ID_W                ),
    .GROUP_ENABLED                  ( GROUP_ENABLED                  )
  ) mws_obuf_ld (
    .clk                            ( clk                            ), //input
    .reset                          ( reset                          ), //input
    .base_addr                      ( obuf_base_addr                 ), //input
    .base_addr_v                    ( obuf_base_addr_v               ),
	  .iter_done						          ( iter_done						           ),
	  .start  						            ( start_pulse				             ),
	  .block_done                     ( block_done                     ),
	  .stall                          ( base_loop_stall                ), //input
	
    .cfg_addr_stride_v              ( cfg_obuf_stride_v              ), //input
    .cfg_addr_stride                ( obuf_stride                    ), //input
    
    .cfg_loop_id                    ( cfg_obuf_stride_loop_id        ), //input
    .cfg_loop_group_id              ( cfg_curr_group_id              ),
   
    .loop_group_id                  ( next_group_id                  ),   

    .addr_out                       ( obuf_addr                      ), //output
    .addr_out_valid                 ( obuf_addr_v                    )  //output
  );

  assign obuf_rd_addr = obuf_addr;
  assign obuf_rd_addr_v = obuf_addr_v;
  
  //register_sync #(OBUF_ADDR_WIDTH) out_addr_reg (clk, reset, obuf_addr, obuf_rd_addr);
  //register_sync #(1'b1) obuf_addr_v_reg (clk, reset, obuf_addr_v, obuf_rd_addr_v);

  assign obuf_wr_addr = obuf_addr;
  assign obuf_wr_addr_v = obuf_addr_v;

  mem_walker_stride_group #(
    .ADDR_WIDTH                     ( BBUF_ADDR_WIDTH                     ),
    .ADDR_STRIDE_W                  ( ADDR_STRIDE_W                  ),
    .LOOP_ID_W                      ( LOOP_ID_W                      ),
    .GROUP_ID_W                     ( INST_GROUP_ID_W                ),
    .GROUP_ENABLED                  ( GROUP_ENABLED                  )
  ) mws_bbuf_ld (
    .clk                            ( clk                            ), //input
    .reset                          ( reset                          ), //input
    .base_addr                      ( bbuf_base_addr                 ), //input
    .base_addr_v                    ( bbuf_base_addr_v               ),
    .iter_done                      ( iter_done                      ),
    .start                          ( start_pulse                    ),
    .block_done                     ( block_done                     ),
    .stall                          ( base_loop_stall                ), //input
    
    .cfg_addr_stride_v              ( cfg_bbuf_stride_v              ), //input
    .cfg_addr_stride                ( bbuf_stride                    ), //input
    
    .cfg_loop_id                    ( cfg_bbuf_stride_loop_id        ), //input
    .cfg_loop_group_id              ( cfg_curr_group_id              ),
   
    .loop_group_id                  ( next_group_id                  ),   

    .addr_out                       ( bbuf_addr                      ), //output
    .addr_out_valid                 ( bbuf_addr_v                    )  //output
  );

  assign bbuf_rd_addr = bbuf_addr;
  assign bbuf_rd_addr_v = bbuf_addr_v;

  mem_walker_stride_group #(
    .ADDR_WIDTH                     ( IBUF_ADDR_WIDTH                     ),
    .ADDR_STRIDE_W                  ( ADDR_STRIDE_W                  ),
    .LOOP_ID_W                      ( LOOP_ID_W                      ),
    .GROUP_ID_W                     ( INST_GROUP_ID_W                ),
    .GROUP_ENABLED                  ( GROUP_ENABLED                  )
  ) mws_ibuf_ld (
    .clk                            ( clk                            ), //input
    .reset                          ( reset                          ), //input
    .base_addr                      ( ibuf_base_addr                 ), //input
    .base_addr_v                    ( ibuf_base_addr_v               ),
    .iter_done                      ( iter_done                      ),
    .start                          ( start_pulse                    ),
    .block_done                     ( block_done                     ),
    .stall                          ( base_loop_stall                ), //input
    
    .cfg_addr_stride_v              ( cfg_ibuf_stride_v              ), //input
    .cfg_addr_stride                ( ibuf_stride                    ), //input
    
    .cfg_loop_id                    ( cfg_ibuf_stride_loop_id        ), //input
    .cfg_loop_group_id              ( cfg_curr_group_id              ),
   
    .loop_group_id                  ( next_group_id                  ),   

    .addr_out                       ( ibuf_addr                      ), //output
    .addr_out_valid                 ( ibuf_addr_v                    )  //output
  );
  
  assign ibuf_rd_addr = ibuf_addr;
  assign ibuf_rd_addr_v = ibuf_addr_v;  

  mem_walker_stride_group #(
    .ADDR_WIDTH                     ( WBUF_ADDR_WIDTH                     ),
    .ADDR_STRIDE_W                  ( ADDR_STRIDE_W                  ),
    .LOOP_ID_W                      ( LOOP_ID_W                      ),
    .GROUP_ID_W                     ( INST_GROUP_ID_W                ),
    .GROUP_ENABLED                  ( GROUP_ENABLED                  )
  ) mws_wbuf_ld (
    .clk                            ( clk                            ), //input
    .reset                          ( reset                          ), //input
    .base_addr                      ( wbuf_base_addr                 ), //input
    .base_addr_v                    ( wbuf_base_addr_v               ),
    .iter_done                      ( iter_done                      ),
    .start                          ( start_pulse                    ),
    .block_done                     ( block_done                     ),
    .stall                          ( base_loop_stall                ), //input
    
    .cfg_addr_stride_v              ( cfg_wbuf_stride_v              ), //input
    .cfg_addr_stride                ( wbuf_stride                    ), //input
    
    .cfg_loop_id                    ( cfg_wbuf_stride_loop_id        ), //input
    .cfg_loop_group_id              ( cfg_curr_group_id              ),
   
    .loop_group_id                  ( next_group_id                  ),   

    .addr_out                       ( wbuf_addr                      ), //output
    .addr_out_valid                 ( wbuf_addr_v                    )  //output
  );

  assign wbuf_rd_addr = wbuf_addr;
  assign wbuf_rd_addr_v = wbuf_addr_v;

//==============================================================================
// Base loop controller
//============================================================================== 
 
  assign base_loop_stall = stall;
  

  controller_fsm_group #(
    .LOOP_ID_W                      ( LOOP_ID_W                      ),
    .GROUP_ID_W                     ( INST_GROUP_ID_W                ),
    .LOOP_ITER_W                    ( LOOP_ITER_W                    ),
    .GROUP_ENABLED                  ( GROUP_ENABLED                  )
  ) base_loop_ctrl (
    .clk                            ( clk                            ), //input
    .reset                          ( reset                          ), //input
    
    .cfg_loop_iter_v                ( cfg_base_loop_iter_v           ), //input
    .cfg_loop_iter                  ( cfg_base_loop_iter             ), //input
    .cfg_loop_iter_loop_id          ( cfg_base_loop_id               ), //input
    
    .start                          ( start_pulse                    ), //input
    .block_done                     ( block_done                     ),
    .done                           ( done                           ), //output
    .stall                          ( base_loop_stall                ), //input
    
    .cfg_loop_group_id              ( cfg_curr_group_id              ), //input
    .loop_group_id                  ( next_group_id                  ), //input
    
    .current_iters                  ( curr_base_loop_iters           ), //output
    
    .iter_done                      ( iter_done				         )  //output
  );
  
//==============================================================================
// ic == 0: Bias needs to be added, bias_prev_sw should be zero
//==============================================================================  
  wire                                              cfg_ic_inner_loop_wr_req;
  wire                                              cfg_ic_inner_loop_rd_req;
  wire [ LOOP_ID_W                  -1 : 0 ]        ic_inner_loop_level;
  
  wire                                              cfg_kw_inner_loop_wr_req;
  wire                                              cfg_kw_inner_loop_rd_req;
  wire [ LOOP_ID_W                  -1 : 0 ]        kw_inner_loop_level;  

  wire                                              cfg_kh_inner_loop_wr_req;
  wire                                              cfg_kh_inner_loop_rd_req;
  wire [ LOOP_ID_W                  -1 : 0 ]        kh_inner_loop_level;
  
  reg  [ NUM_MAX_GROUPS             -1 : 0 ]        compute_ic_loop_cfg;
  reg  [ NUM_MAX_GROUPS             -1 : 0 ]        compute_kw_loop_cfg;
  reg  [ NUM_MAX_GROUPS             -1 : 0 ]        compute_kh_loop_cfg;

    
  reg                                               start_q;
  
  reg  [ NUM_MAX_LOOPS              -1 : 0 ]        _bias_prev_sw;
  


  always @(posedge clk) begin
     if (reset || block_done)
        start_q <= 1'b0;
     else if (sa_compute_done_delayed)
        start_q <= 1'b0; 
     else if (start)
        start_q <= 1'b1;
  end

  assign start_pulse = start && ~start_q;

  always @(posedge clk) begin
     if (reset || block_done) begin
        compute_ic_loop_cfg <= 0;
        compute_kw_loop_cfg <= 0;
        compute_kh_loop_cfg <= 0;
     end
     else if (cfg_ic_inner_loop_wr_req)
        compute_ic_loop_cfg[cfg_curr_group_id] <= 1'b1;
     else if (cfg_kw_inner_loop_wr_req)
        compute_kw_loop_cfg[cfg_curr_group_id] <= 1'b1;
     else if (cfg_kh_inner_loop_wr_req)
        compute_kh_loop_cfg[cfg_curr_group_id] <= 1'b1;
  end

 
  assign cfg_ic_inner_loop_wr_req = cfg_set_specific_loop_v && (cfg_set_specific_loop_loop_param == IC_INNER_LOOP_PARAM);
  assign cfg_ic_inner_loop_rd_req = start || start_q;

  assign cfg_kw_inner_loop_wr_req = cfg_set_specific_loop_v && (cfg_set_specific_loop_loop_param == KW_INNER_LOOP_PARAM);
  assign cfg_kw_inner_loop_rd_req = start || start_q;

  assign cfg_kh_inner_loop_wr_req = cfg_set_specific_loop_v && (cfg_set_specific_loop_loop_param == KH_INNER_LOOP_PARAM);
  assign cfg_kh_inner_loop_rd_req = start || start_q;

  
  
  genvar i;
  generate
      for (i=0; i<NUM_MAX_LOOPS; i=i+1) begin
          always @(*) begin
             // if (i == ic_inner_loop_level) begin
                 _bias_prev_sw[i] = (curr_base_loop_iters[(i+1)*LOOP_ITER_W-1:i*LOOP_ITER_W] == 0);
             // end              
          end            
      end
  endgenerate
  
  //assign bias_prev_sw = (compute_ic_loop_cfg[next_group_id] && compute_kw_loop_cfg[next_group_id] && compute_kh_loop_cfg[next_group_id]) ? ~(_bias_prev_sw[ic_inner_loop_level] && _bias_prev_sw[kw_inner_loop_level] && _bias_prev_sw[kh_inner_loop_level]) : ~(_bias_prev_sw[ic_inner_loop_level]);
  assign bias_prev_sw =  obuf_first_ic_outer_loop_ld ? (compute_ic_loop_cfg[next_group_id] && compute_kw_loop_cfg[next_group_id] && compute_kh_loop_cfg[next_group_id]) ? ~(_bias_prev_sw[ic_inner_loop_level] && _bias_prev_sw[kw_inner_loop_level] && _bias_prev_sw[kh_inner_loop_level]) : ~(_bias_prev_sw[ic_inner_loop_level]) : 1'b1;
  
 ram
#(
  .DATA_WIDTH               ( LOOP_ID_W         ),
  .ADDR_WIDTH               ( INST_GROUP_ID_W   )
) ic_inner_loop_level_memory (
    
  .clk                      (    clk                            ),
  .reset                    (    reset                          ),

  .read_req                 (    cfg_ic_inner_loop_rd_req       ),
  .read_addr                (    next_group_id                  ),
  .read_data                (    ic_inner_loop_level            ),

  .write_req                (    cfg_ic_inner_loop_wr_req       ),
  .write_addr               (    cfg_curr_group_id              ),
  .write_data               (    cfg_set_specific_loop_loop_id  )
); 
 

 ram
#(
  .DATA_WIDTH               ( LOOP_ID_W         ),
  .ADDR_WIDTH               ( INST_GROUP_ID_W   )
) kw_inner_loop_level_memory (
    
  .clk                      (    clk                            ),
  .reset                    (    reset                          ),

  .read_req                 (    cfg_kw_inner_loop_rd_req       ),
  .read_addr                (    next_group_id                  ),
  .read_data                (    kw_inner_loop_level            ),

  .write_req                (    cfg_kw_inner_loop_wr_req       ),
  .write_addr               (    cfg_curr_group_id              ),
  .write_data               (    cfg_set_specific_loop_loop_id  )
); 

 
 ram
#(
  .DATA_WIDTH               ( LOOP_ID_W         ),
  .ADDR_WIDTH               ( INST_GROUP_ID_W   )
) kh_inner_loop_level_memory (
    
  .clk                      (    clk                            ),
  .reset                    (    reset                          ),

  .read_req                 (    cfg_kh_inner_loop_rd_req       ),
  .read_addr                (    next_group_id                  ),
  .read_data                (    kh_inner_loop_level            ),

  .write_req                (    cfg_kh_inner_loop_wr_req       ),
  .write_addr               (    cfg_curr_group_id              ),
  .write_data               (    cfg_set_specific_loop_loop_id  )
); 
//==============================================================================

//==============================================================================
//// VCD
////==============================================================================
//`ifdef COCOTB_TOPLEVEL_base_addr_gen
//initial begin
//  $dumpfile("base_addr_gen.vcd");
//  $dumpvars(0, base_addr_gen);
//end
//`endif
//==============================================================================
endmodule
