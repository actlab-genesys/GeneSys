module perf_counter_step #(
      //==============================
      // Top level block parameters
      //==============================
      parameter DATA_WIDTH   = 8,                // number of bits in counter
      parameter COUNT_FROM   = 0,                // start with this number   
      parameter COUNT_TO     = 2^(DATA_WIDTH-1)  // value to count to in CL case
   ) (
      //===============
      // Input Ports
      //===============
      input clk,
      input en,
      input rst,
      input [DATA_WIDTH-1:0] step,
      //===============
      // Output Ports
      //===============
      output reg [DATA_WIDTH-1:0] out
   );

   // Synchronous logic
   always @(posedge clk)
   begin
      if (rst)
         out <= 0;
      else begin
         if (en == 1)
            out <= out + step;
      end
   end
endmodule