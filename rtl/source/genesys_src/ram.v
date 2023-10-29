`timescale 1ns/1ps
module ram
#(
  parameter integer DATA_WIDTH    = 10,
  parameter integer ADDR_WIDTH    = 12
)
(
  input  wire                         clk,
  input  wire                         reset,

  input  wire                         read_req,
  input  wire [ ADDR_WIDTH  -1 : 0 ]  read_addr,
  output wire [ DATA_WIDTH  -1 : 0 ]  read_data,

  input  wire                         write_req,
  input  wire [ ADDR_WIDTH  -1 : 0 ]  write_addr,
  input  wire [ DATA_WIDTH  -1 : 0 ]  write_data
);

  reg  [ DATA_WIDTH -1 : 0 ] mem [ 0 : 1<<ADDR_WIDTH ];

  always @(posedge clk)
  begin: RAM_WRITE
    if (write_req)
      mem[write_addr] <= write_data;
  end



  reg [DATA_WIDTH-1:0] read_data_q;
  always @(posedge clk)
  begin
    if (reset)
      read_data_q <= {DATA_WIDTH{1'b1}};
    else if (read_req)
      read_data_q <= mem[read_addr];
  end
  assign read_data = read_data_q;

endmodule
