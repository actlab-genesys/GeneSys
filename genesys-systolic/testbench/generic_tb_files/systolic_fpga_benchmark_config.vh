`define ADD_ONLY

    bit [31:0] instruction_base_addr    = 32'd67108864;

`ifdef CONV_RELU


    bit [31:0] num_instruction_bytes               = 32'd992; // num_instr * 4
    bit [63:0] axi00_imem_addr                     = 67108864; // does not matter as Innstructions as written using config reg
    bit [63:0] axi03_obuf_addr                     = 542003200;
                                                     
    bit [63:0] axi01_parambuf_addr                 = 67133440;
    bit [63:0] axi02_ibuf_addr                     = 71368704;
    bit [63:0] axi04_bias_addr                     = 67112960;
    bit [63:0] axi04_simd_addr                     = 0;

    integer config_stride                          = 1048576; // high stride = 0 & Low stride = 4096
    integer config_input_num_tiles                 = 1;
    integer config_bias_num_tiles                  = 4;
    integer config_weight_num_tiles                = 4;
    integer config_output_num_tiles                = 4;  
    integer config_input_tile_size_32B_cnt         = 128;
    integer config_bias_tile_size_32B_cnt          = 256;
    integer config_weight_tile_size_32B_cnt        = 32768;
    integer config_output_tile_size_32B_cnt        = 256;
    
    bit last_layer_obuf                            = 0;
      

    integer instr_filep   = $fopen("/home/lavanya/genesys_github/testcases/conv_relu_test/conv_bias_relu1_decimal.txt","r"); 
    integer instr_filep1  = $fopen("/home/lavanya/genesys_github/testcases/conv_relu_test/conv_bias_relu1_decimal.txt","r"); 

    integer output_filep  = $fopen("/home/lavanya/genesys_github/testcases/conv_relu_test/data/out.txt","r");
    integer output_filep1 = $fopen("/home/lavanya/genesys_github/testcases/conv_relu_test/data/out.txt","r");
    integer output_filep2 = $fopen("/home/lavanya/genesys_github/testcases/conv_relu_test/data/out.txt","r");

    integer input_filep   = $fopen("/home/lavanya/genesys_github/testcases/conv_relu_test/data/data/data_shuffled.txt","r");
    integer input_filep1  = $fopen("/home/lavanya/genesys_github/testcases/conv_relu_test/data/data/data_shuffled.txt","r");

    integer params_filep  = $fopen("/home/lavanya/genesys_github/testcases/conv_relu_test/data/weight/weight_shuffled.txt","r"); 
    integer params_filep1 = $fopen("/home/lavanya/genesys_github/testcases/conv_relu_test/data/weight/weight_shuffled.txt","r"); 

    integer bias_filep    = $fopen("/home/lavanya/genesys_github/testcases/conv_relu_test/data/bias.txt","r"); 
    integer bias_filep1   = $fopen("/home/lavanya/genesys_github/testcases/conv_relu_test/data/bias.txt","r"); 
    
    integer simd_file1    = $fopen("/home/lavanya/genesys_github/testcases/conv_relu_test/data/out.txt","r");
    integer simd_file2    = $fopen("/home/lavanya/genesys_github/testcases/conv_relu_test/data/out.txt","r");

    
