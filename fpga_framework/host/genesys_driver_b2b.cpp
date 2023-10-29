#define CL_HPP_CL_1_2_DEFAULT_BUILD
#define CL_HPP_TARGET_OPENCL_VERSION 120
#define CL_HPP_MINIMUM_OPENCL_VERSION 120
#define CL_HPP_ENABLE_PROGRAM_CONSTRUCTION_FROM_ARRAY_COMPATIBILITY 1
#define CL_USE_DEPRECATED_OPENCL_1_2_APIS

#include <genesys_driver_b2b.h>

std::vector<cl::Device> get_xilinx_devices();
int num_output = 0; 

// ------------------------------------------------------------------------------------
// Main program
// ------------------------------------------------------------------------------------
int main(int argc, char** argv)
{
    int reg_initialize_val = 0;
   // int wait_var = 0;
    long addr_initialize_val = 0;
    clock_t data_transfer_start, output_transfer_start, execution_start, time_taken;
    clock_t start;
    start = clock();
// ------------------------------------------------------------------------------------
// Step 1: Initialize the OpenCL environment 
// the host detects the attached Xilinx device, loads the FPGA binary (.xclbin file) from file and programs it into the first Xilinx device it found
// ------------------------------------------------------------------------------------ 
    cl_int err;
    cl_ulong time_start, time_end, exec_time;
    cl::Event timing_event;

    std::string binaryFile = (argc != 2) ? "systolic_fpga.hw.xclbin" : argv[1];
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
    
    cl::Buffer base_address(context, CL_MEM_ALLOC_HOST_PTR | CL_MEM_READ_ONLY, sizeof(int) * TOTAL_DATA_NUM, NULL, &err);
    // cl::Buffer outputs(context, CL_MEM_ALLOC_HOST_PTR | CL_MEM_READ_WRITE, sizeof(int)*32, NULL, &err); 
    // cl::Buffer simd_outputs(context, CL_MEM_ALLOC_HOST_PTR | CL_MEM_READ_WRITE, SIMD_OFFSET + sizeof(int) * NUM_OUTPUT, NULL, &err);

    int *base_ptr = (int *)q.enqueueMapBuffer(base_address, CL_TRUE, CL_MAP_WRITE, 0, sizeof(int) * TOTAL_DATA_NUM);
    // int *output_ptr = (int *)q.enqueueMapBuffer(outputs, CL_TRUE, CL_MAP_WRITE | CL_MAP_READ, 0, sizeof(int)*32);
    // int *simd_output_ptr = (int *)q.enqueueMapBuffer(simd_outputs, CL_TRUE, CL_MAP_WRITE | CL_MAP_READ, 0, SIMD_OFFSET + sizeof(int) * NUM_OUTPUT);
     
// ------------------------------------------------------------------------------------
// Step 3: Read instruction and input files to the respective buffers 
// ------------------------------------------------------------------------------------
    Json::Value data_info;
    Json::Value layer_input; 
    Json::Value layer_inst; 
    Json::Value layer_output;
    std::ifstream data_info_f (data_info_file, std::ifstream::binary); //TODO: Remove Hardcoding 
    Json::Reader reader ;
    reader.parse(data_info_f, data_info);
        
    Json::Value::iterator layer_iter;  
    Json::Value::iterator input_iter;  
    Json::Value::iterator output_iter;   
 
    // Fill Data
    std::vector<int> inst_offsets; 
    std::vector<std::string> inst_paths;   

    int num_blocks = 0;
    for (layer_iter = data_info.begin(); layer_iter != data_info.end(); ++layer_iter) {
        layer_input = (*layer_iter)["inputs"];
        for (input_iter = layer_input.begin(); input_iter != layer_input.end(); ++input_iter) {
            std::string path = base_path + (*input_iter)["path"].asString().substr(71);
            int offset = (*input_iter)["offset"].asInt()/4;
            read_data_file(path, base_ptr, offset, 0);
        }

        layer_inst = (*layer_iter)["instructions"];
        int inst_offset = (layer_inst)["offset"].asInt()/4;
        inst_offsets.push_back(inst_offset); 
        std::cout << "Offset " << inst_offset << "\n";
        
        std::string path = (layer_inst)["path"].asString();
        std::string inst_path = test_path + path.substr(104, (path.size()-16)-104) + "decimal.txt";
        inst_paths.push_back(inst_path);
        std::cout << "Path " << inst_path << "\n";

        num_blocks++; 
    }

    // Load insturction
    for (int i = 0 ; i<num_blocks;i++) { // order in reverse
        read_instructions_file(inst_paths[i], inst_offsets[i], base_ptr, 0);
    }


// // ------------------------------------------------------------------------------------
// // Step 4: Run the kernel
// // schedule three operations on the command queue: 
// //  1. the transfers of the three input vectors to device memory 
// //  2. the execution of the kernel
// //  3. lastly the transfer of the results back to host memory
// // ------------------------------------------------------------------------------------
 
    // Set kernel arguments
    std::cout << "Initialize registers" <<"\n";    
    for (int i = 0; i < 15; i++) {
        if (i != 2 && i!= 4)
            systolic_fpga_krnl.setArg(i, reg_initialize_val);    
    }

    systolic_fpga_krnl.setArg(2, NUM_INSTRUCTION); 
    systolic_fpga_krnl.setArg(4, NUM_OUTPUT); 
    systolic_fpga_krnl.setArg(15, base_address);
    // writing base address for now. Else getting seg fault    
    systolic_fpga_krnl.setArg(16, base_address);  
    systolic_fpga_krnl.setArg(17, base_address);   
    // systolic_fpga_krnl.setArg(18, outputs);
    // systolic_fpga_krnl.setArg(19, simd_outputs);
    systolic_fpga_krnl.setArg(18, base_address);  
    systolic_fpga_krnl.setArg(19, base_address);     

        
    // Schedule transfer of inputs to device memory, execution of kernel, and transfer of outputs back to host memory
    std::cout << "Transfer Data to DDR" <<"\n";
   
    // q.enqueueMigrateMemObjects({base_address, outputs, simd_outputs}, 0 ,NULL,&timing_event);
    q.enqueueMigrateMemObjects({base_address}, 0 ,NULL,&timing_event); 
    q.finish();
    timing_event.getProfilingInfo(CL_PROFILING_COMMAND_START, &time_start);
    timing_event.getProfilingInfo(CL_PROFILING_COMMAND_END,&time_end);
    exec_time = time_end-time_start;
    printf("Input Transfer Time: %.7lf \n", (double) exec_time/1000000000);
    printf("Input Transfer Cycles: %lf \n", (double) exec_time);
       
    std::cout << "Execute Program" <<"\n";
    stoptime(start, "set up kernel");
    start = clock();
    q.enqueueTask(systolic_fpga_krnl,NULL,&timing_event);
    q.finish();
    stoptime(start, "run kernel");
    timing_event.getProfilingInfo(CL_PROFILING_COMMAND_START, &time_start);
    timing_event.getProfilingInfo(CL_PROFILING_COMMAND_END,&time_end);
    exec_time = time_end-time_start;
    printf("Execution Time: %.7lf \n", (double) exec_time/1000000000);
    printf("Execution Cycles: %lf \n", (double) exec_time);

    std::cout << "Copy data from DDR" <<"\n";
   
    //q.enqueueMigrateMemObjects({simd_outputs,outputs}, CL_MIGRATE_MEM_OBJECT_HOST,NULL,&timing_event);
    q.enqueueMigrateMemObjects({base_address}, CL_MIGRATE_MEM_OBJECT_HOST,NULL,&timing_event);
    q.finish();
    timing_event.getProfilingInfo(CL_PROFILING_COMMAND_START, &time_start);
    timing_event.getProfilingInfo(CL_PROFILING_COMMAND_END,&time_end);
    exec_time = time_end-time_start;
    printf("Output Transfer Time: %.7lf \n", (double) exec_time/1000000000);
    printf("Output Transfer Cycles: %lf \n", (double) exec_time);
  
    q.finish();


// // ------------------------------------------------------------------------------------
// // Step 5: Check Results and Release Allocated Resources
// // ------------------------------------------------------------------------------------
    std::cout << "Output Comparision" <<"\n";
    int pc_offset = 0;
    int output_reference_arr[NUM_OUTPUT * 5];

    for (layer_iter = data_info.begin(); layer_iter != data_info.end(); ++layer_iter) {
        std::cout << "In Output Comparision" <<"\n";
        
        layer_output = (*layer_iter)["outputs"];
        for (output_iter = layer_output.begin(); output_iter != layer_output.end(); ++output_iter) {
            std::string path = base_path + (*output_iter)["path"].asString().substr(71);
            int output_offset = (*output_iter)["offset"].asInt()/4;
            // std::cout << path << " " << output_offset << "\n";
            read_data_file(path, output_reference_arr, 0, 0);
        
            //int output_offset = 0;
            bool match0 = true; //OBUF
            bool match1 = true; //SIMD

            //Checking OBUF output
            // for (int i =  0  ; i < num_output ; i++){
            //     int expected = output_reference_arr[i];
            //     if (output_ptr[output_offset+i] != expected){
            //         std::cout << "Error: Result mismatch" << std::endl;
            //         std::cout << "i = " << i << " CPU result = " << expected << " Device result = " << output_ptr[output_offset+i] << std::endl;
            //         match0 = false;
            //         break;
            //     }	
            // }

            // //Checking SIMD output
            // for (int i =  0  ; i < num_output ; i++){
            //     int expected = output_reference_arr[i];      
            //     if (simd_output_ptr[output_offset+i] != expected){
            //         std::cout << "Error: Result mismatch" << std::endl;
            //         std::cout << "i = " << i << " CPU result = " << expected << " Device result = " << simd_output_ptr[output_offset+i] << std::endl;
            //         match1 = false;
            //         break;
            //     }
            // }

            //Checking OBUF output
            for (int i =  0  ; i < num_output ; i++){
                int expected = output_reference_arr[i];
                if (base_ptr[output_offset+i] != expected){
                    std::cout << "Error: Result mismatch" << std::endl;
                    std::cout << "i = " << i << " CPU result = " << expected << " Device result = " << base_ptr[output_offset+i] << std::endl;
                    match0 = false;
                    break;
                }	
            }

            //Checking SIMD output
            for (int i =  0  ; i < num_output ; i++){
                int expected = output_reference_arr[i];      
                if (base_ptr[output_offset+i] != expected){
                    std::cout << "Error: Result mismatch" << std::endl;
                    std::cout << "i = " << i << " CPU result = " << expected << " Device result = " << base_ptr[output_offset+i] << std::endl;
                    match1 = false;
                    break;
                }
            }

            // q.enqueueMigrateMemObjects({base_address}, CL_MIGRATE_MEM_OBJECT_HOST,NULL,&timing_event);
            // q.finish();
            
            int count = 0;
            for (int i =  0+pc_offset  ; i < 96+pc_offset ; i+=16) {
                int local_i = i ;
                int value = 0;
                if (count ==0) { 
                    value = base_ptr[local_i];
                    std::cout << "pc_num_tiles: " << value <<  std::endl;
                    local_i+=1 ;
                    value = base_ptr[local_i];
                    std::cout << "pc_simd_tot_compute: " << value <<  std::endl;
                    local_i+=1 ;
                    value = base_ptr[local_i];
                    std::cout << "pc_sys_tot_compute: " << value <<  std::endl;
                    local_i+=1 ;
                //  value = base_ptr[local_i];
                //  std::cout << "pc_sys_tot_compute: " << value <<  std::endl;
                //  local_i+=2 ;
                    value = base_ptr[local_i];
                    std::cout << "pc_end2end: " << value <<  std::endl;
                    local_i+=1 ;
                    value = base_ptr[local_i];
                    std::cout << "pc_state: " << value <<  std::endl;
                }
                else if (count ==1){
                    value = base_ptr[local_i];
                    std::cout << "pc_ibuf_size_per_requests: " << value <<  std::endl;
                    local_i+=2 ;
                    value = base_ptr[local_i];
                    std::cout << "pc_ibuf_tot_requests: " << value <<  std::endl;
                    local_i+=2 ;
                    value = base_ptr[local_i];
                    std::cout << "pc_ibuf_tot_cycles: " << value <<  std::endl;
                    local_i+=2 ;
                    value = base_ptr[local_i];
                    std::cout << "pc_ibuf_num_tiles: " << value <<  std::endl;
                }

                else if (count ==2){
                    value = base_ptr[local_i];
                    std::cout << "pc_obuf_st_size_per_requests: " << value <<  std::endl;
                    local_i+=2 ;
                    value = base_ptr[local_i];
                    std::cout << "pc_obuf_st_tot_requests: " << value <<  std::endl;
                    local_i+=2 ;
                    value = base_ptr[local_i];
                    std::cout << "pc_obuf_st_tot_cycles: " << value <<  std::endl;
                    local_i+=2 ;
                    value = base_ptr[local_i];
                    std::cout << "pc_obuf_st_num_tiles: " << value <<  std::endl;
                    local_i+=2 ;
                    value = base_ptr[local_i];
                    std::cout << "pc_obuf_ld_size_per_requests: " << value <<  std::endl;
                    local_i+=2 ;
                    value = base_ptr[local_i];
                    std::cout << "pc_obuf_ld_tot_requests: " << value <<  std::endl;
                    local_i+=2 ;
                    value = base_ptr[local_i];
                    std::cout << "pc_obuf_ld_tot_cycles: " << value <<  std::endl;
                    local_i+=2 ;
                    value = base_ptr[local_i];
                    std::cout << "pc_obuf_ld_num_tiles: " << value <<  std::endl;
                }
                else if (count ==3){
                    value = base_ptr[local_i];
                    std::cout << "pc_bbuf_size_per_requests: " << value <<  std::endl;
                    local_i+=2 ;
                    value = base_ptr[local_i];
                    std::cout << "pc_bbuf_tot_requests: " << value <<  std::endl;
                    local_i+=2 ;
                    value = base_ptr[local_i];
                    std::cout << "pc_bbuf_tot_cycles: " << value <<  std::endl;
                    local_i+=2 ;
                    value = base_ptr[local_i];
                    std::cout << "pc_bbuf_num_tiles: " << value <<  std::endl;
                    local_i+=2 ;
                    value = base_ptr[local_i];
                    std::cout << "pc_wbuf_size_per_requests: " << value <<  std::endl;
                    local_i+=2 ;
                    value = base_ptr[local_i];
                    std::cout << "pc_wbuf_tot_requests: " << value <<  std::endl;
                    local_i+=2 ;
                    value = base_ptr[local_i];
                    std::cout << "pc_wbuf_tot_cycles: " << value <<  std::endl;
                    local_i+=2 ;
                    value = base_ptr[local_i];
                    std::cout << "pc_wbuf_num_tiles: " << value <<  std::endl;
                }
                else if (count ==4){
                    value = base_ptr[local_i];
                    std::cout << "pc_vmem1_st_size_per_requests: " << value <<  std::endl;
                    local_i+=2 ;
                    value = base_ptr[local_i];
                    std::cout << "pc_vmem1_st_tot_requests: " << value <<  std::endl;
                    local_i+=2 ;
                    value = base_ptr[local_i];
                    std::cout << "pc_vmem1_st_tot_cycles: " << value <<  std::endl;
                    local_i+=2 ;
                    value = base_ptr[local_i];
                    std::cout << "pc_vmem1_st_num_tiles: " << value <<  std::endl;
                    local_i+=2 ;
                    value = base_ptr[local_i];
                    std::cout << "pc_vmem1_ld_size_per_requests: " << value <<  std::endl;
                    local_i+=2 ;
                    value = base_ptr[local_i];
                    std::cout << "pc_vmem1_ld_tot_requests: " << value <<  std::endl;
                    local_i+=2 ;
                    value = base_ptr[local_i];
                    std::cout << "pc_vmem1_ld_tot_cycles: " << value <<  std::endl;
                    local_i+=2 ;
                    value = base_ptr[local_i];
                    std::cout << "pc_vmem1_ld_num_tiles: " << value <<  std::endl;
                }
                else if (count ==5){
                    value = base_ptr[local_i];
                    std::cout << "pc_vmem2_st_size_per_requests: " << value <<  std::endl;
                    local_i+=2 ;
                    value = base_ptr[local_i];
                    std::cout << "pc_vmem2_st_tot_requests: " << value <<  std::endl;
                    local_i+=2 ;
                    value = base_ptr[local_i];
                    std::cout << "pc_vmem2_st_tot_cycles: " << value <<  std::endl;
                    local_i+=2 ;
                    value = base_ptr[local_i];
                    std::cout << "pc_vmem2_st_num_tiles: " << value <<  std::endl;
                    local_i+=2 ;
                    value = base_ptr[local_i];
                    std::cout << "pc_vmem2_ld_size_per_requests: " << value <<  std::endl;
                    local_i+=2 ;
                    value = base_ptr[local_i];
                    std::cout << "pc_vmem2_ld_tot_requests: " << value <<  std::endl;
                    local_i+=2 ;
                    value = base_ptr[local_i];
                    std::cout << "pc_vmem2_ld_tot_cycles: " << value <<  std::endl;
                    local_i+=2 ;
                    value = base_ptr[local_i];
                    std::cout << "pc_vmem2_ld_num_tiles: " << value <<  std::endl;
                }
                count++;
            }
            std::cout << "TEST " << ((match0 || match1) ? "PASSED" : "FAILED") << std::endl; 
        }
        pc_offset += 0;
    }
    
    delete[] fileBuf;
    return EXIT_FAILURE ;
//   return ((match0 || match1 || match2) ? EXIT_SUCCESS : EXIT_FAILURE);
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
    //std::cout << "INFO: Loading '" << xclbin_file_name << "'\n";
    std::ifstream bin_file(xclbin_file_name.c_str(), std::ifstream::binary);
    bin_file.seekg (0, bin_file.end);
    nb = bin_file.tellg();
    bin_file.seekg (0, bin_file.beg);
    char *buf = new char [nb];
    bin_file.read(buf, nb);
    return buf;
}

