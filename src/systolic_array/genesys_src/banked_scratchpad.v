// Banked Scratchpad
//
// Soroush Ghodrati
`timescale 1ns/1ps
module banked_scratchpad
#(
    parameter integer  DATA_WIDTH                      = 16,
    parameter integer  ADDR_WIDTH                      = 13,
    parameter integer  NUM_BANKS                       = 8
)
(
    input  wire                                         clk,
    input  wire                                         reset,
    
    input  wire  [ NUM_BANKS                -1 : 0 ]    bs_read_req,
    input  wire  [ NUM_BANKS*ADDR_WIDTH     -1 : 0 ]    bs_read_addr,
    output wire  [ NUM_BANKS*DATA_WIDTH     -1 : 0 ]    bs_read_data,
    
    input  wire  [ NUM_BANKS                -1 : 0 ]    bs_write_req,
    input  wire  [ NUM_BANKS*ADDR_WIDTH     -1 : 0 ]    bs_write_addr,
    input  wire  [ NUM_BANKS*DATA_WIDTH     -1 : 0 ]    bs_write_data
);
    
    genvar n;
    generate
        for (n=0; n<NUM_BANKS; n=n+1) begin
                wire                              _read_req;
                wire  [ADDR_WIDTH     -1 : 0 ]    _read_addr;
                wire  [DATA_WIDTH     -1 : 0 ]    _read_data;
    
                wire                              _write_req;
                wire  [ADDR_WIDTH     -1 : 0 ]    _write_addr;
                wire  [DATA_WIDTH     -1 : 0 ]    _write_data;
             
                assign _write_req = bs_write_req[n];
                assign _write_addr = bs_write_addr[((n+1) * ADDR_WIDTH) - 1 : n*ADDR_WIDTH];
                assign _write_data = bs_write_data[((n+1) * DATA_WIDTH) - 1 : n*DATA_WIDTH];
                
                
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
              
                assign  _read_req  = bs_read_req[n];
                assign  _read_addr = bs_read_addr[((n+1) * ADDR_WIDTH) - 1 :n*ADDR_WIDTH];
                assign  bs_read_data[((n+1) * DATA_WIDTH) - 1 :n*DATA_WIDTH] = _read_data;
                
         end
    endgenerate

endmodule