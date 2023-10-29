// 
// Data Shuffler module to transpose/permute tensors
//

module simd_data_shuffler #(
parameter   VMEM1_MEM_ID                        = 2,
parameter   VMEM2_MEM_ID                        = 3,

parameter   LOOP_ITER_W                         = 16,
parameter   ADDR_STRIDE_W                       = 16,
parameter   BASE_ADDR_W                         = 16, 
parameter   LOOP_ID_W                           = 5,

parameter   NUM_TAGS                            = 1,
parameter   TAG_W                               = $clog2(NUM_TAGS),
parameter   SIMD_DATA_WIDTH                     = 32,
parameter   NUM_SIMD_LANES                      = 4,
parameter   VMEM_BUF_ADDR_W                     = 16,
parameter   VMEM_TAG_BUF_ADDR_W                 = VMEM_BUF_ADDR_W + TAG_W,
parameter   BANK_COUNTER_W                      = $clog2(NUM_SIMD_LANES)+1,

parameter   GROUP_ID_W                          = 4,
parameter   MAX_NUM_GROUPS                      = (1<<GROUP_ID_W),
parameter   GROUP_ENABLED                       = 0,

parameter   NS_ID_BITS                          = 3,
parameter   NS_INDEX_ID_BITS                    = 5,
parameter   OPCODE_BITS                         = 4,
parameter   FUNCTION_BITS                       = 4,
parameter   INSTRUCTION_WIDTH                   = OPCODE_BITS + FUNCTION_BITS + 3*(NS_ID_BITS + NS_INDEX_ID_BITS)

)(
input  wire                                         clk,
input  wire                                         reset,
input  wire                                         block_done,

input  wire  [GROUP_ID_W            -1:0]           group_id,
// Extracted filed instruction
input  wire  [OPCODE_BITS           -1:0]           opcode,
input  wire  [FUNCTION_BITS         -1:0]           fn,
input  wire  [NS_ID_BITS            -1:0]           dest_ns_id,
input  wire  [NS_INDEX_ID_BITS      -1:0]           dest_ns_index_id,  
input  wire  [NS_ID_BITS            -1:0]           src1_ns_id,
input  wire  [NS_INDEX_ID_BITS      -1:0]           src1_ns_index_id,    
input  wire  [NS_ID_BITS            -1:0]           src2_ns_id,
input  wire  [NS_INDEX_ID_BITS      -1:0]           src2_ns_index_id,

output wire                                         data_shuffle_done,

// VMEM1
output wire  [NUM_SIMD_LANES        -1:0]               vmem1_write_req,
output wire  [NUM_SIMD_LANES*VMEM_TAG_BUF_ADDR_W-1:0]   vmem1_write_addr,
output wire  [NUM_SIMD_LANES*SIMD_DATA_WIDTH -1:0]      vmem1_write_data,
output wire  [NUM_SIMD_LANES        -1:0]               vmem1_read_req,
output wire  [NUM_SIMD_LANES*VMEM_TAG_BUF_ADDR_W-1:0]   vmem1_read_addr,
input  wire  [NUM_SIMD_LANES*SIMD_DATA_WIDTH -1:0]      vmem1_read_data,
// VMEM2
output wire  [NUM_SIMD_LANES        -1:0]               vmem2_write_req,
output wire  [NUM_SIMD_LANES*VMEM_TAG_BUF_ADDR_W-1:0]   vmem2_write_addr,
output wire  [NUM_SIMD_LANES*SIMD_DATA_WIDTH -1:0]      vmem2_write_data,
output wire  [NUM_SIMD_LANES        -1:0]               vmem2_read_req,
output wire  [NUM_SIMD_LANES*VMEM_TAG_BUF_ADDR_W-1:0]   vmem2_read_addr,
input  wire  [NUM_SIMD_LANES*SIMD_DATA_WIDTH -1:0]      vmem2_read_data

);

//==============================================================================
// Localparams
//==============================================================================
    localparam integer      SET_BASE_ADDR               = 0;
    localparam integer      SET_LOOP_ITER               = 1;
    localparam integer      SET_LOOP_STRIDE             = 2;
    localparam integer      START                       = 3;
    
    localparam integer      PERMUTATION_INST            = 8;
    
    localparam integer      RD_SRC                      = 0;
    localparam integer      WR_DST                      = 1;
    
    localparam integer      NO_BANK_SHUFFLING           = 0;
    localparam integer      BANK_SHUFFLING              = 1;
    
    // FSM States
    localparam integer      IDLE                        = 0;
    localparam integer      BUSY                        = 1;
    localparam integer      DONE_WAIT                   = 2;
    localparam integer      DONE                        = 3;
    

//==============================================================================
// WIRE & REG
//==============================================================================
    // RD SRC Walker
    wire    [VMEM_BUF_ADDR_W            -1:0]              mws_rd_src_base_addr;
//    wire                                               mws_rd_src_iter_done;
    wire                                               mws_rd_src_start;
    wire                                               mws_rd_src_stall;
    wire                                               mws_rd_src_base_addr_v;
    wire                                               mws_rd_src_cfg_addr_stride_v;
    wire    [ADDR_STRIDE_W          -1:0]              mws_rd_src_cfg_addr_stride;
    wire    [VMEM_BUF_ADDR_W        -1:0]              mws_rd_src_addr;
    wire                                               mws_rd_src_addr_v;
    // RD SRC controller_fsm
    wire                                               mws_rd_src_done;
    wire                                               mws_rd_src_cfg_loop_iter_v;
    wire    [ (1<<LOOP_ID_W)	 : 0 ]                 mws_rd_src_iter_done;                                                             

    // WR DST Walker
    wire    [VMEM_BUF_ADDR_W            -1:0]              mws_wr_dst_base_addr;
//    wire                                               mws_wr_dst_iter_done;
    wire                                               mws_wr_dst_start;
    wire                                               mws_wr_dst_stall;
    wire                                               mws_wr_dst_base_addr_v;
    wire                                               mws_wr_dst_cfg_addr_stride_v;
    wire    [ADDR_STRIDE_W          -1:0]              mws_wr_dst_cfg_addr_stride;
    wire    [VMEM_BUF_ADDR_W        -1:0]              mws_wr_dst_addr;
    wire                                               mws_wr_dst_addr_v;
    // WR DST controller_fsm
    wire                                               mws_wr_dst_done;
    wire                                               mws_wr_dst_cfg_loop_iter_v;
    wire    [ (1<<LOOP_ID_W)	 : 0 ]                 mws_wr_dst_iter_done;
    
    // Config signals from instructions   
    wire                                               cfg_base_addr_v;
    wire                                               data_transfer_type;
    wire    [LOOP_ID_W              -1:0]              cfg_loop_id;
    wire    [LOOP_ITER_W            -1:0]              cfg_loop_iter;
    wire    [BASE_ADDR_W            -1:0]              cfg_base_addr;
    wire                                               cfg_addr_stride_v;
    wire    [ADDR_STRIDE_W          -1:0]              cfg_addr_stride;
    
    // Start signals
    wire                                               shuffle_start;
    reg                                                shuffle_start_q;
    reg                                                shuffle_start_qq;
    reg     [NS_ID_BITS             -1:0]              dst_ns_id_q;
    reg     [NS_ID_BITS             -1:0]              src_ns_id_q;
    wire                                               shuffling_mode;
    reg                                                shuffling_mode_q;
    
    reg     [2:0]                                      state_d;
    reg     [2:0]                                      state_q;
    reg     [BANK_COUNTER_W         -1:0]              wait_cycles_d;
    reg     [BANK_COUNTER_W         -1:0]              wait_cycles_q;    
//==============================================================================
  
