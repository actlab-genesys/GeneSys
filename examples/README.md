# Example GeneSys Flow Using Resnet50
Here is an exmaple to walk throuh all pieces of GeneSys framework including the compilation, RTL simulation, RTL emulation, FPGA synthesis and implementation, and ASIC synthesis. As example, we uses Resnet50 as the model, a 16x16 Systoic Core, and a 16 lane Tandem Processor as the GeneSys hardware instance. 

## 1. ONNX Model 
Navigate to [benchmark](https://github.com/actlab-genesys/GeneSys/tree/new-organization/benchmarks) directory and download the Resnet50 ONNX mode from *Download ONNX Models* section. You can use Neutron to view a computation graph of this model.

## 2. Compile Model TBF
Go to the terminal that contains the ONNX model
Navigate to the ```GeneSys``` directory and run the following command to compile. Make sure to fill in ```ONNX_PATH``` with the path to the ONNX file:

```console
$ compile-genesys -m <ONNX_PATH> -e "default
```

You should see a new folder in the current working directory called ```genesys_compiler_output```.
TODO: We need to mention where the hardware configuration in entered.

## 3. Run Software Simulation TBF
### 3.1 Locate the Compiled Test
A test folder can be obtained by the following two method:
1. Download the pre-compiled benchmark provided in the benchmark folder
2. Compile your own tests following the instructions here TBF

As an example, we will use the resnet50 16x16 test to work through the procedure of running the GeneSys Software Simulator. We first download the resnet50 test from here and unzip it. The resuting test directory is organized by layer. In each layer directory, you can see the five different output file and one data directory. 

* ```_string_final.txt```: The assembly instructions
* ```_binary.txt```: The assembled assembly instructions as binary numbers
* ```_decimal.txt```: The assembled assembly instructions as decimal numbers
* ```_json.json```: Information about the tensor operands and codelet operations
* ```_operations_idx.txt```: Pseudocode for the codelet
* ```data```: Data directory that contains randomly generated golden input/output data for verification

Besides sub-directory for each layer, the test folder also contains an GeneSys Architecture config file ```modelname_arch_cfg.json```. This file contains the hardware specification that the compiler used to compile the test, the hardware configuration specified here must match the hardware configuration in step 3,

For all the following activity, we use ***layer0_conv_bias_relu1*** from the Resnet50 compiled layer as example. 

### 3.2 Configure the Systoic Core and Tandem Processor
Configure the Systolic and SIMD config files in the config directory

### 3.3 Run       
Ro run the simuator with the test, uses the following command format:
```console
python3 genesys_sim/genesys.py <config_path> <testdir> <csv_output_filename>
```

In the Resnet50 16x16 example, the command is:
```console
python3 genesys_sim/genesys.py configs/ testdir
```
For energy simulations, set --mode energy

## 4. RTL Simulation
In this section, we simulate one layer from the Resnet50 benchmark, ***layer0_conv_bias_relu1***, in RTL simulation using Vivado. Currently we support RTL simulation on Xilinx Vivado since we use Xilinx AXI Verificaition IP. 

### Step 1: Create a GeneSys Vivado Project  
Create an Vivado GeneSys project and add the files in the following directories as design sources, and set the systolic_fpga_tb.sv as top module.
 - *GeneSys/rtl/genesys_top_module*
 - *GeneSys/rtl/memory_interface*
 - *GeneSys/rtl/systolic_core*
 - *GeneSys/rtl/tandem*
 - *GeneSys/rtl/xilinx_macros*

### Step 2: Add and Configure the Architecture and Testbench Config File
Add the testbench configuration files in *GeneSys/rtl/testbench_config*. These config files need to be configured based on the generated instrution file in the *layer0_conv_bias_relu1*. We go through each test file here.

- *conv_bias_relu1_string_final.txt* inside the ***layer0_conv_bias_relu1*** folder from the compiled test

<p align="center">
<img src="https://github.com/actlab-genesys/GeneSys/blob/main/docs/figures/inst_systolic_addr.png" class="center">
</p>

Above figure is the readable string version of the instruction file. One of the info it specifies is the memory addresses for each buffer. The buffer addresses need to be copied to the testbench for the testbench to load/store data to the correct addresses. Line2 to line9 specify the dram address for the each buffer. Specificlly, WBUF represents weight buffer, OBUF represents output buffer, BBUF represents bias buffer, and IBUF represents the input buffer. 

Since each instruciton only has 16 bit for address, each buffer address requires two instructions to specify its 32 bit address. *SET_BASE_ADDR LOW* represents the lower 16 bit address and *SET_BASE_ADDR HIGH* represents the higher 16 bit address. The final address is calcluated as *MSB 16 bit address << 16 + LSB 16 bit address*. For example, input buffer address is $451<<16+40960=29597696$. As such, the weight buffer address is 229376, bias buffer is 430080, and output buffer is 0.

<p align="center">
<img src="https://github.com/actlab-genesys/GeneSys/blob/main/docs/figures/inst_tandem_addr.png" class="center">
</p>

Line 187 and 188 specify the DRAM store address for Tandem Processor. *ST_CONFIG_BASE_ADDR* means it is a store address. For layers that need to load data to tandem proceesor, *LD_CONFIG_BASE_ADDR* is used. *VMEM2* specifies the vmem the store operation is reading the data from. Each Tandem Processor lane has two sctrachpads *VMEM1* and *VMEM2*. The store address from *vmem2* in this case is 26210304.

- *config.vh*
<p align="center">
<img src="https://github.com/actlab-genesys/GeneSys/blob/main/docs/figures/config_vh.png" class="center">
</p>

Config.vh specfies the archiectural parameters for the GeneSys accelerator. *xBUF_DEPTH* specify the depth of a single bank of the scratchpad. *ARRAY_N* and *ARRAY_M* specify the PE dimension of the Systolic Core, *ARRAY_N* also specifies the lane count of the Tandem Processor. The dimension of the Systloic Core are required to match with the dimension of Tandem Processor. In this case, the Systolic Core is 16x16 and Tandem processor has 16 lanes. One thing to note is that the configuration Config.vh are required to match with the GeneSys Architecture config file used in compilation of the tests. 

- *systolic_fpga_benchmark_config.vh*
<p align="center">
<img src="https://github.com/actlab-genesys/GeneSys/blob/main/docs/figures/rtl_testbench_config.png" class="center">
</p>

This config file specify information used in the tesbench. It requires two sets of information. The first set is memory addresses which is from *Line10 to Line18*. We enter the memory address we computed in the previous section based on instruction to corresponding buffer vaiable. If some buffer is not used in the test, *obuf_ptr1_st_offset* for example, enter 0. *last_layer_obuf* need to be set to 1 if the final output is stored on obuf, and 0 if the final output is stgored on vmem.

The second set is file address to insturction and golden data files from *Line28 to Line 45*. Add an entry with the respective instruction, input, and output files generated from the compiler. You could use one of the example entries too for sanity check or as an example. Ensure you use absolute paths to avoid errors. Ensure valid paths are given for all the file variables as shown in the template even if it is not applicable to your test. For example, ADD_ONLY test does not need a bias input, nevertheless, a valid path is given for the variable.

### Step 3: Create and Configure AXI Verification IPs
We need to generate the AXI Verification IPs all the strachpads for running simulation. In Vivado, go to *IP Catalog* and look for *AXI Verification* IP. Six AXI VIPs need to be created and use the same names as below. This might require a Xilinx Vivado License. 
- control_systolic_fpga_vip
Configure the AXI Verificartion IP for controller as below. Name the IP *control_systolic_fpga_vip*
<p align="center">
<img src="https://github.com/actlab-genesys/GeneSys/blob/main/docs/figures/veri_ip_control_1.png" class="center">
</p>

<p align="center">
<img src="https://github.com/actlab-genesys/GeneSys/blob/main/docs/figures/veri_ip_control_2.png" class="center">
</p>


- slv_mxx_xbuf_axi_vip
Configure the AXI verification IP for sctrachpad buffers as follow, the names should be the following: *slv_m00_imem_axi_vip*, *slv_m01_parambuf_axi_vip*, *slv_m02_ibuf_axi_vip*, *slv_m03_obuf_axi_vip*, *slv_m04_simd_axi_vip*
<p align="center">
<img src="https://github.com/actlab-genesys/GeneSys/blob/main/docs/figures/veri_ip_buf_1.png" class="center">
</p>

<p align="center">
<img src="https://github.com/actlab-genesys/GeneSys/blob/main/docs/figures/veri_ip_buf_2.png" class="center">
</p>

### Step 4: Launch the Test


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
