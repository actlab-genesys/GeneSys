`timescale 1ns/1ps
module ram_asymmetric
#(
  parameter integer DATA_WIDTH    = 10,
  parameter integer ADDR_WIDTH_IN    = 10,
  parameter integer ADDR_WIDTH_OUT   = 12,
  parameter integer BITWIDTH_RATIO   = 4,
  parameter integer OUTPUT_REG    = 0
)
(
  input  wire                         clk,
  input  wire                         reset,

  input  wire                         s_read_req,
  input  wire [ ADDR_WIDTH_OUT  -1 : 0 ]  s_read_addr,
  output wire [ DATA_WIDTH  -1 : 0 ]  s_read_data,

  input  wire                         s_write_req,
  input  wire [ ADDR_WIDTH_IN  -1 : 0 ]  s_write_addr,
  input  wire [ BITWIDTH_RATIO*DATA_WIDTH  -1 : 0 ]  s_write_data
);

  reg  [ BITWIDTH_RATIO*DATA_WIDTH -1 : 0 ] mem [ 0 : 1<<ADDR_WIDTH_IN ];
  wire [ BITWIDTH_RATIO*DATA_WIDTH  -1 : 0 ]  s_read_data_w;
  wire [ DATA_WIDTH  -1 : 0 ]  s_read_data_r[0:BITWIDTH_RATIO-1];
   
  always @(posedge clk)
  begin: RAM_WRITE
    if (s_write_req)
      mem[s_write_addr] <= s_write_data;
  end
	
  assign s_read_data_w = mem[s_read_addr[ADDR_WIDTH_OUT-1:ADDR_WIDTH_OUT-ADDR_WIDTH_IN]];
  generate
	for(genvar i=0; i < BITWIDTH_RATIO; i = i+1) begin
		assign s_read_data_r[i] = s_read_data_w[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH];
	end
  endgenerate
  generate
    if (OUTPUT_REG == 0)
      assign s_read_data = s_read_data_r[s_read_addr[ADDR_WIDTH_OUT-ADDR_WIDTH_IN-1:0]];
    else begin
      reg [DATA_WIDTH-1:0] _s_read_data;
      always @(posedge clk)
      begin
        if (reset)
          _s_read_data <= 0;
        else if (s_read_req)
          _s_read_data <= s_read_data_r[s_read_addr[ADDR_WIDTH_OUT-ADDR_WIDTH_IN-1:0]];
      end
      assign s_read_data = _s_read_data;
    end
  endgenerate
endmodule
