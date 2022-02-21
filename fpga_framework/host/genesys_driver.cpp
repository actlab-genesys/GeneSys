#define CL_HPP_CL_1_2_DEFAULT_BUILD
#define CL_HPP_TARGET_OPENCL_VERSION 120
#define CL_HPP_MINIMUM_OPENCL_VERSION 120
#define CL_HPP_ENABLE_PROGRAM_CONSTRUCTION_FROM_ARRAY_COMPATIBILITY 1
#define CL_USE_DEPRECATED_OPENCL_1_2_APIS

#include <genesys_driver.h>

std::vector<cl::Device> get_xilinx_devices();
int num_output = 0 ;

// ------------------------------------------------------------------------------------
// Main program
// ------------------------------------------------------------------------------------
int main(int argc, char** argv)
{
    int reg_initialize_val = 0;
    long addr_initialize_val = 0;
    clock_t data_transfer_start, output_transfer_start, execution_start;
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
   
    cl::Buffer base_address(context, CL_MEM_ALLOC_HOST_PTR | CL_MEM_READ_ONLY, sizeof(int) * TOTAL_DATA_SIZE_INT, NULL, &err);
    cl::Buffer outputs(context, CL_MEM_ALLOC_HOST_PTR | CL_MEM_WRITE_ONLY, sizeof(int) * NUM_OUTPUT * 2, NULL, &err);

    // Map host-side buffer memory to user-space pointers (kernel paramters?)
    int *base_ptr = (int *)q.enqueueMapBuffer(base_address, CL_TRUE, CL_MAP_WRITE, 0, sizeof(int) * TOTAL_DATA_SIZE_INT);
    int *output_ptr = (int *)q.enqueueMapBuffer(outputs, CL_TRUE, CL_MAP_WRITE | CL_MAP_READ, 0, sizeof(int) * NUM_OUTPUT * 2);
    
    
    const int input_addr_iterator = INPUT_ADDR_PTR;
    const int weight_addr_iterator = WEIGHTS_ADDR_PTR;
    const int bias_addr_iterator = BIAS_ADDR_PTR;
    

    read_instructions_file(instruction_file, base_ptr,0);
    read_data_file(bias_file, base_ptr,bias_addr_iterator,0);
    read_data_file(weight_file, base_ptr,weight_addr_iterator,0);
    read_data_file(input_file, base_ptr,input_addr_iterator,0);
    initialize_array(output_ptr, NUM_OUTPUT, reg_initialize_val);
// ------------------------------------------------------------------------------------
// Step 3: Run the kernel
// schedule three operations on the command queue: 
//  1. the transfers of the three input vectors to device memory 
//  2. the execution of the kernel
//  3. lastly the transfer of the results back to host memory
// ------------------------------------------------------------------------------------
    // Set kernel arguments
    std::cout << "Initialize registers" <<"\n";    
    for (int i = 0; i < 15; i++) {
        if (i != 2)
            systolic_fpga_krnl.setArg(i, reg_initialize_val);    
    }   
    systolic_fpga_krnl.setArg(2, NUM_INSTRUCTION); 
    systolic_fpga_krnl.setArg(15, base_address);
    // writing base address for now. Else getting seg fault    
    systolic_fpga_krnl.setArg(16, base_address);  
    systolic_fpga_krnl.setArg(17, base_address);   
    systolic_fpga_krnl.setArg(18, outputs);
    
    // Schedule transfer of inputs to device memory, execution of kernel, and transfer of outputs back to host memory
    std::cout << "Transfer Data to DDR" <<"\n";
    //data_transfer_start = clock();
    q.enqueueMigrateMemObjects({base_address, outputs}, 0 /* 0 means from host*/); 
    //std::cout<< "Input Transfer Time: "<<(double)(clock() - data_transfer_start)/CLOCKS_PER_SEC << std::endl;

       
    std::cout << "Execute Program" <<"\n";
    //execution_start  = clock();
    q.enqueueTask(systolic_fpga_krnl);
    //std::cout<< "Execution Time: "<<(double)(clock() - execution_start)/CLOCKS_PER_SEC << std::endl;
    std::cout << "Copy data from DDR" <<"\n";
    //output_transfer_start = clock();
    q.enqueueMigrateMemObjects({outputs}, CL_MIGRATE_MEM_OBJECT_HOST);
    std::cout<< "Execution Time: "<<(double)(clock() - output_transfer_start)/CLOCKS_PER_SEC << std::endl;

    // Wait for all scheduled operations to finish
    //q.finish() is necessary to wait until all enqueued commands run to completion as otherwise computation on the accelerator is non blocking.
    q.finish();
    
// ------------------------------------------------------------------------------------
// Step 4: Check Results and Release Allocated Resources
// ------------------------------------------------------------------------------------
    std::cout << "Output Comparision" <<"\n";
    //std::cout << output_ptr[0] << "\n" ;
    const int output_addr_iterator = OUTPUT_ADDR_PTR + NUM_OUTPUT;
    int *output_reference_arr = (int *)q.enqueueMapBuffer(outputs, CL_TRUE, CL_MAP_WRITE | CL_MAP_READ, 0, sizeof(int) * NUM_OUTPUT * 2); 
    read_data_file(output_file, output_reference_arr, output_addr_iterator,1);
    
    bool match = true;
    for (int i = 0 ; i < num_output ; i++){
        int expected = output_reference_arr[i+NUM_OUTPUT];
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


void read_data_file(const std::string &file_name, int *arr, const int ptr, const int get_num_lines) 
{
    if(access(file_name.c_str(), R_OK) != 0) {
        printf("ERROR: %s Error reading file \n", file_name.c_str());
        exit(EXIT_FAILURE);
    } 
    std::cout << "INFO: Reading File '" << file_name << "'\n";
    std::fstream fp(file_name.c_str(), std::ios_base::in);
    
    int local_ptr = ptr;
    long long line;
    int idx = 0;
    while (fp >> line)
    {
        arr[local_ptr] = (uint) line;
//	std::cout << arr[local_ptr] << " \n" << std::endl ;
        local_ptr++;
	idx++ ;
	
    }
    if (get_num_lines){
        num_output = idx ;
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
    std::cout << "Exiting Initialize Array Function" <<"\n";
}
