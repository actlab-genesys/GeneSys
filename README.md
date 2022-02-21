# Overview

Genesys is a programmable Deep Neural Networks (DNN) accelerator generator. The core computation engines in GeneSys 
are a systolic array (for operations such as convolution) and a SIMD array (for operations such as ReLU and pooling). 
GeneSys is parametrizable, and it is possible to automatically generate hardware with different numbers of processing 
elements, bit-widths, on-chip buffer configurations and memory bandwidth. GeneSys acts like a co-processor connected 
to the host via the PCIe bus.

The target workloads for GeneSys are CNNs, RNNs/LSTM and Transformers.

# Software Requirements

OS: Ubuntu 18.04.4 LTS
RTL Simulation Tool: Xilinx Vivado 2020.2 and Xilinx Vitis 2020.2

Note: For RTL Simulation, the DNN accelerator's memory channels require an AXI Slave Verification IP. 
      We have used Xilinx AXI Verification IP (https://www.xilinx.com/products/intellectual-property/axi-vip.html).
      

# Running tests on RTL Simulator:

* Step 1. Clone this repo <br />
* Step 2. Open verif/systolic_array/systolic_fpga_benchmark_config.vh and make sure that the path to lines  <br />
        26 through 40 and 63 through 77 are accessible. You might need to add the absolute path depending on
        the simulator setup.<br />
* Step 3. (optional) To run ResNet50 GEMM, uncomment line 1. By default, it will run ResNet50 convolution layer.<br />
* Step 4. Open RTL Simulator (preferably Xilinx Vivado) and load all the files from *src* and *verif* directories.<br />
* Step 5. Run RTL Simulation with *systolic_fpga_tb.sv* testbench as the top module. Please ensure that the Xilinx 
        Verification IPs are present in the heirarchy. This might require a Xilinx Vivado License. <br />
* Step 6. Once the simulation is over, the TCL Command window in Vivado should display "TEST PASSED". <br />


# Running tests on FPGA:

** Requirements for running test of FPGA <br />
- We use Xilinx FPGA, Xilinx XRT and Vitis to run tests on the FPGA. <br />
- The host/driver code uses OpenCL. Please make sure that you have OpenCL installed on your machine.
  You can use fpga_framework/host/openCL_version.cpp script to check the OpenCL version on your machine. <br />
- Please replace the path pointing to the tests (lines 39-43, 58-62) on the file fpga_framework/host/genesys_driver.h with absolute paths. <br />

Before running the below steps, please make sure that the FPGA is active and detectable. <br />
If using Xilinx FPGA compatible with Xilinx XRT, use _xbutil_ _query_ to check the FPGA status. <br />

* Step 1. cd fpga_framework. <br />
* Step 2. make pack_kernel. <br /> 
* Step 3. make build_hw (this launches Synthesis and Implementation on 4 cores by default). <br />
* Step 4. make build_sw (please pass the make parameter TEST_NAME="resnet_gemm" or TEST_NAME="resnet_conv"). <br />
* Step 5. ./host/genesys_driver systolic_fpga.hw.xclbin (this runs the test on the FPGA). <br />
* Step 6. If the test run was successful, "TEST PASSED" is displayed on the console. 

For any questions, please feel free to send us an email at <br />
rohan@ucsd.edu or soghodra@eng.ucsd.edu  <br />
