# JPEG-Based Lossy Image Compression System

> **Hardware JPEG Encoder (SystemVerilog Implementation)**
> Real-time, low-power RGB to JPEG bitstream converter for embedded systems
>
> 🗕️ *Last updated: July 22, 2025*
> © 2025 [Maktab-e-Digital Systems Lahore](https://github.com/meds-uet). Licensed under the Apache 2.0 License.

---

## Overview

This project implements a **hardware JPEG encoder** using **SystemVerilog**. It compresses RGB image data following the standard JPEG pipeline:

> **Color Conversion → DCT → Quantization → Huffman Coding → Bitstream Assembly**

Designed for **real-time**, **low-power**, and **embedded platforms**, this encoder significantly reduces image size while preserving visual quality.

###  Why JPEG?

* Reduces file size by discarding perceptually insignificant data
* Enables fast transmission and efficient memory use
* Maintains high visual fidelity
* Universally supported across hardware/software platforms

---
## RTL
## System Architecture

### Top-Level Block Diagram

<div align="center">
  <img src="https://github.com/meds-uet/JPEG-Encoder/blob/main/docs/images_design_diagrams/JPEG-Top%20level%20module.png" width="600" height="400">
</div>

#### Inputs:
* `data_in [23:0]`: RGB input pixel `{R, G, B}`
* `enable`: Starts processing the current pixel
* `end_of_file_signal`: Flags final pixel
* `rst`: Active-high reset
* `clk`: Clock signal

#### Outputs:

* `JPEG_bitstream [31:0]`: Final compressed JPEG data
* `end_of_file_bitstream_count [3:0]`: Remaining byte count
* `eof_data_partial_ready`: Final block ready signal
* `data_ready`: Valid compressed output signal

---

## Pipeline Architecture
<div align="center">
  <img src="https://github.com/meds-uet/JPEG-Encoder/blob/main/docs/images_design_diagrams/JPEG-pipeline_diagram.png" width="640" height="480">
</div>


The JPEG encoding pipeline begins its process with the `rgb2ycbcr` module, which takes incoming RGB pixel data and, once an 8x8 block is processed, outputs separate Y, Cb, and Cr data blocks along with a `data_ready` signal; these outputs simultaneously fan out as inputs to the three parallel `y_dct`, `cb_dct`, and `cr_dct` modules. Each DCT module then transforms its respective block into 12-bit signed frequency domain coefficients (`*_dct_data`), passing these, along with `dct_valid` and `block_valid` signals, to their corresponding `y_quantizer`, `cb_quantizer`, and `cr_quantizer` modules. From the quantization stage, the 8-bit `*_quantized_data` and control signals (`quant_valid`, `block_done`) are routed to the respective `y_huff`, `cb_huff`, and `cr_huff` Huffman encoding modules. In a parallel path from the quantization stage, the 12-bit quantized data also feeds into intermediate buffers (`yd_q_h`, `cbd_q_h`, `crd_q_h`), which then combine to form a 24-bit `data_in` for the `pre_fifo` stage, subsequently feeding into the `fifo_out` module. Both the Huffman encoders (providing `vc_code` and `code_len`) and the `pre_fifo` (providing `data_in`) connect to this `fifo_out` module, which then packs the incoming data into a continuous 32-bit `JPEG_bitstream`, also outputting `data_ready` and `orc_reg` (output register count). This 32-bit `JPEG_bitstream` then directly connects to a `sync_fifo_32` for synchronized data flow, whose output (`syncd_data` and `data_ready`) then feeds into the `ff_checker` module for bitstream integrity checks. Finally, the `ff_checker`'s validated output (`checked_data` and `checked_valid`) connects to the `jpeg_out` module, which serves as the ultimate output interface, providing the final `output_data` along with `output_valid` and `write_enable` signals to the external environment.

---
## Sub-modules:
```
JPEG_Encoder/
├── RGB2YCBCR/
│   └── rgb2ycbcr.sv
├── DCT/
│   ├── y_dct/
│   │   └── y_dct.sv
│   ├── cb_dct/
│   │   └── cb_dct.sv
│   └── cr_dct/
│       └── cr_dct.sv
├── Quantizer/
│   ├── y_quantizer/
│   │   └── y_quantizer.sv
│   ├── cb_quantizer/
│   │   └── cb_quantizer.sv
│   └── cr_quantizer/
│       └── cr_quantizer.sv
├── Huffman_Encoder/
│   ├── y_huff/
│   │   └── y_huff.sv
│   ├── cb_huff/
│   │   └── cb_huff.sv
│   └── cr_huff/
│       └── cr_huff.sv
├── FIFO_System/
│   ├── pre_fifo/
│   │   └── pre_fifo.sv
│   ├── sync_fifo_32/
│   │   └── sync_fifo_32.sv
│   └── fifo_out/
│       └── fifo_out.sv
├── Byte_Handler/
│   └── ff_checker/
│       └── ff_checker.sv
├── d_q_h/
│   ├── yd_q_h/
│   │   └── yd_q_h.sv
│   ├── crd_q_h/
│   │   └── crd_q_h.sv
│   └── cbd_q_h/
│       └── cbd_q_h.sv
└── jpeg_out/
    └── jpeg_out.sv
```

---
## Module Descriptions
### `RGB2YCBCR`

<div align="center">
  <img src="https://github.com/meds-uet/JPEG-Encoder/blob/main/docs/images_design_diagrams/JPEG-rgb2ycrcb.png" width="640" height="440">
</div>

* Converts RGB to YCbCr using fixed-point arithmetic
* **Stage 1**: Multiply-add stage with coefficients for Y, Cb, Cr
* **Stage 2**: Round and clip to 8-bit output
* **Stage 3**: Enable signal delay for synchronization

---

### `*_dct`: DCT Modules

<div align="center">
  <img src="https://github.com/meds-uet/JPEG-Encoder/blob/main/docs/images_design_diagrams/JPEG-dct.png" width="600" height="580">
</div>

* Modules: `y_dct`, `cb_dct`, `cr_dct`
* Accepts 8×8 block, outputs 64 DCT coefficients (Z11 to Z88)
* **Stage 1**: Row-wise DCT (matrix multiplication)
* **Stage 2**: Column-wise DCT on intermediate values
* **Stage 3**: Accumulate and round to generate output

---

### `*_quantizer`: Quantization Modules

<div align="center">
  <img src="https://github.com/meds-uet/JPEG-Encoder/blob/main/docs/images_design_diagrams/JPEG-quantization.png" width="600" height="580">
</div>

* Quantizes DCT coefficients using reciprocal pre-computed multipliers
* 3-stage pipelined structure:
  1. **Sign Extension**: Convert signed 11-bit to 32-bit
  2. **Multiply**: With scaled reciprocal Q matrix value
  3. **Round & Shift**: Arithmetic right shift by 12

---

### `*_huff`: Huffman Encoding

<div align="center">
  <img src="https://github.com/meds-uet/JPEG-Encoder/blob/main/docs/images_design_diagrams/JPEG-huff.png" width="640" height="500">
</div>

* JPEG-compliant DC and AC Huffman coding
* **Stage 1**: Sign and magnitude extraction
* **Stage 2**: Run-length encoding of zeroes
* **Stage 3**: Table lookup for Huffman codes
* **Stage 4**: Pack variable-length codes
* **Stage 5**: Output data with `valid` signal
---

### `FIFO and FSM Handling`:

### Block Diagram

<div align="center">
  <img src="https://github.com/meds-uet/JPEG-Encoder/blob/main/docs/images_design_diagrams/JPEG-fsm.png" width="800" height="580">
</div>

#### 1. `sync_fifo_32`:

* Stores 32-bit Huffman output words
* Read/write control and flow flags (`not_empty`, `not_full`)
* 

#### 2. `fifo_out`:

* Converts 32-bit word into 8-bit byte stream
* Interleaves Y → Cb → Cr order
* Includes pipelined control and muxing logic

#### 3. `ff_checker`:

* Detects 0xFF bytes in output
* Inserts 0x00 after 0xFF (JPEG standard)

#### 4. `jpeg_out`:

* Outputs final valid bytes
* Generates `write_enable`, `output_valid`

---

## FSM State Table

| **State** | **Action**                             |
| --------- | -------------------------------------- |
| IDLE      | Waits for Y FIFO to be non-empty       |
| READ\_Y   | Reads 1 byte from Y FIFO               |
| CHECK\_FF | If byte == 0xFF, set `insert_zero = 1` |
| OUTPUT    | Outputs byte (and optionally 0x00)     |
| READ\_CB  | Reads from Cb FIFO                     |
| READ\_CR  | Reads from Cr FIFO                     |


---
## Testbenches

##  `tb_rgb2ycrcb`

### Purpose
Verifies the `rgb2ycrcb` module that converts RGB input into YCbCr format using fixed-point arithmetic.
### Test Cases
* Red (255, 0, 0)
* Green (0, 255, 0)
* Blue (0, 0, 255)
* White (255, 255, 255)
* Black (0, 0, 0)
* Gray (128, 128, 128)
* Custom: (50, 100, 150)
### Input Vectors
* Clock and Reset
* `data_in [23:0]`: `{B, G, R}` packed RGB
* `enable`: Applied for 1 cycle per vector
### Expected Outputs:

<div align="center">
  <img src="https://github.com/meds-uet/JPEG-Encoder/blob/main/docs/images_testbench_EO_CO/rgb2ycrcb_EO_CO.png?raw=true" width="640" height="360">
</div>

---

## ✅ `y_dct_tb`, `cb_dct_tb`, `cr_dct_tb`
### Purpose
Validate the 2D Discrete Cosine Transform for luminance and chrominance components. Checks pipeline operation, timing, and coefficient outputs.
### Test Cases
* Ramp Pattern: `data_in = i` for i in 0 to 63
* Constant Block: All values = 100
* Checkerboard: Alternating 255 and 0
### Input Vectors
* Clock and Reset
* `enable = 1` during input phase
* `data_in [7:0]`: Serial 8-bit input over 64 cycles
### Expected Outputs


* y_dct:
  
  <div align="center">
  <img src="https://github.com/meds-uet/JPEG-Encoder/blob/main/docs/images_testbench_EO_CO/y_dct_EO_CO.png?raw=true" width="640" height="360">
  </div>
 
* cr_dct:
  
<div align="center">
  <img src="https://github.com/meds-uet/JPEG-Encoder/blob/main/docs/images_testbench_EO_CO/cr_dct_EO_CO.png?raw=true" width="640" height="360">
</div>


*cb_dct:

<div align="center">
  <img src="https://github.com/meds-uet/JPEG-Encoder/blob/main/docs/images_testbench_EO_CO/cb_dct_EO_CO.png?raw=true" width="640" height="360">
</div>

---

## `tb_y_quantizer`, `tb_cb_quantizer`, `tb_cr_quantizer`
### Purpose
Test quantization logic for Y, Cb, and Cr DCT blocks. Ensures pipelined quantization with reciprocal quantization matrix is correctly applied.
### Test Cases
* Above diagonal: Large values (200, 210...)
* Diagonal: Constant value 50
* Below diagonal: Small signed values (-1, 0, 1)
### Input Vectors
* Clock and Reset
* `Z[8][8]`: 11-bit signed DCT coefficients
* `enable = 1` to start quantization
### Expected Outputs
* y_quantizer:
  
  <div align="center">
  <img src="https://github.com/meds-uet/JPEG-Encoder/blob/main/docs/images_testbench_EO_CO/y_quantizer_EO_CO.png?raw=true" width="600" height="450">
  </div>

* cr_quantizer:
  
<div align="center">
  <img src="https://github.com/meds-uet/JPEG-Encoder/blob/main/docs/images_testbench_EO_CO/cr_quantizer_EO_CO.png?raw=true" width="600" height="450">
</div>

*cb_quantizer:

<div align="center">
  <img src="https://github.com/meds-uet/JPEG-Encoder/blob/main/docs/images_testbench_EO_CO/cb_quantizer_EO_CO.png?raw=true" width="600" height="450">
</div>

---

## `y_huff_tb`, `cb_huff_tb`, `cr_huff_tb`
### Purpose
Validate Huffman encoding of quantized DCT blocks for Y, Cb, Cr. Checks bitstream formation and control signaling.
### Test Cases
* Standard quantized input block with DC + AC coefficients
* All-zero AC run
* High magnitude DC offset
### Input Vectors
* Clock and Reset
* `X11`–`X88`: 11-bit signed coefficients
* `enable = 1` to trigger encoding
### Expected Outputs
* y_huff:
  
  <div align="center">
  <img src="https://github.com/meds-uet/JPEG-Encoder/blob/main/docs/images_testbench_EO_CO/y_huff_EO_CO.png?raw=true" width="640" height="360">
  </div>

* cr_huff:
  
<div align="center">
  <img src="https://github.com/meds-uet/JPEG-Encoder/blob/main/docs/images_testbench_EO_CO/cr_huff_EO_CO.png?raw=true" width="640" height="360">
</div>

*cb_huff:

<div align="center">
  <img src="https://github.com/meds-uet/JPEG-Encoder/blob/main/docs/images_testbench_EO_CO/cb_huff_EO_CO.png?raw=true" width="640" height="360">
</div>

---

## `tb_fifo_out`
### Purpose
Test final bitstream packager. Verifies interleaving, alignment, and FIFO register tracking.
### Test Cases
* Stream of 24-bit dummy JPEG segments
* Varying enable pulses
* Alignment edge cases
### Input Vectors
* Clock and Reset
* `data_in [23:0]`: 10 test values (e.g. 123456, 123457...)
* `enable = 1` to write to FIFO
### Expected Outputs
* `JPEG_bitstream [31:0]`: Padded, aligned output
* `data_ready = 1` when valid
* `orc_reg`: Register count tracking state
* Output is printed and checked for byte alignment

---
## `tb_sync_fifo_32`
### Purpose
Verify 32-bit synchronous FIFO. Validates write/read functionality and `fifo_empty` signal.
### Test Cases
* Write: 10, 20, 30, 40
* Read in same order
* Empty FIFO check after reads
### Input Vectors
* Clock and Reset
* `write_enable = 1` with `write_data`
* `read_enable = 1` when ready
### Expected Outputs

<div align="center">
  <img src="https://github.com/meds-uet/JPEG-Encoder/blob/main/docs/images_testbench_EO_CO/sync_fifo_32_EO_CO.png?raw=true" width="640" height="400">
</div>

---

## `tb_sync_fifo_ff`

### Purpose
Verify 91-bit FIFO with `rollover_write` behavior. Designed for special pipelined skip-write operations.
### Test Cases
* Write sequence with rollover
* Readback with skipped entries
### Input Vectors
* Clock and Reset
* `write_data [90:0]`
* `rollover_write = 1` on selected cycles
### Expected Outputs

<div align="center">
  <img src="https://github.com/meds-uet/JPEG-Encoder/blob/main/docs/images_testbench_EO_CO/sync_fifo_ff_EO_CO.png?raw=true" width="640" height="400">
</div>

---

##  Licensing

Licensed under the **Apache License 2.0**
Copyright © 2025
**[Maktab-e-Digital Systems Lahore](https://github.com/meds-uet)**

---
