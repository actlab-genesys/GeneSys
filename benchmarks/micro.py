import argparse
import dataclasses
import re
from typing import Any, Callable, Optional, Union
import onnx
import numpy as np
import numpy.typing as npt


@dataclasses.dataclass(frozen=True)
class Argument:
    name: str
    kwargs: dict[str, Any]


def parse_shape(shape_str: str) -> list[Union[str, int]]:
    if re.match(r"(?:(?:\d+|(?:(?:[:alpha:]_)[:word:]*)),)*(?:\d+|(?:(?:[:alpha:]_)[:word:]*))?", shape_str) is None:
        raise argparse.ArgumentTypeError("Shape must be a comma-separated list of integers or strings with no spaces (e.g., N,3,64)")
    return list(map(lambda s: int(s) if s.isdigit() else s, shape_str.split(",")))


def get_unary_operation_arguments() -> list[Argument]:
    return [
        Argument("input_shape", {"type": parse_shape, "required": True, "help": "Shape of the input tensor; comma-separated (e.g., N,3,64)", "metavar": "SHAPE"})
    ]


def get_binary_operation_arguments() -> list[Argument]:
    return [
        Argument("input1_shape", {"type": parse_shape, "required": True, "help": "Shape of the first input tensor; comma-separated (e.g., N,3,64)", "metavar": "SHAPE"}),
        Argument("input1_compile_time", {"action": "store_true", "default": False, "required": False, "help": "Set input1's values to be known at compile time"}),
        Argument("input1_data_file", {"type": str, "required": False, "help": "Path to a file containing input1's values if known at compile time", "metavar": "PATH"}),
        Argument("input2_shape", {"type": parse_shape, "required": True, "help": "Shape of the second input tensor; comma-separated (e.g., N,3,64)", "metavar": "SHAPE"}),
        Argument("input2_compile_time", {"action": "store_true", "default": False, "required": False, "help": "Set input2's values to be known at compile time"}),
        Argument("input2_data_file", {"type": str, "required": False, "help": "Path to a file containing input2's values if known at compile time", "metavar": "PATH"}),
    ] 


@dataclasses.dataclass(frozen=True)
class MicroBenchmark:
    name: str
    description: str
    arguments: tuple[Argument, ...]
    model_creation_function: Callable[[argparse.Namespace], tuple[str, onnx.ModelProto]]


def get_data_from_file(file_path: str) -> npt.NDArray[np.float32]:
    if file_path.endswith(".txt"):
        return np.loadtxt(file_path, dtype=np.float32).flatten()
    else:
        raise NotImplementedError("Only .txt files are supported at this time.")


class BenchmarkCreator:
    _name: str
    _inputs: list[onnx.ValueInfoProto]
    _outputs: list[onnx.ValueInfoProto]
    _value_infos: list[onnx.ValueInfoProto]
    _initializers: list[onnx.TensorProto]
    _nodes: list[onnx.NodeProto]

    def __init__(self, name: str) -> None:
        self._name = name
        self._inputs = []
        self._outputs = []
        self._value_infos = []
        self._initializers = []
        self._nodes = []
    
    def reset(self) -> None:
        self._inputs = []
        self._outputs = []
        self._value_infos = []
        self._initializers = []

    def create_value(self, name: str, shape: Optional[list[Union[str, int]]] = None) -> onnx.ValueInfoProto:
        return onnx.helper.make_tensor_value_info(name, onnx.TensorProto.FLOAT, shape=shape)

    def add_input(self, value: onnx.ValueInfoProto) -> None:
        self._inputs.append(value)
    
    def add_output(self, value: onnx.ValueInfoProto) -> None:
        self._outputs.append(value)
    
    def add_intermediate(self, value: onnx.ValueInfoProto) -> None:
        self._value_infos.append(value)
    
    def add_initializer(self, name: str, data: npt.NDArray[np.float32]) -> None:
        self._initializers.append(onnx.numpy_helper.from_array(data, name=name))
    
    def add_initializer_from_file(self, name: str, shape: list[Union[str, int]], file_path: str) -> None:
        if any(isinstance(s, str) for s in shape):
            raise ValueError("Cannot have a compile-time input with any non-integer dimensions.")
        data = get_data_from_file(file_path)
        self.add_initializer(name, data.reshape(shape))

    def create_node(self, op_type: str, inputs: list[str], outputs: list[str], name: Optional[str] = None, **kwargs: Any) -> onnx.NodeProto:
        return onnx.helper.make_node(op_type, inputs=inputs, outputs=outputs, name=name, **kwargs)
    
    def add_node(self, node: onnx.NodeProto) -> None:
        self._nodes.append(node)
    
    def finalize_model(self) -> onnx.ModelProto:
        graph = onnx.helper.make_graph(
            nodes=self._nodes,
            name=f"{self._name.capitalize()}Graph",
            inputs=self._inputs,
            outputs=self._outputs,
            value_info=self._value_infos,
            initializer=self._initializers if len(self._initializers) > 0 else None
        )

        initial_model = onnx.helper.make_model(graph, producer_name=f"{self._name}_model")
        inferred_model = onnx.shape_inference.infer_shapes(initial_model)
        return inferred_model