void read_instructions_file(const std::string &file_name,const int ptr, int *arr, int debug_flag) 
{
    if(access(file_name.c_str(), R_OK) != 0) {
        printf("ERROR: %s Error reading file \n", file_name.c_str());
        exit(EXIT_FAILURE);
    } 
    std::cout << "INFO: Reading File '" << file_name << "'\n";
    std::ifstream fp(file_name.c_str());
    
    std::string line;
    int local_ptr = ptr ;
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
            
            arr[local_ptr++] = (uint)longLine;
	        idx++ ;

            if (((uint)longLine == 2952790017) or ((uint)longLine == 2952790016))
                break;        
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
    // std::cout << "INFO: Reading File '" << file_name << "'\n";
    std::fstream fp(file_name.c_str(), std::ios_base::in);
    
    int local_ptr = ptr;
    long long line;
    int idx = 0;
    while (fp >> line) {
        arr[local_ptr] = (uint) line;
        // if (get_num_lines)
        // 	std::cout << arr +4*local_ptr << "\n" << std::endl ;
        local_ptr++;
	    idx++ ;
    }
    if (get_num_lines) {
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

void stoptime (clock_t start, char msg[])
{
    clock_t end;
    double cpu_time_used;
    end = clock();
    cpu_time_used = ((double) (end - start))/CLOCKS_PER_SEC;
    printf("CPU time used for %s =  %.7lf \n", msg, cpu_time_used);
}

