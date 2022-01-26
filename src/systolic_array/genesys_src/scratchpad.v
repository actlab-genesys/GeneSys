//
// SRAM Block

// Soroush Ghodrati 
// soghodra@eng.ucsd.edu

`timescale 1ns/1ps

module scratchpad #(

	parameter					DATA_BITWIDTH						= 8,
	parameter					ADDR_BITWIDTH						= 10
)(
	input															clk,
	input															reset,
	input															read_req,
	input															write_req,	
	input						[ADDR_BITWIDTH - 1: 0]				r_addr,
	input						[ADDR_BITWIDTH - 1: 0]				w_addr,
	input						[DATA_BITWIDTH - 1: 0]				w_data,	
	output						[DATA_BITWIDTH - 1: 0]				r_data
);	
	
	reg			[DATA_BITWIDTH - 1: 0]			memory				[0 : (1 << ADDR_BITWIDTH) - 1];
	reg			[DATA_BITWIDTH - 1: 0]								_r_data;
	
		
	always @ (posedge clk) 
	begin : SRAM_READ

		if (reset)
			_r_data <= 0;
		
		else if (read_req == 1)
			_r_data <= memory[r_addr];	
	end
	
	assign 		r_data = _r_data;
	
	always @ (posedge clk)
	begin : SRAM_WRITE
		
		if (write_req == 1)
			memory[w_addr] <= w_data;		
	end
endmodule