# ==================== Get Operations Function ====================
def get_operations() -> list[MicroBenchmark]:
    return [
        MicroBenchmark(
            "add", 
            "Element-wise addition operation", 
            get_binary_operation_arguments(),
            create_add_operation
        ),
        MicroBenchmark(
            "matmul", 
            "Matrix multiplication operation", 
            get_binary_operation_arguments(),
            create_matmul_operation
        ),
        MicroBenchmark(
            "relu",
            "Rectified linear unit operation",
            get_unary_operation_arguments(),
            create_relu_operation
        ),
        MicroBenchmark(
            "transpose",
            "Transpose operation",
            get_unary_operation_arguments() + [
                Argument("perm", {"type": parse_shape, "required": True, "help": "Permutation of the input tensor's dimensions; comma-separated (e.g., 1,0,2)", "metavar": "PERM"})
            ],
            create_transpose_operation
        )
    ]


# ==================== Operation Creation Functions ====================
def create_unary_operation(
    name: str, 
    op_type: str, 
    args: argparse.Namespace, 
    input_name: str = "input",
    output_name: str = "output",
    node_attributes: dict[str, Any] = {}
) -> tuple[str, onnx.ModelProto]:
    input_shape: list[Union[str, int]] = args.input_shape

    creator = BenchmarkCreator(name)

    input = creator.create_value(input_name, input_shape)
    creator.add_input(input)
    output = creator.create_value(output_name)
    creator.add_output(output)
    add_node = creator.create_node(op_type, [input_name], [output_name], **node_attributes)
    creator.add_node(add_node)

    return name, creator.finalize_model()


def create_binary_operation(
    name: str, 
    op_type: str, 
    args: argparse.Namespace, 
    input1_name: str = "input1", 
    input2_name: str = "input2",
    output_name: str = "output",
    node_attributes: dict[str, Any] = {}
) -> tuple[str, onnx.ModelProto]:
    input1_shape: list[Union[str, int]] = args.input1_shape
    is_input1_compile_time: bool = args.input1_compile_time
    input1_data_file: str = args.input1_data_file
    input2_shape: list[Union[str, int]] = args.input2_shape
    is_input2_compile_time: bool = args.input2_compile_time
    input2_data_file: str = args.input2_data_file

    if is_input1_compile_time and input1_data_file is None:
        raise ValueError("Input 1 is compile-time but no data file was provided.")
    if not is_input1_compile_time and input1_data_file is not None:
        raise ValueError("Input 1 is not compile-time but a data file was provided.")
    if is_input2_compile_time and input2_data_file is None:
        raise ValueError("Input 2 is compile-time but no data file was provided.")
    if not is_input2_compile_time and input2_data_file is not None:
        raise ValueError("Input 2 is not compile-time but a data file was provided.")
    if is_input1_compile_time and is_input2_compile_time:
        raise ValueError("Cannot have both inputs be compile-time.")

    creator = BenchmarkCreator(name)

    add_node_inputs = []
    if is_input1_compile_time:
        creator.add_initializer_from_file(input1_name, input1_shape, input1_data_file) 
        add_node_inputs.append(input1_name)
    else:
        input1 = creator.create_value(input1_name, input1_shape)
        creator.add_input(input1)
        add_node_inputs.append(input1_name)

    if is_input2_compile_time:
        creator.add_initializer_from_file(input2_name, input2_shape, input2_data_file)
        add_node_inputs.append(input2_name)
    else:
        input2 = creator.create_value(input2_name, input2_shape)
        creator.add_input(input2)
        add_node_inputs.append(input2_name)

    output = creator.create_value(output_name)
    creator.add_output(output)
    add_node = creator.create_node(op_type, add_node_inputs, [output_name], **node_attributes)
    creator.add_node(add_node)

    return name, creator.finalize_model()


def create_add_operation(args: argparse.Namespace) -> tuple[str, onnx.ModelProto]:
    return create_binary_operation("add", "Add", args) 


def create_matmul_operation(args: argparse.Namespace) -> tuple[str, onnx.ModelProto]:
    input_1_shape: list[Union[str, int]] = args.input1_shape
    input_2_shape: list[Union[str, int]] = args.input2_shape
    if len(input_1_shape) < 1:
        raise ValueError("Input 1 must have at least 1 dimension.")
    if len(input_2_shape) < 1:
        raise ValueError("Input 2 must have at least 1 dimension.")
    if input_1_shape[-1] != (input_2_shape[-2] if len(input_2_shape) > 1 else input_2_shape[0]):
        raise ValueError("Input 1's last dimension must match input 2's second-to-last dimension.")
    return create_binary_operation("matmul", "MatMul", args)


def create_relu_operation(args: argparse.Namespace) -> tuple[str, onnx.ModelProto]:
    return create_unary_operation("relu", "Relu", args)


def create_transpose_operation(args: argparse.Namespace) -> tuple[str, onnx.ModelProto]:
    input_shape: list[Union[str, int]] = args.input_shape
    perm: list[Union[str, int]] = args.perm
    if len(input_shape) != len(perm):
        raise ValueError("Input shape and permutation must have the same number of dimensions.")
    return create_unary_operation("transpose", "Transpose", args, output_name="output", input_name="input", node_attributes={"perm": perm})


def main():
    operations: list[MicroBenchmark] = get_operations()
    parser = argparse.ArgumentParser(description="Generate micro benchmarks for GeneSys.")
    subparsers = parser.add_subparsers(dest="operation", help="Operations")

    for operation in operations:
        operation_parser: argparse.ArgumentParser = subparsers.add_parser(operation.name, help=operation.description)
        for argument in operation.arguments:
            operation_parser.add_argument("--" + argument.name, **argument.kwargs)

    args: argparse.Namespace = parser.parse_args()

    name, model = {o.name: o for o in operations}[args.operation].model_creation_function(args)

    onnx.save(model, name + ".onnx")


if __name__ == "__main__":
    main()
