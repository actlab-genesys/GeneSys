module simd_ld_st_interface_flexible #(

parameter   VMEM1_MEM_ID                        = 0,
parameter   VMEM2_MEM_ID                        = 1,

//LD/ST
parameter   MEM_REQ_W                           = 16,
parameter   LOOP_ITER_W                         = 16,
parameter   IMM_WIDTH                           = 16,
parameter   ADDR_STRIDE_W                       = 16, 
parameter   SIMD_LOOP_ID_W                      = 5,
parameter   NUM_TAGS                            = 1,
parameter   TAG_W                               = $clog2(NUM_TAGS),
parameter   SIMD_DATA_WIDTH                     = 32,
parameter   LD_ST_HIGH_DATA_WIDTH               = SIMD_DATA_WIDTH,
parameter   LD_ST_LOW_DATA_WIDTH                = 8,

// AXI
parameter   AXI_ADDR_WIDTH                      = 64,
parameter   AXI_DATA_WIDTH                      = 512,
parameter   C_XFER_SIZE_WIDTH                   = 32,
parameter   C_ADDER_BIT_WIDTH                   = 32,
parameter   WSTRB_W                             = AXI_DATA_WIDTH/8,
parameter   AXI_BURST_WIDTH                     = 8,

parameter integer  AXI_DATA_WIDTH_BYTES         = AXI_DATA_WIDTH/8,
parameter integer  AXI_DATA_WIDTH_LOG_BYTES     = $clog2(AXI_DATA_WIDTH/8),

parameter   NUM_SIMD_LANES                      = 4,
parameter   VMEM_BUF_ADDR_W                     = 16,
parameter   VMEM_TAG_BUF_ADDR_W                 = VMEM_BUF_ADDR_W + TAG_W,

parameter   GROUP_ID_W                          = 4,
parameter   MAX_NUM_GROUPS                      = (1<<GROUP_ID_W),
parameter   NS_ID_BITS                          = 3,
parameter   NS_INDEX_ID_BITS                    = 5,
parameter   OPCODE_BITS                         = 4,
parameter   FUNCTION_BITS                       = 4,
parameter   INSTRUCTION_WIDTH                   = OPCODE_BITS + FUNCTION_BITS + 3*(NS_ID_BITS + NS_INDEX_ID_BITS),

parameter   LD_ST_DATA_WIDTH                    = NS_INDEX_ID_BITS + 1,
parameter   LOOP_ID_W                           = 5,
parameter   NUM_MAX_LOOPS                = (1 << LOOP_ID_W),
parameter   BASE_ADDR_SEGMENT_W                 = 16,
parameter   ADDR_WIDTH                          = 32,

parameter   SIMD_LD_ST_HIGH_BW_GROUP_SIZE       = AXI_DATA_WIDTH / LD_ST_HIGH_DATA_WIDTH,
parameter   SIMD_LD_ST_HIGH_BW_NUM_GROUPS       = NUM_SIMD_LANES / SIMD_LD_ST_HIGH_BW_GROUP_SIZE,
parameter   SIMD_LD_ST_LOW_BW_GROUP_SIZE        = AXI_DATA_WIDTH / LD_ST_LOW_DATA_WIDTH,
parameter   SIMD_LD_ST_LOW_BW_NUM_GROUPS        = NUM_SIMD_LANES / SIMD_LD_ST_LOW_BW_GROUP_SIZE,

parameter integer FIFO_READ_LATENCY = 1,
parameter integer LD_FIFO_WRITE_DEPTH = 32,
parameter integer LD_PROG_EMPTY_THRESH = 3,
parameter integer LD_PROG_FULL_THRESH = 3,
parameter integer LD_READ_DATA_WIDTH = (NUM_SIMD_LANES * SIMD_DATA_WIDTH) > AXI_DATA_WIDTH ? AXI_DATA_WIDTH : (NUM_SIMD_LANES * SIMD_DATA_WIDTH), // DEBUG
parameter integer LD_WRITE_DATA_WIDTH = AXI_DATA_WIDTH,
parameter integer LD_FIFO_READ_DEPTH =  LD_FIFO_WRITE_DEPTH*LD_WRITE_DATA_WIDTH/LD_READ_DATA_WIDTH,
parameter integer LD_RD_DATA_COUNT_WIDTH = $clog2(LD_FIFO_READ_DEPTH)+1,
parameter integer LD_WR_DATA_COUNT_WIDTH = $clog2(LD_FIFO_WRITE_DEPTH)+1,

parameter integer ST_FIFO_WRITE_DEPTH = 64,
parameter integer ST_PROG_EMPTY_THRESH = 3,
parameter integer ST_PROG_FULL_THRESH = 60,
parameter integer ST_READ_DATA_WIDTH = NUM_SIMD_LANES * SIMD_DATA_WIDTH > AXI_DATA_WIDTH ? AXI_DATA_WIDTH : NUM_SIMD_LANES * SIMD_DATA_WIDTH, // DEBUG
parameter integer ST_WRITE_DATA_WIDTH = NUM_SIMD_LANES * SIMD_DATA_WIDTH > AXI_DATA_WIDTH ? AXI_DATA_WIDTH : NUM_SIMD_LANES * SIMD_DATA_WIDTH, // DEBUG
parameter integer ST_FIFO_READ_DEPTH =  ST_FIFO_WRITE_DEPTH*ST_WRITE_DATA_WIDTH/ST_READ_DATA_WIDTH,
parameter integer ST_RD_DATA_COUNT_WIDTH = $clog2(ST_FIFO_READ_DEPTH)+1,
parameter integer ST_WR_DATA_COUNT_WIDTH = $clog2(ST_FIFO_WRITE_DEPTH)+1,

parameter integer PC_DATA_WIDTH = 64
)(
input  wire                                         clk,
input  wire                                         reset,
input  wire                                         block_done,
// Extracted filed instruction
input  wire  [OPCODE_BITS           -1:0]           opcode,
input  wire  [FUNCTION_BITS         -1:0]           fn,
input  wire  [NS_ID_BITS            -1:0]           dest_ns_id,
input  wire  [NS_INDEX_ID_BITS      -1:0]           dest_ns_index_id,  
input  wire  [NS_ID_BITS            -1:0]           src1_ns_id,
input  wire  [NS_INDEX_ID_BITS      -1:0]           src1_ns_index_id,    
input  wire  [NS_ID_BITS            -1:0]           src2_ns_id,
input  wire  [NS_INDEX_ID_BITS      -1:0]           src2_ns_index_id,

//
input  wire  [MAX_NUM_GROUPS        -1:0]           ld_config_done,
input  wire  [MAX_NUM_GROUPS        -1:0]           st_config_done,
input  wire  [GROUP_ID_W            -1:0]           ld_st_group_id,

output wire                                         ld_mem_simd_done,
output wire                                         st_mem_simd_done,

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
input  wire  [NUM_SIMD_LANES*SIMD_DATA_WIDTH -1:0]      vmem2_read_data,

// Controller
output reg                                              mws_ld_base_vmem1_has_start,
output reg                                              mws_ld_base_vmem2_has_start,
output reg                                              mws_st_base_vmem1_has_start,
output reg                                              mws_st_base_vmem2_has_start,
output reg                                              simd_tiles_done,

// AXI
output wire  [ AXI_ADDR_WIDTH       -1 : 0 ]        mws_awaddr,
output wire  [ AXI_BURST_WIDTH      -1 : 0 ]        mws_awlen,
output wire  [ 2                    -1 : 0 ]        mws_awburst,
output wire                                         mws_awvalid,
input  wire                                         mws_awready,
// Master Interface Write Data
output wire  [ AXI_DATA_WIDTH       -1 : 0 ]        mws_wdata,
output wire  [ WSTRB_W              -1 : 0 ]        mws_wstrb,
output wire                                         mws_wlast,
output wire                                         mws_wvalid,
input  wire                                         mws_wready,
// Master Interface Write Response
input  wire                                         mws_bvalid,
output wire                                         mws_bready,
// Master Interface Read Address
output wire  [ AXI_ADDR_WIDTH       -1 : 0 ]        mws_araddr,
output wire  [ AXI_BURST_WIDTH      -1 : 0 ]        mws_arlen,
output wire                                         mws_arvalid,
input  wire                                         mws_arready,
// Master Interface Read Data
input  wire  [ AXI_DATA_WIDTH       -1 : 0 ]        mws_rdata,
input  wire                                         mws_rlast,
input  wire                                         mws_rvalid,
output wire                                         mws_rready,
input wire   [ AXI_ADDR_WIDTH   -1 : 0 ]            simd_base_offset,
// Perf Counter
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
output wire [PC_DATA_WIDTH - 1 : 0]                 pc_simd_st_size_per_requests
);

//==============================================================================
// Localparams
//==============================================================================
  localparam integer  LDMEM_IDLE                   = 0;
  localparam integer  LDMEM_GEN_BASE_ADDR          = 1;
  localparam integer  LDMEM_TILE_BUSY_NS_VMEM1     = 2;
  localparam integer  LDMEM_TILE_BUSY_NS_VMEM2     = 3;
  localparam integer  LDMEM_DONE                   = 4;

  localparam integer  STMEM_IDLE                   = 0;
  localparam integer  STMEM_GEN_BASE_ADDR          = 1;
  localparam integer  STMEM_TILE_BUSY_NS_VMEM1     = 2;
  localparam integer  STMEM_TILE_BUSY_NS_VMEM2     = 3;
  localparam integer  STMEM_DONE                   = 4;

  localparam integer  SPLIT_LD_REQ_IDLE            = 0;
  localparam integer  SPLIT_LD_REQ_A               = 1;
  localparam integer  SPLIT_LD_REQ_A_WAIT          = 2;
  localparam integer  SPLIT_LD_REQ_B               = 3;
  localparam integer  SPLIT_LD_REQ_B_WAIT          = 4;
  localparam integer  SPLIT_LD_DONE                = 5;

  localparam integer  SPLIT_ST_REQ_IDLE            = 0;
  localparam integer  SPLIT_ST_REQ                 = 1;
  localparam integer  SPLIT_ST_REQ_A               = 2;
  localparam integer  SPLIT_ST_REQ_A_WAIT          = 3;
  localparam integer  SPLIT_ST_REQ_B               = 4;
  localparam integer  SPLIT_ST_REQ_B_WAIT          = 5;
  localparam integer  SPLIT_ST_DONE                = 6;  

  localparam integer  MEM_LD                       = 0;
  localparam integer  MEM_ST                       = 1;
  
  localparam integer  NS_VMEM_1                    = 2;
  localparam integer  NS_VMEM_2                    = 3;
  
  localparam integer  LD_CONFIG_BASE_ADDR          = 0;
  localparam integer  LD_CONFIG_BASE_LOOP_ITER     = 1;
  localparam integer  LD_CONFIG_BASE_LOOP_STRIDE   = 2;
  localparam integer  LD_CONFIG_TILE_LOOP_ITER     = 3;
  localparam integer  LD_CONFIG_TILE_LOOP_STRIDE   = 4;
  localparam integer  LD_START                     = 5;

  localparam integer  ST_CONFIG_BASE_ADDR          = 8;
  localparam integer  ST_CONFIG_BASE_LOOP_ITER     = 9;
  localparam integer  ST_CONFIG_BASE_LOOP_STRIDE   = 10;
  localparam integer  ST_CONFIG_TILE_LOOP_ITER     = 11;
  localparam integer  ST_CONFIG_TILE_LOOP_STRIDE   = 12;
  localparam integer  ST_START                     = 13;
  
  // This is for the maximum range of the number of groups
  localparam integer  GROUP_COUNTER_LD_ST_WIDTH = $clog2(SIMD_LD_ST_HIGH_BW_NUM_GROUPS);
//==============================================================================
// WIRE & REG
//==============================================================================
  // Signals for Programming     
  wire                                         ld_cfg_base_addr_v;
  wire                                         ld_cfg_base_loop_iter_v;
  wire                                         ld_cfg_base_loop_stride_v;
  wire                                         ld_cfg_tile_loop_iter_v;
  wire                                         ld_cfg_tile_loop_stride_v;
  wire                                         ld_start;
                                    
  wire                                         st_cfg_base_addr_v;
  wire                                         st_cfg_base_loop_iter_v;
  wire                                         st_cfg_base_loop_stride_v;
  wire                                         st_cfg_tile_loop_iter_v;
  wire                                         st_cfg_tile_loop_stride_v;
  wire                                         st_start;  
  
  wire                                         cfg_base_addr_segment;
  wire                                         cfg_stride_segment;
  wire  [ 2                    -1: 0 ]         cfg_ns_id;
  wire  [ LOOP_ID_W            -1: 0 ]         cfg_loop_id;
  
  wire  [ BASE_ADDR_SEGMENT_W  -1: 0 ]         cfg_base_addr;
  wire  [ ADDR_STRIDE_W        -1: 0 ]         cfg_loop_stride;
  wire  [ LOOP_ITER_W          -1: 0 ]         cfg_loop_iter;
  wire  [ MEM_REQ_W            -1: 0 ]         cfg_mem_req_size;
  wire  [ LD_ST_DATA_WIDTH     -1: 0 ]         cfg_ld_st_data_width;
  
  wire  [ GROUP_ID_W           -1: 0 ]         cfg_group_id;
  
  wire                                         cfg_ns_ld_start_addr;
  wire                                         cfg_ns_wr_start_addr;    
  reg   [ BASE_ADDR_SEGMENT_W  -1: 0 ]         _on_chip_ld_start_addr_lsb;
  reg   [ BASE_ADDR_SEGMENT_W  -1: 0 ]         _on_chip_ld_start_addr_msb;                                 
  wire  [ ADDR_WIDTH  -1: 0 ]                  on_chip_ld_start_addr;

  reg   [ BASE_ADDR_SEGMENT_W  -1: 0 ]         _on_chip_st_start_addr_lsb;
  reg   [ BASE_ADDR_SEGMENT_W  -1: 0 ]         _on_chip_st_start_addr_msb;
  wire  [ ADDR_WIDTH  -1: 0 ]                  on_chip_st_start_addr;

  // FSM
  reg   [ 4                     -1: 0 ]        ldmem_state_d;
  reg   [ 4                     -1: 0 ]        ldmem_state_q;
  reg   [ 4                     -1: 0 ]        stmem_state_d;
  reg   [ 4                     -1: 0 ]        stmem_state_q;
  
  // Memory Request
  wire                                         ld_req_valid_d;
  reg                                          ld_req_valid_q;
  reg   [ MEM_REQ_W             -1: 0 ]        ld_req_size;
  reg   [ AXI_ADDR_WIDTH        -1: 0 ]        ld_req_addr;
  wire                                         st_req_valid_d;
  reg                                          st_req_valid_q;
  reg   [ MEM_REQ_W             -1: 0 ]        st_req_size;
  reg   [ AXI_ADDR_WIDTH        -1: 0 ]        st_req_addr;
  reg   [ LD_ST_DATA_WIDTH      -1: 0 ]        ld_data_width;
  reg   [ LD_ST_DATA_WIDTH      -1: 0 ]        st_data_width;    
  
  //MWS
  wire  [ NUM_MAX_LOOPS			 : 0 ]             mws_ld_base_vmem1_iter_done;
  wire                                         mws_ld_base_vmem1_start; 
  wire                                         mws_ld_base_vmem1_stall;
  wire                                         mws_ld_base_vmem1_done; 
  reg   [ BASE_ADDR_SEGMENT_W  -1: 0 ]         _mws_ld_base_vmem1_lsb;
  reg   [ BASE_ADDR_SEGMENT_W  -1: 0 ]         _mws_ld_base_vmem1_msb;
  wire  [ AXI_ADDR_WIDTH           -1: 0 ]         mws_ld_cfg_base_addr_vmem1;
  
  wire  [ AXI_ADDR_WIDTH       -1: 0 ]         mws_ld_base_addr_vmem1;
  wire                                         mws_ld_cfg_base_addr_vmem1_v;
  wire                                         mws_ld_base_addr_out_vmem1_v;
  
  //MWS
  wire  [ NUM_MAX_LOOPS			 : 0 ]             mws_ld_base_vmem2_iter_done;
  wire                                         mws_ld_base_vmem2_start; 
  wire                                         mws_ld_base_vmem2_stall;
  wire                                         mws_ld_base_vmem2_done; 
  reg   [ BASE_ADDR_SEGMENT_W  -1: 0 ]         _mws_ld_base_vmem2_lsb;
  reg   [ BASE_ADDR_SEGMENT_W  -1: 0 ]         _mws_ld_base_vmem2_msb;
  wire  [ AXI_ADDR_WIDTH           -1: 0 ]     mws_ld_cfg_base_addr_vmem2;
  
  wire  [ AXI_ADDR_WIDTH           -1: 0 ]     mws_ld_base_addr_vmem2;
  wire                                         mws_ld_cfg_base_addr_vmem2_v;
  wire                                         mws_ld_base_addr_out_vmem2_v;
  
  //MWS
  wire  [ NUM_MAX_LOOPS			 : 0 ]             mws_st_base_vmem1_iter_done;
  wire                                         mws_st_base_vmem1_start; 
  wire                                         mws_st_base_vmem1_stall;
  wire                                         mws_st_base_vmem1_done; 
  reg   [ BASE_ADDR_SEGMENT_W  -1: 0 ]         _mws_st_base_vmem1_lsb;
  reg   [ BASE_ADDR_SEGMENT_W  -1: 0 ]         _mws_st_base_vmem1_msb;
  wire  [ AXI_ADDR_WIDTH           -1: 0 ]     mws_st_cfg_base_addr_vmem1;
  wire                                         mws_st_cfg_base_addr_vmem1_v;
  
  wire  [ AXI_ADDR_WIDTH           -1: 0 ]     mws_st_base_addr_vmem1;
  wire                                         mws_st_base_addr_out_vmem1_v;
  
  //MWS
  wire  [ NUM_MAX_LOOPS			 : 0 ]             mws_st_base_vmem2_iter_done;
  wire                                         mws_st_base_vmem2_start; 
  wire                                         mws_st_base_vmem2_stall;
  wire                                         mws_st_base_vmem2_done; 
  reg   [ BASE_ADDR_SEGMENT_W  -1: 0 ]         _mws_st_base_vmem2_lsb;
  reg   [ BASE_ADDR_SEGMENT_W  -1: 0 ]         _mws_st_base_vmem2_msb;
  wire  [ AXI_ADDR_WIDTH           -1: 0 ]     mws_st_cfg_base_addr_vmem2;
  wire                                         mws_st_cfg_base_addr_vmem2_v;
  
  wire  [ AXI_ADDR_WIDTH       -1: 0 ]         mws_st_base_addr_vmem2;
  wire                                         mws_st_base_addr_out_vmem2_v;

  //MWS
  wire  [ NUM_MAX_LOOPS			 : 0 ]             mws_ld_tile_vmem1_iter_done;
  wire                                         mws_ld_tile_vmem1_start; 
  wire                                         mws_ld_tile_vmem1_stall;
  wire                                         mws_ld_tile_vmem1_done; 
  reg   [ AXI_ADDR_WIDTH           -1: 0 ]     _mws_ld_tile_base_addr_vmem1;
  wire  [ AXI_ADDR_WIDTH           -1: 0 ]     mws_ld_tile_base_addr_vmem1;
  wire                                         mws_ld_tile_base_addr_vmem1_v;
  
  wire  [ AXI_ADDR_WIDTH       -1: 0 ]         mws_ld_tile_addr_vmem1;
  wire                                         mws_ld_tile_addr_out_vmem1_v;
  
  //MWS
  wire  [ NUM_MAX_LOOPS			 : 0 ]             mws_ld_tile_vmem2_iter_done;
  wire                                         mws_ld_tile_vmem2_start; 
  wire                                         mws_ld_tile_vmem2_stall;
  wire                                         mws_ld_tile_vmem2_done; 
  reg   [ AXI_ADDR_WIDTH           -1: 0 ]     _mws_ld_tile_base_addr_vmem2;
  wire  [ AXI_ADDR_WIDTH           -1: 0 ]     mws_ld_tile_base_addr_vmem2;
  wire                                         mws_ld_tile_base_addr_vmem2_v;
  
  wire  [ AXI_ADDR_WIDTH           -1: 0 ]     mws_ld_tile_addr_vmem2;
  wire                                         mws_ld_tile_addr_out_vmem2_v;
  
  //MWS
  wire  [ NUM_MAX_LOOPS			 : 0 ]             mws_st_tile_vmem1_iter_done;
  wire                                         mws_st_tile_vmem1_start; 
  wire                                         mws_st_tile_vmem1_stall;
  wire                                         mws_st_tile_vmem1_done; 
  reg   [ AXI_ADDR_WIDTH           -1: 0 ]     _mws_st_tile_base_addr_vmem1;
  wire  [ AXI_ADDR_WIDTH           -1: 0 ]     mws_st_tile_base_addr_vmem1;
  wire                                         mws_st_tile_base_addr_vmem1_v;

  
  wire  [ AXI_ADDR_WIDTH       -1: 0 ]         mws_st_tile_addr_vmem1;
  wire                                         mws_st_tile_addr_out_vmem1_v;
  
  //MWS
  wire  [ NUM_MAX_LOOPS			 : 0 ]             mws_st_tile_vmem2_iter_done;
  wire                                         mws_st_tile_vmem2_start; 
  wire                                         mws_st_tile_vmem2_stall;
  wire                                         mws_st_tile_vmem2_done; 
  reg   [ AXI_ADDR_WIDTH          -1: 0 ]      _mws_st_tile_base_addr_vmem2;
  wire  [ AXI_ADDR_WIDTH          -1: 0 ]      mws_st_tile_base_addr_vmem2;
  wire                                         mws_st_tile_base_addr_vmem2_v;
  
  wire  [ AXI_ADDR_WIDTH           -1: 0 ]     mws_st_tile_addr_vmem2;
  wire                                         mws_st_tile_addr_out_vmem2_v;    

// AXI Interface   
  wire                                         axi_rd_req;
  wire                                         axi_rd_done;
  reg                                          axi_rd_done_d;
  wire [ MEM_REQ_W*2          -1 : 0 ]         axi_rd_req_size;
  wire [ (MEM_REQ_W*2)        -1 : 0 ]         rd_req_size_coefficient, wr_req_size_coefficient;
  wire                                         axi_rd_ready;
  wire [ AXI_ADDR_WIDTH       -1 : 0 ]         axi_rd_addr;

  wire                                         axi_wr_req;
  wire                                         axi_wr_done;
  reg                                          axi_wr_done_d;
  wire [ MEM_REQ_W*2            -1 : 0 ]       axi_wr_req_size;
  wire                                         axi_wr_ready;
  wire [ AXI_ADDR_WIDTH       -1 : 0 ]         axi_wr_addr;


  wire                                        mem_write_req;
  wire                                        mem_write_req_fifo;
  wire [ AXI_DATA_WIDTH-1:0 ]                 mem_write_data;
  wire [ AXI_DATA_WIDTH       -1 : 0 ]        mem_write_data_fifo;
  wire                                        axi_wr_data_v; 
  wire                                        mem_write_ready;
  
  wire [ AXI_DATA_WIDTH       -1 : 0 ]        mem_read_data;
  wire                                        axi_mem_read_req;
  wire                                        axi_mem_read_ready;                             

  wire                                        curr_group_ld_config_done;
  wire                                        curr_group_st_config_done;
  wire                                        _curr_group_ld_config_done;
  wire                                        _curr_group_st_config_done;   
//==============================================================================
  
//==============================================================================
// ASSIGNS CONFIG SIGNALS
//==============================================================================

  assign  _curr_group_ld_config_done =  ld_config_done[cfg_group_id] ;
  assign  _curr_group_st_config_done =  st_config_done[cfg_group_id];

  assign curr_group_ld_config_done = _curr_group_ld_config_done;
  assign curr_group_st_config_done = _curr_group_st_config_done;

  assign ld_cfg_base_addr_v = (opcode == 4'b0101) && (fn == LD_CONFIG_BASE_ADDR)  && (~curr_group_ld_config_done);
  assign ld_cfg_base_loop_iter_v = (opcode == 4'b0101) && (fn == LD_CONFIG_BASE_LOOP_ITER) && (~curr_group_ld_config_done);
  assign ld_cfg_base_loop_stride_v = (opcode == 4'b0101) && (fn == LD_CONFIG_BASE_LOOP_STRIDE) && (~curr_group_ld_config_done);
    
  assign ld_cfg_tile_loop_iter_v = (opcode == 4'b0101) && (fn == LD_CONFIG_TILE_LOOP_ITER) && (~curr_group_ld_config_done);
  assign ld_cfg_tile_loop_stride_v = (opcode == 4'b0101) && (fn == LD_CONFIG_TILE_LOOP_STRIDE) && (~curr_group_ld_config_done); 
  
  assign ld_start = (opcode == 4'b0101) && (fn == LD_START);
  
  assign st_cfg_base_addr_v = (opcode == 4'b0101) && (fn == ST_CONFIG_BASE_ADDR)  && (~curr_group_st_config_done); 
  assign st_cfg_base_loop_iter_v = (opcode == 4'b0101) && (fn == ST_CONFIG_BASE_LOOP_ITER) && (~curr_group_st_config_done);
  assign st_cfg_base_loop_stride_v = (opcode == 4'b0101) && (fn == ST_CONFIG_BASE_LOOP_STRIDE)  && (~curr_group_st_config_done); 
  
  assign st_cfg_tile_loop_iter_v = (opcode == 4'b0101) && (fn == ST_CONFIG_TILE_LOOP_ITER) && (~curr_group_st_config_done);
  assign st_cfg_tile_loop_stride_v = (opcode == 4'b0101) && (fn == ST_CONFIG_TILE_LOOP_STRIDE)  && (~curr_group_st_config_done); 
  
  assign st_start = fn == ST_START;    

  assign cfg_group_id = ld_st_group_id;
  
  assign cfg_base_addr_segment = dest_ns_id[2];
  assign cfg_ns_id = dest_ns_id[1:0];
  assign cfg_loop_id = dest_ns_index_id;
  assign cfg_stride_segment = dest_ns_id[2];
  assign cfg_base_addr = {src1_ns_id, src1_ns_index_id, src2_ns_id, src2_ns_index_id};
  assign cfg_loop_stride = {src1_ns_id, src1_ns_index_id, src2_ns_id, src2_ns_index_id};
  assign cfg_loop_iter = {src1_ns_id, src1_ns_index_id, src2_ns_id, src2_ns_index_id};
  assign cfg_mem_req_size = {src1_ns_id, src1_ns_index_id, src2_ns_id, src2_ns_index_id};
  assign cfg_ld_st_data_width = {1'b0, dest_ns_index_id} + 1;

  assign cfg_ns_ld_start_addr = (opcode == 4'b0101) && (fn == 4'b0110);
  assign cfg_ns_st_start_addr = (opcode == 4'b0101) && (fn == 4'b1110);

  always @(posedge clk) begin
      if (reset) begin
          _on_chip_ld_start_addr_lsb <= 0;
          _on_chip_ld_start_addr_msb <= 0;
      end else if (cfg_ns_ld_start_addr && cfg_base_addr_segment == 0)
          _on_chip_ld_start_addr_lsb <= cfg_base_addr;
      else if (cfg_ns_ld_start_addr && cfg_base_addr_segment == 1)
          _on_chip_ld_start_addr_msb <= cfg_base_addr;
  end

  assign on_chip_ld_start_addr[BASE_ADDR_SEGMENT_W-1:0] = _on_chip_ld_start_addr_lsb;
  assign on_chip_ld_start_addr[2*BASE_ADDR_SEGMENT_W-1:BASE_ADDR_SEGMENT_W] = _on_chip_ld_start_addr_msb;

  always @(posedge clk) begin
      if (reset) begin
          _on_chip_st_start_addr_lsb <= 0;
          _on_chip_st_start_addr_msb <= 0;
      end else if (cfg_ns_st_start_addr && cfg_base_addr_segment == 0)
          _on_chip_st_start_addr_lsb <= cfg_base_addr;
      else if (cfg_ns_st_start_addr && cfg_base_addr_segment == 1)
          _on_chip_st_start_addr_msb <= cfg_base_addr;
  end

  assign on_chip_st_start_addr[BASE_ADDR_SEGMENT_W-1:0] = _on_chip_st_start_addr_lsb;
  assign on_chip_st_start_addr[2*BASE_ADDR_SEGMENT_W-1:BASE_ADDR_SEGMENT_W] = _on_chip_st_start_addr_msb;
//==============================================================================
  // Change for fusion, keep in case of undetected bug
  // always @(*) begin
  //   if (_ldmem_ns_id == NS_VMEM_1) 
  //     simd_tiles_done = mws_ld_base_vmem1_done;
  //   else if (_ldmem_ns_id == NS_VMEM_2)
  //     simd_tiles_done = mws_ld_base_vmem2_done;
  // end

  always @(*) begin
    if (_stmem_ns_id == NS_VMEM_1) 
      simd_tiles_done = mws_st_base_vmem1_done;
    else if (_stmem_ns_id == NS_VMEM_2)
      simd_tiles_done = mws_st_base_vmem2_done;
  end

  //assign simd_tiles_done = mws_ld_base_vmem1_done || mws_ld_base_vmem2_done;
  assign ld_mem_simd_done = ld_from_axi_done; // DEBUG (mws_ld_tile_vmem1_done || mws_ld_tile_vmem2_done);
  assign st_mem_simd_done = st_to_axi_done; // DEBUG mws_st_tile_vmem1_done || mws_st_tile_vmem2_done;

//==============================================================================    
// mem_walker_stride and controller_fsm for BASE_ADDR/LD/VMEM1    
//==============================================================================
  always @(posedge clk) begin
      if (reset) begin
          _mws_ld_base_vmem1_lsb <= 0;
          _mws_ld_base_vmem1_msb <= 0;
      end else if (ld_cfg_base_addr_v && cfg_base_addr_segment == 0 && cfg_ns_id == NS_VMEM_1)
          _mws_ld_base_vmem1_lsb <= cfg_base_addr;
      else if (ld_cfg_base_addr_v && cfg_base_addr_segment == 1 && cfg_ns_id == NS_VMEM_1)
          _mws_ld_base_vmem1_msb <= cfg_base_addr;
  end
  assign mws_ld_cfg_base_addr_vmem1[BASE_ADDR_SEGMENT_W-1:0] = _mws_ld_base_vmem1_lsb;
  assign mws_ld_cfg_base_addr_vmem1[2*BASE_ADDR_SEGMENT_W-1:BASE_ADDR_SEGMENT_W] = _mws_ld_base_vmem1_msb;
  assign mws_ld_cfg_base_addr_vmem1[4*BASE_ADDR_SEGMENT_W-1:2*BASE_ADDR_SEGMENT_W] = 'b0;

  register_sync #(1) mws_ld_cfg_base_vmem1_delay (clk, reset, ((~mws_ld_base_vmem1_has_start) && ld_cfg_base_addr_v && cfg_base_addr_segment == 1 && cfg_ns_id == NS_VMEM_1), mws_ld_cfg_base_addr_vmem1_v);

  wire                              ld_cfg_stride_base_addr_vmem1_v;
  wire                              ld_cfg_base_loop_iter_vmem1_v;

  wire [ 2*ADDR_STRIDE_W          -1: 0 ]              mws_ld_cfg_stride_base_addr_vmem1;
  reg  [ ADDR_STRIDE_W            -1: 0 ]              _mws_ld_cfg_stride_vmem1_lsb;
  reg  [ ADDR_STRIDE_W            -1: 0 ]              _mws_ld_cfg_stride_vmem1_msb;
  
  always @(posedge clk) begin
      if (reset) begin
          _mws_ld_cfg_stride_vmem1_lsb <= 0;
          _mws_ld_cfg_stride_vmem1_msb <= 0;
      end
      else if (ld_cfg_base_loop_stride_v && cfg_ns_id == NS_VMEM_1 && cfg_stride_segment == 0 )
          _mws_ld_cfg_stride_vmem1_lsb <= cfg_loop_stride;
      else if (ld_cfg_base_loop_stride_v && cfg_ns_id == NS_VMEM_1 && cfg_stride_segment == 1 )
          _mws_ld_cfg_stride_vmem1_msb <= cfg_loop_stride;
  end    
  assign mws_ld_cfg_stride_base_addr_vmem1[ADDR_STRIDE_W-1:0] = _mws_ld_cfg_stride_vmem1_lsb;
  assign mws_ld_cfg_stride_base_addr_vmem1[2*ADDR_STRIDE_W-1:ADDR_STRIDE_W] = _mws_ld_cfg_stride_vmem1_msb;
  
  register_sync #(1) mws_ld_cfg_stride_base_vmem1_delay (clk, reset, ((~mws_ld_base_vmem1_has_start) && ld_cfg_base_loop_stride_v && cfg_ns_id == NS_VMEM_1 && cfg_stride_segment == 1 ), ld_cfg_stride_base_addr_vmem1_v);
  
  mem_walker_stride_group_simd #(
    .ADDR_WIDTH                   ( AXI_ADDR_WIDTH ),
    .ADDR_STRIDE_W                ( 2*ADDR_STRIDE_W ),
    .LOOP_ID_W                    ( LOOP_ID_W ),
    .GROUP_ID_W                   ( GROUP_ID_W )  
  ) mws_base_ld_vmem1 (
    .clk                          ( clk ),
    .reset                        ( reset ),
    .isBase                       (1'b1),

    .base_addr                    ( mws_ld_cfg_base_addr_vmem1 ),
    .iter_done                    ( mws_ld_base_vmem1_iter_done ),
    .start                        ( mws_ld_base_vmem1_start ),
    .stall                        ( mws_ld_base_vmem1_stall ),
    .block_done                   ( block_done              ),
    .base_addr_v                  ( mws_ld_cfg_base_addr_vmem1_v ),
    
    .cfg_loop_id                  ( cfg_loop_id ),
    .cfg_addr_stride_v            ( ld_cfg_stride_base_addr_vmem1_v ),
    .cfg_addr_stride              ( mws_ld_cfg_stride_base_addr_vmem1 ),
    
    .cfg_loop_group_id            ( cfg_group_id ),
    .loop_group_id                ( ld_st_group_id ),
    
    .addr_out                     ( mws_ld_base_addr_vmem1 ),
    .addr_out_valid               ( mws_ld_base_addr_out_vmem1_v )
  );

  assign ld_cfg_base_loop_iter_vmem1_v = ld_cfg_base_loop_iter_v && cfg_ns_id == NS_VMEM_1;

  controller_fsm_group_simd #(
    .LOOP_ID_W                    ( LOOP_ID_W ),
    .GROUP_ID_W                   ( GROUP_ID_W ),
    .LOOP_ITER_W                  ( LOOP_ITER_W )
  ) controller_fsm_base_ld_vmem1  (
    .clk                          ( clk ),
    .reset                        ( reset ),
    .isBase                       (1'b1),

    .start                        ( mws_ld_base_vmem1_start_d ),
    .has_start                    ( mws_ld_base_vmem1_has_start),
    .block_done                   ( block_done              ),
    .done                         ( mws_ld_base_vmem1_done ),
    .stall                        ( mws_ld_base_vmem1_stall ),
    
    .cfg_loop_iter_v              ( ld_cfg_base_loop_iter_vmem1_v ),
    .cfg_loop_iter                ( cfg_loop_iter ),
    .cfg_loop_iter_loop_id        ( cfg_loop_id ),   
    .cfg_loop_group_id            ( cfg_group_id ),
    
    .loop_group_id                ( ld_st_group_id ),
    .iter_done                    ( mws_ld_base_vmem1_iter_done ),
    .current_iters                (                            )
  );


//==============================================================================    
// mem_walker_stride and controller_fsm for BASE_ADDR/LD/VMEM2 
//==============================================================================
    always @(posedge clk) begin
        if (reset) begin
            _mws_ld_base_vmem2_lsb <= 0; //change from _mws_ld_tile_vmem2_lsb <= 0;
            _mws_ld_base_vmem2_msb <= 0;
        end
        else if (ld_cfg_base_addr_v && cfg_base_addr_segment == 0 && cfg_ns_id == NS_VMEM_2)
            _mws_ld_base_vmem2_lsb <= cfg_base_addr;
        else if (ld_cfg_base_addr_v && cfg_base_addr_segment == 1 && cfg_ns_id == NS_VMEM_2)
            _mws_ld_base_vmem2_msb <= cfg_base_addr;
    end
    
    assign mws_ld_cfg_base_addr_vmem2[BASE_ADDR_SEGMENT_W-1:0] = _mws_ld_base_vmem2_lsb;
    assign mws_ld_cfg_base_addr_vmem2[2*BASE_ADDR_SEGMENT_W-1:BASE_ADDR_SEGMENT_W] = _mws_ld_base_vmem2_msb;
    assign mws_ld_cfg_base_addr_vmem2[4*BASE_ADDR_SEGMENT_W-1:2*BASE_ADDR_SEGMENT_W] = 'b0;

    register_sync #(1) mws_ld_cfg_base_vmem2_delay (clk, reset, ((~mws_ld_base_vmem2_has_start) && ld_cfg_base_addr_v && cfg_base_addr_segment == 1 && cfg_ns_id == NS_VMEM_2), mws_ld_cfg_base_addr_vmem2_v);
    
    wire                              ld_cfg_stride_base_addr_vmem2_v;
    wire                              ld_cfg_base_loop_iter_vmem2_v;

 
    wire [ 2*ADDR_STRIDE_W          -1: 0 ]              mws_ld_cfg_stride_base_addr_vmem2;
    reg  [ ADDR_STRIDE_W            -1: 0 ]              _mws_ld_cfg_stride_vmem2_lsb;
    reg  [ ADDR_STRIDE_W            -1: 0 ]              _mws_ld_cfg_stride_vmem2_msb;
    
    always @(posedge clk) begin
        if (reset) begin
           _mws_ld_cfg_stride_vmem2_lsb <= 0;
           _mws_ld_cfg_stride_vmem2_msb <= 0;
        end
        else if (ld_cfg_base_loop_stride_v && cfg_ns_id == NS_VMEM_2 && cfg_stride_segment == 0 )
            _mws_ld_cfg_stride_vmem2_lsb <= cfg_loop_stride;
        else if (ld_cfg_base_loop_stride_v && cfg_ns_id == NS_VMEM_2 && cfg_stride_segment == 1 )
            _mws_ld_cfg_stride_vmem2_msb <= cfg_loop_stride;
    end    
    assign mws_ld_cfg_stride_base_addr_vmem2[ADDR_STRIDE_W-1:0] = _mws_ld_cfg_stride_vmem2_lsb;
    assign mws_ld_cfg_stride_base_addr_vmem2[2*ADDR_STRIDE_W-1:ADDR_STRIDE_W] = _mws_ld_cfg_stride_vmem2_msb;
    
    register_sync #(1) mws_ld_cfg_stride_base_vmem2_delay (clk, reset, ((~mws_ld_base_vmem2_has_start) && ld_cfg_base_loop_stride_v && cfg_ns_id == NS_VMEM_2 && cfg_stride_segment == 1 ), ld_cfg_stride_base_addr_vmem2_v);

    mem_walker_stride_group_simd #(
      .ADDR_WIDTH                   ( AXI_ADDR_WIDTH ),
      .ADDR_STRIDE_W                ( 2*ADDR_STRIDE_W ),
      .LOOP_ID_W                    ( LOOP_ID_W ),
      .GROUP_ID_W                   ( GROUP_ID_W )  
    ) mws_base_ld_vmem2 (
      .clk                          ( clk ),
      .reset                        ( reset ),
      .isBase                       (1'b1),

      .base_addr                    ( mws_ld_cfg_base_addr_vmem2  ),
      .iter_done                    ( mws_ld_base_vmem2_iter_done ),
      .start                        ( mws_ld_base_vmem2_start     ),
      .stall                        ( mws_ld_base_vmem2_stall     ),
      .block_done                   ( block_done                  ),
      .base_addr_v                  ( mws_ld_cfg_base_addr_vmem2_v),
      
      .cfg_loop_id                  ( cfg_loop_id ),
      .cfg_addr_stride_v            ( ld_cfg_stride_base_addr_vmem2_v   ),
      .cfg_addr_stride              ( mws_ld_cfg_stride_base_addr_vmem2 ),
      
      .cfg_loop_group_id            ( cfg_group_id    ),
      .loop_group_id                ( ld_st_group_id  ),
      
      .addr_out                     ( mws_ld_base_addr_vmem2 ),
      .addr_out_valid               ( mws_ld_base_addr_out_vmem2_v )
    );

    assign ld_cfg_base_loop_iter_vmem2_v = ld_cfg_base_loop_iter_v && cfg_ns_id == NS_VMEM_2;

    controller_fsm_group_simd #(
      .LOOP_ID_W                    ( LOOP_ID_W ),
      .GROUP_ID_W                   ( GROUP_ID_W ),
      .LOOP_ITER_W                  ( LOOP_ITER_W )
    ) controller_fsm_base_ld_vmem2  (
      .clk                          ( clk ),
      .reset                        ( reset ),
      .isBase                       (1'b1),

      .start                        ( mws_ld_base_vmem2_start_d ),
      .has_start                    ( mws_ld_base_vmem2_has_start),
      .block_done                   ( block_done              ),
      .done                         ( mws_ld_base_vmem2_done ),
      .stall                        ( mws_ld_base_vmem2_stall ),
      
      .cfg_loop_iter_v              ( ld_cfg_base_loop_iter_vmem2_v ),
      .cfg_loop_iter                ( cfg_loop_iter ),
      .cfg_loop_iter_loop_id        ( cfg_loop_id ),   
      .cfg_loop_group_id            ( cfg_group_id ),
      
      .loop_group_id                ( ld_st_group_id ),
      .iter_done                    ( mws_ld_base_vmem2_iter_done ),
      .current_iters                (                             )
    );

//==============================================================================    
// mem_walker_stride and controller_fsm for TILE/LD/VMEM1    
//==============================================================================
    always @(posedge clk) begin
       if (reset)
           _mws_ld_tile_base_addr_vmem1 <= 0;
       else if (mws_ld_base_addr_out_vmem1_v)
           _mws_ld_tile_base_addr_vmem1 <= mws_ld_base_addr_vmem1;
    end
    
    assign mws_ld_tile_base_addr_vmem1 = _mws_ld_tile_base_addr_vmem1;

    register_sync #(1) mws_ld_cfg_tile_vmem1_delay (clk, reset, mws_ld_base_addr_out_vmem1_v, mws_ld_tile_base_addr_vmem1_v);

    wire                              ld_cfg_stride_tile_addr_vmem1_v;
 
    wire [ 2*ADDR_STRIDE_W          -1: 0 ]              mws_ld_cfg_stride_tile_addr_vmem1;
    reg  [ ADDR_STRIDE_W            -1: 0 ]              _mws_ld_cfg_stride_tile_vmem1_lsb;
    reg  [ ADDR_STRIDE_W            -1: 0 ]              _mws_ld_cfg_stride_tile_vmem1_msb;
    
    always @(posedge clk) begin
        if (reset) begin
           _mws_ld_cfg_stride_tile_vmem1_lsb <= 0;
           _mws_ld_cfg_stride_tile_vmem1_msb <= 0;
        end
        else if (ld_cfg_tile_loop_stride_v && cfg_ns_id == NS_VMEM_1 && cfg_stride_segment == 0 )
            _mws_ld_cfg_stride_tile_vmem1_lsb <= cfg_loop_stride;
        else if (ld_cfg_tile_loop_stride_v && cfg_ns_id == NS_VMEM_1 && cfg_stride_segment == 1 )
            _mws_ld_cfg_stride_tile_vmem1_msb <= cfg_loop_stride;
    end    
    assign mws_ld_cfg_stride_tile_addr_vmem1[ADDR_STRIDE_W-1:0] = _mws_ld_cfg_stride_tile_vmem1_lsb;
    assign mws_ld_cfg_stride_tile_addr_vmem1[2*ADDR_STRIDE_W-1:ADDR_STRIDE_W] = _mws_ld_cfg_stride_tile_vmem1_msb;
    
    register_sync #(1) mws_ld_cfg_stride_tile_vmem1_delay (clk, reset, ((~mws_ld_base_vmem1_has_start) && ld_cfg_tile_loop_stride_v && cfg_ns_id == NS_VMEM_1 && cfg_stride_segment == 1 ), ld_cfg_stride_tile_addr_vmem1_v);
       
    
    wire   ld_cfg_tile_loop_iter_vmem1_v;
    assign ld_cfg_tile_loop_iter_vmem1_v = ld_cfg_tile_loop_iter_v && cfg_ns_id == NS_VMEM_1;
    
    mem_walker_stride_group_simd #(
      .ADDR_WIDTH                   ( AXI_ADDR_WIDTH ),
      .ADDR_STRIDE_W                ( 2*ADDR_STRIDE_W ),
      .LOOP_ID_W                    ( LOOP_ID_W ),
      .GROUP_ID_W                   ( GROUP_ID_W )  
    ) mws_tile_ld_vmem1 (
      .clk                          ( clk ),
      .reset                        ( reset ),
      .isBase                       (1'b0),

      .base_addr                    ( mws_ld_tile_base_addr_vmem1 ),
      .iter_done                    ( mws_ld_tile_vmem1_iter_done ),
      .start                        ( mws_ld_tile_vmem1_start ),
      .stall                        ( mws_ld_tile_vmem1_stall ),
      .block_done                   ( block_done              ),
      .base_addr_v                  ( mws_ld_tile_base_addr_vmem1_v ),
      
      .cfg_loop_id                  ( cfg_loop_id                   ),
      .cfg_addr_stride_v            ( ld_cfg_stride_tile_addr_vmem1_v ),
      .cfg_addr_stride              ( mws_ld_cfg_stride_tile_addr_vmem1 ),

      .cfg_loop_group_id            ( cfg_group_id ),
      .loop_group_id                ( ld_st_group_id ),
      
      .addr_out                     ( mws_ld_tile_addr_vmem1 ),
      .addr_out_valid               ( mws_ld_tile_addr_out_vmem1_v )
    );

    controller_fsm_group_simd #(
      .LOOP_ID_W                    ( LOOP_ID_W ),
      .GROUP_ID_W                   ( GROUP_ID_W ),
      .LOOP_ITER_W                  ( LOOP_ITER_W )
    ) controller_fsm_tile_ld_vmem1  (
      .clk                          ( clk ),
      .reset                        ( reset ),
      .isBase                       (1'b0),

      .start                        ( mws_ld_tile_vmem1_start ),
      .done                         ( mws_ld_tile_vmem1_done ),
      .stall                        ( mws_ld_tile_vmem1_stall ),
      .block_done                   ( block_done              ),
      
      .cfg_loop_iter_v              ( ld_cfg_tile_loop_iter_vmem1_v ),
      .cfg_loop_iter                ( cfg_loop_iter ),
      .cfg_loop_iter_loop_id        ( cfg_loop_id ),   
      .cfg_loop_group_id            ( cfg_group_id ),
      
      .loop_group_id                ( ld_st_group_id ),
      .iter_done                    ( mws_ld_tile_vmem1_iter_done ),
      .current_iters                (                           )
    );


//==============================================================================    
// mem_walker_stride and controller_fsm for TILE/LD/VMEM2    
//==============================================================================
    always @(posedge clk) begin
       if (reset)
           _mws_ld_tile_base_addr_vmem2 <= 0;
       else if (mws_ld_base_addr_out_vmem2_v)
           _mws_ld_tile_base_addr_vmem2 <= mws_ld_base_addr_vmem2;
    end
    
    assign mws_ld_tile_base_addr_vmem2 = _mws_ld_tile_base_addr_vmem2;

    register_sync #(1) mws_ld_cfg_tile_vmem2_delay (clk, reset, mws_ld_base_addr_out_vmem2_v, mws_ld_tile_base_addr_vmem2_v);
 
    wire                              ld_cfg_stride_tile_addr_vmem2_v;

    wire [ 2*ADDR_STRIDE_W          -1: 0 ]              mws_ld_cfg_stride_tile_addr_vmem2;
    reg  [ ADDR_STRIDE_W            -1: 0 ]              _mws_ld_cfg_stride_tile_vmem2_lsb;
    reg  [ ADDR_STRIDE_W            -1: 0 ]              _mws_ld_cfg_stride_tile_vmem2_msb;
    
    always @(posedge clk) begin
        if (reset) begin
           _mws_ld_cfg_stride_tile_vmem2_lsb <= 0;
           _mws_ld_cfg_stride_tile_vmem2_msb <= 0;
        end
        else if (ld_cfg_tile_loop_stride_v && cfg_ns_id == NS_VMEM_2 && cfg_stride_segment == 0 )
            _mws_ld_cfg_stride_tile_vmem2_lsb <= cfg_loop_stride;
        else if (ld_cfg_tile_loop_stride_v && cfg_ns_id == NS_VMEM_2 && cfg_stride_segment == 1 )
            _mws_ld_cfg_stride_tile_vmem2_msb <= cfg_loop_stride;
    end    
    assign mws_ld_cfg_stride_tile_addr_vmem2[ADDR_STRIDE_W-1:0] = _mws_ld_cfg_stride_tile_vmem2_lsb;
    assign mws_ld_cfg_stride_tile_addr_vmem2[2*ADDR_STRIDE_W-1:ADDR_STRIDE_W] = _mws_ld_cfg_stride_tile_vmem2_msb;
    
    register_sync #(1) mws_ld_cfg_stride_tile_vmem2_delay (clk, reset, (~mws_ld_base_vmem2_has_start && ld_cfg_tile_loop_stride_v && cfg_ns_id == NS_VMEM_2 && cfg_stride_segment == 1 ), ld_cfg_stride_tile_addr_vmem2_v);
       
    
    wire                              ld_cfg_tile_loop_iter_vmem2_v;
    assign ld_cfg_tile_loop_iter_vmem2_v = ld_cfg_tile_loop_iter_v && cfg_ns_id == NS_VMEM_2;
    
    mem_walker_stride_group_simd #(
      .ADDR_WIDTH                   ( AXI_ADDR_WIDTH ),
      .ADDR_STRIDE_W                ( 2*ADDR_STRIDE_W ),
      .LOOP_ID_W                    ( LOOP_ID_W ),
      .GROUP_ID_W                   ( GROUP_ID_W )  
    ) mws_tile_ld_vmem2 (
      .clk                          ( clk ),
      .reset                        ( reset ),
      .isBase                       (1'b0),

      .base_addr                    ( mws_ld_tile_base_addr_vmem2 ),
      .iter_done                    ( mws_ld_tile_vmem2_iter_done ),
      .start                        ( mws_ld_tile_vmem2_start ),
      .stall                        ( mws_ld_tile_vmem2_stall ),
      .block_done                   ( block_done              ),
      .base_addr_v                  ( mws_ld_tile_base_addr_vmem2_v ),
      
      .cfg_loop_id                  ( cfg_loop_id                   ),
      .cfg_addr_stride_v            ( ld_cfg_stride_tile_addr_vmem2_v ),
      .cfg_addr_stride              ( mws_ld_cfg_stride_tile_addr_vmem2 ),

      .cfg_loop_group_id            ( cfg_group_id ),
      .loop_group_id                ( ld_st_group_id ),
      
      .addr_out                     ( mws_ld_tile_addr_vmem2 ),
      .addr_out_valid               ( mws_ld_tile_addr_out_vmem2_v )
    );

    controller_fsm_group_simd #(
      .LOOP_ID_W                    ( LOOP_ID_W ),
      .GROUP_ID_W                   ( GROUP_ID_W ),
      .LOOP_ITER_W                  ( LOOP_ITER_W )
    ) controller_fsm_tile_ld_vmem2  (
      .clk                          ( clk ),
      .reset                        ( reset ),
      .isBase                       (1'b0),
      
      .start                        ( mws_ld_tile_vmem2_start ),
      .done                         ( mws_ld_tile_vmem2_done ),
      .stall                        ( mws_ld_tile_vmem2_stall ),
      .block_done                   ( block_done              ),
      
      .cfg_loop_iter_v              ( ld_cfg_tile_loop_iter_vmem2_v ),
      .cfg_loop_iter                ( cfg_loop_iter ),
      .cfg_loop_iter_loop_id        ( cfg_loop_id ),   
      .cfg_loop_group_id            ( cfg_group_id ),
      
      .loop_group_id                ( ld_st_group_id ),
      .iter_done                    ( mws_ld_tile_vmem2_iter_done ),
      .current_iters                (                           )
    );


//==============================================================================    
// mem_walker_stride and controller_fsm for BASE_ADDR/ST/VMEM1    
//==============================================================================
   always @(posedge clk) begin
        if (reset) begin
            _mws_st_base_vmem1_lsb <= 0;
            _mws_st_base_vmem1_msb <= 0;
        end
        else if (st_cfg_base_addr_v && cfg_base_addr_segment == 0 && cfg_ns_id == NS_VMEM_1)
            _mws_st_base_vmem1_lsb <= cfg_base_addr;
        else if (st_cfg_base_addr_v && cfg_base_addr_segment == 1 && cfg_ns_id == NS_VMEM_1)
            _mws_st_base_vmem1_msb <= cfg_base_addr;
    end
    assign mws_st_cfg_base_addr_vmem1[BASE_ADDR_SEGMENT_W-1:0] = _mws_st_base_vmem1_lsb;
    assign mws_st_cfg_base_addr_vmem1[2*BASE_ADDR_SEGMENT_W-1:BASE_ADDR_SEGMENT_W] = _mws_st_base_vmem1_msb;
    assign mws_st_cfg_base_addr_vmem1[4*BASE_ADDR_SEGMENT_W-1:2*BASE_ADDR_SEGMENT_W] = 'b0;

    register_sync #(1) mws_st_cfg_base_vmem1_delay (clk, reset, (st_cfg_base_addr_v && cfg_base_addr_segment == 1 && cfg_ns_id == NS_VMEM_1), mws_st_cfg_base_addr_vmem1_v);
 
    wire                              st_cfg_stride_base_addr_vmem1_v;
    wire                              st_cfg_base_loop_iter_vmem1_v;

 
    wire [ 2*ADDR_STRIDE_W          -1: 0 ]              mws_st_cfg_stride_base_addr_vmem1;
    reg  [ ADDR_STRIDE_W            -1: 0 ]              _mws_st_cfg_stride_vmem1_lsb;
    reg  [ ADDR_STRIDE_W            -1: 0 ]              _mws_st_cfg_stride_vmem1_msb;
    
    always @(posedge clk) begin
        if (reset) begin
           _mws_st_cfg_stride_vmem1_lsb <= 0;
           _mws_st_cfg_stride_vmem1_msb <= 0;
        end
        else if (st_cfg_base_loop_stride_v && cfg_ns_id == NS_VMEM_1 && cfg_stride_segment == 0 )
            _mws_st_cfg_stride_vmem1_lsb <= cfg_loop_stride;
        else if (st_cfg_base_loop_stride_v && cfg_ns_id == NS_VMEM_1 && cfg_stride_segment == 1 )
            _mws_st_cfg_stride_vmem1_msb <= cfg_loop_stride;
    end    
    assign mws_st_cfg_stride_base_addr_vmem1[ADDR_STRIDE_W-1:0] = _mws_st_cfg_stride_vmem1_lsb;
    assign mws_st_cfg_stride_base_addr_vmem1[2*ADDR_STRIDE_W-1:ADDR_STRIDE_W] = _mws_st_cfg_stride_vmem1_msb;
    
    register_sync #(1) mws_st_cfg_stride_base_vmem1_delay (clk, reset, (st_cfg_base_loop_stride_v && cfg_ns_id == NS_VMEM_1 && cfg_stride_segment == 1 ), st_cfg_stride_base_addr_vmem1_v);
    
    mem_walker_stride_group_simd #(
      .ADDR_WIDTH                   ( AXI_ADDR_WIDTH ),
      .ADDR_STRIDE_W                ( 2*ADDR_STRIDE_W ),
      .LOOP_ID_W                    ( LOOP_ID_W ),
      .GROUP_ID_W                   ( GROUP_ID_W )  
    ) mws_base_st_vmem1 (
      .clk                          ( clk ),
      .reset                        ( reset ),
      .isBase                       (1'b1),

      .base_addr                    ( mws_st_cfg_base_addr_vmem1 ),
      .iter_done                    ( mws_st_base_vmem1_iter_done ),
      .start                        ( mws_st_base_vmem1_start ),
      .stall                        ( mws_st_base_vmem1_stall ),
      .block_done                   ( block_done              ),
      .base_addr_v                  ( mws_st_cfg_base_addr_vmem1_v ),
      
      .cfg_loop_id                  ( cfg_loop_id ),
      .cfg_addr_stride_v            ( st_cfg_stride_base_addr_vmem1_v ),
      .cfg_addr_stride              ( mws_st_cfg_stride_base_addr_vmem1 ),
      
      .cfg_loop_group_id            ( cfg_group_id ),
      .loop_group_id                ( ld_st_group_id ),
      
      .addr_out                     ( mws_st_base_addr_vmem1 ),
      .addr_out_valid               ( mws_st_base_addr_out_vmem1_v )
    );

    assign st_cfg_base_loop_iter_vmem1_v = st_cfg_base_loop_iter_v && cfg_ns_id == NS_VMEM_1;

    controller_fsm_group_simd #(
      .LOOP_ID_W                    ( LOOP_ID_W ),
      .GROUP_ID_W                   ( GROUP_ID_W ),
      .LOOP_ITER_W                  ( LOOP_ITER_W )
    ) controller_fsm_base_st_vmem1  (
      .clk                          ( clk ),
      .reset                        ( reset ),
      .isBase                       (1'b1),

      .start                        ( mws_st_base_vmem1_start_d ),
      .block_done                   ( block_done              ),
      .done                         ( mws_st_base_vmem1_done ),
      .stall                        ( mws_st_base_vmem1_stall ),
      
      .cfg_loop_iter_v              ( st_cfg_base_loop_iter_vmem1_v ),
      .cfg_loop_iter                ( cfg_loop_iter ),
      .cfg_loop_iter_loop_id        ( cfg_loop_id ),   
      .cfg_loop_group_id            ( cfg_group_id ),
      
      .loop_group_id                ( ld_st_group_id ),
      .iter_done                    ( mws_st_base_vmem1_iter_done ),
      .current_iters                (                             )
    );


//==============================================================================    
// mem_walker_stride and controller_fsm for BASE_ADDR/ST/VMEM2    
//==============================================================================
    always @(posedge clk) begin
        if (reset) begin
            _mws_st_base_vmem2_lsb <= 0;
            _mws_st_base_vmem2_msb <= 0;
        end
        else if (st_cfg_base_addr_v && cfg_base_addr_segment == 0 && cfg_ns_id == NS_VMEM_2)
            _mws_st_base_vmem2_lsb <= cfg_base_addr;
        else if (st_cfg_base_addr_v && cfg_base_addr_segment == 1 && cfg_ns_id == NS_VMEM_2)
            _mws_st_base_vmem2_msb <= cfg_base_addr;
    end
    assign mws_st_cfg_base_addr_vmem2[BASE_ADDR_SEGMENT_W-1:0] = _mws_st_base_vmem2_lsb;
    assign mws_st_cfg_base_addr_vmem2[2*BASE_ADDR_SEGMENT_W-1:BASE_ADDR_SEGMENT_W] = _mws_st_base_vmem2_msb;
    assign mws_st_cfg_base_addr_vmem2[4*BASE_ADDR_SEGMENT_W-1:2*BASE_ADDR_SEGMENT_W] = 'b0;

    register_sync #(1) mws_st_cfg_base_vmem2_delay (clk, reset, (st_cfg_base_addr_v && cfg_base_addr_segment == 1 && cfg_ns_id == NS_VMEM_2), mws_st_cfg_base_addr_vmem2_v);
    
    wire                              st_cfg_stride_base_addr_vmem2_v;
    wire                              st_cfg_base_loop_iter_vmem2_v;

    wire [ 2*ADDR_STRIDE_W          -1: 0 ]              mws_st_cfg_stride_base_addr_vmem2;
    reg  [ ADDR_STRIDE_W            -1: 0 ]              _mws_st_cfg_stride_vmem2_lsb;
    reg  [ ADDR_STRIDE_W            -1: 0 ]              _mws_st_cfg_stride_vmem2_msb;
    
    always @(posedge clk) begin
        if (reset) begin
           _mws_st_cfg_stride_vmem2_lsb <= 0;
           _mws_st_cfg_stride_vmem2_msb <= 0;
        end
        else if (st_cfg_base_loop_stride_v && cfg_ns_id == NS_VMEM_2 && cfg_stride_segment == 0 )
            _mws_st_cfg_stride_vmem2_lsb <= cfg_loop_stride;
        else if (st_cfg_base_loop_stride_v && cfg_ns_id == NS_VMEM_2 && cfg_stride_segment == 1 )
            _mws_st_cfg_stride_vmem2_msb <= cfg_loop_stride;
    end    
    assign mws_st_cfg_stride_base_addr_vmem2[ADDR_STRIDE_W-1:0] = _mws_st_cfg_stride_vmem2_lsb;
    assign mws_st_cfg_stride_base_addr_vmem2[2*ADDR_STRIDE_W-1:ADDR_STRIDE_W] = _mws_st_cfg_stride_vmem2_msb;
    
    register_sync #(1) mws_st_cfg_stride_base_vmem2_delay (clk, reset, (st_cfg_base_loop_stride_v && cfg_ns_id == NS_VMEM_2 && cfg_stride_segment == 1 ), st_cfg_stride_base_addr_vmem2_v);
    
    mem_walker_stride_group_simd #(
      .ADDR_WIDTH                   ( AXI_ADDR_WIDTH ),
      .ADDR_STRIDE_W                ( 2*ADDR_STRIDE_W ),
      .LOOP_ID_W                    ( LOOP_ID_W ),
      .GROUP_ID_W                   ( GROUP_ID_W )  
    ) mws_base_st_vmem2 (
      .clk                          ( clk ),
      .reset                        ( reset ),
      .isBase                       (1'b1),

      .base_addr                    ( mws_st_cfg_base_addr_vmem2 ),
      .iter_done                    ( mws_st_base_vmem2_iter_done ),
      .start                        ( mws_st_base_vmem2_start ),
      .stall                        ( mws_st_base_vmem2_stall ),
      .block_done                   ( block_done              ),
      .base_addr_v                  ( mws_st_cfg_base_addr_vmem2_v ),
      
      .cfg_loop_id                  ( cfg_loop_id ),
      .cfg_addr_stride_v            ( st_cfg_stride_base_addr_vmem2_v ),
      .cfg_addr_stride              ( mws_st_cfg_stride_base_addr_vmem2 ),
      
      .cfg_loop_group_id            ( cfg_group_id ),
      .loop_group_id                ( ld_st_group_id ),
      
      .addr_out                     ( mws_st_base_addr_vmem2 ),
      .addr_out_valid               ( mws_st_base_addr_out_vmem2_v )
    );

    assign st_cfg_base_loop_iter_vmem2_v = st_cfg_base_loop_iter_v && cfg_ns_id == NS_VMEM_2;

    controller_fsm_group_simd_debug #(
      .LOOP_ID_W                    ( LOOP_ID_W ),
      .GROUP_ID_W                   ( GROUP_ID_W ),
      .LOOP_ITER_W                  ( LOOP_ITER_W )
    ) controller_fsm_base_st_vmem2  (
      .clk                          ( clk ),
      .reset                        ( reset ),
      .isBase                       (1'b1), 

      .start                        ( mws_st_base_vmem2_start_d ),
      .block_done                   ( block_done              ),
      .done                         ( mws_st_base_vmem2_done ),
      .stall                        ( mws_st_base_vmem2_stall ),
      
      .cfg_loop_iter_v              ( st_cfg_base_loop_iter_vmem2_v ),
      .cfg_loop_iter                ( cfg_loop_iter ),
      .cfg_loop_iter_loop_id        ( cfg_loop_id ),   
      .cfg_loop_group_id            ( cfg_group_id ),
      
      .loop_group_id                ( ld_st_group_id ),
      .iter_done                    ( mws_st_base_vmem2_iter_done ),
      .current_iters                ( cur_iter_test               )
//      .max_iters                    ( st_vmem2_max_iters          )
    );

//    wire [LOOP_ITER_W*NUM_MAX_LOOPS-1:0] cur_iter_test;
//    wire [LOOP_ITER_W*NUM_MAX_LOOPS-1:0] st_vmem2_max_iters;
//    reg [LOOP_ITER_W-1:0] iter_test [NUM_MAX_LOOPS:0];
//    reg [LOOP_ITER_W-1:0] max_iter_test [NUM_MAX_LOOPS:0];
//    for(genvar t=0; t< NUM_MAX_LOOPS; t=t+1) begin
//        always @(*) begin
//          iter_test[t] = cur_iter_test[LOOP_ITER_W*t+:LOOP_ITER_W];
//        end
//    end
    
//    for(genvar t=0; t< NUM_MAX_LOOPS; t=t+1) begin
//        always @(*) begin
//          max_iter_test[t] = st_vmem2_max_iters[LOOP_ITER_W*t+:LOOP_ITER_W];
//        end
//    end

//==============================================================================    
// mem_walker_stride and controller_fsm for TILE/ST/VMEM1    
//==============================================================================
    always @(posedge clk) begin
       if (reset)
           _mws_st_tile_base_addr_vmem1 <= 0;
       else if (mws_st_base_addr_out_vmem1_v)
           _mws_st_tile_base_addr_vmem1 <= mws_st_base_addr_vmem1;
    end
    
    assign mws_st_tile_base_addr_vmem1 = _mws_st_tile_base_addr_vmem1;

    register_sync #(1) mws_st_cfg_tile_vmem1_delay (clk, reset, mws_st_base_addr_out_vmem1_v, mws_st_tile_base_addr_vmem1_v);
 
    wire                              st_cfg_stride_tile_addr_vmem1_v;
    wire [ 2*ADDR_STRIDE_W          -1: 0 ]              mws_st_cfg_stride_tile_addr_vmem1;
    reg  [ ADDR_STRIDE_W            -1: 0 ]              _mws_st_cfg_stride_tile_vmem1_lsb;
    reg  [ ADDR_STRIDE_W            -1: 0 ]              _mws_st_cfg_stride_tile_vmem1_msb;
    
    always @(posedge clk) begin
        if (reset) begin
           _mws_st_cfg_stride_tile_vmem1_lsb <= 0;
           _mws_st_cfg_stride_tile_vmem1_msb <= 0;
        end
        else if (st_cfg_tile_loop_stride_v && cfg_ns_id == NS_VMEM_1 && cfg_stride_segment == 0 )
            _mws_st_cfg_stride_tile_vmem1_lsb <= cfg_loop_stride;
        else if (st_cfg_tile_loop_stride_v && cfg_ns_id == NS_VMEM_1 && cfg_stride_segment == 1 )
            _mws_st_cfg_stride_tile_vmem1_msb <= cfg_loop_stride;
    end    
    assign mws_st_cfg_stride_tile_addr_vmem1[ADDR_STRIDE_W-1:0] = _mws_st_cfg_stride_tile_vmem1_lsb;
    assign mws_st_cfg_stride_tile_addr_vmem1[2*ADDR_STRIDE_W-1:ADDR_STRIDE_W] = _mws_st_cfg_stride_tile_vmem1_msb;
    
    register_sync #(1) mws_st_cfg_stride_tile_vmem1_delay (clk, reset, (st_cfg_tile_loop_stride_v && cfg_ns_id == NS_VMEM_1 && cfg_stride_segment == 1 ), st_cfg_stride_tile_addr_vmem1_v);
    
    wire   st_cfg_tile_loop_iter_vmem1_v;
    assign st_cfg_tile_loop_iter_vmem1_v = st_cfg_tile_loop_iter_v && cfg_ns_id == NS_VMEM_1;
    
    mem_walker_stride_group_simd #(
      .ADDR_WIDTH                   ( AXI_ADDR_WIDTH ),
      .ADDR_STRIDE_W                ( 2*ADDR_STRIDE_W ),
      .LOOP_ID_W                    ( LOOP_ID_W ),
      .GROUP_ID_W                   ( GROUP_ID_W )  
    ) mws_tile_st_vmem1 (
      .clk                          ( clk ),
      .reset                        ( reset ),
      .isBase                       (1'b0),

      .base_addr                    ( mws_st_tile_base_addr_vmem1 ),
      .iter_done                    ( mws_st_tile_vmem1_iter_done ),
      .start                        ( mws_st_tile_vmem1_start ),
      .stall                        ( mws_st_tile_vmem1_stall ),
      .block_done                   ( block_done              ),
      .base_addr_v                  ( mws_st_tile_base_addr_vmem1_v ),
      
      .cfg_loop_id                  ( cfg_loop_id                   ),
      .cfg_addr_stride_v            ( st_cfg_stride_tile_addr_vmem1_v ),
      .cfg_addr_stride              ( mws_st_cfg_stride_tile_addr_vmem1 ),
      
      .cfg_loop_group_id            ( cfg_group_id ),
      .loop_group_id                ( ld_st_group_id ),
      
      .addr_out                     ( mws_st_tile_addr_vmem1 ),
      .addr_out_valid               ( mws_st_tile_addr_out_vmem1_v )
    );

    controller_fsm_group_simd #(
      .LOOP_ID_W                    ( LOOP_ID_W ),
      .GROUP_ID_W                   ( GROUP_ID_W ),
      .LOOP_ITER_W                  ( LOOP_ITER_W )
    ) controller_fsm_tile_st_vmem1  (
      .clk                          ( clk ),
      .reset                        ( reset ),
      .isBase                       (1'b0),

      .start                        ( mws_st_tile_vmem1_start ),
      .done                         ( mws_st_tile_vmem1_done ),
      .stall                        ( mws_st_tile_vmem1_stall ),
      .block_done                   ( block_done              ),
      
      .cfg_loop_iter_v              ( st_cfg_tile_loop_iter_vmem1_v ),
      .cfg_loop_iter                ( cfg_loop_iter ),
      .cfg_loop_iter_loop_id        ( cfg_loop_id ),   
      .cfg_loop_group_id            ( cfg_group_id ),
      
      .loop_group_id                ( ld_st_group_id ),
      .iter_done                    ( mws_st_tile_vmem1_iter_done ),
      .current_iters                (                           )
    );


//==============================================================================    
// mem_walker_stride and controller_fsm for TILE/ST/VMEM2    
//==============================================================================
      always @(posedge clk) begin
       if (reset)
           _mws_st_tile_base_addr_vmem2 <= 0;
       else if (mws_st_base_addr_out_vmem2_v)
           _mws_st_tile_base_addr_vmem2 <= mws_st_base_addr_vmem2;
    end
    
    assign mws_st_tile_base_addr_vmem2 = _mws_st_tile_base_addr_vmem2;

    register_sync #(1) mws_st_cfg_tile_vmem2_delay (clk, reset, mws_st_base_addr_out_vmem2_v, mws_st_tile_base_addr_vmem2_v);
 
    wire                              st_cfg_stride_tile_addr_vmem2_v;
    wire [ 2*ADDR_STRIDE_W          -1: 0 ]              mws_st_cfg_stride_tile_addr_vmem2;
    reg  [ ADDR_STRIDE_W            -1: 0 ]              _mws_st_cfg_stride_tile_vmem2_lsb;
    reg  [ ADDR_STRIDE_W            -1: 0 ]              _mws_st_cfg_stride_tile_vmem2_msb;
    
    always @(posedge clk) begin
        if (reset) begin
           _mws_st_cfg_stride_tile_vmem2_lsb <= 0;
           _mws_st_cfg_stride_tile_vmem2_msb <= 0;
        end
        else if (st_cfg_tile_loop_stride_v && cfg_ns_id == NS_VMEM_2 && cfg_stride_segment == 0 )
            _mws_st_cfg_stride_tile_vmem2_lsb <= cfg_loop_stride;
        else if (st_cfg_tile_loop_stride_v && cfg_ns_id == NS_VMEM_2 && cfg_stride_segment == 1 )
            _mws_st_cfg_stride_tile_vmem2_msb <= cfg_loop_stride;
    end    
    assign mws_st_cfg_stride_tile_addr_vmem2[ADDR_STRIDE_W-1:0] = _mws_st_cfg_stride_tile_vmem2_lsb;
    assign mws_st_cfg_stride_tile_addr_vmem2[2*ADDR_STRIDE_W-1:ADDR_STRIDE_W] = _mws_st_cfg_stride_tile_vmem2_msb;
    
    register_sync #(1) mws_st_cfg_stride_tile_vmem2_delay (clk, reset, (st_cfg_tile_loop_stride_v && cfg_ns_id == NS_VMEM_2 && cfg_stride_segment == 1 ), st_cfg_stride_tile_addr_vmem2_v);
    
    wire                              st_cfg_tile_loop_iter_vmem2_v;
    assign st_cfg_tile_loop_iter_vmem2_v = st_cfg_tile_loop_iter_v && cfg_ns_id == NS_VMEM_2;
    
    mem_walker_stride_group_simd #(
      .ADDR_WIDTH                   ( AXI_ADDR_WIDTH ),
      .ADDR_STRIDE_W                ( 2*ADDR_STRIDE_W ),
      .LOOP_ID_W                    ( LOOP_ID_W ),
      .GROUP_ID_W                   ( GROUP_ID_W )  
    ) mws_tile_st_vmem2 (
      .clk                          ( clk   ),
      .reset                        ( reset ),
      .isBase                       ( 1'b0  ),

      .base_addr                    ( mws_st_tile_base_addr_vmem2 ),
      .iter_done                    ( mws_st_tile_vmem2_iter_done ),
      .start                        ( mws_st_tile_vmem2_start ),
      .stall                        ( mws_st_tile_vmem2_stall ),
      .block_done                   ( block_done              ),
      .base_addr_v                  ( mws_st_tile_base_addr_vmem2_v ),
      
      .cfg_loop_id                  ( cfg_loop_id                   ),
      .cfg_addr_stride_v            ( st_cfg_stride_tile_addr_vmem2_v ),
      .cfg_addr_stride              ( mws_st_cfg_stride_tile_addr_vmem2 ),

      .cfg_loop_group_id            ( cfg_group_id ),
      .loop_group_id                ( ld_st_group_id ),
      
      .addr_out                     ( mws_st_tile_addr_vmem2 ),
      .addr_out_valid               ( mws_st_tile_addr_out_vmem2_v )
    );

    controller_fsm_group_simd #(
      .LOOP_ID_W                    ( LOOP_ID_W ),
      .GROUP_ID_W                   ( GROUP_ID_W ),
      .LOOP_ITER_W                  ( LOOP_ITER_W )
    ) controller_fsm_tile_st_vmem2  (
      .clk                          ( clk   ),
      .reset                        ( reset ),
      .isBase                       ( 1'b0  ), 

      .start                        ( mws_st_tile_vmem2_start ),
      .done                         ( mws_st_tile_vmem2_done ),
      .stall                        ( mws_st_tile_vmem2_stall ),
      .block_done                   ( block_done              ),
      
      .cfg_loop_iter_v              ( st_cfg_tile_loop_iter_vmem2_v ),
      .cfg_loop_iter                ( cfg_loop_iter ),
      .cfg_loop_iter_loop_id        ( cfg_loop_id ),   
      .cfg_loop_group_id            ( cfg_group_id ),
      
      .loop_group_id                ( ld_st_group_id ),
      .iter_done                    ( mws_st_tile_vmem2_iter_done ),
      .current_iters                (                           )
    );

//==============================================================================
// ld/st packet counter
//==============================================================================
  reg             last_ld_iter;
  always @(posedge clk) begin
    if (reset)
      last_ld_iter <= 1'b0;
    else if (mws_ld_tile_vmem1_done || mws_ld_tile_vmem2_done)  // DEBUG
      last_ld_iter <= 1'b1;
    else if (ldmem_state_q == LDMEM_DONE)
      last_ld_iter <= 1'b0;
  end

  always @(posedge clk) begin
    if (reset)
      last_st_iter <= 1'b0;
    else if (mws_st_tile_vmem1_done || mws_st_tile_vmem2_done) // DBEUG
      last_st_iter <= 1'b1;
    else if (stmem_state_q == STMEM_DONE)
      last_st_iter <= 1'b0;
  end


  wire                                        single_ld_iter_flag;
  reg [2*LOOP_ITER_W - 1 : 0]                 ld_iter_cntr;
  wire                                        single_st_iter_flag;
  reg [2*LOOP_ITER_W - 1 : 0]                 st_iter_cntr;
  reg             last_st_iter;

  always @(posedge clk) begin
    if (reset || block_done) begin
      ld_iter_cntr <= 1;
    end else if (ld_cfg_tile_loop_iter_vmem1_v || ld_cfg_tile_loop_iter_vmem2_v) begin // DEBUG
      ld_iter_cntr <= ld_iter_cntr * (cfg_loop_iter + 1); // DEBUG
    end
  end

  assign single_ld_iter_flag = ld_iter_cntr == 1; 

  always @(posedge clk) begin
    if (reset || block_done)
      st_iter_cntr <= 1;
    else if (st_cfg_tile_loop_iter_vmem1_v || st_cfg_tile_loop_iter_vmem2_v)  // DEBUG
      st_iter_cntr <= st_iter_cntr * (cfg_loop_iter + 1); // DEBUG
  end

  assign single_st_iter_flag = st_iter_cntr == 1; 

//==============================================================================
// Memory Request Generation
//==============================================================================

// LD
  wire   [ AXI_ADDR_WIDTH       -1:0 ] ld_addr;
  reg    [ AXI_ADDR_WIDTH       -1:0 ] _ld_addr;
  wire                                 ld_addr_v;
  
  assign ld_addr_v = (mws_ld_tile_addr_out_vmem1_v) || (mws_ld_tile_addr_out_vmem2_v); // DEBUG
  
  always @(*) begin
     if (mws_ld_tile_addr_out_vmem1_v) 
         _ld_addr = mws_ld_tile_addr_vmem1;
     else if (mws_ld_tile_addr_out_vmem2_v)
         _ld_addr = mws_ld_tile_addr_vmem2;
  end
  assign ld_addr = _ld_addr + simd_base_offset ;

  always @(posedge clk) begin
    if (reset) begin
      ld_req_size <= 0;
      ld_data_width <= 0;
    end else if (ld_start) begin
      ld_req_size <= cfg_mem_req_size;
      ld_data_width <= cfg_ld_st_data_width;
    end
  end

  assign ld_req_valid_d = ld_addr_v;

  always @(posedge clk) begin
    if (reset) begin
      ld_req_valid_q <= 1'b0;
      ld_req_addr <= 0;
    end else begin
      ld_req_valid_q <= ld_req_valid_d;
      ld_req_addr <= ld_addr;
    end
  end

// ST
  wire   [ AXI_ADDR_WIDTH       -1:0 ] st_addr;
  reg    [ AXI_ADDR_WIDTH       -1:0 ] _st_addr;
  wire                                 st_addr_v;
  
  assign st_addr_v = mws_st_tile_addr_out_vmem1_v || mws_st_tile_addr_out_vmem2_v;
  
  always @(*) begin
     if (mws_st_tile_addr_out_vmem1_v) 
         _st_addr = mws_st_tile_addr_vmem1;
     else if (mws_st_tile_addr_out_vmem2_v)
         _st_addr = mws_st_tile_addr_vmem2;
  end
  assign st_addr = _st_addr + simd_base_offset;

  always @(posedge clk) begin
    if (reset) begin
      st_req_size <= 0;
      st_data_width <= 0;
    end
    else if (st_start) begin
      st_req_size <= cfg_mem_req_size;
      st_data_width <= cfg_ld_st_data_width;
    end
  end

  assign st_req_valid_d = st_addr_v;

  always @(posedge clk) begin
    if (reset) begin
      st_req_valid_q <= 1'b0;
      st_req_addr <= 0;
    end else begin
      st_req_valid_q <= st_req_valid_d;
      st_req_addr <= st_addr;
    end
  end
//==============================================================================


//==============================================================================
// FSM
//==============================================================================
  reg   [ 2                 -1: 0]          _ldmem_ns_id;
  reg   [ 2                 -1: 0]          _stmem_ns_id;
  
  always @(posedge clk) begin
     if (reset) begin
        _ldmem_ns_id <= 0;
        _stmem_ns_id <= 0;
     end
     else if (ld_start)
        _ldmem_ns_id <= cfg_ns_id;
     else if (st_start)
        _stmem_ns_id <= cfg_ns_id;
  end

  wire ld_from_axi_done;
  wire st_to_axi_done;

  always @(posedge clk) begin
    axi_rd_done_d <= axi_rd_done;
    axi_wr_done_d <= axi_wr_done;
  end

  assign ld_from_axi_done = single_ld_iter_flag ? ld_received_data_flag /*axi_rd_done_d*/ : (ld_received_data_flag && last_ld_iter); // DEBUG
  assign st_to_axi_done = single_st_iter_flag ? st_sent_data_flag /*axi_wr_done_d*/ : (st_sent_data_flag && last_st_iter); // DEBUG

// LD FSM
  always @(posedge clk) begin
      if (reset) begin
          mws_ld_base_vmem1_has_start <= 1'b0;
      end else if (mws_ld_base_vmem1_done) begin
          mws_ld_base_vmem1_has_start <= 1'b0;
      end else begin
          if ((ldmem_state_q == LDMEM_IDLE) && ld_start && (cfg_ns_id == NS_VMEM_1) && !mws_ld_base_vmem1_has_start) begin
              mws_ld_base_vmem1_has_start <= 1'b1;
          end  
      end
  end

  always @(posedge clk) begin
      if (reset) begin
          mws_ld_base_vmem2_has_start <= 1'b0;
      end else if (mws_ld_base_vmem2_done) begin
          mws_ld_base_vmem2_has_start <= 1'b0;
      end else begin
          if ((ldmem_state_q == LDMEM_IDLE) && ld_start && (cfg_ns_id == NS_VMEM_2) && !mws_ld_base_vmem2_has_start) begin
              mws_ld_base_vmem2_has_start <= 1'b1;
          end  
      end
  end

  wire mws_ld_base_vmem1_start_d, mws_ld_base_vmem2_start_d;
  assign mws_ld_base_vmem1_start = (ldmem_state_q == LDMEM_IDLE) && ld_start && (cfg_ns_id == NS_VMEM_1) && !mws_ld_base_vmem1_has_start;
  assign mws_ld_base_vmem2_start = (ldmem_state_q == LDMEM_IDLE) && ld_start && (cfg_ns_id == NS_VMEM_2) && !mws_ld_base_vmem2_has_start;
  register_sync #(1) mws_ld_base_vmem1_start_delay (clk, reset, mws_ld_base_vmem1_start, mws_ld_base_vmem1_start_d);
  register_sync #(1) mws_ld_base_vmem2_start_delay (clk, reset, mws_ld_base_vmem2_start, mws_ld_base_vmem2_start_d);

  wire mws_ld_base_vmem1_start_inst, mws_ld_base_vmem2_start_inst;
  wire mws_ld_base_vmem1_start_inst_d, mws_ld_base_vmem2_start_inst_d;
  assign mws_ld_base_vmem1_start_inst = (ldmem_state_q == LDMEM_IDLE) && ld_start && (cfg_ns_id == NS_VMEM_1);
  assign mws_ld_base_vmem2_start_inst = (ldmem_state_q == LDMEM_IDLE) && ld_start && (cfg_ns_id == NS_VMEM_2);
  register_sync #(1) mws_ld_base_vmem1_start_inst_delay (clk, reset, mws_ld_base_vmem1_start_inst, mws_ld_base_vmem1_start_inst_d);
  register_sync #(1) mws_ld_base_vmem2_start_inst_delay (clk, reset, mws_ld_base_vmem2_start_inst, mws_ld_base_vmem2_start_inst_d);

  assign mws_ld_base_vmem1_stall = ldmem_state_q != LDMEM_GEN_BASE_ADDR || (ldmem_state_q == LDMEM_GEN_BASE_ADDR) && _ldmem_ns_id != NS_VMEM_1;
  assign mws_ld_base_vmem2_stall = ldmem_state_q != LDMEM_GEN_BASE_ADDR || (ldmem_state_q == LDMEM_GEN_BASE_ADDR) && _ldmem_ns_id != NS_VMEM_2;

  // Start should only last one cycle
  reg [ 4-1: 0 ] ldmem_state_next;
  always @(posedge clk) begin
    ldmem_state_next <= ldmem_state_q;
  end
  
  assign mws_ld_tile_vmem1_start = (ldmem_state_q == LDMEM_TILE_BUSY_NS_VMEM1) && (ldmem_state_next != LDMEM_TILE_BUSY_NS_VMEM1);
  assign mws_ld_tile_vmem2_start = (ldmem_state_q == LDMEM_TILE_BUSY_NS_VMEM2) && (ldmem_state_next != LDMEM_TILE_BUSY_NS_VMEM2);  
  assign mws_ld_tile_vmem1_stall = ~axi_rd_ready || rd_req_fifo_full || ld_fifo_prog_full;
  assign mws_ld_tile_vmem2_stall = ~axi_rd_ready || rd_req_fifo_full || ld_fifo_prog_full;
    
  always @(*) begin
    ldmem_state_d = ldmem_state_q;
    case(ldmem_state_q)
        LDMEM_IDLE: begin
          if (ld_start) 
            ldmem_state_d = LDMEM_GEN_BASE_ADDR; 
        end
        LDMEM_GEN_BASE_ADDR: begin
          if (mws_ld_base_vmem1_start_inst_d)     //if (mws_ld_base_addr_out_vmem1_v)
            ldmem_state_d = LDMEM_TILE_BUSY_NS_VMEM1;
          else if (mws_ld_base_vmem2_start_inst_d)     // else if (mws_ld_base_addr_out_vmem2_v)
            ldmem_state_d = LDMEM_TILE_BUSY_NS_VMEM2; 
        end     
        LDMEM_TILE_BUSY_NS_VMEM1: begin
            if (ld_from_axi_done)
                ldmem_state_d = LDMEM_DONE;
        end
        LDMEM_TILE_BUSY_NS_VMEM2: begin
            if (ld_from_axi_done)
                ldmem_state_d = LDMEM_DONE;           
        end
        LDMEM_DONE: begin
           ldmem_state_d = LDMEM_IDLE;
        end
    endcase   
  end  
  
  always @(posedge clk) begin
     if (reset) 
        ldmem_state_q <= LDMEM_IDLE; 
     else
        ldmem_state_q <= ldmem_state_d;
  end
      

// ST FSM
  always @(posedge clk) begin
      if (reset) begin
          mws_st_base_vmem1_has_start <= 1'b0;
      end else if (mws_st_base_vmem1_done) begin
          mws_st_base_vmem1_has_start <= 1'b0;
      end else begin
          if ((stmem_state_q == STMEM_IDLE) && st_start && (cfg_ns_id == NS_VMEM_1) && !mws_st_base_vmem1_has_start) begin
              mws_st_base_vmem1_has_start <= 1'b1;
          end  
      end
  end

  always @(posedge clk) begin
      if (reset) begin
          mws_st_base_vmem2_has_start <= 1'b0;
      end else if (mws_st_base_vmem2_done) begin
          mws_st_base_vmem2_has_start <= 1'b0;
      end else begin
          if ((stmem_state_q == STMEM_IDLE) && st_start && (cfg_ns_id == NS_VMEM_2) && !mws_st_base_vmem2_has_start) begin
              mws_st_base_vmem2_has_start <= 1'b1;
          end  
      end
  end

  wire mws_st_base_vmem1_start_d, mws_st_base_vmem2_start_d;
  assign mws_st_base_vmem1_start = (stmem_state_q == STMEM_IDLE) && st_start && (cfg_ns_id == NS_VMEM_1) && !mws_st_base_vmem1_has_start;
  assign mws_st_base_vmem2_start = (stmem_state_q == STMEM_IDLE) && st_start && (cfg_ns_id == NS_VMEM_2) && !mws_st_base_vmem2_has_start;
  assign mws_st_base_vmem1_stall = stmem_state_q != STMEM_GEN_BASE_ADDR || (stmem_state_q == STMEM_GEN_BASE_ADDR && _stmem_ns_id != NS_VMEM_1);
  assign mws_st_base_vmem2_stall = stmem_state_q != STMEM_GEN_BASE_ADDR || (stmem_state_q == STMEM_GEN_BASE_ADDR && _stmem_ns_id != NS_VMEM_2);
  register_sync #(1) mws_st_base_vmem1_start_delay (clk, reset, mws_st_base_vmem1_start, mws_st_base_vmem1_start_d);
  register_sync #(1) mws_st_base_vmem2_start_delay (clk, reset, mws_st_base_vmem2_start, mws_st_base_vmem2_start_d);

  wire mws_st_base_vmem1_start_inst, mws_st_base_vmem2_start_inst;
  wire mws_st_base_vmem1_start_inst_d, mws_st_base_vmem2_start_inst_d;
  assign mws_st_base_vmem1_start_inst = (ldmem_state_q == LDMEM_IDLE) && st_start && (cfg_ns_id == NS_VMEM_1);
  assign mws_st_base_vmem2_start_inst = (ldmem_state_q == LDMEM_IDLE) && st_start && (cfg_ns_id == NS_VMEM_2);
  register_sync #(1) mws_st_base_vmem1_start_inst_delay (clk, reset, mws_st_base_vmem1_start_inst, mws_st_base_vmem1_start_inst_d);
  register_sync #(1) mws_st_base_vmem2_start_inst_delay (clk, reset, mws_st_base_vmem2_start_inst, mws_st_base_vmem2_start_inst_d);


  // Start should only last one cycle
  reg [ 4-1: 0 ] stmem_state_next;
  always @(posedge clk) begin
    stmem_state_next <= stmem_state_q;
  end

  assign mws_st_tile_vmem1_start = (stmem_state_q == STMEM_TILE_BUSY_NS_VMEM1) && (stmem_state_next != STMEM_TILE_BUSY_NS_VMEM1);
  assign mws_st_tile_vmem2_start = (stmem_state_q == STMEM_TILE_BUSY_NS_VMEM2) && (stmem_state_next != STMEM_TILE_BUSY_NS_VMEM2);  
  assign mws_st_tile_vmem1_stall = ~axi_wr_ready || req_fifo_full;  // DEBUG wait for the AXI to finish the current request size
  assign mws_st_tile_vmem2_stall = ~axi_wr_ready || req_fifo_full;
  
  always @(*) begin
    stmem_state_d = stmem_state_q;
    case (stmem_state_q)
        STMEM_IDLE: begin
           if (st_start) 
              stmem_state_d = STMEM_GEN_BASE_ADDR; 
        end
        STMEM_GEN_BASE_ADDR: begin
           if (mws_st_base_vmem1_start_inst_d)
              stmem_state_d = STMEM_TILE_BUSY_NS_VMEM1;
           else if (mws_st_base_vmem2_start_inst_d)
              stmem_state_d = STMEM_TILE_BUSY_NS_VMEM2; 
        end     
        STMEM_TILE_BUSY_NS_VMEM1: begin
            if (st_to_axi_done)
                stmem_state_d = STMEM_DONE;
        end
        STMEM_TILE_BUSY_NS_VMEM2: begin
            if (st_to_axi_done)
                stmem_state_d = STMEM_DONE;           
        end
        STMEM_DONE: begin
           stmem_state_d = STMEM_IDLE;
        end
    endcase
  end

  always @(posedge clk) begin
     if (reset) 
        stmem_state_q <= STMEM_IDLE; 
     else
        stmem_state_q <= stmem_state_d;
  end
//==============================================================================    

//==============================================================================    

///////////////////////////////////////// 
// Logic to count requested vs received data packets
///////////////////////////////////////// 
// Load
  reg  [31:0] sent_ld_requests, ld_axi_req_size;
  wire [63:0] expected_packets;
  reg  [63:0] received_packets;

  wire  ld_received_data_flag;
  reg   ld_received_data_flag_temp;
  reg [3:0] ldmem_pkt_done_state_d;
  reg [3:0] ldmem_pkt_done_state_q;
  localparam integer  LDMEM_PKTS_SM_IDLE  = 0;
  localparam integer  LDMEM_TO_SEND_PKTS  = 1;
  localparam integer  LDMEM_SENT_PKTS     = 2;
  localparam integer  LDMEM_PKTS_DONE     = 3;

  always @(*) begin
    ldmem_pkt_done_state_d = ldmem_pkt_done_state_q;
    ld_received_data_flag_temp = 0;
    case(ldmem_pkt_done_state_q)
      LDMEM_PKTS_SM_IDLE: begin
        if (ldmem_state_q == LDMEM_TILE_BUSY_NS_VMEM1 || ldmem_state_q == LDMEM_TILE_BUSY_NS_VMEM2) begin
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

  always @(posedge clk) begin
    if (reset)
      ldmem_pkt_done_state_q <= LDMEM_PKTS_SM_IDLE;
    else
      ldmem_pkt_done_state_q <= ldmem_pkt_done_state_d;
  end

  always @(posedge clk) begin
    if (reset || ld_from_axi_done) begin
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
    if (reset || ld_from_axi_done) //DEBUG || ld_received_data_flag)
      received_packets <= 'b0;
    else if (mem_write_req)
      received_packets <= received_packets + WSTRB_W;
  end

  assign expected_packets = last_ld_iter ? sent_ld_requests * ld_axi_req_size : 0; // DEBUG

  assign ld_received_data_flag = (expected_packets == 'b0) ? 0 : ld_received_data_flag_temp;

reg mws_bvalid_q ;
//register_sync #(1) mws_bvalid_delay (clk, reset, mws_bvalid, mws_bvalid_d);
always @(posedge clk) begin
    mws_bvalid_q <= mws_bvalid ;
end


// Store
  reg  [31:0] sent_st_requests, st_axi_req_size;
  wire [63:0] to_send_packets;
  reg  [63:0] sent_packets;
  wire  st_sent_data_flag;
  reg st_sent_data_flag_temp;
  reg [3:0] stmem_pkt_done_state_d;
  reg [3:0] stmem_pkt_done_state_q;

  reg [31 : 0] num_awaddr_requests;
  reg [31 : 0] num_wlast_response;
  reg [31 : 0] num_bvalid_response;
  
  localparam integer  STMEM_PKTS_SM_IDLE  = 0;
  localparam integer  STMEM_TO_SEND_PKTS  = 1;
  localparam integer  STMEM_SENT_PKTS     = 2;
  localparam integer  STMEM_PKTS_WAIT     = 3;
  localparam integer  STMEM_PKTS_COMP     = 4;

  always @(*) begin
    stmem_pkt_done_state_d = stmem_pkt_done_state_q;
    st_sent_data_flag_temp = 0;
    case(stmem_pkt_done_state_q)
      STMEM_PKTS_SM_IDLE: begin
        if (stmem_state_q == STMEM_TILE_BUSY_NS_VMEM1 || stmem_state_q == STMEM_TILE_BUSY_NS_VMEM2) begin
          stmem_pkt_done_state_d = STMEM_TO_SEND_PKTS;
        end
      end
      STMEM_TO_SEND_PKTS: begin
        if (last_st_iter && to_send_packets != 'b0)
          stmem_pkt_done_state_d = STMEM_SENT_PKTS;
      end
      STMEM_SENT_PKTS: begin
        if (to_send_packets == sent_packets)
          if (mws_bvalid_q) begin
            stmem_pkt_done_state_d = STMEM_PKTS_COMP;  
          end else begin
            stmem_pkt_done_state_d = STMEM_PKTS_WAIT;
          end
      end
      STMEM_PKTS_WAIT: begin
        if (mws_bvalid_q)
          stmem_pkt_done_state_d = STMEM_PKTS_COMP;  
      end
      STMEM_PKTS_COMP: begin
        if (num_awaddr_requests == num_bvalid_response) begin
          st_sent_data_flag_temp = 1;
          stmem_pkt_done_state_d = STMEM_PKTS_SM_IDLE;
        end
      end
    endcase
  end

  always @(posedge clk) begin
    if (reset)
      stmem_pkt_done_state_q <= SPLIT_ST_REQ_IDLE;
    else
      stmem_pkt_done_state_q <= stmem_pkt_done_state_d;
  end

  always @(posedge clk) begin
    if (reset || st_to_axi_done)
      num_awaddr_requests <= 0;
    else if (mws_awvalid)
      num_awaddr_requests <= num_awaddr_requests + 1;
  end

  always @(posedge clk) begin
    if (reset || st_to_axi_done)
      num_wlast_response <= 0;
    else if (mws_wlast)
      num_wlast_response <= num_wlast_response + 1;
  end

  always @(posedge clk) begin
    if (reset || st_to_axi_done)
      num_bvalid_response <= 0;
    else if (mws_bvalid)
      num_bvalid_response <= num_bvalid_response + 1;
  end

  always @(posedge clk) begin
    if (reset || st_to_axi_done) begin
      sent_st_requests <= 'b0;
      st_axi_req_size <= 'b0;
    end else if (st_req_valid_q) begin
      sent_st_requests <= sent_st_requests + 1'b1;
      //st_axi_req_size <= axi_wr_req_size;
      st_axi_req_size <= st_req_size * wr_req_size_coefficient;
    end
  end

  // WSTRB_W is essentially AXI_DATA_WIDTH in bytes
  always @(posedge clk) begin
    if (reset || st_to_axi_done)
      sent_packets <= 'b0;
    else if (axi_wr_data_v)
      sent_packets <= sent_packets + WSTRB_W;
  end

  assign to_send_packets = last_st_iter ? sent_st_requests * st_axi_req_size : 0;
  assign st_sent_data_flag = st_sent_data_flag_temp; //&& axi_wr_done;
//============================================================================== 

//==============================================================================
// AXI4 LD FIFO
//==============================================================================
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
      end else begin
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


//==============================================================================
// AXI4 ST FIFO
//==============================================================================
  wire                                   st_fifo_almost_empty;
  wire                                   st_fifo_almost_full;
  wire                                   st_fifo_data_valid;
  wire  [ST_READ_DATA_WIDTH - 1 : 0]     st_fifo_dout;
  wire                                   st_fifo_empty;
  wire                                   st_fifo_full;
  wire                                   st_fifo_overflow;
  wire                                   st_fifo_prog_empty;
  wire                                   st_fifo_prog_full;
  wire  [ST_RD_DATA_COUNT_WIDTH - 1 : 0] st_fifo_rd_data_count;
  wire                                   st_fifo_rd_rst_busy;
  wire                                   st_fifo_underflow;
  wire                                   st_fifo_wr_ack;
  wire  [ST_WR_DATA_COUNT_WIDTH - 1 : 0] st_fifo_wr_data_count;
  wire                                   st_fifo_wr_rst_busy;
  wire  [ST_WRITE_DATA_WIDTH - 1 : 0]    st_fifo_din;
  reg                                    st_fifo_rd_en;
  wire                                   st_fifo_sleep;
  wire                                   st_fifo_wr_en;
  reg  [ST_WRITE_DATA_WIDTH - 1 : 0]     st_fifo_mem_read_data;

  // FIFO Inputs
  assign st_fifo_din    = st_fifo_mem_read_data;
  assign st_fifo_wr_en  = st_fifo_axi_wr_data_v;
  assign st_fifo_sleep = 1'b0;    // used for low power design

  // FIFO Outputs - todo: should we use just full
  assign axi_wr_ready = ~st_fifo_prog_full && ~st_fifo_wr_rst_busy && st_fifo_axi_wr_ready;
  assign axi_wr_data_v = st_fifo_data_valid;
  assign mem_read_data = st_fifo_dout;

  // Control logic for FIFO signals
  // register to make one cycle delay between read and write
  always @(clk) begin
    if (reset)
      st_fifo_rd_en <= 1'b0;
    else begin
      if (~st_fifo_empty && ~st_fifo_rd_rst_busy && st_fifo_axi_wr_ready && read_buf_data) begin
        st_fifo_rd_en <= 1'b1;
      end else begin
        st_fifo_rd_en <= 1'b0;
      end
    end
  end

  asymmetric_fifo_xpm #(
   .FIFO_READ_LATENCY     (FIFO_READ_LATENCY  ),
   .FIFO_WRITE_DEPTH      (ST_FIFO_WRITE_DEPTH   ),
   .PROG_EMPTY_THRESH     (ST_PROG_EMPTY_THRESH  ),
   .PROG_FULL_THRESH      (ST_PROG_FULL_THRESH   ),
   .READ_DATA_WIDTH       (ST_READ_DATA_WIDTH    ),
   .WRITE_DATA_WIDTH      (ST_WRITE_DATA_WIDTH   ),
   .FIFO_READ_DEPTH       (ST_FIFO_READ_DEPTH    ),
   .RD_DATA_COUNT_WIDTH   (ST_RD_DATA_COUNT_WIDTH),
   .WR_DATA_COUNT_WIDTH   (ST_WR_DATA_COUNT_WIDTH)
  ) axi_st_fifo (
   .wr_clk        (clk                  ),
   .rst           (reset                ),
   .almost_empty  (st_fifo_almost_empty ),
   .almost_full   (st_fifo_almost_full  ),
   .data_valid    (st_fifo_data_valid   ),
   .dout          (st_fifo_dout         ),
   .empty         (st_fifo_empty        ),
   .full          (st_fifo_full         ),
   .overflow      (st_fifo_overflow     ),
   .prog_empty    (st_fifo_prog_empty   ),
   .prog_full     (st_fifo_prog_full    ),
   .rd_data_count (st_fifo_rd_data_count),
   .rd_rst_busy   (st_fifo_rd_rst_busy  ),
   .underflow     (st_fifo_underflow    ),
   .wr_ack        (st_fifo_wr_ack       ),
   .wr_data_count (st_fifo_wr_data_count),
   .wr_rst_busy   (st_fifo_wr_rst_busy  ),
   .din           (st_fifo_din          ),
   .rd_en         (st_fifo_rd_en        ),
   .sleep         (st_fifo_sleep        ),
   .wr_en         (st_fifo_wr_en        )                                 
  );

//==============================================================================
// AXI4 Memory Mapped interface
//==============================================================================
  assign axi_mem_read_ready = 1'b1;

  assign rd_req_size_coefficient = NUM_SIMD_LANES; // DEBUG
  assign wr_req_size_coefficient = NUM_SIMD_LANES; // DEBUG

  wire                                  split_ld_req_v;
  wire [ AXI_ADDR_WIDTH      -1 : 0 ]       prev_4k_aligned_addr;
  wire [ AXI_ADDR_WIDTH      -1 : 0 ]       next_4k_aligned_addr;        
  wire [ MEM_REQ_W*2     -1 : 0 ]       total_ld_req_size;
  wire [ MEM_REQ_W*2     -1 : 0 ]       total_st_req_size;

  assign total_ld_req_size = ld_req_size * rd_req_size_coefficient; 
  assign prev_4k_aligned_addr = {ld_req_addr[AXI_ADDR_WIDTH-1:12], 12'b0};
  assign next_4k_aligned_addr = prev_4k_aligned_addr + {1,12'b0};
  assign split_ld_req_v = ((total_ld_req_size + ld_req_addr) > next_4k_aligned_addr) && ld_req_valid_q;

  assign axi_rd_req = (ld_req_valid_q);// && ~split_ld_req_v);
  assign axi_rd_req_size = (ld_req_valid_q) ? (ld_req_size * rd_req_size_coefficient) : 0; // DEBUG split_ld_req_v
  assign axi_rd_addr = (ld_req_valid_q) ? ld_req_addr : 0;

  assign total_st_req_size = curr_group_st_config_done ? st_req_size * wr_req_size_coefficient : 'b0;  
  assign axi_wr_req = st_req_valid_q;
  assign axi_wr_req_size = st_req_valid_q ? st_req_size * wr_req_size_coefficient : 'b0;
  assign axi_wr_addr = st_req_valid_q ? st_req_addr : 'b0;

  wire stmem_state_start, stmem_state_done;
  assign stmem_state_start = stmem_state_q == STMEM_GEN_BASE_ADDR && (mws_st_base_vmem1_start_inst_d || mws_st_base_vmem2_start_inst_d);
  assign stmem_state_done = stmem_state_q == STMEM_DONE;

  ddr_memory_interface_control_m_axi_fifo  #(
    .C_XFER_SIZE_WIDTH              ( MEM_REQ_W*2                    ),
    .C_M_AXI_DATA_WIDTH             ( AXI_DATA_WIDTH                 ),
    .C_M_AXI_ADDR_WIDTH             ( AXI_ADDR_WIDTH                 )
  ) u_axi_mm_master (
    .clk                            ( clk                            ),
    .reset                          ( reset                          ),
    .kernel_clk                     ( clk                            ),                    
    .kernel_rst                     ( reset                          ),
    .m_axi_awaddr                   ( mws_awaddr                     ),
    .m_axi_awlen                    ( mws_awlen                      ),
    .m_axi_awvalid                  ( mws_awvalid                    ),
    .m_axi_awready                  ( mws_awready                    ),
    .m_axi_wdata                    ( mws_wdata                      ),
    .m_axi_wstrb                    ( mws_wstrb                      ),
    .m_axi_wlast                    ( mws_wlast                      ),
    .m_axi_wvalid                   ( mws_wvalid                     ),
    .m_axi_wready                   ( mws_wready                     ),
    .m_axi_bvalid                   ( mws_bvalid                     ),
    .m_axi_bready                   ( mws_bready                     ),
    .m_axi_araddr                   ( mws_araddr                     ),
    .m_axi_arlen                    ( mws_arlen                      ),
    .m_axi_arvalid                  ( mws_arvalid                    ),
    .m_axi_arready                  ( mws_arready                    ),
    .m_axi_rdata                    ( mws_rdata                      ),
    .m_axi_rlast                    ( mws_rlast                      ),
    .m_axi_rvalid                   ( mws_rvalid                     ),
    .m_axi_rready                   ( mws_rready                     ),
    
    // Buffer
    .ap_start_rd                    ( axi_rd_req                     ),
    .ap_start_wr                    ( axi_wr_req                     ),
    .ap_done_rd                     ( axi_rd_done                    ),
    .ap_done_wr                     ( axi_wr_done                    ),                   
    
    .ctrl_addr_offset_rd            ( axi_rd_addr                    ),
    .ctrl_xfer_size_in_bytes_rd     ( axi_rd_req_size                ),
    .ctrl_addr_offset_wr            ( axi_wr_addr                    ),
    .ctrl_xfer_size_in_bytes_wr     ( axi_wr_req_size                ),
        
    .rd_tvalid                      ( mem_write_req_fifo             ),
    .rd_tready                      ( mem_write_ready                ),
    .rd_tdata                       ( mem_write_data_fifo            ),
    .rd_tkeep                       (                                ),
    .rd_tlast                       (                                ),
    .rd_addr_arready                ( axi_rd_ready                   ),
    
    .wr_tvalid                      ( axi_wr_data_v                  ),
    .wr_tready                      ( st_fifo_axi_wr_ready           ),
    .wr_tdata                       ( mem_read_data                  ),

    .read_buf_data                  (read_buf_data                   ),
    .req_fifo_full                  (req_fifo_full                   ),
    .rd_req_fifo_full               (rd_req_fifo_full                ),  
    .st_data_fifo_rd_ready          (~st_fifo_empty                  ),
    .stmem_state_start       	      (stmem_state_start       		     ),
    .stmem_state_done        	      (stmem_state_done	     		       )
  );
//==============================================================================


//==============================================================================
// LD/ST VMEM <--> offchip interface
//==============================================================================
  reg  [ GROUP_COUNTER_LD_ST_WIDTH     -1 : 0 ]   simd_ld_group_counter;
  reg  [ VMEM_BUF_ADDR_W               -1 : 0 ]   simd_ld_addr_counter;
  
  reg  [ GROUP_COUNTER_LD_ST_WIDTH     -1 : 0 ]   simd_st_group_counter;
  reg  [ VMEM_BUF_ADDR_W               -1 : 0 ]   simd_st_addr_counter;  
  
  wire [ VMEM_BUF_ADDR_W               -1 : 0 ]   _vmem_write_addr;
  wire [ VMEM_BUF_ADDR_W               -1 : 0 ]   _vmem_read_addr;   
  
  wire [ VMEM_TAG_BUF_ADDR_W           -1 : 0 ]   tag_vmem_write_addr;
  wire [ VMEM_TAG_BUF_ADDR_W           -1 : 0 ]   tag_vmem_read_addr; 
   
  
  wire [ SIMD_LD_ST_HIGH_BW_GROUP_SIZE                    -1: 0]  group_vmem_high_bw_write_req;
  wire [ SIMD_LD_ST_HIGH_BW_GROUP_SIZE                    -1: 0]  group_vmem_high_bw_read_req;
  wire [ SIMD_LD_ST_LOW_BW_GROUP_SIZE                    -1: 0]   group_vmem_low_bw_write_req;
  wire [ SIMD_LD_ST_LOW_BW_GROUP_SIZE                    -1: 0]   group_vmem_low_bw_read_req;
  
  wire                                            vmem_read_req;
  wire                                            vmem_write_req; 
  
  wire                                            simd_ld_high_bw_v;
  wire                                            simd_st_high_bw_v; 
  
  wire [ AXI_DATA_WIDTH                 -1 : 0 ]                  simd_ld_high_bw_data;
  wire [ AXI_DATA_WIDTH                 -1 : 0 ]                  simd_ld_low_bw_data_packed;
  wire [ SIMD_LD_ST_LOW_BW_GROUP_SIZE*SIMD_DATA_WIDTH-1:0]        simd_ld_low_bw_data_unpacked;

  wire [ AXI_DATA_WIDTH                 -1 : 0 ]                  simd_st_high_bw_data;
  reg  [ AXI_DATA_WIDTH                 -1 : 0 ]                  _simd_st_high_bw_data;
  wire [ AXI_DATA_WIDTH                 -1 : 0 ]                  simd_st_low_bw_data_packed;
  reg [ SIMD_LD_ST_LOW_BW_GROUP_SIZE*SIMD_DATA_WIDTH-1:0]        simd_st_low_bw_data_unpacked; // change from wire
  
  reg  [ NUM_SIMD_LANES*SIMD_DATA_WIDTH              -1:0]        _vmem_write_data_out;
  reg  [ NUM_SIMD_LANES*SIMD_DATA_WIDTH              -1:0]        _vmem1_write_data_out;
  reg  [ NUM_SIMD_LANES*SIMD_DATA_WIDTH              -1:0]        _vmem2_write_data_out;  

  wire  [ NUM_SIMD_LANES*VMEM_TAG_BUF_ADDR_W              -1:0]   _vmem_write_addr_out;
  reg  [ NUM_SIMD_LANES*VMEM_TAG_BUF_ADDR_W              -1:0]    _vmem1_write_addr_out;
  reg  [ NUM_SIMD_LANES*VMEM_TAG_BUF_ADDR_W              -1:0]    _vmem2_write_addr_out; 
  
  wire  [ NUM_SIMD_LANES                                  -1:0]    _vmem_write_req_out_high_bw;
  wire  [ NUM_SIMD_LANES                                  -1:0]    _vmem_write_req_out_low_bw;
  wire  [ NUM_SIMD_LANES                                  -1:0]    _vmem_write_req_out;  
  
  reg  [ NUM_SIMD_LANES                                  -1:0]    _vmem1_write_req_out;
  reg  [ NUM_SIMD_LANES                                  -1:0]    _vmem2_write_req_out;  



  reg  [ NUM_SIMD_LANES*SIMD_DATA_WIDTH              -1:0]        _vmem_read_data_in;
  wire [ NUM_SIMD_LANES*SIMD_DATA_WIDTH              -1:0]        _vmem1_read_data_in;
  wire [ NUM_SIMD_LANES*SIMD_DATA_WIDTH              -1:0]        _vmem2_read_data_in;  

  wire [ NUM_SIMD_LANES*VMEM_TAG_BUF_ADDR_W              -1:0]   _vmem_read_addr_out;
  reg  [ NUM_SIMD_LANES*VMEM_TAG_BUF_ADDR_W              -1:0]    _vmem1_read_addr_out;
  reg  [ NUM_SIMD_LANES*VMEM_TAG_BUF_ADDR_W              -1:0]    _vmem2_read_addr_out; 
  
  wire  [ NUM_SIMD_LANES                                  -1:0]    _vmem_read_req_out_high_bw;
  wire  [ NUM_SIMD_LANES                                  -1:0]    _vmem_read_req_out_low_bw;
  wire  [ NUM_SIMD_LANES                                  -1:0]    _vmem_read_req_out;  
  
  reg  [ NUM_SIMD_LANES                                  -1:0]    _vmem1_read_req_out;
  reg  [ NUM_SIMD_LANES                                  -1:0]    _vmem2_read_req_out;  
//==============================================================================

  assign simd_ld_high_bw_v = ld_data_width == SIMD_DATA_WIDTH;
  assign simd_st_high_bw_v = st_data_width == SIMD_DATA_WIDTH;

//==============================================================================
// Logic For Writing to Vmem    
//==============================================================================
  always @(posedge clk) begin
      if (reset)
          simd_ld_group_counter <= 0;
      else if (mem_write_req) begin
          if (simd_ld_high_bw_v && (simd_ld_group_counter == SIMD_LD_ST_HIGH_BW_NUM_GROUPS - 1 || SIMD_LD_ST_HIGH_BW_NUM_GROUPS == 0))
              simd_ld_group_counter <= 0;
          else if (~simd_ld_high_bw_v && (simd_ld_group_counter == SIMD_LD_ST_LOW_BW_NUM_GROUPS - 1 || SIMD_LD_ST_HIGH_BW_NUM_GROUPS == 0))
              simd_ld_group_counter <= 0;
          else
              simd_ld_group_counter <= simd_ld_group_counter + 1'b1;
      end
  end

  always @(posedge clk) begin
      if (reset)
          simd_ld_addr_counter <= 0;
      else if (cfg_ns_ld_start_addr) begin
          simd_ld_addr_counter <= on_chip_ld_start_addr;
      end else begin 
          if (mem_write_req) begin
             if (simd_ld_high_bw_v && simd_ld_group_counter == SIMD_LD_ST_HIGH_BW_NUM_GROUPS - 1)
                 simd_ld_addr_counter <= simd_ld_addr_counter + 1'b1;
             else if (~simd_ld_high_bw_v && simd_ld_group_counter == SIMD_LD_ST_LOW_BW_NUM_GROUPS - 1 )
                 simd_ld_addr_counter <= simd_ld_addr_counter + 1'b1;
          end  
          else if (ldmem_state_q == LDMEM_DONE)
            simd_ld_addr_counter <= 0;
      end
  end

  assign simd_ld_high_bw_data = mem_write_data;
  assign simd_ld_low_bw_data_packed = mem_write_data;
  
  genvar i;
  generate
      for (i=0; i<SIMD_LD_ST_LOW_BW_GROUP_SIZE; i=i+1) begin
          wire [LD_ST_LOW_DATA_WIDTH   -1:0]   local_data;
          wire [SIMD_DATA_WIDTH        -1:0]   local_sign_ext_data;
          
          assign local_data = simd_ld_low_bw_data_packed[(i+1)*LD_ST_LOW_DATA_WIDTH-1:i*LD_ST_LOW_DATA_WIDTH];
          assign local_sign_ext_data = {{SIMD_DATA_WIDTH-LD_ST_LOW_DATA_WIDTH{local_data[LD_ST_DATA_WIDTH-1]}},local_data}; 
          assign simd_ld_low_bw_data_unpacked[(i+1)*SIMD_DATA_WIDTH-1:i*SIMD_DATA_WIDTH] = local_sign_ext_data;
      end     
  endgenerate
  
  
  wire  [NUM_SIMD_LANES*SIMD_DATA_WIDTH     -1:0]  _vmem_write_data_out_low_bw;
  wire  [NUM_SIMD_LANES*SIMD_DATA_WIDTH     -1:0]  _vmem_write_data_out_high_bw;  

  generate
     for (i=0; i<SIMD_LD_ST_LOW_BW_NUM_GROUPS; i=i+1) begin
         assign _vmem_write_data_out_low_bw[(i+1)*SIMD_LD_ST_LOW_BW_GROUP_SIZE*SIMD_DATA_WIDTH-1:i*SIMD_LD_ST_LOW_BW_GROUP_SIZE*SIMD_DATA_WIDTH] = simd_ld_low_bw_data_unpacked;
     end 
 endgenerate
 
 generate
     for (i=0; i<SIMD_LD_ST_HIGH_BW_NUM_GROUPS; i=i+1) begin
         assign _vmem_write_data_out_high_bw[(i+1)*SIMD_LD_ST_HIGH_BW_GROUP_SIZE*SIMD_DATA_WIDTH-1:i*SIMD_LD_ST_HIGH_BW_GROUP_SIZE*SIMD_DATA_WIDTH] = simd_ld_high_bw_data;
     end 
 endgenerate 
 
 always @(*) begin
    if (simd_ld_high_bw_v) 
        _vmem_write_data_out = _vmem_write_data_out_high_bw;
    else
        _vmem_write_data_out = _vmem_write_data_out_low_bw;
 end 

 
  always @(*) begin
     if (_ldmem_ns_id == NS_VMEM_1) 
        _vmem1_write_data_out = _vmem_write_data_out;
     else if (_ldmem_ns_id == NS_VMEM_2)
        _vmem2_write_data_out = _vmem_write_data_out; 
  end
  
  assign vmem1_write_data = _vmem1_write_data_out;
  assign vmem2_write_data = _vmem2_write_data_out;
//

 // Assign Write addr out
  assign _vmem_write_addr = simd_ld_addr_counter;
  // For now, there is no tag
  assign tag_vmem_write_addr = _vmem_write_addr;
  

  genvar j;
  generate
      for (j=0; j<NUM_SIMD_LANES; j=j+1) begin
          assign _vmem_write_addr_out[(j+1)*VMEM_TAG_BUF_ADDR_W-1: j*VMEM_TAG_BUF_ADDR_W] = tag_vmem_write_addr;         
      end
  endgenerate

  always @(*) begin
     if (_ldmem_ns_id == NS_VMEM_1) 
        _vmem1_write_addr_out = _vmem_write_addr_out;
     else if (_ldmem_ns_id == NS_VMEM_2)
        _vmem2_write_addr_out = _vmem_write_addr_out; 
  end

  assign vmem1_write_addr = _vmem1_write_addr_out;
  assign vmem2_write_addr = _vmem2_write_addr_out;

// Assign Write Req 
  assign vmem_write_req = mem_write_req;
 
  genvar l;
  generate
      for (l=0; l<SIMD_LD_ST_LOW_BW_GROUP_SIZE; l=l+1) begin
          assign group_vmem_low_bw_write_req[l] = vmem_write_req;         
      end
  endgenerate

  genvar m;
  generate
      for (m=0; m<SIMD_LD_ST_HIGH_BW_GROUP_SIZE; m=m+1) begin
          assign group_vmem_high_bw_write_req[m] = vmem_write_req;         
      end
  endgenerate
  
  genvar n;
  generate
      for (n=0; n<SIMD_LD_ST_HIGH_BW_NUM_GROUPS; n=n+1) begin
         assign _vmem_write_req_out_high_bw[(n+1)*SIMD_LD_ST_HIGH_BW_GROUP_SIZE-1:n*SIMD_LD_ST_HIGH_BW_GROUP_SIZE] = (simd_ld_group_counter == n) ? group_vmem_high_bw_write_req : 0;
      end      
  endgenerate
  
  generate
      for (n=0; n<SIMD_LD_ST_LOW_BW_NUM_GROUPS; n=n+1) begin
         assign _vmem_write_req_out_low_bw[(n+1)*SIMD_LD_ST_LOW_BW_GROUP_SIZE-1:n*SIMD_LD_ST_LOW_BW_GROUP_SIZE] = (simd_ld_group_counter == n) ? group_vmem_low_bw_write_req : 0;
      end      
  endgenerate

  assign _vmem_write_req_out = (SIMD_LD_ST_HIGH_BW_NUM_GROUPS == 0) ? {NUM_SIMD_LANES{vmem_write_req}} : (simd_ld_high_bw_v ? _vmem_write_req_out_high_bw : _vmem_write_req_out_low_bw);
  
  always @(*) begin
     if (_ldmem_ns_id == NS_VMEM_1) begin
         _vmem1_write_req_out = _vmem_write_req_out;
         _vmem2_write_req_out = 0;
     end
     else if (_ldmem_ns_id == NS_VMEM_2) begin
         _vmem1_write_req_out = 0;
         _vmem2_write_req_out = _vmem_write_req_out;
     end
  end

  assign vmem1_write_req = _vmem1_write_req_out;
  assign vmem2_write_req = _vmem2_write_req_out;
  
// ************************************************************ //

//==============================================================================
// Logic For Reading From Vmem    
//==============================================================================
  reg buf_read_state_q, buf_read_state_qq;
  reg buf_read_done;

  reg [ MEM_REQ_W-1 : 0 ] st_buf_read_en_cntr;
  wire st_buf_read_en;
  always @(posedge clk) begin
    if (reset || stmem_state_q == STMEM_DONE)
      st_buf_read_en_cntr <= 'b0;
    else begin // because in the same cycle, st_addr_v might be asserted and we can still read the buffer
      if (st_addr_v && (st_buf_read_en_cntr > 0) && ~st_fifo_prog_full)
        st_buf_read_en_cntr <= st_buf_read_en_cntr + (total_st_req_size/AXI_DATA_WIDTH_BYTES) - 1'b1;
      else if (st_buf_read_en_cntr > 0 && ~st_fifo_prog_full)
        st_buf_read_en_cntr <= st_buf_read_en_cntr - 1'b1;
      else if (st_addr_v)
        st_buf_read_en_cntr <= st_buf_read_en_cntr + (total_st_req_size/AXI_DATA_WIDTH_BYTES);
    end
  end

  assign st_buf_read_en = ~st_fifo_prog_full ? |st_buf_read_en_cntr : 1'b0; // DEBUG

  always @(*) begin
    if (simd_st_high_bw_v) begin
      buf_read_done = simd_st_group_counter == (SIMD_LD_ST_HIGH_BW_NUM_GROUPS - 1) && (simd_st_addr_counter == (st_req_size-1));
    end else begin
      buf_read_done = simd_st_group_counter == (SIMD_LD_ST_LOW_BW_NUM_GROUPS - 1) && (simd_st_addr_counter == (st_req_size-1));
    end
  end

  always @(posedge clk) begin
    if (reset)
      buf_read_state_q <= 1'b0;
    else if (st_req_valid_q) 
      buf_read_state_q <= 1'b1;
    else if (buf_read_done)
      buf_read_state_q <= 1'b0;
  end

  always @(posedge clk) begin  
    if (reset)
      buf_read_state_qq <= 1'b0;
    else 
      buf_read_state_qq <= buf_read_state_q;
  end

  always @(posedge clk) begin
      if (reset)
        simd_st_group_counter <= 0;
      else if (axi_mem_read_req) begin
          if (simd_st_high_bw_v && simd_st_group_counter == SIMD_LD_ST_HIGH_BW_NUM_GROUPS -1)
            simd_st_group_counter <= 0;
          else if (~simd_st_high_bw_v && simd_st_group_counter == SIMD_LD_ST_LOW_BW_NUM_GROUPS-1)
            simd_st_group_counter <= 0;
          else
            simd_st_group_counter <= simd_st_group_counter + 1'b1;
      end
  end

  wire [ GROUP_COUNTER_LD_ST_WIDTH      -1 : 0 ] simd_st_group_counter_delayed;
  register_sync #(GROUP_COUNTER_LD_ST_WIDTH) simd_st_group_counter_reg (clk, reset, simd_st_group_counter, simd_st_group_counter_delayed);
  
  always @(posedge clk) begin
      if (reset) begin
          simd_st_addr_counter <= 0;
      end else if (cfg_ns_st_start_addr) begin
          simd_st_addr_counter <= on_chip_st_start_addr;
      end else begin 
          if (axi_mem_read_req) begin
            if (simd_st_high_bw_v && simd_st_group_counter == SIMD_LD_ST_HIGH_BW_NUM_GROUPS - 1)
              simd_st_addr_counter <= simd_st_addr_counter + 1'b1;
            else if (~simd_st_high_bw_v && simd_st_group_counter == SIMD_LD_ST_LOW_BW_NUM_GROUPS - 1)
              simd_st_addr_counter <= simd_st_addr_counter + 1'b1;
          end else if (~buf_read_state_q && buf_read_state_qq)
            simd_st_addr_counter <= simd_st_addr_counter;
          else if (stmem_state_q == STMEM_DONE)
            simd_st_addr_counter <= 0; // DEBUG
      end
  end

  assign axi_mem_read_req = st_buf_read_en;
  register_sync #(1) axi_wr_data_v_reg (clk, reset, axi_mem_read_req, st_fifo_axi_wr_data_v);

  always @(*) begin
    if (_stmem_ns_id == NS_VMEM_1) 
      st_fifo_mem_read_data = _vmem1_read_data_in[(simd_st_group_counter_delayed)*AXI_DATA_WIDTH+:(AXI_DATA_WIDTH)]; // DEBUG
    else if (_stmem_ns_id == NS_VMEM_2)
      st_fifo_mem_read_data = _vmem2_read_data_in[(simd_st_group_counter_delayed)*AXI_DATA_WIDTH+:(AXI_DATA_WIDTH)]; // DEBUG
  end
  
  // --------------------------- DEBUG ------------------------- //
  // --------------------------- DEBUG ------------------------- //
  // --------------------------- DEBUG ------------------------- //
  wire [31:0] data_test[63:0];
  generate
    for (i=0; i < NUM_SIMD_LANES; i=i+1) begin
      assign data_test[i] = vmem1_read_data[(i+1)*32-1:i*32];
    end
  endgenerate
  
  // --------------------------- DEBUG ------------------------- //
  // --------------------------- DEBUG ------------------------- //
  // --------------------------- DEBUG ------------------------- //
  assign _vmem1_read_data_in = vmem1_read_data;
  assign _vmem2_read_data_in = vmem2_read_data;

  // Assign Vmem Read addr out
  assign _vmem_read_addr = simd_st_addr_counter;
  assign tag_vmem_read_addr = _vmem_read_addr;
  
  generate
      for (i=0; i<NUM_SIMD_LANES; i=i+1) begin
          assign _vmem_read_addr_out[(i+1)*VMEM_TAG_BUF_ADDR_W-1:i*VMEM_TAG_BUF_ADDR_W] = tag_vmem_read_addr;
       end
  endgenerate

  always @(*) begin
     if (_stmem_ns_id == NS_VMEM_1) 
        _vmem1_read_addr_out = _vmem_read_addr_out;
     else if (_stmem_ns_id == NS_VMEM_2)
        _vmem2_read_addr_out = _vmem_read_addr_out; 
  end

  assign vmem1_read_addr = _vmem1_read_addr_out;
  assign vmem2_read_addr = _vmem2_read_addr_out ;

  // Assign Vmem Read Req 
  assign vmem_read_req = axi_mem_read_req;
 
  generate
      for (l=0; l<SIMD_LD_ST_LOW_BW_GROUP_SIZE; l=l+1) begin
          assign group_vmem_low_bw_read_req[l] = vmem_read_req;         
      end
  endgenerate

  generate
      for (m=0; m<SIMD_LD_ST_HIGH_BW_GROUP_SIZE; m=m+1) begin
          assign group_vmem_high_bw_read_req[m] = vmem_read_req;         
      end
  endgenerate

  generate
      for (n=0; n<SIMD_LD_ST_HIGH_BW_NUM_GROUPS; n=n+1) begin
         assign _vmem_read_req_out_high_bw[(n+1)*SIMD_LD_ST_HIGH_BW_GROUP_SIZE-1:n*SIMD_LD_ST_HIGH_BW_GROUP_SIZE] = (simd_st_group_counter == n) ? group_vmem_high_bw_read_req : 0;
      end      
  endgenerate
  
  generate
      for (n=0; n<SIMD_LD_ST_LOW_BW_NUM_GROUPS; n=n+1) begin
         assign _vmem_read_req_out_low_bw[(n+1)*SIMD_LD_ST_LOW_BW_GROUP_SIZE-1:n*SIMD_LD_ST_LOW_BW_GROUP_SIZE] = (simd_st_group_counter == n) ? group_vmem_low_bw_read_req : 0;
      end      
  endgenerate

  assign _vmem_read_req_out = simd_st_high_bw_v ? _vmem_read_req_out_high_bw : _vmem_read_req_out_low_bw;
  
  always @(*) begin
     if (_stmem_ns_id == NS_VMEM_1) begin
         _vmem1_read_req_out = _vmem_read_req_out;
         _vmem2_read_req_out = 0;
     end
     else if (_stmem_ns_id == NS_VMEM_2) begin
         _vmem1_read_req_out = 0;
         _vmem2_read_req_out = _vmem_read_req_out;
     end
  end

  assign vmem1_read_req = _vmem1_read_req_out;
  assign vmem2_read_req = _vmem2_read_req_out;
//==============================================================================

// Performance Counter
// ld
wire pc_simd_ld_num_tiles_vmem1_en, pc_simd_ld_num_tiles_vmem2_en;
wire pc_simd_ld_tot_cycles_en_vmem1, pc_simd_ld_tot_cycles_en_vmem2;
wire pc_simd_ld_tot_requests_en_vmem1, pc_simd_ld_tot_requests_en_vmem2;
wire pc_simd_ld_size_per_requests_en;

assign pc_simd_ld_num_tiles_vmem1_en = mws_ld_tile_vmem1_start;
assign pc_simd_ld_num_tiles_vmem2_en = mws_ld_tile_vmem2_start;
assign pc_simd_ld_tot_cycles_en_vmem1 = ldmem_state_q == LDMEM_TILE_BUSY_NS_VMEM1;
assign pc_simd_ld_tot_cycles_en_vmem2 = ldmem_state_q == LDMEM_TILE_BUSY_NS_VMEM2;
assign pc_simd_ld_tot_requests_en_vmem1 = mws_ld_tile_addr_out_vmem1_v;
assign pc_simd_ld_tot_requests_en_vmem2 = mws_ld_tile_addr_out_vmem2_v;
assign pc_simd_ld_size_per_requests_en_vmem1 = mws_ld_tile_addr_out_vmem1_v;
assign pc_simd_ld_size_per_requests_en_vmem2 = mws_ld_tile_addr_out_vmem2_v;

// Number of Tiles
perf_counter #(
    .DATA_WIDTH (PC_DATA_WIDTH)
) pc_ld_num_tiles1 (
    .clk (clk),
    .en (pc_simd_ld_num_tiles_vmem1_en),
    .rst (reset),
    .out (pc_simd_ld_num_tiles_vmem1)
);

perf_counter #(
    .DATA_WIDTH (PC_DATA_WIDTH)
) pc_ld_num_tiles2 (
    .clk (clk),
    .en (pc_simd_ld_num_tiles_vmem2_en),
    .rst (reset),
    .out (pc_simd_ld_num_tiles_vmem2)
);

// obuf total cycles
perf_counter #(
    .DATA_WIDTH (PC_DATA_WIDTH)
) pc_ld_tot_cycles_vmem1 (
    .clk (clk),
    .en (pc_simd_ld_tot_cycles_en_vmem1),
    .rst (reset),
    .out (pc_simd_ld_tot_cycles_vmem1)
);

// obuf total cycles
perf_counter #(
    .DATA_WIDTH (PC_DATA_WIDTH)
) pc_ld_tot_cycles_vmem2 (
    .clk (clk),
    .en (pc_simd_ld_tot_cycles_en_vmem2),
    .rst (reset),
    .out (pc_simd_ld_tot_cycles_vmem2)
);

// obuf total requests
perf_counter #(
    .DATA_WIDTH (PC_DATA_WIDTH)
) pc_ld_tot_requests_vmem1 (
    .clk (clk),
    .en (pc_simd_ld_tot_requests_en_vmem1),
    .rst (reset),
    .out (pc_simd_ld_tot_requests_vmem1)
);

// obuf total requests
perf_counter #(
    .DATA_WIDTH (PC_DATA_WIDTH)
) pc_ld_tot_requests_vmem2 (
    .clk (clk),
    .en (pc_simd_ld_tot_requests_en_vmem2),
    .rst (reset),
    .out (pc_simd_ld_tot_requests_vmem2)
);

// obuf size per request
perf_counter #(
    .DATA_WIDTH (PC_DATA_WIDTH),
    .STEP(0),
    .STEP_BITWIDTH(MEM_REQ_W*2)
) pc_ld_size_per_req_vmem1 (
    .clk  (clk),
    .en   (pc_simd_ld_size_per_requests_en_vmem1),
    .rst  (reset),
    .step (axi_rd_req_size),
    .out  (pc_simd_ld_size_per_requests_vmem1)
);

// obuf size per request
perf_counter #(
    .DATA_WIDTH (PC_DATA_WIDTH),
    .STEP(0),
    .STEP_BITWIDTH(MEM_REQ_W*2)
) pc_ld_size_per_req_vmem2 (
    .clk  (clk),
    .en   (pc_simd_ld_size_per_requests_en_vmem2),
    .rst  (reset),
    .step (axi_rd_req_size),
    .out  (pc_simd_ld_size_per_requests_vmem2)
);

// st
wire pc_simd_st_num_tiles_vmem1_en, pc_simd_st_num_tiles_vmem2_en;
wire pc_simd_st_tot_cycles_en, pc_simd_st_tot_requests_en, pc_simd_st_size_per_requests_en;

assign pc_simd_st_num_tiles_vmem1_en = mws_st_tile_vmem1_start;
assign pc_simd_st_num_tiles_vmem2_en = mws_st_tile_vmem2_start;
assign pc_simd_st_tot_cycles_en = (stmem_state_q == STMEM_TILE_BUSY_NS_VMEM1 || stmem_state_q == STMEM_TILE_BUSY_NS_VMEM2);
assign pc_simd_st_tot_requests_en = st_addr_v;
assign pc_simd_st_size_per_requests_en = st_req_valid_q;

// Number of Tiles
perf_counter #(
    .DATA_WIDTH (PC_DATA_WIDTH)
) pc_st_num_tiles1 (
    .clk (clk),
    .en (pc_simd_st_num_tiles_vmem1_en),
    .rst (reset),
    .out (pc_simd_st_num_tiles_vmem1)
);

perf_counter #(
    .DATA_WIDTH (PC_DATA_WIDTH)
) pc_st_num_tiles2 (
    .clk (clk),
    .en (pc_simd_st_num_tiles_vmem2_en),
    .rst (reset),
    .out (pc_simd_st_num_tiles_vmem2)
);

// obuf total cycles
perf_counter #(
    .DATA_WIDTH (PC_DATA_WIDTH)
) pc_st_tot_cycles (
    .clk (clk),
    .en (pc_simd_st_tot_cycles_en),
    .rst (reset),
    .out (pc_simd_st_tot_cycles)
);

// obuf total requests
perf_counter #(
    .DATA_WIDTH (PC_DATA_WIDTH)
) pc_st_tot_requests (
    .clk (clk),
    .en (pc_simd_st_tot_requests_en),
    .rst (reset),
    .out (pc_simd_st_tot_requests)
);

// obuf size per request
perf_counter #(
    .DATA_WIDTH (PC_DATA_WIDTH),
    .STEP(0),
    .STEP_BITWIDTH (MEM_REQ_W*2)
) pc_st_size_per_req (
    .clk (clk),
    .en (pc_simd_st_size_per_requests_en),
    .rst (reset),
    .step(axi_wr_req_size),
    .out (pc_simd_st_size_per_requests)
);

/*
  ila_0 simd_ila (
  .clk(clk),
  // 1 bit width
  .probe0(mws_st_base_addr_out_vmem2_v),
  .probe1(0),
  .probe2(0),
  .probe3(0),
  .probe4(0),
  .probe5(0),
  // 8 bit width
  .probe6(stmem_state_q),
  .probe7(),
  .probe8(),
  .probe9(),
  .probe10(),
  // 32 bit width
  .probe11(0),
  .probe12(0),
  .probe13(0),
  .probe14(0),
  .probe15(0),
  .probe16(0),
  .probe17(0),
  .probe18(0),
  .probe19(0)
  );
*/

endmodule
