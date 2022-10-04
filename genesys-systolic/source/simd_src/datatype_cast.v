`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/28/2020 09:35:00 AM
// Design Name: 
// Module Name: datatype_cast
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module datatype_cast #(
    parameter FUNCTION_BITS 		=	4,
    parameter BIT_WIDTH      		=	32
)(
    input       clk,
    input       reset,
    
    input [FUNCTION_BITS-1 : 0] fn,
    
    input [31 : 0] immediate,
    input signed [BIT_WIDTH-1 : 0] data_in,
    
    input [7:0]             dest_integer_bits,
    input [7:0]             src1_integer_bits,
    input [7:0]             src2_integer_bits,
    
    output reg [BIT_WIDTH-1 : 0] data_out
    
    );

    wire [5:0] input_fractional_bits, output_fractional_bits;
    wire [5:0] diff,diff2;
    reg [BIT_WIDTH-1 : 0] data_to_saturate;
    wire [31:0] data_32;
    wire [15:0] data_16;
    wire [7:0] data_8;
    wire [3:0] data_4;
    wire [BIT_WIDTH-1 : 0] truncate,ceil,add_for_ceil;
    
    assign  input_fractional_bits = BIT_WIDTH - src1_integer_bits;
    assign  output_fractional_bits = BIT_WIDTH - dest_integer_bits;
    
    //output_fractional_bits = 
    assign diff = input_fractional_bits - output_fractional_bits;
    assign diff2 = output_fractional_bits - input_fractional_bits;
    always @ (*) begin
        if (input_fractional_bits > output_fractional_bits) begin
            data_to_saturate = data_in >>> diff;
        end 
        else if ( input_fractional_bits < output_fractional_bits ) begin
            data_to_saturate = data_in << diff2;
        end
        else data_to_saturate = data_in;
    end
    
    saturate #(
        .Win    (32),
        .Wout   (32)
    ) saturate_32_32 (
        .din        ( data_to_saturate),
        .dout       ( data_32)
    );

    saturate #(
        .Win    (32),
        .Wout   (16)
    ) saturate_32_16 (
        .din        ( data_to_saturate),
        .dout       ( data_16)
    );
    
    saturate #(
        .Win    (32),
        .Wout   (8)
    ) saturate_32_8 (
        .din        ( data_to_saturate),
        .dout       ( data_8)
    );
    
    saturate #(
        .Win    (32),
        .Wout   (4)
    ) saturate_32_4 (
        .din        ( data_to_saturate),
        .dout       ( data_4)
    );
    
    assign truncate = {BIT_WIDTH{1'b1}} << input_fractional_bits;
    assign add_for_ceil = {BIT_WIDTH{1'b1}} >>> (BIT_WIDTH - input_fractional_bits);//{data_in[BIT_WIDTH-1],{BIT_WIDTH-1{1'b1}}} >>> (BIT_WIDTH - input_fractional_bits);
    assign ceil = data_in + add_for_ceil;

    always @(*) begin
        case(fn)
            4'b0000: data_out = {{BIT_WIDTH- 16{data_16[15]}},data_16}; // FXP 32 -> 16
            4'b0001: data_out = {{BIT_WIDTH- 8{data_8[7]}},data_8}; // FXP 32 -> 8
            4'b0010: data_out = {{BIT_WIDTH- 4{data_4[3]}},data_4}; // FXP 32 -> 4
            // Assumption: When going to higher bit width, number of integer bits don't decrease
            4'b0011: data_out = data_to_saturate;  // FXP 16 -> 32 
            4'b0100: data_out = data_to_saturate; // FXP 8 -> 32
            4'b0101: data_out = data_to_saturate; // FXP 4 -> 32
            4'b1000: data_out = data_in & truncate; // floor
            4'b1001: data_out = ceil & truncate; // ceil
            4'b1100: data_out = data_32;
            default:data_out = 'd0;
        endcase
    end
endmodule
