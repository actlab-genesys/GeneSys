![GeneSys Image](https://actlab-genesys.github.io/home/assets/images/genesys-logo.jpg)
# Overview

Genesys is a programmable Deep Neural Networks (DNN) accelerator generator. The core computation engines in GeneSys
are a systolic array (for operations such as convolution) and a SIMD array (for operations such as ReLU and pooling). 
GeneSys is parametrizable, and it is possible to automatically generate hardware with different numbers of processing 
elements, bit-widths, on-chip buffer configurations and memory bandwidth. GeneSys acts like a co-processor connected
to the host via the PCIe bus.

The target workloads for GeneSys are CNNs, RNNs/LSTM and Transformers.

This README describes how to run GeneSys on a local FPGA instance. We do support running on AWS as well. Please refer to the aws_guide for instructions.

# Software Requirements

OS: Ubuntu 18.04.4 LTS
RTL Simulation Tool: Xilinx Vivado 2020.2 and Xilinx Vitis 2020.2

Note: For RTL Simulation the DNN accelerator's memory channels require an AXI Slave Verification IP.
      We have used Xilinx AXI Verification IP (https://www.xilinx.com/products/intellectual-property/axi-vip.html).

# Installation
Please refer to the README in the compiler folder! You will find step by step instructions there!


# Example Flow:


