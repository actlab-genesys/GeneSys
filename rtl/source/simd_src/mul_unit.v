module mul_unit #(
    parameter OPCODE_BITS 			=	4,
    parameter FUNCTION_BITS 		=	4,
    parameter BIT_WIDTH      		=	32
)(
    input       clk,
    input       reset,
    
    input [OPCODE_BITS-1 : 0] opcode,
    input [FUNCTION_BITS-1 : 0] fn,
    
    input signed [BIT_WIDTH-1 : 0] data_in0,
    input signed [BIT_WIDTH-1 : 0] data_in1,
    input signed [BIT_WIDTH-1 : 0] data_acc,
    
    input [7:0] dest_integer_bits,
    input [7:0] src1_integer_bits,
    input [7:0] src2_integer_bits,
    
    output reg signed [BIT_WIDTH-1 : 0] data_out
);
    wire gtz;
    wire [BIT_WIDTH:0] decimal_start;
    wire signed [2*BIT_WIDTH-1:0]   mult_out_temp;
    wire signed [BIT_WIDTH-1:0]     mult_out_cropped;
    reg signed [BIT_WIDTH-1:0]      mult_out, acc_final;
    wire signed [BIT_WIDTH:0]       acc_out;
    wire [7:0] src_bit_width;
    
    assign src_bit_width = (src1_integer_bits > src2_integer_bits) ? src1_integer_bits : src2_integer_bits;
    assign gtz = ~data_in0[BIT_WIDTH-1];
    //assign decimal_start = 2*BIT_WIDTH-src_bit_width-BIT_WIDTH;
    assign decimal_start = BIT_WIDTH-src_bit_width;
    assign mult_out_temp = data_in0 * data_in1;
    assign mult_out_cropped = mult_out_temp[decimal_start +: BIT_WIDTH];
    
    ////// Debug
    reg zeros,ones;
    wire [3:0] checks;
    
    // Cover all the integer bits possibility here since the cropped length varies
    always @(*) begin
        if (src_bit_width == 16) begin
            zeros = |mult_out_temp[BIT_WIDTH*2-1:16+BIT_WIDTH];
            ones = &mult_out_temp[BIT_WIDTH*2-1:16+BIT_WIDTH];
        end else begin
            zeros = |mult_out_temp[BIT_WIDTH*2-1:16+BIT_WIDTH];
            ones = &mult_out_temp[BIT_WIDTH*2-1:16+BIT_WIDTH];
        end  
    end
    
    assign checks = {data_in0[BIT_WIDTH-1], data_in1[BIT_WIDTH-1], mult_out_cropped[BIT_WIDTH-1], zeros};
    
    always @(*) begin
        case(checks)
            4'b00x0, 4'b11x0: mult_out = {1'b0,{BIT_WIDTH-1{1'b1}}}; 
            4'b01x1, 4'b10x1: mult_out = {1'b1,{BIT_WIDTH-1{1'b0}}};
            default : mult_out = mult_out_cropped[BIT_WIDTH-1:0];
        endcase
    end

    assign acc_out = mult_out + data_acc;
    always @(*) begin
        case( acc_out[BIT_WIDTH:BIT_WIDTH-1])
            2'b01 : acc_final = {1'b0,{BIT_WIDTH-1{1'b1}}};
            2'b10 : acc_final = {1'b1,{BIT_WIDTH-1{1'b0}}};
            default : acc_final = acc_out[BIT_WIDTH-1 : 0];
        endcase
    end

    always @(*) begin
        case (opcode)
            4'b0000: begin
                case (fn)
                    4'b0010: data_out = mult_out;
                    4'b0011: data_out = acc_final;
                    default: data_out = data_in0;
                endcase
            end

            4'b0001: begin
                case (fn)
                    4'b0001: data_out = gtz ? data_in0 : mult_out;
                    default: data_out = data_in0;
                endcase
            end
            
            default:    data_out = data_in0;
        endcase        
    end
endmodule

// module mul_tb();
//     wire done;    
//     wire [31 : 0]   data_in0;
//     wire [31 : 0]   data_in1;
//     wire [31 : 0]  data_out;
//     reg clk,reset;

//     always #1 clk = ~clk;

//     reg signed [15:0] integers_0, integers_1;
//     reg [15:0] fractions_0, fractions_1;
    
//     assign data_in0 = {integers_0, fractions_0};
//     assign data_in1 = {integers_1, fractions_1};

//     initial begin
//         clk <= 1; reset <= 1'b1; @(posedge clk); 
//         repeat(5)
//             @(posedge clk); 
//         reset <= 1'b0; @(posedge clk); 
        
//         integers_0 <= 0; fractions_0 <= 65535; integers_1 <= 0; fractions_1 <= 65535; @(posedge clk);
//         integers_0 <= 32767; fractions_0 <= 32767; integers_1 <= 0; fractions_1 <= 65535; @(posedge clk);
        
        
//         repeat(5)
//             @(posedge clk); 
//         $stop();
//     end

//     mul_unit dut (
//         .clk(clk),
//         .reset(reset),
//         .opcode(4'bb0000),
//         .fn(4'b0010),
//         .data_in0(data_in0),
//         .data_in1(data_in1),
//         .data_acc(),
//         .dest_integer_bits(16),
//         .src1_integer_bits(16),
//         .src2_integer_bits(16),
//         .data_out(data_out)
//     );

// endmodule 