// 1. Change path to the compiler generated config file
// 2. Change path to all inlcude files for instr, data etc etc.
`default_nettype none
`timescale 1 ps / 1 ps
`define DEBUG
`define DEBUG1
//`define STRIDE_BASED

import axi_vip_pkg::*;
import slv_m00_imem_axi_vip_pkg::*;
import slv_m01_parambuf_axi_vip_pkg::*;
import slv_m02_ibuf_axi_vip_pkg::*;
import slv_m03_obuf_axi_vip_pkg::*;
import control_systolic_fpga_vip_pkg::*;

module systolic_fpga_tb ();
parameter integer LP_MAX_LENGTH = 8192;
parameter integer C_S_AXI_CONTROL_ADDR_WIDTH = 12;
parameter integer C_S_AXI_CONTROL_DATA_WIDTH = 32;
parameter integer C_M00_IMEM_AXI_ADDR_WIDTH = 64;
parameter integer C_M00_IMEM_AXI_DATA_WIDTH = 512;
parameter integer C_M01_PARAMBUF_AXI_ADDR_WIDTH = 64;
parameter integer C_M01_PARAMBUF_AXI_DATA_WIDTH = 512;
parameter integer C_M02_IBUF_AXI_ADDR_WIDTH = 64;
parameter integer C_M02_IBUF_AXI_DATA_WIDTH = 512;
parameter integer C_M03_OBUF_AXI_ADDR_WIDTH = 64;
parameter integer C_M03_OBUF_AXI_DATA_WIDTH = 512;

// Control Register
parameter KRNL_CTRL_REG_ADDR     = 32'h00000000;
parameter CTRL_START_MASK        = 32'h00000001;
parameter CTRL_DONE_MASK         = 32'h00000002;
parameter CTRL_IDLE_MASK         = 32'h00000004;
parameter CTRL_READY_MASK        = 32'h00000008;
parameter CTRL_CONTINUE_MASK     = 32'h00000010; // Only ap_ctrl_chain
parameter CTRL_AUTO_RESTART_MASK = 32'h00000080; // Not used

// Global Interrupt Enable Register
parameter KRNL_GIE_REG_ADDR      = 32'h00000004;
parameter GIE_GIE_MASK           = 32'h00000001;
// IP Interrupt Enable Register
parameter KRNL_IER_REG_ADDR      = 32'h00000008;
parameter IER_DONE_MASK          = 32'h00000001;
parameter IER_READY_MASK         = 32'h00000002;
// IP Interrupt Status Register
parameter KRNL_ISR_REG_ADDR      = 32'h0000000c;
parameter ISR_DONE_MASK          = 32'h00000001;
parameter ISR_READY_MASK         = 32'h00000002;

parameter integer LP_CLK_PERIOD_PS = 4000; // 250 MHz

logic ap_clk = 0;

initial begin: AP_CLK
  forever begin
    ap_clk = #(LP_CLK_PERIOD_PS/2) ~ap_clk;
  end
end

logic ap_rst_n = 0;
logic initial_reset  =0;

task automatic ap_rst_n_sequence(input integer unsigned width = 20);
  @(posedge ap_clk);
  #1ps;
  ap_rst_n = 0;
  repeat (width) @(posedge ap_clk);
  #1ps;
  ap_rst_n = 1;
endtask

initial begin: AP_RST
  ap_rst_n_sequence(50);
  initial_reset =1;
end

