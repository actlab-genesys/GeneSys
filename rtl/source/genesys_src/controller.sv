// GeneSys main controller

`timescale 1ns/1ps
module controller #(
    parameter integer  NUM_TAGS                     = 2,
    parameter integer  TAG_W                        = $clog2(NUM_TAGS),
    parameter integer  ADDR_WIDTH                   = 42,
    parameter integer  IBUF_ADDR_WIDTH              = ADDR_WIDTH,
    parameter integer  WBUF_ADDR_WIDTH              = ADDR_WIDTH,
    parameter integer  OBUF_ADDR_WIDTH              = ADDR_WIDTH,
    parameter integer  BBUF_ADDR_WIDTH              = ADDR_WIDTH,
    parameter integer  NUM_BASE_LOOPS               = 7,
  // Instructions
    parameter integer  INST_DATA_WIDTH              = 32,
    parameter integer  INST_WSTRB_WIDTH             = INST_DATA_WIDTH/8,
    parameter integer  INST_BURST_WIDTH             = 8,
  // Decoder
    parameter integer  BUF_TYPE_W                   = 2,
    parameter integer  IMM_WIDTH                    = 16,
    parameter integer  LOOP_ITER_W                  = IMM_WIDTH,
    parameter integer  MEM_REQ_W                    = IMM_WIDTH,
    parameter integer  ADDR_STRIDE_W                = 2*IMM_WIDTH,
    parameter integer  GROUP_ENABLED                = 0,
    
    parameter integer  OP_CODE_W                    = 4,
    parameter integer  OP_SPEC_W                    = 6,
    parameter integer  LOOP_ID_W                    = 6,
    parameter integer  INST_GROUP_ID_W              = 4,
    parameter integer  NUM_MAX_LOOPS                = (1 << INST_GROUP_ID_W),
    parameter integer  EXEC_DONE_WAIT_CYCLES        = 128,
  // AXI-Lite
    parameter integer  C_S_AXI_CONTROL_ADDR_WIDTH   = 32,
    parameter integer  C_S_AXI_CONTROL_DATA_WIDTH   = 32,
    parameter integer  CTRL_WSTRB_WIDTH             = C_S_AXI_CONTROL_DATA_WIDTH/8,
  // AXI
    parameter integer  AXI_BURST_WIDTH              = 8,
    parameter integer  AXI_DATA_WIDTH               = 64,
    parameter integer  AXI_ID_WIDTH                 = 1,
    parameter integer  WSTRB_W                      = AXI_DATA_WIDTH/8,
  // Instruction Mem
    parameter integer  IMEM_ADDR_WIDTH              = 12,
    parameter integer  PC_DATA_WIDTH                = 64
) (
    input  wire                                         clk,
    input  wire                                         reset,
    
    output wire                                         done_block,

  // controller <-> compute handshakes
    output wire                                         tag_flush,
    output wire                                         tag_req,
    output wire                                         ibuf_tag_reuse,
    output wire                                         obuf_tag_reuse,
    output wire                                         wbuf_tag_reuse,
    output reg                                          bias_tag_reuse, 
    input  wire                                         tag_ready,
    input  wire                                         ibuf_tag_done,
    input  wire                                         wbuf_tag_done,
    input  wire                                         obuf_tag_done,
    input  wire                                         bias_tag_done,

    input  wire                                         compute_done,
    output wire [ INST_GROUP_ID_W      -1 : 0 ]         cfg_curr_group_id,
    output wire [ INST_GROUP_ID_W      -1 : 0 ]         next_group_id,

  // Load/Store addresses
    // Bias load address
    output wire  [ BBUF_ADDR_WIDTH      -1 : 0 ]        bbuf_ld_addr,
    output wire                                         bbuf_ld_addr_v,
    // IBUF load address
    output wire  [ IBUF_ADDR_WIDTH      -1 : 0 ]        ibuf_ld_addr,
    output wire                                         ibuf_ld_addr_v,
    // WBUF load address
    output wire  [ WBUF_ADDR_WIDTH      -1 : 0 ]        wbuf_ld_addr,
    output wire                                         wbuf_ld_addr_v,
    // OBUF load/store address
    output wire  [ OBUF_ADDR_WIDTH      -1 : 0 ]        obuf_ld_addr,
    output wire                                         obuf_ld_addr_v,
    output wire  [ OBUF_ADDR_WIDTH      -1 : 0 ]        obuf_st_addr,
    output wire                                         obuf_st_addr_v,

  // Load bias or obuf
    output wire                                         tag_first_ic_outer_loop_ld,
    output wire                                         tag_ddr_pe_sw,

 // Systolic Array
    output wire                                         sa_compute_req,
    
    input  wire                                         ibuf_compute_ready,
    input  wire                                         wbuf_compute_ready,
    input  wire                                         obuf_compute_ready,
    input  wire                                         bbuf_compute_ready,


  // PCIe -> CL_wrapper AXI4-Lite interface
    // Slave Write address
    input  wire                                         pci_cl_ctrl_awvalid,
    input  wire  [ C_S_AXI_CONTROL_ADDR_WIDTH      -1 : 0 ]        pci_cl_ctrl_awaddr,
    output wire                                         pci_cl_ctrl_awready,
    // Slave Write data
    input  wire                                         pci_cl_ctrl_wvalid,
    input  wire  [ C_S_AXI_CONTROL_DATA_WIDTH      -1 : 0 ]        pci_cl_ctrl_wdata,
    input  wire  [ CTRL_WSTRB_WIDTH     -1 : 0 ]        pci_cl_ctrl_wstrb,
    output wire                                         pci_cl_ctrl_wready,
    // Slave Write response
    output wire                                         pci_cl_ctrl_bvalid,
    output wire  [ 2                    -1 : 0 ]        pci_cl_ctrl_bresp,
    input  wire                                         pci_cl_ctrl_bready,
    // Slave Read address
    input  wire                                         pci_cl_ctrl_arvalid,
    input  wire  [ C_S_AXI_CONTROL_ADDR_WIDTH      -1 : 0 ]        pci_cl_ctrl_araddr,
    output wire                                         pci_cl_ctrl_arready,
    // Slave Read data/response
    output wire                                         pci_cl_ctrl_rvalid,
    output wire  [ C_S_AXI_CONTROL_DATA_WIDTH      -1 : 0 ]        pci_cl_ctrl_rdata,
    output wire  [ 2                    -1 : 0 ]        pci_cl_ctrl_rresp,
    input  wire                                         pci_cl_ctrl_rready,


  // CL_wrapper -> DDR AXI4 interface
    // Master Interface Write Address
    output wire  [ ADDR_WIDTH           -1 : 0 ]        imem_awaddr,
    output wire  [ AXI_BURST_WIDTH      -1 : 0 ]        imem_awlen,
    output wire  [ 3                    -1 : 0 ]        imem_awsize,
    output wire  [ 2                    -1 : 0 ]        imem_awburst,
    output wire                                         imem_awvalid,
    input  wire                                         imem_awready,
    // Master Interface Write Data
    output wire  [ AXI_DATA_WIDTH       -1 : 0 ]        imem_wdata,
    output wire  [ WSTRB_W              -1 : 0 ]        imem_wstrb,
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
    input  wire  [ AXI_DATA_WIDTH       -1 : 0 ]        imem_rdata,
    input  wire  [ 2                    -1 : 0 ]        imem_rresp,
    input  wire                                         imem_rlast,
    input  wire                                         imem_rvalid,
    input  wire  [ AXI_ID_WIDTH         -1 : 0 ]        imem_rid,
    output wire                                         imem_rready,

  // Programming interface
    // Loop iterations
    output wire  [ LOOP_ITER_W          -1 : 0 ]        cfg_loop_iter,
    output wire  [ LOOP_ID_W            -1 : 0 ]        cfg_loop_iter_loop_id,
    output wire                                         cfg_loop_iter_v,
    output wire                                         cfg_set_specific_loop_v,
    output wire  [ LOOP_ID_W            -1 : 0 ]        cfg_set_specific_loop_loop_id,
    output wire  [ 2                       : 0 ]		cfg_set_specific_loop_loop_param,
    // Loop stride
    output wire  [ ADDR_STRIDE_W        -1 : 0 ]        cfg_loop_stride,
    output wire                                         cfg_loop_stride_v,
    output wire  [ BUF_TYPE_W           -1 : 0 ]        cfg_loop_stride_id,
    output wire  [ 2                    -1 : 0 ]        cfg_loop_stride_type,
    output wire  [ LOOP_ID_W            -1 : 0 ]        cfg_loop_stride_loop_id,
    // Memory request
    output wire  [ MEM_REQ_W            -1 : 0 ]        cfg_mem_req_size,
    output wire                                         cfg_mem_req_v,
    output wire  [ 2                    -1 : 0 ]        cfg_mem_req_type,
    output wire  [ BUF_TYPE_W           -1 : 0 ]        cfg_mem_req_id,
    output wire  [ LOOP_ID_W            -1 : 0 ]        cfg_mem_req_loop_id,
    
    output wire  [ INST_GROUP_ID_W      -1 : 0 ]        inst_group_id,
    output wire                                         inst_group_type,
    output wire                                         inst_group_s_e,
    output wire                                         inst_group_v,
    output wire                                         inst_group_last,
    
    output wire  [ INST_DATA_WIDTH      -1 : 0 ]        cfg_simd_inst, // instructions for SIMD
    output wire                                         cfg_simd_inst_v,  // instructions for SIMD   

    input  wire                                         simd_group_done,
    // For now, not used
    input  wire  [ INST_GROUP_ID_W      -1 : 0 ]        simd_group_done_id,
    input  wire                                         simd_tiles_done,
    output wire                                         ctrl_simd_start,
    output wire                                         fused_sa_simd,
    input  wire                                         simd_ready,

    //input  wire                                       ap_start                ,
    //output wire                                       ap_idle                 ,
    //output wire                                       ap_done                 ,
    //output wire                                       ap_ready                ,
    output wire                                        interrupt,
    output wire                                        last_store_en,
    output wire                                        simd_start_decode_d,
    output wire  [ ADDR_WIDTH           -1 : 0 ]       axi04_simd_ptr0, 
   // output wire                                        software_reset,

   // perf counters
    output wire [PC_DATA_WIDTH - 1 : 0]                  pc_decode,
    output wire [PC_DATA_WIDTH - 1 : 0]                  pc_end2end,
    output wire [PC_DATA_WIDTH - 1 : 0]                  pc_sys_tot_compute,
    output wire [PC_DATA_WIDTH - 1 : 0]                  pc_num_tiles,
    output wire                                          pc_start,
    input  wire [ADDR_WIDTH    -1 : 0 ]                  pc_waddr,
    input  wire [AXI_DATA_WIDTH-1 : 0 ]                  pc_wdata,
    input wire                                           pc_awvalid,
    input wire  [ADDR_WIDTH    -1 : 0 ]                  pc_awsize,
    input wire                                           pc_wvalid,     
    input wire                                           pc_done,
    output reg  [ADDR_WIDTH    -1 : 0 ]                  physical_pc_base_addr,
    output wire                                          axi_wr_done,
    output wire                                          ignore_bias,
    output wire                                          simd_reset   
    
  );

//=============================================================
// Localparam
//=============================================================

  // GeneSys Instruction Groups and Sequence of Execution
  // For now we just support these three case: SA, SIMD, SA-SIMD (one group from each type)

    // GeneSys controller states
    enum bit [3:0] {
        IDLE                         = 0,
        GET_FIRST_INST_BLOCK         = 1,
        DECODE                       = 2,
        SA                           = 3,
        SA_DONE_WAIT                 = 4,
        SIMD                         = 5,
        SIMD_DONE_WAIT               = 6,
        BLOCK_DONE                   = 7,
        DONE                         = 8,
        PERFORMANCE_COUNT            = 9
    } genesys_state_d, genesys_state_q, genesys_state_qq, genesys_state;


    // TM State
    enum bit [2:0] {
        TM_IDLE                      = 0,
        TM_REQUEST                   = 1,
        TM_CHECK                     = 2,
        TM_WAIT                      = 3,
        TM_FLUSH                     = 4,
        TM_READY_NEXT_REQUEST        = 5
    } tm_state, tm_state_d, tm_state_q, tm_state_qq;

    
    localparam integer SA_GROUP                      = 0;
    localparam integer SIMD_GROUP                    = 1;
    localparam integer GROUP_START                   = 0;
    localparam integer GROUP_END                     = 1;


//=============================================================

//=============================================================
// Wires/Regs
//=============================================================

    
    reg                                         sa_group_v;
    reg                                         simd_group_v;
    wire                                        sa_simd_group_v;
    
    reg  [ INST_GROUP_ID_W      -1 : 0 ]        sa_group_id;
    reg  [ INST_GROUP_ID_W      -1 : 0 ]        simd_group_id;
    reg                                         simd_group_done_q ;
    
    wire                                        chip_start;

    wire                                        genesys_done;


  // DECODER
    wire [ INST_DATA_WIDTH      -1 : 0 ]        imem_read_data;
    wire                                        imem_read_valid;
    wire [ IMEM_ADDR_WIDTH      -1 : 0 ]        imem_read_addr;
    wire                                        imem_read_req;
    wire                                        imem_base_addr_valid;
    wire                                        decoder_start;
    wire                                        decoder_done;
    wire                                        base_loop_ctrl_start;
    wire                                        _base_loop_ctrl_start;
    wire                                        base_loop_ctrl_done;
    wire                                        base_loop_ctrl_stall;
    wire                                        block_done;
    wire                                        last_block;
    wire                                        imem_block_ready;
    wire                                        imem_rd_block_done;
    wire                                        _cfg_set_specific_loop_v;
    wire  [ LOOP_ID_W            -1 : 0 ]       _cfg_set_specific_loop_loop_id;
    wire  [ 2                       : 0 ]		_cfg_set_specific_loop_loop_param;
    wire                                        imem_ld_req_valid;
    wire [ IMM_WIDTH            -1 : 0 ]        imem_ld_req_size;
    wire [ ADDR_WIDTH           -1 : 0 ]        imem_ld_req_addr;
    wire [ ADDR_WIDTH           -1 : 0 ]        ibuf_base_addr;
    wire [ ADDR_WIDTH           -1 : 0 ]        wbuf_base_addr;
    wire [ ADDR_WIDTH           -1 : 0 ]        obuf_base_addr;
    wire [ ADDR_WIDTH           -1 : 0 ]        bbuf_base_addr;
    wire [ ADDR_WIDTH           -1 : 0 ]        physical_ibuf_base_addr;
    wire [ ADDR_WIDTH           -1 : 0 ]        physical_wbuf_base_addr;
    wire [ ADDR_WIDTH           -1 : 0 ]        physical_obuf_base_addr;
    wire [ ADDR_WIDTH           -1 : 0 ]        physical_bbuf_base_addr;
    wire [ ADDR_WIDTH           -1 : 0 ]        imem_base_addr;  
    
// Instruction Memory
    wire [ ADDR_WIDTH           -1 : 0 ]        imem_slave_ld_addr;
    wire [ MEM_REQ_W            -1 : 0 ]        imem_slave_ld_req_size;
    wire                                        imem_slave_ld_req_in;
    
    wire                                        imem_start;
    wire  [ ADDR_WIDTH           -1 : 0 ]       axi00_imem_ptr0;
    wire  [ ADDR_WIDTH           -1 : 0 ]       axi03_obuf_ptr0;
    wire  [ ADDR_WIDTH           -1 : 0 ]        axi02_ibuf_ptr0,axi01_parambuf_ptr0;
    ;

// BASE ADDR GEN
    wire [ INST_GROUP_ID_W      -1 : 0 ]        _cfg_curr_group_id;
    wire [ INST_GROUP_ID_W      -1 : 0 ]        _next_group_id;
    wire [ NUM_MAX_LOOPS        -1 : 0 ]        group_first_iter;


  // resetn for axi slave
    wire                                        resetn;

  // processing complete, interrupt the host
    wire                                         ap_done;

  // Slave registers
    wire [ C_S_AXI_CONTROL_DATA_WIDTH      -1 : 0 ]        slv_reg0_out;
    wire [ C_S_AXI_CONTROL_DATA_WIDTH      -1 : 0 ]        slv_reg1_out;
    wire [ C_S_AXI_CONTROL_DATA_WIDTH      -1 : 0 ]        slv_reg2_out;
    wire [ C_S_AXI_CONTROL_DATA_WIDTH      -1 : 0 ]        slv_reg3_out;
    wire [ C_S_AXI_CONTROL_DATA_WIDTH      -1 : 0 ]        slv_reg4_out;
    wire [ C_S_AXI_CONTROL_DATA_WIDTH      -1 : 0 ]        slv_reg5_out;
    wire [ C_S_AXI_CONTROL_DATA_WIDTH      -1 : 0 ]        slv_reg6_out;
    wire [ C_S_AXI_CONTROL_DATA_WIDTH      -1 : 0 ]        slv_reg7_out;
    wire [ C_S_AXI_CONTROL_DATA_WIDTH      -1 : 0 ]        slv_reg8_out;
    wire [ C_S_AXI_CONTROL_DATA_WIDTH      -1 : 0 ]        slv_reg9_out;
    wire [ C_S_AXI_CONTROL_DATA_WIDTH      -1 : 0 ]        slv_reg10_out;
    wire [ C_S_AXI_CONTROL_DATA_WIDTH      -1 : 0 ]        slv_reg11_out;
    wire [ C_S_AXI_CONTROL_DATA_WIDTH      -1 : 0 ]        slv_reg12_out;
    wire [ C_S_AXI_CONTROL_DATA_WIDTH      -1 : 0 ]        slv_reg13_out;
    wire [ C_S_AXI_CONTROL_DATA_WIDTH      -1 : 0 ]        slv_reg14_out;
  // Slave registers end

  // Accelerator start logic
    wire                                        start_bit_d;
    reg                                         start_bit_q;

    reg                                         tm_tag_reuse_enable;
    reg                                         tm_ibuf_tag_reuse;
    reg                                         tm_obuf_tag_reuse;
    reg                                         tm_wbuf_tag_reuse;
    reg                                         tm_bbuf_tag_reuse;
    reg                                         tm_ibuf_tag_reuse_w;
    reg                                         tm_obuf_tag_reuse_w;
    reg                                         tm_wbuf_tag_reuse_w;
    reg                                         tm_bbuf_tag_reuse_w;

    reg  [ ADDR_WIDTH           -1 : 0 ]        tm_ibuf_tag_addr_d;
    reg  [ ADDR_WIDTH           -1 : 0 ]        tm_ibuf_tag_addr_q;
    reg  [ ADDR_WIDTH           -1 : 0 ]        tm_obuf_tag_addr_d;
    reg  [ ADDR_WIDTH           -1 : 0 ]        tm_obuf_tag_addr_q;
    reg  [ ADDR_WIDTH           -1 : 0 ]        tm_wbuf_tag_addr_d;
    reg  [ ADDR_WIDTH           -1 : 0 ]        tm_wbuf_tag_addr_q;
    reg  [ ADDR_WIDTH           -1 : 0 ]        tm_bias_tag_addr_d;
    reg  [ ADDR_WIDTH           -1 : 0 ]        tm_bias_tag_addr_q;

    wire                                        tm_start;
	  wire 										                    base_ctrl_tag_ready;

  // software reset
  wire                                        software_reset  ;
  
  //
  assign software_reset = slv_reg3_out;
  
  always @(posedge clk)
  begin
    if(reset)
      tm_state_q <= TM_IDLE;
    else
      tm_state_q <= tm_state_d;
  end

  always @(posedge clk)
  begin
    if(reset) begin
      tm_ibuf_tag_addr_q  <= 0;
      tm_obuf_tag_addr_q  <= 0;
      tm_wbuf_tag_addr_q  <= 0;
      tm_bias_tag_addr_q  <= 0;
    end else begin
      tm_ibuf_tag_addr_q  <= tm_ibuf_tag_addr_d;
      tm_obuf_tag_addr_q  <= tm_obuf_tag_addr_d;
      tm_wbuf_tag_addr_q  <= tm_wbuf_tag_addr_d;
      tm_bias_tag_addr_q  <= tm_bias_tag_addr_d;
    end
  end

  always @(*)
  begin
    //tm_tag_reuse_enable = 1'b0;
    tm_state_d = tm_state_q;
    
    tm_ibuf_tag_addr_d = tm_ibuf_tag_addr_q;
    tm_obuf_tag_addr_d = tm_obuf_tag_addr_q;
    tm_wbuf_tag_addr_d = tm_wbuf_tag_addr_q;
    tm_bias_tag_addr_d = tm_bias_tag_addr_q;

    tm_ibuf_tag_reuse = 1'b0;
    tm_obuf_tag_reuse = 1'b0;
    tm_wbuf_tag_reuse = 1'b0;
    tm_bbuf_tag_reuse = 1'b0;
    
    case(tm_state_q)
      TM_IDLE: begin
          tm_ibuf_tag_reuse = 1'b0;
          tm_obuf_tag_reuse = 1'b0;
          tm_wbuf_tag_reuse = 1'b0;
          tm_bbuf_tag_reuse = 1'b0;
        if (tm_start && tag_ready)
          tm_state_d = TM_REQUEST;
      end
      TM_REQUEST: begin
          if (tag_ready) begin
             tm_state_d = TM_CHECK;
          end         
     end    
      TM_CHECK: begin
        if (base_loop_ctrl_start_detect && (ibuf_ld_addr_v && obuf_ld_addr_v && wbuf_ld_addr_v && bbuf_ld_addr_v)) begin
          tm_ibuf_tag_reuse = 1'b0;
          tm_obuf_tag_reuse = 1'b0;
          tm_wbuf_tag_reuse = 1'b0;
          tm_bbuf_tag_reuse = 1'b0;
          tm_ibuf_tag_addr_d = ibuf_ld_addr;
          tm_obuf_tag_addr_d = obuf_ld_addr;
          tm_wbuf_tag_addr_d = wbuf_ld_addr; 
          tm_bias_tag_addr_d = bbuf_ld_addr;  
          tm_state_d = TM_WAIT;
        end
        else if (ibuf_ld_addr_v && obuf_ld_addr_v && wbuf_ld_addr_v && bbuf_ld_addr_v) begin
          tm_ibuf_tag_reuse = tm_ibuf_tag_addr_q == ibuf_ld_addr;
          tm_obuf_tag_reuse = tm_obuf_tag_addr_q == obuf_ld_addr;
          tm_wbuf_tag_reuse = tm_wbuf_tag_addr_q == wbuf_ld_addr;
          tm_bbuf_tag_reuse = tm_bias_tag_addr_q == bbuf_ld_addr;
          
          tm_ibuf_tag_addr_d = ibuf_ld_addr;
          tm_obuf_tag_addr_d = obuf_ld_addr;
          tm_wbuf_tag_addr_d = wbuf_ld_addr; 
          tm_bias_tag_addr_d = bbuf_ld_addr;         
          
          //tm_tag_reuse_enable = 1'b1;
          tm_state_d = TM_WAIT;
        end
      end
      TM_WAIT: begin
          if (genesys_state == BLOCK_DONE)
             tm_state_d = TM_FLUSH;
          else if (tag_ready && genesys_state_qq != SA_DONE_WAIT && genesys_state_qq != SIMD_DONE_WAIT && genesys_state_qq != PERFORMANCE_COUNT )
             tm_state_d = TM_READY_NEXT_REQUEST;            
      end
      TM_READY_NEXT_REQUEST : begin
        tm_state_d = TM_REQUEST;
      end      
      TM_FLUSH: begin
        tm_state_d = TM_IDLE;
      end
    endcase
  end

  assign last_store_en = genesys_state == SA_DONE_WAIT;

/*
    syncFlipFlop_Enable #(.DATA_WIDTH(4)) i_instrReadDone_ff (
        .clk(clk),
        .rst_n(resetn),
        .en(tm_tag_reuse_enable ),
        .D({tm_ibuf_tag_reuse_w, tm_obuf_tag_reuse_w, tm_wbuf_tag_reuse_w, tm_bbuf_tag_reuse_w}), 
        .Q({tm_ibuf_tag_reuse, tm_obuf_tag_reuse, tm_wbuf_tag_reuse, tm_bbuf_tag_reuse}) 
    );
*/
    wire tag_req_d,tag_reg_dd;
    
//    assign tag_req = tm_state_q == TM_CHECK;
    assign tag_req_d = (tm_state_q == TM_CHECK) && (tm_state_qq == TM_REQUEST);
    // rohan: As this was causing tag_sync to keep incrementing the tag. Making it high for one cycle
    //assign tag_req = (tm_state_q == TM_REQUEST) && (tm_state_d == TM_CHECK) ;
    register_sync #(1) tag_req_reg1 (clk, reset, tag_req_d, tag_req_dd);
    register_sync #(1) tag_req_reg2 (clk, reset, tag_req_dd, tag_req_ddd);
    

    assign tag_flush = tm_state_q == TM_FLUSH;

    //assign ibuf_tag_reuse = tm_ibuf_tag_reuse;
    //assign obuf_tag_reuse = tm_obuf_tag_reuse;
    //assign wbuf_tag_reuse = tm_wbuf_tag_reuse;
    //assign bias_tag_reuse = tm_bbuf_tag_reuse;

    
    //always @(posedge clk) begin
    //  if (reset || tm_state_q == TM_IDLE || tm_state_q == TM_FLUSH)
    //    bias_tag_reuse <= 1'b0;
    //  else if (tm_state_q == TM_CHECK)
    //    bias_tag_reuse <= tm_bbuf_tag_reuse;
    //end
    

    register_sync #(1) ibuf_tag_reuse_reg (clk, reset, tm_ibuf_tag_reuse, ibuf_tag_reuse);
    register_sync #(1) obuf_tag_reuse_reg (clk, reset, tm_obuf_tag_reuse, obuf_tag_reuse);
    register_sync #(1) wbuf_tag_reuse_reg (clk, reset, tm_wbuf_tag_reuse, wbuf_tag_reuse);
    register_sync #(1) bbuf_tag_reuse_reg (clk, reset, tm_bbuf_tag_reuse, bias_tag_reuse);
    register_sync #(1) tag_req_reg3   (clk, reset, tag_req_ddd, tag_req);


    assign base_ctrl_tag_ready = tag_ready && tm_state_q == TM_REQUEST;
//=============================================================

//=============================================================
// Accelerator Start logic
//=============================================================
  always @(posedge clk)
  begin
    if (reset)
      start_bit_q <= 1'b0;
    else
      start_bit_q <= start_bit_d;
  end
//=============================================================

//=============================================================
// FSM
//=============================================================
  always @(posedge clk)
  begin
    if (reset) begin
      genesys_state_q <= IDLE;
    end
    else begin
      genesys_state_q <= genesys_state_d;
    end
  end

  always @(*)
  begin
    genesys_state_d = genesys_state_q;
    case(genesys_state_q)
      IDLE: begin
        if (chip_start) begin
          genesys_state_d = GET_FIRST_INST_BLOCK;
        end
      end
      GET_FIRST_INST_BLOCK: begin
        if (imem_block_ready) begin
           genesys_state_d = DECODE; 
        end 
      end    
      DECODE: begin   
        if (_base_loop_ctrl_start) begin      // rohan changed as state machine was struck earlier
//        if (last_block) begin
           if (sa_group_v) 
              genesys_state_d = SA;
           else if (simd_group_v)
              genesys_state_d = SIMD;   
        end
      end
      SA: begin
         if (base_loop_ctrl_done) 
             genesys_state_d = SA_DONE_WAIT;
      end
      SA_DONE_WAIT: begin
         if (ibuf_tag_done && wbuf_tag_done && obuf_tag_done && bias_tag_done)
             if (sa_simd_group_v)
                 genesys_state_d = SIMD_DONE_WAIT;
             else
                 genesys_state_d = PERFORMANCE_COUNT;
      end
      SIMD: begin
         if (simd_group_done)
             genesys_state_d = SIMD_DONE_WAIT;
      end
      SIMD_DONE_WAIT: begin
         if (sa_simd_group_v) begin
            if (simd_group_done_q)
                genesys_state_d = PERFORMANCE_COUNT; 
         end
         else begin
            if (simd_tiles_done)
                genesys_state_d = PERFORMANCE_COUNT;
            else
                genesys_state_d = SIMD;
         end
      end
       PERFORMANCE_COUNT: begin
         if (pc_done) 
             genesys_state_d = BLOCK_DONE;          
      end
      BLOCK_DONE: begin
         if (~last_block) 
             genesys_state_d = DECODE;
         else
             genesys_state_d = DONE;
      end
      DONE: begin
         genesys_state_d = IDLE;
      end
  endcase
  end
  
    reg simd_reset_q;
    always @(posedge clk) begin
        if (reset)
            simd_reset_q <= 1 ;
        else if (genesys_state_d == IDLE) 
            simd_reset_q <= 0;
        else if (genesys_state_d == DECODE)
            simd_reset_q <= 0;
        else if (genesys_state_d ==PERFORMANCE_COUNT ) 
            simd_reset_q <= 0;
        else if (genesys_state_d == BLOCK_DONE || genesys_state_d == DONE)
            simd_reset_q <= 1;
    end
        
    assign simd_reset = simd_reset_q ;
      
     
    assign block_done = genesys_state == BLOCK_DONE;
    assign genesys_done = genesys_state == DONE;
    
    // sending the done handshake signal to host 
    assign ap_done = genesys_done;
    
    //Send start to SIMD when only SIMD block
    reg simd_start_decode;    
    always @(posedge clk) begin
        if(reset)
            simd_start_decode <= 0;
        else if(genesys_state_q == SIMD && genesys_state_qq != SIMD )
            simd_start_decode <= 1;
        else  
            simd_start_decode <= 0;            
    end
    
    assign simd_start_decode_d  = simd_start_decode ;
    assign pc_start = genesys_state_d == PERFORMANCE_COUNT && (genesys_state_q != PERFORMANCE_COUNT);

register_sync #(1) simd_group_done_reg (clk, reset, simd_group_done,simd_group_done_q);


// Counter to count sa_compute_req

  wire sa_compute_req_pulse, sa_compute_req_pulse_q;
  reg [7:0] num_sa_compute_req;
  register_sync #(1) sa_compute_req_pulse_reg (clk, reset, sa_compute_req, sa_compute_req_pulse_q);
  assign sa_compute_req_pulse = sa_compute_req & ~sa_compute_req_pulse_q;
  always @(posedge clk) begin
    if (reset)
      num_sa_compute_req <= 0;
    else if (sa_compute_req_pulse == 1)
      num_sa_compute_req <= num_sa_compute_req + 1;
  end

/*
  ila_0 genesys_ila (
  .clk(clk),
  // 1 bit width
  .probe0(sa_compute_req),
  .probe1(genesys_done),
  .probe2(ibuf_compute_ready),
  .probe3(wbuf_compute_ready),
  .probe4(obuf_compute_ready),
  .probe5(bbuf_compute_ready),
  // 8 bit width
  .probe6(genesys_state_q),
  .probe7(num_sa_compute_req),
  .probe8(tm_state_q),
  .probe9(0),
  .probe10(0),
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

// ILA monitoring combinatorial adder
	// ila_1 i_ila_0 (
	// 	.clk(ap_clk),              // input wire        clk
	// 	.probe0(genesys_state_q)   // input wire [0:0]  probe0  _base_loop_ctrl_start
	// 	//.probe1(chip_start),     // input wire [0:0]  probe1 
	// 	//.probe2(genesys_state_q)   // input wire [0:0]  probe2 
	// 	// .probe3(num_sa_compute_req),    // input wire [63:0] probe3 
	// 	// .probe4(wbuf_compute_ready),     // input wire [0:0]  probe4 
	// 	// .probe5(obuf_compute_ready),   // input wire [0:0]  probe5 
	// 	// .probe6(genesys_state_q)       // input wire [31:0] probe6
	// );
  
//=============================================================
  // GROUPs and Sequence Configuration
//=============================================================
  wire                                      _sa_group_v;
  wire                                      _simd_group_v;
  
  reg  [ INST_GROUP_ID_W         -1 : 0]    _sa_group_counter;
  
  assign _sa_group_v = (inst_group_type == SA_GROUP && inst_group_s_e == GROUP_START && inst_group_v);
  assign _simd_group_v = (inst_group_type == SIMD_GROUP && inst_group_s_e == GROUP_START && inst_group_v);
  
  always @ (posedge clk) begin
    if (reset || genesys_state_d == IDLE || genesys_state_d == BLOCK_DONE) begin
       sa_group_v <= 1'b0;
       simd_group_v <= 1'b0;
       sa_group_id <= 0;
       simd_group_id <= 0;  
    end
    else if (_sa_group_v) begin
       sa_group_v <= 1'b1;
       sa_group_id <= inst_group_id;
    end
    else if (_simd_group_v) begin
       simd_group_v <= 1'b1;
       simd_group_id <= inst_group_id;
    end
  end  
  
  assign sa_simd_group_v = sa_group_v && simd_group_v;
  assign fused_sa_simd = sa_simd_group_v;
  
  always @(posedge clk) begin
     if (reset) 
        _sa_group_counter <= 0; 
     else if (_sa_group_v)
        _sa_group_counter <= _sa_group_counter + 1'b1;
     else if (block_done)
        _sa_group_counter <= 0;
  end
  

  assign _cfg_curr_group_id  = _sa_group_counter;
//=============================================================
// Assigns
//============================================================
    // We use the first register to start the chip
    // We use the second and third register to get the infor about the instruction blocks
    assign resetn = ~reset;
    assign genesys_state = genesys_state_q;
    
    //assign start_bit_d = slv_reg0_out[0];
    assign start_bit_d = ap_start;
    assign chip_start = (start_bit_q ^ start_bit_d) && genesys_state_q == IDLE;
    
    assign imem_slave_ld_addr = axi00_imem_ptr0 + slv_reg5_out;
    assign imem_slave_ld_req_size = slv_reg2_out;
    
    assign imem_start = chip_start;
    
    assign imem_slave_ld_req_in = (genesys_state == GET_FIRST_INST_BLOCK) && (genesys_state_qq != GET_FIRST_INST_BLOCK);
    
    assign imem_ld_req_addr = axi00_imem_ptr0 + imem_base_addr ;
    
    always @(posedge clk) begin
       if (reset) begin
          genesys_state_qq <= IDLE;
          tm_state_qq <= TM_IDLE;
       end
       else begin
          genesys_state_qq <= genesys_state_q; 
          tm_state_qq <= tm_state_q; 
       end
    end
    
    assign decoder_start = (genesys_state == DECODE && genesys_state_qq == GET_FIRST_INST_BLOCK) || (genesys_state == DECODE && genesys_state_qq == BLOCK_DONE);
    
    assign tm_start = (genesys_state == SA) && (genesys_state_qq == DECODE);
    
    wire base_loop_ctrl_start_pre;
    assign base_loop_ctrl_start_pre = (tm_state_d == TM_REQUEST) && (tm_state_q == TM_IDLE);
    assign base_loop_ctrl_start = (tm_state_d == TM_CHECK) && (tm_state_q == TM_REQUEST)  && (tm_state_qq == TM_IDLE);
    //assign base_loop_ctrl_start = (tm_state_q == TM_REQUEST) && (tm_state_qq == TM_IDLE);

    
    // Base Loop CTRL stall logic
    reg                         base_loop_ctrl_start_detect;
    wire [2:0] tm_state_qqq;
    register_sync #(3) tm_state_delay_reg (clk, reset, tm_state_qq, tm_state_qqq);
    wire base_loop_ctrl_start_d;
    register_sync #(1) base_loop_ctrl_start_delay_reg (clk, reset, base_loop_ctrl_start, base_loop_ctrl_start_d);

    // TODO:ROHAN: Make sure the below logic is correct if we have multiple tiles!
    //assign base_loop_ctrl_stall = base_loop_ctrl_start_detect ? tm_state_qqq != TM_REQUEST : tm_state_q != TM_REQUEST;
    assign base_loop_ctrl_stall = base_loop_ctrl_start_detect ? ~(base_loop_ctrl_start_d) : ~(tm_state_q == TM_CHECK && tm_state_qq == TM_REQUEST);
    
    always @(posedge clk) begin
      if (reset)
        base_loop_ctrl_start_detect <= 1'b0;
      else if (base_loop_ctrl_start_pre) 
        base_loop_ctrl_start_detect <= 1'b1;
      else if (tm_state_q == TM_READY_NEXT_REQUEST)
        base_loop_ctrl_start_detect <= 1'b0;
         
    end


    // The below logic is just for the case that we have one SA.
    //TODO: for later, that we support multiple groups we need to revisit this
    assign _next_group_id = _sa_group_counter;
    assign cfg_curr_group_id = _cfg_curr_group_id;
    assign next_group_id = _next_group_id;
    
    reg                                 _group_first_iter_v;
    always @(posedge clk) begin
       if  (reset)
           _group_first_iter_v <= 1'b0;
       else if (genesys_state == DECODE && sa_group_v)
           _group_first_iter_v <= 1'b1;
       else if (tm_state_d == TM_WAIT)
           _group_first_iter_v <= 1'b0;
    end
    assign group_first_iter[1] = _group_first_iter_v;
    //
    
    assign ctrl_simd_start = (((genesys_state == SIMD) && (genesys_state_qq == DECODE)) || ((genesys_state == SIMD) && genesys_state_qq == SIMD_DONE_WAIT)) && simd_ready;
    
    assign sa_compute_req = ibuf_compute_ready && wbuf_compute_ready && obuf_compute_ready && bbuf_compute_ready;
    
    assign done_block = block_done;
//=============================================================


//=============================================================
// Status/Control AXI4-Lite
//=============================================================
localparam integer  LP_NUM_EXAMPLES    = 3;
logic                                ap_start_r                     = 1'b0;
logic                                ap_idle_r                      = 1'b1;
logic                                ap_start_pulse                ;
logic [LP_NUM_EXAMPLES-1:0]          ap_done_i                     ;
logic [LP_NUM_EXAMPLES-1:0]          ap_done_r                      = {LP_NUM_EXAMPLES{1'b0}};

// create pulse when ap_start transitions to 1
always @(posedge clk) begin
  if (reset)
    ap_start_r <= 0;
  else
    begin
      ap_start_r <= ap_start;
    end
end

assign ap_start_pulse = ap_start & ~ap_start_r;

// ap_idle is asserted when done is asserted, it is de-asserted when ap_start_pulse
// is asserted
always @(posedge clk) begin
  if (reset) begin
    ap_idle_r <= 1'b1;
  end
  else begin
    ap_idle_r <= ap_done ? 1'b1 : ap_start_pulse ? 1'b0 : ap_idle;
  end
end

assign ap_idle = ap_idle_r;

// Done logic
always @(posedge clk) begin
  if (reset) begin
    ap_done_r <= '0;
  end
  else begin
    ap_done_r <= (ap_done) ? '0 : ap_done_r | ap_done_i;
  end
end

// Ready Logic (non-pipelined case)
assign ap_ready = ap_start_pulse ? 1'b0 : 1'b1;

//=============================================================

// AXI4-Lite slave interface
systolic_fpga_control_s_axi #(
  .C_S_AXI_ADDR_WIDTH ( C_S_AXI_CONTROL_ADDR_WIDTH ),
  .C_S_AXI_DATA_WIDTH ( C_S_AXI_CONTROL_DATA_WIDTH )
)
inst_control_s_axi (
  .ACLK                ( clk                ),
  .ARESET              ( reset                ),
  .ACLK_EN             ( 1'b1                  ),
  .AWVALID             ( pci_cl_ctrl_awvalid ),
  .AWREADY             ( pci_cl_ctrl_awready ),
  .AWADDR              ( pci_cl_ctrl_awaddr  ),
  .WVALID              ( pci_cl_ctrl_wvalid  ),
  .WREADY              ( pci_cl_ctrl_wready  ),
  .WDATA               ( pci_cl_ctrl_wdata   ),
  .WSTRB               ( pci_cl_ctrl_wstrb   ),
  .ARVALID             ( pci_cl_ctrl_arvalid ),
  .ARREADY             ( pci_cl_ctrl_arready ),
  .ARADDR              ( pci_cl_ctrl_araddr  ),
  .RVALID              ( pci_cl_ctrl_rvalid  ),
  .RREADY              ( pci_cl_ctrl_rready  ),
  .RDATA               ( pci_cl_ctrl_rdata   ),
  .RRESP               ( pci_cl_ctrl_rresp   ),
  .BVALID              ( pci_cl_ctrl_bvalid  ),
  .BREADY              ( pci_cl_ctrl_bready  ),
  .BRESP               ( pci_cl_ctrl_bresp   ),
  .interrupt           ( interrupt             ),
  .ap_start            ( ap_start              ),
  .ap_done             ( ap_done               ),
  .ap_ready            ( ap_ready              ),
  .ap_idle             ( ap_idle               ),
  .slv_reg0_out        ( slv_reg0_out          ),
  .slv_reg1_out        ( slv_reg1_out          ),
  .slv_reg2_out        ( slv_reg2_out          ),
  .slv_reg3_out        ( slv_reg3_out          ),
  .slv_reg4_out        ( slv_reg4_out          ),
  .slv_reg5_out        ( slv_reg5_out          ),
  .slv_reg6_out        ( slv_reg6_out          ),
  .slv_reg7_out        ( slv_reg7_out          ),
  .slv_reg8_out        ( slv_reg8_out          ),
  .slv_reg9_out        ( slv_reg9_out          ),
  .slv_reg10_out       ( slv_reg10_out         ),
  .slv_reg11_out       ( slv_reg11_out         ),
  .slv_reg12_out       ( slv_reg12_out         ),
  .slv_reg13_out       ( slv_reg13_out         ),
  .slv_reg14_out       ( slv_reg14_out         ),
  .axi00_imem_ptr0     ( axi00_imem_ptr0       ),
  .axi01_parambuf_ptr0 ( axi01_parambuf_ptr0   ),
  .axi02_ibuf_ptr0     ( axi02_ibuf_ptr0       ),
  .axi03_obuf_ptr0     ( axi03_obuf_ptr0       ),
  .axi04_simd_ptr0     ( axi04_simd_ptr0       )
);


//=============================================================

//=============================================================
// Instruction Memory
//=============================================================
  instruction_memory_wrapper #(
    .MEM_REQ_W                      ( MEM_REQ_W                      ),
    .AXI_ADDR_WIDTH                 ( ADDR_WIDTH                     ),
    .AXI_DATA_WIDTH                 ( AXI_DATA_WIDTH                 ),
    .AXI_BURST_WIDTH                ( AXI_BURST_WIDTH                ),
    .INST_DATA_WIDTH                ( INST_DATA_WIDTH                ),
    .INST_ADDR_WIDTH                ( IMEM_ADDR_WIDTH                )    
  ) inst_memory (
    .clk                            ( clk                            ),
    .reset                          ( reset                          ),
    .start                          ( imem_start                     ),
    .imem_rd_req                    ( imem_read_req                  ),
    .imem_rd_addr                   ( imem_read_addr                 ),
    .imem_rd_block_done             ( imem_rd_block_done             ),
    .imem_rd_data                   ( imem_read_data                 ),
    .imem_rd_valid                  ( imem_read_valid                ),
    .imem_block_ready               ( imem_block_ready               ),
    .imem_awaddr                    ( imem_awaddr                    ),
    .imem_awlen                     ( imem_awlen                     ),
    //.imem_awsize                    ( imem_awsize                    ),
    //.imem_awburst                   ( imem_awburst                   ),
    .imem_awvalid                   ( imem_awvalid                   ),
    .imem_awready                   ( imem_awready                   ),
    .imem_wdata                     ( imem_wdata                     ),
    .imem_wstrb                     ( imem_wstrb                     ),
    .imem_wlast                     ( imem_wlast                     ),
    .imem_wvalid                    ( imem_wvalid                    ),
    .imem_wready                    ( imem_wready                    ),
    //.imem_bresp                     ( imem_bresp                     ),
    .imem_bvalid                    ( imem_bvalid                    ),
    .imem_bready                    ( imem_bready                    ),
    .imem_araddr                    ( imem_araddr                    ),
    .imem_arlen                     ( imem_arlen                     ),
    //.imem_arsize                    ( imem_arsize                    ),
    //.imem_arburst                   ( imem_arburst                   ),
    .imem_arvalid                   ( imem_arvalid                   ),
    //.imem_arid                      ( imem_arid                      ),
    .imem_arready                   ( imem_arready                   ),
    .imem_rdata                     ( imem_rdata                     ),
    //.imem_rresp                     ( imem_rresp                     ),
    .imem_rlast                     ( imem_rlast                     ),
    .imem_rvalid                    ( imem_rvalid                    ),
    //.imem_rid                       ( imem_rid                       ),
    .imem_rready                    ( imem_rready                    ),
    .slave_ld_addr                  ( imem_slave_ld_addr             ),
    .slave_ld_req_size              ( imem_slave_ld_req_size         ),
    .slave_ld_req_in                ( imem_slave_ld_req_in           ),
    .decoder_ld_addr                ( imem_ld_req_addr               ),
    .decoder_ld_req_size            ( imem_ld_req_size               ),
    .decoder_ld_req_in              ( imem_ld_req_valid              ),
    .pc_waddr                       ( pc_waddr                       ),
    .pc_wdata                       ( pc_wdata                       ),
    .pc_awvalid                     ( pc_awvalid                     ),
    .pc_awsize                      ( pc_awsize                      ),
    .pc_wvalid                      ( pc_wvalid                      ),
    .axi_wr_done                    ( axi_wr_done                    )
  );
//=============================================================


//=============================================================
// Decoder
//=============================================================
  decoder #(
    .IMEM_ADDR_W                    ( IMEM_ADDR_WIDTH                ),
    .DDR_ADDR_W                     ( ADDR_WIDTH                     ),
    .INST_W                         ( INST_DATA_WIDTH                ),
    .BUF_TYPE_W                     ( BUF_TYPE_W                     ),
    .IMM_WIDTH                      ( IMM_WIDTH                      ),
    .OP_CODE_W                      ( OP_CODE_W                      ),
    .OP_SPEC_W                      ( OP_SPEC_W                      ),
    .LOOP_ID_W                      ( LOOP_ID_W                      ),
    .INST_GROUP_ID_W                ( INST_GROUP_ID_W                ),
    .WAIT_CYCLES                    ( EXEC_DONE_WAIT_CYCLES          )             
    
  ) instruction_decoder (
    .clk                            ( clk                            ), 
    .reset                          ( reset                          ), 
    .imem_read_data                 ( imem_read_data                 ),
    .imem_read_valid                ( imem_read_valid                ),
    .imem_read_addr                 ( imem_read_addr                 ),
    .imem_read_req                  ( imem_read_req                  ),
    .imem_base_addr_valid           ( imem_base_addr_valid           ),
    .start                          ( decoder_start                  ),
    .done                           ( decoder_done                   ),
    .loop_ctrl_start                ( _base_loop_ctrl_start          ),
    .block_done                     ( block_done                     ),
    .last_block                     ( last_block                     ),
    .next_block_ready               ( imem_block_ready               ),
    .imem_rd_block_done             ( imem_rd_block_done             ),
    .cfg_loop_iter_v                ( cfg_loop_iter_v                ),
    .cfg_loop_iter                  ( cfg_loop_iter                  ),
    .cfg_loop_iter_loop_id          ( cfg_loop_iter_loop_id          ),
    .cfg_set_specific_loop_v        ( cfg_set_specific_loop_v        ),
    .cfg_set_specific_loop_loop_id  ( cfg_set_specific_loop_loop_id  ),
    .cfg_set_specific_loop_loop_param (cfg_set_specific_loop_loop_param ),
    .cfg_loop_stride_v              ( cfg_loop_stride_v              ),
    .cfg_loop_stride_type           ( cfg_loop_stride_type           ),
    .cfg_loop_stride                ( cfg_loop_stride                ),
    .cfg_loop_stride_loop_id        ( cfg_loop_stride_loop_id        ),
    .cfg_loop_stride_id             ( cfg_loop_stride_id             ),
    .cfg_mem_req_v                  ( cfg_mem_req_v                  ),
    .cfg_mem_req_size               ( cfg_mem_req_size               ),
    .cfg_mem_req_type               ( cfg_mem_req_type               ),
    .cfg_mem_req_loop_id            ( cfg_mem_req_loop_id            ),
    .cfg_mem_req_id                 ( cfg_mem_req_id                 ),
    .imem_ld_req_valid              ( imem_ld_req_valid              ),
    .imem_ld_req_size               ( imem_ld_req_size               ),
    .ibuf_base_addr                 ( ibuf_base_addr                 ),
    .wbuf_base_addr                 ( wbuf_base_addr                 ),
    .obuf_base_addr                 ( obuf_base_addr                 ),
    .bias_base_addr                 ( bbuf_base_addr                 ),
    .imem_base_addr                 ( imem_base_addr                 ),
    .inst_group_id                  ( inst_group_id                  ),
    .inst_group_type                ( inst_group_type                ),
    .inst_group_s_e                 ( inst_group_s_e                 ),
    .inst_group_v                   ( inst_group_v                   ),
    .inst_group_last                ( inst_group_last                ),
    .cfg_simd_inst                  ( cfg_simd_inst                  ),
    .cfg_simd_inst_v                ( cfg_simd_inst_v                ),
    .ignore_bias                    ( ignore_bias                    )
  );
//=============================================================


 // Sort of Virtual to Physical memory conversion by adding fixed offset at runtime.
 wire [ADDR_WIDTH-1:0] physical_pc_base_addr_d ;
 assign physical_ibuf_base_addr = ibuf_base_addr + axi00_imem_ptr0;
 assign physical_wbuf_base_addr = wbuf_base_addr + axi00_imem_ptr0;
 assign physical_bbuf_base_addr = bbuf_base_addr + axi00_imem_ptr0;
 assign physical_obuf_base_addr = obuf_base_addr + axi03_obuf_ptr0;
// assign physical_pc_base_addr   = obuf_base_addr + axi03_obuf_ptr0 + slv_reg4_out;
 assign physical_pc_base_addr_d   =  64'd0 + axi00_imem_ptr0; 
 always @(posedge clk)  // Strange Vivado bug during impl opt. 
	 physical_pc_base_addr <= physical_pc_base_addr_d ;

 assign _cfg_set_specific_loop_v = cfg_set_specific_loop_v;
 assign _cfg_set_specific_loop_loop_id = cfg_set_specific_loop_loop_id;
 assign _cfg_set_specific_loop_loop_param  = cfg_set_specific_loop_loop_param;

//=============================================================
// Base address generator
//    This module is in charge of the outer loops (base loops for tiles)
//=============================================================
  base_addr_gen #(
    .ADDR_WIDTH                     ( ADDR_WIDTH                     ),
    .LOOP_ITER_W                    ( LOOP_ITER_W                    ),
    .ADDR_STRIDE_W                  ( ADDR_STRIDE_W                  ),
    .LOOP_ID_W                      ( LOOP_ID_W                      ),
    .INST_GROUP_ID_W                ( INST_GROUP_ID_W                ),
    .BUF_TYPE_W                     ( BUF_TYPE_W                     ),
    .GROUP_ENABLED                  ( GROUP_ENABLED                  )
  ) base_ctrl (
    .clk                            ( clk                            ), //input
    .reset                          ( reset                          ), //input

    .start                          ( base_loop_ctrl_start           ), //input
    .done                           ( base_loop_ctrl_done            ), //output
    .block_done                     ( block_done                     ),
    
    .cfg_curr_group_id              ( _cfg_curr_group_id              ),
    .next_group_id                  ( _next_group_id                  ),
    .group_first_iter               ( group_first_iter               ),
    
    .stall                          ( base_loop_ctrl_stall           ),
    
    .cfg_loop_iter_v                ( cfg_loop_iter_v                ),
    .cfg_loop_iter                  ( cfg_loop_iter                  ),
    .cfg_loop_iter_loop_id          ( cfg_loop_iter_loop_id          ),
    .cfg_set_specific_loop_v        ( _cfg_set_specific_loop_v        ),
    .cfg_set_specific_loop_loop_id  (_cfg_set_specific_loop_loop_id   ),
    .cfg_set_specific_loop_loop_param (_cfg_set_specific_loop_loop_param),
    .cfg_loop_stride_v              ( cfg_loop_stride_v              ),
    .cfg_loop_stride                ( cfg_loop_stride                ),
    .cfg_loop_stride_loop_id        ( cfg_loop_stride_loop_id        ),
    .cfg_loop_stride_id             ( cfg_loop_stride_id             ),
    .cfg_loop_stride_type           ( cfg_loop_stride_type           ),
    .inst_group_id                  ( inst_group_id                  ),
    .inst_group_type                ( inst_group_type                ),
    .inst_group_s_e                 ( inst_group_s_e                 ),
    .inst_group_v                   ( inst_group_v                   ),
    .inst_group_last                ( inst_group_last                ),
    
    .obuf_base_addr                 ( physical_obuf_base_addr                 ),
    .obuf_ld_addr                   ( obuf_ld_addr                   ),
    .obuf_ld_addr_v                 ( obuf_ld_addr_v                 ),
    .obuf_st_addr                   ( obuf_st_addr                   ),
    .obuf_st_addr_v                 ( obuf_st_addr_v                 ),  
    .ibuf_base_addr                 ( physical_ibuf_base_addr                 ),
    .ibuf_ld_addr                   ( ibuf_ld_addr                   ),
    .ibuf_ld_addr_v                 ( ibuf_ld_addr_v                 ),  
    .bbuf_base_addr                 ( physical_bbuf_base_addr                 ),
    .bbuf_ld_addr                   ( bbuf_ld_addr                   ),
    .bbuf_ld_addr_v                 ( bbuf_ld_addr_v                 ),  
    .wbuf_base_addr                 ( physical_wbuf_base_addr                 ),
    .wbuf_ld_addr                   ( wbuf_ld_addr                   ),
    .wbuf_ld_addr_v                 ( wbuf_ld_addr_v                 ),     

    .first_ic_outer_loop_ld         ( tag_first_ic_outer_loop_ld     ), //output
    .ddr_pe_sw                      ( tag_ddr_pe_sw                  )  //output
  );
//=============================================================

//================= PERFORMANCE COUNTERS ======================

// Perf Counter Enables
wire pc_decode_en, pc_end2end_en, pc_sys_compute_per_tile_en, pc_sys_tot_compute_en, pc_num_tiles_en;

assign pc_decode_en = genesys_state == GET_FIRST_INST_BLOCK || genesys_state == DECODE;
assign pc_end2end_en = genesys_state != IDLE  && genesys_state != PERFORMANCE_COUNT  &&  genesys_state != BLOCK_DONE  &&  genesys_state != DONE;
assign pc_sys_tot_compute_en = sa_compute_req;
assign pc_num_tiles_en = sa_compute_req_pulse;

// Decode Cycles
perf_counter #(
    .DATA_WIDTH (PC_DATA_WIDTH)
) pc_decode_inst
  (
    .clk (clk),
    .en (pc_decode_en),
    .rst (reset),
    .out (pc_decode)
  );

//end to end cycles
perf_counter #(
    .DATA_WIDTH (PC_DATA_WIDTH)
) pc_end2end_inst
  (
    .clk (clk),
    .en (pc_end2end_en),
    .rst (reset),
    .out (pc_end2end)
  );

//systolic total compute cycles
perf_counter #(
    .DATA_WIDTH (PC_DATA_WIDTH)
) pc_tot_compute
  (
    .clk (clk),
    .en (pc_sys_tot_compute_en),
    .rst (reset),
    .out (pc_sys_tot_compute)
  );

// num tiles
perf_counter #(
    .DATA_WIDTH (PC_DATA_WIDTH)
) pc_num_tile
  (
    .clk (clk),
    .en (pc_num_tiles_en),
    .rst (reset),
    .out (pc_num_tiles)
  );

//=============================================================

endmodule
