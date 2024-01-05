<p align="center">
<img src="https://github.com/actlab-genesys/GeneSys/blob/main/docs/figures/genesys_logo.png" class="center">
</p>
# 1 Overview

Genesys is a programmable Deep Neural Networks (DNN) accelerator generator. The core computation engines in GeneSys
are a systolic array (for operations such as convolution) and a SIMD array (for operations such as ReLU and pooling). 
GeneSys is parametrizable, and it is possible to automatically generate hardware with different numbers of processing 
elements, bit-widths, on-chip buffer configurations and memory bandwidth. GeneSys acts like a co-processor connected
to the host via the PCIe bus. The below figure demonstrates a high level diagram of GeneSys:
<p align="center">
<img src="https://github.com/actlab-genesys/GeneSys/blob/main/docs/figures/GeneSys_overview.png" width="800" height="500" class="center">
</p>


The target workloads for GeneSys are CNNs, RNNs/LSTM and Transformers.

## 1.1 Architecture
The accelerator consists of two core components: a systolic array and a SIMD array. Data is supplied to the two engines through the input buffer (IBUF), output buffer (OBUF), instruction memory (IMEM), weight buffer (WBUF), bias buffer (BBUF) and vector memory (VMEM). These interfaces harbor programmable data access modules and controller FSMs that together issue the addresses and requests to load or store a tile of data from/to off-chip memory. The data access creates strided patterns that access the off-chip memory to read/write the corresponding data from/to on-chip buffers and populate the on-chip memory. These interfaces also include tag logic that is in charge of handling double-buffered data transfer to hide the latencies of load/store operations and also facilitate prefetching. Among these interfaces, the interfaces for the OBUF and SIMD array handle both load and store operations, while the other interfaces handle only load operations. These interfaces are fully programmable through the instruction set architecture (ISA) of the GeneSys accelerator. The overall system view of the GeneSys DNN accelerator is shown below.
<p align="center">
<img src="https://github.com/actlab-genesys/GeneSys/blob/main/docs/figures/high_level_diagram.jpg?raw=true" width="600" height="500" class="center">
</p>
Our systolic array configuration is characterized by a unified activation buffer that feeds input data into the system. Each PE in the array is also equipped with its own weight buffer bank. The output generated by the systolic array can be directed in two ways. It can either be stored directly to DRAM or it can be read by the SIMD array. The latter option allows for additional operations to be performed on the output data, such as activation functions or pooling. A diagram of our systolic array is shown below.
<p align="center">
<img src="https://github.com/actlab-genesys/GeneSys/blob/main/docs/figures/systolic_array_architecture.jpg?raw=true" width="700" height="500" class="center">
</p>

## 1.2 Compiler 
The compiler for GeneSys starts with an ONNX description of an ML algorithm and generates an intermediate representation (IR) in the form of a simultaneous-recursive dataflow graph (sr-DFG). The sr-DFG is a recursively defined dataflow graph which enables simultaneous access to all levels of operation granularity for flexibly compiling to different architectures. Once generated from an ONNX file, the sr-DFG is transformed to a series of parameterized operation kernels. The operation kernels are then transformed and optimized by applying an architecture description to the compilation process, which constrains kernel parameters based on hardware attributes such as memory size, bandwidth, and operation capabilities. Once the kernel parameters are evaluated, each statement in the kernel is used to generate sequences of instructions defined by the architecture abstraction. The compilation flow is shown below.
<p align="center">
<img src="https://github.com/actlab-genesys/GeneSys/blob/main/docs/figures/compiler_flow.jpg?raw=true" width="800" height="500" class="center">
</p>

## 1.3 ISA
GeneSys is a programmable accelerator which offers a large set of instructions such that it can accelerate DNNs. Directly supported operations include GEMM, convolution, non-linear activation functions, and pooling.

## 1.4 Verification Infrastructure
(Rohan/Hanyang)

# 2 Installation
## 2.1 Conda Environment
To install any needed dependencies please proceed to the installation directory. In this directory, you will find a setup script as well as the needed .yml file to create a conda environment to run GeneSys in. Please run this setup script which will create a conda env for you. 
```console
$ ./setup.sh
```
## 2.2 Compiler
The GeneSys compiler uses an embedded architecture description language to create a Hierarchical Architecture Graph for flexibly compiling _mg_-DFGs to different architectures. The GeneSys architecture uses a systolic array centric approach that forms the core convolution engine for implementing DNN algorithms, and can be customized to  run a range of standard DNN topologies.

