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

# Conda Environment Installation

To install any needed dependencies please proceed to the installation directory. In this directory, you will find a setup script as well as the needed .yml file to create a conda environment to run GeneSys in. Please run this setup script which will create a conda env for you. 

# Compiler Installation

The GeneSys compiler uses an embedded architecture description language to create a Hierarchical Architecture Graph for flexibly compiling _mg_-DFGs to different architectures. The GeneSys architecture uses a systolic array centric approach that forms the core convolution engine for implementing DNN algorithms, and can be customized to  run a range of standard DNN topologies.

This document will help you get up and running.  

### Step 0: Check prerequisites
The following dependencies must be met by your system:
  * python >= 3.7 (For [PEP 560](https://www.python.org/dev/peps/pep-0560/) support)

### Step 1: Clone the Codelets Src code
  ```console
  $ git clone --recurse-submodules https://github.com/he-actlab/codelets.src
  $ cd codelets.src
  ```
### Step 2: Create a [Python virtualenv](https://docs.python.org/3/tutorial/venv.html)
Note: You may choose to skip this step if you are doing a system-wide install for multiple users.
      Please DO NOT skip this step if you are installing for personal use and/or you are a developer.
```console
$ python -m venv general
$ source general/bin/activate
$ python -m pip install pip --upgrade
```
### Step 3: Install GeneSys
If you already have a working installation of Python 3.7 or Python 3.8, the easiest way to install GeneSys is:
```console
$ pip install -e .
```
# Example Flow:


