# RTL Emulation
## Step 1: Emulation Build
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
## Step 2: Emulation Run
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

# FPGA Prototyping
## Step 1: Edit Makefile
First we will need to build an xclbin file. To do this open the Makefile and edit Target to be hw . 
```console
$ cd ~/GeneSys/rtl/genesys_wrapper/
$ gvim Makefile
```
## Step 2: Unset Variables
If you ran emulation prior to this, please unset the XCL_EMULATION_MODE variable
```console
$ unset XCL_EMULATION_MODE
```

## Step 3: Build xclbin file
Please run the following commands to kick-off the bhild
```console
$ cd ~/GeneSys/rtl/genesys_wrapper
$ make clean
$ make pack_kernel
$ make build_hw
```