//==============================================================================
// ASSIGNS CONFIG SIGNALS
//==============================================================================
    // general config signals
    assign cfg_base_addr_v = (opcode == PERMUTATION_INST) && (fn == SET_BASE_ADDR);
    assign cfg_addr_stride_v = (opcode == PERMUTATION_INST) && (fn == SET_LOOP_STRIDE);
    assign cfg_loop_iter_v = (opcode == PERMUTATION_INST) && (fn == SET_LOOP_ITER);
    
    assign data_transfer_type = dest_ns_id[0];
    assign cfg_base_addr = {src1_ns_id, src1_ns_index_id, src2_ns_id, src2_ns_index_id};
    assign cfg_addr_stride = {src1_ns_id, src1_ns_index_id, src2_ns_id, src2_ns_index_id};
    assign cfg_loop_iter = {src1_ns_id, src1_ns_index_id, src2_ns_id, src2_ns_index_id};
    assign cfg_loop_id = dest_ns_index_id;

    
    // config mws_rd_src
    assign mws_rd_src_base_addr_v = cfg_base_addr_v && (data_transfer_type == RD_SRC);
    assign mws_rd_src_base_addr = cfg_base_addr[VMEM_BUF_ADDR_W-1:0];
    assign mws_rd_src_cfg_addr_stride = cfg_addr_stride;
    assign mws_rd_src_cfg_addr_stride_v = cfg_addr_stride_v && (data_transfer_type == RD_SRC);
    // config controller_fsm_rd_src
    assign mws_rd_src_cfg_loop_iter_v = cfg_loop_iter_v && (data_transfer_type == RD_SRC);
    
     // config mws_wr_dst
    assign mws_wr_dst_base_addr_v = cfg_base_addr_v && (data_transfer_type == WR_DST);
    assign mws_wr_dst_base_addr = cfg_base_addr[VMEM_BUF_ADDR_W-1:0];
    assign mws_wr_dst_cfg_addr_stride = cfg_addr_stride;
    assign mws_wr_dst_cfg_addr_stride_v = cfg_addr_stride_v && (data_transfer_type == WR_DST);
    // config controller_fsm_rd_src
    assign mws_wr_dst_cfg_loop_iter_v = cfg_loop_iter_v && (data_transfer_type == WR_DST);  
    
    assign shuffling_mode = src2_ns_index_id[0]; 
//==============================================================================

//==============================================================================
// ASSIGNS START/DONE Signals
//==============================================================================
    assign shuffle_start = (opcode == PERMUTATION_INST) && (fn == START);
    
    always @(posedge clk) begin
       if (reset)
          shuffle_start_q <= 1'b0;
       else
          shuffle_start_q <= shuffle_start;  
    end
 
    always @(posedge clk) begin
       if (reset)
          shuffle_start_qq <= 1'b0;
       else
          shuffle_start_qq <= shuffle_start_q; 
    end
    // start the wlakers/controller_fsm
    assign mws_rd_src_start = shuffle_start_q;
    assign mws_wr_dst_start = shuffle_start_qq;
    
   
    // storing the dest/src ns_id and shuffling mode info
    always @(posedge clk) begin
       if (reset) begin
           dst_ns_id_q <= 0;
           src_ns_id_q <= 0;
           // default is no bank shuffling
           shuffling_mode_q <= 1'b0;
       end
       else if (shuffle_start) begin
           dst_ns_id_q <= dest_ns_id;
           src_ns_id_q <= src1_ns_id;
           shuffling_mode_q <= shuffling_mode; 
       end
    end
    
    assign data_shuffle_done = state_q == DONE;
//==============================================================================
    
    
//==============================================================================
// FSM
//==============================================================================
  always @(posedge clk) begin
     if (reset) 
        state_q <= IDLE; 
     else
        state_q <= state_d;
  end
  
  always @(posedge clk)
  begin
    if (reset)
      wait_cycles_q <= 0;
    else
      wait_cycles_q <= wait_cycles_d;
  end  

  
  always @(*) begin
     state_d = state_q;
     wait_cycles_d = wait_cycles_q;   
     case(state_q) 
         IDLE: begin
            if (shuffle_start)
                state_d = BUSY; 
         end
         BUSY: begin
            if (mws_wr_dst_done) 
               state_d = DONE_WAIT;
               wait_cycles_d = NUM_SIMD_LANES;
         end
         DONE_WAIT: begin
             if (wait_cycles_q == 0)
                state_d = DONE;
             else 
                wait_cycles_d = wait_cycles_q - 1'b1; 
         end
         DONE: begin
            state_d = IDLE; 
         end
     endcase 
      
  end

