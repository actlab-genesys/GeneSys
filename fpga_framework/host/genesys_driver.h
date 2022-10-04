#include <vector>
#include <unistd.h>
#include <iostream>
#include <fstream>
#include <string> 
#include <CL/cl2.hpp>
#include <time.h>

/********* Choose Systolic Array Size *********/
#include <regression_config_SA_16x16.h>
std::string REPO_PATH = "/home/rohan/serverless_accel_results"

/*
#ifdef SA_2x2
    #include <regression_config.h>
#elif defined(SA_4x4)
    #include <regression_config_SA_8x8.h>
#elif defined(SA_8x8)
    #include <regression_config_SA_8x8.h>
#elif defined(SA_16x16)
    #include <regression_config_SA_16x16.h>
#elif defined(SA32x32)
    #include <regression_config_SA_8x8.h>
#elif defined(SA_64x64)
    #include <regression_config.h>
#else
    #include <regression_config.h>
#endif

*/

/************************************************/

// SIZE OF EACH ELEMENT
#define INT_SIZE 4
#define INSTRUCTION_SIZE 4
#define INPUT_SIZE 1
#define WEIGHT_SIZE 1
#define BIAS_SIZE 4
#define OUTPUT_SIZE 4

//#define CUSTOM_CONV_NON_ALIGNED_REQ 1
    #define NUM_INSTRUCTION 4000 // this has to be in bytes as it is used by hardware. Or change hardware
    #define NUM_INPUT 13542400
    #define NUM_WEIGHT 1605632
    #define NUM_BIAS 128
    #define NUM_OUTPUT 1605632
    
    #define ADDR_OFFSET_INSTRUCTION 0
    #define ADDR_OFFSET_INPUT 4259840
    #define ADDR_OFFSET_WEIGHT 24576
    #define ADDR_OFFSET_BIAS 4096
    #define ADDR_OFFSET_OUTPUT 0
    #define ADDR_OFFSET_VMEM1 2097152
    #define ADDR_OFFSET_VMEM2 4194304
    #define ADDR_OFFSET_VMEM1_LD 0
    #define ADDR_OFFSET_VMEM2_LD 262144
#ifdef RESNET_CONV_64_TILES
    #define NUM_INSTRUCTION 880 // this has to be in bytes as it is used by hardware. Or change hardware
    #define NUM_INPUT 13542400
    #define NUM_WEIGHT 1605632
    #define NUM_BIAS 128
    #define NUM_OUTPUT 1605632

    // todo: add a path varialbe and concatenate it to the below file names
    std::string instruction_file  =   "/home/rohan/genesys-merged-repo/genesys-systolic/testbench/resnet18_conv_64tiles/resnet18_conv_decimal.txt"; 
    std::string output_file       =   "/home/rohan/genesys-merged-repo/genesys-systolic/testbench/resnet18_conv_64tiles/weights_shuffled.txt";
    std::string input_file        =   "/home/rohan/genesys-merged-repo/genesys-systolic/testbench/resnet18_conv_64tiles/input_shuffled.txt";
    std::string weight_file       =   "/home/rohan/genesys-merged-repo/genesys-systolic/testbench/resnet18_conv_64tiles/weights_shuffled.txt"; 
    std::string bias_file         =   "/home/rohan/genesys-merged-repo/genesys-systolic/testbench/resnet18_conv_64tiles/bias.txt"; 

    #define ADDR_OFFSET_INSTRUCTION 0
    #define ADDR_OFFSET_INPUT 4259840
    #define ADDR_OFFSET_WEIGHT 24576
    #define ADDR_OFFSET_BIAS 4096
    #define ADDR_OFFSET_OUTPUT 0

#elif CUSTOM_CONV_NON_ALIGNED_REQ
    #define NUM_INSTRUCTION 880 // this has to be in bytes as it is used by hardware. Or change hardware
    #define NUM_INPUT 13542400
    #define NUM_WEIGHT 1605632
    #define NUM_BIAS 128
    #define NUM_OUTPUT 1605632

    // todo: add a path varialbe and concatenate it to the below file names
    std::string instruction_file  =   "/home/rohan/genesys-merged-repo/genesys-systolic/testbench/cc_layer_non_aligned_req/cc_layer2_conv_decimal.txt"; 
    std::string output_file       =   "/home/rohan/genesys-merged-repo/genesys-systolic/testbench/cc_layer_non_aligned_req/output.txt";
    std::string input_file        =   "/home/rohan/genesys-merged-repo/genesys-systolic/testbench/cc_layer_non_aligned_req/input_shuffled.txt";
    std::string weight_file       =   "/home/rohan/genesys-merged-repo/genesys-systolic/testbench/cc_layer_non_aligned_req/weights_shuffled.txt"; 
    std::string bias_file         =   "/home/rohan/genesys-merged-repo/genesys-systolic/testbench/cc_layer_non_aligned_req/bias.txt"; 

    #define ADDR_OFFSET_INSTRUCTION 0
    #define ADDR_OFFSET_INPUT 4259840
    #define ADDR_OFFSET_WEIGHT 24576
    #define ADDR_OFFSET_BIAS 4096
    #define ADDR_OFFSET_OUTPUT 0
