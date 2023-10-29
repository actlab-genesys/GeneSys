`timescale 1ns / 1ps

module saturate  #(
    parameter Win  = 16, // input width
    parameter Wout = 14  // output width
)(
    input  [Win-1:0]  din,
    output reg [Wout-1:0] dout
);
    always @(*) begin
        // check if discarded bits all equal the MS retained bit.  
        if ((din[Win-1:Wout-1] == {(Win-Wout+1){1'b1}}) || (din[Win-1:Wout-1]=={(Win-Wout+1){1'b0}})) begin
            // no saturation
            dout = din[Wout-1:0];
        end else begin
            // saturate to most positive or most negative
            if(din[Win-1] == 1'b1)
                dout = {1'b1, {(Wout-1){1'b0}}};
            else
                dout = {1'b0, {(Wout-1){1'b1}}};
        end
    end
   
endmodule
