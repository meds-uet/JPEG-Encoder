# JPEG-Based Lossy Image Compression System

> **Hardware JPEG Encoder (SystemVerilog Implementation)**
> Real-time, low-power RGB to JPEG bitstream converter for embedded systems
>
> 🗕️ *Last updated: July 30, 2025*
> © 2025 [Maktab-e-Digital Systems Lahore](https://github.com/meds-uet). Licensed under the Apache 2.0 License.

---

## Overview

This project implements a **hardware JPEG encoder** using **SystemVerilog**. It compresses RGB image data following the standard JPEG pipeline:

                               Color Conversion → DCT → Quantization → Huffman Coding → Bitstream Assembly 

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
  <img src="./images_design_diagrams/JPEG-Top-level-module.png" width="600" height="400">
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
* **Stage 5**: Output data 
---

### `FIFO and FSM Handling`:

### Block Diagram

<div align="center">
  <img src="https://github.com/meds-uet/JPEG-Encoder/blob/main/docs/images_design_diagrams/JPEG-fsm.png" width="800" height="580">
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
## Testbenches

##  1. `tb_rgb2ycrcb`

### 1. Purpose of Test Cases
The testbench is designed to check the accuracy of color space conversion under common edge cases and validate robustness with random RGB inputs. It ensures proper pipeline behavior, rounding, and output timing of the rgb2ycrcb module.

### 2. Input Vectors
The testbench applies both fixed and random RGB values:
Fixed RGB Values:
- (0, 0, 0) — Black
- (255, 255, 255) — White
- (255, 0, 0) — Red
- (0, 255, 0) — Green
- (0, 0, 255) — Blue
- (128, 128, 128) — Mid-gray
- Random RGB Values:
Ten 24-bit RGB values are generated using $urandom_range(0, 255) to simulate general use cases and uncover hidden bugs.

 ### 3. Expected Output:
Each input is applied with a 1-cycle enable signal and a 3-cycle wait to accommodate pipeline latency. The testbench checks for a valid enable_out and prints the YCbCr result in a readable format. This allows visual confirmation and debugging, and can be extended for automated comparisons with a golden reference model if needed.

  <div align="center">
  <img src="https://github.com/meds-uet/JPEG-Encoder/blob/main/docs/images_testbench_EO_CO/rgb2ycrcb_EO_CO.png" width="640" height="360">
  </div>


---

## `y_dct_tb`, `cb_dct_tb`, `cr_dct_tb`
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

## 3. `tb_*_quantizer`
### 1. Purpose
The test cases are designed to confirm that the quantization logic correctly applies scaling and rounding to signed DCT coefficients. The expected outputs are computed using the same reciprocal-based method used in hardware: multiplying by (4096 / Q[i][j]), right-shifting by 12, and rounding toward zero. The goal is to validate accuracy, rounding behavior, and pipeline timing across various coefficient patterns.

### 2.  Input Pattern
The testbench uses four structured input patterns to thoroughly test the quantizer:
- All 1023: Applies the maximum positive value (11'sd1023) to all matrix elements.
- Ramp Pattern: Gradually increasing values from 0 to 63 across the matrix.
- Checkerboard Pattern: Alternating +1023 and -1024 values to test signed rounding.
- Random Values: 64 random signed 11-bit inputs in the range [-1024, +1023] for general-case validation.
- These patterns are stored in the test_input matrix and applied to the Z input of the DUT.
  
### 3. Expected Outputs
After applying inputs and enabling the module for one clock cycle, the testbench waits for the out_enable signal to assert (indicating pipeline completion). It then prints the input matrix, expected quantized values, and actual hardware outputs side-by-side for visual comparison

 ### *** *_quantizer:***
  
  <div align="center">
  <img src="https://github.com/meds-uet/JPEG-Encoder/blob/main/docs/images_testbench_EO_CO/quantizer_EO_CO.png" width="900" height="650">
  </div>
  
  <div align="center">
  <img src="https://github.com/meds-uet/JPEG-Encoder/blob/main/docs/images_testbench_EO_CO/quantizer_2_EO_CO.png" width="900" height="650">
  </div>
  
---

## `tb_*_huff`:
### 1. Purpose
This testbench validates the functionality of the *_huff module, which performs Huffman encoding on an 8×8 block of quantized DCT coefficients for the components in JPEG compression. It ensures correct encoding of sparse DCT blocks, including proper handling of DC and AC coefficients, output bitstream generation, and end-of-block signaling.

### 2.  Input Pattern
Two test cases are included:
Test Case 1 – Sparse DCT Block
- Y11 = 50 (DC coefficient)
- Y21 = 3, Y13 = 2 (non-zero AC coefficients)
- All other coefficients are zero.
Test Case 2 – New DC & AC Coefficients After Reset
-Y11 = 100 (new DC)
-Y21 = 5 (non-zero AC)
-All others remain zero.
Each test applies a reset, then enables the module for one cycle to start encoding. The simulation runs long enough to process all 64 inputs through the internal pipeline.
  
### 3. Expected Outputs
For each test case, the monitor displays:The evolving state of data_ready, output_reg_count, end_of_block_output, and JPEG_bitstream.The encoded output should reflect the DC value followed by Huffman-encoded non-zero AC coefficients, terminated with an end-of-block symbol.

 ### ***y_huff***:
  
  <div align="center">
  <img src="https://github.com/meds-uet/JPEG-Encoder/blob/main/docs/images_testbench_EO_CO/y_huff_EO_CO.png?raw=true" width="900" height="680">
  </div>

 ### ***cr_huff***:
  
<div align="center">
  <img src="https://github.com/meds-uet/JPEG-Encoder/blob/main/docs/images_testbench_EO_CO/cr_huff_EO_CO.png?raw=true" width="900" height="680">
</div>

 ### ***cb_huff***:

<div align="center">
  <img src="https://github.com/meds-uet/JPEG-Encoder/blob/main/docs/images_testbench_EO_CO/cb_huff_EO_CO.png?raw=true" width="900" height="680">
</div>
<div align="center">
  <img src="https://github.com/meds-uet/JPEG-Encoder/blob/main/docs/images_testbench_EO_CO/cb_huff_2_EO_CO.png?raw=true" width="900" height="680">
</div>

---

## `tb_sync_fifo_32`
### 1. Purpose
This testbench validates the core functionality of the sync_fifo_32 module — a 32-bit wide synchronous FIFO. It checks the correctness of write and read operations, verifies the timing of valid read data, and ensures the FIFO empty flag is asserted after all data has been read.The goal of this test is to ensure that the FIFO can: Correctly store and retrieve 32-bit values, Maintain proper read/write synchronization,Assert the fifo_empty flag only after all data has been read out,Assert the rdata_valid signal in line with available data.

### 2.  Input Pattern
The test sequence includes:
- Reset Initialization – The FIFO is reset to a known empty state.
- Write Phase – Four distinct 32-bit values (10, 20, 30, 40) are written sequentially using the write_word task.
- Read Phase – The same values are read back using the read_word task, which waits for rdata_valid to ensure timing correctness.
- FIFO Empty Check – After all reads, the fifo_empty flag is checked to confirm the FIFO is indeed empty.
 
### 3. Expected Outputs
The expected output from the testbench includes confirmation of correct write and read sequences, along with validation that the FIFO becomes empty after all data is read.

  <div align="center">
  <img src="https://github.com/meds-uet/JPEG-Encoder/blob/main/docs/images_testbench_EO_CO/sync_fifo_32_EO_CO.png?raw=true" width="640" height="400">
  </div>

---

## `tb_sync_fifo_ff`
### 1. Purpose
This testbench verifies the behavior of the sync_fifo_ff module — a synchronous FIFO buffer with a 91-bit wide data interface and a special rollover_write input that triggers an intentional "bubble" or skipped entry in the FIFO. The design includes standard FIFO operations along with extended functionality, making it important to validate both normal and rollover behavior.The testbench aims to confirm: Standard FIFO write and read sequencing,Correct handling of valid data (rdata_valid) and empty flags.The effect of rollover_write, which should insert a skipped (or invalid) slot in the FIFO write pipeline.

### 2.  Input Pattern
Standard Write & Read:
- Four 91-bit data values (100, 101, 102, 103) are written into the FIFO.
- These values are read back in order using synchronized read_req pulses and checking rdata_valid to confirm valid outputs.
Rollover Write Test:
- A special write_rollover(500) is issued, expected to skip a FIFO entry.
- Two more values (999, 777) are written normally.
- All entries are read sequentially to observe if the rollover_write caused a gap or delay in FIFO output behavior.
  
### 3. Expected Outputs
Read operations are synchronized using read_req and a wait on rdata_valid.This helps trace FIFO behavior, especially around skipped or inserted bubbles from the rollover_write mechanism.
  
  <div align="center">
  <img src="https://github.com/meds-uet/JPEG-Encoder/blob/main/docs/images_testbench_EO_CO/sync_fifo_ff_EO_CO.png?raw=true" width="640" height="400">
  </div>
  
---

##  Licensing

Licensed under the **Apache License 2.0**
Copyright © 2025
**[Maktab-e-Digital Systems Lahore](https://github.com/meds-uet)**

---
