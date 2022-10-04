module syncFlipFlop_Enable #(parameter DATA_WIDTH = 32) (
    input clk,
    input rst_n, 
    input en,
    input [DATA_WIDTH-1:0] D, 
    output reg  [DATA_WIDTH-1:0] Q
    );

    always @(posedge clk) begin
        if (~rst_n)
            Q <= 0;
        else if (en)
            Q <= D;  
    end
endmodule 
