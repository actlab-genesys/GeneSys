#ifdef CONV_RELU
     std::string instruction_file  = "/home/lavanya/genesys_github/testcases/conv_relu_test/conv_bias_relu1_decimal.txt";
     std::string input_file  = "/home/lavanya/genesys_github/testcases/conv_relu_test/data/data/data_shuffled.txt";
     std::string weight_file  = "/home/lavanya/genesys_github/testcases/conv_relu_test/data/weight/weight_shuffled.txt";
     std::string output_file  = "/home/lavanya/genesys_github/testcases/conv_relu_test/data/out.txt";
     std::string bias_file  = "/home/lavanya/genesys_github/testcases/conv_relu_test/data/bias.txt";
     std::string simd_input_file1   = "/home/lavanya/genesys_github/testcases/conv_relu_test/data/out.txt";
     std::string simd_input_file2   = "/home/lavanya/genesys_github/testcases/conv_relu_test/data/out.txt";
/**************/
#elif CONV_ONLY
     std::string instruction_file  = "/home/lavanya/genesys_github/testcases/resnet50_conv_0/resnet50_custom_conv_decimal.txt";
     std::string input_file  = "/home/lavanya/genesys_github/testcases/resnet50_conv_0/data_shuffled.txt";
     std::string weight_file  = "/home/lavanya/genesys_github/testcases/resnet50_conv_0/weight_shuffled.txt";
     std::string output_file  = "/home/lavanya/genesys_github/testcases/resnet50_conv_0/out.txt";
     std::string bias_file  = "/home/lavanya/genesys_github/testcases/resnet50_conv_0/bias.txt";
     std::string simd_input_file1   = "/home/lavanya/genesys_github/testcases/resnet50_conv_0/out.txt";
     std::string simd_input_file2   = "/home/lavanya/genesys_github/testcases/resnet50_conv_0/out.txt";
/**************/
#elif ADD_ONLY
     std::string instruction_file  = "/home/lavanya/genesys_github/testcases/add_test/add_decimal.txt";
     std::string input_file  = "/home/lavanya/genesys_github/testcases/add_test/data/out.txt";
     std::string weight_file  = "/home/lavanya/genesys_github/testcases/add_test/data/out.txt";
     std::string output_file  = "/home/lavanya/genesys_github/testcases/add_test/data/out.txt";
     std::string bias_file  = "/home/lavanya/genesys_github/testcases/add_test/data/out.txt";
     std::string simd_input_file1   = "/home/lavanya/genesys_github/testcases/add_test/data/op1.txt";
     std::string simd_input_file2   = "/home/lavanya/genesys_github/testcases/add_test/data/op2.txt";
#else 
     std::string instruction_file  = "/home/lavanya/genesys_github/testcases/conv_relu_test/conv_bias_relu1_decimal.txt";
     std::string input_file  = "/home/lavanya/genesys_github/testcases/conv_relu_test/data/data/data_shuffled.txt";
     std::string weight_file  = "/home/lavanya/genesys_github/testcases/conv_relu_test/data/weight/weight_shuffled.txt";
     std::string output_file  = "/home/lavanya/genesys_github/testcases/conv_relu_test/data/out.txt";
     std::string bias_file  = "/home/lavanya/genesys_github/testcases/conv_relu_test/data/bias.txt";
     std::string simd_input_file1   = "/home/lavanya/genesys_github/testcases/conv_relu_test/data/out.txt";
     std::string simd_input_file2   = "/home/lavanya/genesys_github/testcases/conv_relu_test/data/out.txt";
#endif

