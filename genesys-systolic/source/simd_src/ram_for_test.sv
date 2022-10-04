`timescale 1ns/1ps
module ram_for_test
#(
  parameter integer DATA_WIDTH    = 32,
  parameter integer ADDR_WIDTH    = 32,
  parameter string  FILE_NAME = "0",
  parameter integer num = 0,
  parameter integer num_elem = 1
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

////////////////
reg  [ DATA_WIDTH -1 : 0 ] mem [ 0:1<<ADDR_WIDTH ];
//reg  [31:0] mem [1023:0];

task load_mem();
    integer file_i,count,data;
    if (FILE_NAME != "0") begin
        file_i = $fopen(FILE_NAME,"r"); 
        count = 0;
        while (! $feof(file_i)) begin 
            $fscanf(file_i,"%d\n",data);
            //@( posedge clk);
            if ( count % num_elem == num ) begin
                mem[count/num_elem] = data;
            end
            count = count + 'd1;
        end 
        $fclose(file_i);
    end
 endtask 
 //////////////////////////
initial begin
    @(posedge clk);
    load_mem();
end

  always @(posedge clk)
  begin: RAM_WRITE
    if (write_req)
      mem[write_addr] <= write_data;
  end

  reg [DATA_WIDTH-1:0] read_data_q;
  always @(posedge clk)
  begin
    if (reset)
      read_data_q <= 0;
    else if (read_req)
      read_data_q <= mem[read_addr];
  end
  assign read_data = read_data_q;

endmodule
