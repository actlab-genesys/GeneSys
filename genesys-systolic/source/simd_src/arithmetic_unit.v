`timescale 1ns / 1ps

module arithmetic_unit #(
    parameter FUNCTION_BITS 		=	4,
    parameter BIT_WIDTH      		=	32
)(
    input       clk,
    input       reset,
    
    input [FUNCTION_BITS-1 : 0] fn,
    
    input signed [BIT_WIDTH-1 : 0] data_in0,
    input signed [BIT_WIDTH-1 : 0] data_in1,
    input signed [BIT_WIDTH-1 : 0] data_acc,
    
    input [7:0] dest_integer_bits,
    input [7:0] src1_integer_bits,
    input [7:0] src2_integer_bits,
    
    output reg signed [BIT_WIDTH-1 : 0] data_out
);
    wire signed [BIT_WIDTH:0]       sum_out,sub_out,acc_out;
    reg signed [BIT_WIDTH-1:0]      sum_final,sub_final,acc_final;
    wire signed [2*BIT_WIDTH-1:0]   mult_out_temp;
    wire signed [BIT_WIDTH-1:0]     mult_out_cropped;
    reg signed [BIT_WIDTH-1:0]      mult_out;
    wire [BIT_WIDTH-1:0]            div_out;
    
    assign sum_out = data_in0 + data_in1;
    assign sub_out = data_in0 - data_in1;
 
    always @(*) begin
        case(sum_out[BIT_WIDTH:BIT_WIDTH-1])
            2'b01 : sum_final = {1'b0,{BIT_WIDTH-'d1{1'b1}}};
            2'b10 : sum_final = {1'b1,{BIT_WIDTH-'d1{1'b0}}};
            default : sum_final = sum_out[BIT_WIDTH-1 : 0];
        endcase
    end
    
    always @(*) begin
        case( sub_out[BIT_WIDTH:BIT_WIDTH-1])
            2'b01 : sub_final = {1'b0,{BIT_WIDTH-'d1{1'b1}}};
            2'b10 : sub_final = {1'b1,{BIT_WIDTH-'d1{1'b0}}};
            default : sub_final = sub_out[BIT_WIDTH-1 : 0];
        endcase
    end
    
    always @(*) begin
        case(fn)
            4'b0000:    data_out = sum_final;
            4'b0001:    data_out = sub_final;
            4'b0100:    data_out = div_out;
            4'b0101,4'b110:  begin
                if ( data_in0 > data_in1)
                    data_out = fn[0] ? data_in0 : data_in1;
                else
                    data_out = fn[0] ? data_in1 : data_in0;
            end
            4'b0111:    data_out = data_in0 >>> $unsigned(data_in1[4:0]);
            4'b1000:    data_out = data_in0 <<< $unsigned(data_in1[4:0]);
            4'b1001:    data_out = data_in0 ;
            4'b1010:    data_out = data_in0 ;
            4'b1011:    data_out = data_in0 ;
            4'b1100:    data_out = ~data_in0 ;
            4'b1101:    data_out = data_in0 & data_in1 ;
            4'b1110:    data_out = data_in0 | data_in1 ;
            default:    data_out = data_in0;
        endcase        
    end
endmodule