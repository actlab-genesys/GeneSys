`define FPGA
`timescale 1ns/1ps
module ibuf
#(
    parameter integer DDR_BANDWIDTH                 = 512,
    parameter integer NUM_BANKS                     = 64,
    parameter integer DATA_WIDTH                    = 8,
    parameter integer READ_WIDTH                    = 64,
    parameter integer BUFFER_DEPTH                  = 64,
    parameter integer READ_LATENCY_B                = 1,
    parameter integer WRITE_WIDTH                   = 8,
    parameter integer MEMORY_SIZE                   = 1024,
    parameter integer WRITE_ADDR_WIDTH              = 8,  
    parameter integer READ_ADDR_WIDTH               = 8
)
(
    input  wire                                         clk,
    input  wire                                         reset,
    
    input  wire  [ NUM_BANKS                -1 : 0 ]    bs_read_req,
    input  wire  [ NUM_BANKS*READ_ADDR_WIDTH     -1 : 0 ]    bs_read_addr,
    output wire  [ READ_WIDTH*NUM_BANKS    -1 : 0 ]    bs_read_data,
    
    input  wire  [ NUM_BANKS                -1 : 0 ]    bs_write_req,
    input  wire  [ NUM_BANKS*WRITE_ADDR_WIDTH     -1 : 0 ]    bs_write_addr,
    input  wire  [ DDR_BANDWIDTH            -1 : 0 ]    bs_write_data
);

    wire  [ DDR_BANDWIDTH            -1 : 0 ]    bs_write_data_w;
    wire                                         regceb;

    assign regceb = 1'b0;

`ifdef FPGA
    ibuf_data_shuffler #(
        .DDR_BANDWIDTH(DDR_BANDWIDTH),
        .NUM_BANKS(NUM_BANKS),    
        .DATA_WIDTH(DATA_WIDTH)    
    ) i_ibuf_data_shuffler (
        .data_in(bs_write_data),
        .data_out(bs_write_data_w)
    );
`endif

    genvar n;
    generate
        for (n=0; n<NUM_BANKS; n=n+1) begin
                wire                              _read_req;
                wire  [READ_ADDR_WIDTH     -1 : 0 ]    _read_addr;
                wire  [READ_WIDTH     -1 : 0 ]    _read_data;
    
                wire                              _write_req;
                wire  [WRITE_ADDR_WIDTH     -1 : 0 ]    _write_addr;
                wire  [WRITE_WIDTH     -1 : 0 ]    _write_data;
                wire                                _write_data_en;
             
                assign _write_req = bs_write_req[n];
                assign _write_addr = bs_write_addr[((n+1) * WRITE_ADDR_WIDTH) - 1 : n*WRITE_ADDR_WIDTH];
                assign _write_data = bs_write_data_w[((n+1) * WRITE_WIDTH) - 1 : n*WRITE_WIDTH];
                assign _write_data_en = bs_write_req[n];
                
            `ifdef FPGA
                simple_dual_port_xpm #(
                    .WRITE_WIDTH        (WRITE_WIDTH),     
                    .READ_WIDTH         (READ_WIDTH),     
                    .BUFFER_DEPTH       (BUFFER_DEPTH),     
                    .READ_LATENCY_B     (READ_LATENCY_B), 
                    .MEMORY_SIZE        (MEMORY_SIZE),    
                    .WRITE_ADDR_WIDTH   (WRITE_ADDR_WIDTH),
                    .READ_ADDR_WIDTH    (READ_ADDR_WIDTH)    
                ) ibuf_bank (
                    .clka(clk),
                    .rstb(reset),
                    .addra(_write_addr),
                    .addrb(_read_addr),
                    .dina(_write_data),
                    .ena(_write_req),
                    .enb(_read_req),
                    .regceb(regceb),
                    .wea(_write_data_en),
                    .dbiterrb(),
                    .doutb(_read_data),
                    .sbiterrb()
                );
            `else
               scratchpad #(
                    .DATA_BITWIDTH                                          (DATA_WIDTH),
                    .ADDR_BITWIDTH                                          (ADDR_WIDTH)
               ) bank_scratchpad (
                    .clk                                                    (clk),
                    .reset                                                  (reset),
                    .read_req                                               (_read_req),
                    .write_req                                              (_write_req),
                    .r_addr                                                 (_read_addr),
                    .w_addr                                                 (_write_addr),
                    .w_data                                                 (_write_data),
                    .r_data                                                 (_read_data)
              );
            `endif

           
                assign  _read_req  = bs_read_req[n];
                assign  _read_addr = bs_read_addr[((n+1) * READ_ADDR_WIDTH) - 1 :n*READ_ADDR_WIDTH];
                assign  bs_read_data[((n+1) * DATA_WIDTH) - 1 :n*DATA_WIDTH] = _read_data;
                
         end
    endgenerate

endmodule