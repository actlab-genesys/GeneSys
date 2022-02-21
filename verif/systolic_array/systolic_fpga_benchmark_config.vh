//`define RESNET50_GEMM

    bit [31:0] instruction_base_addr    = 32'd67108864;

`ifdef RESNET50_GEMM
 
    bit [31:0] num_instruction_bytes               = 32'd880; // num_instr * 4
    bit [63:0] axi00_imem_addr                     = 67108864; // does not matter as Innstructions as written using config reg
    bit [63:0] axi03_obuf_addr                     = 542003200;
                                                     
    bit [63:0] axi01_parambuf_addr                 = 67133440;
    bit [63:0] axi02_ibuf_addr                     = 71368704;
    bit [63:0] axi04_bias_addr                     = 67112960;

    integer config_stride                          = 1048576; // high stride = 0 & Low stride = 4096
    integer config_input_num_tiles                 = 1;
    integer config_bias_num_tiles                  = 4;
    integer config_weight_num_tiles                = 4;
    integer config_output_num_tiles                = 4;  
    integer config_input_tile_size_32B_cnt         = 128;
    integer config_bias_tile_size_32B_cnt          = 256;
    integer config_weight_tile_size_32B_cnt        = 32768;
    integer config_output_tile_size_32B_cnt        = 256;

    integer instr_filep   = $fopen("verif/systolic_array/resnet50_gemm/fpga_8x8_tile4_case0_gemm_decimal.txt.txt","r"); 
    integer instr_filep1  = $fopen("verif/systolic_array/resnet50_gemm/fpga_8x8_tile4_case0_gemm_decimal.txt.txt","r"); 

    integer output_filep  = $fopen("verif/systolic_array/resnet50_gemm/out.txt","r");
    integer output_filep1 = $fopen("verif/systolic_array/resnet50_gemm/out.txt","r");
    integer output_filep2 = $fopen("verif/systolic_array/resnet50_gemm/out.txt","r");

    integer input_filep   = $fopen("verif/systolic_array/resnet50_gemm/data_shuffled.txt","r");
    integer input_filep1  = $fopen("verif/systolic_array/resnet50_gemm/data_shuffled.txt","r");

    integer params_filep  = $fopen("verif/systolic_array/resnet50_gemm/weight_shuffled.txt","r"); 
    integer params_filep1 = $fopen("verif/systolic_array/resnet50_gemm/weight_shuffled.txt","r"); 

    integer bias_filep    = $fopen("verif/systolic_array/resnet50_gemm/bias.txt","r"); 
    integer bias_filep1   = $fopen("verif/systolic_array/resnet50_gemm/bias.txt","r"); 


`else
 
    bit [31:0] num_instruction_bytes               = 32'd880; // num_instr * 4
    bit [63:0] axi00_imem_addr                     = 67108864; // does not matter as Innstructions as written using config reg
    bit [63:0] axi03_obuf_addr                     = 542003200;
                                                     
    bit [63:0] axi01_parambuf_addr                 = 67133440;
    bit [63:0] axi02_ibuf_addr                     = 71368704;
    bit [63:0] axi04_bias_addr                     = 67112960;

    integer config_stride                          = 1048576; // high stride = 0 & Low stride = 4096
    integer config_input_num_tiles                 = 1;
    integer config_bias_num_tiles                  = 4;
    integer config_weight_num_tiles                = 4;
    integer config_output_num_tiles                = 4;  
    integer config_input_tile_size_32B_cnt         = 128;
    integer config_bias_tile_size_32B_cnt          = 256;
    integer config_weight_tile_size_32B_cnt        = 32768;
    integer config_output_tile_size_32B_cnt        = 256;

    integer instr_filep   = $fopen("verif/systolic_array/resnet50_conv/fpga_8x8_tile3_case0_oc_oh_ow_conv_decimal.txt.txt","r"); 
    integer instr_filep1  = $fopen("verif/systolic_array/resnet50_conv/fpga_8x8_tile3_case0_oc_oh_ow_conv_decimal.txt.txt","r"); 

    integer output_filep  = $fopen("verif/systolic_array/resnet50_conv/out.txt","r");
    integer output_filep1 = $fopen("verif/systolic_array/resnet50_conv/out.txt","r");
    integer output_filep2 = $fopen("verif/systolic_array/resnet50_conv/out.txt","r");

    integer input_filep   = $fopen("verif/systolic_array/resnet50_conv/data_shuffled.txt","r");
    integer input_filep1  = $fopen("verif/systolic_array/resnet50_conv/data_shuffled.txt","r");

    integer params_filep  = $fopen("verif/systolic_array/resnet50_conv/weight_shuffled.txt","r"); 
    integer params_filep1 = $fopen("verif/systolic_array/resnet50_conv/weight_shuffled.txt","r"); 

    integer bias_filep    = $fopen("verif/systolic_array/resnet50_conv/bias.txt","r"); 
    integer bias_filep1   = $fopen("verif/systolic_array/resnet50_conv/bias.txt","r"); 
    
`endif
