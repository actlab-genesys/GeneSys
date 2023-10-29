#define CL_HPP_CL_1_2_DEFAULT_BUILD
#define CL_HPP_TARGET_OPENCL_VERSION 120
#define CL_HPP_MINIMUM_OPENCL_VERSION 120
#define CL_HPP_ENABLE_PROGRAM_CONSTRUCTION_FROM_ARRAY_COMPATIBILITY 1
#define CL_USE_DEPRECATED_OPENCL_1_2_APIS

#define INSTRUCTION_SIZE 412
#define INPUT_DATA_SIZE 128
#define WEIGHT_SIZE 131072
#define BIAS_SIZE 1024
#define OUTPUT_DATA_SIZE 1024

#include <vector>
#include <unistd.h>
#include <iostream>
#include <fstream>
#include <string> 
#include <CL/cl2.hpp>

std::vector<cl::Device> get_xilinx_devices();
char* read_binary_file(const std::string &xclbin_file_name, unsigned &nb);
void read_data_file(const std::string &file_name, int *arr); 
void read_instructions_file(const std::string &file_name, int *arr, int debug_flag); 
void initialize_array(int *arr, int size, int val); 
void print_array(int *arr, int size);

std::string instruction_file    =   "/home/rohan/genesys-fpga-v1/genesys-systolic/testbench/resnet18_gemm_actual_ip/resnet18_gemm_decimal.txt"; 
std::string input_file          =   "/home/rohan/genesys-fpga-v1/genesys-systolic/testbench/resnet18_gemm_actual_ip/gemm_output.txt";
std::string weight_file         =   "/home/rohan/genesys-fpga-v1/genesys-systolic/testbench/resnet18_gemm_actual_ip/inputs.txt";
std::string bias_file           =   "/home/rohan/genesys-fpga-v1/genesys-systolic/testbench/resnet18_gemm_actual_ip/parameters_gemm_ddr.txt"; 
std::string output_file         =   "/home/rohan/genesys-fpga-v1/genesys-systolic/testbench/resnet18_gemm_actual_ip/resnet18_linear_bias_i32.txt"; 

