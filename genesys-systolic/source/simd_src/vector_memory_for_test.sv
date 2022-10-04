`timescale 1ns / 1ps

module vector_memory_for_test #(
    parameter integer   DATA_WIDTH    = 32,
    parameter integer   ADDR_WIDTH    = 32,
    parameter string    FILE_NAME     = "0",
    parameter NUM_ELEM                = 16
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

generate
for ( genvar gv = 0 ; gv < NUM_ELEM ; gv = gv + 1) begin
    wire [DATA_WIDTH - 1 : 0] mem_data_in,mem_data_out;
    assign mem_data_in = write_data[gv*DATA_WIDTH+:DATA_WIDTH];
    assign read_data[gv*DATA_WIDTH+:DATA_WIDTH] = mem_data_out;
    
    ram_for_test #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .FILE_NAME(FILE_NAME),
        .num(gv),
        .num_elem(NUM_ELEM)
    ) vector_memory_bank (
        .clk		 (  clk                 ),
        .reset       (	reset               ),
    
        .read_req    (  read_req[gv]                                    ),
        .read_addr   (	read_addr[ADDR_WIDTH*gv +: ADDR_WIDTH]          ),
        .read_data   (	mem_data_out                                    ),   

        .write_req   (	write_req[gv]                                   ),   
        .write_addr  (	write_addr[ADDR_WIDTH*gv +: ADDR_WIDTH]         ),   
        .write_data  (	mem_data_in                                     )    
    );
    
end
endgenerate 
    
endmodule
