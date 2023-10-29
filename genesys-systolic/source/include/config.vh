parameter integer  NUM_TAGS                     = 2;
parameter integer  TAG_W                        = $clog2(NUM_TAGS);
parameter integer  TAG_REUSE_COUNTER_W          = 7;
parameter integer  ADDR_WIDTH                   = 64;
//parameter integer  ARRAY_N                      = 16;
//parameter integer  ARRAY_M                      = 16;
// Precision
//parameter integer  DATA_WIDTH                   = 4;
//parameter integer  BIAS_WIDTH                   = 32;
//parameter integer  ACC_WIDTH                    = 32;
// Buffers
//parameter integer  IBUF_CAPACITY_BITS           = 131072;
//parameter integer  WBUF_CAPACITY_BITS           = 131072;
//parameter integer  OBUF_CAPACITY_BITS           = 524288*2;
//parameter integer  BBUF_CAPACITY_BITS           = 16384;


//////////////// From Compiler 
parameter integer  BBUF_DEPTH                   = 1024;
parameter integer  IBUF_DEPTH                   = 2048;
parameter integer  OBUF_DEPTH                   = 2048;
parameter integer  WBUF_DEPTH                   = 4096;
parameter integer  ARRAY_N                      = 64;
parameter integer  ARRAY_M                      = 64;
parameter integer  INSTR_DEPTH                  = 1024;
// Precision
parameter integer  DATA_WIDTH                   = 8;
parameter integer  BIAS_WIDTH                   = 32;
parameter integer  ACC_WIDTH                    = 32;
// Buffers
parameter integer  IBUF_CAPACITY_BITS           = ARRAY_M * DATA_WIDTH * IBUF_DEPTH;
parameter integer  WBUF_CAPACITY_BITS           = ARRAY_N * ARRAY_M * DATA_WIDTH * WBUF_DEPTH;
parameter integer  OBUF_CAPACITY_BITS           = ARRAY_N * ACC_WIDTH * OBUF_DEPTH * 2;
parameter integer  BBUF_CAPACITY_BITS           = ARRAY_M * ACC_WIDTH * BBUF_DEPTH;
////////////////////////////////////


// Buffer Addr Width
parameter integer  IBUF_TAG_ADDR_WIDTH          = $clog2(IBUF_CAPACITY_BITS / ARRAY_N / DATA_WIDTH);
parameter integer  OBUF_TAG_ADDR_WIDTH          = $clog2(OBUF_CAPACITY_BITS / ARRAY_M / ACC_WIDTH);
parameter integer  WBUF_TAG_ADDR_WIDTH          = $clog2(WBUF_CAPACITY_BITS / ARRAY_N / ARRAY_M / DATA_WIDTH);
parameter integer  BBUF_TAG_ADDR_WIDTH          = $clog2(BBUF_CAPACITY_BITS / ARRAY_M / BIAS_WIDTH);
parameter integer  IBUF_ADDR_WIDTH              = IBUF_TAG_ADDR_WIDTH - TAG_W;
parameter integer  WBUF_ADDR_WIDTH              = WBUF_TAG_ADDR_WIDTH - TAG_W;
parameter integer  OBUF_ADDR_WIDTH              = OBUF_TAG_ADDR_WIDTH - TAG_W;
parameter integer  BBUF_ADDR_WIDTH              = BBUF_TAG_ADDR_WIDTH - TAG_W;
parameter integer  WBUF_REQ_WIDTH               = $clog2(ARRAY_M) + 1;
// Instructions
parameter integer  INST_DATA_WIDTH              = 32;
parameter integer  INST_MEM_CAPACITY_BITS       = INSTR_DEPTH * INST_DATA_WIDTH;
parameter integer  INST_MEM_ADDR_WIDTH          = $clog2(INST_MEM_CAPACITY_BITS / INST_DATA_WIDTH);
parameter integer  BUF_TYPE_W                   = 2;
parameter integer  IMM_WIDTH                    = 16;
parameter integer  OP_CODE_W                    = 4;
parameter integer  OP_SPEC_W                    = 6;
parameter integer  LOOP_ID_W                    = 6;
parameter integer  INST_GROUP_ID_W              = 4;
parameter integer  LOOP_ITER_W                  = IMM_WIDTH;
parameter integer  ADDR_STRIDE_W                = 2*IMM_WIDTH;
parameter integer  MEM_REQ_W                    = IMM_WIDTH;
parameter integer  GROUP_ENABLED                = 0;
// AXI Params
parameter integer  AXI_ADDR_WIDTH               = C_M00_IMEM_AXI_ADDR_WIDTH;
parameter integer  AXI_ID_WIDTH                 = 1;
parameter integer  AXI_BURST_WIDTH              = 8;
// INST MEM AXI Params
parameter integer INST_MEM_AXI_DATA_WIDTH       = C_M00_IMEM_AXI_DATA_WIDTH;
parameter integer INST_WSTRB_WIDTH              = INST_MEM_AXI_DATA_WIDTH / 8;
// IBUF AXI Params
parameter integer IBUF_AXI_DATA_WIDTH           = C_M02_IBUF_AXI_DATA_WIDTH;
parameter integer IBUF_WSTRB_WIDTH              = IBUF_AXI_DATA_WIDTH / 8;
// Prambauf AXI Params
parameter integer PARAMBUF_AXI_DATA_WIDTH       = C_M01_PARAMBUF_AXI_DATA_WIDTH;
parameter integer PARAMBUF_WSTRB_WIDTH          = PARAMBUF_AXI_DATA_WIDTH / 8;
// OBUF AXI Params
parameter integer OBUF_AXI_DATA_WIDTH           = C_M03_OBUF_AXI_DATA_WIDTH;
parameter integer OBUF_WSTRB_WIDTH              = OBUF_AXI_DATA_WIDTH / 8;
// AXI-Lite
parameter integer  CTRL_ADDR_WIDTH              = C_S_AXI_CONTROL_ADDR_WIDTH;
parameter integer  CTRL_DATA_WIDTH              = C_S_AXI_CONTROL_DATA_WIDTH;
parameter integer  CTRL_WSTRB_WIDTH             = CTRL_DATA_WIDTH/8;