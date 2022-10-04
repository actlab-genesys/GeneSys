`timescale 1ns / 1ps
`define FPGA

module vector_memory
#(
  parameter integer DATA_WIDTH    = 16,
  parameter integer ADDR_WIDTH    = 16,
  parameter integer READ_LATENCY_B = 1,
  parameter NUM_ELEM              = 64
)(
    input  wire                         clk,
    input  wire                         reset,

    input  wire [ NUM_ELEM  -1 : 0 ]             read_req,
    input  wire [ ADDR_WIDTH*NUM_ELEM  -1 : 0 ]  read_addr,
    output wire [ DATA_WIDTH*NUM_ELEM  -1 : 0 ]  read_data,

    input  wire [ NUM_ELEM  -1 : 0 ]             write_req,
    input  wire [ ADDR_WIDTH*NUM_ELEM  -1 : 0 ]  write_addr,
    input  wire [ DATA_WIDTH*NUM_ELEM  -1 : 0 ]  write_data
 );
    
    localparam integer BUFFER_DEPTH = 2 << ADDR_WIDTH;
    localparam integer MEMORY_SIZE = BUFFER_DEPTH * ADDR_WIDTH;
    localparam integer WRITE_ADDR_WIDTH = ADDR_WIDTH;
    localparam integer READ_ADDR_WIDTH  = ADDR_WIDTH;
    
    generate
    for ( genvar gv = 0 ; gv < NUM_ELEM ; gv = gv + 1) begin
        
        wire [DATA_WIDTH - 1 : 0] mem_data_in,mem_data_out;
        
        assign mem_data_in = write_data[gv*DATA_WIDTH+:DATA_WIDTH];
        assign read_data[gv*DATA_WIDTH+:DATA_WIDTH] = mem_data_out;
        
        `ifdef FPGA
        simple_dual_port_xpm #(
            .WRITE_WIDTH        (DATA_WIDTH),     
            .READ_WIDTH         (DATA_WIDTH),     
            .BUFFER_DEPTH       (BUFFER_DEPTH),
            .READ_LATENCY_B     (READ_LATENCY_B), 
            .MEMORY_SIZE        (MEMORY_SIZE),    
            .WRITE_ADDR_WIDTH   (WRITE_ADDR_WIDTH),
            .READ_ADDR_WIDTH    (READ_ADDR_WIDTH)    
        ) vector_memory_bank (
            .clka(clk),
            .rstb(reset),
            
            .addra(write_addr[ADDR_WIDTH*gv +: ADDR_WIDTH]),
            .addrb(read_addr[ADDR_WIDTH*gv +: ADDR_WIDTH]),
            .dina(mem_data_in),
            .ena(write_req[gv]),
            .enb(read_req[gv]),
            .regceb(1'b0),
            .wea(write_req[gv]),
            .dbiterrb(),
            .doutb(mem_data_out),
            .sbiterrb()
        );
        `else
        ram #(
          .DATA_WIDTH(DATA_WIDTH),
          .ADDR_WIDTH(ADDR_WIDTH )
        ) vector_memory_bank (
          .clk		   (    clk                 ),
          .reset       (	reset               ),
        
          .read_req    (    read_req[gv]                                    ),
          .read_addr   (	read_addr[ADDR_WIDTH*gv +: ADDR_WIDTH]          ),
          .read_data   (	mem_data_out                                    ),   

          .write_req   (	write_req[gv]                                   ),   
          .write_addr  (	write_addr[ADDR_WIDTH*gv +: ADDR_WIDTH]         ),   
          .write_data  (	mem_data_in                                     )    
        );
        `endif
        
    end
    endgenerate 
    
endmodule
