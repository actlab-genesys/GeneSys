`timescale 1ns / 1ps

module compute_unit #(
    parameter OPCODE_BITS 			=	4,
	parameter FUNCTION_BITS 		=	4,
	parameter BASE_STRIDE_WIDTH     =   32,
	parameter DATA_WIDTH            =   32
)(
    input clk,
    input reset,
    
    input [DATA_WIDTH-1 : 0] data_in0,
    input [DATA_WIDTH-1 : 0] data_in1,
    
    input acc_reset,
    input reduction_flag,
    input reduction_dim,

    input [7:0]             dest_integer_bits,
    input [7:0]             src1_integer_bits,
    input [7:0]             src2_integer_bits,

    output reg [DATA_WIDTH-1 : 0] data_out,
    
    input [OPCODE_BITS-1 : 0] opcode,
    input [FUNCTION_BITS-1 : 0] fn
    );
    
    wire [DATA_WIDTH-1 : 0] data_out_arith_temp,data_out_arith,data_out_mul,data_out_calc_temp,data_out_calc,data_out_comp,data_out_cast, data_acc;
    reg [DATA_WIDTH-1 :0] data_out_mux;
    reg [BASE_STRIDE_WIDTH-1 : 0] buffer_address_write_d;

    assign data_acc = acc_reset ? 0'b0 : data_out;
    assign data_out_arith = (opcode == 4'b0000) && (fn == 4'b0010 || fn == 4'b0011) ? data_out_mul : data_out_arith_temp;
    assign data_out_calc = (opcode == 4'b0001) && (fn == 4'b0001) ? data_out_mul : data_out_calc_temp;

    wire [DATA_WIDTH-1 : 0] data_in0_muxed;
    wire [DATA_WIDTH-1 : 0] data_in1_muxed;
    
    assign data_in0_muxed =  data_in0;
    assign data_in1_muxed =  data_in1;

//    assign data_in0_muxed = (reduction_flag && !reduction_dim) ? data_out : data_in0;
//    assign data_in1_muxed = (reduction_flag && reduction_dim) ? data_out : data_in1;

    mul_unit mul_inst (
        .clk            (   clk             ),
        .reset          (   reset           ),
        
        .opcode         (   opcode          ),
        .fn             (   fn              ),
        .data_in0       (   data_in0        ),
        .data_in1       (   data_in1        ),
        .data_acc       (   data_acc        ),

        .dest_integer_bits  (   dest_integer_bits   ),
        .src1_integer_bits  (   src1_integer_bits   ),
        .src2_integer_bits  (   src2_integer_bits   ),

        .data_out       (   data_out_mul   )
    );

    arithmetic_unit arithmetic_inst (
        .clk            (   clk             ),
        .reset          (   reset           ),
        
        .fn             (   fn              ),
        .data_in0       (   data_in0_muxed        ),
        .data_in1       (   data_in1_muxed        ),
        .data_acc       (   data_acc        ),
        
        .dest_integer_bits  (   dest_integer_bits   ),
        .src1_integer_bits  (   src1_integer_bits   ),
        .src2_integer_bits  (   src2_integer_bits   ),
    
        .data_out       (   data_out_arith_temp  )
    );
    
    comparison_unit comparison_inst (
        .clk            (   clk             ),
        .reset          (   reset           ),
        
        .fn             (   fn              ),
        .data_in0       (   data_in0        ),
        .data_in1       (   data_in1        ),
        .data_out       (   data_out_comp   )
    );
    
    calculus_unit calculus_inst (
        .clk            (   clk             ),
        .reset          (   reset           ),
        
        .fn             (   fn              ),
        .data_in0       (   data_in0        ),
        .data_in1       (   data_in1        ),

        .dest_integer_bits  (   dest_integer_bits   ),
        .src1_integer_bits  (   src1_integer_bits   ),
        .src2_integer_bits  (   src2_integer_bits   ),

        .data_out       (   data_out_calc_temp   )
    );
    
    datatype_cast cast_inst (
        .clk            (   clk             ),
        .reset          (   reset           ),
        
        .fn             (   fn              ),
        .immediate      (   data_in1[31:0]  ),
        .data_in        (   data_in0        ),

        .dest_integer_bits  (   dest_integer_bits   ),
        .src1_integer_bits  (   src1_integer_bits   ),
        .src2_integer_bits  (   src2_integer_bits   ),
        
        .data_out       (   data_out_cast   )
    );
        
    always @(*) begin
        case(opcode)
            4'b0000: data_out_mux = data_out_arith;
            4'b0001: data_out_mux = data_out_calc;
            4'b0010: data_out_mux = data_out_comp;
            4'b0011: data_out_mux = data_out_cast;
            default: data_out_mux = 'd0;
        endcase
    end
    
    always @(posedge clk ) begin
        if(reset) begin
            data_out <= 'b0;
        end else begin
            data_out <=  data_out_mux;
        end
    end
    
endmodule
