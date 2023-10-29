// Project F Library - Division (Fixed-Point)
// (C)2021 Will Green, Open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module div #(
    parameter WIDTH=4,  // width of numbers in bits
    parameter FBITS=0   // fractional bits (for fixed point)
    ) (
    input wire logic clk,
    input wire logic start,          // start signal
    output     logic busy,           // calculation in progress
    output     logic valid,          // quotient and remainder are valid
    output     logic dbz,            // divide by zero flag
    output     logic ovf,            // overflow flag (fixed-point)
    input wire logic [WIDTH-1:0] x,  // dividend
    input wire logic [WIDTH-1:0] y,  // divisor
    output     logic [WIDTH-1:0] q,  // quotient
    output     logic [WIDTH-1:0] r   // remainder
    );

    // avoid negative vector width when fractional bits are not used
    localparam FBITSW = (FBITS) ? FBITS : 1;

    logic [WIDTH-1:0] y1;           // copy of divisor
    logic [WIDTH-1:0] q1, q1_next;  // intermediate quotient
    logic [WIDTH:0] ac, ac_next;    // accumulator (1 bit wider)

    localparam ITER = WIDTH+FBITS;  // iterations are dividend width + fractional bits
    logic [$clog2(ITER)-1:0] i;     // iteration counter

    always_comb begin
        if (ac >= {1'b0,y1}) begin
            ac_next = ac - y1;
            {ac_next, q1_next} = {ac_next[WIDTH-1:0], q1, 1'b1};
        end else begin
            {ac_next, q1_next} = {ac, q1} << 1;
        end
    end

    always_ff @(posedge clk) begin
        if (start) begin
            valid <= 0;
            ovf <= 0;
            i <= 0;
            if (y == 0) begin  // catch divide by zero
                busy <= 0;
                dbz <= 1;
            end else begin
                busy <= 1;
                dbz <= 0;
                y1 <= y;
                {ac, q1} <= {{WIDTH{1'b0}}, x, 1'b0};
            end
        end else if (busy) begin
            if (i == ITER-1) begin  // done
                busy <= 0;
                valid <= 1;
                q <= q1_next;
                r <= ac_next[WIDTH:1];  // undo final shift
            end else if (i == WIDTH-1 && q1_next[WIDTH-1:WIDTH-FBITSW]) begin // overflow?
                busy <= 0;
                ovf <= 1;
                q <= 0;
                r <= 0;
            end else begin  // next iteration
                i <= i + 1;
                ac <= ac_next;
                q1 <= q1_next;
            end
        end
    end
endmodule

/*
module div_tb();
    parameter CLK_PERIOD = 10;  // 10 ns == 100 MHz
    parameter WIDTH = 8;
    parameter FBITS = 4;
    parameter SF = 2.0**-4.0;  // Q4.4 scaling factor is 2^-4

    logic clk;
    logic start;            // start signal
    logic busy;             // calculation in progress
    logic valid;            // quotient and remainder are valid
    logic dbz;              // divide by zero flag
    logic ovf;              // overflow flag (fixed-point only)
    logic [WIDTH-1:0] x;    // dividend
    logic [WIDTH-1:0] y;    // divisor
    logic [WIDTH-1:0] q;    // quotient
    logic [WIDTH-1:0] r;    // remainder

    div #(.WIDTH(WIDTH), .FBITS(FBITS)) div_inst (.*);

    always #(CLK_PERIOD / 2) clk = ~clk;

    initial begin
        $monitor("\t%d:\t%f / %f = %b (%f) (r = %b) (V=%b) (DBZ=%b) (OVF=%b)",
            $time, x*SF, y*SF, q, q*SF, r, valid, dbz, ovf);
    end

    initial begin
                clk = 1;

        #100    x = 8'b0011_0000;  // 3.0
                y = 8'b0010_0000;  // 2.0
                start = 1;
        #10     start = 0;

        #120    x = 8'b0010_0000;  // 2.0
                y = 8'b0001_0110;  // 1.375 (the largest number that's ≤√2 in Q4.4)
                start = 1;
        #10     start = 0;

        #120    x = 8'b0010_0000;  // 2.0
                y = 8'b0000_0000;  // 0.0
                start = 1;
        #10     start = 0;

        #120    x = 8'b0000_0000;  // 0.0
                y = 8'b0010_0000;  // 2.0
                start = 1;
        #10     start = 0;

        #120    x = 8'b0000_0010;  // 0.125
                y = 8'b0010_0000;  // 2.0
                start = 1;
        #10     start = 0;

        #120    x = 8'b1000_0000;  // 8.0
                y = 8'b0000_0100;  // 0.25
                start = 1;
        #10     start = 0;

        #120    x = 8'b1111_1110;  // 15.875
                y = 8'b0010_0000;  // 2.0
                start = 1;
        #10     start = 0;

        #120    x = 8'b1000_0000;  // 8.0
                y = 8'b1001_0000;  // 9.0
                start = 1;
        #10     start = 0;

        // ...
    end
endmodule */