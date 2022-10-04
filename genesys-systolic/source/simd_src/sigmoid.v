`timescale 1ns / 1ps

module sigmoid #(
    parameter BIT_WIDTH  =	32
)(
    input       clk,
    input       reset,
    input [BIT_WIDTH-1 : 0] data_in,
    input [31 : 0] immediate,
    output reg [BIT_WIDTH-1 : 0] data_out
    );
    
    wire [5:0] fractional_bits;
    reg [5:0] fractional_bits_d;
    wire unsigned [BIT_WIDTH-1 : 0] mod_x;
    reg unsigned [BIT_WIDTH-1 : 0] mod_x_d,mod_x_d2;
    wire [BIT_WIDTH+2:0] const_1;
    reg [BIT_WIDTH-1:0] const_1_d,const_1_d2;
    wire [BIT_WIDTH+2:0] const_2p375,const_5;
    reg [BIT_WIDTH-1:0] const_2p375_d,const_5_d;
    wire [BIT_WIDTH+4:0] const_0p84375,const_0p5,const_0p625;
    reg [BIT_WIDTH-1:0] const_0p84375_d,const_0p5_d,const_0p625_d;
    wire [2:0] select;
    reg [2:0] select_d;
    reg input_sign,input_sign_d;
    reg input_sign_final,input_sign_final_d;
    reg [BIT_WIDTH-1:0] out_y;
    
    reg [BIT_WIDTH-1 : 0] data_in0;
    always @(*) begin
        if (!data_in[BIT_WIDTH-1]) begin
            data_in0 = data_in;
        end else begin
            data_in0 = (~data_in) + 1'b1;
        end
    end

    assign fractional_bits = immediate[5:0];
    assign mod_x = (data_in0 ^ {BIT_WIDTH{data_in0[BIT_WIDTH-1]}}) + (const_1 & {BIT_WIDTH{data_in0[BIT_WIDTH-1]}}) ;
    
    assign const_1 = 6'b001000 << fractional_bits;
    assign const_2p375 = 6'b010011 << fractional_bits;
    assign const_5 = 6'b101000 << fractional_bits;
    
    always @(posedge clk) begin
        const_1_d <= const_1[BIT_WIDTH+2:3];
        const_2p375_d <= const_2p375[BIT_WIDTH+2:3];
        const_5_d <= const_5[BIT_WIDTH+2:3];
        fractional_bits_d <= fractional_bits;
        mod_x_d <= mod_x;
        input_sign <= data_in[BIT_WIDTH-1];
    end
        
    assign const_0p5 = 5'b10000 << fractional_bits_d;
    assign const_0p625 = 5'b10100 << fractional_bits_d;
    assign const_0p84375 = 5'b11011 << fractional_bits_d;
    
    assign select[0] = mod_x_d < const_1_d ? 1'b1 : 1'b0;
    assign select[1] = mod_x_d < const_2p375_d ? 1'b1 : 1'b0;
    assign select[2] = mod_x_d < const_5_d ? 1'b1 : 1'b0;
    
    always @(posedge clk) begin
        const_1_d2 <= const_1_d;
        mod_x_d2 <= mod_x_d;
        select_d <= select;
        const_0p5_d <= const_0p5[BIT_WIDTH+4:5];
        const_0p625_d <= const_0p625[BIT_WIDTH+4:5];
        const_0p84375_d <= const_0p84375[BIT_WIDTH+4:5];
        input_sign_d <= input_sign;
    end
    
    always @(*) begin
        case(select_d)
            3'b111 : out_y = ((mod_x_d2)    >> 2) + const_0p5_d;
            3'b110 : out_y = ((mod_x_d2)  >> 3) + const_0p625_d;
            3'b100 : out_y = ((mod_x_d2)>> 5) + const_0p84375_d;
            default : out_y = const_1_d2;
        endcase
    end
    
    always @(posedge clk) begin
    
        data_out = input_sign_d ? ((~out_y) + 1'b1) + const_1_d2 : out_y;
    end

endmodule

 
