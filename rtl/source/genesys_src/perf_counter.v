module perf_counter #(
      //==============================
      // Top level block parameters
      //==============================
      parameter DATA_WIDTH   = 8,                // number of bits in counter
      parameter COUNT_FROM   = 0,                // start with this number   
      parameter COUNT_TO     = 2^(DATA_WIDTH-1), // value to count to in CL case
      parameter STEP         = 1'b1,                // negative or positive, sets direction
      parameter STEP_BITWIDTH = 32
   ) (
      //===============
      // Input Ports
      //===============
      input clk,
      input en,
      input rst,
      input [STEP_BITWIDTH-1:0] step,
      
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
         if (en == 1) begin
            if (~STEP) 
                out <= out + step ;
            else 
                out <= out + STEP;
         end
      end
   end
endmodule