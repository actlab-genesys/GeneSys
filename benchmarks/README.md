# Tandem Processor ASPLOS 2024 Benchmarks
## Overview
To facilitate baselining and benchmarking on the Tandem Processor for the research community, we have prepared the necessary artifacts, including ONNX models, the GeneSys compiler, and the GeneSys software simulator, to enable the reproduction of the benchmarks presented in the paper. The specific steps and commands are listed below, You will need to be approved for GeneSys access to complete this benchmark. Please fill out the Access Form here: [GeneSys Access Form](https://forms.gle/Co7YBvS9YFuTrNzg7).

## Step 0 Access ONNX Models
The Open Neural Network Exchange (ONNX) is an open standard format created to represent machine learning models. GeneSys uses ONNX models to represent the neural networks and as the required input to the GeneSys Compiler. We have prepared the ONNX model used in the Tandem Processor benchmark in Google Drive [here](https://drive.google.com/drive/folders/1gxfW-vH-OI1waZpQJzJ_D9fM9S9ya8pk?usp=sharing). The ONNX files used in the paper is available [here] (https://drive.google.com/drive/folders/1gxfW-vH-OI1waZpQJzJ_D9fM9S9ya8pk?usp=sharing). If you only want to recreate the benchmark numbers, you do not need to be approved for GeneSys Compiler, you will only need the GeneSys Simulator with the compiled binary available [here](https://drive.google.com/drive/folders/149fD_jE4BWHti3TS6D8Zr3dyuZbkUsu0?usp=sharing).

## Step 1 Compile the models:
After downloading the ONNX model, follow the steps [here](https://github.com/actlab-genesys/GeneSys.codelets/tree/main) in the GeneSys compiler repository to install the GeneSys compiler from the main branch. To compare ONNX models, you must specify the architecture configurations for the GeneSys Accelerator (Systolic Array and Tandem Processor). The configuration file can be found at: ``` GeneSys.codelets/genesys_configs/tandem-baseline-paper-config.json ```

After installing the GeneSys compiler, run the following command to compile the target ONNX model:
```bash
compile-genesys -v -f -m PATH-TO-ONNX-FILE -c genesys_configs/tandem-baseline-paper-config.json
```
This command will produce compiled code in a folder named after the onnx file under ``` GeneSys.codelets/genesys_compiler_output ```, you will need this for the next step.

## Step 2 Simulate the Compiled Models on GeneSys Software Simulator:

After compiling the models, follow the steps [here](https://github.com/actlab-genesys/GeneSys.sim) to install the GeneSys software simulator. To simulate a compiled model, you need to specify the architecture configurations for the GeneSys Accelerator (Systolic Array and Tandem Processor) that matches to the configuration provided to the compiler. These can be found at: ``` GeneSys.sim/configs/tandem-processor-asplos24/simd_config.json``` and ```GeneSys.sim/configs/tandem-processor-asplos24/systolic_config```.

After installing the GeneSys software simulator, run the following command to launch the GeneSys software simulator:
```bash
python genesys_sim/genesys.py configs/tandem-processor-asplos24/ PATH-TO-COMPILED-CODE_FOLDER --mode energy
```
The results will be saved to the test-results folder as a csv file. The file includes all useful statistics of the execution, including the tile size, number of tiles, total execution cycle, Systolic Array execution cycle, Tandem Processor execution cycle, and other more detailed statistics.

# Generate GeneSys Micro Benchmark using micro_benchmark_gen.py
This guide provides instructions on how to use the Command Line Interface (CLI) to generate benchmarks for GeneSys. The CLI of the various scripts supports many layers, subgraphs, and models.

## Micro Benchmarks `micro_benchmark_gen.py`
### Available Operations
The CLI supports the following operations:

* Element-wise Addition (`add`)
* Matrix Multiplication (`matmul`)
* Rectified Linear Unit (`relu`)
* Transpose (`transpose`)

### Usage
To use the CLI, follow these steps:

#### Invoke the CLI:

```bash
python3 micro_benchmark_gen.py <operation> <options>
```
Replace `<operation>` with one of the operation names (add, matmul, relu, transpose, etc.).

#### Specify Operation Arguments:
Each operation requires specific arguments. Append these arguments after the operation name in the command line. Arguments follow the pattern `--argument_name value`.

For example:

```bash
python3 micro_benchmark_gen.py add --input1_shape N,C,H,W --input2_shape N,C,H,W
```

For more information on the command line arguments for each operation, see the help menu for each operation by running `python3 micro_benchmark_gen.py <operation> -h`.
