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

To install any needed dependencies please proceed to the installation directory. In this directory, you will find a setup script as well as the needed .yml file to create a conda environment to run GeneSys in. Please run this setup script which will create a conda env for you. 

# Installation
Please refer to the README in the compiler folder! You will find step by step instructions there!


# Example Flow:


