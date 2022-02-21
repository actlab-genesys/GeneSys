//
// GeneSys Top Module
//
`timescale 1ns/1ps

module genesys_top_module #(
    parameter integer  NUM_TAGS                     = 2,
    parameter integer  TAG_W                        = $clog2(NUM_TAGS),
    parameter integer  TAG_REUSE_COUNTER_W          = 7,
    parameter integer  ADDR_WIDTH                   = 42,
    parameter integer  ARRAY_N                      = 16,
    parameter integer  ARRAY_M                      = 16,

  // Precision
    parameter integer  DATA_WIDTH                   = 4,
    parameter integer  BIAS_WIDTH                   = 32,
    parameter integer  ACC_WIDTH                    = 32,
  // Buffers
    parameter integer  IBUF_CAPACITY_BITS           = 131072,
    parameter integer  WBUF_CAPACITY_BITS           = 131072,
    parameter integer  OBUF_CAPACITY_BITS           = 524288*2,
    parameter integer  BBUF_CAPACITY_BITS           = 16384,

    // IBUF
    parameter integer IBUF_BANK_DEPTH               = 2048,
    parameter integer IBUF_READ_LATENCY_B           = 1,

    // WBUF
    parameter integer  WBUF_BANK_DEPTH              = 4096, 
    parameter integer  WBUF_READ_WIDTH              = 8,
    parameter integer  WBUF_READ_LATENCY_B          = 1,
  
    // BBUF
    parameter integer  BBUF_BANK_DEPTH              = 2048, 
    parameter integer  BBUF_READ_WIDTH              = BIAS_WIDTH,
    parameter integer  BBUF_READ_LATENCY_B          = 1,

    // OBUF
    parameter integer OBUF_BANK_DEPTH               = 2048,
    parameter integer OBUF_READ_LATENCY_B           = 1,
  
  // Instructions
    parameter integer  INST_DATA_WIDTH              = 32,
    parameter integer  INST_MEM_CAPACITY_BITS       = 8192,
    parameter integer  INST_MEM_ADDR_WIDTH          = $clog2(INST_MEM_CAPACITY_BITS / INST_DATA_WIDTH),
    parameter integer  BUF_TYPE_W                   = 2,
    parameter integer  IMM_WIDTH                    = 16,
    parameter integer  OP_CODE_W                    = 4,
    parameter integer  OP_SPEC_W                    = 6,
    parameter integer  LOOP_ID_W                    = 6,
    parameter integer  INST_GROUP_ID_W              = 4,
    parameter integer  LOOP_ITER_W                  = IMM_WIDTH,
    parameter integer  ADDR_STRIDE_W                = 2*IMM_WIDTH,
    parameter integer  MEM_REQ_W                    = IMM_WIDTH,
    parameter integer  GROUP_ENABLED                = 0,
    // AXI Params
    parameter integer  AXI_ADDR_WIDTH               = ADDR_WIDTH,
    parameter integer  AXI_ID_WIDTH                 = 1,
    parameter integer  AXI_BURST_WIDTH              = 8,
    // INST MEM AXI Params
    parameter integer INST_MEM_AXI_DATA_WIDTH       = 64,
    parameter integer INST_WSTRB_WIDTH              = INST_MEM_AXI_DATA_WIDTH / 8,
    // IBUF AXI Params
    parameter integer IBUF_AXI_DATA_WIDTH           = 128,
    parameter integer IBUF_WSTRB_WIDTH              = IBUF_AXI_DATA_WIDTH / 8,
    // Prambauf AXI Params
    parameter integer PARAMBUF_AXI_DATA_WIDTH       = 64,
    parameter integer PARAMBUF_WSTRB_WIDTH          = PARAMBUF_AXI_DATA_WIDTH / 8,
    // OBUF AXI Params
    parameter integer OBUF_AXI_DATA_WIDTH           = 128,
    parameter integer OBUF_WSTRB_WIDTH              = OBUF_AXI_DATA_WIDTH / 8,
    // AXI-Lite
    parameter integer  CTRL_ADDR_WIDTH              = 32,
    parameter integer  CTRL_DATA_WIDTH              = 32,
    parameter integer  CTRL_WSTRB_WIDTH             = CTRL_DATA_WIDTH/8,
    parameter integer  COMPUTE_DONE_DELAY_CYCLES    = $clog2(ARRAY_M) + 1


)(
    input  wire                                         clk,
    input  wire                                         reset,


  // AXI4-Lite interface
    // Slave Write address
    input  wire                                         pci_cl_ctrl_awvalid,
    input  wire  [ CTRL_ADDR_WIDTH      -1 : 0 ]        pci_cl_ctrl_awaddr,
    output wire                                         pci_cl_ctrl_awready,
    // Slave Write data
    input  wire                                         pci_cl_ctrl_wvalid,
    input  wire  [ CTRL_DATA_WIDTH      -1 : 0 ]        pci_cl_ctrl_wdata,
    input  wire  [ CTRL_WSTRB_WIDTH     -1 : 0 ]        pci_cl_ctrl_wstrb,
    output wire                                         pci_cl_ctrl_wready,
    // Slave Write response
    output wire                                         pci_cl_ctrl_bvalid,
    output wire  [ 2                    -1 : 0 ]        pci_cl_ctrl_bresp,
    input  wire                                         pci_cl_ctrl_bready,
    // Slave Read address
    input  wire                                         pci_cl_ctrl_arvalid,
    input  wire  [ CTRL_ADDR_WIDTH      -1 : 0 ]        pci_cl_ctrl_araddr,
    output wire                                         pci_cl_ctrl_arready,
    // Slave Read data/response
    output wire                                         pci_cl_ctrl_rvalid,
    output wire  [ CTRL_DATA_WIDTH      -1 : 0 ]        pci_cl_ctrl_rdata,
    output wire  [ 2                    -1 : 0 ]        pci_cl_ctrl_rresp,
    input  wire                                         pci_cl_ctrl_rready,

  // AXI4 interface
    // Master Interface for Instrucion Memory
    output wire  [ ADDR_WIDTH           -1 : 0 ]        imem_awaddr,
    output wire  [ AXI_BURST_WIDTH      -1 : 0 ]        imem_awlen,
    output wire  [ 3                    -1 : 0 ]        imem_awsize,
    output wire  [ 2                    -1 : 0 ]        imem_awburst,
    output wire                                         imem_awvalid,
    input  wire                                         imem_awready,
    // Master Interface Write Data
    output wire  [ INST_MEM_AXI_DATA_WIDTH-1 : 0 ]      imem_wdata,
    output wire  [ INST_WSTRB_WIDTH     -1 : 0 ]        imem_wstrb,
    output wire                                         imem_wlast,
    output wire                                         imem_wvalid,
    input  wire                                         imem_wready,
    // Master Interface Write Response
    input  wire  [ 2                    -1 : 0 ]        imem_bresp,
    input  wire                                         imem_bvalid,
    output wire                                         imem_bready,
    // Master Interface Read Address
    output wire  [ ADDR_WIDTH           -1 : 0 ]        imem_araddr,
    output wire  [ AXI_BURST_WIDTH      -1 : 0 ]        imem_arlen,
    output wire  [ 3                    -1 : 0 ]        imem_arsize,
    output wire  [ 2                    -1 : 0 ]        imem_arburst,
    output wire                                         imem_arvalid,
    output wire  [ AXI_ID_WIDTH         -1 : 0 ]        imem_arid,
    input  wire                                         imem_arready,
    // Master Interface Read Data
    input  wire  [ INST_MEM_AXI_DATA_WIDTH-1 : 0 ]      imem_rdata,
    input  wire  [ 2                    -1 : 0 ]        imem_rresp,
    input  wire                                         imem_rlast,
    input  wire                                         imem_rvalid,
    input  wire  [ AXI_ID_WIDTH         -1 : 0 ]        imem_rid,
    output wire                                         imem_rready,

    // AXI Interface
    // Master Interface for Parambuf
    output wire  [ AXI_ADDR_WIDTH       -1 : 0 ]        parambuf_awaddr,
    output wire  [ AXI_BURST_WIDTH      -1 : 0 ]        parambuf_awlen,
    output wire  [ 3                    -1 : 0 ]        parambuf_awsize,
    output wire  [ 2                    -1 : 0 ]        parambuf_awburst,
    output wire                                         parambuf_awvalid,
    input  wire                                         parambuf_awready,
    // Master Interface Write Data
    output wire  [ PARAMBUF_AXI_DATA_WIDTH-1 : 0 ]      parambuf_wdata,
    output wire  [ PARAMBUF_WSTRB_WIDTH   -1 : 0 ]      parambuf_wstrb,
    output wire                                         parambuf_wlast,
    output wire                                         parambuf_wvalid,
    input  wire                                         parambuf_wready,
    // Master Interface Write Response
    input  wire  [ 2                    -1 : 0 ]        parambuf_bresp,
    input  wire                                         parambuf_bvalid,
    output wire                                         parambuf_bready,
    // Master Interface Read Address
    output wire  [ AXI_ADDR_WIDTH       -1 : 0 ]        parambuf_araddr,
    output wire  [ AXI_ID_WIDTH         -1 : 0 ]        parambuf_arid,
    output wire  [ AXI_BURST_WIDTH      -1 : 0 ]        parambuf_arlen,
    output wire  [ 3                    -1 : 0 ]        parambuf_arsize,
    output wire  [ 2                    -1 : 0 ]        parambuf_arburst,
    output wire                                         parambuf_arvalid,
    input  wire                                         parambuf_arready,
    // Master Interface Read Data
    input  wire  [ PARAMBUF_AXI_DATA_WIDTH-1 : 0 ]      parambuf_rdata,
    input  wire  [ AXI_ID_WIDTH         -1 : 0 ]        parambuf_rid,
    input  wire  [ 2                    -1 : 0 ]        parambuf_rresp,
    input  wire                                         parambuf_rlast,
    input  wire                                         parambuf_rvalid,
    output wire                                         parambuf_rready,

    // AXI Interface
    // Master Interface for Ibuf
    output wire  [ AXI_ADDR_WIDTH       -1 : 0 ]        ibuf_awaddr,
    output wire  [ AXI_BURST_WIDTH      -1 : 0 ]        ibuf_awlen,
    output wire  [ 3                    -1 : 0 ]        ibuf_awsize,
    output wire  [ 2                    -1 : 0 ]        ibuf_awburst,
    output wire                                         ibuf_awvalid,
    input  wire                                         ibuf_awready,
    // Master Interface Write Data
    output wire  [ IBUF_AXI_DATA_WIDTH  -1 : 0 ]        ibuf_wdata,
    output wire  [ IBUF_WSTRB_WIDTH     -1 : 0 ]        ibuf_wstrb,
    output wire                                         ibuf_wlast,
    output wire                                         ibuf_wvalid,
    input  wire                                         ibuf_wready,
    // Master Interface Write Response
    input  wire  [ 2                    -1 : 0 ]        ibuf_bresp,
    input  wire                                         ibuf_bvalid,
    output wire                                         ibuf_bready,
    // Master Interface Read Address
    output wire  [ AXI_ADDR_WIDTH       -1 : 0 ]        ibuf_araddr,
    output wire  [ AXI_BURST_WIDTH      -1 : 0 ]        ibuf_arlen,
    output wire  [ 3                    -1 : 0 ]        ibuf_arsize,
    output wire  [ 2                    -1 : 0 ]        ibuf_arburst,
    output wire                                         ibuf_arvalid,
    output wire  [ AXI_ID_WIDTH         -1 : 0 ]        ibuf_arid,
    input  wire                                         ibuf_arready,
    // Master Interface Read Data
    input  wire  [ IBUF_AXI_DATA_WIDTH  -1 : 0 ]        ibuf_rdata,
    input  wire  [ 2                    -1 : 0 ]        ibuf_rresp,
    input  wire                                         ibuf_rlast,
    input  wire                                         ibuf_rvalid,
    input  wire  [ AXI_ID_WIDTH         -1 : 0 ]        ibuf_rid,
    output wire                                         ibuf_rready,

    // AXI Interface
    // Master Interface for Obuf
    output wire  [ AXI_ADDR_WIDTH       -1 : 0 ]        obuf_awaddr,
    output wire  [ AXI_BURST_WIDTH      -1 : 0 ]        obuf_awlen,
    output wire  [ 3                    -1 : 0 ]        obuf_awsize,
    output wire  [ 2                    -1 : 0 ]        obuf_awburst,
    output wire                                         obuf_awvalid,
    input  wire                                         obuf_awready,
    // Master Interface Write Data
    output wire  [ OBUF_AXI_DATA_WIDTH  -1 : 0 ]        obuf_wdata,
    output wire  [ OBUF_WSTRB_WIDTH     -1 : 0 ]        obuf_wstrb,
    output wire                                         obuf_wlast,
    output wire                                         obuf_wvalid,
    input  wire                                         obuf_wready,
    // Master Interface Write Response
    input  wire  [ 2                    -1 : 0 ]        obuf_bresp,
    input  wire                                         obuf_bvalid,
    output wire                                         obuf_bready,
    // Master Interface Read Address
    output wire  [ AXI_ADDR_WIDTH       -1 : 0 ]        obuf_araddr,
    output wire  [ AXI_ID_WIDTH         -1 : 0 ]        obuf_arid,
    output wire  [ AXI_BURST_WIDTH      -1 : 0 ]        obuf_arlen,
    output wire  [ 3                    -1 : 0 ]        obuf_arsize,
    output wire  [ 2                    -1 : 0 ]        obuf_arburst,
    output wire                                         obuf_arvalid,
    input  wire                                         obuf_arready,
    // Master Interface Read Data
    input  wire  [ OBUF_AXI_DATA_WIDTH  -1 : 0 ]        obuf_rdata,
    input  wire  [ AXI_ID_WIDTH         -1 : 0 ]        obuf_rid,
    input  wire  [ 2                    -1 : 0 ]        obuf_rresp,
    input  wire                                         obuf_rlast,
    input  wire                                         obuf_rvalid,
    output wire                                         obuf_rready,
    output wire                                         interrupt


);

//=============================================================
// LocalParams
//=============================================================

    localparam integer IBUF_WRITE_WIDTH              = INST_MEM_AXI_DATA_WIDTH / ARRAY_N;
    localparam integer IBUF_READ_WIDTH               = DATA_WIDTH;
    localparam integer IBUF_MEMORY_SIZE              = IBUF_BANK_DEPTH * IBUF_WRITE_WIDTH;
    localparam integer IBUF_WRITE_ADDR_WIDTH         = $clog2(IBUF_MEMORY_SIZE/IBUF_WRITE_WIDTH);
    localparam integer IBUF_READ_ADDR_WIDTH          = $clog2(IBUF_MEMORY_SIZE/IBUF_READ_WIDTH);
   
	localparam integer  WBUF_NUM_BANKS               = ARRAY_N;
    localparam integer  WBUF_WRITE_WIDTH             = PARAMBUF_AXI_DATA_WIDTH/WBUF_NUM_BANKS;
    localparam integer  WBUF_MEMORY_SIZE             = WBUF_BANK_DEPTH * WBUF_WRITE_WIDTH;
    localparam integer  WBUF_WRITE_ADDR_WIDTH        = $clog2(WBUF_MEMORY_SIZE/WBUF_WRITE_WIDTH);
    localparam integer  WBUF_READ_ADDR_WIDTH         = $clog2(WBUF_MEMORY_SIZE/WBUF_READ_WIDTH);
    
    localparam integer  BBUF_NUM_BANKS               = ARRAY_M;
    localparam integer  BBUF_WRITE_WIDTH             = PARAMBUF_AXI_DATA_WIDTH/BBUF_NUM_BANKS;
    localparam integer  BBUF_MEMORY_SIZE             = BBUF_BANK_DEPTH * BBUF_WRITE_WIDTH;
    localparam integer  BBUF_WRITE_ADDR_WIDTH        = $clog2(BBUF_MEMORY_SIZE/BBUF_WRITE_WIDTH);
    localparam integer  BBUF_READ_ADDR_WIDTH         = $clog2(BBUF_MEMORY_SIZE/BBUF_READ_WIDTH);
    
    //localparam integer OBUF_WRITE_WIDTH_A            = OBUF_AXI_DATA_WIDTH/ARRAY_M;
    localparam integer OBUF_DATA_WIDTH                     = ACC_WIDTH;
    localparam integer OBUF_READ_WIDTH                     = ACC_WIDTH;
    localparam integer OBUF_WRITE_WIDTH                    = ACC_WIDTH;
    localparam integer OBUF_MEMORY_SIZE                    = OBUF_BANK_DEPTH * OBUF_WRITE_WIDTH;
    localparam integer OBUF_WRITE_ADDR_WIDTH               = $clog2(OBUF_MEMORY_SIZE/OBUF_WRITE_WIDTH);
    localparam integer OBUF_READ_ADDR_WIDTH                = $clog2(OBUF_MEMORY_SIZE/OBUF_READ_WIDTH);


    // Buffer Addr Width
    localparam integer  IBUF_TAG_ADDR_WIDTH          = IBUF_READ_ADDR_WIDTH;
    localparam integer  OBUF_TAG_ADDR_WIDTH          = OBUF_READ_ADDR_WIDTH;
    localparam integer  WBUF_TAG_ADDR_WIDTH          = WBUF_READ_ADDR_WIDTH;
    localparam integer  BBUF_TAG_ADDR_WIDTH          = $clog2((BBUF_MEMORY_SIZE * 8) / ARRAY_M / BIAS_WIDTH);

    localparam integer  IBUF_ADDR_WIDTH              = IBUF_TAG_ADDR_WIDTH - TAG_W;
    localparam integer  WBUF_ADDR_WIDTH              = WBUF_TAG_ADDR_WIDTH - TAG_W;
    localparam integer  OBUF_ADDR_WIDTH              = OBUF_TAG_ADDR_WIDTH;
    localparam integer  BBUF_ADDR_WIDTH              = BBUF_TAG_ADDR_WIDTH - TAG_W;
    localparam integer  WBUF_REQ_WIDTH               = $clog2(ARRAY_M) + 1;


//=============================================================
// Wires/Regs
//=============================================================

    wire                                         done_block;

  // controller <-> compute handshakes
    wire                                         tag_flush;
    wire                                         tag_req;
    wire                                         ibuf_tag_reuse;
    wire                                         obuf_tag_reuse;
    wire                                         wbuf_tag_reuse;
    wire                                         bias_tag_reuse;
    wire                                         tag_ready;
    wire                                         ibuf_tag_done;
    wire                                         wbuf_tag_done;
    wire                                         obuf_tag_done;
    wire                                         bias_tag_done;

    wire                                         compute_done;
  // Load/Store addresses
    // Bias load address
    wire  [ ADDR_WIDTH      -1 : 0 ]             bbuf_ld_base_addr;
    wire                                         bbuf_ld_base_addr_v;
    // IBUF load address
    wire  [ ADDR_WIDTH      -1 : 0 ]             ibuf_ld_base_addr;
    wire                                         ibuf_ld_base_addr_v;
    // WBUF load address
    wire  [ ADDR_WIDTH      -1 : 0 ]             wbuf_ld_base_addr;
    wire                                         wbuf_ld_base_addr_v;
    // OBUF load/store address
    wire  [ ADDR_WIDTH      -1 : 0 ]             obuf_ld_base_addr;
    wire                                         obuf_ld_base_addr_v;
    wire  [ ADDR_WIDTH      -1 : 0 ]             obuf_st_base_addr;
    wire                                         obuf_st_base_addr_v;

  // Load bias or obuf
    wire                                         tag_first_ic_outer_loop_ld;
    wire                                         tag_ddr_pe_sw;

 // Systolic Array
    wire                                         sa_compute_req;

    wire                                         ibuf_compute_ready;
    wire                                         wbuf_compute_ready;
    wire                                         obuf_compute_ready;
    wire                                         bbuf_compute_ready;

  // Programming interface
    // Loop iterations
    wire  [ LOOP_ITER_W          -1 : 0 ]        cfg_loop_iter;
    wire  [ LOOP_ID_W            -1 : 0 ]        cfg_loop_iter_loop_id;
    wire                                         cfg_loop_iter_v;
    wire                                         cfg_set_specific_loop_v;
    wire  [ LOOP_ID_W            -1 : 0 ]        cfg_set_specific_loop_loop_id;
    wire  [ 2                       : 0 ]	     cfg_set_specific_loop_loop_param;
    // Loop stride
    wire  [ ADDR_STRIDE_W        -1 : 0 ]        cfg_loop_stride;
    wire                                         cfg_loop_stride_v;
    wire  [ BUF_TYPE_W           -1 : 0 ]        cfg_loop_stride_id;
    wire  [ 2                    -1 : 0 ]        cfg_loop_stride_type;
    wire  [ LOOP_ID_W            -1 : 0 ]        cfg_loop_stride_loop_id;
    // Memory request
    wire  [ MEM_REQ_W            -1 : 0 ]        cfg_mem_req_size;
    wire                                         cfg_mem_req_v;
    wire  [ 2                    -1 : 0 ]        cfg_mem_req_type;
    wire  [ BUF_TYPE_W           -1 : 0 ]        cfg_mem_req_id;
    wire  [ LOOP_ID_W            -1 : 0 ]        cfg_mem_req_loop_id;

    wire  [ INST_GROUP_ID_W      -1 : 0 ]        inst_group_id;
    wire                                         inst_group_type;
    wire                                         inst_group_s_e;
    wire                                         inst_group_v;
    wire                                         inst_group_last;


    wire                                         fused_sa_simd;
    // Compute Addr Gen
    wire                                         sa_compute_done;
    wire  [ INST_GROUP_ID_W     -1 : 0 ]         cfg_curr_group_id;
    wire  [ INST_GROUP_ID_W     -1 : 0 ]         next_group_id;
    wire                                         compute_addr_gen_stall;
    wire  [ OBUF_ADDR_WIDTH     -1 : 0 ]         obuf_compute_base_addr;
    wire  [ OBUF_ADDR_WIDTH     -1 : 0 ]         obuf_rd_addr;
    wire                                         obuf_rd_req;
    wire  [ OBUF_ADDR_WIDTH     -1 : 0 ]         obuf_wr_addr;
    wire                                         obuf_wr_req;
    wire  [ IBUF_ADDR_WIDTH     -1 : 0 ]         ibuf_compute_base_addr;
    wire  [ IBUF_ADDR_WIDTH     -1 : 0 ]         ibuf_rd_addr;
    wire                                         ibuf_rd_req;
    wire  [ WBUF_ADDR_WIDTH     -1 : 0 ]         wbuf_compute_base_addr;
    wire  [ WBUF_ADDR_WIDTH     -1 : 0 ]         wbuf_rd_addr;
    wire                                         wbuf_rd_req;
    wire  [ BBUF_ADDR_WIDTH     -1 : 0 ]         bbuf_compute_base_addr;
    wire  [ BBUF_ADDR_WIDTH     -1 : 0 ]         bbuf_rd_addr;
    wire                                         bbuf_rd_req;

    wire                                         bias_prev_sw;

    // Systolic Array
    wire                                         acc_clear;

    wire                                         ibuf_read_req_in;
    wire  [ IBUF_TAG_ADDR_WIDTH   -1 : 0]        ibuf_read_addr_in;
    wire  [ ARRAY_N               -1 : 0]        sys_ibuf_read_req;
    wire  [ ARRAY_N*IBUF_TAG_ADDR_WIDTH-1:0]     sys_ibuf_read_addr;
    wire  [ IBUF_READ_WIDTH*ARRAY_N    -1: 0]    ibuf_read_data;

    wire  [ ARRAY_M              -1 : 0]         sys_bias_read_req;
    wire  [ BBUF_TAG_ADDR_WIDTH*ARRAY_M-1 :0]    sys_bias_read_addr;
    wire                                         bias_read_req_in;
    wire  [ BBUF_TAG_ADDR_WIDTH  -1 : 0 ]        bias_read_addr_in;
    wire  [ BIAS_WIDTH*ARRAY_M   -1 : 0 ]        bbuf_read_data;

    wire                                         wbuf_read_req_in;
    wire  [ WBUF_TAG_ADDR_WIDTH  -1 : 0 ]        wbuf_read_addr_in;
    wire  [ WBUF_REQ_WIDTH*ARRAY_N       -1 : 0 ]        wbuf_write_req;
    wire  [ WBUF_WRITE_ADDR_WIDTH*ARRAY_N  -1 : 0 ]        wbuf_write_addr;
    wire  [ WBUF_WRITE_WIDTH*ARRAY_N           -1 : 0 ]        wbuf_write_data;

    wire  [ ARRAY_M*ACC_WIDTH    -1 : 0 ]        obuf_read_data;
    wire  [ OBUF_ADDR_WIDTH  -1 : 0 ]            obuf_read_addr_in;
    wire                                         obuf_read_req_in;

    wire  [ ARRAY_M              -1 : 0 ]        sys_obuf_read_req;
    wire  [ OBUF_ADDR_WIDTH*ARRAY_M-1:0 ]        sys_obuf_read_addr;
    wire                                         obuf_write_req_in;
    wire  [ ARRAY_M*ACC_WIDTH    -1 : 0 ]        obuf_write_data;
    wire  [ OBUF_ADDR_WIDTH  -1 : 0 ]            obuf_write_addr_in;
    wire  [ ARRAY_M              -1 : 0 ]        sys_obuf_write_req;
    wire  [ OBUF_ADDR_WIDTH*ARRAY_M-1 :0]        sys_obuf_write_addr;


    wire                                         parambuf_tag_ready;
    //wire                                         parambuf_tag_done;
    wire                                         parambuf_compute_ready;
    wire  [ ARRAY_M               -1 : 0 ]       bbuf_write_req_out;
    wire  [ ARRAY_M*BBUF_WRITE_ADDR_WIDTH-1 : 0 ]  bbuf_write_addr_out;
    wire  [ ARRAY_M*BBUF_WRITE_WIDTH    -1 : 0 ]       bbuf_write_data_out;

    wire                                         ibuf_tag_ready;
    
    wire  [ ARRAY_N              -1 : 0 ]        ibuf_write_req_out;
    wire  [ ARRAY_N*IBUF_WRITE_ADDR_WIDTH -1 : 0 ] ibuf_write_addr_out;
    wire  [ ARRAY_N*IBUF_WRITE_WIDTH   -1 : 0 ]  ibuf_write_data_out;

    wire                                         obuf_tag_ready;


  // BUF---Interface
    wire  [ NUM_TAGS*ARRAY_M              -1 : 0 ]        ld_st_sys_obuf_write_req_out;
    wire  [ NUM_TAGS*ARRAY_M*OBUF_ADDR_WIDTH-1: 0 ]       ld_st_sys_obuf_write_addr_out;
    wire  [ NUM_TAGS*ARRAY_M*ACC_WIDTH   -1 : 0 ]         ld_st_sys_obuf_write_data_out;
    wire  [ NUM_TAGS*ARRAY_M              -1 : 0 ]        ld_st_sys_obuf_read_req_out;
    wire  [ NUM_TAGS*ARRAY_M*OBUF_ADDR_WIDTH-1: 0 ]       ld_st_sys_obuf_read_addr_out;
    wire  [ NUM_TAGS*ARRAY_M*ACC_WIDTH   -1 : 0 ]         ld_st_sys_obuf_read_data_in;


    wire                                        simd_ready;

    wire                                        sync_tag_req;

	wire obuf_compute_base_addr_v;
    wire ibuf_compute_base_addr_v;
    wire bbuf_compute_base_addr_v;
    wire wbuf_compute_base_addr_v;

	wire   [ LOOP_ID_W             -1 : 0 ]		inst_group_sa_loop_id;
	wire   										cfg_loop_stride_segment;
    wire                                        compute_done_addr_gen;
    wire                                        last_store_en;
//=============================================================
// Assigns
//=============================================================
    // Compute Base ADDR

    wire sa_compute_req_q, sa_compute_req_pulse;
    register_sync #(1) tag_req_reg1 (clk, reset, sa_compute_req, sa_compute_req_q);
    assign sa_compute_req_pulse = sa_compute_req && ~sa_compute_req_q;


    assign obuf_compute_base_addr = {OBUF_ADDR_WIDTH{1'b0}};
    assign ibuf_compute_base_addr = {IBUF_ADDR_WIDTH{1'b0}};
    assign wbuf_compute_base_addr = {WBUF_ADDR_WIDTH{1'b0}};
    assign bbuf_compute_base_addr = {BBUF_ADDR_WIDTH{1'b0}};
    assign obuf_compute_base_addr_v = sa_compute_req_pulse;
    assign ibuf_compute_base_addr_v = sa_compute_req_pulse;
    assign bbuf_compute_base_addr_v = sa_compute_req_pulse;
    assign wbuf_compute_base_addr_v = sa_compute_req_pulse;

    //assign wbuf_tag_done = parambuf_tag_done;
    assign bias_tag_done = bbuf_tag_done;
    assign wbuf_compute_ready = parambuf_compute_ready;
    assign bbuf_compute_ready = parambuf_compute_ready;

    assign tag_ready = parambuf_tag_ready && ibuf_tag_ready && obuf_tag_ready;
    assign compute_done = sa_compute_done;

    assign sync_tag_req = tag_req && ibuf_tag_ready && obuf_tag_ready && parambuf_tag_ready;

//=============================================================
// Controller
// This module is in charge of base address generation, instruction decode and synchronization of other modules
//=============================================================
    controller #(
        .NUM_TAGS                   ( NUM_TAGS                  ),
        .ADDR_WIDTH                 ( ADDR_WIDTH                ),
        .INST_DATA_WIDTH            ( INST_DATA_WIDTH           ),
        .INST_BURST_WIDTH           ( AXI_BURST_WIDTH           ),
        .BUF_TYPE_W                 ( BUF_TYPE_W                ),
        .IMM_WIDTH                  ( IMM_WIDTH                 ),
        .GROUP_ENABLED              ( GROUP_ENABLED             ),
        .OP_CODE_W                  ( OP_CODE_W                 ),
        .OP_SPEC_W                  ( OP_SPEC_W                 ),
        .LOOP_ID_W                  ( LOOP_ID_W                 ),
        .INST_GROUP_ID_W            ( INST_GROUP_ID_W           ),
        .C_S_AXI_CONTROL_ADDR_WIDTH ( CTRL_ADDR_WIDTH           ),
        .CTRL_WSTRB_WIDTH           (CTRL_WSTRB_WIDTH           ),
        .C_S_AXI_CONTROL_DATA_WIDTH ( CTRL_DATA_WIDTH           ),
        .AXI_BURST_WIDTH            ( AXI_BURST_WIDTH           ),
        .AXI_DATA_WIDTH             ( INST_MEM_AXI_DATA_WIDTH   ),
        .IMEM_ADDR_WIDTH            ( INST_MEM_ADDR_WIDTH       )
    ) genesys_controller (
        .clk                        ( clk                       ),
        .reset                      ( reset                     ),

        .done_block                 ( done_block                ),
        .tag_flush                  ( tag_flush                 ),
        .tag_req                    ( tag_req                   ),
        .ibuf_tag_reuse             ( ibuf_tag_reuse            ),
        .obuf_tag_reuse             ( obuf_tag_reuse            ),
        .wbuf_tag_reuse             ( wbuf_tag_reuse            ),
        .bias_tag_reuse             ( bias_tag_reuse            ),
        .tag_ready                  ( tag_ready                 ),
        .ibuf_tag_done              ( ibuf_tag_done             ),
        .wbuf_tag_done              ( wbuf_tag_done             ),
        .obuf_tag_done              ( obuf_tag_done             ),
        .bias_tag_done              ( bias_tag_done             ),
        .compute_done               ( compute_done              ),
        .cfg_curr_group_id          ( cfg_curr_group_id         ),
        .next_group_id              ( next_group_id             ),

        .bbuf_ld_addr               ( bbuf_ld_base_addr         ),
        .bbuf_ld_addr_v             ( bbuf_ld_base_addr_v       ),
        .ibuf_ld_addr               ( ibuf_ld_base_addr         ),
        .ibuf_ld_addr_v             ( ibuf_ld_base_addr_v       ),
        .wbuf_ld_addr               ( wbuf_ld_base_addr         ),
        .wbuf_ld_addr_v             ( wbuf_ld_base_addr_v       ),
        .obuf_ld_addr               ( obuf_ld_base_addr         ),
        .obuf_ld_addr_v             ( obuf_ld_base_addr_v       ),
        .obuf_st_addr               ( obuf_st_base_addr         ),
        .obuf_st_addr_v             ( obuf_st_base_addr_v       ),
        .tag_first_ic_outer_loop_ld ( tag_first_ic_outer_loop_ld),
        .tag_ddr_pe_sw              ( tag_ddr_pe_sw             ),
        .sa_compute_req             ( sa_compute_req            ),
        .ibuf_compute_ready         ( ibuf_compute_ready        ),
        .wbuf_compute_ready         ( wbuf_compute_ready        ),
        .obuf_compute_ready         ( obuf_compute_ready        ),
        .bbuf_compute_ready         ( bbuf_compute_ready        ),

        .pci_cl_ctrl_awvalid        ( pci_cl_ctrl_awvalid       ),
        .pci_cl_ctrl_awaddr         ( pci_cl_ctrl_awaddr        ),
        .pci_cl_ctrl_awready        ( pci_cl_ctrl_awready       ),
        .pci_cl_ctrl_wvalid         ( pci_cl_ctrl_wvalid        ),
        .pci_cl_ctrl_wdata          ( pci_cl_ctrl_wdata         ),
        .pci_cl_ctrl_wstrb          ( pci_cl_ctrl_wstrb         ),
        .pci_cl_ctrl_wready         ( pci_cl_ctrl_wready        ),
        .pci_cl_ctrl_bvalid         ( pci_cl_ctrl_bvalid        ),
        .pci_cl_ctrl_bresp          ( pci_cl_ctrl_bresp         ),
        .pci_cl_ctrl_bready         ( pci_cl_ctrl_bready        ),
        .pci_cl_ctrl_arvalid        ( pci_cl_ctrl_arvalid       ),
        .pci_cl_ctrl_araddr         ( pci_cl_ctrl_araddr        ),
        .pci_cl_ctrl_arready        ( pci_cl_ctrl_arready       ),
        .pci_cl_ctrl_rvalid         ( pci_cl_ctrl_rvalid        ),
        .pci_cl_ctrl_rdata          ( pci_cl_ctrl_rdata         ),
        .pci_cl_ctrl_rresp          ( pci_cl_ctrl_rresp         ),
        .pci_cl_ctrl_rready         ( pci_cl_ctrl_rready        ),

        .imem_awaddr                (imem_awaddr                ),
        .imem_awlen                 ( imem_awlen                ),
        .imem_awsize                ( imem_awsize               ),
        .imem_awburst               ( imem_awburst              ),
        .imem_awvalid               ( imem_awvalid              ),
        .imem_awready               ( imem_awready              ),
        .imem_wdata                 ( imem_wdata                ),
        .imem_wstrb                 ( imem_wstrb                ),
        .imem_wlast                 ( imem_wlast                ),
        .imem_wvalid                ( imem_wvalid               ),
        .imem_wready                ( imem_wready               ),
        .imem_bresp                 ( imem_bresp                ),
        .imem_bvalid                ( imem_bvalid               ),
        .imem_bready                ( imem_bready               ),
        .imem_araddr                ( imem_araddr               ),
        .imem_arlen                 ( imem_arlen                ),
        .imem_arsize                ( imem_arsize               ),
        .imem_arburst               ( imem_arburst              ),
        .imem_arvalid               ( imem_arvalid              ),
        .imem_arid                  ( imem_arid                 ),
        .imem_arready               ( imem_arready              ),
        .imem_rdata                 ( imem_rdata                ),
        .imem_rresp                 ( imem_rresp                ),
        .imem_rlast                 ( imem_rlast                ),
        .imem_rvalid                ( imem_rvalid               ),
        .imem_rid                   ( imem_rid                  ),
        .imem_rready                ( imem_rready               ),

        .cfg_loop_iter              ( cfg_loop_iter             ),
        .cfg_loop_iter_loop_id      ( cfg_loop_iter_loop_id     ),
        .cfg_loop_iter_v            ( cfg_loop_iter_v           ),
        .cfg_set_specific_loop_v    ( cfg_set_specific_loop_v   ),
        .cfg_set_specific_loop_loop_id(cfg_set_specific_loop_loop_id),
        .cfg_set_specific_loop_loop_param(cfg_set_specific_loop_loop_param),
        .cfg_loop_stride            ( cfg_loop_stride           ),
        .cfg_loop_stride_v          ( cfg_loop_stride_v         ),
        .cfg_loop_stride_id         ( cfg_loop_stride_id        ),
        .cfg_loop_stride_type       ( cfg_loop_stride_type      ),
        .cfg_loop_stride_loop_id    ( cfg_loop_stride_loop_id   ),

        .cfg_mem_req_size           ( cfg_mem_req_size          ),
        .cfg_mem_req_v              ( cfg_mem_req_v             ),
        .cfg_mem_req_type           ( cfg_mem_req_type          ),
        .cfg_mem_req_id             ( cfg_mem_req_id            ),
        .cfg_mem_req_loop_id        ( cfg_mem_req_loop_id       ),

        .inst_group_id              ( inst_group_id             ),
        .inst_group_type            ( inst_group_type           ),
        .inst_group_s_e             ( inst_group_s_e            ),
        .inst_group_v               ( inst_group_v              ),
        .inst_group_last            ( inst_group_last           ),

        .cfg_simd_inst              (                           ),
        .cfg_simd_inst_v            (                           ),
        .simd_group_done            (                           ),

        .simd_group_done_id         (                           ),
        .simd_tiles_done            (                           ),
        .ctrl_simd_start            (                           ),
        .fused_sa_simd              ( fused_sa_simd             ),
        .simd_ready                 ( simd_ready                ),
        .interrupt                  (interrupt                  ),
        .last_store_en              (last_store_en              )
    );




//=============================================================
// Compute Address Generator
//    This module is in charge of generating the addresses for the buffers during systolic array computation
//=============================================================
    assign compute_addr_gen_stall = ~(parambuf_compute_ready && ibuf_compute_ready && obuf_compute_ready);
    assign obuf_read_req_in = obuf_rd_req;
    assign obuf_read_addr_in = obuf_rd_addr;
    assign obuf_write_req_in = obuf_wr_req;
    assign obuf_write_addr_in = obuf_wr_addr;

    compute_addr_gen #(
        .IBUF_ADDR_WIDTH            ( IBUF_ADDR_WIDTH           ),
        .WBUF_ADDR_WIDTH            ( WBUF_ADDR_WIDTH           ),
        .OBUF_ADDR_WIDTH            ( OBUF_ADDR_WIDTH           ),
        .BBUF_ADDR_WIDTH            ( BBUF_ADDR_WIDTH           ),
        .LOOP_ITER_W                ( LOOP_ITER_W               ),
        .ADDR_STRIDE_W              ( ADDR_STRIDE_W             ),
        .LOOP_ID_W                  ( LOOP_ID_W                 ),
        .INST_GROUP_ID_W            ( INST_GROUP_ID_W           ),
        .BUF_TYPE_W                 ( BUF_TYPE_W                ),
        .GROUP_ENABLED              ( GROUP_ENABLED             )
    ) sa_compute_addr_gen (
        .clk                        ( clk                       ),
        .reset                      ( reset                     ),

        .start                      ( sa_compute_req            ),
        .done                       ( compute_done_addr_gen     ),
        .block_done                 ( done_block                ),
        .cfg_curr_group_id          ( cfg_curr_group_id         ),
        .next_group_id              ( next_group_id             ),
        .stall                      ( compute_addr_gen_stall    ),

        .cfg_loop_iter_v            ( cfg_loop_iter_v           ),
        .cfg_loop_iter              ( cfg_loop_iter             ),
        .cfg_loop_iter_loop_id      ( cfg_loop_iter_loop_id     ),

        .cfg_set_specific_loop_v    ( cfg_set_specific_loop_v   ),
        .cfg_set_specific_loop_loop_id(cfg_set_specific_loop_loop_id),
        .cfg_set_specific_loop_loop_param(cfg_set_specific_loop_loop_param),

        .cfg_loop_stride_v          ( cfg_loop_stride_v         ),
        .cfg_loop_stride            ( cfg_loop_stride           ),
        .cfg_loop_stride_loop_id    ( cfg_loop_stride_loop_id   ),
        .cfg_loop_stride_id         ( cfg_loop_stride_id        ),
        .cfg_loop_stride_type       ( cfg_loop_stride_type      ),

        .inst_group_id              ( inst_group_id             ),
        .inst_group_type            ( inst_group_type           ),
        .inst_group_s_e             ( inst_group_s_e            ),
        .inst_group_v               ( inst_group_v              ),
        .inst_group_last            ( inst_group_last           ),

        .obuf_base_addr             ( obuf_compute_base_addr    ),
        .obuf_rd_addr               ( obuf_rd_addr              ),
        .obuf_rd_addr_v             ( obuf_rd_req               ),
        .obuf_wr_addr               ( obuf_wr_addr              ),
        .obuf_wr_addr_v             ( obuf_wr_req               ),

        .ibuf_base_addr             ( ibuf_compute_base_addr    ),
        .ibuf_rd_addr               ( ibuf_rd_addr              ),
        .ibuf_rd_addr_v             ( ibuf_rd_req               ),

        .wbuf_base_addr             ( wbuf_compute_base_addr    ),
        .wbuf_rd_addr               ( wbuf_rd_addr              ),
        .wbuf_rd_addr_v             ( wbuf_rd_req               ),

        .bbuf_base_addr             ( bbuf_compute_base_addr    ),
        .bbuf_rd_addr               ( bbuf_rd_addr              ),
        .bbuf_rd_addr_v             ( bbuf_rd_req               ),

        .obuf_base_addr_v           ( obuf_compute_base_addr_v  ),
        .ibuf_base_addr_v           ( ibuf_compute_base_addr_v  ),
        .wbuf_base_addr_v           ( wbuf_compute_base_addr_v  ),
        .bbuf_base_addr_v           ( bbuf_compute_base_addr_v  ),

        .bias_prev_sw               ( bias_prev_sw              ),
        .sa_compute_done_delayed    (sa_compute_done            ),
        .obuf_first_ic_outer_loop_ld (obuf_first_ic_outer_loop_ld)

    );



//=============================================================
// Delay Logic for Compute Done
//=============================================================

    reg [COMPUTE_DONE_DELAY_CYCLES: 0] compute_done_delay_cycles_cntr;
    wire [COMPUTE_DONE_DELAY_CYCLES: 0] compute_done_delay_cycles_cntr_d;
    reg                                  compute_done_delay_cycles_cntr_en;

    always @(posedge clk) begin
        if (reset || (compute_done_delay_cycles_cntr_d == ((2 * ARRAY_M) + 1)))
            compute_done_delay_cycles_cntr_en <= 1'b0;
        else if (compute_done_addr_gen)
            compute_done_delay_cycles_cntr_en <= 1'b1;
    end


    always @(posedge clk) begin
        if (reset)
            compute_done_delay_cycles_cntr <= 'b0;
        else if (compute_done_delay_cycles_cntr_en) begin
            if (compute_done_delay_cycles_cntr == (2 * ARRAY_M) + 1)
                compute_done_delay_cycles_cntr <= 'b0;
            else
                compute_done_delay_cycles_cntr <= compute_done_delay_cycles_cntr + 1'b1;
        end
    end

    register_sync #(COMPUTE_DONE_DELAY_CYCLES+1) compute_done_delay_cycles_cntr_reg (clk, reset, compute_done_delay_cycles_cntr, compute_done_delay_cycles_cntr_d);
    assign sa_compute_done = compute_done_delay_cycles_cntr == ((2 * ARRAY_M) + 1);

//=============================================================
// Parambuf Interface: The interface for WBUF and BBUF
//=============================================================
    parambuf_interface #(
        .MEM_REQ_W                  ( MEM_REQ_W                 ),
        .ADDR_WIDTH                 ( ADDR_WIDTH                ),
        .LOOP_ITER_W                ( LOOP_ITER_W               ),
        .ADDR_STRIDE_W              ( ADDR_STRIDE_W             ),
        .LOOP_ID_W                  ( LOOP_ID_W                 ),
        .BUF_TYPE_W                 ( BUF_TYPE_W                ),
        .NUM_TAGS                   ( NUM_TAGS                  ),
        .WBUF_WRITE_WIDTH           (WBUF_WRITE_WIDTH           ),
        .BBUF_WRITE_WIDTH           (BBUF_WRITE_WIDTH           ),
        .WBUF_WRITE_ADDR_WIDTH      (WBUF_WRITE_ADDR_WIDTH      ),
        .BBUF_WRITE_ADDR_WIDTH      (BBUF_WRITE_ADDR_WIDTH      ),
        .WGT_DATA_WIDTH             ( DATA_WIDTH                ),
        .BIAS_DATA_WIDTH            ( BIAS_WIDTH                ),
        .AXI_ADDR_WIDTH             ( AXI_ADDR_WIDTH            ),
        .AXI_DATA_WIDTH             ( PARAMBUF_AXI_DATA_WIDTH   ),
        .ARRAY_N                    ( ARRAY_N                   ),
        .ARRAY_M                    ( ARRAY_M                   ),
        .WBUF_ADDR_W                ( WBUF_ADDR_WIDTH           ),
        .BBUF_ADDR_W                ( BBUF_ADDR_WIDTH           ),
        .INST_GROUP_ID_W            ( INST_GROUP_ID_W           ),
        .GROUP_ENABLED              ( GROUP_ENABLED             ),
        .WBUF_READ_ADDR_WIDTH       (WBUF_READ_ADDR_WIDTH       ),
        .BBUF_READ_ADDR_WIDTH       (BBUF_READ_ADDR_WIDTH       )
    ) parambuf_interface_inst (
        .clk                        ( clk                       ),
        .reset                      ( reset                     ),

        .tag_req                    ( sync_tag_req              ),
        .wbuf_tag_reuse             ( wbuf_tag_reuse            ),
        .bbuf_tag_reuse             ( bias_tag_reuse            ),
        .tag_bias_prev_sw           (                           ),
        .tag_ddr_pe_sw              (                           ),
        .parambuf_tag_ready         ( parambuf_tag_ready        ),
        //.parambuf_tag_done          ( parambuf_tag_done         ),
        .wbuf_tag_done              (wbuf_tag_done              ),
        .bbuf_tag_done              (bbuf_tag_done              ),
        .compute_done               ( sa_compute_done           ),
        .block_done                 ( done_block                ),
        .tag_base_wbuf_ld_addr      ( wbuf_ld_base_addr         ),
        .tag_base_bbuf_ld_addr      ( bbuf_ld_base_addr         ),
        .wbuf_base_addr_v           ( wbuf_ld_base_addr_v       ),
        .bbuf_base_addr_v           ( bbuf_ld_base_addr_v       ),
        .parambuf_compute_ready     ( parambuf_compute_ready    ),
        // for now, not used
        .parambuf_next_group_ld_id  (                           ),
        //not used
        .wbuf_compute_bias_prev_sw  (                           ),
        .bbuf_compute_bias_prev_sw  (                           ),

        .cfg_loop_stride_v          ( cfg_loop_stride_v         ),
        .cfg_loop_stride_type       ( cfg_loop_stride_type      ),
        .cfg_loop_stride            ( cfg_loop_stride           ),
        .cfg_loop_stride_loop_id    ( cfg_loop_stride_loop_id   ),
        .cfg_loop_stride_id         ( cfg_loop_stride_id        ),
        .cfg_loop_stride_segment    (                           ),
        .cfg_loop_iter_v            ( cfg_loop_iter_v           ),
        .cfg_loop_iter              ( cfg_loop_iter             ),
        .cfg_loop_iter_loop_id      ( cfg_loop_iter_loop_id     ),
        .cfg_loop_iter_level        (                           ),
        .cfg_mem_req_v              ( cfg_mem_req_v             ),
        .cfg_mem_req_id             ( cfg_mem_req_id            ),
        .cfg_mem_req_size           ( cfg_mem_req_size          ),
        .cfg_mem_req_loop_id        ( cfg_mem_req_loop_id       ),
        .cfg_mem_req_type           ( cfg_mem_req_type          ),
        .inst_group_id              ( inst_group_id             ),
        .inst_group_type            ( inst_group_type           ),
        .inst_group_s_e             ( inst_group_s_e            ),
        .inst_group_v               ( inst_group_v              ),
        .inst_group_sa_loop_id      ( inst_group_sa_loop_id     ),
        .inst_group_last            ( inst_group_last           ),

        .wbuf_read_req              ( wbuf_rd_req               ),
        .wbuf_read_addr             ( wbuf_rd_addr              ),
        .wbuf_read_req_out          ( wbuf_read_req_in          ),
        .wbuf_read_addr_out         ( wbuf_read_addr_in         ),
        .wbuf_write_req_out         ( wbuf_write_req            ),
        .wbuf_write_addr_out        ( wbuf_write_addr           ),
        .wbuf_write_data_out        ( wbuf_write_data           ),
        .bbuf_read_req              ( bbuf_rd_req               ),
        .bbuf_read_addr             ( bbuf_rd_addr              ),
        .bbuf_read_req_out          ( bias_read_req_in          ),
        .bbuf_read_addr_out         ( bias_read_addr_in         ),

        .bbuf_write_req_out         ( bbuf_write_req_out        ),
        .bbuf_write_addr_out        ( bbuf_write_addr_out       ),
        .bbuf_write_data_out        ( bbuf_write_data_out       ),

        .mws_awaddr                 ( parambuf_awaddr                ),
        .mws_awlen                  ( parambuf_awlen                 ),
        //.mws_awsize                 ( parambuf_awsize                ),
        //.mws_awburst                ( parambuf_awburst               ),
        .mws_awvalid                ( parambuf_awvalid               ),
        .mws_awready                ( parambuf_awready               ),
        .mws_wdata                  ( parambuf_wdata                 ),
        .mws_wstrb                  ( parambuf_wstrb                 ),
        .mws_wlast                  ( parambuf_wlast                 ),
        .mws_wvalid                 ( parambuf_wvalid                ),
        .mws_wready                 ( parambuf_wready                ),
        //.mws_bresp                  ( parambuf_bresp                 ),
        .mws_bvalid                 ( parambuf_bvalid                ),
        .mws_bready                 ( parambuf_bready                ),
        .mws_araddr                 ( parambuf_araddr                ),
        //.mws_arid                   ( parambuf_arid                  ),
        .mws_arlen                  ( parambuf_arlen                 ),
        //.mws_arsize                 ( parambuf_arsize                ),
        //.mws_arburst                ( parambuf_arburst               ),
        .mws_arvalid                ( parambuf_arvalid               ),
        .mws_arready                ( parambuf_arready               ),
        .mws_rdata                  ( parambuf_rdata                 ),
        //.mws_rid                    ( parambuf_rid                   ),
        //.mws_rresp                  ( parambuf_rresp                 ),
        .mws_rlast                  ( parambuf_rlast                 ),
        .mws_rvalid                 ( parambuf_rvalid                ),
        .mws_rready                 ( parambuf_rready                ),
        .last_store_en              (last_store_en                   )

    );

//=============================================================
// Bias Buffer (BBUF)
//=============================================================

    bias_buffer #(
        .DDR_BANDWIDTH     (PARAMBUF_AXI_DATA_WIDTH  ),
        .NUM_BANKS         (BBUF_NUM_BANKS           ),
        .READ_WIDTH        (BBUF_READ_WIDTH          ),
        .BUFFER_DEPTH      (BBUF_BANK_DEPTH          ),
        .READ_LATENCY_B    (BBUF_READ_LATENCY_B      ),
        .WRITE_WIDTH       (BBUF_WRITE_WIDTH         ),
        .MEMORY_SIZE       (BBUF_MEMORY_SIZE         ),
        .WRITE_ADDR_WIDTH  (BBUF_WRITE_ADDR_WIDTH    ),  
        .READ_ADDR_WIDTH   (BBUF_READ_ADDR_WIDTH     )
    ) bbuf (
        .clk                        ( clk                           ),
        .reset                      ( reset                         ),

        .bs_read_req                ( sys_bias_read_req             ),
        .bs_read_addr               ( sys_bias_read_addr            ),
        .bs_read_data               ( bbuf_read_data                ),

        .bs_write_req               ( bbuf_write_req_out            ),
        .bs_write_addr              ( bbuf_write_addr_out           ),
        .bs_write_data              ( bbuf_write_data_out           )
    );

//=============================================================
// Input Buffer Interface
//=============================================================
    ibuf_interface #(
        .MEM_REQ_W                  ( MEM_REQ_W                     ),
        .ADDR_WIDTH                 ( ADDR_WIDTH                    ),
        .DATA_WIDTH                 ( DATA_WIDTH                    ),
        .LOOP_ITER_W                ( LOOP_ITER_W                   ),
        .ADDR_STRIDE_W              ( ADDR_STRIDE_W                 ),
        .LOOP_ID_W                  ( LOOP_ID_W                     ),
        .BUF_TYPE_W                 ( BUF_TYPE_W                    ),
        .NUM_TAGS                   ( NUM_TAGS                      ),
        .TAG_REUSE_COUNTER_W        ( TAG_REUSE_COUNTER_W           ),
        .INST_GROUP_ID_W            ( INST_GROUP_ID_W               ),
        .AXI_ADDR_WIDTH             ( AXI_ADDR_WIDTH                ),
        .AXI_DATA_WIDTH             ( IBUF_AXI_DATA_WIDTH           ),
        .IBUF_WRITE_WIDTH           ( IBUF_WRITE_WIDTH              ),
        .IBUF_WRITE_ADDR_WIDTH      ( IBUF_WRITE_ADDR_WIDTH         ),
        .IBUF_READ_WIDTH            ( IBUF_READ_WIDTH               ),
        .IBUF_READ_ADDR_WIDTH       ( IBUF_READ_ADDR_WIDTH          ),
        .AXI_BURST_WIDTH            ( AXI_BURST_WIDTH               ),
        .WSTRB_W                    ( IBUF_WSTRB_WIDTH              ),
        .ARRAY_N                    ( ARRAY_N                       ),
        .BUF_ADDR_W                 ( IBUF_ADDR_WIDTH               ),
        .GROUP_ENABLED              ( GROUP_ENABLED                 )

    ) ibuf_interface_inst (
        .clk                        ( clk                           ),
        .reset                      ( reset                         ),

        .tag_req                    ( sync_tag_req                  ),
        .tag_reuse                  ( ibuf_tag_reuse                ),
        .tag_bias_prev_sw           (                               ),
        .tag_ddr_pe_sw              (                               ),
        .tag_ready                  ( ibuf_tag_ready                ),
        .tag_done                   ( ibuf_tag_done                 ),
        .compute_done               ( sa_compute_done               ),
        .tag_base_ld_addr           ( ibuf_ld_base_addr             ),
        .base_ld_addr_v             ( ibuf_ld_base_addr_v           ),

        .block_done                 ( done_block                    ),
        .compute_ready              ( ibuf_compute_ready            ),
        .compute_bias_prev_sw       (                               ),

        .cfg_loop_stride_v          ( cfg_loop_stride_v             ),
        .cfg_loop_stride_type       ( cfg_loop_stride_type          ),
        .cfg_loop_stride            ( cfg_loop_stride               ),
        .cfg_loop_stride_loop_id    ( cfg_loop_stride_loop_id       ),
        .cfg_loop_stride_id         ( cfg_loop_stride_id            ),
        .cfg_loop_stride_segment    ( cfg_loop_stride_segment       ),

        .cfg_loop_iter_v            ( cfg_loop_iter_v               ),
        .cfg_loop_iter              ( cfg_loop_iter                 ),
        .cfg_loop_iter_loop_id      ( cfg_loop_iter_loop_id         ),
        .cfg_loop_iter_level        (                               ),

        .cfg_mem_req_v              ( cfg_mem_req_v                 ),
        .cfg_mem_req_id             ( cfg_mem_req_id                ),
        .cfg_mem_req_size           ( cfg_mem_req_size              ),
        .cfg_mem_req_loop_id        ( cfg_mem_req_loop_id           ),
        .cfg_mem_req_type           ( cfg_mem_req_type              ),

        .inst_group_id              ( inst_group_id                 ),
        .inst_group_type            ( inst_group_type               ),
        .inst_group_s_e             ( inst_group_s_e                ),
        .inst_group_v               ( inst_group_v                  ),
        .inst_group_sa_loop_id      ( inst_group_sa_loop_id         ),
        .inst_group_last            ( inst_group_last               ),
        // For now, not used
        .buf_ld_first_group         (                               ),
        .compute_group_id           (                               ),

        .simd_ibuf_write_req        (                               ),
        .simd_ibuf_write_addr       (                               ),
        .simd_ibuf_write_data       (                               ),

        .buf_read_req               ( ibuf_rd_req                   ),
        .buf_read_addr              ( ibuf_rd_addr                  ),
        .buf_read_req_out           ( ibuf_read_req_in              ),
        .buf_read_addr_out          ( ibuf_read_addr_in             ),

        .buf_write_req_out          ( ibuf_write_req_out            ),
        .buf_write_addr_out         ( ibuf_write_addr_out           ),
        .buf_write_data_out         ( ibuf_write_data_out           ),

        .mws_awaddr                 ( ibuf_awaddr                    ),
        .mws_awlen                  ( ibuf_awlen                     ),
        //.mws_awsize                 ( ibuf_awsize                    ),
        //.mws_awburst                ( ibuf_awburst                   ),
        .mws_awvalid                ( ibuf_awvalid                   ),
        .mws_awready                ( ibuf_awready                   ),
        .mws_wdata                  ( ibuf_wdata                     ),
        .mws_wstrb                  ( ibuf_wstrb                     ),
        .mws_wlast                  ( ibuf_wlast                     ),
        .mws_wvalid                 ( ibuf_wvalid                    ),
        .mws_wready                 ( ibuf_wready                    ),
        //.mws_bresp                  ( ibuf_bresp                     ),
        .mws_bvalid                 ( ibuf_bvalid                    ),
        .mws_bready                 ( ibuf_bready                    ),
        .mws_araddr                 ( ibuf_araddr                    ),
        .mws_arlen                  ( ibuf_arlen                     ),
        //.mws_arsize                 ( ibuf_arsize                    ),
        //.mws_arburst                ( ibuf_arburst                   ),
        .mws_arvalid                ( ibuf_arvalid                   ),
        //.mws_arid                   ( ibuf_arid                      ),
        .mws_arready                ( ibuf_arready                   ),
        .mws_rdata                  ( ibuf_rdata                     ),
        //.mws_rresp                  ( ibuf_rresp                     ),
        .mws_rlast                  ( ibuf_rlast                     ),
        .mws_rvalid                 ( ibuf_rvalid                    ),
        //.mws_rid                    ( ibuf_rid                       ),
        .mws_rready                 ( ibuf_rready                    ),
        .last_store_en              (last_store_en                   )
    );


//=============================================================
// Input Buffer (IBUF)
//=============================================================

    ibuf #(
        .DDR_BANDWIDTH              (IBUF_AXI_DATA_WIDTH),
        .NUM_BANKS                  (ARRAY_N),
        .DATA_WIDTH                 (DATA_WIDTH),
        .READ_WIDTH                 (IBUF_READ_WIDTH),
        .BUFFER_DEPTH               (IBUF_BANK_DEPTH),
        .READ_LATENCY_B             (IBUF_READ_LATENCY_B),
        .WRITE_WIDTH                (IBUF_WRITE_WIDTH),
        .MEMORY_SIZE                (IBUF_MEMORY_SIZE),
        .WRITE_ADDR_WIDTH           (IBUF_WRITE_ADDR_WIDTH),
        .READ_ADDR_WIDTH            (IBUF_READ_ADDR_WIDTH)
    ) i_ibuf (
        .clk                        ( clk                           ),
        .reset                      ( reset                         ),

        .bs_read_req                ( sys_ibuf_read_req             ),
        .bs_read_addr               ( sys_ibuf_read_addr            ),
        .bs_read_data               ( ibuf_read_data                ),

        .bs_write_req               ( ibuf_write_req_out            ),
        .bs_write_addr              ( ibuf_write_addr_out           ),
        .bs_write_data              ( ibuf_write_data_out           )
    );


//=============================================================
// Output Buffer Interface
//=============================================================
    // Taking SIMD array out
    assign simd_ready = 1'b0;
    //

    obuf_interface #(
        .MEM_REQ_W                  ( MEM_REQ_W                     ),
        .ADDR_WIDTH                 ( ADDR_WIDTH                    ),
        .DATA_WIDTH                 ( ACC_WIDTH                     ),
        .LOOP_ITER_W                ( LOOP_ITER_W                   ),
        .ADDR_STRIDE_W              ( ADDR_STRIDE_W                 ),
        .LOOP_ID_W                  ( LOOP_ID_W                     ),
        .BUF_TYPE_W                 ( BUF_TYPE_W                    ),
        .NUM_TAGS                   ( NUM_TAGS                      ),
        .TAG_REUSE_COUNTER_W        ( TAG_REUSE_COUNTER_W           ),
        .INST_GROUP_ID_W            ( INST_GROUP_ID_W               ),
        .AXI_ADDR_WIDTH             ( AXI_ADDR_WIDTH                ),
        .AXI_DATA_WIDTH             ( OBUF_AXI_DATA_WIDTH           ),
        .AXI_BURST_WIDTH            ( AXI_BURST_WIDTH               ),
        .WSTRB_W                    ( OBUF_WSTRB_WIDTH              ),
        .ARRAY_M                    ( ARRAY_M                       ),
        .ARRAY_N                    ( ARRAY_N                       ),
        .BUF_ADDR_W                 ( OBUF_ADDR_WIDTH               ),
        .GROUP_ENABLED              ( GROUP_ENABLED                 )

    ) obuf_interface_inst (
        .clk                        ( clk                           ),
        .reset                      ( reset                         ),
        .tag_req                    ( sync_tag_req                  ),
        .tag_reuse                  ( obuf_tag_reuse                ),
        .tag_bias_prev_sw           (                               ),
        .tag_ddr_pe_sw              ( tag_ddr_pe_sw                 ),
        .tag_ready                  ( obuf_tag_ready                ),
        .tag_done                   ( obuf_tag_done                 ),
        .compute_done               ( sa_compute_done               ),
        .block_done                 ( done_block                    ),
        .tag_base_ld_addr           ( obuf_ld_base_addr             ),
        .tag_base_st_addr           ( obuf_st_base_addr             ),
        .base_ld_addr_v             ( obuf_ld_base_addr_v           ),
        .base_st_addr_v             ( obuf_st_base_addr_v           ),
        .compute_start              ( sa_compute_req                ),
        .compute_ready              ( obuf_compute_ready            ),
        .compute_bias_prev_sw       (                               ),
        .first_ic_outer_loop_ld     ( tag_first_ic_outer_loop_ld    ),
        // For now, this is fixed at grup_id=0
        .next_group_simd            (  fused_sa_simd		        ),
        .cfg_loop_stride_v          ( cfg_loop_stride_v             ),
        .cfg_loop_stride_type       ( cfg_loop_stride_type          ),
        .cfg_loop_stride            ( cfg_loop_stride               ),
        .cfg_loop_stride_loop_id    ( cfg_loop_stride_loop_id       ),
        .cfg_loop_stride_id         ( cfg_loop_stride_id            ),
        .cfg_loop_stride_segment    (                               ),

        .cfg_loop_iter_v            ( cfg_loop_iter_v               ),
        .cfg_loop_iter              ( cfg_loop_iter                 ),
        .cfg_loop_iter_loop_id      ( cfg_loop_iter_loop_id         ),
        .cfg_loop_iter_level        (                               ),

        .cfg_mem_req_v              ( cfg_mem_req_v                 ),
        .cfg_mem_req_id             ( cfg_mem_req_id                ),
        .cfg_mem_req_size           ( cfg_mem_req_size              ),
        .cfg_mem_req_loop_id        ( cfg_mem_req_loop_id           ),
        .cfg_mem_req_type           ( cfg_mem_req_type              ),

        .inst_group_id              ( inst_group_id                 ),
        .inst_group_type            ( inst_group_type               ),
        .inst_group_s_e             ( inst_group_s_e                ),
        .inst_group_v               ( inst_group_v                  ),
        .inst_group_sa_loop_id      ( inst_group_sa_loop_id         ),
        .inst_group_last            ( inst_group_last               ),

        .sys_buf_write_req_in       ( sys_obuf_write_req            ),
        .sys_buf_write_addr_in      ( sys_obuf_write_addr           ),
        .sys_buf_write_data_in      ( obuf_write_data               ),

        .sys_buf_read_req_in        ( sys_obuf_read_req             ),
        .sys_buf_read_addr_in       ( sys_obuf_read_addr            ),
        .sys_buf_read_data_out      ( obuf_read_data                ),

        .simd_ready                 ( simd_ready                    ),
        .simd_activate              (                               ),
        .simd_buf_read_req          (                               ),
        .simd_buf_read_addr         (                               ),
        .simd_buf_read_data         (                               ),
        .simd_data_valid            (                               ),

        .ld_st_sys_buf_write_req_out( ld_st_sys_obuf_write_req_out   ),
        .ld_st_sys_buf_write_addr_out( ld_st_sys_obuf_write_addr_out ),
        .ld_st_sys_buf_write_data_out( ld_st_sys_obuf_write_data_out ),
        .ld_st_sys_buf_read_req_out ( ld_st_sys_obuf_read_req_out    ),
        .ld_st_sys_buf_read_addr_out( ld_st_sys_obuf_read_addr_out   ),
        .ld_st_sys_buf_read_data_in ( ld_st_sys_obuf_read_data_in    ),

        .mws_awaddr                 ( obuf_awaddr                    ),
        .mws_awlen                  ( obuf_awlen                     ),
        //.mws_awsize                 ( obuf_awsize                    ),
        //.mws_awburst                ( obuf_awburst                   ),
        .mws_awvalid                ( obuf_awvalid                   ),
        .mws_awready                ( obuf_awready                   ),
        .mws_wdata                  ( obuf_wdata                     ),
        .mws_wstrb                  ( obuf_wstrb                     ),
        .mws_wlast                  ( obuf_wlast                     ),
        .mws_wvalid                 ( obuf_wvalid                    ),
        .mws_wready                 ( obuf_wready                    ),
        //.mws_bresp                  ( obuf_bresp                     ),
        .mws_bvalid                 ( obuf_bvalid                    ),
        .mws_bready                 ( obuf_bready                    ),
        .mws_araddr                 ( obuf_araddr                    ),
        .mws_arlen                  ( obuf_arlen                     ),
        //.mws_arsize                 ( obuf_arsize                    ),
        //.mws_arburst                ( obuf_arburst                   ),
        .mws_arvalid                ( obuf_arvalid                   ),
        //.mws_arid                   ( obuf_arid                      ),
        .mws_arready                ( obuf_arready                   ),
        .mws_rdata                  ( obuf_rdata                     ),
        //.mws_rresp                  ( obuf_rresp                     ),
        .mws_rlast                  ( obuf_rlast                     ),
        .mws_rvalid                 ( obuf_rvalid                    ),
        //.mws_rid                    ( obuf_rid                       ),
        .mws_rready                 ( obuf_rready                    ),
        .last_store_en              (last_store_en                   ),
        .obuf_first_ic_outer_loop_ld (obuf_first_ic_outer_loop_ld)

    );

//=============================================================
// Output Buffer (OBUF)
//=============================================================
    obuf_wrapper #(
        .NUM_TAGS                   ( NUM_TAGS                      ),
        .ARRAY_M                    ( ARRAY_M                       ),
        .OBUF_DATA_WIDTH                 ( ACC_WIDTH                     ),
        .OBUF_DDR_BANDWIDTH         (OBUF_AXI_DATA_WIDTH            ),         
        .OBUF_READ_WIDTH            (OBUF_READ_WIDTH                ),   
        .OBUF_BUFFER_DEPTH          (OBUF_BANK_DEPTH                ),   
        .OBUF_READ_LATENCY_B        (OBUF_READ_LATENCY_B            ),  
        .OBUF_WRITE_WIDTH           (OBUF_WRITE_WIDTH               ),  
        .OBUF_MEMORY_SIZE           (OBUF_MEMORY_SIZE               ),   
        .OBUF_WRITE_ADDR_WIDTH      (OBUF_WRITE_ADDR_WIDTH          ),
        .OBUF_READ_ADDR_WIDTH       (OBUF_READ_ADDR_WIDTH           ) 

    ) obuf_mem (
        .clk                        ( clk                           ),
        .reset                      ( reset                         ),

        .bs_read_req               (ld_st_sys_obuf_read_req_out    ),
        .bs_read_addr              (ld_st_sys_obuf_read_addr_out   ),
        .bs_read_data              (ld_st_sys_obuf_read_data_in    ),
        .bs_write_req              (ld_st_sys_obuf_write_req_out   ),
        .bs_write_addr             (ld_st_sys_obuf_write_addr_out  ),
        .bs_write_data             (ld_st_sys_obuf_write_data_out  )

    );

//=============================================================
// Systolic Array: In charge of Conv/FC/GEMM Operations
// This module includes the WBUF
//=============================================================

    assign acc_clear = sa_compute_done;

    systolic_array #(
        .ARRAY_N                    ( ARRAY_N                   ),
        .ARRAY_M                    ( ARRAY_M                   ),
        .ACT_WIDTH                  ( DATA_WIDTH                ),
        .WGT_WIDTH                  ( DATA_WIDTH                ),
        .BIAS_WIDTH                 ( BIAS_WIDTH                ),
        .ACC_WIDTH                  ( ACC_WIDTH                 ),
        .OBUF_ADDR_WIDTH            ( OBUF_ADDR_WIDTH           ),
        .BBUF_ADDR_WIDTH            ( BBUF_TAG_ADDR_WIDTH       ),
        .IBUF_ADDR_WIDTH            ( IBUF_TAG_ADDR_WIDTH       ),
        .WBUF_ADDR_WIDTH            ( WBUF_TAG_ADDR_WIDTH       ),

        .WBUF_DDR_BANDWIDTH			(PARAMBUF_AXI_DATA_WIDTH),
        .WBUF_READ_WIDTH            (WBUF_READ_WIDTH),
        .WBUF_DEPTH                 (WBUF_BANK_DEPTH),
        .WBUF_NUM_BANKS 			(WBUF_NUM_BANKS),
        .WBUF_READ_LATENCY_B        (WBUF_READ_LATENCY_B),
        .WBUF_WRITE_WIDTH           (WBUF_WRITE_WIDTH),
        .WBUF_MEMORY_SIZE           (WBUF_MEMORY_SIZE),
        .WBUF_WRITE_ADDR_WIDTH      (WBUF_WRITE_ADDR_WIDTH),
        .WBUF_READ_ADDR_WIDTH       (WBUF_READ_ADDR_WIDTH)
    ) systolic_array_inst (
        .clk                        ( clk                       ),
        .reset                      ( reset                     ),

        .acc_clear                  ( acc_clear                 ),

        .ibuf_read_req_in           ( ibuf_read_req_in          ),
        .ibuf_read_addr_in          ( ibuf_read_addr_in         ),
        .sys_ibuf_read_req          ( sys_ibuf_read_req         ),
        .sys_ibuf_read_addr         ( sys_ibuf_read_addr        ),
        .ibuf_read_data             ( ibuf_read_data            ),
        .sys_bias_read_req          ( sys_bias_read_req         ),
        .sys_bias_read_addr         ( sys_bias_read_addr        ),
        .bias_read_req_in           ( bias_read_req_in          ),
        .bias_read_addr_in          ( bias_read_addr_in         ),
        .bbuf_read_data             ( bbuf_read_data            ),
        .bias_prev_sw               ( bias_prev_sw              ),
        .wbuf_read_req              ( wbuf_read_req_in          ),
        .wbuf_read_addr             ( wbuf_read_addr_in         ),
        .wbuf_write_req             ( wbuf_write_req            ),
        .wbuf_write_addr            ( wbuf_write_addr           ),
        .wbuf_write_data            ( wbuf_write_data           ),
        .obuf_read_data             ( obuf_read_data            ),
        .obuf_read_addr             ( obuf_read_addr_in         ),
        .obuf_read_req_in           ( obuf_read_req_in          ),
        .sys_obuf_read_req          ( sys_obuf_read_req         ),
        .sys_obuf_read_addr         ( sys_obuf_read_addr        ),
        .obuf_write_req_in          ( obuf_write_req_in         ),
        .obuf_write_data            ( obuf_write_data           ),
        .obuf_write_addr_in         ( obuf_write_addr_in        ),
        .sys_obuf_write_req         ( sys_obuf_write_req        ),
        .sys_obuf_write_addr        ( sys_obuf_write_addr       )

    );



endmodule
