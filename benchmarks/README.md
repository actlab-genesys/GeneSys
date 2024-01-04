# Pre-Compiled Benchmarks
We pre-compiled some popular neural networks to help your experiment with GeneSys hardware. 

|Model Name|GeneSys Hardware Configuration|Link|
|-|-|-|
|Resnet50|Systolic Core PE: 16x16, Tandem Processor Lane: 16|[Link](https://drive.google.com/file/d/1_LzRrtGWsf8-AE91nQm20lGW702F4Whg/view?usp=sharing)|
|Bert|TBF|[Link]()|

# Download ONNX Models
The Open Neural Network Exchange (ONNX) is an open standard format created to represent machine learning models. GeneSys uses ONNX models to represent the neural networks, and as the required input to the GeneSys Compiler. This table provides the download link to the ONNX models we used to compile the benchmarks.

|Model Name|Link|Description|
|-|-|-|
|Resnet50|[Link](https://drive.google.com/file/d/1bKDu6PB0LcMCyJIfPLkS_GMek94ED-NX/view?usp=sharing)|TBF|
|Bert|[Link]()|TBF|

## Required ONNX Model Modification
Due to the GeneSys Compiler and architecture design choices and constriants, some modifications are required on the ONNX model. These modifications should not affect the model behavior.

### Dynamic Inputs
Describe how we remove dynamic inputs...

### Other Constaints
Tbf...

# Generate GeneSys Micro Benchmark using micro_benchmark_gen.py
This guide provides instructions on how to use the Command Line Interface (CLI) for generating benchmarks for GeneSys. The CLI of the various scripts support many layers, subgraphs, and models.

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