`elsif CONV_ONLY

    bit [31:0] num_instruction_bytes               = 32'd880; // num_instr * 4
    bit [63:0] axi00_imem_addr                     = 67108864; // does not matter as Innstructions as written using config reg
    bit [63:0] axi03_obuf_addr                     = 542003200;
                                                     
    bit [63:0] axi01_parambuf_addr                 = 67133440;
    bit [63:0] axi02_ibuf_addr                     = 71368704;
    bit [63:0] axi04_bias_addr                     = 67112960;
    bit [63:0] axi04_simd_addr                     = 0;

    integer config_stride                          = 1048576; // high stride = 0 & Low stride = 4096
    integer config_input_num_tiles                 = 1;
    integer config_bias_num_tiles                  = 4;
    integer config_weight_num_tiles                = 4;
    integer config_output_num_tiles                = 4;  
    integer config_input_tile_size_32B_cnt         = 128;
    integer config_bias_tile_size_32B_cnt          = 256;
    integer config_weight_tile_size_32B_cnt        = 32768;
    integer config_output_tile_size_32B_cnt        = 256;
    
    bit last_layer_obuf                            = 1;
      

    integer instr_filep   = $fopen("/home/lavanya/genesys_github/testcases/resnet50_conv_0/resnet50_custom_conv_decimal.txt","r"); 
    integer instr_filep1  = $fopen("/home/lavanya/genesys_github/testcases/resnet50_conv_0/resnet50_custom_conv_decimal.txt","r"); 

    integer output_filep  = $fopen("/home/lavanya/genesys_github/testcases/resnet50_conv_0/out.txt","r");
    integer output_filep1 = $fopen("/home/lavanya/genesys_github/testcases/resnet50_conv_0/out.txt","r");
    integer output_filep2 = $fopen("/home/lavanya/genesys_github/testcases/resnet50_conv_0/out.txt","r");

    integer input_filep   = $fopen("/home/lavanya/genesys_github/testcases/resnet50_conv_0/data_shuffled.txt","r");
    integer input_filep1  = $fopen("/home/lavanya/genesys_github/testcases/resnet50_conv_0/data_shuffled.txt","r");

    integer params_filep  = $fopen("/home/lavanya/genesys_github/testcases/resnet50_conv_0/weight_shuffled.txt","r"); 
    integer params_filep1 = $fopen("/home/lavanya/genesys_github/testcases/resnet50_conv_0/weight_shuffled.txt","r"); 

    integer bias_filep    = $fopen("/home/lavanya/genesys_github/testcases/resnet50_conv_0/bias.txt","r"); 
    integer bias_filep1   = $fopen("/home/lavanya/genesys_github/testcases/resnet50_conv_0/bias.txt","r"); 
    
    integer simd_file1    = $fopen("/home/lavanya/genesys_github/testcases/resnet50_conv_0/out.txt","r");
    integer simd_file2    = $fopen("/home/lavanya/genesys_github/testcases/resnet50_conv_0/out.txt","r");

`elsif ADD_ONLY

    
    bit [31:0] num_instruction_bytes               = 32'd880; // num_instr * 4
    bit [63:0] axi00_imem_addr                     = 67108864; // does not matter as Innstructions as written using config reg
    bit [63:0] axi03_obuf_addr                     = 542003200;
                                                     
    bit [63:0] axi01_parambuf_addr                 = 67133440;
    bit [63:0] axi02_ibuf_addr                     = 71368704;
    bit [63:0] axi04_bias_addr                     = 67112960;
    bit [63:0] axi04_simd_addr                     = 0;

    integer config_stride                          = 1048576; // high stride = 0 & Low stride = 4096
    integer config_input_num_tiles                 = 1;
    integer config_bias_num_tiles                  = 4;
    integer config_weight_num_tiles                = 4;
    integer config_output_num_tiles                = 4;  
    integer config_input_tile_size_32B_cnt         = 128;
    integer config_bias_tile_size_32B_cnt          = 256;
    integer config_weight_tile_size_32B_cnt        = 32768;
    integer config_output_tile_size_32B_cnt        = 256;
    
    bit last_layer_obuf                            = 0;
      
    
    integer instr_filep   = $fopen("/home/lavanya/genesys_github/testcases/add_test/add_decimal.txt","r"); 
    integer instr_filep1  = $fopen("/home/lavanya/genesys_github/testcases/add_test/add_decimal.txt","r"); 

    integer output_filep  = $fopen("/home/lavanya/genesys_github/testcases/add_test/data/out.txt","r");
    integer output_filep1 = $fopen("/home/lavanya/genesys_github/testcases/add_test/data/out.txt","r");
    integer output_filep2 = $fopen("/home/lavanya/genesys_github/testcases/add_test/data/out.txt","r");

    integer input_filep   = $fopen("/home/lavanya/genesys_github/testcases/add_test/data/out.txt","r");
    integer input_filep1  = $fopen("/home/lavanya/genesys_github/testcases/add_test/data/out.txt","r");

    integer params_filep  = $fopen("/home/lavanya/genesys_github/testcases/add_test/data/out.txt","r"); 
    integer params_filep1 = $fopen("/home/lavanya/genesys_github/testcases/add_test/data/out.txt","r"); 

    integer bias_filep    = $fopen("/home/lavanya/genesys_github/testcases/add_test/data/out.txt","r"); 
    integer bias_filep1   = $fopen("/home/lavanya/genesys_github/testcases/add_test/data/out.txt","r"); 
    
    integer simd_file1    = $fopen("/home/lavanya/genesys_github/testcases/add_test/data/op1.txt","r");
    integer simd_file2    = $fopen("/home/lavanya/genesys_github/testcases/add_test/data/op2.txt","r");

    
  



`endif
