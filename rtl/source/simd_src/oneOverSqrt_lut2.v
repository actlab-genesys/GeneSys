`timescale 1ns / 1ps 
 
module oneOverSqrt_lut2 #(
   BIT_WIDTH = 32,
   LUT_BIT_WIDTH = 17,
   SECLECT_START_WIDTH = 15
)(
   input clk,
   input reset,
   input [BIT_WIDTH-1:0] in,
   output [BIT_WIDTH-1:0] out
);

wire [LUT_BIT_WIDTH-1:0] select; 
reg  [BIT_WIDTH-1:0] output_comb; 
assign select = in[BIT_WIDTH-1:SECLECT_START_WIDTH];
assign out = output_comb;

always @(posedge clk) begin
   case(select)
      17'd2: output_comb <= 65536;
      17'd3: output_comb <= 53509;
      17'd4: output_comb <= 46340;
      17'd5: output_comb <= 41448;
      17'd6: output_comb <= 37837;
      17'd7: output_comb <= 35030;
      17'd8: output_comb <= 32768;
      17'd9: output_comb <= 30893;
      17'd10: output_comb <= 29308;
      17'd11: output_comb <= 27944;
      17'd12: output_comb <= 26754;
      17'd13: output_comb <= 25705;
      17'd14: output_comb <= 24770;
      17'd15: output_comb <= 23930;
      17'd16: output_comb <= 23170;
      17'd17: output_comb <= 22478;
      17'd18: output_comb <= 21845;
      17'd19: output_comb <= 21262;
      default: output_comb <= 0;
   endcase
end
endmodule
