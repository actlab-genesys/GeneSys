#include <vector>
#include <unistd.h>
#include <iostream>
#include <fstream>
#include <string> 
#include <CL/cl2.hpp>
#include <time.h>
#include <jsoncpp/json/json.h>
#include <dirent.h>

std::string REPO_PATH = "/home/lavanya/genesys-16x16/tests";
#include <regression_config_genesys16.h>

// SIZE OF EACH ELEMENT
#define NUM_INSTRUCTION 2048 // this has to be in bytes as it is used by hardware. Or change hardware
#define NUM_OUTPUT 200704
#define MAX_OFFSET 29638656
#define scaling_factor 1.5
#define TOTAL_DATA_NUM scaling_factor * MAX_OFFSET

// Helper function declarations
;
char* read_binary_file(const std::string &xclbin_file_name, unsigned &nb);
void read_data_file(const std::string &file_name, int *arr, const int ptr,const int get_num_lines); 
void read_instructions_file(const std::string &file_name, const int ptr ,int *arr, int debug_flag); 
void initialize_array(int *arr, int size, int val); 
void print_array(int *arr, int size);
void stoptime (clock_t start, char msg[]);
