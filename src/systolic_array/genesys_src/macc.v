//
// Processing Element (MACC unit)
//
// Soroush Ghodrati
// (soghodra@eng.ucsd.edu)

`timescale 1ns/1ps

module macc #(
	parameter					 ACT_BITWIDTH							 	 = 16,
	parameter					 WGT_BITWIDTH							     = 16,
	parameter					 SUM_IN_BITWIDTH							 = 64,
	parameter					 INTER_BITWIDTH							     = 65,
	parameter					 MULT_OUT_BITWIDTH							 = ACT_BITWIDTH + WGT_BITWIDTH,
	parameter					 ACT_OUT_BITWIDT							 = ACT_BITWIDTH
)(
	input					[ACT_BITWIDTH - 	1 : 0]			a_in,
	input					[WGT_BITWIDTH - 	1 : 0]			w_in,
	input					[SUM_IN_BITWIDTH -  1 : 0]			sum_in,
	output					[INTER_BITWIDTH -   1 : 0]			out
);
	
	wire	  signed		[ACT_BITWIDTH - 	1 : 0]			_a_in;
	wire	  signed 		[WGT_BITWIDTH - 	1 : 0]			_w_in;
	wire	  signed		[MULT_OUT_BITWIDTH- 1 : 0]			_mult_out;
	wire	  signed		[SUM_IN_BITWIDTH -  1 : 0]			_sum_in;
	
	assign	  _a_in = a_in;
	assign 	  _w_in = w_in;
	assign	  _sum_in = sum_in;
	
	
	assign 	  _mult_out    = _a_in * _w_in;
	

	wire 	  signed		[INTER_BITWIDTH - 	1 : 0]			_sum_out;
	
	assign	  _sum_out = _mult_out + _sum_in;
	
	assign	  out      =  _sum_out;
	
endmodule

	
	
	
	