//==============================================================================    
// mem_walker_stride and controller_fsm for RD SRC Data 
//==============================================================================
    assign mws_rd_src_stall = 1'b0;
    assign mws_wr_dst_stall = 1'b0;
    
    mem_walker_stride_group_simd #(
        .ADDR_WIDTH                   ( VMEM_BUF_ADDR_W ),
        .ADDR_STRIDE_W                ( ADDR_STRIDE_W   ),
        .LOOP_ID_W                    ( LOOP_ID_W       ),
        .GROUP_ID_W                   ( GROUP_ID_W      ),
        .GROUP_ENABLED                ( GROUP_ENABLED   )  
    ) mws_base_rd_src (
        .clk                          ( clk ),
        .reset                        ( reset ),
        
        .isBase                       (1'b0),

        .base_addr                    ( mws_rd_src_base_addr        ),
        .iter_done                    ( mws_rd_src_iter_done        ),
        .start                        ( mws_rd_src_start            ),
        .stall                        ( mws_rd_src_stall            ),
        .block_done                   ( block_done                  ),
        .base_addr_v                  ( mws_rd_src_base_addr_v      ),
        
        .cfg_loop_id                  ( cfg_loop_id                 ),
        .cfg_addr_stride_v            ( mws_rd_src_cfg_addr_stride_v),
        .cfg_addr_stride              ( mws_rd_src_cfg_addr_stride  ),
        
        .cfg_loop_group_id            ( group_id                    ),
        .loop_group_id                ( group_id                    ),
        
        .addr_out                     ( mws_rd_src_addr             ),
        .addr_out_valid               ( mws_rd_src_addr_v           )
    );


    controller_fsm_group_simd #(
        .LOOP_ID_W                    ( LOOP_ID_W    ),
        .GROUP_ID_W                   ( GROUP_ID_W   ),
        .LOOP_ITER_W                  ( LOOP_ITER_W  ),
        .GROUP_ENABLED                ( GROUP_ENABLED)
    ) controller_fsm_rd_src  (
        .clk                          ( clk ),
        .reset                        ( reset ),
        .isBase                       (1'b0),

        .start                        ( mws_rd_src_start        ),
        .block_done                   ( block_done              ),
        .done                         ( mws_rd_src_done         ),
        .stall                        ( mws_rd_src_stall        ),
        
        .cfg_loop_iter_v              ( mws_rd_src_cfg_loop_iter_v ),
        .cfg_loop_iter                ( cfg_loop_iter              ),
        .cfg_loop_iter_loop_id        ( cfg_loop_id                ),   
        .cfg_loop_group_id            ( group_id                   ),
        
        .loop_group_id                ( group_id                   ),
        .iter_done                    ( mws_rd_src_iter_done       ),
        .current_iters                (                            )
    );



//==============================================================================    
// mem_walker_stride and controller_fsm for WR DST Data
//==============================================================================
    mem_walker_stride_group_simd #(
      .ADDR_WIDTH                   ( VMEM_BUF_ADDR_W ),
      .ADDR_STRIDE_W                ( ADDR_STRIDE_W   ),
      .LOOP_ID_W                    ( LOOP_ID_W       ),
      .GROUP_ID_W                   ( GROUP_ID_W      ),
      .GROUP_ENABLED                ( GROUP_ENABLED   )  
    ) mws_base_wr_dst (
      .clk                          ( clk ),
      .reset                        ( reset ),
      .isBase                       (1'b0),

      .base_addr                    ( mws_wr_dst_base_addr        ),
      .iter_done                    ( mws_wr_dst_iter_done        ),
      .start                        ( mws_wr_dst_start            ),
      .stall                        ( mws_wr_dst_stall            ),
      .block_done                   ( block_done                  ),
      .base_addr_v                  ( mws_wr_dst_base_addr_v      ),
      
      .cfg_loop_id                  ( cfg_loop_id                 ),
      .cfg_addr_stride_v            ( mws_wr_dst_cfg_addr_stride_v),
      .cfg_addr_stride              ( mws_wr_dst_cfg_addr_stride  ),
      
      .cfg_loop_group_id            ( group_id                    ),
      .loop_group_id                ( group_id                    ),
      
      .addr_out                     ( mws_wr_dst_addr             ),
      .addr_out_valid               ( mws_wr_dst_addr_v           )
    );


    controller_fsm_group_simd #(
      .LOOP_ID_W                    ( LOOP_ID_W    ),
      .GROUP_ID_W                   ( GROUP_ID_W   ),
      .LOOP_ITER_W                  ( LOOP_ITER_W  ),
      .GROUP_ENABLED                ( GROUP_ENABLED)
    ) controller_fsm_wr_dst  (
      .clk                          ( clk ),
      .reset                        ( reset ),
      .isBase                       (1'b0),
      
      .start                        ( mws_wr_dst_start        ),
      .block_done                   ( block_done              ),
      .done                         ( mws_wr_dst_done         ),
      .stall                        ( mws_wr_dst_stall        ),
      
      .cfg_loop_iter_v              ( mws_wr_dst_cfg_loop_iter_v ),
      .cfg_loop_iter                ( cfg_loop_iter              ),
      .cfg_loop_iter_loop_id        ( cfg_loop_id                ),   
      .cfg_loop_group_id            ( group_id                   ),
      
      .loop_group_id                ( group_id                   ),
      .iter_done                    ( mws_wr_dst_iter_done       ),
      .current_iters                (                            )
    );
//==============================================================================

//==============================================================================    
// SRC to DST data mapping and bank handeling logic
//==============================================================================
    // Wires and Reg
    wire                                                        buf_src_rd_req_en;
//    reg                                                         _rd_src_addr_v;
    wire    [ NUM_SIMD_LANES                    -1:0]           buf_src_rd_req;
    wire    [ NUM_SIMD_LANES*VMEM_BUF_ADDR_W    -1:0]           buf_src_rd_addr;
    wire    [ NUM_SIMD_LANES*SIMD_DATA_WIDTH    -1:0]           buf_src_rd_data;
    wire    [ SIMD_DATA_WIDTH    -1:0]           				buf_src_rd_data_w[0:NUM_SIMD_LANES-1];
    reg     [ NUM_SIMD_LANES*SIMD_DATA_WIDTH    -1:0]           _buf_src_rd_data;
    
    wire    [ NUM_SIMD_LANES*SIMD_DATA_WIDTH    -1:0]           buf_dst_data_shuffled;
    wire    [ NUM_SIMD_LANES*SIMD_DATA_WIDTH    -1:0]           buf_dst_data_non_shuffled;
    
    wire                                                        buf_dst_wr_req_en;
    wire    [ NUM_SIMD_LANES                    -1:0]           buf_dst_wr_req;
    wire    [ NUM_SIMD_LANES*VMEM_BUF_ADDR_W    -1:0]           buf_dst_wr_addr;
    wire    [ NUM_SIMD_LANES*SIMD_DATA_WIDTH    -1:0]           buf_dst_wr_data;
    
// VMEM1
    reg  [NUM_SIMD_LANES        -1:0]               _vmem1_write_req;
    reg  [NUM_SIMD_LANES*VMEM_TAG_BUF_ADDR_W-1:0]   _vmem1_write_addr;
    reg  [NUM_SIMD_LANES*SIMD_DATA_WIDTH -1:0]      _vmem1_write_data;
    reg  [NUM_SIMD_LANES        -1:0]               _vmem1_read_req;
    reg  [NUM_SIMD_LANES*VMEM_TAG_BUF_ADDR_W-1:0]   _vmem1_read_addr;
// VMEM2
    reg  [NUM_SIMD_LANES        -1:0]               _vmem2_write_req;
    reg  [NUM_SIMD_LANES*VMEM_TAG_BUF_ADDR_W-1:0]   _vmem2_write_addr;
    reg  [NUM_SIMD_LANES*SIMD_DATA_WIDTH -1:0]      _vmem2_write_data;
    reg  [NUM_SIMD_LANES        -1:0]               _vmem2_read_req;
    reg  [NUM_SIMD_LANES*VMEM_TAG_BUF_ADDR_W-1:0]   _vmem2_read_addr;

    // counter
    reg  [BANK_COUNTER_W        -1:0]               bank_counter_q [NUM_SIMD_LANES -1:0];
    wire [NUM_SIMD_LANES        -1:0]               bank_counter_en;
    wire                                            bank_counter_trigger;
//    

   
    // Generating the rd_req and rd_addr signals
//    always @(posedge clk) begin
//       if (reset || block_done)
//           _rd_src_addr_v <= 1'b0;
//       else 
//           _rd_src_addr_v <= mws_rd_src_addr_v;        
//    end
//    
    assign buf_src_rd_req_en = mws_rd_src_addr_v; //&& ~_rd_src_addr_v;
    assign buf_src_rd_req[0] = buf_src_rd_req_en;
    assign buf_src_rd_addr[VMEM_BUF_ADDR_W-1:0] = mws_rd_src_addr;
    
    genvar n;
    generate
        for (n=1; n<NUM_SIMD_LANES; n=n+1) begin
           register_sync #(1) rd_src_req_delay_bank (clk, reset, buf_src_rd_req[n-1], buf_src_rd_req[n]); 
           register_sync #(VMEM_BUF_ADDR_W) rd_src_addr_delay_bank (clk, reset, buf_src_rd_addr[n*VMEM_BUF_ADDR_W-1:(n-1)*VMEM_BUF_ADDR_W], buf_src_rd_addr[(n+1)*VMEM_BUF_ADDR_W-1:(n)*VMEM_BUF_ADDR_W]); 
        end     
    endgenerate
    
    // muxing the rd_req/addr to the right VMEM and muxing the rd data from right VMEM
    always @(*) begin
       if (src_ns_id_q == VMEM1_MEM_ID) begin
          _vmem1_read_req = buf_src_rd_req;
          _vmem1_read_addr = buf_src_rd_addr;
          _vmem2_read_req = {NUM_SIMD_LANES{1'b0}};
       end
       else if (src_ns_id_q == VMEM2_MEM_ID) begin
          _vmem2_read_req = buf_src_rd_req;
          _vmem2_read_addr = buf_src_rd_addr;
          _vmem1_read_req = {NUM_SIMD_LANES{1'b0}};         
       end
    end
   
    // setting the read_req/addr ports
    assign vmem1_read_req = _vmem1_read_req;
    assign vmem1_read_addr = _vmem1_read_addr;
    assign vmem2_read_req = _vmem2_read_req;
    assign vmem2_read_addr = _vmem2_read_addr;
    
    // muxing the buf_src_rd_data from vmem1 and vmem2
    always @(*) begin
       if (src_ns_id_q == VMEM1_MEM_ID) 
          _buf_src_rd_data = vmem1_read_data;
       else if (src_ns_id_q == VMEM2_MEM_ID)
          _buf_src_rd_data = vmem2_read_data;
    end
    
    assign buf_src_rd_data = _buf_src_rd_data;
    
    // counter logic to handle banks shuffling
    register_sync #(1) bank_counter_trigger_delay (clk, reset, buf_src_rd_req_en, bank_counter_trigger);
    assign  bank_counter_en[0] = bank_counter_trigger;
    
    generate
        for (n=1; n<NUM_SIMD_LANES; n=n+1) begin
            register_sync #(1) bank_counter_en_delay (clk, reset, bank_counter_en[n-1], bank_counter_en[n]); 
        end
    endgenerate
    
    generate
        for (n=0; n<NUM_SIMD_LANES; n=n+1) begin
           
           always @(posedge clk) begin
              if (reset)
                 bank_counter_q[n] <= 0;
              else if (bank_counter_en[n]) begin
                 if (bank_counter_q[n] == NUM_SIMD_LANES - 1'b1)
                     bank_counter_q[n] <= 0;
                 else
                     bank_counter_q[n] <= bank_counter_q[n] + 1'b1;
              end 
           end
        end  
    endgenerate
    
    // generating the dst_wr_req/addr signals, needed for muxing the shuffled data
    assign buf_dst_wr_req_en = mws_wr_dst_addr_v;
    assign buf_dst_wr_req[0] = buf_dst_wr_req_en;
    assign buf_dst_wr_addr[VMEM_BUF_ADDR_W-1:0] = mws_wr_dst_addr;
    generate
        for (n=1; n<NUM_SIMD_LANES; n=n+1) begin
           register_sync #(1) wr_dst_req_delay_bank (clk, reset, buf_dst_wr_req[n-1], buf_dst_wr_req[n]); 
           register_sync #(VMEM_BUF_ADDR_W) wr_dst_addr_delay_bank (clk, reset, buf_dst_wr_addr[n*VMEM_BUF_ADDR_W-1:(n-1)*VMEM_BUF_ADDR_W], buf_dst_wr_addr[(n+1)*VMEM_BUF_ADDR_W-1:(n)*VMEM_BUF_ADDR_W]); 
        end           
    endgenerate

    // muxing the wr_req/addr to the right VMEM 
    always @(*) begin
       if (dst_ns_id_q == VMEM1_MEM_ID) begin
          _vmem1_write_req = buf_dst_wr_req;
          _vmem1_write_addr = buf_dst_wr_addr;
          _vmem2_write_req = {NUM_SIMD_LANES{1'b0}};
       end
       else if (dst_ns_id_q == VMEM2_MEM_ID) begin
          _vmem2_write_req = buf_dst_wr_req;
          _vmem2_write_addr = buf_dst_wr_addr;
          _vmem1_write_req = {NUM_SIMD_LANES{1'b0}};         
       end
    end
   
    // setting the read_req/addr ports
    assign vmem1_write_req = _vmem1_write_req;
    assign vmem1_write_addr = _vmem1_write_addr;
    assign vmem2_write_req = _vmem2_write_req;
    assign vmem2_write_addr = _vmem2_write_addr;
    
    // mapping the src data to dst banks based on the counter (bank shuffling case), this signal needs to be muxed later with the 1-1 mapping
    generate
        for (n=0; n<NUM_SIMD_LANES; n=n+1) begin
			assign buf_src_rd_data_w[n] = buf_src_rd_data[(n+1)*SIMD_DATA_WIDTH-1: n*SIMD_DATA_WIDTH];
            assign buf_dst_data_shuffled[(n+1)*SIMD_DATA_WIDTH-1:n*SIMD_DATA_WIDTH] = buf_src_rd_data_w[bank_counter_q[n]];
        end
    endgenerate
    
    // 1-1 mapping for the case that we do not shuffle data across banks
    assign buf_dst_data_non_shuffled = buf_src_rd_data;
    
    assign buf_dst_wr_data = shuffling_mode_q ? buf_dst_data_shuffled : buf_dst_data_non_shuffled;
    
    always @(*) begin
       if (dst_ns_id_q == VMEM1_MEM_ID) 
           _vmem1_write_data = buf_dst_wr_data;
       else if (dst_ns_id_q == VMEM2_MEM_ID)
           _vmem2_write_data = buf_dst_wr_data;
    end
    
    assign vmem1_write_data = _vmem1_write_data;
    assign vmem2_write_data = _vmem2_write_data;



endmodule