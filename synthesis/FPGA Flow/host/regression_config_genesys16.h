#ifdef FPGA_resnet50_gemm57_standalone
std::string instruction_file  = REPO_PATH+"/resnet50_benchmark16x16_endtoend/layer56_gemm57/gemm57_decimal.txt";
std::string output_file  = REPO_PATH+"/resnet50_benchmark16x16_endtoend/layer56_gemm57/data/output.txt";
std::string bias_file  = REPO_PATH+"/resnet50_benchmark16x16_endtoend/layer56_gemm57/data/fc.bias.txt";
std::string weight_file  = REPO_PATH+"/resnet50_benchmark16x16_endtoend/layer56_gemm57/data/fc.weight/fc.weight_shuffled.txt";
std::string input_file  = REPO_PATH+"/resnet50_benchmark16x16_endtoend/layer56_gemm57/data/flatten_120_494Y/flatten_120_494Y_shuffled.txt";
std::string simd_input_file1 = "";
std::string simd_input_file2 = "";

#define ADDR_OFFSET_INPUT 26619904
#define ADDR_OFFSET_WEIGHT 10403840
#define ADDR_OFFSET_BIAS 6160384
#define MAX_OFFSET 26619904
#define ADDR_OFFSET_OUTPUT 26210304
#define ADDR_OFFSET_VMEM1 0
#define ADDR_OFFSET_VMEM2 0
#define ADDR_OFFSET_VMEM1_LD 0
#define ADDR_OFFSET_VMEM2_LD 0
#define NUM_INSTRUCTION 600 // this has to be in bytes as it is used by hardware. Or change hardware
#define NUM_INPUT 2048
#define NUM_WEIGHT 2097152
#define NUM_BIAS 1024
#define NUM_OUTPUT 1024

#elif FPGA_resnet50_gemm57_quant
std::string instruction_file  = REPO_PATH+"/resnet50_benchmark16x16_endtoend_quant0/layer56_gemm57/gemm57_decimal.txt";
std::string output_file  = REPO_PATH+"/resnet50_benchmark16x16_endtoend_quant0/layer56_gemm57/data/output.txt";
std::string bias_file  = REPO_PATH+"/resnet50_benchmark16x16_endtoend_quant0/layer56_gemm57/data/fc.bias.txt";
std::string weight_file  = REPO_PATH+"/resnet50_benchmark16x16_endtoend_quant0/layer56_gemm57/data/fc.weight/fc.weight_shuffled.txt";
std::string input_file  = REPO_PATH+"/resnet50_benchmark16x16_endtoend_quant0/layer56_gemm57/data/flatten_120_494Y/flatten_120_494Y_shuffled.txt";
std::string simd_input_file1 = "";
std::string simd_input_file2 = "";

#define ADDR_OFFSET_INPUT 26619904
#define ADDR_OFFSET_WEIGHT 17031168
#define ADDR_OFFSET_BIAS 8740864
#define MAX_OFFSET 26619904
#define ADDR_OFFSET_OUTPUT 0
#define ADDR_OFFSET_VMEM1 26210304
#define ADDR_OFFSET_VMEM2 0
#define ADDR_OFFSET_VMEM1_LD 0
#define ADDR_OFFSET_VMEM2_LD 0
#define NUM_INSTRUCTION 600 // this has to be in bytes as it is used by hardware. Or change hardware
#define NUM_INPUT 2048
#define NUM_WEIGHT 2097152
#define NUM_BIAS 1024
#define NUM_OUTPUT 1024

