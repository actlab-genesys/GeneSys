# MICRO 2023 Compiler Demo
## Prerequisites
Ensure you have a working Python environment with the required dependencies, have cloned GeneSys, and have built the compiler.
If you are joining us for the MICRO tutorial, this should have already been done by the ```tutorial_setup.sh``` script.
Click [here](../../README.md) for instructions on how to do this.

## Compiling ResNet50
### Goals
* Compile ResNet50
* Change convolution layers’ loop order
* Change a convolution layer’s tiling
* Change max pool layers’ on-chip buffer use
* Turn-on layer fusion

### Compile ResNet50
On your personal device, download the ResNet50 ONNX model [here](https://drive.google.com/file/d/12DxCALFbnzNg9NCMogKq92-MtNA-KMqf/view?usp=sharing).
Open Netron either using the client or in a web browser [here](https://netron.app/).
Click ```Open model``` in the center of the web page.
Navigate to the ResNet50 ONNX file you just downloaded and select it.
You should see a computation graph of a ResNet.

Move the ONNX file to the AWS instance using this command. Make sure to fill in each of the fields:
```console
$ scp -i <KEY_FILE_PATH> <ONNX_PATH_ON_USER_DEVICE> centos@<PRIVATE_IP>:<ONNX_PATH_ON_AWS>
```

Go to the terminal you have connected to the AWS instance through.
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

### Change convolution layers' loop order
View ```conv_bias1_operations_idx.txt```. You can use ```cat``` to do this.

The following lines define the outer loops for this convolution operation:

```
5  (OC)loop0[0]: …
7  (N)loop1[1]: …
8  (IC)loop2[2]: …
9  (KH)loop3[3]: …
10 (KW)loop4[4]: …
12 (OH)loop5[5]: …
13 (OW)loop6[6]: …
```

Navigate to ```compiler/src/genesys_codelets/genesys/codelets``` and open ```systolic_array.py``` or open the file containing the codelets for systolic array operations directly using the following command:

```console
$ vi compiler/src/genesys_codelets/genesys/codelets/systolic_array.py
```

Search for ```conv2d_bias_unquantized``` function (```/conv2d_bias_unquantized``` in ```vi``` console).
Move down 30 lines or so and you should see the following.

```python
with cdlt.loop(OC) as oc:
    with cdlt.loop(N) as n:
        with cdlt.loop(IC) as ic:
            with cdlt.loop(KH) as kh:
                with cdlt.loop(KW) as kw:
                    with cdlt.loop(OH) as y:
                        with cdlt.loop(OW) as x:
```

The loop order in the ```conv2d_bias_unquantized``` codelet is reflected in ```conv_bias1_operations_idx.txt```.

Switch the two outer loops. For example:

```python
with cdlt.loop(OC) as oc:
	with cdlt.loop(N) as n:
```

to

```python
with cdlt.loop(N) as n:
	with cdlt.loop(OC) as oc:
```

Navigate back to the ```GeneSys``` directory and run the following command to compile. Make sure to fill in ```ONNX_PATH``` with the path to the ResNet50 ONNX file.

```console
$ compile-genesys -m <ONNX_PATH> -e "loop_order"
```

You should see a new folder under ```genesys_compiler_output```:

```
genesys_compiler_output
	| resnet50_genesys16x16_default
	| resnet50_genesys16x16_loop_order
		| layer0_conv_bias1
		| layer1_relu2
		| layer2_max_pool3
		| layer3_conv_bias4
		| layer4_relu5
		…
```

View ```conv_bias1_operations_idx.txt``` for this new output. You can use ```cat``` to do this.
You should see that the loop order has changed to what was defined in the codelet.

```
5  (N)loop0[0]: …
6  (OC)loop1[1]: …
8  (IC)loop2[2]: …
9  (KH)loop3[3]: …
10 (KW)loop4[4]: …
12 (OH)loop5[5]: …
13 (OW)loop6[6]: …
```

### Change a convolution layer's tiling
Open ```conv_bias1_json.json``` under the first layer of either of the previous outputs.
Search for the ```tile_splits``` field (```/tile_splits``` in ```vi```).
You should see something similar to the following, though it can vary slightly. The ```IC```, ```OC```, ```N```, ```KH```, and ```KW``` dimensions should not be tiled.

```
"tile_splits": {
    "N": 1,
    "OC": 1,
    "IC": 1,
    "KH": 1,
    "KW": 1,
    "OH": 2,
    "OW": 112
},
```

Navigate back to the ```GeneSys``` directory and open a new file called ```tiling.json```. Add the following contents:

```
{
    "conv_bias1": {
		"1": {
			"OC": 1,
			"IC": 1,
			"N": 1,
			"KH": 1,
			"KW": 1,
			"OH": 112,
			"OW": 112
		}
	}
}
```

The first-level key specifies the name of the layer you want to set tiling for. The second-level key specifies the level you want to set the tiling for. For most purposes, only level 1 will need to be set and the rest will be automatically done. The third-level key specifies the dimension. Each key-value pair here defines the number of tiles for that dimension.

Run the following command to compile. Make sure to fill in ```ONNX_PATH``` with the path to the ResNet50 ONNX file.

```console
$ compile-genesys -m <ONNX_PATH> -t "tiling.json" -e "tiling"
```

You should see a new folder under ```genesys_compiler_output```:

```
genesys_compiler_output
	| resnet50_genesys16x16_default
	| resnet50_genesys16x16_loop_order
	| resnet50_genesys16x16_tiling
		| layer0_conv_bias1
		| layer1_relu2
		| layer2_max_pool3
		| layer3_conv_bias4
		| layer4_relu5
		…
```

Open ```conv_bias1_json.json``` under the first layer of the new output. 
Search for the ```tile_splits``` field (```/tile_splits``` in ```vi```).
You should see that the tiling has changed to what you set it to.

```
"tile_splits": {
    "N": 1,
    "OC": 1,
    "IC": 1,
    "KH": 1,
    "KW": 1,
    "OH": 112,
    "OW": 112
},
```

### Change max pool layers’ on-chip buffer use
View ```max_pool3_operations_idx.txt``` under the first layer of either of the previous outputs.  You can use ```cat``` to do this.

This following line defines the ```DRAM``` (off-chip) to ```VMEM``` (on-chip) transfer for this operation:

```
9 transfer0: OPERAND: data[DRAM->VMEM1], …
```

Navigate to ```compiler/src/genesys_codelets/genesys/codelets``` and open ```dnn.py``` or open the file containing the codelets for DNN-specific operations directly using the following command:

```console
$ vi compiler/src/genesys_codelets/genesys/codelets/dnn.py
```

Search for ```maxpool2d``` function (```/maxpool2d``` in ```vi``` console).
Move down 20 lines or so and you should see the following:

```
cdlt.transfer(data, ["DRAM", "VMEM1"])
```

The off-chip to on-chip input data transfer in the ```maxpool2d``` codelet is reflected in ```max_pool3_operations_idx.txt```.

Change the transfer to go from ```DRAM``` to ```VMEM2```. For example:

```python
…
cdlt.transfer(data, ["DRAM", "VMEM1"])
…

```

to 

```python
…
cdlt.transfer(data, ["DRAM", "VMEM2"])
…
```

Navigate back to the ```GeneSys``` directory and run the following command to compile. Make sure to fill in ```ONNX_PATH``` with the path to the ResNet50 ONNX file.

```console
$ compile-genesys -m <ONNX_PATH> -e "on_chip_use"
```

You should see a new folder under ```genesys_compiler_output```:

```
genesys_compiler_output
	| resnet50_genesys16x16_default
	| resnet50_genesys16x16_loop_order
	| resnet50_genesys16x16_tiling
	| resnet50_genesys16x16_on_chip_use
		| layer0_conv_bias1
		| layer1_relu2
		| layer2_max_pool3
		| layer3_conv_bias4
		…
```

Navigate back to the ```GeneSys``` directory and run the following command to compile. Make sure to fill in ```ONNX_PATH``` with the path to the ResNet50 ONNX file.

```console
$ compile-genesys -m <ONNX_PATH> -f -e "fused"
```

You should see a new folder under ```genesys_compiler_output```:

```
genesys_compiler_output
	| resnet50_genesys16x16_default
	| resnet50_genesys16x16_loop_order
	| resnet50_genesys16x16_tiling
	| resnet50_genesys16x16_on_chip_use
	| resnet50_genesys16x16_fused
		| layer0_conv_bias_relu1
		| layer1_max_pool2
		| layer2_conv_bias_relu3
		…
```

## Compiling BERT
### Goals
* Compile BERT

### Compile BERT
On your personal device, download the BERT ONNX model [here](https://drive.google.com/file/d/1iFv_gsh4xO1gvOcVKJEHBuuy8-nRuyOF/view?usp=sharing).
Open Netron either using the client or in a web browser [here](https://netron.app/).
Click ```Open model``` in the center of the web page.
Navigate to the BERT ONNX file you just downloaded and select it.

Move the ONNX file to the AWS instance using this command. Make sure to fill in each of the fields:
```console
$ scp -i <KEY_FILE_PATH> <ONNX_PATH_ON_USER_DEVICE> centos@<PRIVATE_IP>:<ONNX_PATH_ON_AWS>
```

Go to the terminal you have connected to the AWS instance through.
Navigate to the ```GeneSys``` directory and run the following command to compile. Make sure to fill in ```ONNX_PATH``` with the path to the BERT ONNX file:

```console
$ compile-genesys -m <ONNX_PATH> -e "default"
```

You should see a new folder in the current working directory called ```genesys_compiler_output``` with the following structure.

```
genesys_compiler_output
	…
	| bert-base-cased_genesys16x16_default
		| layer0_elem_add3d3d1
		| layer1_elem_sub_const2
		| layer2_elem_add3d3d3
		| layer3_elem_mul_const4
		…
```

## Conclusion
In this activity, you learned how to perform basic compilation from the command line for GeneSys.
The compiler also provides a similar API with Python functions rather than a command line interface.
If you have any questions, please feel free to reach out!
