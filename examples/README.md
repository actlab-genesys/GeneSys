# Example GeneSys Flow Using Resnet50
Here is an exmaple to walk throuh all pieces of GeneSys framework including the compilation, RTL simulation, RTL emulation, and ASIC synthesis. As example, we uses Resnet50 as the model, a 16x16 Systoic Core, and a 16 lane Tandem Processor as the GeneSys hardware instance. 

## 1 ONNX Model 
Navigate to [benchmark](https://github.com/actlab-genesys/GeneSys/tree/new-organization/benchmarks) directory and download the Resnet50 ONNX mode from ***Download ONNX Models*** section. You can use Neutron to view a computation graph of this model.

## 2 Compile Model TBF
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

TODO: We need to mention where the hardware configuration in entered.

## 3 Run Software Simulation
### 3.1 Locate the Compiled Test
A test folder can be obtained by the following two method:
1. Download the pre-compiled benchmark provided in the benchmark folder
2. Compile your own tests following the instructions here TBF

As an example, we will use the resnet50 16x16 test to work through the procedure of running the GeneSys Software Simulator. We first download the resnet50 test from here and unzip it. The resuting test directory is organized by layer. In each layer directory, you can see the five different outputs.

* ```_string_final.txt```: The assembly instructions
* ```_binary.txt```: The assembled assembly instructions as binary numbers
* ```_decimal.txt```: The assembled assembly instructions as decimal numbers
* ```_json.json```: Information about the tensor operands and codelet operations
* ```_operations_idx.txt```: Pseudocode for the codelet

Besides sub-directory for each layer, the test folder also contains an GeneSys Architecture config file ```modelname_arch_cfg.json```. This file contains the hardware specification that the compiler used to compile the test, the hardware configuration specified here must match the hardware configuration in step 3,

## 3.2 Configure the Systoic Core and Tandem Processor
Configure the Systolic and SIMD config files in the config directory

## 3.3 Run       
Ro run the simuator with the test, uses the following command format:
```console
python3 genesys_sim/genesys.py <config_path> <testdir> <csv_output_filename>
```

In the Resnet50 16x16 example, the command is:
```console
python3 genesys_sim/genesys.py configs/ testdir
```
For energy simulations, set --mode energy

## 4 RTL Simulation
### Step 0: Choose a configuration
Choose a configuration for your test. For example, if you want to run a test on a 16x16 systolic array, edit genesys_systolic/source/config.vh to ensure that ARRAY_N and ARRAY_M are set to 16. Also make sure that the compiler is configured for a 16x16 systolic array. Once you have compiled the instructions.

### Step 1: Add compiler instructions
Open genesys_systolic/testbench/generic_tb_files/systolic_fpga_benchmark_config.vh and add an entry with the respective instruction, input, and output files generated from the compiler. You could use one of the example entries too for sanity check or as an example. Ensure you use absolute paths to avoid errors. Ensure valid paths are given for all the file variables as shown in the template even if it is not applicable to your test. For example, ADD_ONLY test does not need a bias input, nevertheless, a valid path is given for the variable.

### Step 2: Launch Vivado
Start Vivado and add all the files in the subdirectories of genesys_systolic/source/ and genesys_systolic/testbench/generic_tb_files/ as sources.

### Step 3: Verify correct IPs
You will need to generate the AXI Verification IPs for running simulation. In Vivado, go to IP Catalog and look for AXI Verification IP. Six AXI VIPs need to be created and use the same names as below. This might require a Xilinx Vivado License.

## 5 RTL Emulation
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

## 6 FPGA Prototyping
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
