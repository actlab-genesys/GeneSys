#include <iostream>
#include <vector>
#include <CL/cl.hpp>

int main() {

    // Get the platforms
    std::vector<cl::Platform> platforms;
    cl::Platform::get(&platforms);

    // Loop over the number of platforms
    for ( size_t i = 0; i < platforms.size(); ++i ) {

        // Display the platform information
        std::cout << "Platform " << i+1 << ": "
                            << platforms[i].getInfo<CL_PLATFORM_NAME>()
        << "\n----------------------------------------------"
        << "\nVendor    : " << platforms[i].getInfo<CL_PLATFORM_VENDOR>()
        << "\nVersion   : " << platforms[i].getInfo<CL_PLATFORM_VERSION>();

        // Get the devices on the current platform
        std::vector <cl::Device> devices;
        platforms[i].getDevices( CL_DEVICE_TYPE_ALL , & devices);

        // Loop over the devices
        std::cout << "\n----------------------------------------------\n";
        for ( size_t j = 0; j < devices.size(); ++j ) {

            // Display the device information
            std::cout
            << "\n   Device " << j+1 << ": "
            <<          devices[j].getInfo< CL_DEVICE_NAME >()
            << "\n\t Device Version     : "
            <<          devices[j].getInfo< CL_DEVICE_VERSION >()
            << "\n\t OpenCL C Version   : "
            <<          devices[j].getInfo< CL_DEVICE_OPENCL_C_VERSION >()
            << "\n\t Compute Units      : "
            <<          devices[j].getInfo< CL_DEVICE_MAX_COMPUTE_UNITS >()
            << "\n\t Max Work Group Size: "
            <<          devices[j].getInfo< CL_DEVICE_MAX_WORK_GROUP_SIZE >()
            << "\n\t Clock Frequency    : "
            <<          devices[j].getInfo< CL_DEVICE_MAX_CLOCK_FREQUENCY >()
            << "\n\t Local Memory Size  : "
            <<          devices[j].getInfo< CL_DEVICE_LOCAL_MEM_SIZE >()
            << "\n\t Global Memory Size : "
            <<          devices[j].getInfo< CL_DEVICE_GLOBAL_MEM_SIZE >();

            // Check if the device supports double precision
            std::string str = devices[j].getInfo<CL_DEVICE_EXTENSIONS>();
            size_t found = str.find("cl_khr_fp64");
            std::cout << "\n\t Double Precision   : ";
            if ( found != std::string::npos ){ std::cout << "yes\n"; }
            else {                             std::cout <<  "no\n"; }
        }
        std::cout << "\n----------------------------------------------\n";
    }
//  std::cin.ignore();
    return 0;
}