// ------------------------------------------------------------------------------------
// Main program
// ------------------------------------------------------------------------------------
int main(int argc, char** argv)
{

    int reg_initialize_val = 0;
// ------------------------------------------------------------------------------------
// Step 1: Initialize the OpenCL environment 
// the host detects the attached Xilinx device, loads the FPGA binary (.xclbin file) from file and programs it into the first Xilinx device it found
// ------------------------------------------------------------------------------------ 
    cl_int err;
    std::string binaryFile = (argc != 2) ? "systolic_fpga.hw_emu.xclbin" : argv[1];
    unsigned fileBufSize;    
    // adds the list of xilinx devices into the stl  vector
    std::vector<cl::Device> devices = get_xilinx_devices();
    // have a single FPGA device on the PC
    devices.resize(1);
    cl::Device device = devices[0];
    cl::Context context(device, NULL, NULL, NULL, &err);
    char* fileBuf = read_binary_file(binaryFile, fileBufSize);
    cl::Program::Binaries bins{{fileBuf, fileBufSize}};
    // program the FPGA
    cl::Program program(context, devices, bins, NULL, &err);
    // command queue and the kernel object are created
    cl::CommandQueue q(context, device, CL_QUEUE_PROFILING_ENABLE, &err);
    cl::Kernel systolic_fpga_krnl(program,"systolic_fpga", &err);

// ------------------------------------------------------------------------------------
// Step 2: Create buffers and initialize test values
// ------------------------------------------------------------------------------------
    // Create the buffers and allocate memory   
    /*
    On data-center platforms, it is more efficient to allocate memory aligned on 4k page boundaries. 
    On embedded platforms, it is more efficient to perform contiguous memory allocation. 
    A simple way of achieving either of these is to let the Xilinx Runtime allocate host memory when creating the buffers. 
    This is done by using the CL_MEM_ALLOC_HOST_PTR flag when creating the buffers and then mapping the allocated memory to user-space pointers.
    */
   
    cl::Buffer instructions(context, CL_MEM_ALLOC_HOST_PTR | CL_MEM_READ_ONLY, INSTRUCTION_SIZE, NULL, &err);
    cl::Buffer inputs(context, CL_MEM_ALLOC_HOST_PTR | CL_MEM_READ_ONLY,  INPUT_DATA_SIZE, NULL, &err);
    cl::Buffer weights(context, CL_MEM_ALLOC_HOST_PTR | CL_MEM_READ_ONLY, WEIGHT_SIZE, NULL, &err);
    cl::Buffer bias(context, CL_MEM_ALLOC_HOST_PTR | CL_MEM_READ_ONLY,  sizeof(int) * BIAS_SIZE, NULL, &err);
    cl::Buffer outputs(context, CL_MEM_ALLOC_HOST_PTR | CL_MEM_WRITE_ONLY, sizeof(int) * OUTPUT_DATA_SIZE, NULL, &err);

    // Map buffers to kernel arguments, thereby assigning them to specific device memory banks
    //systolic_fpga_krnl.setArg(15, instructions);
    //systolic_fpga_krnl.setArg(16, inputs);
    //systolic_fpga_krnl.setArg(17, weights);
    //systolic_fpga_krnl.setArg(18, outputs);

    // Map host-side buffer memory to user-space pointers (kernel paramters?)
    int *instructions_ptr = (int *)q.enqueueMapBuffer(instructions, CL_TRUE, CL_MAP_WRITE, 0, INSTRUCTION_SIZE);
    int *input_ptr = (int *)q.enqueueMapBuffer(inputs, CL_TRUE, CL_MAP_WRITE, 0, INPUT_DATA_SIZE); 
    int *weight_ptr = (int *)q.enqueueMapBuffer(weights, CL_TRUE, CL_MAP_WRITE, 0, WEIGHT_SIZE);
    int *bias_ptr = (int *)q.enqueueMapBuffer(bias, CL_TRUE, CL_MAP_WRITE, 0, sizeof(int) * BIAS_SIZE); 
    int *output_ptr = (int *)q.enqueueMapBuffer(outputs, CL_TRUE, CL_MAP_WRITE | CL_MAP_READ, 0, sizeof(int) * OUTPUT_DATA_SIZE);
    
    read_instructions_file(instruction_file, instructions_ptr,1);
    read_data_file(input_file, input_ptr);
    read_data_file(weight_file, weight_ptr);
    read_data_file(bias_file, bias_ptr);
    initialize_array(output_ptr, OUTPUT_DATA_SIZE, reg_initialize_val);
// ------------------------------------------------------------------------------------
// Step 3: Run the kernel
// schedule three operations on the command queue: 
//  1. the transfers of the three input vectors to device memory 
//  2. the execution of the kernel
//  3. lastly the transfer of the results back to host memory
// ------------------------------------------------------------------------------------
    // Set kernel arguments
        
    for (int i = 0; i < 15; i++) {
        if (i != 2)
            systolic_fpga_krnl.setArg(i, reg_initialize_val);    
    }
    
    systolic_fpga_krnl.setArg(2, INSTRUCTION_SIZE);
    systolic_fpga_krnl.setArg(15, instructions);
    systolic_fpga_krnl.setArg(16, inputs);
    systolic_fpga_krnl.setArg(17, weights);
    systolic_fpga_krnl.setArg(18, outputs);
    
    // Schedule transfer of inputs to device memory, execution of kernel, and transfer of outputs back to host memory
    q.enqueueMigrateMemObjects({instructions, inputs, weights}, 0 /* 0 means from host*/); 
    q.enqueueTask(systolic_fpga_krnl);
    q.enqueueMigrateMemObjects({outputs}, CL_MIGRATE_MEM_OBJECT_HOST);

    // Wait for all scheduled operations to finish
    //q.finish() is necessary to wait until all enqueued commands run to completion as otherwise computation on the accelerator is non blocking.
    q.finish();
    
// ------------------------------------------------------------------------------------
// Step 4: Check Results and Release Allocated Resources
// ------------------------------------------------------------------------------------
    
    
    int *output_reference_arr = (int *)q.enqueueMapBuffer(outputs, CL_TRUE, CL_MAP_WRITE | CL_MAP_READ, 0, sizeof(int) * OUTPUT_DATA_SIZE); 
    read_data_file(output_file, output_reference_arr);
    
    bool match = true;
    for (int i = 0 ; i < OUTPUT_DATA_SIZE ; i++){
        int expected = output_reference_arr[i];
        if (output_ptr[i] != expected){
            std::cout << "Error: Result mismatch" << std::endl;
            std::cout << "i = " << i << " CPU result = " << expected << " Device result = " << output_ptr[i] << std::endl;
            match = false;
            break;
        }
    }

    delete[] fileBuf;

    std::cout << "TEST " << (match ? "PASSED" : "FAILED") << std::endl; 
    return (match ? EXIT_SUCCESS : EXIT_FAILURE);
}