/*
#else
    // NUMBER OF ELEMENTS
    #define NUM_INSTRUCTION 880 // this has to be in bytes as it is used by hardware. Or change hardware
    #define NUM_INPUT 69696
    #define NUM_WEIGHT 36864
    #define NUM_BIAS 64
    #define NUM_OUTPUT 16384
    // todo: add a path varialbe and concatenate it to the below file names
    std::string instruction_file  =   "/home/rohan/genesys-merged-repo/genesys-systolic/testbench/test_custom_conv_conv_partials_cs_v3/custom_conv_conv_decimal.txt"; 
    std::string output_file       =   "/home/rohan/genesys-merged-repo/genesys-systolic/testbench/test_custom_conv_conv_partials_cs_v3/output.txt";
    std::string input_file        =   "/home/rohan/genesys-merged-repo/genesys-systolic/testbench/test_custom_conv_conv_partials_cs_v3/input_shuffled.txt";
    std::string weight_file       =   "/home/rohan/genesys-merged-repo/genesys-systolic/testbench/test_custom_conv_conv_partials_cs_v3/weights_shuffled.txt"; 
    std::string bias_file         =   "/home/rohan/genesys-merged-repo/genesys-systolic/testbench/test_custom_conv_conv_partials_cs_v3/bias.txt"; 
    // ADDRESS OFFSETS
    #define ADDR_OFFSET_INSTRUCTION 0
    #define ADDR_OFFSET_INPUT 65536
    #define ADDR_OFFSET_WEIGHT 1048576
    #define ADDR_OFFSET_BIAS 8192
    #define ADDR_OFFSET_OUTPUT 0
*/
#endif

// TOTAL SIZE OF DATA
#define INSTRUCTION_SIZE_BYTES (NUM_INSTRUCTION/(INT_SIZE/INSTRUCTION_SIZE)) * INT_SIZE  
#define INPUT_SIZE_BYTES (NUM_INPUT/(INT_SIZE/INPUT_SIZE)) * INT_SIZE 
#define WEIGHT_SIZE_BYTES (NUM_WEIGHT/(INT_SIZE/WEIGHT_SIZE)) * INT_SIZE  
#define BIAS_SIZE_BYTES (NUM_BIAS/(INT_SIZE/BIAS_SIZE)) * INT_SIZE  
#define OUTPUT_SIZE_BYTES (NUM_OUTPUT/(INT_SIZE/OUTPUT_SIZE)) * INT_SIZE  




#define SCALE_FACTOR 1.1
#define TOTAL_DATA_SIZE SCALE_FACTOR * (INSTRUCTION_SIZE_BYTES + INPUT_SIZE_BYTES + WEIGHT_SIZE_BYTES + BIAS_SIZE_BYTES)
//#define TOTAL_DATA_SIZE_INT TOTAL_DATA_SIZE/INT_SIZE 262144 
#define TOTAL_DATA_SIZE_INT 17902240/INT_SIZE 

#define INSTRUCTION_ADDR_PTR 0
#define INPUT_ADDR_PTR ADDR_OFFSET_INPUT/INT_SIZE
#define WEIGHTS_ADDR_PTR ADDR_OFFSET_WEIGHT/INT_SIZE
#define BIAS_ADDR_PTR ADDR_OFFSET_BIAS/INT_SIZE
// Use different buffer for output. So initialize it to 0
//#define OUTPUT_ADDR_PTR OUTPUT_SIZE_BYTES/INT_SIZE
#define OUTPUT_ADDR_PTR 0


// Helper function declarations
;
char* read_binary_file(const std::string &xclbin_file_name, unsigned &nb);
void read_data_file(const std::string &file_name, int *arr, const int ptr,const int get_num_lines); 
void read_instructions_file(const std::string &file_name, int *arr, int debug_flag); 
void initialize_array(int *arr, int size, int val); 
void print_array(int *arr, int size);
void stoptime (clock_t start, char msg[]);
