`define FPGA
`timescale 1ns/1ps
module weight_buffer
#(
    parameter integer DDR_BANDWIDTH                 = 512,
    parameter integer NUM_BANKS                     = 64,
    parameter integer DATA_WIDTH                    = 8,
    parameter integer READ_WIDTH                    = 8,
    parameter integer BUFFER_DEPTH                  = 64,
    parameter integer READ_LATENCY_B                = 1,
    parameter integer WRITE_WIDTH                   = 8,
    parameter integer MEMORY_SIZE                   = 256,
    parameter integer WRITE_ADDR_WIDTH              = 8,  
    parameter integer READ_ADDR_WIDTH               = 8
)
(
    input  wire                                  clk,
    input  wire                                  reset,
    input  wire                                  bs_read_req,
    input  wire  [READ_ADDR_WIDTH     -1 : 0]    bs_read_addr,
    output wire  [READ_WIDTH          -1 : 0]    bs_read_data,
    input  wire                                  bs_write_req,
    input  wire  [WRITE_ADDR_WIDTH     -1 : 0]   bs_write_addr,
    input  wire  [WRITE_WIDTH            -1 : 0] bs_write_data
);

    wire                                         regceb;

    assign regceb = 1'b0;

    `ifdef FPGA
 
        simple_dual_port_xpm #(
            .WRITE_WIDTH      (WRITE_WIDTH),     
            .READ_WIDTH       (READ_WIDTH),     
            .BUFFER_DEPTH     (BUFFER_DEPTH),     
            .READ_LATENCY_B   (READ_LATENCY_B),
            .MEMORY_SIZE      (MEMORY_SIZE     ),
            .WRITE_ADDR_WIDTH (WRITE_ADDR_WIDTH),  
            .READ_ADDR_WIDTH  (READ_ADDR_WIDTH )

        ) ram (
            .clka(clk),
            .rstb(reset),
            .addra(bs_write_addr),
            .addrb(bs_read_addr),
            .dina(bs_write_data),
            .ena(bs_write_req),
            .enb(bs_read_req),
            .regceb(regceb),
            .wea(bs_write_req),
            .dbiterrb(),
            .doutb(bs_read_data),
            .sbiterrb()
        );
    
    `else
	
    scratchpad #(
		.DATA_BITWIDTH											(DATA_WIDTH),
		.ADDR_BITWIDTH											(WRITE_ADDR_WIDTH)
	) weight_scratchpad (
		.clk													(clk),
		.reset													(reset),
		.read_req												(bs_read_req),
		.write_req   											(bs_write_req),
		.r_addr													(bs_read_addr),
		.w_addr													(bs_write_addr),
		.w_data													(bs_write_data),
		.r_data													(bs_read_data)
	);

    `endif
                

endmodule