// importing compiler generated files and addresses
`include "systolic_fpga_benchmark_config.vh"
//////////////////////////////////////////

//AXI4 master interface m00_imem_axi
wire [1-1:0] m00_imem_axi_awvalid;
wire [1-1:0] m00_imem_axi_awready;
wire [C_M00_IMEM_AXI_ADDR_WIDTH-1:0] m00_imem_axi_awaddr;
wire [8-1:0] m00_imem_axi_awlen;
wire [1-1:0] m00_imem_axi_wvalid;
wire [1-1:0] m00_imem_axi_wready;
wire [C_M00_IMEM_AXI_DATA_WIDTH-1:0] m00_imem_axi_wdata;
wire [C_M00_IMEM_AXI_DATA_WIDTH/8-1:0] m00_imem_axi_wstrb;
wire [1-1:0] m00_imem_axi_wlast;
wire [1-1:0] m00_imem_axi_bvalid;
wire [1-1:0] m00_imem_axi_bready;
wire [1-1:0] m00_imem_axi_arvalid;
wire [1-1:0] m00_imem_axi_arready;
wire [C_M00_IMEM_AXI_ADDR_WIDTH-1:0] m00_imem_axi_araddr;
wire [8-1:0] m00_imem_axi_arlen;
wire [1-1:0] m00_imem_axi_rvalid;
wire [1-1:0] m00_imem_axi_rready;
wire [C_M00_IMEM_AXI_DATA_WIDTH-1:0] m00_imem_axi_rdata;
wire [1-1:0] m00_imem_axi_rlast;
//AXI4 master interface m01_parambuf_axi
wire [1-1:0] m01_parambuf_axi_awvalid;
wire [1-1:0] m01_parambuf_axi_awready;
wire [C_M01_PARAMBUF_AXI_ADDR_WIDTH-1:0] m01_parambuf_axi_awaddr;
wire [8-1:0] m01_parambuf_axi_awlen;
wire [1-1:0] m01_parambuf_axi_wvalid;
wire [1-1:0] m01_parambuf_axi_wready;
wire [C_M01_PARAMBUF_AXI_DATA_WIDTH-1:0] m01_parambuf_axi_wdata;
wire [C_M01_PARAMBUF_AXI_DATA_WIDTH/8-1:0] m01_parambuf_axi_wstrb;
wire [1-1:0] m01_parambuf_axi_wlast;
wire [1-1:0] m01_parambuf_axi_bvalid;
wire [1-1:0] m01_parambuf_axi_bready;
wire [1-1:0] m01_parambuf_axi_arvalid;
wire [1-1:0] m01_parambuf_axi_arready;
wire [C_M01_PARAMBUF_AXI_ADDR_WIDTH-1:0] m01_parambuf_axi_araddr;
wire [8-1:0] m01_parambuf_axi_arlen;
wire [1-1:0] m01_parambuf_axi_rvalid;
wire [1-1:0] m01_parambuf_axi_rready;
wire [C_M01_PARAMBUF_AXI_DATA_WIDTH-1:0] m01_parambuf_axi_rdata;
wire [1-1:0] m01_parambuf_axi_rlast;
//AXI4 master interface m02_ibuf_axi
wire [1-1:0] m02_ibuf_axi_awvalid;
wire [1-1:0] m02_ibuf_axi_awready;
wire [C_M02_IBUF_AXI_ADDR_WIDTH-1:0] m02_ibuf_axi_awaddr;
wire [8-1:0] m02_ibuf_axi_awlen;
wire [1-1:0] m02_ibuf_axi_wvalid;
wire [1-1:0] m02_ibuf_axi_wready;
wire [C_M02_IBUF_AXI_DATA_WIDTH-1:0] m02_ibuf_axi_wdata;
wire [C_M02_IBUF_AXI_DATA_WIDTH/8-1:0] m02_ibuf_axi_wstrb;
wire [1-1:0] m02_ibuf_axi_wlast;
wire [1-1:0] m02_ibuf_axi_bvalid;
wire [1-1:0] m02_ibuf_axi_bready;
wire [1-1:0] m02_ibuf_axi_arvalid;
wire [1-1:0] m02_ibuf_axi_arready;
wire [C_M02_IBUF_AXI_ADDR_WIDTH-1:0] m02_ibuf_axi_araddr;
wire [8-1:0] m02_ibuf_axi_arlen;
wire [1-1:0] m02_ibuf_axi_rvalid;
wire [1-1:0] m02_ibuf_axi_rready;
wire [C_M02_IBUF_AXI_DATA_WIDTH-1:0] m02_ibuf_axi_rdata;
wire [1-1:0] m02_ibuf_axi_rlast;
//AXI4 master interface m03_obuf_axi
wire [1-1:0] m03_obuf_axi_awvalid;
wire [1-1:0] m03_obuf_axi_awready;
wire [C_M03_OBUF_AXI_ADDR_WIDTH-1:0] m03_obuf_axi_awaddr;
wire [8-1:0] m03_obuf_axi_awlen;
wire [1-1:0] m03_obuf_axi_wvalid;
wire [1-1:0] m03_obuf_axi_wready;
wire [C_M03_OBUF_AXI_DATA_WIDTH-1:0] m03_obuf_axi_wdata;
wire [C_M03_OBUF_AXI_DATA_WIDTH/8-1:0] m03_obuf_axi_wstrb;
wire [1-1:0] m03_obuf_axi_wlast;
wire [1-1:0] m03_obuf_axi_bvalid;
wire [1-1:0] m03_obuf_axi_bready;
wire [1-1:0] m03_obuf_axi_arvalid;
wire [1-1:0] m03_obuf_axi_arready;
wire [C_M03_OBUF_AXI_ADDR_WIDTH-1:0] m03_obuf_axi_araddr;
wire [8-1:0] m03_obuf_axi_arlen;
wire [1-1:0] m03_obuf_axi_rvalid;
wire [1-1:0] m03_obuf_axi_rready;
wire [C_M03_OBUF_AXI_DATA_WIDTH-1:0] m03_obuf_axi_rdata;
wire [1-1:0] m03_obuf_axi_rlast;
//AXI4LITE control signals
wire [1-1:0] s_axi_control_awvalid;
wire [1-1:0] s_axi_control_awready;
wire [C_S_AXI_CONTROL_ADDR_WIDTH-1:0] s_axi_control_awaddr;
wire [1-1:0] s_axi_control_wvalid;
wire [1-1:0] s_axi_control_wready;
wire [C_S_AXI_CONTROL_DATA_WIDTH-1:0] s_axi_control_wdata;
wire [C_S_AXI_CONTROL_DATA_WIDTH/8-1:0] s_axi_control_wstrb;
wire [1-1:0] s_axi_control_arvalid;
wire [1-1:0] s_axi_control_arready;
wire [C_S_AXI_CONTROL_ADDR_WIDTH-1:0] s_axi_control_araddr;
wire [1-1:0] s_axi_control_rvalid;
wire [1-1:0] s_axi_control_rready;
wire [C_S_AXI_CONTROL_DATA_WIDTH-1:0] s_axi_control_rdata;
wire [2-1:0] s_axi_control_rresp;
wire [1-1:0] s_axi_control_bvalid;
wire [1-1:0] s_axi_control_bready;
wire [2-1:0] s_axi_control_bresp;
wire interrupt;

systolic_fpga #(
  .C_S_AXI_CONTROL_ADDR_WIDTH    ( C_S_AXI_CONTROL_ADDR_WIDTH    ),
  .C_S_AXI_CONTROL_DATA_WIDTH    ( C_S_AXI_CONTROL_DATA_WIDTH    ),
  .C_M00_IMEM_AXI_ADDR_WIDTH     ( C_M00_IMEM_AXI_ADDR_WIDTH     ),
  .C_M00_IMEM_AXI_DATA_WIDTH     ( C_M00_IMEM_AXI_DATA_WIDTH     ),
  .C_M01_PARAMBUF_AXI_ADDR_WIDTH ( C_M01_PARAMBUF_AXI_ADDR_WIDTH ),
  .C_M01_PARAMBUF_AXI_DATA_WIDTH ( C_M01_PARAMBUF_AXI_DATA_WIDTH ),
  .C_M02_IBUF_AXI_ADDR_WIDTH     ( C_M02_IBUF_AXI_ADDR_WIDTH     ),
  .C_M02_IBUF_AXI_DATA_WIDTH     ( C_M02_IBUF_AXI_DATA_WIDTH     ),
  .C_M03_OBUF_AXI_ADDR_WIDTH     ( C_M03_OBUF_AXI_ADDR_WIDTH     ),
  .C_M03_OBUF_AXI_DATA_WIDTH     ( C_M03_OBUF_AXI_DATA_WIDTH     )
)
inst_dut (
  .ap_clk                   ( ap_clk                   ),
  .ap_rst_n                 ( ap_rst_n                 ),
  .m00_imem_axi_awvalid     ( m00_imem_axi_awvalid     ),
  .m00_imem_axi_awready     ( m00_imem_axi_awready     ),
  .m00_imem_axi_awaddr      ( m00_imem_axi_awaddr      ),
  .m00_imem_axi_awlen       ( m00_imem_axi_awlen       ),
  .m00_imem_axi_wvalid      ( m00_imem_axi_wvalid      ),
  .m00_imem_axi_wready      ( m00_imem_axi_wready      ),
  .m00_imem_axi_wdata       ( m00_imem_axi_wdata       ),
  .m00_imem_axi_wstrb       ( m00_imem_axi_wstrb       ),
  .m00_imem_axi_wlast       ( m00_imem_axi_wlast       ),
  .m00_imem_axi_bvalid      ( m00_imem_axi_bvalid      ),
  .m00_imem_axi_bready      ( m00_imem_axi_bready      ),
  .m00_imem_axi_arvalid     ( m00_imem_axi_arvalid     ),
  .m00_imem_axi_arready     ( m00_imem_axi_arready     ),
  .m00_imem_axi_araddr      ( m00_imem_axi_araddr      ),
  .m00_imem_axi_arlen       ( m00_imem_axi_arlen       ),
  .m00_imem_axi_rvalid      ( m00_imem_axi_rvalid      ),
  .m00_imem_axi_rready      ( m00_imem_axi_rready      ),
  .m00_imem_axi_rdata       ( m00_imem_axi_rdata       ),
  .m00_imem_axi_rlast       ( m00_imem_axi_rlast       ),
  .m01_parambuf_axi_awvalid ( m01_parambuf_axi_awvalid ),
  .m01_parambuf_axi_awready ( m01_parambuf_axi_awready ),
  .m01_parambuf_axi_awaddr  ( m01_parambuf_axi_awaddr  ),
  .m01_parambuf_axi_awlen   ( m01_parambuf_axi_awlen   ),
  .m01_parambuf_axi_wvalid  ( m01_parambuf_axi_wvalid  ),
  .m01_parambuf_axi_wready  ( m01_parambuf_axi_wready  ),
  .m01_parambuf_axi_wdata   ( m01_parambuf_axi_wdata   ),
  .m01_parambuf_axi_wstrb   ( m01_parambuf_axi_wstrb   ),
  .m01_parambuf_axi_wlast   ( m01_parambuf_axi_wlast   ),
  .m01_parambuf_axi_bvalid  ( m01_parambuf_axi_bvalid  ),
  .m01_parambuf_axi_bready  ( m01_parambuf_axi_bready  ),
  .m01_parambuf_axi_arvalid ( m01_parambuf_axi_arvalid ),
  .m01_parambuf_axi_arready ( m01_parambuf_axi_arready ),
  .m01_parambuf_axi_araddr  ( m01_parambuf_axi_araddr  ),
  .m01_parambuf_axi_arlen   ( m01_parambuf_axi_arlen   ),
  .m01_parambuf_axi_rvalid  ( m01_parambuf_axi_rvalid  ),
  .m01_parambuf_axi_rready  ( m01_parambuf_axi_rready  ),
  .m01_parambuf_axi_rdata   ( m01_parambuf_axi_rdata   ),
  .m01_parambuf_axi_rlast   ( m01_parambuf_axi_rlast   ),
  .m02_ibuf_axi_awvalid     ( m02_ibuf_axi_awvalid     ),
  .m02_ibuf_axi_awready     ( m02_ibuf_axi_awready     ),
  .m02_ibuf_axi_awaddr      ( m02_ibuf_axi_awaddr      ),
  .m02_ibuf_axi_awlen       ( m02_ibuf_axi_awlen       ),
  .m02_ibuf_axi_wvalid      ( m02_ibuf_axi_wvalid      ),
  .m02_ibuf_axi_wready      ( m02_ibuf_axi_wready      ),
  .m02_ibuf_axi_wdata       ( m02_ibuf_axi_wdata       ),
  .m02_ibuf_axi_wstrb       ( m02_ibuf_axi_wstrb       ),
  .m02_ibuf_axi_wlast       ( m02_ibuf_axi_wlast       ),
  .m02_ibuf_axi_bvalid      ( m02_ibuf_axi_bvalid      ),
  .m02_ibuf_axi_bready      ( m02_ibuf_axi_bready      ),
  .m02_ibuf_axi_arvalid     ( m02_ibuf_axi_arvalid     ),
  .m02_ibuf_axi_arready     ( m02_ibuf_axi_arready     ),
  .m02_ibuf_axi_araddr      ( m02_ibuf_axi_araddr      ),
  .m02_ibuf_axi_arlen       ( m02_ibuf_axi_arlen       ),
  .m02_ibuf_axi_rvalid      ( m02_ibuf_axi_rvalid      ),
  .m02_ibuf_axi_rready      ( m02_ibuf_axi_rready      ),
  .m02_ibuf_axi_rdata       ( m02_ibuf_axi_rdata       ),
  .m02_ibuf_axi_rlast       ( m02_ibuf_axi_rlast       ),
  .m03_obuf_axi_awvalid     ( m03_obuf_axi_awvalid     ),
  .m03_obuf_axi_awready     ( m03_obuf_axi_awready     ),
  .m03_obuf_axi_awaddr      ( m03_obuf_axi_awaddr      ),
  .m03_obuf_axi_awlen       ( m03_obuf_axi_awlen       ),
  .m03_obuf_axi_wvalid      ( m03_obuf_axi_wvalid      ),
  .m03_obuf_axi_wready      ( m03_obuf_axi_wready      ),
  .m03_obuf_axi_wdata       ( m03_obuf_axi_wdata       ),
  .m03_obuf_axi_wstrb       ( m03_obuf_axi_wstrb       ),
  .m03_obuf_axi_wlast       ( m03_obuf_axi_wlast       ),
  .m03_obuf_axi_bvalid      ( m03_obuf_axi_bvalid      ),
  .m03_obuf_axi_bready      ( m03_obuf_axi_bready      ),
  .m03_obuf_axi_arvalid     ( m03_obuf_axi_arvalid     ),
  .m03_obuf_axi_arready     ( m03_obuf_axi_arready     ),
  .m03_obuf_axi_araddr      ( m03_obuf_axi_araddr      ),
  .m03_obuf_axi_arlen       ( m03_obuf_axi_arlen       ),
  .m03_obuf_axi_rvalid      ( m03_obuf_axi_rvalid      ),
  .m03_obuf_axi_rready      ( m03_obuf_axi_rready      ),
  .m03_obuf_axi_rdata       ( m03_obuf_axi_rdata       ),
  .m03_obuf_axi_rlast       ( m03_obuf_axi_rlast       ),
  .s_axi_control_awvalid    ( s_axi_control_awvalid    ),
  .s_axi_control_awready    ( s_axi_control_awready    ),
  .s_axi_control_awaddr     ( s_axi_control_awaddr     ),
  .s_axi_control_wvalid     ( s_axi_control_wvalid     ),
  .s_axi_control_wready     ( s_axi_control_wready     ),
  .s_axi_control_wdata      ( s_axi_control_wdata      ),
  .s_axi_control_wstrb      ( s_axi_control_wstrb      ),
  .s_axi_control_arvalid    ( s_axi_control_arvalid    ),
  .s_axi_control_arready    ( s_axi_control_arready    ),
  .s_axi_control_araddr     ( s_axi_control_araddr     ),
  .s_axi_control_rvalid     ( s_axi_control_rvalid     ),
  .s_axi_control_rready     ( s_axi_control_rready     ),
  .s_axi_control_rdata      ( s_axi_control_rdata      ),
  .s_axi_control_rresp      ( s_axi_control_rresp      ),
  .s_axi_control_bvalid     ( s_axi_control_bvalid     ),
  .s_axi_control_bready     ( s_axi_control_bready     ),
  .s_axi_control_bresp      ( s_axi_control_bresp      ),
  .interrupt                ( interrupt                )
);


control_systolic_fpga_vip inst_control_systolic_fpga_vip (
  .aclk          ( ap_clk                ),
  .aresetn       ( ap_rst_n              ),
  .m_axi_awvalid ( s_axi_control_awvalid ),
  .m_axi_awready ( s_axi_control_awready ),
  .m_axi_awaddr  ( s_axi_control_awaddr  ),
  .m_axi_wvalid  ( s_axi_control_wvalid  ),
  .m_axi_wready  ( s_axi_control_wready  ),
  .m_axi_wdata   ( s_axi_control_wdata   ),
  .m_axi_wstrb   ( s_axi_control_wstrb   ),
  .m_axi_arvalid ( s_axi_control_arvalid ),
  .m_axi_arready ( s_axi_control_arready ),
  .m_axi_araddr  ( s_axi_control_araddr  ),
  .m_axi_rvalid  ( s_axi_control_rvalid  ),
  .m_axi_rready  ( s_axi_control_rready  ),
  .m_axi_rdata   ( s_axi_control_rdata   ),
  .m_axi_rresp   ( s_axi_control_rresp   ),
  .m_axi_bvalid  ( s_axi_control_bvalid  ),
  .m_axi_bready  ( s_axi_control_bready  ),
  .m_axi_bresp   ( s_axi_control_bresp   )
);

control_systolic_fpga_vip_mst_t  ctrl;

// Slave MM VIP instantiation
slv_m00_imem_axi_vip inst_slv_m00_imem_axi_vip (
  .aclk          ( ap_clk               ),
  .aresetn       ( ap_rst_n             ),
  .s_axi_awvalid ( m00_imem_axi_awvalid ),
  .s_axi_awready ( m00_imem_axi_awready ),
  .s_axi_awaddr  ( m00_imem_axi_awaddr  ),
  .s_axi_awlen   ( m00_imem_axi_awlen   ),
  .s_axi_wvalid  ( m00_imem_axi_wvalid  ),
  .s_axi_wready  ( m00_imem_axi_wready  ),
  .s_axi_wdata   ( m00_imem_axi_wdata   ),
  .s_axi_wstrb   ( m00_imem_axi_wstrb   ),
  .s_axi_wlast   ( m00_imem_axi_wlast   ),
  .s_axi_bvalid  ( m00_imem_axi_bvalid  ),
  .s_axi_bready  ( m00_imem_axi_bready  ),
  .s_axi_arvalid ( m00_imem_axi_arvalid ),
  .s_axi_arready ( m00_imem_axi_arready ),
  .s_axi_araddr  ( m00_imem_axi_araddr  ),
  .s_axi_arlen   ( m00_imem_axi_arlen   ),
  .s_axi_rvalid  ( m00_imem_axi_rvalid  ),
  .s_axi_rready  ( m00_imem_axi_rready  ),
  .s_axi_rdata   ( m00_imem_axi_rdata   ),
  .s_axi_rlast   ( m00_imem_axi_rlast   )
);


slv_m00_imem_axi_vip_slv_mem_t   m00_imem_axi;
slv_m00_imem_axi_vip_slv_t   m00_imem_axi_slv;

// Slave MM VIP instantiation
slv_m01_parambuf_axi_vip inst_slv_m01_parambuf_axi_vip (
  .aclk          ( ap_clk                   ),
  .aresetn       ( ap_rst_n                 ),
  .s_axi_awvalid ( m01_parambuf_axi_awvalid ),
  .s_axi_awready ( m01_parambuf_axi_awready ),
  .s_axi_awaddr  ( m01_parambuf_axi_awaddr  ),
  .s_axi_awlen   ( m01_parambuf_axi_awlen   ),
  .s_axi_wvalid  ( m01_parambuf_axi_wvalid  ),
  .s_axi_wready  ( m01_parambuf_axi_wready  ),
  .s_axi_wdata   ( m01_parambuf_axi_wdata   ),
  .s_axi_wstrb   ( m01_parambuf_axi_wstrb   ),
  .s_axi_wlast   ( m01_parambuf_axi_wlast   ),
  .s_axi_bvalid  ( m01_parambuf_axi_bvalid  ),
  .s_axi_bready  ( m01_parambuf_axi_bready  ),
  .s_axi_arvalid ( m01_parambuf_axi_arvalid ),
  .s_axi_arready ( m01_parambuf_axi_arready ),
  .s_axi_araddr  ( m01_parambuf_axi_araddr  ),
  .s_axi_arlen   ( m01_parambuf_axi_arlen   ),
  .s_axi_rvalid  ( m01_parambuf_axi_rvalid  ),
  .s_axi_rready  ( m01_parambuf_axi_rready  ),
  .s_axi_rdata   ( m01_parambuf_axi_rdata   ),
  .s_axi_rlast   ( m01_parambuf_axi_rlast   )
);


slv_m01_parambuf_axi_vip_slv_mem_t   m01_parambuf_axi;
slv_m01_parambuf_axi_vip_slv_t   m01_parambuf_axi_slv;

// Slave MM VIP instantiation
slv_m02_ibuf_axi_vip inst_slv_m02_ibuf_axi_vip (
  .aclk          ( ap_clk               ),
  .aresetn       ( ap_rst_n             ),
  .s_axi_awvalid ( m02_ibuf_axi_awvalid ),
  .s_axi_awready ( m02_ibuf_axi_awready ),
  .s_axi_awaddr  ( m02_ibuf_axi_awaddr  ),
  .s_axi_awlen   ( m02_ibuf_axi_awlen   ),
  .s_axi_wvalid  ( m02_ibuf_axi_wvalid  ),
  .s_axi_wready  ( m02_ibuf_axi_wready  ),
  .s_axi_wdata   ( m02_ibuf_axi_wdata   ),
  .s_axi_wstrb   ( m02_ibuf_axi_wstrb   ),
  .s_axi_wlast   ( m02_ibuf_axi_wlast   ),
  .s_axi_bvalid  ( m02_ibuf_axi_bvalid  ),
  .s_axi_bready  ( m02_ibuf_axi_bready  ),
  .s_axi_arvalid ( m02_ibuf_axi_arvalid ),
  .s_axi_arready ( m02_ibuf_axi_arready ),
  .s_axi_araddr  ( m02_ibuf_axi_araddr  ),
  .s_axi_arlen   ( m02_ibuf_axi_arlen   ),
  .s_axi_rvalid  ( m02_ibuf_axi_rvalid  ),
  .s_axi_rready  ( m02_ibuf_axi_rready  ),
  .s_axi_rdata   ( m02_ibuf_axi_rdata   ),
  .s_axi_rlast   ( m02_ibuf_axi_rlast   )
);


slv_m02_ibuf_axi_vip_slv_mem_t   m02_ibuf_axi;
slv_m02_ibuf_axi_vip_slv_t   m02_ibuf_axi_slv;

// Slave MM VIP instantiation
slv_m03_obuf_axi_vip inst_slv_m03_obuf_axi_vip (
  .aclk          ( ap_clk               ),
  .aresetn       ( ap_rst_n             ),
  .s_axi_awvalid ( m03_obuf_axi_awvalid ),
  .s_axi_awready ( m03_obuf_axi_awready ),
  .s_axi_awaddr  ( m03_obuf_axi_awaddr  ),
  .s_axi_awlen   ( m03_obuf_axi_awlen   ),
  .s_axi_wvalid  ( m03_obuf_axi_wvalid  ),
  .s_axi_wready  ( m03_obuf_axi_wready  ),
  .s_axi_wdata   ( m03_obuf_axi_wdata   ),
  .s_axi_wstrb   ( m03_obuf_axi_wstrb   ),
  .s_axi_wlast   ( m03_obuf_axi_wlast   ),
  .s_axi_bvalid  ( m03_obuf_axi_bvalid  ),
  .s_axi_bready  ( m03_obuf_axi_bready  ),
  .s_axi_arvalid ( m03_obuf_axi_arvalid ),
  .s_axi_arready ( m03_obuf_axi_arready ),
  .s_axi_araddr  ( m03_obuf_axi_araddr  ),
  .s_axi_arlen   ( m03_obuf_axi_arlen   ),
  .s_axi_rvalid  ( m03_obuf_axi_rvalid  ),
  .s_axi_rready  ( m03_obuf_axi_rready  ),
  .s_axi_rdata   ( m03_obuf_axi_rdata   ),
  .s_axi_rlast   ( m03_obuf_axi_rlast   )
);


slv_m03_obuf_axi_vip_slv_mem_t   m03_obuf_axi;
slv_m03_obuf_axi_vip_slv_t   m03_obuf_axi_slv;

parameter NUM_AXIS_MST = 0;
parameter NUM_AXIS_SLV = 0;

bit               error_found = 0;

///////////////////////////////////////////////////////////////////////////
// Pointer for interface : m00_imem_axi
bit [63:0] axi00_imem_ptr0_ptr = 64'h0;

///////////////////////////////////////////////////////////////////////////
// Pointer for interface : m01_parambuf_axi
bit [63:0] axi01_parambuf_ptr0_ptr = 64'h0;

///////////////////////////////////////////////////////////////////////////
// Pointer for interface : m02_ibuf_axi
bit [63:0] axi02_ibuf_ptr0_ptr = 64'h0;

///////////////////////////////////////////////////////////////////////////
// Pointer for interface : m03_obuf_axi
bit [63:0] axi03_obuf_ptr0_ptr = 64'h0;

///////////////////////////////////////////////////////////////////////////
// Pointer for interface : m04_bias_axi
bit [63:0] axi04_bias_ptr0_ptr = 64'h0;

/////////////////////////////////////////////////////////////////////////////////////////////////
// Initialize m00_imem_axi memory.
function void m00_imem_axi_fill_memory(
  input bit [63:0] ptr,
  input integer    length
);
  automatic longint unsigned slot = 0;
  reg [31:0] read_instr;
  integer file_instr;
  //file_instr = $fopen("/home/rohan/rtml_july1/genesys-systolic-FPGA/testbench/resnet18_gemm/resnet18_gemm_decimal.txt","r");
  file_instr = instr_filep;
  while (! $feof(file_instr)) begin
    $fscanf(file_instr,"%d\n",read_instr);
    m00_imem_axi.mem_model.backdoor_memory_write_4byte(ptr + (slot * 4), read_instr);
    slot++;
  end 

endfunction

/////////////////////////////////////////////////////////////////////////////////////////////////
// Initialize m01_parambuf_axi memory.
function void m01_parambuf_axi_fill_memory(
  input bit [63:0] ptr,
  input integer    length,
  input integer    weight_num_tiles, 
  input integer    weight_tile_size_32B_cnt,
  input integer    stride
);
  automatic longint unsigned slot = 0;
  reg [31:0] read_params;
  bit [63:0] base_ptr;
  integer file_params;
  integer tile_counter = 0;
  integer tile_elements_counter = 0;
  //file_params = $fopen("/home/rohan/rtml_july1/genesys-systolic-FPGA/testbench/resnet18_gemm/parameters_gemm_ddr.txt","r"); 
  file_params = params_filep;

  base_ptr = ptr;

  while (! $feof(file_params)) begin
    $fscanf(file_params,"%d\n",read_params);
    m01_parambuf_axi.mem_model.backdoor_memory_write_4byte(base_ptr + (slot * 4), read_params);
    slot++;

    `ifdef STRIDE_BASED
    tile_elements_counter++;
    if (tile_elements_counter == weight_tile_size_32B_cnt) begin
      tile_counter++;
      tile_elements_counter = 0;
      `ifdef DEBUG
       $display("%t :m01_parambuf_axi_fill_memory: base_ptr address = %d", $time, base_ptr);
      `endif 
      base_ptr = base_ptr + stride;
      slot = 0;
    end
    `endif

  end 
 
endfunction

/////////////////////////////////////////////////////////////////////////////////////////////////
// Initialize m01_parambuf_axi memory.
function void m01_bias_axi_fill_memory(
  input bit [63:0] ptr,
  input integer    length,
  input integer    bias_num_tiles, 
  input integer    bias_tile_size_32B_cnt,
  input integer    stride
);
  automatic longint unsigned slot = 0;
  reg [31:0] read_params;
  bit [63:0] base_ptr;
  integer file_params;
  integer tile_counter = 0;
  integer tile_elements_counter = 0, countr = 0;
  automatic longint unsigned initialize_value = 0;
  //file_params = $fopen("/home/rohan/rtml_july1/genesys-systolic-FPGA/testbench/resnet18_gemm/bias.txt","r"); 
  file_params = bias_filep;
  
  base_ptr = ptr;
  while (! $feof(file_params)) begin
    $fscanf(file_params,"%d\n",read_params);
    //m01_parambuf_axi.mem_model.backdoor_memory_write_4byte(ptr + (slot * 4), read_params);
    m01_parambuf_axi.mem_model.backdoor_memory_write_4byte(base_ptr + (slot * 4), initialize_value);
    slot++;
    
    `ifdef STRIDE_BASED
    tile_elements_counter++;
    if (tile_elements_counter == bias_tile_size_32B_cnt) begin
      tile_counter++;
      `ifdef DEBUG
       $display("%t : base_ptr address = %d", $time, base_ptr);
      `endif 
      tile_elements_counter = 0;
      base_ptr = base_ptr + stride;
      slot = 0;
    end
    `endif

  end 
  
endfunction


/////////////////////////////////////////////////////////////////////////////////////////////////
// Initialize m02_ibuf_axi memory.
function void m02_ibuf_axi_fill_memory(
  input bit [63:0] ptr,
  input integer    length,
  input integer    input_num_tiles, 
  input integer    input_tile_size_32B_cnt,
  input integer    stride
);

  integer file_idata;
  reg [31:0] read_idata;
  bit [63:0] base_ptr;
  integer file_params;
  integer tile_counter = 0;
  integer tile_elements_counter = 0;
  automatic longint unsigned slot = 0;
  //file_idata = $fopen("/home/rohan/rtml_july1/genesys-systolic-FPGA/testbench/resnet18_gemm/input_gemm_ddr.txt","r");
  file_idata = input_filep;
  
  base_ptr = ptr;
  while (! $feof(file_idata)) begin
    $fscanf(file_idata,"%d\n",read_idata);
    m02_ibuf_axi.mem_model.backdoor_memory_write_4byte(base_ptr + (slot * 4), read_idata);
    slot++;

    `ifdef STRIDE_BASED
    tile_elements_counter++;
    if (tile_elements_counter == input_tile_size_32B_cnt) begin
      tile_counter++;
      tile_elements_counter = 0;
      base_ptr = base_ptr + stride;
      slot = 0;
    end
    `endif

  end 

endfunction

/////////////////////////////////////////////////////////////////////////////////////////////////
// Initialize m03_obuf_axi memory.
function void m03_obuf_axi_fill_memory(
  input bit [63:0] ptr,
  input integer    length,
  input integer    output_num_tiles, 
  input integer    output_tile_size_32B_cnt,
  input integer    stride
);
  
  integer file_odata;
  reg [31:0] read_odata;
  bit [63:0] base_ptr;
  integer file_params;
  integer tile_counter = 0;
  integer tile_elements_counter = 0;
  automatic longint unsigned slot = 0;
  automatic longint unsigned initialize_value = 0;
  //file_odata =  $fopen("/home/rohan/rtml_july1/genesys-systolic-FPGA/testbench/resnet18_gemm/gemm_output.txt","r"); // just to find how many locations to initialize
  file_odata = output_filep;
  
  base_ptr = ptr;
  while (! $feof(file_odata)) begin
    $fscanf(file_odata,"%d\n",read_odata);  // without this it goes into an infinite loop. Read and discard the value
    m03_obuf_axi.mem_model.backdoor_memory_write_4byte(base_ptr + (slot * 4), initialize_value);
    slot++;

    `ifdef STRIDE_BASED
    tile_elements_counter++;
    if (tile_elements_counter == output_tile_size_32B_cnt) begin
      tile_counter++;
      tile_elements_counter = 0;
      base_ptr = base_ptr + stride;
      slot = 0;
    end
    `endif

  end 

endfunction

task automatic system_reset_sequence(input integer unsigned width = 20);
  $display("%t : Starting System Reset Sequence", $time);
  fork
    ap_rst_n_sequence(25);
    
  join

endtask


/////////////////////////////////////////////////////////////////////////////////////////////////
// random 32bit number generator
function bit [31:0] get_random_4bytes();
  bit [31:0] rptr;
  ptr_random_failed: assert(std::randomize(rptr));
  return(rptr);
endfunction

/////////////////////////////////////////////////////////////////////////////////////////////////
// Generate a random 64bit 4k aligned address pointer.
function bit [63:0] get_random_ptr();
  bit [63:0] rptr;
  ptr_random_failed: assert(std::randomize(rptr));
  rptr[31:0] &= ~(32'h00000fff);
  return(rptr);
endfunction

/////////////////////////////////////////////////////////////////////////////////////////////////
// Control interface non-blocking write
// The task will return when the transaction has been accepted by the driver. It will be some
// amount of time before it will appear on the interface.
task automatic write_register (input bit [31:0] addr_in, input bit [31:0] data);
  axi_transaction   wr_xfer;
  wr_xfer = ctrl.wr_driver.create_transaction("wr_xfer");
  assert(wr_xfer.randomize() with {addr == addr_in;});
  wr_xfer.set_data_beat(0, data);
  ctrl.wr_driver.send(wr_xfer);
endtask

/////////////////////////////////////////////////////////////////////////////////////////////////
// Control interface blocking write
// The task will return when the BRESP has been returned from the kernel.
task automatic blocking_write_register (input bit [31:0] addr_in, input bit [31:0] data);
  axi_transaction   wr_xfer;
  axi_transaction   wr_rsp;
  wr_xfer = ctrl.wr_driver.create_transaction("wr_xfer");
  wr_xfer.set_driver_return_item_policy(XIL_AXI_PAYLOAD_RETURN);
  assert(wr_xfer.randomize() with {addr == addr_in;});
  wr_xfer.set_data_beat(0, data);
  ctrl.wr_driver.send(wr_xfer);
  ctrl.wr_driver.wait_rsp(wr_rsp);
endtask

/////////////////////////////////////////////////////////////////////////////////////////////////
// Control interface blocking read
// The task will return when the BRESP has been returned from the kernel.
task automatic read_register (input bit [31:0] addr, output bit [31:0] rddata);
  axi_transaction   rd_xfer;
  axi_transaction   rd_rsp;
  bit [31:0] rd_value;
  rd_xfer = ctrl.rd_driver.create_transaction("rd_xfer");
  rd_xfer.set_addr(addr);
  rd_xfer.set_driver_return_item_policy(XIL_AXI_PAYLOAD_RETURN);
  ctrl.rd_driver.send(rd_xfer);
  ctrl.rd_driver.wait_rsp(rd_rsp);
  rd_value = rd_rsp.get_data_beat(0);
  rddata = rd_value;
endtask



/////////////////////////////////////////////////////////////////////////////////////////////////
task automatic poll_done_register ();
  bit [31:0] rd_value;
  do begin
    read_register(KRNL_CTRL_REG_ADDR, rd_value);
  end while ((rd_value & CTRL_DONE_MASK) == 0);
endtask

task automatic poll_idle_register ();
  bit [31:0] rd_value;
  do begin
    read_register(KRNL_CTRL_REG_ADDR, rd_value);
  end while ((rd_value & CTRL_IDLE_MASK) == 0);
endtask

/////////////////////////////////////////////////////////////////////////////////////////////////
task automatic enable_interrupts();
  $display("Starting: Enabling Interrupts....");
  write_register(KRNL_GIE_REG_ADDR, GIE_GIE_MASK);
  write_register(KRNL_IER_REG_ADDR, IER_DONE_MASK);
  $display("Finished: Interrupts enabled.");
endtask

task automatic disable_interrupts();
  $display("Starting: Disable Interrupts....");
  write_register(KRNL_GIE_REG_ADDR, 32'h0);
  write_register(KRNL_IER_REG_ADDR, 32'h0);
  $display("Finished: Interrupts disabled.");
endtask

/////////////////////////////////////////////////////////////////////////////////////////////////
//When the interrupt is asserted, read the correct registers and clear the asserted interrupt.
task automatic service_interrupts();
  bit [31:0] rd_value;
  $display("Starting Servicing interrupts....");
  read_register(KRNL_CTRL_REG_ADDR, rd_value);
  $display("Control Register: 0x%0x", rd_value);

  blocking_write_register(KRNL_CTRL_REG_ADDR, rd_value);

  if ((rd_value & CTRL_DONE_MASK) == 0) begin
    $error("%t : DONE bit not asserted. Register value: (0x%0x)", $time, rd_value);
  end
  read_register(KRNL_ISR_REG_ADDR, rd_value);
  $display("Interrupt Status Register: 0x%0x", rd_value);
  blocking_write_register(KRNL_ISR_REG_ADDR, rd_value);
  $display("Finished Servicing interrupts");
endtask


/////////////////////////////////////////////////////////////////////////////////////////////////
// Start the control VIP, SLAVE memory models and AXI4-Stream.
task automatic start_vips();
  $display("///////////////////////////////////////////////////////////////////////////");
  $display("Control Master: ctrl");
  ctrl = new("ctrl", systolic_fpga_tb.inst_control_systolic_fpga_vip.inst.IF);
  ctrl.start_master();

  $display("///////////////////////////////////////////////////////////////////////////");
  $display("Starting Memory slave: m00_imem_axi");
  m00_imem_axi = new("m00_imem_axi", systolic_fpga_tb.inst_slv_m00_imem_axi_vip.inst.IF);
  m00_imem_axi.start_slave();

  $display("///////////////////////////////////////////////////////////////////////////");
  $display("Starting Memory slave: m01_parambuf_axi");
  m01_parambuf_axi = new("m01_parambuf_axi", systolic_fpga_tb.inst_slv_m01_parambuf_axi_vip.inst.IF);
  m01_parambuf_axi.start_slave();

  $display("///////////////////////////////////////////////////////////////////////////");
  $display("Starting Memory slave: m02_ibuf_axi");
  m02_ibuf_axi = new("m02_ibuf_axi", systolic_fpga_tb.inst_slv_m02_ibuf_axi_vip.inst.IF);
  m02_ibuf_axi.start_slave();

  $display("///////////////////////////////////////////////////////////////////////////");
  $display("Starting Memory slave: m03_obuf_axi");
  m03_obuf_axi = new("m03_obuf_axi", systolic_fpga_tb.inst_slv_m03_obuf_axi_vip.inst.IF);
  m03_obuf_axi.start_slave();

endtask

/////////////////////////////////////////////////////////////////////////////////////////////////
task automatic slv_no_backpressure_wready();
  axi_ready_gen     rgen;
  $display("%t - Applying slv_no_backpressure_wready", $time);

  rgen = new("m00_imem_axi_no_backpressure_wready");
  rgen.set_ready_policy(XIL_AXI_READY_GEN_NO_BACKPRESSURE);
  m00_imem_axi.wr_driver.set_wready_gen(rgen);

  rgen = new("m01_parambuf_axi_no_backpressure_wready");
  rgen.set_ready_policy(XIL_AXI_READY_GEN_NO_BACKPRESSURE);
  m01_parambuf_axi.wr_driver.set_wready_gen(rgen);

  rgen = new("m02_ibuf_axi_no_backpressure_wready");
  rgen.set_ready_policy(XIL_AXI_READY_GEN_NO_BACKPRESSURE);
  m02_ibuf_axi.wr_driver.set_wready_gen(rgen);

  rgen = new("m03_obuf_axi_no_backpressure_wready");
  rgen.set_ready_policy(XIL_AXI_READY_GEN_NO_BACKPRESSURE);
  m03_obuf_axi.wr_driver.set_wready_gen(rgen);

endtask



/////////////////////////////////////////////////////////////////////////////////////////////////
// Force the memory model to not insert any inter-beat gaps on the READ channel.
task automatic slv_no_delay_rvalid();
  $display("%t - Applying slv_no_delay_rvalid", $time);

  m00_imem_axi.mem_model.set_inter_beat_gap_delay_policy(XIL_AXI_MEMORY_DELAY_FIXED);
  m00_imem_axi.mem_model.set_inter_beat_gap(0);

  m01_parambuf_axi.mem_model.set_inter_beat_gap_delay_policy(XIL_AXI_MEMORY_DELAY_FIXED);
  m01_parambuf_axi.mem_model.set_inter_beat_gap(0);

  m02_ibuf_axi.mem_model.set_inter_beat_gap_delay_policy(XIL_AXI_MEMORY_DELAY_FIXED);
  m02_ibuf_axi.mem_model.set_inter_beat_gap(0);

  m03_obuf_axi.mem_model.set_inter_beat_gap_delay_policy(XIL_AXI_MEMORY_DELAY_FIXED);
  m03_obuf_axi.mem_model.set_inter_beat_gap(0);

endtask



/////////////////////////////////////////////////////////////////////////////////////////////////
// Check to ensure, following reset the value of the register is 0.
// Check that only the width of the register bits can be written.
task automatic check_register_value(input bit [31:0] addr_in, input integer unsigned register_width, output bit error_found);
  bit [31:0] rddata;
  bit [31:0] mask_data;
  error_found = 0;
  if (register_width < 32) begin
    mask_data = (1 << register_width) - 1;
  end else begin
    mask_data = 32'hffffffff;
  end
  read_register(addr_in, rddata);
  if (rddata != 32'h0) begin
    $error("Initial value mismatch: A:0x%0x : Expected 0x%x -> Got 0x%x", addr_in, 0, rddata);
    error_found = 1;
  end
  blocking_write_register(addr_in, 32'hffffffff);
  read_register(addr_in, rddata);
  if (rddata != mask_data) begin
    $error("Initial value mismatch: A:0x%0x : Expected 0x%x -> Got 0x%x", addr_in, mask_data, rddata);
    error_found = 1;
  end
endtask


/////////////////////////////////////////////////////////////////////////////////////////////////
// For each of the scalar registers, check:
// * reset value
// * correct number bits set on a write
task automatic check_scalar_registers(output bit error_found);
  bit tmp_error_found = 0;
  error_found = 0;
  $display("%t : Checking post reset values of scalar registers", $time);

  ///////////////////////////////////////////////////////////////////////////
  //Check ID 0: slv_reg0_out (0x010)
  check_register_value(32'h010, 32, tmp_error_found);
  error_found |= tmp_error_found;

  `ifdef DEBUG
    $display("%t : Checking post reset values of x10", $time);
  `endif 
  ///////////////////////////////////////////////////////////////////////////
  //Check ID 1: slv_reg1_out (0x018)
  check_register_value(32'h018, 32, tmp_error_found);
  error_found |= tmp_error_found;

  `ifdef DEBUG
    $display("%t : Checking post reset values of x18", $time);
  `endif 
  ///////////////////////////////////////////////////////////////////////////
  //Check ID 2: slv_reg2_out (0x020)
  check_register_value(32'h020, 32, tmp_error_found);
  error_found |= tmp_error_found;

  `ifdef DEBUG
    $display("%t : Checking post reset values of x20", $time);
  `endif 
  ///////////////////////////////////////////////////////////////////////////
  //Check ID 3: slv_reg3_out (0x028)
  check_register_value(32'h028, 32, tmp_error_found);
  error_found |= tmp_error_found;

  `ifdef DEBUG
    $display("%t : Checking post reset values of x28", $time);
  `endif 
  ///////////////////////////////////////////////////////////////////////////
  //Check ID 4: slv_reg4_out (0x030)
  check_register_value(32'h030, 32, tmp_error_found);
  error_found |= tmp_error_found;

  `ifdef DEBUG
    $display("%t : Checking post reset values of x30", $time);
  `endif 
  ///////////////////////////////////////////////////////////////////////////
  //Check ID 5: slv_reg5_out (0x038)
  check_register_value(32'h038, 32, tmp_error_found);
  error_found |= tmp_error_found;

  `ifdef DEBUG
    $display("%t : Checking post reset values of x38", $time);
  `endif 
  ///////////////////////////////////////////////////////////////////////////
  //Check ID 6: slv_reg6_out (0x040)
  check_register_value(32'h040, 32, tmp_error_found);
  error_found |= tmp_error_found;

  `ifdef DEBUG
    $display("%t : Checking post reset values of x40", $time);
  `endif 
  ///////////////////////////////////////////////////////////////////////////
  //Check ID 7: slv_reg7_out (0x048)
  check_register_value(32'h048, 32, tmp_error_found);
  error_found |= tmp_error_found;

  `ifdef DEBUG
    $display("%t : Checking post reset values of x48", $time);
  `endif 
  ///////////////////////////////////////////////////////////////////////////
  //Check ID 8: slv_reg8_out (0x050)
  check_register_value(32'h050, 32, tmp_error_found);
  error_found |= tmp_error_found;

  `ifdef DEBUG
    $display("%t : Checking post reset values of x50", $time);
  `endif 
  ///////////////////////////////////////////////////////////////////////////
  //Check ID 9: slv_reg9_out (0x058)
  check_register_value(32'h058, 32, tmp_error_found);
  error_found |= tmp_error_found;

  `ifdef DEBUG
    $display("%t : Checking post reset values of x58", $time);
  `endif 
  ///////////////////////////////////////////////////////////////////////////
  //Check ID 10: slv_reg10_out (0x060)
  check_register_value(32'h060, 32, tmp_error_found);
  error_found |= tmp_error_found;

  `ifdef DEBUG
    $display("%t : Checking post reset values of x60", $time);
  `endif 
  ///////////////////////////////////////////////////////////////////////////
  //Check ID 11: slv_reg11_out (0x068)
  check_register_value(32'h068, 32, tmp_error_found);
  error_found |= tmp_error_found;

  `ifdef DEBUG
    $display("%t : Checking post reset values of x68", $time);
  `endif 
  ///////////////////////////////////////////////////////////////////////////
  //Check ID 12: slv_reg12_out (0x070)
  check_register_value(32'h070, 32, tmp_error_found);
  error_found |= tmp_error_found;

  `ifdef DEBUG
    $display("%t : Checking post reset values of x70", $time);
  `endif 
  ///////////////////////////////////////////////////////////////////////////
  //Check ID 13: slv_reg13_out (0x078)
  check_register_value(32'h078, 32, tmp_error_found);
  error_found |= tmp_error_found;

  `ifdef DEBUG
    $display("%t : Checking post reset values of x78", $time);
  `endif 
  ///////////////////////////////////////////////////////////////////////////
  //Check ID 14: slv_reg14_out (0x080)
  check_register_value(32'h080, 32, tmp_error_found);
  error_found |= tmp_error_found;
 
 `ifdef DEBUG
    $display("%t : Checking post reset values of scalar registers Done", $time);
  `endif 
endtask

task automatic set_scalar_registers(input bit [31:0] slv_reg0_out,
                                    input bit [31:0] slv_reg1_out,
                                    input bit [31:0] slv_reg2_out,
                                    input bit [31:0] slv_reg3_out,
                                    input bit [31:0] slv_reg4_out,
                                    input bit [31:0] slv_reg5_out,
                                    input bit [31:0] slv_reg6_out,
                                    input bit [31:0] slv_reg7_out,
                                    input bit [31:0] slv_reg8_out,
                                    input bit [31:0] slv_reg9_out,
                                    input bit [31:0] slv_reg10_out,
                                    input bit [31:0] slv_reg11_out,
                                    input bit [31:0] slv_reg12_out,
                                    input bit [31:0] slv_reg13_out,
                                    input bit [31:0] slv_reg14_out

);
  $display("%t : Setting Scalar Registers registers", $time);

  write_register(32'h010, slv_reg0_out);
  write_register(32'h018, slv_reg1_out);
  write_register(32'h020, slv_reg2_out);
  write_register(32'h028, slv_reg3_out);
  write_register(32'h030, slv_reg4_out);
  write_register(32'h038, slv_reg5_out);
  write_register(32'h040, slv_reg6_out);
  write_register(32'h048, slv_reg7_out);
  write_register(32'h050, slv_reg8_out);
  write_register(32'h058, slv_reg9_out);
  write_register(32'h060, slv_reg10_out);
  write_register(32'h068, slv_reg11_out);
  write_register(32'h070, slv_reg12_out);
  write_register(32'h078, slv_reg13_out);
  write_register(32'h080, slv_reg14_out);

endtask

task automatic check_pointer_registers(output bit error_found);
  bit tmp_error_found = 0;
  ///////////////////////////////////////////////////////////////////////////
  //Check the reset states of the pointer registers.
  $display("%t : Checking post reset values of pointer registers", $time);

  ///////////////////////////////////////////////////////////////////////////
  //Write ID 15: axi00_imem_ptr0 (0x088)
  check_register_value(32'h088, 32, tmp_error_found);
  error_found |= tmp_error_found;

  ///////////////////////////////////////////////////////////////////////////
  //Write ID 15: axi00_imem_ptr0 (0x08c)
  check_register_value(32'h08c, 32, tmp_error_found);
  error_found |= tmp_error_found;

  ///////////////////////////////////////////////////////////////////////////
  //Write ID 16: axi01_parambuf_ptr0 (0x094)
  check_register_value(32'h094, 32, tmp_error_found);
  error_found |= tmp_error_found;

  ///////////////////////////////////////////////////////////////////////////
  //Write ID 16: axi01_parambuf_ptr0 (0x098)
  check_register_value(32'h098, 32, tmp_error_found);
  error_found |= tmp_error_found;

  ///////////////////////////////////////////////////////////////////////////
  //Write ID 17: axi02_ibuf_ptr0 (0x0a0)
  check_register_value(32'h0a0, 32, tmp_error_found);
  error_found |= tmp_error_found;

  ///////////////////////////////////////////////////////////////////////////
  //Write ID 17: axi02_ibuf_ptr0 (0x0a4)
  check_register_value(32'h0a4, 32, tmp_error_found);
  error_found |= tmp_error_found;

  ///////////////////////////////////////////////////////////////////////////
  //Write ID 18: axi03_obuf_ptr0 (0x0ac)
  check_register_value(32'h0ac, 32, tmp_error_found);
  error_found |= tmp_error_found;

  ///////////////////////////////////////////////////////////////////////////
  //Write ID 18: axi03_obuf_ptr0 (0x0b0)
  check_register_value(32'h0b0, 32, tmp_error_found);
  error_found |= tmp_error_found;

endtask

// ignore as this is not used in the hardware
task automatic set_memory_pointers( input bit [63:0] m00_axi_ptr, 
                                    input bit [63:0] m01_axi_ptr, 
                                    input bit [63:0] m02_axi_ptr,
                                    input bit [63:0] m03_axi_ptr,
                                    input bit [63:0] m04_axi_ptr );
  ///////////////////////////////////////////////////////////////////////////
  //Randomly generate memory pointers.
  axi00_imem_ptr0_ptr     = m00_axi_ptr;
  axi01_parambuf_ptr0_ptr = m01_axi_ptr;
  axi02_ibuf_ptr0_ptr     = m02_axi_ptr;
  axi03_obuf_ptr0_ptr     = m03_axi_ptr;
  axi04_bias_ptr0_ptr     = m04_axi_ptr;

  write_register(32'h088, axi00_imem_ptr0_ptr[31:0]);
  write_register(32'h08c, axi00_imem_ptr0_ptr[63:32]);
  write_register(32'h094, axi00_imem_ptr0_ptr[31:0]);
  write_register(32'h098, axi00_imem_ptr0_ptr[63:32]);
  write_register(32'h0a0, axi00_imem_ptr0_ptr[31:0]);
  write_register(32'h0a4, axi00_imem_ptr0_ptr[63:32]);
  write_register(32'h0ac, axi03_obuf_ptr0_ptr[31:0]);
  write_register(32'h0b0, axi03_obuf_ptr0_ptr[63:32]);

endtask

// Initialize the memory with the content.
task automatic backdoor_fill_memories(integer input_num_tiles, 
                                      integer bias_num_tiles, 
                                      integer weight_num_tiles, 
                                      integer output_num_tiles, 
                                      integer input_tile_size_32B_cnt, 
                                      integer bias_tile_size_32B_cnt, 
                                      integer weight_tile_size_32B_cnt, 
                                      integer output_tile_size_32B_cnt,
                                      integer stride);

  m00_imem_axi_fill_memory(axi00_imem_ptr0_ptr, LP_MAX_LENGTH);

  m01_parambuf_axi_fill_memory(axi01_parambuf_ptr0_ptr, LP_MAX_LENGTH, weight_num_tiles, weight_tile_size_32B_cnt, stride);
  `ifdef DEBUG
    $display("%t : parambuf backdoor write complete", $time);
  `endif 
  m01_bias_axi_fill_memory(axi04_bias_ptr0_ptr, LP_MAX_LENGTH, bias_num_tiles, bias_tile_size_32B_cnt, stride);
  `ifdef DEBUG
    $display("%t : bias backdoor write complete", $time);
  `endif 
  m02_ibuf_axi_fill_memory(axi02_ibuf_ptr0_ptr, LP_MAX_LENGTH, input_num_tiles, input_tile_size_32B_cnt, stride);
  `ifdef DEBUG
    $display("%t : ibuf write complete", $time);
  `endif 
  m03_obuf_axi_fill_memory(axi03_obuf_ptr0_ptr, LP_MAX_LENGTH, output_num_tiles, output_tile_size_32B_cnt, stride);
  `ifdef DEBUG
    $display("%t : obuf write complete", $time);
  `endif 

endtask

function automatic bit check_memory_data(integer input_num_tiles, 
                                      integer bias_num_tiles, 
                                      integer weight_num_tiles, 
                                      integer output_num_tiles, 
                                      integer input_tile_size_32B_cnt, 
                                      integer bias_tile_size_32B_cnt, 
                                      integer weight_tile_size_32B_cnt, 
                                      integer output_tile_size_32B_cnt,
                                      integer stride);
  reg [31:0] read_instr;
  reg [31:0] read_parameters;
  reg [31:0] read_idata;
  reg [31:0] read_odata;
  bit [31:0]        ret_rd_value = 32'h0;
  bit [31:0]        odata_initialVal = 32'h0;
  bit error_found = 0;
  
  // DECLARING POINTERS TO STORE THE MEMORY ADDRESSES AND UPDATED THEM BASED ON STRIDE
  bit [63:0] parambuf_ptr     = axi01_parambuf_ptr0_ptr;
  bit [63:0] ibuf_ptr         = axi02_ibuf_ptr0_ptr;
  bit [63:0] obuf_ptr         = axi03_obuf_ptr0_ptr;
  bit [63:0] bias_ptr         = axi04_bias_ptr0_ptr;

  integer tile_counter = 0;
  integer tile_elements_counter = 0;

  integer error_counter, file_instr, file_idata, file_params, file_odata;
  longint unsigned slot = 0;
  error_counter = 0;

  /////////////////////////////////////////////////////////////////////////////////////////////////
  // Checking memory connected to m00_imem_axi
   
  file_instr = instr_filep1;


  `ifdef DEBUG1
         $display("\n%t : check_memory_data: axi01_parambuf_ptr0_ptr = %d , stride = %d", $time,  axi01_parambuf_ptr0_ptr, stride);
         $display("\n%t : check_memory_data: axi02_ibuf_ptr0_ptr = %d ", $time,  axi02_ibuf_ptr0_ptr);
         $display("\n%t : check_memory_data: axi03_obuf_ptr0_ptr = %d ", $time,  axi03_obuf_ptr0_ptr);
         $display("\n%t : check_memory_data: axi04_bias_ptr0_ptr = %d ", $time,  axi04_bias_ptr0_ptr);
  `endif 

  while (! $feof(file_instr)) begin
    $fscanf(file_instr,"%d\n",read_instr);
    ret_rd_value = m00_imem_axi.mem_model.backdoor_memory_read_4byte(axi00_imem_ptr0_ptr + (slot * 4));
    
    `ifdef DEBUG1
           $display("%t : Instruction Memory Addr: @0x%x - Written Value = %d ; Read Value = %d ", $time,  axi00_imem_ptr0_ptr + (slot * 4), read_instr, ret_rd_value);
    `endif 
      
    if (ret_rd_value != read_instr) begin
        $error("Memory Mismatch: m00_axi : @0x%x : Expected 0x%x -> Got 0x%x ", axi00_imem_ptr0_ptr + (slot * 4), read_instr, ret_rd_value);
        error_found |= 1;
        error_counter++;
    end
    slot++;
    if (error_counter > 5) begin
      $display("Too many errors found. Exiting check of m00_axi.");
      break;
    end
  end 
  error_counter = 0;
  slot = 0;

  /////////////////////////////////////////////////////////////////////////////////////////////////

  // Checking memory connected to m01_parambuf_axi

  //file_params = $fopen("/home/rohan/rtml_july1/genesys-systolic-FPGA/testbench/resnet18_gemm/parameters_gemm_ddr.txt","r");
  file_params = params_filep1;
  while (! $feof(file_params)) begin
    $fscanf(file_params,"%d\n",read_parameters);
    ret_rd_value = m01_parambuf_axi.mem_model.backdoor_memory_read_4byte(parambuf_ptr + (slot * 4));
      
    if (ret_rd_value != read_parameters) begin
        $error("Memory Mismatch: m01_parambuf_axi : @0x%x : Expected 0x%x -> Got 0x%x ", parambuf_ptr + (slot * 4), read_parameters, ret_rd_value);
        error_found |= 1;
        error_counter++;
    end
    slot++;
    `ifdef STRIDE_BASED
    tile_elements_counter++;
    if (tile_elements_counter == weight_tile_size_32B_cnt) begin
      tile_counter++;
      tile_elements_counter = 0;
      parambuf_ptr = parambuf_ptr + stride;
      slot = 0;
    end
    `endif

    if (error_counter > 5) begin
      $display("Too many errors found. Exiting check of m01_axi.");
      break;
    end
  end 
  error_counter = 0;
  slot = 0;
  tile_counter = 0;
  tile_elements_counter = 0;
  /////////////////////////////////////////////////////////////////////////////////////////////////
  // Checking memory connected to m02_ibuf_axi
  
  //file_idata = $fopen("/home/rohan/rtml_july1/genesys-systolic-FPGA/testbench/resnet18_gemm/input_gemm_ddr.txt","r");
  file_idata = input_filep1;
  while (! $feof(file_idata)) begin
    $fscanf(file_idata,"%d\n",read_idata);
    ret_rd_value = m02_ibuf_axi.mem_model.backdoor_memory_read_4byte(ibuf_ptr + (slot * 4));
    if (ret_rd_value != read_idata) begin
        $error("Memory Mismatch: m02_ibuf_axi : @0x%x : Expected 0x%x -> Got 0x%x ", ibuf_ptr + (slot * 4), read_idata, ret_rd_value);
        error_found |= 1;
        error_counter++;
    end
    slot++;
    `ifdef STRIDE_BASED
    tile_elements_counter++;
    if (tile_elements_counter == input_tile_size_32B_cnt) begin
      tile_counter++;
      tile_elements_counter = 0;
      ibuf_ptr = ibuf_ptr + stride;
      slot = 0;
    end
    `endif
    
    if (error_counter > 5) begin
      $display("Too many errors found. Exiting check of m02_axi.");
      break;
    end
  end 
  error_counter = 0;
  slot = 0;
  tile_counter = 0;
  tile_elements_counter = 0;

  /////////////////////////////////////////////////////////////////////////////////////////////////
  // Checking memory connected to m03_obuf_axi 
  
  //file_odata = $fopen("/home/rohan/rtml_july1/genesys-systolic-FPGA/testbench/resnet18_gemm/gemm_output.txt","r");
  file_odata = output_filep1;

  while (! $feof(file_odata)) begin   // because we want to read the same amount of values
    $fscanf(file_odata,"%d\n",read_odata);
    ret_rd_value = m03_obuf_axi.mem_model.backdoor_memory_read_4byte(obuf_ptr + (slot * 4));
    if (ret_rd_value != odata_initialVal) begin
        $error("Memory Mismatch: m03_obuf_axi : @0x%x : Expected 0x%x -> Got 0x%x ", obuf_ptr + (slot * 4), odata_initialVal, ret_rd_value);
        error_found |= 1;
        error_counter++;
    end
    slot++;

    `ifdef STRIDE_BASED
    tile_elements_counter++;
    if (tile_elements_counter == output_tile_size_32B_cnt) begin
      tile_counter++;
      tile_elements_counter = 0;
      obuf_ptr = obuf_ptr + stride;
      slot = 0;
    end
    `endif

    if (error_counter > 5) begin
      $display("Too many errors found. Exiting check of m03_axi.");
      break;
    end
  end 
  error_counter = 0;
  slot = 0;
  tile_counter = 0;
  tile_elements_counter = 0;

  return(error_found);
endfunction




function automatic bit check_output_data( integer output_num_tiles, 
                                          integer output_tile_size_32B_cnt,
                                          integer stride);
  reg [31:0] read_odata;
  reg [7:0] val1,val2,val3,val4,read_val1,read_val2,read_val3,read_val4;
  bit [31:0]        ret_rd_value = 32'h0;
  bit error_found = 0;
  bit [63:0] obuf_ptr1         = axi03_obuf_ptr0_ptr;
  integer error_counter;
  integer tile_counter = 0;
  integer tile_elements_counter = 0;
  reg signed [31:0] file_odata;
  longint unsigned slot = 0, cnt = 0;
  error_counter = 0;
  
  //file_odata = $fopen("/home/rohan/rtml_july1/genesys-systolic-FPGA/testbench/resnet18_gemm/gemm_output.txt","r");
  file_odata = output_filep2;
  $display("\n%t In check_output_data function. Checking outputs : \n", $time);
  while (! $feof(file_odata)) begin   // because we want to read the same amount of values
      cnt += 1;
      $fscanf(file_odata,"%d\n",read_odata);
      ret_rd_value = m03_obuf_axi.mem_model.backdoor_memory_read_4byte(obuf_ptr1 + (slot * 4));
      
      if ((read_odata != ret_rd_value)) begin
          $error("%d: Output Memory Mismatch:  : @0x%x : Expected %d -> Got %D ",cnt, obuf_ptr1 + (slot * 4), read_odata, ret_rd_value);
          error_found |= 1;
          error_counter++;
      end
      slot++;
      `ifdef STRIDE_BASED
      tile_elements_counter++;
      if (tile_elements_counter == output_tile_size_32B_cnt) begin
        tile_counter++;
        tile_elements_counter = 0;
        obuf_ptr1 = obuf_ptr1 + stride;
        slot = 0;
        $display("\n%t New Output Address = %D: \n", $time, obuf_ptr1);
      end
      `endif

      if (error_counter > 20) begin
        $display("Too many errors found. Exiting check of m03_axi.");
        return(error_found);
      end
      
  end 

  return(error_found);
endfunction




bit choose_pressure_type = 0;
bit axis_choose_pressure_type = 0;
bit [0-1:0] axis_tlast_received;

/////////////////////////////////////////////////////////////////////////////////////////////////
// The task will poll the DONE bit and check the results on the host when complete.
task automatic systolic_driver(output bit error_found);
  bit [31:0] slv_reg0_out     =   32'd0 ;
  bit [31:0] slv_reg1_out     =   axi00_imem_addr;
  bit [31:0] slv_reg2_out     =   num_instruction_bytes; // 193 instr each 4 bytes
  bit [31:0] slv_reg3_out     =   32'd0 ;
  bit [31:0] slv_reg4_out     =   32'd0 ;
  bit [31:0] slv_reg5_out     =   32'd0 ;
  bit [31:0] slv_reg6_out     =   32'd0 ;
  bit [31:0] slv_reg7_out     =   32'd0 ;
  bit [31:0] slv_reg8_out     =   32'd0 ;
  bit [31:0] slv_reg9_out     =   32'd0 ;
  bit [31:0] slv_reg10_out    =   32'd0 ;
  bit [31:0] slv_reg11_out    =   32'd0 ;
  bit [31:0] slv_reg12_out    =   32'd0 ;
  bit [31:0] slv_reg13_out    =   32'd0 ;
  bit [31:0] slv_reg14_out    =   32'd0 ;
  

  //bit [63:0] m00_axi_ptr_random      =   get_random_ptr();
  //bit [63:0] m01_axi_ptr_random      =   get_random_ptr();
  //bit [63:0] m02_axi_ptr_random      =   get_random_ptr();
  //bit [63:0] m03_axi_ptr_random      =   get_random_ptr();

  // for resnet_18 8 tiles
  bit [63:0] m00_axi_ptr_random      = axi00_imem_addr ; // does not matter as Innstructions as written using config reg
  bit [63:0] m01_axi_ptr_random      = axi01_parambuf_addr ;
  bit [63:0] m02_axi_ptr_random      = axi02_ibuf_addr ;
  bit [63:0] m03_axi_ptr_random      = axi03_obuf_addr;
  bit [63:0] m04_axi_ptr_random      = axi04_bias_addr ;

  
  bit [63:0] m00_axi_ptr             = m00_axi_ptr_random; 
  bit [63:0] m01_axi_ptr             = m01_axi_ptr_random; 
  bit [63:0] m02_axi_ptr             = m02_axi_ptr_random; 
  bit [63:0] m03_axi_ptr             = m03_axi_ptr_random; 
  bit [63:0] m04_axi_ptr             = m04_axi_ptr_random; 

   // 67108864; // 27'b100000000000000000000000000;     // Imem
   // 100663296;  // 27b'110000000000000000000000000;   // Weights
   // 117440512;  // 27'b111000000000000000000000000;   // inputs
   // 125845504;  // 27'b111100000000100000000000000;   // bias
   // 134217856; // 27'b1000000000000000000010000000;   // output
   // stride = 1048576

  integer stride                          = config_stride                   ;
  integer input_num_tiles                 = config_input_num_tiles          ;
  integer bias_num_tiles                  = config_bias_num_tiles           ;
  integer weight_num_tiles                = config_weight_num_tiles         ;
  integer output_num_tiles                = config_output_num_tiles         ;  
  integer input_tile_size_32B_cnt         = config_input_tile_size_32B_cnt  ;
  integer bias_tile_size_32B_cnt          = config_bias_tile_size_32B_cnt   ;
  integer weight_tile_size_32B_cnt        = config_weight_tile_size_32B_cnt ;
  integer output_tile_size_32B_cnt        = config_output_tile_size_32B_cnt ;
    
    
    
    error_found = 0;

    $display("Starting: systolic_driver");
    
    // ignore the below two functions. THey are for AXI
    slv_no_backpressure_wready();
    slv_no_delay_rvalid();

    set_scalar_registers(slv_reg0_out,
                         slv_reg1_out,
                         slv_reg2_out,
                         slv_reg3_out,
                         slv_reg4_out,
                         slv_reg5_out,
                         slv_reg6_out,
                         slv_reg7_out,
                         slv_reg8_out,
                         slv_reg9_out,
                         slv_reg10_out,
                         slv_reg11_out,
                         slv_reg12_out,
                         slv_reg13_out,
                         slv_reg14_out);
    
    `ifdef DEBUG
       $display("%t : set_scalar_registers done", $time);
    `endif 
                  
    set_memory_pointers(m00_axi_ptr, m01_axi_ptr, m02_axi_ptr, m03_axi_ptr, m04_axi_ptr);
    `ifdef DEBUG
       $display("%t : set_memory_pointers done", $time);
    `endif 

    backdoor_fill_memories(input_num_tiles, bias_num_tiles, weight_num_tiles, output_num_tiles, input_tile_size_32B_cnt, bias_tile_size_32B_cnt, weight_tile_size_32B_cnt, output_tile_size_32B_cnt, stride);
    `ifdef DEBUG
       $display("%t : backdoor_fill_memories done", $time);
    `endif
    // sanity check the memory to ensure correct data was written
    check_memory_data(input_num_tiles, bias_num_tiles, weight_num_tiles, output_num_tiles, input_tile_size_32B_cnt, bias_tile_size_32B_cnt, weight_tile_size_32B_cnt, output_tile_size_32B_cnt, stride);
    // Check that Kernel is IDLE before starting.
    poll_idle_register();
    `ifdef DEBUG
       $display("%t : poll_idle_register done", $time);
    `endif 
    ///////////////////////////////////////////////////////////////////////////
    //Start transfers
    blocking_write_register(KRNL_CTRL_REG_ADDR, CTRL_START_MASK);
    
    `ifdef DEBUG
       $display("%t : blocking_write_register done", $time);
    `endif
    ctrl.wait_drivers_idle();
     `ifdef DEBUG
       $display("%t : wait_drivers_idle done", $time);
    `endif 

    ///////////////////////////////////////////////////////////////////////////
    //Wait for interrupt being asserted or poll done register
    // poll until done flag is asserted
    poll_done_register();
    `ifdef DEBUG
       $display("%t : poll_done_register done", $time);
    `endif
    
    error_found |= check_output_data(output_num_tiles, 
                                     output_tile_size_32B_cnt,
                                     stride);
  

    $display("Finished");

 endtask

// Main Driver
initial begin : STIMULUS
  #200000;
  
  `ifdef DEBUG
    $display("%t : Simulation Started", $time);
  `endif

  start_vips();
  `ifdef DEBUG
    $display("%t : VIPs Started, Next Checking Scalar Registers", $time);
  `endif 

  check_scalar_registers(error_found);
  if (error_found == 1) begin
    $display( "Test Failed!");
    $finish();
  end
  `ifdef DEBUG
    $display("%t : check_scalar_registers done, Next check_pointer_registers", $time);
  `endif

  check_pointer_registers(error_found);
  if (error_found == 1) begin
    $display( "Test Failed!");
    $finish();
  end
   
  `ifdef DEBUG
    $display("%t : check_pointer_registers done, next enable_interrupts", $time);
  `endif 


  enable_interrupts();
  
  `ifdef DEBUG
    $display("%t : enable_interrupts done, Next simd_driver", $time);
  `endif
  
  systolic_driver(error_found);

  if (error_found == 1) begin
    $display( "Test Failed!");
    $finish();
  end 
  else begin
    $display( "Test completed successfully");
  end
  $finish;
end

endmodule
`default_nettype wire

