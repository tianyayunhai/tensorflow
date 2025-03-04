/* Copyright 2019 The TensorFlow Authors. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
==============================================================================*/

// Quantization patterns to be used both when the converter authoritatively
// quantizes the model and when the converter follows Q-DQ annotations.

include "mlir/IR/OpBase.td"
include "mlir/IR/PatternBase.td"
include "mlir/Dialect/Arith/IR/ArithOps.td"
include "mlir/Dialect/Func/IR/FuncOps.td"
include "mlir/IR/CommonTypeConstraints.td"
include "tensorflow/compiler/mlir/quantization/common/quantization_lib/quantization.td"
include "tensorflow/compiler/mlir/lite/ir/tfl_ops.td"

// Quantize attribute $0 by using quantization parameter from %1.
def QuantizeByQuantizedType : NativeCodeCall<"quant::Quantize($0, $1.getValue())">;
def F32ElementsAttr : ElementsAttrBase<
  CPred<"$_self.cast<ElementsAttr>().getShapedType().getElementType().isF32()">, "float constant tensor">;

// Squash tfl.dequantize and tfl.quantize pairs.
// TODO(fengliuai): Compare the scale of input and output. This can also be
// squashed to a requantize op if the scales are different.
def : Pat<(TFL_QuantizeOp (TFL_DequantizeOp $in), $qt), (replaceWithValue $in)>;

// If the tfl.dequantize op wasn't fused, we shouldn't quantize the floating
// point constant.
def : Pat<(TFL_DequantizeOp
             (TFL_QuantizeOp (Arith_ConstantOp F32ElementsAttr:$cst), $qt)),
          (TFL_ConstOp $cst)>;

