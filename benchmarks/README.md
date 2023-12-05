# DNN Benchmark CLI Guide
This guide provides instructions on how to use the Command Line Interface (CLI) for generating benchmarks for GeneSys. The CLI of the various scripts support many layers, subgraphs, and models.

## Micro Benchmarks `micro.py`
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
python3 micro.py <operation> <options>
```
Replace `<operation>` with one of the operation names (add, matmul, relu, transpose, etc.).

#### Specify Operation Arguments:
Each operation requires specific arguments. Append these arguments after the operation name in the command line. Arguments follow the pattern `--argument_name value`.

For example:

```bash
python3 micro.py add --input1_shape N,C,H,W --input2_shape N,C,H,W
```

For more information on the command line arguments for each operation, see the help menu for each operation by running `python3 micro.py <operation> -h`.
