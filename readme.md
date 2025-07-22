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

## System Architecture

### Top-Level Block Diagram
<div align="center">
  <img src="https://drive.google.com/uc?id=1mRtAl3d6mx95bcHVfP82KFCAkTnEHIwH" width="600" height="400">
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
  <img src="https://drive.google.com/uc?id=1mRtAl3d6mx95bcHVfP82KFCAkTnEHIwH" width="640" height="480">
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
  <img src="https://drive.google.com/uc?id=1L2DIvizOIso9FsDpLFeT24lqjbnk3u6x" width="640" height="440">
</div>

* Converts RGB to YCbCr using fixed-point arithmetic
* **Stage 1**: Multiply-add stage with coefficients for Y, Cb, Cr
* **Stage 2**: Round and clip to 8-bit output
* **Stage 3**: Enable signal delay for synchronization

---

### `*_dct`: DCT Modules

* Modules: `y_dct`, `cb_dct`, `cr_dct`
* Accepts 8×8 block, outputs 64 DCT coefficients (Z11 to Z88)
* **Stage 1**: Row-wise DCT (matrix multiplication)
* **Stage 2**: Column-wise DCT on intermediate values
* **Stage 3**: Accumulate and round to generate output

---

### `*_quantizer`: Quantization Modules

<div align="center">
  <img src="https://drive.google.com/uc?id=14HqEGYOWrooeTAi3vzY9K2ukFDauzobw" width="600" height="580">
</div>

* Quantizes DCT coefficients using reciprocal pre-computed multipliers
* 3-stage pipelined structure:
  1. **Sign Extension**: Convert signed 11-bit to 32-bit
  2. **Multiply**: With scaled reciprocal Q matrix value
  3. **Round & Shift**: Arithmetic right shift by 12

---

### `*_huff`: Huffman Encoding

<div align="center">
  <img src="https://drive.google.com/uc?id=1QW2JD19TAh8yTAYJZvgZVAOwX6gChf3o" width="640" height="500">
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
  <img src="https://drive.google.com/uc?id=1PH06MWUhUusrJRR7ESJDLxEhG3zJOgls" width="800" height="580">
</div>

#### 1. `sync_fifo_32`:

* Stores 32-bit Huffman output words
* Read/write control and flow flags (`not_empty`, `not_full`)

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

##  Licensing

Licensed under the **Apache License 2.0**
Copyright © 2025
**[Maktab-e-Digital Systems Lahore](https://github.com/meds-uet)**

---
