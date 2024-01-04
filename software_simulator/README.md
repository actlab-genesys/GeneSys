# Running GeneSys Software Simulator
GeneSys Software Simulator is a python based software simulator of GeneSys hardware architecture. 

## 1. Locate the Compiled Test
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

## 2. Repo Setup:
* Clone the repo
* Add the path to the cloned repo to PYTHONPATH env variable

## 3. Configure the Systoic Core and Tandem Processor
Configure the Systolic and SIMD config files in the config directory

## 4. Run       
Ro run the simuator with the test, uses the following command format:
```console
python3 genesys_sim/genesys.py <config_path> <testdir> <csv_output_filename>
```

In the Resnet50 16x16 example, the command is:
```console
python3 genesys_sim/genesys.py configs/ testdir
```
For energy simulations, set --mode energy