### Step 0: Check prerequisites
The following dependencies must be met by your system:
  * python >= 3.7 (For [PEP 560](https://www.python.org/dev/peps/pep-0560/) support)
  * These dependencies should already be setup via the conda environment

### Step 1: Clone the Codelets Src code
If you already have a working installation of Python 3.7 or Python 3.8, then please proceed to the compiler directory and run the following:
```console
$ pip install -e .
```

# 3 GeneSys Flow

## 3.1 ONNX Model 
Please navigate to your desired ONNX model and download it. You should also be able to use Neutron to view a computation graph of the desired model (i.e. BERT, ResNet).

## 3.2 Compile Model
Go to the terminal that contains the ONNX model
Navigate to the ```GeneSys``` directory and run the following command to compile. Make sure to fill in ```ONNX_PATH``` with the path to the ONNX file:

```console
$ compile-genesys -m <ONNX_PATH> -e "default
```

You should see a new folder in the current working directory called ```genesys_compiler_output```.

In this directory, you can see the five different outputs that you will see for each layer in the output.

* ```_string_final.txt```: The assembly instructions
* ```_binary.txt```: The assembled assembly instructions as binary numbers
* ```_decimal.txt```: The assembled assembly instructions as decimal numbers
* ```_json.json```: Information about the tensor operands and codelet operations
* ```_operations_idx.txt```: Pseudocode for the codelet

## 3.3 RTL Simulation
### Step 0: Choose a configuration
Choose a configuration for your test. For example, if you want to run a test on a 16x16 systolic array, edit genesys_systolic/source/config.vh to ensure that ARRAY_N and ARRAY_M are set to 16. Also make sure that the compiler is configured for a 16x16 systolic array. Once you have compiled the instructions.

### Step 1: Add compiler instructions
Open genesys_systolic/testbench/generic_tb_files/systolic_fpga_benchmark_config.vh and add an entry with the respective instruction, input, and output files generated from the compiler. You could use one of the example entries too for sanity check or as an example. Ensure you use absolute paths to avoid errors. Ensure valid paths are given for all the file variables as shown in the template even if it is not applicable to your test. For example, ADD_ONLY test does not need a bias input, nevertheless, a valid path is given for the variable.

### Step 2: Launch Vivado
Start Vivado and add all the files in the subdirectories of genesys_systolic/source/ and genesys_systolic/testbench/generic_tb_files/ as sources.

### Step 3: Verify correct IPs
You will need to generate the AXI Verification IPs for running simulation. In Vivado, go to IP Catalog and look for AXI Verification IP. Six AXI VIPs need to be created and use the same names as below. This might require a Xilinx Vivado License.

## 3.4 RTL Emulation
### Step 1: Emulation Build
```console
$ cd ~/GeneSys/rtl/genesys_wrapper
$ export XCL_EMULATION_MODE=hw_emu
$ make clean
```
Proceed to the Makefile and set TARGET := hw_emu
```console
$ make pack_kernel
$ make build_hw
```
### Step 2: Emulation Run
Please proceed to the host_py directory.
```console
$ cd GeneSys/rtl/genesys_wrapper/host_py/
$ gvim host.py
```
Within this file, please set the data_info_file and base_path according to the desired .json file and base directory.
In addition, make sure the genesys_binary path is set to the hw_emu xclbin file. Finally run the following:
```console
$ python3 host.py
```

## 3.5 FPGA Prototyping
### Step 1: Edit Makefile
First we will need to build an xclbin file. To do this open the Makefile and edit Target to be hw . 
```console
$ cd ~/GeneSys/rtl/genesys_wrapper/
$ gvim Makefile
```
### Step 2: Unset Variables
If you ran emulation prior to this, please unset the XCL_EMULATION_MODE variable
```console
$ unset XCL_EMULATION_MODE
```

### Step 3: Build xclbin file
Please run the following commands to kick-off the bhild
```console
$ cd ~/GeneSys/rtl/genesys_wrapper
$ make clean
$ make pack_kernel
$ make build_hw
```

### Step 4: Running GeneSys using xclbin file
Edit host.py, which is inside host_py with the hardware xclbin file (rather than the emulation xclbin file).
Now run the following command:
```console
$ python3 host.py
```


## 3.6 ASIC Synthesis
### Step 0: 
Move read_rtl_genesys.tcl and run_dc_SIMD_4x4.tcl to a directory containing the needed rtl files which are listed in read_rtl_genesys.tcl

### Step 1: 
Run the following command to launch the compilation tool:
```console
$ dc_compiler
```
### Step 2:
Finally, run:
```console
$ source run_dc_genesys.tcl
```
