![GeneSys Image](https://actlab-genesys.github.io/home/assets/images/genesys-logo.jpg)
# Overview

Genesys is a programmable Deep Neural Networks (DNN) accelerator generator. The core computation engines in GeneSys
are a systolic array (for operations such as convolution) and a SIMD array (for operations such as ReLU and pooling). 
GeneSys is parametrizable, and it is possible to automatically generate hardware with different numbers of processing 
elements, bit-widths, on-chip buffer configurations and memory bandwidth. GeneSys acts like a co-processor connected
to the host via the PCIe bus. The below figure demonstrates a high level diagram of GeneSys:

![High Level Diagram](https://github.com/actlab-genesys/GeneSys/blob/new-organization/overview/framework_diagram/GeneSys-Overview.PNG)



The target workloads for GeneSys are CNNs, RNNs/LSTM and Transformers.

## Architecture
![Architecture Diagram](https://github.com/actlab-genesys/GeneSys/blob/new-organization/overview/architecture/systolic_array_architecture.jpg?raw=true)

(Rohan/Hanyang - Insert commentary on architecture here)

## Compiler 
![Compiler Flow](https://github.com/actlab-genesys/GeneSys/blob/new-organization/overview/compiler_organization/compiler_flow.jpg?raw=true)

(Chris - Insert commentary here)

## ISA
(Rohan)

## Verification Infrastructure
(Rohan/Hanyang)

# Installation
## Conda Environment
To install any needed dependencies please proceed to the installation directory. In this directory, you will find a setup script as well as the needed .yml file to create a conda environment to run GeneSys in. Please run this setup script which will create a conda env for you. 
```console
$ ./setup.sh
```
## Compiler
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

# Example Flow - ResNet50

## Downloading an ONNX model
On your personal device, download the ResNet50 ONNX model [here](https://drive.google.com/file/d/12DxCALFbnzNg9NCMogKq92-MtNA-KMqf/view?usp=sharing).
Open Netron either using the client or in a web browser [here](https://netron.app/).
Click ```Open model``` in the center of the web page.
Navigate to the ResNet50 ONNX file you just downloaded and select it.
You should see a computation graph of a ResNet.

## Compile ResNet50
Go to the terminal that contains the ONNX model
Navigate to the ```GeneSys``` directory and run the following command to compile. Make sure to fill in ```ONNX_PATH``` with the path to the ResNet50 ONNX file:

```console
$ compile-genesys -m <ONNX_PATH> -e "default
```

You should see a new folder in the current working directory called ```genesys_compiler_output``` with the following structure.

```
genesys_compiler_output
	| resnet50_genesys16x16_default
		| layer0_conv_bias1
		| layer1_relu2
		| layer2_max_pool3
		| layer3_conv_bias4
		| layer4_relu5
		…
```

List the first layer called ```layer0_conv_bias1```. You should see the following structure.

```
layer0_conv_bias1
	| conv_bias1_binary.txt
	| conv_bias1_decimal.txt
	| conv_bias1_json.json
	| conv_bias1_operations_idx.txt
	| conv_bias1_string_final.txt
```

Here you can see the five different outputs that you will see for each layer in the output.

* ```_string_final.txt```: The assembly instructions
* ```_binary.txt```: The assembled assembly instructions as binary numbers
* ```_decimal.txt```: The assembled assembly instructions as decimal numbers
* ```_json.json```: Information about the tensor operands and codelet operations
* ```_operations_idx.txt```: Pseudocode for the codelet

## RTL Simulation
### Step 0: Choose a configuration
Choose a configuration for your test. For example, if you want to run a test on a 16x16 systolic array, edit genesys_systolic/source/config.vh to ensure that ARRAY_N and ARRAY_M are set to 16. Also make sure that the compiler is configured for a 16x16 systolic array. Once you have compiled the instructions.

### Step 1: Add compiler instructions
Open genesys_systolic/testbench/generic_tb_files/systolic_fpga_benchmark_config.vh and add an entry with the respective instruction, input, and output files generated from the compiler. You could use one of the example entries too for sanity check or as an example. Ensure you use absolute paths to avoid errors. Ensure valid paths are given for all the file variables as shown in the template even if it is not applicable to your test. For example, ADD_ONLY test does not need a bias input, nevertheless, a valid path is given for the variable.

### Step 2: Launch Vivado
Start Vivado and add all the files in the subdirectories of genesys_systolic/source/ and genesys_systolic/testbench/generic_tb_files/ as sources.

### Step 3: Verify correct IPs
You will need to generate the AXI Verification IPs for running simulation. In Vivado, go to IP Catalog and look for AXI Verification IP. Six AXI VIPs need to be created and use the same names as below. This might require a Xilinx Vivado License.

## RTL Emulation
### Step 1: Emulation Build
```console
$ cd GeneSys/rtl/genesys_wrapper
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

## Running on an FPGA
### Step 1: Edit Makefile
First we will need to build an xclbin file. To do this open the Makefile and edit Target to be hw . 
```console
$ cd GeneSys/rtl/genesys_wrapper/
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
$ cd /home/harsha/genesys_public/GeneSys/rtl/genesys_wrapper
$ make clean
$ make pack_kernel
$ make build_hw
```

### Step 4: Running GeneSys using xclbin file
Edit host.py, which is inside host_py with the hardware xclbin file (rather than the emulation xclbin file).
Now run the following command:
```console
> python3 host.py
```


## ASIC Synthesis
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
