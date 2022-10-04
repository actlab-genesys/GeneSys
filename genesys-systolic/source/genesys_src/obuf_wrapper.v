`timescale 1ns/1ps
module obuf_wrapper #(
  parameter integer NUM_TAGS                            = 2,  // Log number of banks
  parameter integer TAG_W                               = $clog2(NUM_TAGS),
  parameter integer ARRAY_M                             = 16,
  parameter integer OBUF_DDR_BANDWIDTH                  = 512,
  parameter integer OBUF_DATA_WIDTH                     = 8,
  parameter integer OBUF_READ_WIDTH                     = 64,
  parameter integer OBUF_BUFFER_DEPTH                   = 64,
  parameter integer OBUF_READ_LATENCY_B                 = 1,
  parameter integer OBUF_WRITE_WIDTH                    = 8,
  parameter integer OBUF_MEMORY_SIZE                    = 1024,
  parameter integer OBUF_WRITE_ADDR_WIDTH               = 8,  
  parameter integer OBUF_READ_ADDR_WIDTH                = 8
)
(
  input  wire                                            clk,
  input  wire                                            reset,

  input  wire  [ NUM_TAGS*ARRAY_M                      -1 : 0 ]             bs_read_req,
  input  wire  [ NUM_TAGS*ARRAY_M*OBUF_READ_ADDR_WIDTH         -1 : 0 ]     bs_read_addr,
  output wire  [ NUM_TAGS*ARRAY_M*OBUF_READ_WIDTH         -1 : 0 ]          bs_read_data,
  
  input  wire  [ NUM_TAGS*ARRAY_M                      -1 : 0 ]             bs_write_req,
  input  wire  [ NUM_TAGS*ARRAY_M*OBUF_WRITE_ADDR_WIDTH         -1 : 0 ]    bs_write_addr,
  input  wire  [ NUM_TAGS*ARRAY_M*OBUF_WRITE_WIDTH        -1 : 0 ]          bs_write_data
);

  genvar n;
  generate
      for (n=0; n<NUM_TAGS; n=n+1) begin
          obuf #(
                .DDR_BANDWIDTH    (OBUF_DDR_BANDWIDTH   ),
                .NUM_BANKS        (ARRAY_M              ),
                .DATA_WIDTH       (OBUF_DATA_WIDTH      ),
                .READ_WIDTH       (OBUF_READ_WIDTH      ),
                .BUFFER_DEPTH     (OBUF_BUFFER_DEPTH    ),
                .READ_LATENCY_B   (OBUF_READ_LATENCY_B  ),
                .WRITE_WIDTH      (OBUF_WRITE_WIDTH     ),
                .MEMORY_SIZE      (OBUF_MEMORY_SIZE     ),
                .WRITE_ADDR_WIDTH (OBUF_WRITE_ADDR_WIDTH),
                .READ_ADDR_WIDTH  (OBUF_READ_ADDR_WIDTH )
          ) obuf_tag_inst
          (
              .clk                   (clk),
              .reset                 (reset),
              .bs_read_req           (bs_read_req[(n+1)*ARRAY_M-1:n*ARRAY_M]),
              .bs_read_addr          (bs_read_addr[(n+1)*ARRAY_M*OBUF_READ_ADDR_WIDTH-1:n*ARRAY_M*OBUF_READ_ADDR_WIDTH]),
              .bs_read_data          (bs_read_data[(n+1)*ARRAY_M*OBUF_READ_WIDTH-1:n*ARRAY_M*OBUF_READ_WIDTH]),
              .bs_write_req          (bs_write_req[(n+1)*ARRAY_M-1:n*ARRAY_M]),
              .bs_write_addr         (bs_write_addr[(n+1)*ARRAY_M*OBUF_WRITE_ADDR_WIDTH-1:n*ARRAY_M*OBUF_WRITE_ADDR_WIDTH]),
              .bs_write_data         (bs_write_data[(n+1)*ARRAY_M*OBUF_WRITE_WIDTH-1:n*ARRAY_M*OBUF_WRITE_WIDTH])
          );
    


      end
  endgenerate
  
// ila_0 simd_ila (
//  .clk(clk),
//  // 1 bit width
//  .probe0(bs_read_req[0]),
//  //8 bit width
//  .probe1(bs_read_addr[7:0])
  
//  );
  
endmodule
