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

Note: For RTL Simulation the DNN accelerator's memory channels require an AXI Slave Verification IP.
      We have used Xilinx AXI Verification IP (https://www.xilinx.com/products/intellectual-property/axi-vip.html).


# Running tests on RTL Simulator:

* Step 1. Clone this repo. <br />
* Step 2. Choose a configuration for your test. For eg. if you want to run a test on a 16x16 systolic array,  <br />
          edit genesys_systolic/source/config.vh to ensure that ARRAY_N and ARRAY_M are set to 16.  <br />
          Also make sure that the compiler is configured for 16 x 16 systolic array. Once you had compiled the instructions. 
* Step 3. Open genesys_systolic/testbench/generic_tb_files/systolic_fpga_benchmark_config.vh and add an entry with  <br />
          the respective instruction, input and output files generated from the compiler. You could use one of the example entries too for sanity check or as an example. <br />
          Ensure you use absolute paths to avoid errors. Ensure valid paths are given for all the file  <br /> variables as shown in the template even if it is not applicable to your test. For eg. ADD_ONLY  <br />
          test does not need a bias input, nevertheless a valid path is given for the variable.  <br />
* Step 4. Start Vivado and add all the files in the subdirectories of genesys_systolic/source/ and  <br />
          genesys_systolic/testbench/generic_tb_files/ as sources.  <br />
* Step 5. You will need to generate the AXI Verification IPs for running simulation. In Vivado,  <br />
          go to IP Catalog and look for AXI Verification IP. Six AXI VIPs need to be created and use  <br />
          the same names as below. This might require a Xilinx Vivado License. <br />

# Example: Running RESNET50 Layers on 16 x 16 Configuration:

* Step 1. Clone this repo. <br />
* Step 2. Download pre-compiled Resnet50 Layers from testcases/benchmarks/benchmark.md<br />
* Step 3. Open genesys_systolic/testbench/generic_tb_files/systolic_fpga_benchmark_config.vh and add an entry with  <br />
          the respective instruction, input and output files generated from the compiler similar to one of the example entries already present in the file. <br />
          Ensure you use absolute paths to avoid errors. Ensure valid paths are given for all the file  <br /> variables as shown in the template even if it is not applicable to your test.
* Step 4. Start Vivado and add all the files in the subdirectories of genesys_systolic/source/ and  <br />
          genesys_systolic/testbench/generic_tb_files/ as sources.  <br />
* Step 5. You will need to generate the AXI Verification IPs for running simulation. In Vivado,  <br />
          go to IP Catalog and look for AXI Verification IP. Six AXI VIPs need to be created and use  <br />
          the same names as below. This might require a Xilinx Vivado License. <br />


|                                                  **Buffer Name**                                                 |                                                                          **Configuration**                                                                         |
|:----------------------------------------------------------------------------------------------------------------:|:------------------------------------------------------------------------------------------------------------------------------------------------------------------:|
| slv_m00_imem_axi_vip  slv_m01_parambuf_axi_vip  slv_m02_ibuf_axi_vip  slv_m03_obuf_axi_vip  slv_m04_simd_axi_vip | Type: Slave  AXI Type: AXI  Data width: 512  Address width: 64  Advanced options: WSTRB and   ARESETN are enabled (1), rest   are disabled (0)                     |
| control_systolic_fpga_vip                                                                                        | Type: Master  AXI Type: AXI-Lite  Data width: 32  Address width: 12  Advanced options: WSTRB,   RRESP, BRESP and ARESETN are  enabled (1), rest are disabled   (0) |


* Step 6. Run RTL Simulation with systolic_fpga_tb.sv testbench as the top module.  <br />
* Step 7. Once the simulation is over, the TCL Command window in Vivado should display "TEST PASSED". <br />


# Running tests on FPGA or FPGA Emulation:

** Requirements for running test of FPGA:  <br />
We use Xilinx FPGA, Xilinx XRT and Vitis to run tests on the FPGA. <br />

* The host/driver code uses OpenCL. Please make sure that you have OpenCL installed on your machine.  <br />
  You can use fpga_framework/host/openCL_version.cpp script to check the OpenCL version on your machine. <br />

Before running the below steps, please make sure that the FPGA is active and detectable. <br />
If using Xilinx FPGA compatible with Xilinx XRT, use xbutil query to check the FPGA status. <br />

For generating the FPGA binary:

* Step 1. cd fpga_framework. Modify TARGET in Makefile to “hw”. <br />
* Step 2. make pack_kernel. <br />
* Step 3. make build_hw (this launches Synthesis and Implementation on 6 cores by default).  <br />
          This would take several hours. As an alternative for just checking functionality and not 
          running on the FPGA, you may choose to do FPGA Emulation.  <br />
          
For generating FPGA Emulation binary:

* Step 1. cd fpga_framework. Modify TARGET in Makefile to “hw_emu”. <br />
* Step 2. make pack_kernel <br />
* Step 3. export XCL_EMULATION_MODE=hw_emu <br />
* Step 3. make build_hw <br />

Next to run the binary a software executable (host driver) should be built. For generating the executable: 

* Step 1. cd fpga_framework <br />
* Step 2. make build_sw (please pass the make parameter TEST_NAME="CONV_RELU" or TEST_NAME="CONV_ONLY"). <br />
* Step 3. ./CONV_RELU systolic_fpga.hw.xclbin (for FPGA) or ./CONV_RELU systolic_fpga.hw_emu.xclbin (for FPGA Emulation) <br />
* Step 4. If the test run was successful, "TEST PASSED" is displayed on the console. <br />

# Running regression test suite on FPGA or FPGA Emulation:

Once you have the binary instead of individually launching tests you may also use regression scripts to run multiple tests on either FPGA or FPGA Emulation.  <br />

Follow the below for using the scripts.  <br />

* Step 1. cd fpga_framework <br />
* Step 2. Ensure all your tests are in ./host/regression_config_SA_<c>x<c>.h , where “c” denotes the  configuration. <br />
          For example if your test requires a 16x16 systolic array use regression_config_SA_16x16.h. Ensure the same file is mentioned in line no. 10 of ./host/genesys_driver.h . Follow the template examples in regression_config_SA_16x16.h and add all your tests. <br />

* Step 3. Open scripts/compile_regression_emu.py (for emulation) or  scripts/compile_regression_fpga.py (for FPGA) and  
          add your tests to the list SA_<c>x<c>_reg_list <br />

* Step 4. python3 scripts/compile_regression_emu.py (for emulation) or python3 scripts/compile_regression_fpga.py (for FPGA) <br />

* Logs of the tests can be found in ./emu_logs . If the test passed it should say TEST_PASSED else TEST_FAILED.  <br />

Comprehensive metrics can be found in ./emu_logs/metrics.csv  <br />

For any questions, please feel free to send us an email at <br />
* rohan@ucsd.edu (Rohan Mahapatra)  <br />
* soghodra@eng.ucsd.edu (Soroush Ghodrati) <br />
