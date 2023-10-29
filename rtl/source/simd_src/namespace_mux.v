`timescale 1ns / 1ps

module namespace_mux #(
    parameter DATA_WIDTH = 32
)(
    input [DATA_WIDTH-1:0]  obuf_data,    
    input [DATA_WIDTH-1:0]  ibuf_data,    
    input [DATA_WIDTH-1:0]  vmem_data1,    
    input [DATA_WIDTH-1:0]  vmem_data2,    
    input [DATA_WIDTH-1:0]  imm_data,    
    input [DATA_WIDTH-1:0]  ext_data,  
    
    input [2:0] data_sel,
    
    output  reg [DATA_WIDTH-1:0]  data_out
    );
    
    always @(*) begin
        case(data_sel)
            3'b000: data_out = obuf_data;
            3'b001: data_out = ibuf_data;
            3'b010: data_out = vmem_data1;
            3'b011: data_out = vmem_data2;
            3'b100: data_out = imm_data;
            default: data_out = obuf_data;
        endcase
    end
endmodule
