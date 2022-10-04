`timescale 1ns / 1ps

module tanh #(
    parameter BIT_WIDTH      		=	32,
    parameter TANH_LUT_SIZE         =   8,
    parameter LUT_BIT_WIDTH         =   10
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
    wire [BIT_WIDTH-1:0] const_1;
    reg [BIT_WIDTH-1:0] const_1_d,const_1_d2;

    wire lt1;
    reg input_sign,input_sign_d;
    wire [BIT_WIDTH-1:0] out_y,correction_value;
    reg [BIT_WIDTH-1:0] lut_out,correction_value_d;
    wire [LUT_BIT_WIDTH+BIT_WIDTH-1:0] lut_out_extended;
    
    reg lt1_d;

    reg [BIT_WIDTH-1 : 0] data_in0;
    always @(*) begin
        if (!data_in[BIT_WIDTH-1]) begin
            data_in0 = data_in;
        end else begin
            data_in0 = (~data_in) + 1'b1;
        end
    end

    assign fractional_bits = immediate[5:0];
    assign mod_x = data_in0 ^ {BIT_WIDTH{data_in0[BIT_WIDTH-1]}} + (const_1 & {BIT_WIDTH{data_in0[BIT_WIDTH-1]}});
    
    assign const_1 = 1'b1 << fractional_bits;
    
    /////pipeline
    always @(posedge clk) begin
        const_1_d <= const_1;
        fractional_bits_d <= fractional_bits;
        mod_x_d <= mod_x;
        input_sign <= data_in[BIT_WIDTH-1];
    end
        
    assign lut_out_extended = {{BIT_WIDTH{1'b0}},lut_out[LUT_BIT_WIDTH-1:0]} << fractional_bits;
    assign correction_value = lut_out_extended[LUT_BIT_WIDTH+BIT_WIDTH-1:LUT_BIT_WIDTH];
    
    assign lt1 = mod_x_d < const_1_d ? 1'b1 : 1'b0;
    
    /////pipeline
    always @(posedge clk) begin
        lt1_d <= lt1;
        correction_value_d <= correction_value;
        const_1_d2 <= const_1_d;
        mod_x_d2 <= mod_x_d;
        input_sign_d <= input_sign;
    end
    
    assign out_y  = lt1_d ? mod_x_d2 - correction_value_d : const_1_d2;
    
    always @(posedge clk) begin
        data_out = input_sign_d ? (~out_y + 1'b1) : out_y;
    end
    
    ////LUT
    generate 
    if( TANH_LUT_SIZE == 8 ) begin
        wire [2:0] select;
        assign select = mod_x_d[(BIT_WIDTH-2) -:3];
        always @(*) begin
            case(select)
                3'd0: lut_out = 'b0;
                3'd1: lut_out = 'b0;
                3'd2: lut_out = 'b0;
                3'd3: lut_out = 'b0;
                3'd4: lut_out = 'b0;
                3'd5: lut_out = 'b0;
                3'd6: lut_out = 'b0;
                default: lut_out = 'b0;
            endcase
        end
    end else begin
        wire [3:0] select;
        assign select = mod_x_d[(BIT_WIDTH-2) -:4];
        always @(*) begin
            case(select)
                3'd0: lut_out = 'b0;
                3'd1: lut_out = 'b0;
                3'd2: lut_out = 'b0;
                3'd3: lut_out = 'b0;
                3'd4: lut_out = 'b0;
                3'd5: lut_out = 'b0;
                3'd6: lut_out = 'b0;
                3'd7: lut_out = 'b0;
                3'd8: lut_out = 'b0;
                3'd9: lut_out = 'b0;
                3'd10: lut_out = 'b0;
                3'd11: lut_out = 'b0;
                3'd12: lut_out = 'b0;
                3'd13: lut_out = 'b0;
                3'd15: lut_out = 'b0;
                default: lut_out = 'b0;
            endcase
        end
    end
    endgenerate
endmodule


module tanh_tb();
    wire done;    
    reg [31 : 0]  data_in0;
    reg [31 : 0]   immediate;
    wire [31 : 0]  data_out;
    reg clk,reset;

    always #1 clk = ~clk;

    initial begin
        clk <= 1; reset <= 1'b1; @(posedge clk); @(posedge clk); 
        reset <= 1'b0; immediate <= 16; @(posedge clk); 
        data_in0 <= 58746;
        repeat(5)
            @(posedge clk); 
        $stop();
    end

    tanh dut (
        .clk(clk),
        .reset(reset),
        .data_in(data_in0),
        .immediate(immediate),
        .data_out(data_out)
    );
endmodule