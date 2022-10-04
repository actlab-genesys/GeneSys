//
// Truncator
// Soroush Ghodrati
// (soghodra@eng.ucsd.edu)

`timescale 1ns/1ps

module truncator #(
/*$*/
	parameter				 TRUNCATION_MODE						 = "MSB",
	parameter				 DATA_IN_BITWIDTH						 = 32,
	parameter				 DATA_OUT_BITWIDTH						 = 32
/*@*/
)(
		
	input						[DATA_IN_BITWIDTH   -1 : 0]		data_in,
	
	output						[DATA_OUT_BITWIDTH	-1 : 0]		data_out
);
	
	wire			signed		[DATA_IN_BITWIDTH   -1 : 0]		_data_in;
	wire			signed		[DATA_OUT_BITWIDTH	-1 : 0]		_data_out;
	
	assign			_data_in = data_in;
	
	
	if		(TRUNCATION_MODE == "MSB")	
		assign 		_data_out = _data_in [DATA_OUT_BITWIDTH	-1 : 0];
		
	else if (TRUNCATION_MODE == "LSB")
		assign 		_data_out = _data_in [DATA_IN_BITWIDTH   -1 : DATA_IN_BITWIDTH - DATA_OUT_BITWIDTH];
	
	assign			data_out = _data_out;
	
endmodule