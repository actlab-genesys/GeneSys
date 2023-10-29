module ibuf_data_shuffler #(
    parameter DDR_BANDWIDTH = 512,
    parameter NUM_BANKS     = 8,
    parameter DATA_WIDTH    = 8,
    parameter RATIO = DDR_BANDWIDTH/(NUM_BANKS*DATA_WIDTH)
) (
    input  [DDR_BANDWIDTH - 1 : 0] data_in,
    output [DDR_BANDWIDTH - 1 : 0] data_out
);

    wire [DDR_BANDWIDTH - 1 : 0] data_out_w;
    
    genvar i,j;
    generate;
        for (j=0; j<NUM_BANKS; j=j+1) begin
            wire [RATIO*DATA_WIDTH - 1 : 0] perBankData;
            for (i=0; i<RATIO; i=i+1) begin
                assign perBankData[(i+1) * DATA_WIDTH - 1 : i * DATA_WIDTH] =  data_in[(i * NUM_BANKS * DATA_WIDTH) + ((j+1) * DATA_WIDTH) - 1 : (i * NUM_BANKS * DATA_WIDTH) + (j * DATA_WIDTH)];
            end
        assign data_out_w[((j+1) * DATA_WIDTH * RATIO) - 1 : (j * DATA_WIDTH * RATIO)] = perBankData;
        end
    endgenerate
    assign data_out = data_out_w ;
endmodule