#elif FPGA_resnet50_conv_bias_relu1_quant
std::string instruction_file  = REPO_PATH+"/resnet50_benchmark16x16_endtoend_quant0/layer0_conv_bias_relu1/conv_bias_relu1_decimal.txt";
std::string output_file  = REPO_PATH+"/resnet50_benchmark16x16_endtoend_quant0/layer0_conv_bias_relu1/data/relu_1_323Y.txt";
std::string bias_file  = REPO_PATH+"/resnet50_benchmark16x16_endtoend_quant0/layer0_conv_bias_relu1/data/conv_0_498D.txt";
std::string weight_file  = REPO_PATH+"/resnet50_benchmark16x16_endtoend_quant0/layer0_conv_bias_relu1/data/conv_0_497B/conv_0_497B_shuffled.txt";
std::string input_file  = REPO_PATH+"/resnet50_benchmark16x16_endtoend_quant0/layer0_conv_bias_relu1/data/input/input_shuffled.txt";
std::string simd_input_file1 = "";
std::string simd_input_file2 = "";

#define ADDR_OFFSET_INPUT 29597696
#define ADDR_OFFSET_WEIGHT 229376
#define ADDR_OFFSET_BIAS 430080
#define MAX_OFFSET 29597696
#define ADDR_OFFSET_OUTPUT 0
#define ADDR_OFFSET_VMEM1 0
#define ADDR_OFFSET_VMEM2 26210304
#define ADDR_OFFSET_VMEM1_LD 0
#define ADDR_OFFSET_VMEM2_LD 0
#define NUM_INSTRUCTION 2048 // this has to be in bytes as it is used by hardware. Or change hardware
#define NUM_INPUT 831744
#define NUM_WEIGHT 200704
#define NUM_BIAS 64
#define NUM_OUTPUT 802816

#elif FPGA_resnet50_maxpool2_quant
std::string instruction_file  = REPO_PATH+"/resnet50_benchmark16x16_endtoend_quant0/layer1_max_pool2/max_pool2_decimal.txt";
std::string output_file  = REPO_PATH+"/resnet50_benchmark16x16_endtoend_quant0/layer1_max_pool2/data/maxpool_2_324Y.txt";
std::string bias_file  = "";
std::string weight_file  = "";
std::string input_file  = "";
std::string simd_input_file1 = REPO_PATH+"/resnet50_benchmark16x16_endtoend_quant0/layer1_max_pool2/data/relu_1_323Y.txt";
std::string simd_input_file2 = "";

#define ADDR_OFFSET_INPUT 0
#define ADDR_OFFSET_WEIGHT 0
#define ADDR_OFFSET_BIAS 0
#define MAX_OFFSET 29638656
#define ADDR_OFFSET_OUTPUT 0
#define ADDR_OFFSET_VMEM1 0
#define ADDR_OFFSET_VMEM2 29638656
#define ADDR_OFFSET_VMEM1_LD 26210304
#define ADDR_OFFSET_VMEM2_LD 0
#define NUM_INSTRUCTION 2048 // this has to be in bytes as it is used by hardware. Or change hardware
#define NUM_INPUT 831744
#define NUM_WEIGHT 0
#define NUM_BIAS 0
#define NUM_OUTPUT 200704

#elif FPGA_resnet_b2b
std::string data_info_file = REPO_PATH+"/resnet50_benchmark16x16_endtoend_quant0/program/resnet50_operand_storage_info.json";
std::string test_path = REPO_PATH+"/resnet50_benchmark16x16_endtoend_quant0/";
std::string base_path = REPO_PATH+"/";

#else
std::string instruction_file  = "/home/rohan/genesys-merged-repo/testcases/resnet50_1_conv_case106/resnet50_1_conv_decimal.txt";
std::string input_file        = "/home/rohan/genesys-merged-repo/testcases/resnet50_1_conv_case106/input_shuffled.txt";
std::string bias_file         = "/home/rohan/genesys-merged-repo/testcases/resnet50_1_conv_case106/bias.txt";
std::string weight_file       = "/home/rohan/genesys-merged-repo/testcases/resnet50_1_conv_case106/weights_shuffled.txt";
std::string output_file       = "/home/rohan/genesys-merged-repo/testcases/resnet50_1_conv_case106/output.txt";
#endif
