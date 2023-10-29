//
// Base address generator
//

`timescale 1ns/1ps
module base_addr_gen #(
  // Internal Parameters
  parameter integer  NUM_BASE_LOOPS               = 7,
  parameter integer  WBUF_MEM_ID                  = 0,
  parameter integer  IBUF_MEM_ID                  = 1,
  parameter integer  OBUF_MEM_ID                  = 2,
  parameter integer  BBUF_MEM_ID                  = 3,

  parameter integer  ADDR_WIDTH                   = 42,
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
  input  wire  [ NUM_MAX_GROUPS       -1 : 0 ]        group_first_iter,


  input  wire                                         stall,

  // Programming LOOP Iter
  input  wire                                         cfg_loop_iter_v,
  input  wire  [ LOOP_ITER_W          -1 : 0 ]        cfg_loop_iter,
  input  wire  [ LOOP_ID_W            -1 : 0 ]        cfg_loop_iter_loop_id,

  input  wire                                         cfg_set_specific_loop_v,
  input  wire  [ LOOP_ID_W            -1 : 0 ]        cfg_set_specific_loop_loop_id,
  input  wire  [ 2                       : 0 ]        cfg_set_specific_loop_loop_param,

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
  
  // Address - OBUF LD/ST
  input  wire  [ ADDR_WIDTH      -1 : 0 ]             obuf_base_addr,
  output wire  [ ADDR_WIDTH      -1 : 0 ]             obuf_ld_addr,
  output wire                                         obuf_ld_addr_v,
  output wire  [ ADDR_WIDTH      -1 : 0 ]             obuf_st_addr,
  output wire                                         obuf_st_addr_v,
  // Address - IBUF LD
  input  wire  [ ADDR_WIDTH      -1 : 0 ]             ibuf_base_addr,
  output wire  [ ADDR_WIDTH      -1 : 0 ]             ibuf_ld_addr,
  output wire                                         ibuf_ld_addr_v,
  // Address - WBUF LD
  input  wire  [ ADDR_WIDTH      -1 : 0 ]             wbuf_base_addr,
  output wire  [ ADDR_WIDTH      -1 : 0 ]             wbuf_ld_addr,
  output wire                                         wbuf_ld_addr_v,
  // Address - BIAS LD
  input  wire  [ ADDR_WIDTH      -1 : 0 ]             bbuf_base_addr,
  output wire  [ ADDR_WIDTH      -1 : 0 ]             bbuf_ld_addr,
  output wire                                         bbuf_ld_addr_v,

//  output wire                                         bias_prev_sw,
  output wire                                         first_ic_outer_loop_ld,
  output wire                                         ddr_pe_sw
);


//==============================================================================
// Local Params
//==============================================================================
  localparam integer  LD                            = 0;
  localparam integer  ST                            = 1; 
  localparam integer  RD                            = 2;
  localparam integer  WR                            = 3;
    
  localparam integer  IC_OUTER_LOOP_PARAM           = 4;
  localparam integer  KW_OUTER_LOOP_PARAM           = 5;
  localparam integer  KH_OUTER_LOOP_PARAM           = 6;
//==============================================================================
// Wires/Regs
//==============================================================================
  // Programming - Base loop
  wire                                        cfg_base_loop_iter_v;
  wire [ LOOP_ITER_W          -1 : 0 ]        cfg_base_loop_iter;
  wire [ LOOP_ID_W            -1 : 0 ]        cfg_base_loop_id;
  
  
    
  wire  [ (1<<LOOP_ID_W)        : 0 ]         iter_done;

  wire [ ADDR_WIDTH           -1 : 0 ]        _obuf_base_addr;
  wire [ ADDR_WIDTH           -1 : 0 ]        _wbuf_base_addr;
  wire [ ADDR_WIDTH           -1 : 0 ]        _ibuf_base_addr;
  wire [ ADDR_WIDTH           -1 : 0 ]        _bbuf_base_addr;

  wire                                        obuf_base_addr_v;
  wire                                        wbuf_base_addr_v; 
  wire                                        ibuf_base_addr_v;
  wire                                        bbuf_base_addr_v;

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

  wire [ ADDR_WIDTH      -1 : 0 ]             obuf_addr;
  wire                                        obuf_addr_v;
  wire [ ADDR_WIDTH      -1 : 0 ]             wbuf_addr;
  wire                                        wbuf_addr_v;
  wire [ ADDR_WIDTH      -1 : 0 ]             ibuf_addr;
  wire                                        ibuf_addr_v;
  wire [ ADDR_WIDTH      -1 : 0 ]             bbuf_addr;
  wire                                        bbuf_addr_v;

  wire                                              cfg_ic_outer_loop_wr_req;
  wire                                              cfg_ic_outer_loop_rd_req;
  wire [ LOOP_ID_W                  -1 : 0 ]        ic_outer_loop_level;
  
  reg  [ NUM_MAX_LOOPS                  -1 : 0 ]    _first_ic_outer_loop_ld;
  reg  [ NUM_MAX_LOOPS                  -1 : 0 ]    _ddr_pe_sw;
  wire   [LOOP_ITER_W-1 : 0]   max_iter_ic ;
   
//==============================================================================

//==============================================================================
// Assigns
//==============================================================================
// Assumption: All the walkers use a similar set of loops and strides. In the compiler it has already been handled that the stride for those loops that are not used for a buffer is set to zero.

  assign cfg_base_stride_v = cfg_loop_stride_v && (cfg_loop_stride_loop_id < NUM_BASE_LOOPS);

  assign obuf_stride = cfg_loop_stride;
  assign cfg_obuf_stride_v = cfg_base_stride_v && cfg_loop_stride_type == LD && cfg_loop_stride_id == OBUF_MEM_ID;
  assign cfg_obuf_stride_loop_id = cfg_loop_stride_loop_id;

  assign wbuf_stride = cfg_loop_stride;
  assign cfg_wbuf_stride_v = cfg_base_stride_v && cfg_loop_stride_type == LD && cfg_loop_stride_id == WBUF_MEM_ID;
  assign cfg_wbuf_stride_loop_id = cfg_loop_stride_loop_id;  

  assign ibuf_stride = cfg_loop_stride;
  assign cfg_ibuf_stride_v = cfg_base_stride_v && cfg_loop_stride_type == LD && cfg_loop_stride_id == IBUF_MEM_ID;
  assign cfg_ibuf_stride_loop_id = cfg_loop_stride_loop_id;

  assign bbuf_stride = cfg_loop_stride;
  assign cfg_bbuf_stride_v = cfg_base_stride_v && cfg_loop_stride_type == LD && cfg_loop_stride_id == BBUF_MEM_ID;
  assign cfg_bbuf_stride_loop_id = cfg_loop_stride_loop_id;

  assign cfg_base_loop_iter_v = cfg_loop_iter_v && cfg_loop_iter_loop_id < NUM_BASE_LOOPS;
  assign cfg_base_loop_iter = cfg_loop_iter;
  assign cfg_base_loop_id = cfg_loop_iter_loop_id;
//==============================================================================
 
//==============================================================================
// BASE ADDR Memories
//==============================================================================  

  wire                                      base_addr_mem_wr_req;
  wire                                      base_addr_mem_rd_req;
  wire                                      base_addr_v;
  reg   [  NUM_MAX_GROUPS -1 : 0]            _group_first_iter_v;
  wire                                      group_first_iter_v;
  
  genvar n;
  generate
      for (n=0; n<NUM_MAX_GROUPS; n=n+1) begin
         always @(*) begin
            // if (n == next_group_id)
               _group_first_iter_v[n] = group_first_iter[n]; 
         end 
      end
  endgenerate
  
  assign group_first_iter_v = _group_first_iter_v[next_group_id];
  
    
  assign base_addr_mem_wr_req = inst_group_v && inst_group_s_e && ~inst_group_type;
 
  assign base_addr_mem_rd_req = (start) && group_first_iter_v;
  
  register_sync #(1) base_addr_v_reg (clk, reset, base_addr_mem_rd_req, base_addr_v);  
  
  assign obuf_base_addr_v = base_addr_v;  
  assign ibuf_base_addr_v = base_addr_v;  
  assign wbuf_base_addr_v = base_addr_v;  
  assign bbuf_base_addr_v = base_addr_v;  

ram
#(
  .DATA_WIDTH               ( ADDR_WIDTH        ),
  .ADDR_WIDTH               ( INST_GROUP_ID_W   )
) wbuf_base_addr_memory (
    
  .clk                      (    clk                            ),
  .reset                    (    reset                          ),

  .read_req                 (    base_addr_mem_rd_req           ),
  .read_addr                (    next_group_id                  ),
  .read_data                (    _wbuf_base_addr                ),

  .write_req                (    base_addr_mem_wr_req           ),
  .write_addr               (    cfg_curr_group_id              ),
  .write_data               (    wbuf_base_addr                 )
);


ram
#(
  .DATA_WIDTH               ( ADDR_WIDTH        ),
  .ADDR_WIDTH               ( INST_GROUP_ID_W   )
) ibuf_base_addr_memory (
    
  .clk                      (    clk                            ),
  .reset                    (    reset                          ),

  .read_req                 (    base_addr_mem_rd_req           ),
  .read_addr                (    next_group_id                  ),
  .read_data                (    _ibuf_base_addr                ),

  .write_req                (    base_addr_mem_wr_req           ),
  .write_addr               (    cfg_curr_group_id              ),
  .write_data               (    ibuf_base_addr                 )
);

ram
#(
  .DATA_WIDTH               ( ADDR_WIDTH        ),
  .ADDR_WIDTH               ( INST_GROUP_ID_W   )
) obuf_base_addr_memory (
    
  .clk                      (    clk                            ),
  .reset                    (    reset                          ),

  .read_req                 (    base_addr_mem_rd_req           ),
  .read_addr                (    next_group_id                  ),
  .read_data                (    _obuf_base_addr                ),

  .write_req                (    base_addr_mem_wr_req           ),
  .write_addr               (    cfg_curr_group_id              ),
  .write_data               (    obuf_base_addr                 )
);

ram
#(
  .DATA_WIDTH               ( ADDR_WIDTH        ),
  .ADDR_WIDTH               ( INST_GROUP_ID_W   )
) bbuf_base_addr_memory (
    
  .clk                      (    clk                            ),
  .reset                    (    reset                          ),

  .read_req                 (    base_addr_mem_rd_req           ),
  .read_addr                (    next_group_id                  ),
  .read_data                (    _bbuf_base_addr                ),

  .write_req                (    base_addr_mem_wr_req           ),
  .write_addr               (    cfg_curr_group_id              ),
  .write_data               (    bbuf_base_addr                 )
);

  
//==============================================================================
// Address generators
//==============================================================================
  mem_walker_stride_group #(
    .ADDR_WIDTH                     ( ADDR_WIDTH                     ),
    .ADDR_STRIDE_W                  ( ADDR_STRIDE_W                  ),
    .LOOP_ID_W                      ( LOOP_ID_W                      ),
    .GROUP_ID_W                     ( INST_GROUP_ID_W                ),
    .GROUP_ENABLED                  ( GROUP_ENABLED                  )
  ) mws_obuf_ld (
    .clk                            ( clk                            ), //input
    .reset                          ( reset                          ), //input
    .base_addr                      ( _obuf_base_addr                ), //input
    .base_addr_v                    ( obuf_base_addr_v               ),
	.iter_done						( iter_done						 ),
	.start  						( start_delay      				     ),
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

  assign obuf_ld_addr = obuf_addr;
  assign obuf_ld_addr_v = obuf_addr_v;
  
  assign obuf_st_addr = obuf_addr;
  assign obuf_st_addr_v = obuf_addr_v;

  mem_walker_stride_group #(
    .ADDR_WIDTH                     ( ADDR_WIDTH                     ),
    .ADDR_STRIDE_W                  ( ADDR_STRIDE_W                  ),
    .LOOP_ID_W                      ( LOOP_ID_W                      ),
    .GROUP_ID_W                     ( INST_GROUP_ID_W                ),
    .GROUP_ENABLED                  ( GROUP_ENABLED                  )
  ) mws_bbuf_ld (
    .clk                            ( clk                            ), //input
    .reset                          ( reset                          ), //input
    .base_addr                      ( _bbuf_base_addr                ), //input
    .base_addr_v                    ( bbuf_base_addr_v               ),
    .iter_done                      ( iter_done                      ),
    .start                          ( start_delay                          ),
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

  assign bbuf_ld_addr = bbuf_addr;
  assign bbuf_ld_addr_v = bbuf_addr_v;

  mem_walker_stride_group #(
    .ADDR_WIDTH                     ( ADDR_WIDTH                     ),
    .ADDR_STRIDE_W                  ( ADDR_STRIDE_W                  ),
    .LOOP_ID_W                      ( LOOP_ID_W                      ),
    .GROUP_ID_W                     ( INST_GROUP_ID_W                ),
    .GROUP_ENABLED                  ( GROUP_ENABLED                  )
  ) mws_ibuf_ld (
    .clk                            ( clk                            ), //input
    .reset                          ( reset                          ), //input
    .base_addr                      ( _ibuf_base_addr                ), //input
    .base_addr_v                    ( ibuf_base_addr_v               ),
    .iter_done                      ( iter_done                      ),
    .start                          ( start_delay                          ),
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
  
  assign ibuf_ld_addr = ibuf_addr;
  assign ibuf_ld_addr_v = ibuf_addr_v;  

  mem_walker_stride_group #(
    .ADDR_WIDTH                     ( ADDR_WIDTH                     ),
    .ADDR_STRIDE_W                  ( ADDR_STRIDE_W                  ),
    .LOOP_ID_W                      ( LOOP_ID_W                      ),
    .GROUP_ID_W                     ( INST_GROUP_ID_W                ),
    .GROUP_ENABLED                  ( GROUP_ENABLED                  )
  ) mws_wbuf_ld (
    .clk                            ( clk                            ), //input
    .reset                          ( reset                          ), //input
    .base_addr                      ( _wbuf_base_addr                ), //input
    .base_addr_v                    ( wbuf_base_addr_v               ),
    .iter_done                      ( iter_done                      ),
    .start                          ( start_delay                          ),
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

  assign wbuf_ld_addr = wbuf_addr;
  assign wbuf_ld_addr_v = wbuf_addr_v;

//==============================================================================
// Base loop controller
//==============================================================================
  reg                       start_q;
  
 
  assign base_loop_stall = stall;
  // assign base_loop_stall = 1'b0;
  always @(posedge clk) begin 
      if (reset || block_done)
          start_q <= 1'b0;
      else if (start)
          start_q <= 1'b1;
  end

  wire                      start_delay;
  register_sync #(1) start_delay_reg (clk, reset, start, start_delay);


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
    
    .start                          ( start_delay                          ), //input
    .block_done                     ( block_done                     ),
    .done                           ( done                           ), //output
    .stall                          ( base_loop_stall                ), //input
    
    .cfg_loop_group_id              ( cfg_curr_group_id              ), //input
    .loop_group_id                  ( next_group_id                  ), //input
    
    .current_iters                  ( curr_base_loop_iters           ), //output
    
    .iter_done                      ( iter_done				         ),  //output
    .max_iter_ic                    ( max_iter_ic                      )
  );
  
//==============================================================================
// IC == 0 (LD_DUMMY_OBUF) and IC Iter Done/ We use the Loop Level Info
//==============================================================================  

  assign cfg_ic_outer_loop_wr_req = cfg_set_specific_loop_v && (cfg_set_specific_loop_loop_param == IC_OUTER_LOOP_PARAM);
  assign cfg_ic_outer_loop_rd_req = start || ~base_loop_stall;
  
  
  genvar i;
  generate
      for (i=0; i<NUM_MAX_LOOPS; i=i+1) begin
          always @(*) begin
             // if (i == ic_outer_loop_level) begin
                 _first_ic_outer_loop_ld[i] = (curr_base_loop_iters[(i+1)*LOOP_ITER_W-1:i*LOOP_ITER_W] == 0);
                 _ddr_pe_sw[i] = iter_done[i];
             // end              
          end            
      end
  endgenerate
  
  assign first_ic_outer_loop_ld = _first_ic_outer_loop_ld[ic_outer_loop_level];
  assign ddr_pe_sw = (max_iter_ic==0)?1'b1: _ddr_pe_sw[ic_outer_loop_level];
  
 ram
#(
  .DATA_WIDTH               ( LOOP_ID_W         ),
  .ADDR_WIDTH               ( INST_GROUP_ID_W   )
) ic_outer_loop_level_memory (
    
  .clk                      (    clk                            ),
  .reset                    (    reset                          ),

  .read_req                 (    cfg_ic_outer_loop_rd_req       ),
  .read_addr                (    next_group_id                  ),
  .read_data                (    ic_outer_loop_level            ),

  .write_req                (    cfg_ic_outer_loop_wr_req       ),
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
