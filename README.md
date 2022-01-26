## Overview

Genesys is a programmable Deep Neural Networks (DNN) accelerator generator. The core computation engines in GeneSys 
are a systolic array (for operations such as convolution) and a SIMD array (for operations such as ReLU and pooling). 
GeneSys is parametrizable, and it is possible to automatically generate hardware with different numbers of processing 
elements, bit-widths, on-chip buffer configurations and memory bandwidth. GeneSys acts like a co-processor connected 
to the host via the PCIe bus.

The target workloads for GeneSys are CNNs, RNNs/LSTM and Transformers.

## Software Requirements

OS: Ubuntu 18.04.4 LTS
RTL Simulation Tool: Xilinx Vivado 2020.2 and Xilinx Vitis 2020.2

Note: For RTL Simulation, the DNN accelerator's memory channels require an AXI Slave Verification IP. 
      We have used Xilinx AXI Verification IP (https://www.xilinx.com/products/intellectual-property/axi-vip.html).
      

## Steps to simulate tests on GeneSys DNN Accelerators

Step 1. Clone this repo <br />
Step 2. Open verif/systolic_array/systolic_fpga_benchmark_config.vh and make sure that the path to lines  <br />
        26 through 40 and 63 through 77 are accessible. You might need to add the absolute path depending on
        the simulator setup.<br />
Step 3. (optional) To run ResNet50 GEMM, uncomment line 1. By default, it will run ResNet50 convolution layer.<br />
Step 4. Open RTL Simulator (preferably Xilinx Vivado) and load all the files from *src* and *verif* directories.<br />
Step 5. Run RTL Simulation with *systolic_fpga_tb.sv* testbench as the top module. Please ensure that the Xilinx 
        Verification IPs are present in the heirarchy. This might require a Xilinx Vivado License. <br />
Step 6. Once the simulation is over, the TCL Command window in Vivado should display "TEST PASSED". <br />
        
For any questions, please feel free to send us an email at <br />
rohan@ucsd.edu or soghodra@eng.ucsd.edu  <br />
