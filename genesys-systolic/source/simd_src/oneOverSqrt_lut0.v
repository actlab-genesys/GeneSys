`timescale 1ns / 1ps 
 
module oneOverSqrt_lut0 #(
   BIT_WIDTH = 32,
   LUT_BIT_WIDTH = 24,
   SECLECT_START_WIDTH = 8
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
      24'd1: output_comb <= 1048576;
      24'd2: output_comb <= 741455;
      24'd3: output_comb <= 605395;
      24'd4: output_comb <= 524288;
      24'd5: output_comb <= 468937;
      24'd6: output_comb <= 428079;
      24'd7: output_comb <= 396324;
      24'd8: output_comb <= 370727;
      24'd9: output_comb <= 349525;
      24'd10: output_comb <= 331588;
      24'd11: output_comb <= 316157;
      24'd12: output_comb <= 302697;
      24'd13: output_comb <= 290822;
      24'd14: output_comb <= 280243;
      24'd15: output_comb <= 270741;
      24'd16: output_comb <= 262144;
      24'd17: output_comb <= 254317;
      24'd18: output_comb <= 247151;
      24'd19: output_comb <= 240559;
      24'd20: output_comb <= 234468;
      24'd21: output_comb <= 228818;
      24'd22: output_comb <= 223557;
      24'd23: output_comb <= 218643;
      24'd24: output_comb <= 214039;
      24'd25: output_comb <= 209715;
      24'd26: output_comb <= 205642;
      24'd27: output_comb <= 201798;
      24'd28: output_comb <= 198162;
      24'd29: output_comb <= 194715;
      24'd30: output_comb <= 191442;
      24'd31: output_comb <= 188329;
      24'd32: output_comb <= 185363;
      24'd33: output_comb <= 182533;
      24'd34: output_comb <= 179829;
      24'd35: output_comb <= 177241;
      24'd36: output_comb <= 174762;
      24'd37: output_comb <= 172384;
      24'd38: output_comb <= 170101;
      24'd39: output_comb <= 167906;
      24'd40: output_comb <= 165794;
      24'd41: output_comb <= 163760;
      24'd42: output_comb <= 161798;
      24'd43: output_comb <= 159906;
      24'd44: output_comb <= 158078;
      24'd45: output_comb <= 156312;
      24'd46: output_comb <= 154604;
      24'd47: output_comb <= 152950;
      24'd48: output_comb <= 151348;
      24'd49: output_comb <= 149796;
      24'd50: output_comb <= 148291;
      24'd51: output_comb <= 146830;
      24'd52: output_comb <= 145411;
      24'd53: output_comb <= 144032;
      24'd54: output_comb <= 142693;
      24'd55: output_comb <= 141389;
      24'd56: output_comb <= 140121;
      24'd57: output_comb <= 138887;
      24'd58: output_comb <= 137684;
      24'd59: output_comb <= 136512;
      24'd60: output_comb <= 135370;
      24'd61: output_comb <= 134256;
      24'd62: output_comb <= 133169;
      24'd63: output_comb <= 132108;
      default: output_comb <= 0;
   endcase
end
endmodule
