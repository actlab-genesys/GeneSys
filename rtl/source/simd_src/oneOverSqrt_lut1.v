`timescale 1ns / 1ps 
 
module oneOverSqrt_lut1 #(
   BIT_WIDTH = 32,
   LUT_BIT_WIDTH = 20,
   SECLECT_START_WIDTH = 12
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
      20'd4: output_comb <= 131072;
      20'd5: output_comb <= 117234;
      20'd6: output_comb <= 107019;
      20'd7: output_comb <= 99081;
      20'd8: output_comb <= 92681;
      20'd9: output_comb <= 87381;
      20'd10: output_comb <= 82897;
      20'd11: output_comb <= 79039;
      20'd12: output_comb <= 75674;
      20'd13: output_comb <= 72705;
      20'd14: output_comb <= 70060;
      20'd15: output_comb <= 67685;
      default: output_comb <= 0;
   endcase
end
endmodule
