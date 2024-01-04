#include <vector>
#include <unistd.h>
#include <iostream>
#include <fstream>
#include <string> 
#include <CL/cl2.hpp>
#include <time.h>

std::string REPO_PATH = "/home/lavanya/genesys-16x16/tests";
#include <regression_config_genesys16.h>

// SIZE OF EACH ELEMENT
#define INT_SIZE 4
#define INSTRUCTION_SIZE 4
#define INPUT_SIZE 1
#define WEIGHT_SIZE 1
#define BIAS_SIZE 4
#define OUTPUT_SIZE 4

// #define NUM_INSTRUCTION 432 // this has to be in bytes as it is used by hardware. Or change hardware
// #define NUM_INPUT 2048
// #define NUM_WEIGHT 2097152
// #define NUM_BIAS 1024
// #define NUM_OUTPUT 1024
#define ADDR_OFFSET_INSTRUCTION 0

// #define ADDR_OFFSET_INPUT 26619904
// #define ADDR_OFFSET_WEIGHT 10403840
// #define ADDR_OFFSET_BIAS 6160384
// #define MAX_OFFSET 26619904
// #define ADDR_OFFSET_OUTPUT 0
// #define ADDR_OFFSET_VMEM1 0
// #define ADDR_OFFSET_VMEM2 0
// #define ADDR_OFFSET_VMEM1_LD 0
// #define ADDR_OFFSET_VMEM2_LD 0 

#define scaling_factor 1.1
#define TOTAL_DATA_NUM MAX_OFFSET+(NUM_INSTRUCTION + NUM_INPUT + NUM_WEIGHT + NUM_BIAS)
#define INSTRUCTION_ADDR_PTR 0
#define INPUT_ADDR_PTR ADDR_OFFSET_INPUT/INT_SIZE
#define WEIGHTS_ADDR_PTR ADDR_OFFSET_WEIGHT/INT_SIZE
#define BIAS_ADDR_PTR ADDR_OFFSET_BIAS/INT_SIZE
// Use different buffer for output. So initialize it to 0
//#define OUTPUT_ADDR_PTR OUTPUT_SIZE_BYTES/INT_SIZE
#define OUTPUT_ADDR_PTR ADDR_OFFSET_OUTPUT/INT_SIZE
#define SIMD_ADDR_VMEM1_PTR ADDR_OFFSET_VMEM1/INT_SIZE
#define SIMD_ADDR_VMEM1_LD_PTR ADDR_OFFSET_VMEM1_LD/INT_SIZE
#define SIMD_ADDR_VMEM2_PTR ADDR_OFFSET_VMEM2/INT_SIZE
#define SIMD_ADDR_VMEM2_LD_PTR ADDR_OFFSET_VMEM2_LD/INT_SIZE

// Helper function declarations
;
char* read_binary_file(const std::string &xclbin_file_name, unsigned &nb);
void read_data_file(const std::string &file_name, int *arr, const int ptr,const int get_num_lines); 
void read_instructions_file(const std::string &file_name, int *arr, int debug_flag); 
void initialize_array(int *arr, int size, int val); 
void print_array(int *arr, int size);
void stoptime (clock_t start, char msg[]);
