![GeneSys Image](https://actlab-genesys.github.io/home/assets/images/genesys-logo.jpg)
# General Overview

Genesys is a programmable Deep Neural Networks (DNN) accelerator generator. The core computation engines in GeneSys
are a systolic array (for operations such as convolution) and a SIMD array (for operations such as ReLU and pooling). 
GeneSys is parametrizable, and it is possible to automatically generate hardware with different numbers of processing 
elements, bit-widths, on-chip buffer configurations and memory bandwidth. GeneSys acts like a co-processor connected
to the host via the PCIe bus. The below figure demonstrates a high level diagram of GeneSys:
![High Level Diagram](https://raw.githubusercontent.com/actlab-genesys/GeneSys/new-organization/overview/framework_diagram/high_level_diagram.jpg?token=GHSAT0AAAAAACJSA5EWXZP7HRIO3VR2ANSOZK7RI5Q)


The target workloads for GeneSys are CNNs, RNNs/LSTM and Transformers.

# Architecture
![Architecture Diagram](https://raw.githubusercontent.com/actlab-genesys/GeneSys/new-organization/overview/architecture/systolic_array_architecture.jpg?token=GHSAT0AAAAAACJSA5EX2MOH5RJEX4CFMTUOZK7RF6Q)

(Rohan/Hanyang - Insert commentary on architecture here)

# Compiler Organization
![Compiler Flow](https://raw.githubusercontent.com/actlab-genesys/GeneSys/new-organization/overview/compiler_organization/compiler_flow.jpg?token=GHSAT0AAAAAACJSA5EXUOOG2BZEZ5GIPQD4ZK7RH5Q)

(Chris - Insert commentary here)

# Software Requirements

To install any needed dependencies please proceed to the installation directory. In this directory, you will find a setup script as well as the needed .yml file to create a conda environment to run GeneSys in. Please run this setup script which will create a conda env for you. 

# Installation
Please refer to the README in the compiler folder! You will find step by step instructions there!


# Example Flow:


