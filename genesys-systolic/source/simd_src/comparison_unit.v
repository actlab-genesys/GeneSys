`timescale 1ns / 1ps

module comparison_unit#(
    parameter FUNCTION_BITS 		=	4,
    parameter BIT_WIDTH      		=	32
)(
    input       clk,
    input       reset,
    
    input [FUNCTION_BITS-1 : 0] fn,
    
    input signed [BIT_WIDTH-1 : 0] data_in0,
    input signed [BIT_WIDTH-1 : 0] data_in1,
    
    output reg [BIT_WIDTH-1 : 0] data_out
    
    );
    
    wire eq,lt,gt,gte,lte;
    
    assign eq = (data_in0 == data_in1);
    assign gt = (data_in0 > data_in1);
    assign gte = gt || eq;
    assign lt = ~gte;
    assign lte = lt || eq;
    
    always @(*) begin
        case(fn)
            4'b0000,4'b0001: begin
                if (eq)
                    data_out = fn[0] ? 'd0 : 'd1;
                else
                    data_out = fn[0] ? 'd1 : 'd0;
            end   
            4'b0010:    data_out = gt ? 'd1 : 'd0;
            4'b0011:    data_out = gte ? 'd1 : 'd0;
            4'b0100:    data_out = lt ? 'd1 : 'd0;
            4'b0101:    data_out = lte ? 'd1 : 'd0;
            default:    data_out = 'd0;
        endcase        
    end
endmodule