// ------------------------------------------------------------------------------------
// Utility functions
// ------------------------------------------------------------------------------------
std::vector<cl::Device> get_xilinx_devices() 
{
    size_t i;
    cl_int err;
    std::vector<cl::Platform> platforms;
    err = cl::Platform::get(&platforms);
    cl::Platform platform;
    for (i  = 0 ; i < platforms.size(); i++){
        platform = platforms[i];
        std::string platformName = platform.getInfo<CL_PLATFORM_NAME>(&err);
        if (platformName == "Xilinx"){
            std::cout << "INFO: Found Xilinx Platform" << std::endl;
            break;
        }
    }
    if (i == platforms.size()) {
        std::cout << "ERROR: Failed to find Xilinx platform" << std::endl;
        exit(EXIT_FAILURE);
    }
   
    //Getting ACCELERATOR Devices and selecting 1st such device 
    std::vector<cl::Device> devices;
    err = platform.getDevices(CL_DEVICE_TYPE_ACCELERATOR, &devices);
    return devices;
}
   
char* read_binary_file(const std::string &xclbin_file_name, unsigned &nb) 
{
    if(access(xclbin_file_name.c_str(), R_OK) != 0) {
        printf("ERROR: %s xclbin not available please build\n", xclbin_file_name.c_str());
        exit(EXIT_FAILURE);
    }
    //Loading XCL Bin into char buffer 
    std::cout << "INFO: Loading '" << xclbin_file_name << "'\n";
    std::ifstream bin_file(xclbin_file_name.c_str(), std::ifstream::binary);
    bin_file.seekg (0, bin_file.end);
    nb = bin_file.tellg();
    bin_file.seekg (0, bin_file.beg);
    char *buf = new char [nb];
    bin_file.read(buf, nb);
    return buf;
}

void read_instructions_file(const std::string &file_name, int *arr, int debug_flag) 
{
    if(access(file_name.c_str(), R_OK) != 0) {
        printf("ERROR: %s Error reading file \n", file_name.c_str());
        exit(EXIT_FAILURE);
    } 
    std::cout << "INFO: Reading File '" << file_name << "'\n";
    std::ifstream fp(file_name.c_str());
    
    std::string line;
    int idx = 0;
    long long longLine;
    if (fp.is_open()) {
        while (!fp.eof()) {
            std::getline(fp, line);
            longLine = std::stoll(line);
            if (debug_flag == 1) {
                std::cout<<"size is ="<<line.size()<<"\n";
                std::cout << "Index: " << idx << " String Value: "<< (uint)longLine <<"\n";
            }
            arr[idx++] = (uint)longLine;

        
        }
        fp.close();
    }
    else std::cout << "Unable to open the file";
    
}


void read_data_file(const std::string &file_name, int *arr) 
{
    if(access(file_name.c_str(), R_OK) != 0) {
        printf("ERROR: %s Error reading file \n", file_name.c_str());
        exit(EXIT_FAILURE);
    } 
    std::cout << "INFO: Reading File '" << file_name << "'\n";
    std::fstream fp(file_name.c_str(), std::ios_base::in);
    
    int line, idx = 0;
    while (fp >> line)
    {
        arr[idx] = line;
        idx++;
    }
}


void print_array(int *arr, int size)
{
    /*
    std::string name ;
    std::ifstream dataFile("/home/rohan/genesys-fpga-v1/genesys-systolic/testbench/resnet18_gemm_actual_ip/resnet18_gemm_decimal.txt");
    while (!dataFile.fail() && !dataFile.eof() )
    {
          dataFile >> name ;
          std::cout << name << "\n";
    }
    */
    for (int i = 0; i < size; i++)
        std::cout << "Index" << i << "Value"<< arr[i] <<"\n";


}


void initialize_array(int *arr, int size, int val) 
{
    for (int i =0; i < size; i++)
    {
        arr[i] = val;
    }
}