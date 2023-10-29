`timescale 1ns / 1ps

module oneOverSqrt #(
    parameter BIT_WIDTH      		=	32
)(
    input wire  clk,
    input   reset,
    
    input [BIT_WIDTH-1 : 0] data_in,
    input [31 : 0] immediate,

    output wire [BIT_WIDTH-1 : 0] data_out
    );
    
    wire [5:0] fractional_bits;
    assign  fractional_bits = immediate[5:0];

    // Assume three level of precicion, three look up table
    // 0 - 0.25 --> 2^-8
    // 0.25 - 1 --> 2^-4
    // 1 - 10   --> 2^-1
    wire [BIT_WIDTH-1:0] const_0p25;
    wire [BIT_WIDTH-1:0] const_1,const_10;

    reg [BIT_WIDTH-1:0] yn, yn_d;
    wire [BIT_WIDTH-1:0] out_0, out_1, out_2; // 3 look up table out

    assign const_0p25 = 4'b0001 << (fractional_bits-2);
    assign const_1 = 4'b0001 << fractional_bits;
    assign const_10 = 4'b1010 << fractional_bits;

    reg [BIT_WIDTH-1 : 0] data_in_d;
    
    wire [2:0] select;
    reg [2:0] select_d;

    assign select[0] = data_in_d < const_0p25 ? 1'b1 : 1'b0;
    assign select[1] = data_in_d < const_1 ? 1'b1 : 1'b0;
    assign select[2] = data_in_d < const_10 ? 1'b1 : 1'b0;

    always @(*) begin
        case(select)
            3'b111 : yn = out_0;
            3'b110 : yn = out_1;
            3'b100 : yn = out_2;
            default : yn = 0;
        endcase
    end

    oneOverSqrt_lut0 lut0 (
        .clk(clk),
        .reset(reset),
        .in(data_in),
        .out(out_0)
    );
    
    oneOverSqrt_lut1 lut1 (
        .clk(clk),
        .reset(reset),
        .in(data_in),
        .out(out_1)
    );
    
    oneOverSqrt_lut2 lut2 (
        .clk(clk),
        .reset(reset),
        .in(data_in),
        .out(out_2)
    );

    wire [BIT_WIDTH:0] decimal_start;
    assign decimal_start = fractional_bits + fractional_bits;
    
    /*** First Cycle ***/

    // xyn
    wire signed [2*BIT_WIDTH-1:0]   xyn_temp;
    wire signed [BIT_WIDTH-1:0]     xyn_cropped;
    reg signed [BIT_WIDTH-1:0]      xyn, xyn_d;
    
    assign xyn_temp = data_in_d * yn;
    assign xyn_cropped = xyn_temp[decimal_start-fractional_bits +: BIT_WIDTH]; // Need to decide how to crop

    wire xyn_zeros, xyn_ones;
    assign xyn_zeros = |xyn_cropped[2*BIT_WIDTH-2:BIT_WIDTH-1];
    assign xyn_ones = &xyn_cropped[2*BIT_WIDTH-2:BIT_WIDTH-1];

    always @(*) begin
        case({xyn_cropped[2*BIT_WIDTH-1],xyn_ones,xyn_zeros} )
            3'b001,3'b011 : xyn = {1'b0,{BIT_WIDTH-1{1'b1}}};
            3'b100,3'b101 : xyn = {1'b1,{BIT_WIDTH-1{1'b0}}};
            default : xyn = xyn_cropped[BIT_WIDTH-1:0];
        endcase
    end

    // yn^2
    wire signed [2*BIT_WIDTH-1:0]   yn2_temp;
    wire signed [BIT_WIDTH-1:0]     yn2_cropped;
    reg signed [BIT_WIDTH-1:0]      yn2, yn2_d;
    
    assign yn2_temp = yn * yn;
    assign yn2_cropped = yn2_temp[decimal_start-fractional_bits +: BIT_WIDTH];

    wire yn2_zeros, yn2_ones;
    assign yn2_zeros = |yn2_cropped[2*BIT_WIDTH-2:BIT_WIDTH-1];
    assign yn2_ones = &yn2_cropped[2*BIT_WIDTH-2:BIT_WIDTH-1];

    always @(*) begin
        case({yn2_cropped[2*BIT_WIDTH-1],yn2_ones,yn2_zeros} )
            3'b001,3'b011 : yn2 = {1'b0,{BIT_WIDTH-1{1'b1}}};
            3'b100,3'b101 : yn2 = {1'b1,{BIT_WIDTH-1{1'b0}}};
            default : yn2 = yn2_cropped[BIT_WIDTH-1:0];
        endcase
    end
    
    wire signed [BIT_WIDTH-1:0] ynp5;
    reg signed [BIT_WIDTH-1:0]  ynp5_d;
    assign ynp5 = yn >> 1;

    /*** Second Cycle ***/
    // 1.5yn
    wire signed [BIT_WIDTH-1:0] yn1p5;
    reg signed [BIT_WIDTH-1:0]  yn1p5_d, yn1p5_d2;
    assign yn1p5 = ynp5_d + yn_d;

    // xyn^3
    wire signed [2*BIT_WIDTH-1:0]   xyn3_temp;
    wire signed [BIT_WIDTH-1:0]     xyn3_cropped;
    reg signed [BIT_WIDTH-1:0]      xyn3, xyn3_d;
    
    assign xyn3_temp = yn2_d * xyn_d;
    assign xyn3_cropped = xyn3_temp[decimal_start-fractional_bits +: BIT_WIDTH];

    wire xyn3_zeros, xyn3_ones;
    assign xyn3_zeros = |xyn3_cropped[2*BIT_WIDTH-2:BIT_WIDTH-1];
    assign xyn3_ones = &xyn3_cropped[2*BIT_WIDTH-2:BIT_WIDTH-1];

    always @(*) begin
        case({xyn3_cropped[2*BIT_WIDTH-1],xyn3_ones,xyn3_zeros} )
            3'b001,3'b011 : xyn3 = {1'b0,{BIT_WIDTH-1{1'b1}}};
            3'b100,3'b101 : xyn3 = {1'b1,{BIT_WIDTH-1{1'b0}}};
            default : xyn3 = xyn3_cropped[BIT_WIDTH-1:0];
        endcase
    end

    /*** Third Cycle ***/
    wire signed [BIT_WIDTH-1:0]      xyn3p5;
    reg signed [BIT_WIDTH-1:0]      xyn3p5_d;
    assign xyn3p5 = xyn3_d >> 1;

    /*** Final Cycle ***/
    reg [BIT_WIDTH-1 : 0] data_out_temp;
    assign data_out = data_out_temp;

    always @(posedge clk) begin
        data_in_d <= data_in;
        select_d <= select;

        // first cycle
        ynp5_d <= ynp5;
        yn2_d <= yn2;
        xyn_d <= xyn;
        yn_d <= yn;

        // second cycle
        yn1p5_d <= yn1p5;
        xyn3_d <= xyn3;

        // third cycle
        yn1p5_d2 <= yn1p5_d;
        xyn3p5_d <= xyn3p5;

        // final result
        data_out_temp <= yn1p5_d2 + -(xyn3p5_d);
    end
endmodule
/*
module oneOverSqrt_tb();
    wire done;    
    reg [31 : 0]   data_in0;
    reg [31 : 0]   immediate;
    wire [31 : 0]  data_out;
    reg clk,reset;

    always #1 clk = ~clk;

    reg signed [15:0] integers;
    reg[15:0] fractions;
    //assign data_in0 = {integers, fractions};
    //assign data_in0 = 32'b11111111111100010111010111101000;
    
    integer f;
    integer i;
    integer j = 256*10;
    
    initial begin
        f = $fopen("C:/Users/hax032/Desktop/SIMD_tb_script_hanyang/sqrt_output.txt","w");
        
        clk <= 1; reset <= 1'b1; @(posedge clk); 
        repeat(5)
            @(posedge clk); 
        reset <= 1'b0; immediate <= 16; integers <= 0; @(posedge clk); 
        
        for (i = 1; i <= j; i=i+1) begin
            $display(i);
            data_in0 <= i*256; $fwrite(f,"%d\n",data_out); @(posedge clk);
        end
        
        $fwrite(f,"%d\n",data_out); @(posedge clk);
        $fwrite(f,"%d\n",data_out); @(posedge clk);
        $fwrite(f,"%d\n",data_out); @(posedge clk);
        $fwrite(f,"%d\n",data_out); @(posedge clk);
        $fwrite(f,"%d\n",data_out); @(posedge clk);
        $fwrite(f,"%d\n",data_out); @(posedge clk);
  
        $fclose(f);
        
        $stop();
    end

    oneOverSqrt dut (
        .clk(clk),
        .reset(reset),
        .data_in(data_in0),
        .immediate(immediate),
        .data_out(data_out)
    );

endmodule */
