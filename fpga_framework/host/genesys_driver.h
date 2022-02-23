#include <vector>
#include <unistd.h>
#include <iostream>
#include <fstream>
#include <string> 
#include <CL/cl2.hpp>
#include <time.h>


#define SA_8x8

// SIZE OF EACH ELEMENT
#define INT_SIZE 4
#define INSTRUCTION_SIZE 4
#define INPUT_SIZE 1
#define WEIGHT_SIZE 1
#define BIAS_SIZE 4
#define OUTPUT_SIZE 4

#define NUM_INSTRUCTION 880 // this has to be in bytes as it is used by hardware. Or change hardware
#define NUM_INPUT 13542400
#define NUM_WEIGHT 1605632
#define NUM_BIAS 128
#define NUM_OUTPUT 1605632

#define ADDR_OFFSET_INSTRUCTION 0
#define ADDR_OFFSET_INPUT 4259840
#define ADDR_OFFSET_WEIGHT 24576
#define ADDR_OFFSET_BIAS 4096
#define ADDR_OFFSET_OUTPUT 0

std::string REPO_PATH = "/home/rohan/GeneSys"


#ifdef RESNET50_GEMM
    #define NUM_INSTRUCTION 880 // this has to be in bytes as it is used by hardware. Or change hardware
    #define NUM_INPUT 13542400
    #define NUM_WEIGHT 1605632
    #define NUM_BIAS 128
    #define NUM_OUTPUT 1605632

    std::string instruction_file  =  REPO_PATH + "verif/systolic_array/resnet50_gemm/fpga_8x8_tile4_case0_gemm_decimal.txt.txt"; 
    std::string output_file       =  REPO_PATH + "verif/systolic_array/resnet50_gemm/out.txt";
    std::string input_file        =  REPO_PATH + "verif/systolic_array/resnet50_gemm/data_shuffled.txt";
    std::string weight_file       =  REPO_PATH + "verif/systolic_array/resnet50_gemm/weight_shuffled.txt"; 
    std::string bias_file         =  REPO_PATH + "verif/systolic_array/resnet50_gemm/bias.txt"; 

    #define ADDR_OFFSET_INSTRUCTION 0
    #define ADDR_OFFSET_INPUT 4259840
    #define ADDR_OFFSET_WEIGHT 24576
    #define ADDR_OFFSET_BIAS 4096
    #define ADDR_OFFSET_OUTPUT 0

#else
    #define NUM_INSTRUCTION 880
    #define NUM_INPUT 13542400
    #define NUM_WEIGHT 1605632
    #define NUM_BIAS 128
    #define NUM_OUTPUT 1605632

    std::string instruction_file  =  REPO_PATH + "verif/systolic_array/resnet50_conv/fpga_8x8_tile3_case0_oc_oh_ow_conv_decimal.txt"; 
    std::string output_file       =  REPO_PATH + "verif/systolic_array/resnet50_conv/out.txt";
    std::string input_file        =  REPO_PATH + "verif/systolic_array/resnet50_conv/data_shuffled.txt";
    std::string weight_file       =  REPO_PATH + "verif/systolic_array/resnet50_conv/weight_shuffled.txt"; 
    std::string bias_file         =  REPO_PATH + "verif/systolic_array/resnet50_conv/bias.txt"; 

    #define ADDR_OFFSET_INSTRUCTION 0
    #define ADDR_OFFSET_INPUT 4259840
    #define ADDR_OFFSET_WEIGHT 24576
    #define ADDR_OFFSET_BIAS 4096
    #define ADDR_OFFSET_OUTPUT 0

#endif

// TOTAL SIZE OF DATA
#define INSTRUCTION_SIZE_BYTES (NUM_INSTRUCTION/(INT_SIZE/INSTRUCTION_SIZE)) * INT_SIZE  
#define INPUT_SIZE_BYTES (NUM_INPUT/(INT_SIZE/INPUT_SIZE)) * INT_SIZE 
#define WEIGHT_SIZE_BYTES (NUM_WEIGHT/(INT_SIZE/WEIGHT_SIZE)) * INT_SIZE  
#define BIAS_SIZE_BYTES (NUM_BIAS/(INT_SIZE/BIAS_SIZE)) * INT_SIZE  
#define OUTPUT_SIZE_BYTES (NUM_OUTPUT/(INT_SIZE/OUTPUT_SIZE)) * INT_SIZE  

#define SCALE_FACTOR 1.1
#define TOTAL_DATA_SIZE SCALE_FACTOR * (INSTRUCTION_SIZE_BYTES + INPUT_SIZE_BYTES + WEIGHT_SIZE_BYTES + BIAS_SIZE_BYTES)
#define TOTAL_DATA_SIZE_INT 17902240/INT_SIZE 

#define INSTRUCTION_ADDR_PTR 0
#define INPUT_ADDR_PTR ADDR_OFFSET_INPUT/INT_SIZE
#define WEIGHTS_ADDR_PTR ADDR_OFFSET_WEIGHT/INT_SIZE
#define BIAS_ADDR_PTR ADDR_OFFSET_BIAS/INT_SIZE
#define OUTPUT_ADDR_PTR 0

// Helper function declarations
char* read_binary_file(const std::string &xclbin_file_name, unsigned &nb);
void read_data_file(const std::string &file_name, int *arr, const int ptr,const int get_num_lines); 
void read_instructions_file(const std::string &file_name, int *arr, int debug_flag); 
void initialize_array(int *arr, int size, int val); 
void print_array(int *arr, int size);

