`timescale 1ns/1ps
module systolic_fpga_control_s_axi
#(parameter
    C_S_AXI_ADDR_WIDTH = 8,
    C_S_AXI_DATA_WIDTH = 32
)(
    input  wire                          ACLK,
    input  wire                          ARESET,
    input  wire                          ACLK_EN,
    input  wire [C_S_AXI_ADDR_WIDTH-1:0] AWADDR,
    input  wire                          AWVALID,
    output wire                          AWREADY,
    input  wire [C_S_AXI_DATA_WIDTH-1:0] WDATA,
    input  wire [C_S_AXI_DATA_WIDTH/8-1:0] WSTRB,
    input  wire                          WVALID,
    output wire                          WREADY,
    output wire [1:0]                    BRESP,
    output wire                          BVALID,
    input  wire                          BREADY,
    input  wire [C_S_AXI_ADDR_WIDTH-1:0] ARADDR,
    input  wire                          ARVALID,
    output wire                          ARREADY,
    output wire [C_S_AXI_DATA_WIDTH-1:0] RDATA,
    output wire [1:0]                    RRESP,
    output wire                          RVALID,
    input  wire                          RREADY,
    output wire                          interrupt,
    output wire [31:0]                   slv_reg0_out,
    output wire [31:0]                   slv_reg1_out,
    output wire [31:0]                   slv_reg2_out,
    output wire [31:0]                   slv_reg3_out,
    output wire [31:0]                   slv_reg4_out,
    output wire [31:0]                   slv_reg5_out,
    output wire [31:0]                   slv_reg6_out,
    output wire [31:0]                   slv_reg7_out,
    output wire [31:0]                   slv_reg8_out,
    output wire [31:0]                   slv_reg9_out,
    output wire [31:0]                   slv_reg10_out,
    output wire [31:0]                   slv_reg11_out,
    output wire [31:0]                   slv_reg12_out,
    output wire [31:0]                   slv_reg13_out,
    output wire [31:0]                   slv_reg14_out,
    output wire [63:0]                   axi00_imem_ptr0,
    output wire [63:0]                   axi01_parambuf_ptr0,
    output wire [63:0]                   axi02_ibuf_ptr0,
    output wire [63:0]                   axi03_obuf_ptr0,
    output wire [63:0]                   axi04_simd_ptr0,
    output wire                          ap_start,
    input  wire                          ap_done,
    input  wire                          ap_ready,
    input  wire                          ap_idle
);
//------------------------Address Info-------------------
// 0x00 : Control signals
//        bit 0  - ap_start (Read/Write/COH)
//        bit 1  - ap_done (Read/COR)
//        bit 2  - ap_idle (Read)
//        bit 3  - ap_ready (Read)
//        bit 7  - auto_restart (Read/Write)
//        others - reserved
// 0x04 : Global Interrupt Enable Register
//        bit 0  - Global Interrupt Enable (Read/Write)
//        others - reserved
// 0x08 : IP Interrupt Enable Register (Read/Write)
//        bit 0  - enable ap_done interrupt (Read/Write)
//        bit 1  - enable ap_ready interrupt (Read/Write)
//        others - reserved
// 0x0c : IP Interrupt Status Register (Read/TOW)
//        bit 0  - ap_done (COR/TOW)
//        bit 1  - ap_ready (COR/TOW)
//        others - reserved
// 0x10 : Data signal of slv_reg0_out
//        bit 31~0 - slv_reg0_out[31:0] (Read/Write)
// 0x14 : reserved
// 0x18 : Data signal of slv_reg1_out
//        bit 31~0 - slv_reg1_out[31:0] (Read/Write)
// 0x1c : reserved
// 0x20 : Data signal of slv_reg2_out
//        bit 31~0 - slv_reg2_out[31:0] (Read/Write)
// 0x24 : reserved
// 0x28 : Data signal of slv_reg3_out
//        bit 31~0 - slv_reg3_out[31:0] (Read/Write)
// 0x2c : reserved
// 0x30 : Data signal of slv_reg4_out
//        bit 31~0 - slv_reg4_out[31:0] (Read/Write)
// 0x34 : reserved
// 0x38 : Data signal of slv_reg5_out
//        bit 31~0 - slv_reg5_out[31:0] (Read/Write)
// 0x3c : reserved
// 0x40 : Data signal of slv_reg6_out
//        bit 31~0 - slv_reg6_out[31:0] (Read/Write)
// 0x44 : reserved
// 0x48 : Data signal of slv_reg7_out
//        bit 31~0 - slv_reg7_out[31:0] (Read/Write)
// 0x4c : reserved
// 0x50 : Data signal of slv_reg8_out
//        bit 31~0 - slv_reg8_out[31:0] (Read/Write)
// 0x54 : reserved
// 0x58 : Data signal of slv_reg9_out
//        bit 31~0 - slv_reg9_out[31:0] (Read/Write)
// 0x5c : reserved
// 0x60 : Data signal of slv_reg10_out
//        bit 31~0 - slv_reg10_out[31:0] (Read/Write)
// 0x64 : reserved
// 0x68 : Data signal of slv_reg11_out
//        bit 31~0 - slv_reg11_out[31:0] (Read/Write)
// 0x6c : reserved
// 0x70 : Data signal of slv_reg12_out
//        bit 31~0 - slv_reg12_out[31:0] (Read/Write)
// 0x74 : reserved
// 0x78 : Data signal of slv_reg13_out
//        bit 31~0 - slv_reg13_out[31:0] (Read/Write)
// 0x7c : reserved
// 0x80 : Data signal of slv_reg14_out
//        bit 31~0 - slv_reg14_out[31:0] (Read/Write)
// 0x84 : reserved
// 0x88 : Data signal of axi00_imem_ptr0
//        bit 31~0 - axi00_imem_ptr0[31:0] (Read/Write)
// 0x8c : Data signal of axi00_imem_ptr0
//        bit 31~0 - axi00_imem_ptr0[63:32] (Read/Write)
// 0x90 : reserved
// 0x94 : Data signal of axi01_parambuf_ptr0
//        bit 31~0 - axi01_parambuf_ptr0[31:0] (Read/Write)
// 0x98 : Data signal of axi01_parambuf_ptr0
//        bit 31~0 - axi01_parambuf_ptr0[63:32] (Read/Write)
// 0x9c : reserved
// 0xa0 : Data signal of axi02_ibuf_ptr0
//        bit 31~0 - axi02_ibuf_ptr0[31:0] (Read/Write)
// 0xa4 : Data signal of axi02_ibuf_ptr0
//        bit 31~0 - axi02_ibuf_ptr0[63:32] (Read/Write)
// 0xa8 : reserved
// 0xac : Data signal of axi03_obuf_ptr0
//        bit 31~0 - axi03_obuf_ptr0[31:0] (Read/Write)
// 0xb0 : Data signal of axi03_obuf_ptr0
//        bit 31~0 - axi03_obuf_ptr0[63:32] (Read/Write)
// 0xb4 : reserved
// 0xb8 : Data signal of axi04_simd_ptr0
//        bit 31~0 - axi04_simd_ptr0[31:0] (Read/Write)
// 0xbc : Data signal of axi04_simd_ptr0
//        bit 31~0 - axi04_simd_ptr0[63:32] (Read/Write)
// 0xc0 : reserved
// (SC = Self Clear, COR = Clear on Read, TOW = Toggle on Write, COH = Clear on Handshake)

//------------------------Parameter----------------------
localparam
    ADDR_AP_CTRL                    = 8'h00,
    ADDR_GIE                        = 8'h04,
    ADDR_IER                        = 8'h08,
    ADDR_ISR                        = 8'h0c,
    ADDR_SLV_REG0_OUT_DATA_0        = 8'h10,
    ADDR_SLV_REG0_OUT_CTRL          = 8'h14,
    ADDR_SLV_REG1_OUT_DATA_0        = 8'h18,
    ADDR_SLV_REG1_OUT_CTRL          = 8'h1c,
    ADDR_SLV_REG2_OUT_DATA_0        = 8'h20,
    ADDR_SLV_REG2_OUT_CTRL          = 8'h24,
    ADDR_SLV_REG3_OUT_DATA_0        = 8'h28,
    ADDR_SLV_REG3_OUT_CTRL          = 8'h2c,
    ADDR_SLV_REG4_OUT_DATA_0        = 8'h30,
    ADDR_SLV_REG4_OUT_CTRL          = 8'h34,
    ADDR_SLV_REG5_OUT_DATA_0        = 8'h38,
    ADDR_SLV_REG5_OUT_CTRL          = 8'h3c,
    ADDR_SLV_REG6_OUT_DATA_0        = 8'h40,
    ADDR_SLV_REG6_OUT_CTRL          = 8'h44,
    ADDR_SLV_REG7_OUT_DATA_0        = 8'h48,
    ADDR_SLV_REG7_OUT_CTRL          = 8'h4c,
    ADDR_SLV_REG8_OUT_DATA_0        = 8'h50,
    ADDR_SLV_REG8_OUT_CTRL          = 8'h54,
    ADDR_SLV_REG9_OUT_DATA_0        = 8'h58,
    ADDR_SLV_REG9_OUT_CTRL          = 8'h5c,
    ADDR_SLV_REG10_OUT_DATA_0       = 8'h60,
    ADDR_SLV_REG10_OUT_CTRL         = 8'h64,
    ADDR_SLV_REG11_OUT_DATA_0       = 8'h68,
    ADDR_SLV_REG11_OUT_CTRL         = 8'h6c,
    ADDR_SLV_REG12_OUT_DATA_0       = 8'h70,
    ADDR_SLV_REG12_OUT_CTRL         = 8'h74,
    ADDR_SLV_REG13_OUT_DATA_0       = 8'h78,
    ADDR_SLV_REG13_OUT_CTRL         = 8'h7c,
    ADDR_SLV_REG14_OUT_DATA_0       = 8'h80,
    ADDR_SLV_REG14_OUT_CTRL         = 8'h84,
    ADDR_AXI00_IMEM_PTR0_DATA_0     = 8'h88,
    ADDR_AXI00_IMEM_PTR0_DATA_1     = 8'h8c,
    ADDR_AXI00_IMEM_PTR0_CTRL       = 8'h90,
    ADDR_AXI01_PARAMBUF_PTR0_DATA_0 = 8'h94,
    ADDR_AXI01_PARAMBUF_PTR0_DATA_1 = 8'h98,
    ADDR_AXI01_PARAMBUF_PTR0_CTRL   = 8'h9c,
    ADDR_AXI02_IBUF_PTR0_DATA_0     = 8'ha0,
    ADDR_AXI02_IBUF_PTR0_DATA_1     = 8'ha4,
    ADDR_AXI02_IBUF_PTR0_CTRL       = 8'ha8,
    ADDR_AXI03_OBUF_PTR0_DATA_0     = 8'hac,
    ADDR_AXI03_OBUF_PTR0_DATA_1     = 8'hb0,
    ADDR_AXI03_OBUF_PTR0_CTRL       = 8'hb4,
    ADDR_AXI04_SIMD_PTR0_DATA_0     = 8'hb8,
    ADDR_AXI04_SIMD_PTR0_DATA_1     = 8'hbc,
    ADDR_AXI04_SIMD_PTR0_CTRL       = 8'hc0,
    WRIDLE                          = 2'd0,
    WRDATA                          = 2'd1,
    WRRESP                          = 2'd2,
    WRRESET                         = 2'd3,
    RDIDLE                          = 2'd0,
    RDDATA                          = 2'd1,
    RDRESET                         = 2'd2,
    ADDR_BITS                = 8;

//------------------------Local signal-------------------
    reg  [1:0]                    wstate = WRRESET;
    reg  [1:0]                    wnext;
    reg  [ADDR_BITS-1:0]          waddr;
    wire [C_S_AXI_DATA_WIDTH-1:0] wmask;
    wire                          aw_hs;
    wire                          w_hs;
    reg  [1:0]                    rstate = RDRESET;
    reg  [1:0]                    rnext;
    reg  [C_S_AXI_DATA_WIDTH-1:0] rdata;
    wire                          ar_hs;
    wire [ADDR_BITS-1:0]          raddr;
    // internal registers
    reg                           int_ap_idle;
    reg                           int_ap_ready;
    reg                           int_ap_done = 1'b0;
    reg                           int_ap_start = 1'b0;
    reg                           int_auto_restart = 1'b0;
    reg                           int_gie = 1'b0;
    reg  [1:0]                    int_ier = 2'b0;
    reg  [1:0]                    int_isr = 2'b0;
    reg  [31:0]                   int_slv_reg0_out = 'b0;
    reg  [31:0]                   int_slv_reg1_out = 'b0;
    reg  [31:0]                   int_slv_reg2_out = 'b0;
    reg  [31:0]                   int_slv_reg3_out = 'b0;
    reg  [31:0]                   int_slv_reg4_out = 'b0;
    reg  [31:0]                   int_slv_reg5_out = 'b0;
    reg  [31:0]                   int_slv_reg6_out = 'b0;
    reg  [31:0]                   int_slv_reg7_out = 'b0;
    reg  [31:0]                   int_slv_reg8_out = 'b0;
    reg  [31:0]                   int_slv_reg9_out = 'b0;
    reg  [31:0]                   int_slv_reg10_out = 'b0;
    reg  [31:0]                   int_slv_reg11_out = 'b0;
    reg  [31:0]                   int_slv_reg12_out = 'b0;
    reg  [31:0]                   int_slv_reg13_out = 'b0;
    reg  [31:0]                   int_slv_reg14_out = 'b0;
    reg  [63:0]                   int_axi00_imem_ptr0 = 'b0;
    reg  [63:0]                   int_axi01_parambuf_ptr0 = 'b0;
    reg  [63:0]                   int_axi02_ibuf_ptr0 = 'b0;
    reg  [63:0]                   int_axi03_obuf_ptr0 = 'b0;
    reg  [63:0]                   int_axi04_simd_ptr0 = 'b0;

//------------------------Instantiation------------------


//------------------------AXI write fsm------------------
assign AWREADY = (wstate == WRIDLE);
assign WREADY  = (wstate == WRDATA);
assign BRESP   = 2'b00;  // OKAY
assign BVALID  = (wstate == WRRESP);
assign wmask   = { {8{WSTRB[3]}}, {8{WSTRB[2]}}, {8{WSTRB[1]}}, {8{WSTRB[0]}} };
assign aw_hs   = AWVALID & AWREADY;
assign w_hs    = WVALID & WREADY;

// wstate
always @(posedge ACLK) begin
    if (ARESET)
        wstate <= WRRESET;
    else if (ACLK_EN)
        wstate <= wnext;
end

// wnext
always @(*) begin
    case (wstate)
        WRIDLE:
            if (AWVALID)
                wnext = WRDATA;
            else
                wnext = WRIDLE;
        WRDATA:
            if (WVALID)
                wnext = WRRESP;
            else
                wnext = WRDATA;
        WRRESP:
            if (BREADY)
                wnext = WRIDLE;
            else
                wnext = WRRESP;
        default:
            wnext = WRIDLE;
    endcase
end

// waddr
always @(posedge ACLK) begin
    if (ACLK_EN) begin
        if (aw_hs)
            waddr <= AWADDR[ADDR_BITS-1:0];
    end
end

//------------------------AXI read fsm-------------------
assign ARREADY = (rstate == RDIDLE);
assign RDATA   = rdata;
assign RRESP   = 2'b00;  // OKAY
assign RVALID  = (rstate == RDDATA);
assign ar_hs   = ARVALID & ARREADY;
assign raddr   = ARADDR[ADDR_BITS-1:0];

// rstate
always @(posedge ACLK) begin
    if (ARESET)
        rstate <= RDRESET;
    else if (ACLK_EN)
        rstate <= rnext;
end

// rnext
always @(*) begin
    case (rstate)
        RDIDLE:
            if (ARVALID)
                rnext = RDDATA;
            else
                rnext = RDIDLE;
        RDDATA:
            if (RREADY & RVALID)
                rnext = RDIDLE;
            else
                rnext = RDDATA;
        default:
            rnext = RDIDLE;
    endcase
end

// rdata
always @(posedge ACLK) begin
    if (ACLK_EN) begin
        if (ar_hs) begin
            rdata <= 'b0;
            case (raddr)
                ADDR_AP_CTRL: begin
                    rdata[0] <= int_ap_start;
                    rdata[1] <= int_ap_done;
                    rdata[2] <= int_ap_idle;
                    rdata[3] <= int_ap_ready;
                    rdata[7] <= int_auto_restart;
                end
                ADDR_GIE: begin
                    rdata <= int_gie;
                end
                ADDR_IER: begin
                    rdata <= int_ier;
                end
                ADDR_ISR: begin
                    rdata <= int_isr;
                end
                ADDR_SLV_REG0_OUT_DATA_0: begin
                    rdata <= int_slv_reg0_out[31:0];
                end
                ADDR_SLV_REG1_OUT_DATA_0: begin
                    rdata <= int_slv_reg1_out[31:0];
                end
                ADDR_SLV_REG2_OUT_DATA_0: begin
                    rdata <= int_slv_reg2_out[31:0];
                end
                ADDR_SLV_REG3_OUT_DATA_0: begin
                    rdata <= int_slv_reg3_out[31:0];
                end
                ADDR_SLV_REG4_OUT_DATA_0: begin
                    rdata <= int_slv_reg4_out[31:0];
                end
                ADDR_SLV_REG5_OUT_DATA_0: begin
                    rdata <= int_slv_reg5_out[31:0];
                end
                ADDR_SLV_REG6_OUT_DATA_0: begin
                    rdata <= int_slv_reg6_out[31:0];
                end
                ADDR_SLV_REG7_OUT_DATA_0: begin
                    rdata <= int_slv_reg7_out[31:0];
                end
                ADDR_SLV_REG8_OUT_DATA_0: begin
                    rdata <= int_slv_reg8_out[31:0];
                end
                ADDR_SLV_REG9_OUT_DATA_0: begin
                    rdata <= int_slv_reg9_out[31:0];
                end
                ADDR_SLV_REG10_OUT_DATA_0: begin
                    rdata <= int_slv_reg10_out[31:0];
                end
                ADDR_SLV_REG11_OUT_DATA_0: begin
                    rdata <= int_slv_reg11_out[31:0];
                end
                ADDR_SLV_REG12_OUT_DATA_0: begin
                    rdata <= int_slv_reg12_out[31:0];
                end
                ADDR_SLV_REG13_OUT_DATA_0: begin
                    rdata <= int_slv_reg13_out[31:0];
                end
                ADDR_SLV_REG14_OUT_DATA_0: begin
                    rdata <= int_slv_reg14_out[31:0];
                end
                ADDR_AXI00_IMEM_PTR0_DATA_0: begin
                    rdata <= int_axi00_imem_ptr0[31:0];
                end
                ADDR_AXI00_IMEM_PTR0_DATA_1: begin
                    rdata <= int_axi00_imem_ptr0[63:32];
                end
                ADDR_AXI01_PARAMBUF_PTR0_DATA_0: begin
                    rdata <= int_axi01_parambuf_ptr0[31:0];
                end
                ADDR_AXI01_PARAMBUF_PTR0_DATA_1: begin
                    rdata <= int_axi01_parambuf_ptr0[63:32];
                end
                ADDR_AXI02_IBUF_PTR0_DATA_0: begin
                    rdata <= int_axi02_ibuf_ptr0[31:0];
                end
                ADDR_AXI02_IBUF_PTR0_DATA_1: begin
                    rdata <= int_axi02_ibuf_ptr0[63:32];
                end
                ADDR_AXI03_OBUF_PTR0_DATA_0: begin
                    rdata <= int_axi03_obuf_ptr0[31:0];
                end
                ADDR_AXI03_OBUF_PTR0_DATA_1: begin
                    rdata <= int_axi03_obuf_ptr0[63:32];
                end
                ADDR_AXI04_SIMD_PTR0_DATA_0: begin
                    rdata <= int_axi04_simd_ptr0[31:0];
                end
                ADDR_AXI04_SIMD_PTR0_DATA_1: begin
                    rdata <= int_axi04_simd_ptr0[63:32];
                end
            endcase
        end
    end
end


//------------------------Register logic-----------------
assign interrupt           = int_gie & (|int_isr);
assign ap_start            = int_ap_start;
assign slv_reg0_out        = int_slv_reg0_out;
assign slv_reg1_out        = int_slv_reg1_out;
assign slv_reg2_out        = int_slv_reg2_out;
assign slv_reg3_out        = int_slv_reg3_out;
assign slv_reg4_out        = int_slv_reg4_out;
assign slv_reg5_out        = int_slv_reg5_out;
assign slv_reg6_out        = int_slv_reg6_out;
assign slv_reg7_out        = int_slv_reg7_out;
assign slv_reg8_out        = int_slv_reg8_out;
assign slv_reg9_out        = int_slv_reg9_out;
assign slv_reg10_out       = int_slv_reg10_out;
assign slv_reg11_out       = int_slv_reg11_out;
assign slv_reg12_out       = int_slv_reg12_out;
assign slv_reg13_out       = int_slv_reg13_out;
assign slv_reg14_out       = int_slv_reg14_out;
assign axi00_imem_ptr0     = int_axi00_imem_ptr0;
assign axi01_parambuf_ptr0 = int_axi01_parambuf_ptr0;
assign axi02_ibuf_ptr0     = int_axi02_ibuf_ptr0;
assign axi03_obuf_ptr0     = int_axi03_obuf_ptr0;
assign axi04_simd_ptr0     = int_axi04_simd_ptr0;
// int_ap_start
always @(posedge ACLK) begin
    if (ARESET)
        int_ap_start <= 1'b0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_AP_CTRL && WSTRB[0] && WDATA[0])
            int_ap_start <= 1'b1;
        else if (ap_ready)
            int_ap_start <= int_auto_restart; // clear on handshake/auto restart
    end
end

// int_ap_done
always @(posedge ACLK) begin
    if (ARESET)
        int_ap_done <= 1'b0;
    else if (ACLK_EN) begin
        if (ap_done)
            int_ap_done <= 1'b1;
        else if (ar_hs && raddr == ADDR_AP_CTRL)
            int_ap_done <= 1'b0; // clear on read
    end
end

// int_ap_idle
always @(posedge ACLK) begin
    if (ARESET)
        int_ap_idle <= 1'b0;
    else if (ACLK_EN) begin
            int_ap_idle <= ap_idle;
    end
end

// int_ap_ready
always @(posedge ACLK) begin
    if (ARESET)
        int_ap_ready <= 1'b0;
    else if (ACLK_EN) begin
            int_ap_ready <= ap_ready;
    end
end

// int_auto_restart
always @(posedge ACLK) begin
    if (ARESET)
        int_auto_restart <= 1'b0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_AP_CTRL && WSTRB[0])
            int_auto_restart <=  WDATA[7];
    end
end

// int_gie
always @(posedge ACLK) begin
    if (ARESET)
        int_gie <= 1'b0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_GIE && WSTRB[0])
            int_gie <= WDATA[0];
    end
end

// int_ier
always @(posedge ACLK) begin
    if (ARESET)
        int_ier <= 1'b0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_IER && WSTRB[0])
            int_ier <= WDATA[1:0];
    end
end

// int_isr[0]
always @(posedge ACLK) begin
    if (ARESET)
        int_isr[0] <= 1'b0;
    else if (ACLK_EN) begin
        if (int_ier[0] & ap_done)
            int_isr[0] <= 1'b1;
        else if (w_hs && waddr == ADDR_ISR && WSTRB[0])
            int_isr[0] <= int_isr[0] ^ WDATA[0]; // toggle on write
    end
end

// int_isr[1]
always @(posedge ACLK) begin
    if (ARESET)
        int_isr[1] <= 1'b0;
    else if (ACLK_EN) begin
        if (int_ier[1] & ap_ready)
            int_isr[1] <= 1'b1;
        else if (w_hs && waddr == ADDR_ISR && WSTRB[0])
            int_isr[1] <= int_isr[1] ^ WDATA[1]; // toggle on write
    end
end

// int_slv_reg0_out[31:0]
always @(posedge ACLK) begin
    if (ARESET)
        int_slv_reg0_out[31:0] <= 0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_SLV_REG0_OUT_DATA_0)
            int_slv_reg0_out[31:0] <= (WDATA[31:0] & wmask) | (int_slv_reg0_out[31:0] & ~wmask);
    end
end

// int_slv_reg1_out[31:0]
always @(posedge ACLK) begin
    if (ARESET)
        int_slv_reg1_out[31:0] <= 0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_SLV_REG1_OUT_DATA_0)
            int_slv_reg1_out[31:0] <= (WDATA[31:0] & wmask) | (int_slv_reg1_out[31:0] & ~wmask);
    end
end

// int_slv_reg2_out[31:0]
always @(posedge ACLK) begin
    if (ARESET)
        int_slv_reg2_out[31:0] <= 0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_SLV_REG2_OUT_DATA_0)
            int_slv_reg2_out[31:0] <= (WDATA[31:0] & wmask) | (int_slv_reg2_out[31:0] & ~wmask);
    end
end

// int_slv_reg3_out[31:0]
always @(posedge ACLK) begin
    if (ARESET)
        int_slv_reg3_out[31:0] <= 0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_SLV_REG3_OUT_DATA_0)
            int_slv_reg3_out[31:0] <= (WDATA[31:0] & wmask) | (int_slv_reg3_out[31:0] & ~wmask);
    end
end

// int_slv_reg4_out[31:0]
always @(posedge ACLK) begin
    if (ARESET)
        int_slv_reg4_out[31:0] <= 0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_SLV_REG4_OUT_DATA_0)
            int_slv_reg4_out[31:0] <= (WDATA[31:0] & wmask) | (int_slv_reg4_out[31:0] & ~wmask);
    end
end

// int_slv_reg5_out[31:0]
always @(posedge ACLK) begin
    if (ARESET)
        int_slv_reg5_out[31:0] <= 0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_SLV_REG5_OUT_DATA_0)
            int_slv_reg5_out[31:0] <= (WDATA[31:0] & wmask) | (int_slv_reg5_out[31:0] & ~wmask);
    end
end

// int_slv_reg6_out[31:0]
always @(posedge ACLK) begin
    if (ARESET)
        int_slv_reg6_out[31:0] <= 0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_SLV_REG6_OUT_DATA_0)
            int_slv_reg6_out[31:0] <= (WDATA[31:0] & wmask) | (int_slv_reg6_out[31:0] & ~wmask);
    end
end

// int_slv_reg7_out[31:0]
always @(posedge ACLK) begin
    if (ARESET)
        int_slv_reg7_out[31:0] <= 0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_SLV_REG7_OUT_DATA_0)
            int_slv_reg7_out[31:0] <= (WDATA[31:0] & wmask) | (int_slv_reg7_out[31:0] & ~wmask);
    end
end

// int_slv_reg8_out[31:0]
always @(posedge ACLK) begin
    if (ARESET)
        int_slv_reg8_out[31:0] <= 0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_SLV_REG8_OUT_DATA_0)
            int_slv_reg8_out[31:0] <= (WDATA[31:0] & wmask) | (int_slv_reg8_out[31:0] & ~wmask);
    end
end

// int_slv_reg9_out[31:0]
always @(posedge ACLK) begin
    if (ARESET)
        int_slv_reg9_out[31:0] <= 0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_SLV_REG9_OUT_DATA_0)
            int_slv_reg9_out[31:0] <= (WDATA[31:0] & wmask) | (int_slv_reg9_out[31:0] & ~wmask);
    end
end

// int_slv_reg10_out[31:0]
always @(posedge ACLK) begin
    if (ARESET)
        int_slv_reg10_out[31:0] <= 0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_SLV_REG10_OUT_DATA_0)
            int_slv_reg10_out[31:0] <= (WDATA[31:0] & wmask) | (int_slv_reg10_out[31:0] & ~wmask);
    end
end

// int_slv_reg11_out[31:0]
always @(posedge ACLK) begin
    if (ARESET)
        int_slv_reg11_out[31:0] <= 0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_SLV_REG11_OUT_DATA_0)
            int_slv_reg11_out[31:0] <= (WDATA[31:0] & wmask) | (int_slv_reg11_out[31:0] & ~wmask);
    end
end

// int_slv_reg12_out[31:0]
always @(posedge ACLK) begin
    if (ARESET)
        int_slv_reg12_out[31:0] <= 0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_SLV_REG12_OUT_DATA_0)
            int_slv_reg12_out[31:0] <= (WDATA[31:0] & wmask) | (int_slv_reg12_out[31:0] & ~wmask);
    end
end

// int_slv_reg13_out[31:0]
always @(posedge ACLK) begin
    if (ARESET)
        int_slv_reg13_out[31:0] <= 0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_SLV_REG13_OUT_DATA_0)
            int_slv_reg13_out[31:0] <= (WDATA[31:0] & wmask) | (int_slv_reg13_out[31:0] & ~wmask);
    end
end

// int_slv_reg14_out[31:0]
always @(posedge ACLK) begin
    if (ARESET)
        int_slv_reg14_out[31:0] <= 0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_SLV_REG14_OUT_DATA_0)
            int_slv_reg14_out[31:0] <= (WDATA[31:0] & wmask) | (int_slv_reg14_out[31:0] & ~wmask);
    end
end

// int_axi00_imem_ptr0[31:0]
always @(posedge ACLK) begin
    if (ARESET)
        int_axi00_imem_ptr0[31:0] <= 0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_AXI00_IMEM_PTR0_DATA_0)
            int_axi00_imem_ptr0[31:0] <= (WDATA[31:0] & wmask) | (int_axi00_imem_ptr0[31:0] & ~wmask);
    end
end

// int_axi00_imem_ptr0[63:32]
always @(posedge ACLK) begin
    if (ARESET)
        int_axi00_imem_ptr0[63:32] <= 0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_AXI00_IMEM_PTR0_DATA_1)
            int_axi00_imem_ptr0[63:32] <= (WDATA[31:0] & wmask) | (int_axi00_imem_ptr0[63:32] & ~wmask);
    end
end

// int_axi01_parambuf_ptr0[31:0]
always @(posedge ACLK) begin
    if (ARESET)
        int_axi01_parambuf_ptr0[31:0] <= 0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_AXI01_PARAMBUF_PTR0_DATA_0)
            int_axi01_parambuf_ptr0[31:0] <= (WDATA[31:0] & wmask) | (int_axi01_parambuf_ptr0[31:0] & ~wmask);
    end
end

// int_axi01_parambuf_ptr0[63:32]
always @(posedge ACLK) begin
    if (ARESET)
        int_axi01_parambuf_ptr0[63:32] <= 0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_AXI01_PARAMBUF_PTR0_DATA_1)
            int_axi01_parambuf_ptr0[63:32] <= (WDATA[31:0] & wmask) | (int_axi01_parambuf_ptr0[63:32] & ~wmask);
    end
end

// int_axi02_ibuf_ptr0[31:0]
always @(posedge ACLK) begin
    if (ARESET)
        int_axi02_ibuf_ptr0[31:0] <= 0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_AXI02_IBUF_PTR0_DATA_0)
            int_axi02_ibuf_ptr0[31:0] <= (WDATA[31:0] & wmask) | (int_axi02_ibuf_ptr0[31:0] & ~wmask);
    end
end

// int_axi02_ibuf_ptr0[63:32]
always @(posedge ACLK) begin
    if (ARESET)
        int_axi02_ibuf_ptr0[63:32] <= 0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_AXI02_IBUF_PTR0_DATA_1)
            int_axi02_ibuf_ptr0[63:32] <= (WDATA[31:0] & wmask) | (int_axi02_ibuf_ptr0[63:32] & ~wmask);
    end
end

// int_axi03_obuf_ptr0[31:0]
always @(posedge ACLK) begin
    if (ARESET)
        int_axi03_obuf_ptr0[31:0] <= 0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_AXI03_OBUF_PTR0_DATA_0)
            int_axi03_obuf_ptr0[31:0] <= (WDATA[31:0] & wmask) | (int_axi03_obuf_ptr0[31:0] & ~wmask);
    end
end

// int_axi03_obuf_ptr0[63:32]
always @(posedge ACLK) begin
    if (ARESET)
        int_axi03_obuf_ptr0[63:32] <= 0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_AXI03_OBUF_PTR0_DATA_1)
            int_axi03_obuf_ptr0[63:32] <= (WDATA[31:0] & wmask) | (int_axi03_obuf_ptr0[63:32] & ~wmask);
    end
end

// int_axi04_simd_ptr0[31:0]
always @(posedge ACLK) begin
    if (ARESET)
        int_axi04_simd_ptr0[31:0] <= 0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_AXI04_SIMD_PTR0_DATA_0)
            int_axi04_simd_ptr0[31:0] <= (WDATA[31:0] & wmask) | (int_axi04_simd_ptr0[31:0] & ~wmask);
    end
end

// int_axi04_simd_ptr0[63:32]
always @(posedge ACLK) begin
    if (ARESET)
        int_axi04_simd_ptr0[63:32] <= 0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_AXI04_SIMD_PTR0_DATA_1)
            int_axi04_simd_ptr0[63:32] <= (WDATA[31:0] & wmask) | (int_axi04_simd_ptr0[63:32] & ~wmask);
    end
end


//------------------------Memory logic-------------------

endmodule
