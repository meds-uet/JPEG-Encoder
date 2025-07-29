// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// Description:
//    This module performs Huffman encoding for Cr (Chroma Red) data. It takes the quantized
//    DCT coefficients for an 8x8 Cr block and generates the corresponding variable-length
//    Huffman codes, suitable for bitstream compression.
//
// Author:Rameen
// Date:16th July,2025.

`timescale 1ns / 100ps
module cr_huff (
	input  logic        clk,       // Clock signal
	input  logic        rst,       // Active-high synchronous reset
	input  logic        enable,    // Enable signal for processing
	
	// 64 input DCT coefficients (11-bit each) from Cr channel (8x8 block)
	input  logic [10:0] Cr11, Cr12, Cr13, Cr14, Cr15, Cr16, Cr17, Cr18,
	input  logic [10:0] Cr21, Cr22, Cr23, Cr24, Cr25, Cr26, Cr27, Cr28,
	input  logic [10:0] Cr31, Cr32, Cr33, Cr34, Cr35, Cr36, Cr37, Cr38,
	input  logic [10:0] Cr41, Cr42, Cr43, Cr44, Cr45, Cr46, Cr47, Cr48,
	input  logic [10:0] Cr51, Cr52, Cr53, Cr54, Cr55, Cr56, Cr57, Cr58,
	input  logic [10:0] Cr61, Cr62, Cr63, Cr64, Cr65, Cr66, Cr67, Cr68,
	input  logic [10:0] Cr71, Cr72, Cr73, Cr74, Cr75, Cr76, Cr77, Cr78,
	input  logic [10:0] Cr81, Cr82, Cr83, Cr84, Cr85, Cr86, Cr87, Cr88,

	// Huffman encoded output bitstream (32 bits)
	output logic [31:0] JPEG_bitstream,

	// Signals to indicate status
	output logic        data_ready,          // High when output is valid
	output logic [4:0]  output_reg_count,    // Number of output registers used
	output logic        end_of_block_empty   // High when no more data in block
);
// Block counter for tracking coefficient processing
logic [7:0] block_counter;

// Registers for Cr11 AC/DC amplitude and differences
logic [11:0] Cr11_amp, Cr11_1_pos, Cr11_1_neg, Cr11_diff;
logic [11:0] Cr11_previous, Cr11_1;

// Cr12 amplitude and its positive/negative versions
logic [10:0] Cr12_amp, Cr12_pos, Cr12_neg;

// Positive/negative versions of multiple Cr coefficients
logic [10:0] Cr21_pos, Cr21_neg, Cr31_pos, Cr31_neg, Cr22_pos, Cr22_neg;
logic [10:0] Cr13_pos, Cr13_neg, Cr14_pos, Cr14_neg, Cr15_pos, Cr15_neg;
logic [10:0] Cr16_pos, Cr16_neg, Cr17_pos, Cr17_neg, Cr18_pos, Cr18_neg;
logic [10:0] Cr23_pos, Cr23_neg, Cr24_pos, Cr24_neg, Cr25_pos, Cr25_neg;
logic [10:0] Cr26_pos, Cr26_neg, Cr27_pos, Cr27_neg, Cr28_pos, Cr28_neg;
logic [10:0] Cr32_pos, Cr32_neg;
logic [10:0] Cr33_pos, Cr33_neg, Cr34_pos, Cr34_neg, Cr35_pos, Cr35_neg;
logic [10:0] Cr36_pos, Cr36_neg, Cr37_pos, Cr37_neg, Cr38_pos, Cr38_neg;
logic [10:0] Cr41_pos, Cr41_neg, Cr42_pos, Cr42_neg;
logic [10:0] Cr43_pos, Cr43_neg, Cr44_pos, Cr44_neg, Cr45_pos, Cr45_neg;
logic [10:0] Cr46_pos, Cr46_neg, Cr47_pos, Cr47_neg, Cr48_pos, Cr48_neg;
logic [10:0] Cr51_pos, Cr51_neg, Cr52_pos, Cr52_neg;
logic [10:0] Cr53_pos, Cr53_neg, Cr54_pos, Cr54_neg, Cr55_pos, Cr55_neg;
logic [10:0] Cr56_pos, Cr56_neg, Cr57_pos, Cr57_neg, Cr58_pos, Cr58_neg;
logic [10:0] Cr61_pos, Cr61_neg, Cr62_pos, Cr62_neg;
logic [10:0] Cr63_pos, Cr63_neg, Cr64_pos, Cr64_neg, Cr65_pos, Cr65_neg;
logic [10:0] Cr66_pos, Cr66_neg, Cr67_pos, Cr67_neg, Cr68_pos, Cr68_neg;
logic [10:0] Cr71_pos, Cr71_neg, Cr72_pos, Cr72_neg;
logic [10:0] Cr73_pos, Cr73_neg, Cr74_pos, Cr74_neg, Cr75_pos, Cr75_neg;
logic [10:0] Cr76_pos, Cr76_neg, Cr77_pos, Cr77_neg, Cr78_pos, Cr78_neg;
logic [10:0] Cr81_pos, Cr81_neg, Cr82_pos, Cr82_neg;
logic [10:0] Cr83_pos, Cr83_neg, Cr84_pos, Cr84_neg, Cr85_pos, Cr85_neg;
logic [10:0] Cr86_pos, Cr86_neg, Cr87_pos, Cr87_neg, Cr88_pos, Cr88_neg;

// Bit count registers for Cr11 and Cr12 values
logic [3:0] Cr11_bits_pos, Cr11_bits_neg, Cr11_bits, Cr11_bits_1;
logic [3:0] Cr12_bits_pos, Cr12_bits_neg, Cr12_bits, Cr12_bits_1;
logic [3:0] Cr12_bits_2, Cr12_bits_3;

// MSB flags and status flags
logic Cr11_msb, Cr12_msb, Cr12_msb_1;

// Enable pipeline stages and control flags
logic enable_1, enable_2, enable_3, enable_4, enable_5, enable_6;
logic enable_7, enable_8, enable_9, enable_10, enable_11, enable_12;
logic enable_13, enable_module, enable_latch_7, enable_latch_8;

// Zero-detection and rollover flags
logic Cr12_et_zero, rollover, rollover_1, rollover_2, rollover_3;
logic rollover_4, rollover_5, rollover_6, rollover_7;

// End-zero flags and MSB detection flags for each coefficient
logic Cr21_et_zero, Cr21_msb, Cr31_et_zero, Cr31_msb;
logic Cr22_et_zero, Cr22_msb, Cr13_et_zero, Cr13_msb;
logic Cr14_et_zero, Cr14_msb, Cr15_et_zero, Cr15_msb;
logic Cr16_et_zero, Cr16_msb, Cr17_et_zero, Cr17_msb;
logic Cr18_et_zero, Cr18_msb;
logic Cr23_et_zero, Cr23_msb, Cr24_et_zero, Cr24_msb;
logic Cr25_et_zero, Cr25_msb, Cr26_et_zero, Cr26_msb;
logic Cr27_et_zero, Cr27_msb, Cr28_et_zero, Cr28_msb;
logic Cr32_et_zero, Cr32_msb, Cr33_et_zero, Cr33_msb;
logic Cr34_et_zero, Cr34_msb, Cr35_et_zero, Cr35_msb;
logic Cr36_et_zero, Cr36_msb, Cr37_et_zero, Cr37_msb;
logic Cr38_et_zero, Cr38_msb;
logic Cr41_et_zero, Cr41_msb, Cr42_et_zero, Cr42_msb;
logic Cr43_et_zero, Cr43_msb, Cr44_et_zero, Cr44_msb;
logic Cr45_et_zero, Cr45_msb, Cr46_et_zero, Cr46_msb;
logic Cr47_et_zero, Cr47_msb, Cr48_et_zero, Cr48_msb;
logic Cr51_et_zero, Cr51_msb, Cr52_et_zero, Cr52_msb;
logic Cr53_et_zero, Cr53_msb, Cr54_et_zero, Cr54_msb;
logic Cr55_et_zero, Cr55_msb, Cr56_et_zero, Cr56_msb;
logic Cr57_et_zero, Cr57_msb, Cr58_et_zero, Cr58_msb;
logic Cr61_et_zero, Cr61_msb, Cr62_et_zero, Cr62_msb;
logic Cr63_et_zero, Cr63_msb, Cr64_et_zero, Cr64_msb;
// Flags for zero detection and MSB of Cr65–Cr88 coefficients
logic Cr65_et_zero, Cr65_msb, Cr66_et_zero, Cr66_msb;
logic Cr67_et_zero, Cr67_msb, Cr68_et_zero, Cr68_msb;
logic Cr71_et_zero, Cr71_msb, Cr72_et_zero, Cr72_msb;
logic Cr73_et_zero, Cr73_msb, Cr74_et_zero, Cr74_msb;
logic Cr75_et_zero, Cr75_msb, Cr76_et_zero, Cr76_msb;
logic Cr77_et_zero, Cr77_msb, Cr78_et_zero, Cr78_msb;
logic Cr81_et_zero, Cr81_msb, Cr82_et_zero, Cr82_msb;
logic Cr83_et_zero, Cr83_msb, Cr84_et_zero, Cr84_msb;
logic Cr85_et_zero, Cr85_msb, Cr86_et_zero, Cr86_msb;
logic Cr87_et_zero, Cr87_msb, Cr88_et_zero, Cr88_msb;

// Intermediate control flags for Cr12
logic Cr12_et_zero_1, Cr12_et_zero_2, Cr12_et_zero_3, Cr12_et_zero_4, Cr12_et_zero_5;



// Huffman encoding registers for Cr11 and Cr12
logic [10:0] Cr11_Huff, Cr11_Huff_1, Cr11_Huff_2;
logic [15:0] Cr12_Huff, Cr12_Huff_1, Cr12_Huff_2;

// Shift and count controls for Huffman encoding
logic [3:0] Cr11_Huff_count, Cr11_Huff_shift, Cr11_Huff_shift_1;
logic [3:0] Cr11_amp_shift, Cr12_amp_shift;
logic [3:0] Cr12_Huff_shift, Cr12_Huff_shift_1;
logic [3:0] zero_run_length, zrl_1, zrl_2, zrl_3;

// Output count and edge alignment for Cr12
logic [4:0] Cr12_Huff_count, Cr12_Huff_count_1;
logic [4:0] Cr11_output_count;
logic [4:0] old_orc_1, old_orc_2, old_orc_3, old_orc_4, old_orc_5, old_orc_6;
logic [4:0] Cr12_oc_1;
logic [4:0] orc_3, orc_4, orc_5, orc_6, orc_7, orc_8;
logic [4:0] Cr12_output_count;
logic [4:0] Cr12_edge, Cr12_edge_1, Cr12_edge_2, Cr12_edge_3, Cr12_edge_4;

// Final JPEG output stream and intermediate bitstreams
logic [31:0] JPEG_bs, JPEG_bs_1, JPEG_bs_2, JPEG_bs_3, JPEG_bs_4, JPEG_bs_5;
logic [31:0] JPEG_Cr12_bs, JPEG_Cr12_bs_1, JPEG_Cr12_bs_2, JPEG_Cr12_bs_3, JPEG_Cr12_bs_4;
logic [31:0] JPEG_ro_bs, JPEG_ro_bs_1, JPEG_ro_bs_2, JPEG_ro_bs_3, JPEG_ro_bs_4;

// Lower significant bits and bit counters for Cr11 and Cr12
logic [21:0] Cr11_JPEG_LSBs_3;
logic [10:0] Cr11_JPEG_LSBs, Cr11_JPEG_LSBs_1, Cr11_JPEG_LSBs_2;
logic [9:0]  Cr12_JPEG_LSBs, Cr12_JPEG_LSBs_1, Cr12_JPEG_LSBs_2, Cr12_JPEG_LSBs_3;
logic [25:0] Cr11_JPEG_bits, Cr11_JPEG_bits_1;
logic [25:0] Cr12_JPEG_bits, Cr12_JPEG_LSBs_4;
logic [7:0]  Cr12_code_entry;

// Flags for checking if entire 8-value block is zero (used in run-length encoding)
logic third_8_all_0s, fourth_8_all_0s, fifth_8_all_0s, sixth_8_all_0s, seventh_8_all_0s;
logic eighth_8_all_0s;

// End-of-block flags and special Huffman encoding control flags
logic end_of_block, code_15_0, zrl_et_15;
logic end_of_block_output;

// Combined wire used for code indexing based on run-length and bit size
wire [7:0] code_index = { zrl_2, Cr12_bits };

// Detect if each 8-element group in the zig-zag scan is entirely zero
// Each group is updated when enable_1 is active

// Define constants for JPEG Huffman tables

localparam logic [3:0] Cr_DC_code_length [0:11] = '{
    4'd2, 4'd2, 4'd2, 4'd3,
    4'd4, 4'd5, 4'd6, 4'd7,
    4'd8, 4'd9, 4'd10, 4'd11
};

localparam logic [10:0] Cr_DC [0:11] = '{
    11'b00000000000,
    11'b01000000000,
    11'b10000000000,
    11'b11000000000,
    11'b11100000000,
    11'b11110000000,
    11'b11111000000,
    11'b11111100000,
    11'b11111110000,
    11'b11111111000,
    11'b11111111100,
    11'b11111111110
};

localparam logic [4:0] Cr_AC_code_length [0:160] = '{
    5'd2,  5'd2,  5'd3,  5'd4,  5'd4,  5'd4,  5'd5,  5'd5,
    5'd5,  5'd6,  5'd6,  5'd7,  5'd7,  5'd7,  5'd7,  5'd8,
    5'd8,  5'd8,  5'd9,  5'd9,  5'd9,  5'd9,  5'd9,  5'd10,
    5'd10, 5'd10, 5'd10, 5'd10, 5'd11, 5'd11, 5'd11, 5'd11,
    5'd12, 5'd12, 5'd12, 5'd12, 5'd15, 5'd16, 5'd16, 5'd16,
    5'd16, 5'd16, 5'd16, 5'd16, 5'd16, 5'd16, 5'd16, 5'd16,
    5'd16, 5'd16, 5'd16, 5'd16, 5'd16, 5'd16, 5'd16, 5'd16,
    5'd16, 5'd16, 5'd16, 5'd16, 5'd16, 5'd16, 5'd16, 5'd16,
    5'd16, 5'd16, 5'd16, 5'd16, 5'd16, 5'd16, 5'd16, 5'd16,
    5'd16, 5'd16, 5'd16, 5'd16, 5'd16, 5'd16, 5'd16, 5'd16,
    5'd16, 5'd16, 5'd16, 5'd16, 5'd16, 5'd16, 5'd16, 5'd16,
    5'd16, 5'd16, 5'd16, 5'd16, 5'd16, 5'd16, 5'd16, 5'd16,
    5'd16, 5'd16, 5'd16, 5'd16, 5'd16, 5'd16, 5'd16, 5'd16,
    5'd16, 5'd16, 5'd16, 5'd16, 5'd16, 5'd16, 5'd16, 5'd16,
    5'd16, 5'd16, 5'd16, 5'd16, 5'd16, 5'd16, 5'd16, 5'd16,
    5'd16, 5'd16, 5'd16, 5'd16, 5'd16, 5'd16, 5'd16, 5'd16,
    5'd16, 5'd16, 5'd16, 5'd16, 5'd16, 5'd16, 5'd16, 5'd16,
    5'd16
};

localparam logic [15:0] Cr_AC [0:161] = '{
    16'h0000, 16'h4000, 16'h8000, 16'hA000, 16'hB000, 16'hC000, 16'hD000, 16'hD800,
    16'hE000, 16'hE800, 16'hEC00, 16'hF000, 16'hF200, 16'hF400, 16'hF600, 16'hF800,
    16'hF900, 16'hFA00, 16'hFB00, 16'hFB80, 16'hFC00, 16'hFC80, 16'hFD00, 16'hFD80,
    16'hFDC0, 16'hFE00, 16'hFE40, 16'hFE80, 16'hFEC0, 16'hFEE0, 16'hFF00, 16'hFF20,
    16'hFF40, 16'hFF50, 16'hFF60, 16'hFF70, 16'hFF80, 16'hFF82, 16'hFF83, 16'hFF84,
    16'hFF85, 16'hFF86, 16'hFF87, 16'hFF88, 16'hFF89, 16'hFF8A, 16'hFF8B, 16'hFF8C,
    16'hFF8D, 16'hFF8E, 16'hFF8F, 16'hFF90, 16'hFF91, 16'hFF92, 16'hFF93, 16'hFF94,
    16'hFF95, 16'hFF96, 16'hFF97, 16'hFF98, 16'hFF99, 16'hFF9A, 16'hFF9B, 16'hFF9C,
    16'hFF9D, 16'hFF9E, 16'hFF9F, 16'hFFA0, 16'hFFA1, 16'hFFA2, 16'hFFA3, 16'hFFA4,
    16'hFFA5, 16'hFFA6, 16'hFFA7, 16'hFFA8, 16'hFFA9, 16'hFFAA, 16'hFFAB, 16'hFFAC,
    16'hFFAD, 16'hFFAE, 16'hFFAF, 16'hFFB0, 16'hFFB1, 16'hFFB2, 16'hFFB3, 16'hFFB4,
    16'hFFB5, 16'hFFB6, 16'hFFB7, 16'hFFB8, 16'hFFB9, 16'hFFBA, 16'hFFBB, 16'hFFBC,
    16'hFFBD, 16'hFFBE, 16'hFFBF, 16'hFFC0, 16'hFFC1, 16'hFFC2, 16'hFFC3, 16'hFFC4,
    16'hFFC5, 16'hFFC6, 16'hFFC7, 16'hFFC8, 16'hFFC9, 16'hFFCA, 16'hFFCB, 16'hFFCC,
    16'hFFCD, 16'hFFCE, 16'hFFCF, 16'hFFD0, 16'hFFD1, 16'hFFD2, 16'hFFD3, 16'hFFD4,
    16'hFFD5, 16'hFFD6, 16'hFFD7, 16'hFFD8, 16'hFFD9, 16'hFFDA, 16'hFFDB, 16'hFFDC,
    16'hFFDD, 16'hFFDE, 16'hFFDF, 16'hFFE0, 16'hFFE1, 16'hFFE2, 16'hFFE3, 16'hFFE4,
    16'hFFE5, 16'hFFE6, 16'hFFE7, 16'hFFE8, 16'hFFE9, 16'hFFEA, 16'hFFEB, 16'hFFEC,
    16'hFFED, 16'hFFEE, 16'hFFEF, 16'hFFF0, 16'hFFF1, 16'hFFF2, 16'hFFF3, 16'hFFF4,
    16'hFFF5, 16'hFFF6, 16'hFFF7, 16'hFFF8, 16'hFFF9, 16'hFFFA, 16'hFFFB, 16'hFFFC,
    16'hFFFD, 16'hFFFE
};

localparam int Cr_AC_run_code [0:250] = '{
    3, 0, 1, 2, 4, 6, 11, 15, 23, 37, 38, 39, 40, 41, 42, 0, // 0–15
    0, 5, 6, 12, 18, 28, 39, 40, 41, 42, 43, 44, 45, 46, 47, 0, // 16–31
    0, 8, 16, 24, 32, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 0, // 32–47
    0, 9, 25, 54, 55, 56, 57, 58, 0, 0, 0, 0, 0, 0, 0, 0, // 48–63
    0, 10, 29, 65, 0, 17, 36, 98, 114, 130, 20, 82, 0, 21, 0, 0, // 64–79
    0, 13, 29, 65, 0, 17, 36, 98, 114, 130, 20, 82, 0, 21, 0, 0, // 80–95
    0, 14, 7, 34, 113, 18, 50, 129, 145, 161, 8, 35, 66, 177, 193, 21, // 96–111
    82, 209, 0, 36, 51, 98, 114, 130, 9, 10, 22, 23, 24, 25, 26, 37, // 112–127
    38, 39, 40, 41, 42, 52, 53, 54, 55, 56, 57, 58, 67, 68, 69, 70, // 128–143
    71, 72, 73, 74, 83, 84, 85, 86, 87, 88, 89, 90, 99, 100, 101, 102, // 144–159
    103, 104, 105, 106, 115, 116, 117, 118, 119, 120, 121, 122, 131, 132, 133, 134, // 160–175
    135, 136, 137, 138, 146, 147, 148, 149, 150, 151, 152, 153, 154, 162, 163, 164, // 176–191
    165, 166, 167, 168, 169, 170, 178, 179, 180, 181, 182, 183, 184, 185, 186, 194, // 192–207
    195, 196, 197, 198, 199, 200, 201, 202, 210, 211, 212, 213, 214, 215, 216, 217, // 208–223
    218, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 241, 242, 243, 244, 245, // 224–239
    246, 247, 248, 249, 250 // 240–250
};

always_ff @(posedge clk) begin
	if (rst) begin
		// Reset all group-zero flags
		third_8_all_0s   <= 0;
		fourth_8_all_0s  <= 0;
		fifth_8_all_0s   <= 0;
		sixth_8_all_0s   <= 0;
		seventh_8_all_0s <= 0;
		eighth_8_all_0s  <= 0;
	end
	else if (enable_1) begin
		// Set flags based on all elements in group being zero (et_zero flags)
		third_8_all_0s   <= Cr25_et_zero & Cr34_et_zero & Cr43_et_zero & Cr52_et_zero &
		                    Cr61_et_zero & Cr71_et_zero & Cr62_et_zero & Cr53_et_zero;
		fourth_8_all_0s  <= Cr44_et_zero & Cr35_et_zero & Cr26_et_zero & Cr17_et_zero &
		                    Cr18_et_zero & Cr27_et_zero & Cr36_et_zero & Cr45_et_zero;
		fifth_8_all_0s   <= Cr54_et_zero & Cr63_et_zero & Cr72_et_zero & Cr81_et_zero &
		                    Cr82_et_zero & Cr73_et_zero & Cr64_et_zero & Cr55_et_zero;
		sixth_8_all_0s   <= Cr46_et_zero & Cr37_et_zero & Cr28_et_zero & Cr38_et_zero &
		                    Cr47_et_zero & Cr56_et_zero & Cr65_et_zero & Cr74_et_zero;
		seventh_8_all_0s <= Cr83_et_zero & Cr84_et_zero & Cr75_et_zero & Cr66_et_zero &
		                    Cr57_et_zero & Cr48_et_zero & Cr58_et_zero & Cr67_et_zero;
		eighth_8_all_0s  <= Cr76_et_zero & Cr85_et_zero & Cr86_et_zero & Cr77_et_zero &
		                    Cr68_et_zero & Cr78_et_zero & Cr87_et_zero & Cr88_et_zero;
	end
end

/* 
Check if the end of block (EOB) marker should be inserted.
The EOB is used when no more non-zero coefficients remain.
The logic checks in groups of 8 based on the block_counter stage.
*/

always_ff @(posedge clk) begin
	if (rst)
		end_of_block <= 0; // Reset
	else if (enable)
		end_of_block <= 0; // Clear when new block starts
	else if (enable_module & block_counter < 32)
		// If processing in early block, all groups 3–8 must be zero
		end_of_block <= third_8_all_0s & fourth_8_all_0s & fifth_8_all_0s &
		                sixth_8_all_0s & seventh_8_all_0s & eighth_8_all_0s;
	else if (enable_module & block_counter < 48)
		// Later stage: only groups 5–8 must be zero
		end_of_block <= fifth_8_all_0s & sixth_8_all_0s & seventh_8_all_0s & eighth_8_all_0s;
	else if (enable_module & block_counter <= 64)
		// Final stage: only groups 7–8 must be zero
		end_of_block <= seventh_8_all_0s & eighth_8_all_0s;
	else if (enable_module & block_counter > 64)
		// Past valid block range: force EOB
		end_of_block <= 1;
end

// Counter that tracks number of processed coefficients in current block
always_ff @(posedge clk) begin
	if (rst) begin
		block_counter <= 0; // Reset counter
	end
	else if (enable) begin
		block_counter <= 0; // Restart counting for new block
	end	
	else if (enable_module) begin
		block_counter <= block_counter + 1; // Increment on valid processing cycle
	end
end

// Count the total number of output register bits used so far
always_ff @(posedge clk) begin
	if (rst) begin
		output_reg_count <= 0; // Reset
	end
	else if (end_of_block_output) begin
		output_reg_count <= 0; // Clear count after block output
	end
	else if (enable_6) begin
		output_reg_count <= output_reg_count + Cr11_output_count; // Add DC output count
	end	
	else if (enable_latch_7) begin
		output_reg_count <= output_reg_count + Cr12_oc_1; // Add AC output count
	end
end

// Store the previous output_reg_count for comparison (rollover detection)
always_ff @(posedge clk) begin
	if (rst) begin
		old_orc_1 <= 0;
	end
	else if (end_of_block_output) begin
		old_orc_1 <= 0;
	end
	else if (enable_module) begin
		old_orc_1 <= output_reg_count; // Capture current count
	end
end

// Handle all rollover and output pipeline delay logic
always_ff @(posedge clk) begin
	if (rst) begin
		rollover      <= 0;
		rollover_1    <= 0; rollover_2 <= 0;
		rollover_3    <= 0; rollover_4 <= 0;
		rollover_5    <= 0; rollover_6 <= 0;
		rollover_7    <= 0;

		old_orc_2     <= 0;
		orc_3         <= 0; orc_4 <= 0; orc_5 <= 0;
		orc_6         <= 0; orc_7 <= 0; orc_8 <= 0;

		data_ready            <= 0;
		end_of_block_output   <= 0;
		end_of_block_empty    <= 0;
	end
	else if (enable_module) begin
		// Detect if output_reg_count wrapped around
		rollover   <= (old_orc_1 > output_reg_count);
		rollover_1 <= rollover;
		rollover_2 <= rollover_1;
		rollover_3 <= rollover_2;
		rollover_4 <= rollover_3;
		rollover_5 <= rollover_4;
		rollover_6 <= rollover_5;
		rollover_7 <= rollover_6;

		// Delay old output count through pipeline
		old_orc_2 <= old_orc_1;
		orc_3     <= old_orc_2;
		orc_4     <= orc_3; orc_5 <= orc_4;
		orc_6     <= orc_5; orc_7 <= orc_6;
		orc_8     <= orc_7;

		// Signal that output data is ready
		data_ready          <= rollover_6 | (block_counter == 77);
		end_of_block_output <= (block_counter == 77);

		// Indicate block was empty and ended
		end_of_block_empty  <= rollover_7 & (block_counter == 77) & (output_reg_count == 0);
	end
end
always_ff @(posedge clk) begin
	if (rst) begin
		JPEG_bs_5 <= 32'd0;
	end else if (enable_module) begin
		for (int i = 1; i < 32; i++) begin
			JPEG_bs_5[i] <= (rollover_6 && (orc_7 > (31 - i))) ? JPEG_ro_bs_4[i] : JPEG_bs_4[i];
		end
		JPEG_bs_5[0] <= JPEG_bs_4[0]; // Bit 0 is always from normal path
	end
end


// Shifts JPEG bitstreams based on old_orc_6 and Cr12_edge_4
// This is part of the alignment pipeline logic for the bitstream
always_ff @(posedge clk) begin
	if (rst) begin
		JPEG_bs_4     <= 32'd0;
		JPEG_ro_bs_4  <= 32'd0;
	end
	else if (enable_module) begin
		// If old_orc_6 == 1, shift right to align JPEG_bs_3, else keep as-is
		JPEG_bs_4 <= (old_orc_6 == 1) ? JPEG_bs_3 >> 1 : JPEG_bs_3;

		// If Cr12_edge_4 <= 1, shift left (add a zero bit), else pass through
		JPEG_ro_bs_4 <= (Cr12_edge_4 <= 1) ? JPEG_ro_bs_3 << 1 : JPEG_ro_bs_3;
	end
end

// Stage 4 of bitstream alignment pipeline
// Shifts and aligns based on old_orc_5 and Cr12_edge_3
always_ff @(posedge clk) begin
	if (rst) begin
		JPEG_bs_3       <= 0;
		old_orc_6       <= 0;
		JPEG_ro_bs_3    <= 0;
		Cr12_edge_4     <= 0;
	end
	else if (enable_module) begin
		// Right-shift by 2 bits if old_orc_5 >= 2
		JPEG_bs_3 <= (old_orc_5 >= 2) ? (JPEG_bs_2 >> 2) : JPEG_bs_2;
		old_orc_6 <= (old_orc_5 >= 2) ? (old_orc_5 - 2) : old_orc_5;

		// Left-shift by 2 bits if edge <= 2
		JPEG_ro_bs_3 <= (Cr12_edge_3 <= 2) ? (JPEG_ro_bs_2 << 2) : JPEG_ro_bs_2;
		Cr12_edge_4  <= (Cr12_edge_3 <= 2) ? Cr12_edge_3 : (Cr12_edge_3 - 2);
	end
end

// Stage 3 of bitstream alignment pipeline
always_ff @(posedge clk) begin
	if (rst) begin
		JPEG_bs_2       <= 0;
		old_orc_5       <= 0;
		JPEG_ro_bs_2    <= 0;
		Cr12_edge_3     <= 0;
	end
	else if (enable_module) begin
		JPEG_bs_2    <= (old_orc_4 >= 4) ? (JPEG_bs_1 >> 4) : JPEG_bs_1;
		old_orc_5    <= (old_orc_4 >= 4) ? (old_orc_4 - 4) : old_orc_4;
		JPEG_ro_bs_2 <= (Cr12_edge_2 <= 4) ? (JPEG_ro_bs_1 << 4) : JPEG_ro_bs_1;
		Cr12_edge_3  <= (Cr12_edge_2 <= 4) ? Cr12_edge_2 : (Cr12_edge_2 - 4);
	end
end

// Stage 2 of bitstream alignment pipeline
always_ff @(posedge clk) begin
	if (rst) begin
		JPEG_bs_1       <= 0;
		old_orc_4       <= 0;
		JPEG_ro_bs_1    <= 0;
		Cr12_edge_2     <= 0;
	end
	else if (enable_module) begin
		JPEG_bs_1    <= (old_orc_3 >= 8) ? (JPEG_bs >> 8) : JPEG_bs;
		old_orc_4    <= (old_orc_3 >= 8) ? (old_orc_3 - 8) : old_orc_3;
		JPEG_ro_bs_1 <= (Cr12_edge_1 <= 8) ? (JPEG_ro_bs << 8) : JPEG_ro_bs;
		Cr12_edge_2  <= (Cr12_edge_1 <= 8) ? Cr12_edge_1 : (Cr12_edge_1 - 8);
	end
end

// Stage 1 of bitstream alignment pipeline (initial load from Cr11 bits)
always_ff @(posedge clk) begin
	if (rst) begin
		JPEG_bs            <= 0;
		old_orc_3          <= 0;
		JPEG_ro_bs         <= 0;
		Cr12_edge_1        <= 0;
		Cr11_JPEG_bits_1   <= 0;
	end
	else if (enable_module) begin
		// Right-shift Cr11 bits if output count >= 16, else left-shift by 6
		JPEG_bs <= (old_orc_2 >= 16) ? (Cr11_JPEG_bits >> 10) : (Cr11_JPEG_bits << 6);
		old_orc_3 <= (old_orc_2 >= 16) ? (old_orc_2 - 16) : old_orc_2;

		// Adjust Cr12 edge and corresponding bitstream
		JPEG_ro_bs      <= (Cr12_edge <= 16) ? (Cr11_JPEG_bits_1 << 16) : Cr11_JPEG_bits_1;
		Cr12_edge_1     <= (Cr12_edge <= 16) ? Cr12_edge : (Cr12_edge - 16);

		// Save Cr11 JPEG bits for later use
		Cr11_JPEG_bits_1 <= Cr11_JPEG_bits;
	end
end
always_ff @(posedge clk) begin
	if (rst) begin
		Cr12_JPEG_bits <= 26'd0;
		Cr12_edge      <= 5'd0;
	end else if (enable_module) begin
		// Bits 25 down to 10: conditionally select from Huffman or LSBs
		for (int i = 10; i <= 25; i++) begin
			Cr12_JPEG_bits[i] <= (Cr12_Huff_shift_1 >= (26 - i)) ? Cr12_JPEG_LSBs_4[i] : Cr12_Huff_2[25 - i];
		end

		// Bits 9 down to 0: always from LSBs
		Cr12_JPEG_bits[9:0] <= Cr12_JPEG_LSBs_4[9:0];

		// Update edge value
		Cr12_edge <= old_orc_2 + 26;
	end
end
always_ff @(posedge clk) begin
	if (rst) begin
		Cr11_JPEG_bits <= 26'd0;
	end else if (enable_7) begin
		// Merge Huffman and LSBs
		for (int i = 15; i <= 25; i++) begin
			Cr11_JPEG_bits[i] <= (Cr11_Huff_shift_1 >= (26 - i)) 
			                   ? Cr11_JPEG_LSBs_3[i - 4]       // LSB index from 11 to 21
			                   : Cr11_Huff_2[25 - i];           // Huffman index from 10 to 0
		end
		Cr11_JPEG_bits[14:4] <= Cr11_JPEG_LSBs_3[10:0]; // Lower 11 bits from LSBs
	end else if (enable_latch_8) begin
		// Pass-through from Cr12
		Cr11_JPEG_bits <= Cr12_JPEG_bits;
	end
end

// Prepare Cr12 output count and LSB shift
always_ff @(posedge clk) begin
	if (rst) begin
		Cr12_oc_1          <= 0;
		Cr12_JPEG_LSBs_4   <= 0;
		Cr12_Huff_2        <= 0;
		Cr12_Huff_shift_1  <= 0;
	end
	else if (enable_module) begin
		// If run-length is not skipped (zrl), calculate output count
		Cr12_oc_1 <= (Cr12_et_zero_5 && !code_15_0 && block_counter != 67)
			? 0 : Cr12_bits_3 + Cr12_Huff_count_1;
		Cr12_JPEG_LSBs_4   <= Cr12_JPEG_LSBs_3 << Cr12_Huff_shift; // Align LSBs
		Cr12_Huff_2        <= Cr12_Huff_1;
		Cr12_Huff_shift_1  <= Cr12_Huff_shift;
	end
end

// Prepare Cr11 Huffman and LSBs before merging
always_ff @(posedge clk) begin
	if (rst) begin
		Cr11_JPEG_LSBs_3    <= 0;
		Cr11_Huff_2         <= 0;
		Cr11_Huff_shift_1   <= 0;
	end
	else if (enable_6) begin
		Cr11_JPEG_LSBs_3    <= Cr11_JPEG_LSBs_2 << Cr11_Huff_shift; // Align
		Cr11_Huff_2         <= Cr11_Huff_1;
		Cr11_Huff_shift_1   <= Cr11_Huff_shift;
	end
end

// Pipeline stage for Cr12 Huffman shift, amplitude bits, and control flags
always_ff @(posedge clk) begin
	if (rst) begin
		Cr12_Huff_shift     <= 0;
		Cr12_Huff_1         <= 0;
		Cr12_JPEG_LSBs_3    <= 0;
		Cr12_bits_3         <= 0;
		Cr12_Huff_count_1   <= 0;
		Cr12_et_zero_5      <= 0;
		code_15_0           <= 0;
	end
	else if (enable_module) begin
		Cr12_Huff_shift     <= 16 - Cr12_Huff_count;
		Cr12_Huff_1         <= Cr12_Huff;
		Cr12_JPEG_LSBs_3    <= Cr12_JPEG_LSBs_2;
		Cr12_bits_3         <= Cr12_bits_2;
		Cr12_Huff_count_1   <= Cr12_Huff_count;
		Cr12_et_zero_5      <= Cr12_et_zero_4;
		code_15_0           <= zrl_et_15 & !end_of_block; // Use 15-0 ZRL only if not end of block
	end
end

// Cr11 output count and Huffman alignment for final JPEG stream encoding
always_ff @(posedge clk) begin
	if (rst) begin
		Cr11_output_count   <= 0;
		Cr11_JPEG_LSBs_2    <= 0;
		Cr11_Huff_shift     <= 0;
		Cr11_Huff_1         <= 0;
	end
	else if (enable_5) begin
		Cr11_output_count   <= Cr11_bits_1 + Cr11_Huff_count;
		Cr11_JPEG_LSBs_2    <= Cr11_JPEG_LSBs_1 << Cr11_amp_shift;
		Cr11_Huff_shift     <= 11 - Cr11_Huff_count;
		Cr11_Huff_1         <= Cr11_Huff;
	end
end

// Cr12 AC Huffman and amplitude alignment
always_ff @(posedge clk) begin
	if (rst) begin
		Cr12_JPEG_LSBs_2    <= 0;
		Cr12_Huff           <= 0;
		Cr12_Huff_count     <= 0;
		Cr12_bits_2         <= 0;
		Cr12_et_zero_4      <= 0;
		zrl_et_15           <= 0;
		zrl_3               <= 0;
	end
	else if (enable_module) begin
		Cr12_JPEG_LSBs_2    <= Cr12_JPEG_LSBs_1 << Cr12_amp_shift;
		Cr12_Huff           <= Cr_AC[Cr12_code_entry];
		Cr12_Huff_count     <= Cr_AC_code_length[Cr12_code_entry];
		Cr12_bits_2         <= Cr12_bits_1;
		Cr12_et_zero_4      <= Cr12_et_zero_3;
		zrl_et_15           <= (zrl_3 == 15); // Detect 15 zero run
		zrl_3               <= zrl_2;
	end
end

// Cr11 DC Huffman encoding and bit position prep
always_ff @(posedge clk) begin
	if (rst) begin
		Cr11_Huff           <= 0;
		Cr11_Huff_count     <= 0;
		Cr11_amp_shift      <= 0;
		Cr11_JPEG_LSBs_1    <= 0;
		Cr11_bits_1         <= 0;
	end
	else if (enable_4) begin
		Cr11_Huff[10:0]     <= Cr_DC[Cr11_bits];
		Cr11_Huff_count     <= Cr_DC_code_length[Cr11_bits];
		Cr11_amp_shift      <= 11 - Cr11_bits;
		Cr11_JPEG_LSBs_1    <= Cr11_JPEG_LSBs;
		Cr11_bits_1         <= Cr11_bits;
	end
end

// Cr12 AC code index lookup and amplitude shift calculation
always_ff @(posedge clk) begin
	if (rst) begin
		Cr12_code_entry     <= 0;
		Cr12_JPEG_LSBs_1    <= 0;
		Cr12_amp_shift      <= 0;
		Cr12_bits_1         <= 0;
		Cr12_et_zero_3      <= 0;
		zrl_2               <= 0;
	end
	else if (enable_module) begin
		Cr12_code_entry     <= Cr_AC_run_code[code_index]; // Lookup combined run-length & size code
		Cr12_JPEG_LSBs_1    <= Cr12_JPEG_LSBs;
		Cr12_amp_shift      <= 10 - Cr12_bits;
		Cr12_bits_1         <= Cr12_bits;
		Cr12_et_zero_3      <= Cr12_et_zero_2;
		zrl_2               <= zrl_1;
	end
end

// Determine Cr12 bits, LSBs, zero run tracking
always_ff @(posedge clk) begin
	if (rst) begin
		Cr12_bits        <= 0;
		Cr12_JPEG_LSBs   <= 0;
		zrl_1            <= 0;
		Cr12_et_zero_2   <= 0;
	end
	else if (enable_module) begin
		// Select number of bits based on sign
		Cr12_bits        <= Cr12_msb_1 ? Cr12_bits_neg : Cr12_bits_pos;

		// Save 10-bit amplitude (ignores sign bit)
		Cr12_JPEG_LSBs   <= Cr12_amp[9:0];

		// Zero Run Length:
		// If block_counter == 62 and Cr12 is zero => reset to 0
		// Else propagate current zero_run_length
		zrl_1            <= (block_counter == 62 && Cr12_et_zero) ? 0 : zero_run_length;

		// Latch the zero flag and MSB
		Cr12_et_zero_2   <= Cr12_et_zero_1;
	end
end

// Compute Cr11 amplitude value to encode based on its sign
always_ff @(posedge clk) begin
	if (rst) begin
		Cr11_amp <= 0;
	end
	else if (enable_2) begin
		// Choose amplitude based on MSB
		Cr11_amp <= Cr11_msb ? Cr11_1_neg : Cr11_1_pos;
	end
end

// Count the number of consecutive zeros (zero run length)
always_ff @(posedge clk) begin
	if (rst) begin
		zero_run_length <= 0;
	end
	else if (enable) begin
		zero_run_length <= 0;
	end
	else if (enable_module) begin
		zero_run_length <= Cr12_et_zero ? zero_run_length + 1 : 0;
	end
end

// Store Cr12 amplitude and zero flag
always_ff @(posedge clk) begin
	if (rst) begin
		Cr12_amp        <= 0;
		Cr12_et_zero_1  <= 0;
		Cr12_msb_1      <= 0;
	end
	else if (enable_module) begin
		// Choose amplitude value based on sign
		Cr12_amp        <= Cr12_msb ? Cr12_neg : Cr12_pos;

		// Latch current state
		Cr12_et_zero_1  <= Cr12_et_zero;
		Cr12_msb_1      <= Cr12_msb;
	end
end

// Cr11: Compute signed difference and extract sign bit (MSB)
always_ff @(posedge clk) begin
	if (rst) begin
		Cr11_1_pos     <= 0;
		Cr11_1_neg     <= 0;
		Cr11_msb       <= 0;
		Cr11_previous  <= 0;
	end
	else if (enable_1) begin
		Cr11_1_pos     <= Cr11_diff;           // Store current positive diff
		Cr11_1_neg     <= Cr11_diff - 1;       // Store adjusted neg diff
		Cr11_msb       <= Cr11_diff[11];       // MSB determines sign
		Cr11_previous  <= Cr11_1;              // Store previous value
	end
end

// Cr12 to Cr88: Initialize all AC coefficient helper registers on reset
// These hold signed positive and negative amplitudes, MSB (sign), and zero status
always_ff @(posedge clk) begin
	if (rst) begin
		// Loop replacement (manual unrolling for synthesis compatibility)
		Cr12_pos <= 0; Cr12_neg <= 0; Cr12_msb <= 0; Cr12_et_zero <= 0;
		Cr13_pos <= 0; Cr13_neg <= 0; Cr13_msb <= 0; Cr13_et_zero <= 0;
		Cr14_pos <= 0; Cr14_neg <= 0; Cr14_msb <= 0; Cr14_et_zero <= 0;
		Cr15_pos <= 0; Cr15_neg <= 0; Cr15_msb <= 0; Cr15_et_zero <= 0;
		Cr16_pos <= 0; Cr16_neg <= 0; Cr16_msb <= 0; Cr16_et_zero <= 0;
		Cr17_pos <= 0; Cr17_neg <= 0; Cr17_msb <= 0; Cr17_et_zero <= 0;
		Cr18_pos <= 0; Cr18_neg <= 0; Cr18_msb <= 0; Cr18_et_zero <= 0;

		Cr21_pos <= 0; Cr21_neg <= 0; Cr21_msb <= 0; Cr21_et_zero <= 0;
		Cr22_pos <= 0; Cr22_neg <= 0; Cr22_msb <= 0; Cr22_et_zero <= 0;
		Cr23_pos <= 0; Cr23_neg <= 0; Cr23_msb <= 0; Cr23_et_zero <= 0;
		Cr24_pos <= 0; Cr24_neg <= 0; Cr24_msb <= 0; Cr24_et_zero <= 0;
		Cr25_pos <= 0; Cr25_neg <= 0; Cr25_msb <= 0; Cr25_et_zero <= 0;
		Cr26_pos <= 0; Cr26_neg <= 0; Cr26_msb <= 0; Cr26_et_zero <= 0;
		Cr27_pos <= 0; Cr27_neg <= 0; Cr27_msb <= 0; Cr27_et_zero <= 0;
		Cr28_pos <= 0; Cr28_neg <= 0; Cr28_msb <= 0; Cr28_et_zero <= 0;

		Cr31_pos <= 0; Cr31_neg <= 0; Cr31_msb <= 0; Cr31_et_zero <= 0;
		Cr32_pos <= 0; Cr32_neg <= 0; Cr32_msb <= 0; Cr32_et_zero <= 0;
		Cr33_pos <= 0; Cr33_neg <= 0; Cr33_msb <= 0; Cr33_et_zero <= 0;
		Cr34_pos <= 0; Cr34_neg <= 0; Cr34_msb <= 0; Cr34_et_zero <= 0;
		Cr35_pos <= 0; Cr35_neg <= 0; Cr35_msb <= 0; Cr35_et_zero <= 0;
		Cr36_pos <= 0; Cr36_neg <= 0; Cr36_msb <= 0; Cr36_et_zero <= 0;
		Cr37_pos <= 0; Cr37_neg <= 0; Cr37_msb <= 0; Cr37_et_zero <= 0;
		Cr38_pos <= 0; Cr38_neg <= 0; Cr38_msb <= 0; Cr38_et_zero <= 0;

		Cr41_pos <= 0; Cr41_neg <= 0; Cr41_msb <= 0; Cr41_et_zero <= 0;
		Cr42_pos <= 0; Cr42_neg <= 0; Cr42_msb <= 0; Cr42_et_zero <= 0;
		Cr43_pos <= 0; Cr43_neg <= 0; Cr43_msb <= 0; Cr43_et_zero <= 0;
		Cr44_pos <= 0; Cr44_neg <= 0; Cr44_msb <= 0; Cr44_et_zero <= 0;
		Cr45_pos <= 0; Cr45_neg <= 0; Cr45_msb <= 0; Cr45_et_zero <= 0;
		Cr46_pos <= 0; Cr46_neg <= 0; Cr46_msb <= 0; Cr46_et_zero <= 0;
		Cr47_pos <= 0; Cr47_neg <= 0; Cr47_msb <= 0; Cr47_et_zero <= 0;
		Cr48_pos <= 0; Cr48_neg <= 0; Cr48_msb <= 0; Cr48_et_zero <= 0;

		Cr51_pos <= 0; Cr51_neg <= 0; Cr51_msb <= 0; Cr51_et_zero <= 0;
		Cr52_pos <= 0; Cr52_neg <= 0; Cr52_msb <= 0; Cr52_et_zero <= 0;
		Cr53_pos <= 0; Cr53_neg <= 0; Cr53_msb <= 0; Cr53_et_zero <= 0;
		Cr54_pos <= 0; Cr54_neg <= 0; Cr54_msb <= 0; Cr54_et_zero <= 0;
		Cr55_pos <= 0; Cr55_neg <= 0; Cr55_msb <= 0; Cr55_et_zero <= 0;
		Cr56_pos <= 0; Cr56_neg <= 0; Cr56_msb <= 0; Cr56_et_zero <= 0;
		Cr57_pos <= 0; Cr57_neg <= 0; Cr57_msb <= 0; Cr57_et_zero <= 0;
		Cr58_pos <= 0; Cr58_neg <= 0; Cr58_msb <= 0; Cr58_et_zero <= 0;

		Cr61_pos <= 0; Cr61_neg <= 0; Cr61_msb <= 0; Cr61_et_zero <= 0;
		Cr62_pos <= 0; Cr62_neg <= 0; Cr62_msb <= 0; Cr62_et_zero <= 0;
		Cr63_pos <= 0; Cr63_neg <= 0; Cr63_msb <= 0; Cr63_et_zero <= 0;
		Cr64_pos <= 0; Cr64_neg <= 0; Cr64_msb <= 0; Cr64_et_zero <= 0;
		Cr65_pos <= 0; Cr65_neg <= 0; Cr65_msb <= 0; Cr65_et_zero <= 0;
		Cr66_pos <= 0; Cr66_neg <= 0; Cr66_msb <= 0; Cr66_et_zero <= 0;
		Cr67_pos <= 0; Cr67_neg <= 0; Cr67_msb <= 0; Cr67_et_zero <= 0;
		Cr68_pos <= 0; Cr68_neg <= 0; Cr68_msb <= 0; Cr68_et_zero <= 0;

		Cr71_pos <= 0; Cr71_neg <= 0; Cr71_msb <= 0; Cr71_et_zero <= 0;
		Cr72_pos <= 0; Cr72_neg <= 0; Cr72_msb <= 0; Cr72_et_zero <= 0;
		Cr73_pos <= 0; Cr73_neg <= 0; Cr73_msb <= 0; Cr73_et_zero <= 0;
		Cr74_pos <= 0; Cr74_neg <= 0; Cr74_msb <= 0; Cr74_et_zero <= 0;
		Cr75_pos <= 0; Cr75_neg <= 0; Cr75_msb <= 0; Cr75_et_zero <= 0;
		Cr76_pos <= 0; Cr76_neg <= 0; Cr76_msb <= 0; Cr76_et_zero <= 0;
		Cr77_pos <= 0; Cr77_neg <= 0; Cr77_msb <= 0; Cr77_et_zero <= 0;
		Cr78_pos <= 0; Cr78_neg <= 0; Cr78_msb <= 0; Cr78_et_zero <= 0;

		Cr81_pos <= 0; Cr81_neg <= 0; Cr81_msb <= 0; Cr81_et_zero <= 0;
		Cr82_pos <= 0; Cr82_neg <= 0; Cr82_msb <= 0; Cr82_et_zero <= 0;
		Cr83_pos <= 0; Cr83_neg <= 0; Cr83_msb <= 0; Cr83_et_zero <= 0;
		Cr84_pos <= 0; Cr84_neg <= 0; Cr84_msb <= 0; Cr84_et_zero <= 0;
		Cr85_pos <= 0; Cr85_neg <= 0; Cr85_msb <= 0; Cr85_et_zero <= 0;
		Cr86_pos <= 0; Cr86_neg <= 0; Cr86_msb <= 0; Cr86_et_zero <= 0;
		Cr87_pos <= 0; Cr87_neg <= 0; Cr87_msb <= 0; Cr87_et_zero <= 0;
		Cr88_pos <= 0; Cr88_neg <= 0; Cr88_msb <= 0; Cr88_et_zero <= 0;
	end

else if (enable) begin 
		Cr12_pos <= Cr12;	   
		Cr12_neg <= Cr12 - 1;
		Cr12_msb <= Cr12[10];
		Cr12_et_zero <= !(|Cr12);
		Cr13_pos <= Cr13;	   
		Cr13_neg <= Cr13 - 1;
		Cr13_msb <= Cr13[10];
		Cr13_et_zero <= !(|Cr13);
		Cr14_pos <= Cr14;	   
		Cr14_neg <= Cr14 - 1;
		Cr14_msb <= Cr14[10];
		Cr14_et_zero <= !(|Cr14);
		Cr15_pos <= Cr15;	   
		Cr15_neg <= Cr15 - 1;
		Cr15_msb <= Cr15[10];
		Cr15_et_zero <= !(|Cr15);
		Cr16_pos <= Cr16;	   
		Cr16_neg <= Cr16 - 1;
		Cr16_msb <= Cr16[10];
		Cr16_et_zero <= !(|Cr16);
		Cr17_pos <= Cr17;	   
		Cr17_neg <= Cr17 - 1;
		Cr17_msb <= Cr17[10];
		Cr17_et_zero <= !(|Cr17);
		Cr18_pos <= Cr18;	   
		Cr18_neg <= Cr18 - 1;
		Cr18_msb <= Cr18[10];
		Cr18_et_zero <= !(|Cr18);
		Cr21_pos <= Cr21;	   
		Cr21_neg <= Cr21 - 1;
		Cr21_msb <= Cr21[10];
		Cr21_et_zero <= !(|Cr21);
		Cr22_pos <= Cr22;	   
		Cr22_neg <= Cr22 - 1;
		Cr22_msb <= Cr22[10];
		Cr22_et_zero <= !(|Cr22);
		Cr23_pos <= Cr23;	   
		Cr23_neg <= Cr23 - 1;
		Cr23_msb <= Cr23[10];
		Cr23_et_zero <= !(|Cr23);
		Cr24_pos <= Cr24;	   
		Cr24_neg <= Cr24 - 1;
		Cr24_msb <= Cr24[10];
		Cr24_et_zero <= !(|Cr24);
		Cr25_pos <= Cr25;	   
		Cr25_neg <= Cr25 - 1;
		Cr25_msb <= Cr25[10];
		Cr25_et_zero <= !(|Cr25);
		Cr26_pos <= Cr26;	   
		Cr26_neg <= Cr26 - 1;
		Cr26_msb <= Cr26[10];
		Cr26_et_zero <= !(|Cr26);
		Cr27_pos <= Cr27;	   
		Cr27_neg <= Cr27 - 1;
		Cr27_msb <= Cr27[10];
		Cr27_et_zero <= !(|Cr27);
		Cr28_pos <= Cr28;	   
		Cr28_neg <= Cr28 - 1;
		Cr28_msb <= Cr28[10];
		Cr28_et_zero <= !(|Cr28);
        Cr31_pos <= Cr31;	   
		Cr31_neg <= Cr31 - 1;
		Cr31_msb <= Cr31[10];
		Cr31_et_zero <= !(|Cr31);
		Cr32_pos <= Cr32;	   
		Cr32_neg <= Cr32 - 1;
		Cr32_msb <= Cr32[10];
		Cr32_et_zero <= !(|Cr32);
		Cr33_pos <= Cr33;	   
		Cr33_neg <= Cr33 - 1;
		Cr33_msb <= Cr33[10];
		Cr33_et_zero <= !(|Cr33);
		Cr34_pos <= Cr34;	   
		Cr34_neg <= Cr34 - 1;
		Cr34_msb <= Cr34[10];
		Cr34_et_zero <= !(|Cr34);
		Cr35_pos <= Cr35;	   
		Cr35_neg <= Cr35 - 1;
		Cr35_msb <= Cr35[10];
		Cr35_et_zero <= !(|Cr35);
		Cr36_pos <= Cr36;	   
		Cr36_neg <= Cr36 - 1;
		Cr36_msb <= Cr36[10];
		Cr36_et_zero <= !(|Cr36);
		Cr37_pos <= Cr37;	   
		Cr37_neg <= Cr37 - 1;
		Cr37_msb <= Cr37[10];
		Cr37_et_zero <= !(|Cr37);
		Cr38_pos <= Cr38;	   
		Cr38_neg <= Cr38 - 1;
		Cr38_msb <= Cr38[10];
		Cr38_et_zero <= !(|Cr38);
		Cr41_pos <= Cr41;	   
		Cr41_neg <= Cr41 - 1;
		Cr41_msb <= Cr41[10];
		Cr41_et_zero <= !(|Cr41);
		Cr42_pos <= Cr42;	   
		Cr42_neg <= Cr42 - 1;
		Cr42_msb <= Cr42[10];
		Cr42_et_zero <= !(|Cr42);
		Cr43_pos <= Cr43;	   
		Cr43_neg <= Cr43 - 1;
		Cr43_msb <= Cr43[10];
		Cr43_et_zero <= !(|Cr43);
		Cr44_pos <= Cr44;	   
		Cr44_neg <= Cr44 - 1;
		Cr44_msb <= Cr44[10];
		Cr44_et_zero <= !(|Cr44);
		Cr45_pos <= Cr45;	   
		Cr45_neg <= Cr45 - 1;
		Cr45_msb <= Cr45[10];
		Cr45_et_zero <= !(|Cr45);
		Cr46_pos <= Cr46;	   
		Cr46_neg <= Cr46 - 1;
		Cr46_msb <= Cr46[10];
		Cr46_et_zero <= !(|Cr46);
		Cr47_pos <= Cr47;	   
		Cr47_neg <= Cr47 - 1;
		Cr47_msb <= Cr47[10];
		Cr47_et_zero <= !(|Cr47);
		Cr48_pos <= Cr48;	   
		Cr48_neg <= Cr48 - 1;
		Cr48_msb <= Cr48[10];
		Cr48_et_zero <= !(|Cr48);
		Cr51_pos <= Cr51;	   
		Cr51_neg <= Cr51 - 1;
		Cr51_msb <= Cr51[10];
		Cr51_et_zero <= !(|Cr51);
		Cr52_pos <= Cr52;	   
		Cr52_neg <= Cr52 - 1;
		Cr52_msb <= Cr52[10];
		Cr52_et_zero <= !(|Cr52);
		Cr53_pos <= Cr53;	   
		Cr53_neg <= Cr53 - 1;
		Cr53_msb <= Cr53[10];
		Cr53_et_zero <= !(|Cr53);
		Cr54_pos <= Cr54;	   
		Cr54_neg <= Cr54 - 1;
		Cr54_msb <= Cr54[10];
		Cr54_et_zero <= !(|Cr54);
		Cr55_pos <= Cr55;	   
		Cr55_neg <= Cr55 - 1;
		Cr55_msb <= Cr55[10];
		Cr55_et_zero <= !(|Cr55);
        Cr56_pos <= Cr56;	   
		Cr56_neg <= Cr56 - 1;
		Cr56_msb <= Cr56[10];
		Cr56_et_zero <= !(|Cr56);
		Cr57_pos <= Cr57;	   
		Cr57_neg <= Cr57 - 1;
		Cr57_msb <= Cr57[10];
		Cr57_et_zero <= !(|Cr57);
		Cr58_pos <= Cr58;	   
		Cr58_neg <= Cr58 - 1;
		Cr58_msb <= Cr58[10];
		Cr58_et_zero <= !(|Cr58);
		Cr61_pos <= Cr61;	   
		Cr61_neg <= Cr61 - 1;
		Cr61_msb <= Cr61[10];
		Cr61_et_zero <= !(|Cr61);
		Cr62_pos <= Cr62;	   
		Cr62_neg <= Cr62 - 1;
		Cr62_msb <= Cr62[10];
		Cr62_et_zero <= !(|Cr62);
		Cr63_pos <= Cr63;	   
		Cr63_neg <= Cr63 - 1;
		Cr63_msb <= Cr63[10];
		Cr63_et_zero <= !(|Cr63);
		Cr64_pos <= Cr64;	   
		Cr64_neg <= Cr64 - 1;
		Cr64_msb <= Cr64[10];
		Cr64_et_zero <= !(|Cr64);
		Cr65_pos <= Cr65;	   
		Cr65_neg <= Cr65 - 1;
		Cr65_msb <= Cr65[10];
		Cr65_et_zero <= !(|Cr65);
		Cr66_pos <= Cr66;	   
		Cr66_neg <= Cr66 - 1;
		Cr66_msb <= Cr66[10];
		Cr66_et_zero <= !(|Cr66);
		Cr67_pos <= Cr67;	   
		Cr67_neg <= Cr67 - 1;
		Cr67_msb <= Cr67[10];
		Cr67_et_zero <= !(|Cr67);
		Cr68_pos <= Cr68;	   
		Cr68_neg <= Cr68 - 1;
		Cr68_msb <= Cr68[10];
		Cr68_et_zero <= !(|Cr68);
		Cr71_pos <= Cr71;	   
		Cr71_neg <= Cr71 - 1;
		Cr71_msb <= Cr71[10];
		Cr71_et_zero <= !(|Cr71);
		Cr72_pos <= Cr72;	   
		Cr72_neg <= Cr72 - 1;
		Cr72_msb <= Cr72[10];
		Cr72_et_zero <= !(|Cr72);
		Cr73_pos <= Cr73;	   
		Cr73_neg <= Cr73 - 1;
		Cr73_msb <= Cr73[10];
		Cr73_et_zero <= !(|Cr73);
		Cr74_pos <= Cr74;	   
		Cr74_neg <= Cr74 - 1;
		Cr74_msb <= Cr74[10];
		Cr74_et_zero <= !(|Cr74);
		Cr75_pos <= Cr75;	   
		Cr75_neg <= Cr75 - 1;
		Cr75_msb <= Cr75[10];
		Cr75_et_zero <= !(|Cr75);
		Cr76_pos <= Cr76;	   
		Cr76_neg <= Cr76 - 1;
        Cr76_msb <= Cr76[10];
		Cr76_et_zero <= !(|Cr76);
		Cr77_pos <= Cr77;	   
		Cr77_neg <= Cr77 - 1;
		Cr77_msb <= Cr77[10];
		Cr77_et_zero <= !(|Cr77);
		Cr78_pos <= Cr78;	   
		Cr78_neg <= Cr78 - 1;
		Cr78_msb <= Cr78[10];
		Cr78_et_zero <= !(|Cr78);
		Cr81_pos <= Cr81;	   
		Cr81_neg <= Cr81 - 1;
		Cr81_msb <= Cr81[10];
		Cr81_et_zero <= !(|Cr81);
		Cr82_pos <= Cr82;	   
		Cr82_neg <= Cr82 - 1;
		Cr82_msb <= Cr82[10];
		Cr82_et_zero <= !(|Cr82);
		Cr83_pos <= Cr83;	   
		Cr83_neg <= Cr83 - 1;
		Cr83_msb <= Cr83[10];
		Cr83_et_zero <= !(|Cr83);
		Cr84_pos <= Cr84;	   
		Cr84_neg <= Cr84 - 1;
		Cr84_msb <= Cr84[10];
		Cr84_et_zero <= !(|Cr84);
		Cr85_pos <= Cr85;	   
		Cr85_neg <= Cr85 - 1;
		Cr85_msb <= Cr85[10];
		Cr85_et_zero <= !(|Cr85);
		Cr86_pos <= Cr86;	   
		Cr86_neg <= Cr86 - 1;
		Cr86_msb <= Cr86[10];
		Cr86_et_zero <= !(|Cr86);
		Cr87_pos <= Cr87;	   
		Cr87_neg <= Cr87 - 1;
		Cr87_msb <= Cr87[10];
		Cr87_et_zero <= !(|Cr87);
		Cr88_pos <= Cr88;	   
		Cr88_neg <= Cr88 - 1;
		Cr88_msb <= Cr88[10];
		Cr88_et_zero <= !(|Cr88);
		end
	else if (enable_module) begin 
		Cr12_pos <= Cr21_pos;	   
		Cr12_neg <= Cr21_neg;
		Cr12_msb <= Cr21_msb;
		Cr12_et_zero <= Cr21_et_zero;
		Cr21_pos <= Cr31_pos;	   
		Cr21_neg <= Cr31_neg;
		Cr21_msb <= Cr31_msb;
		Cr21_et_zero <= Cr31_et_zero;
		Cr31_pos <= Cr22_pos;	   
		Cr31_neg <= Cr22_neg;
		Cr31_msb <= Cr22_msb;
		Cr31_et_zero <= Cr22_et_zero;
		Cr22_pos <= Cr13_pos;	   
		Cr22_neg <= Cr13_neg;
		Cr22_msb <= Cr13_msb;
		Cr22_et_zero <= Cr13_et_zero;
		Cr13_pos <= Cr14_pos;	   
		Cr13_neg <= Cr14_neg;
		Cr13_msb <= Cr14_msb;
		Cr13_et_zero <= Cr14_et_zero;
		Cr14_pos <= Cr23_pos;	   
		Cr14_neg <= Cr23_neg;
		Cr14_msb <= Cr23_msb;
		Cr14_et_zero <= Cr23_et_zero;
		Cr23_pos <= Cr32_pos;	   
		Cr23_neg <= Cr32_neg;
		Cr23_msb <= Cr32_msb;
		Cr23_et_zero <= Cr32_et_zero;
		Cr32_pos <= Cr41_pos;	   
		Cr32_neg <= Cr41_neg;
		Cr32_msb <= Cr41_msb;
		Cr32_et_zero <= Cr41_et_zero;
		Cr41_pos <= Cr51_pos;	   
		Cr41_neg <= Cr51_neg;
		Cr41_msb <= Cr51_msb;
		Cr41_et_zero <= Cr51_et_zero;
		Cr51_pos <= Cr42_pos;	   
		Cr51_neg <= Cr42_neg;
		Cr51_msb <= Cr42_msb;
		Cr51_et_zero <= Cr42_et_zero;
		Cr42_pos <= Cr33_pos;	   
		Cr42_neg <= Cr33_neg;
		Cr42_msb <= Cr33_msb;
		Cr42_et_zero <= Cr33_et_zero;
		Cr33_pos <= Cr24_pos;	   
		Cr33_neg <= Cr24_neg;
        Cr33_msb <= Cr24_msb;
		Cr33_et_zero <= Cr24_et_zero;
		Cr24_pos <= Cr15_pos;	   
		Cr24_neg <= Cr15_neg;
		Cr24_msb <= Cr15_msb;
		Cr24_et_zero <= Cr15_et_zero;
		Cr15_pos <= Cr16_pos;	   
		Cr15_neg <= Cr16_neg;
		Cr15_msb <= Cr16_msb;
		Cr15_et_zero <= Cr16_et_zero;
		Cr16_pos <= Cr25_pos;	   
		Cr16_neg <= Cr25_neg;
		Cr16_msb <= Cr25_msb;
		Cr16_et_zero <= Cr25_et_zero;
		Cr25_pos <= Cr34_pos;	   
		Cr25_neg <= Cr34_neg;
		Cr25_msb <= Cr34_msb;
		Cr25_et_zero <= Cr34_et_zero;
		Cr34_pos <= Cr43_pos;	   
		Cr34_neg <= Cr43_neg;
		Cr34_msb <= Cr43_msb;
		Cr34_et_zero <= Cr43_et_zero;
		Cr43_pos <= Cr52_pos;	   
		Cr43_neg <= Cr52_neg;
		Cr43_msb <= Cr52_msb;
		Cr43_et_zero <= Cr52_et_zero;
		Cr52_pos <= Cr61_pos;	   
		Cr52_neg <= Cr61_neg;
		Cr52_msb <= Cr61_msb;
		Cr52_et_zero <= Cr61_et_zero;
		Cr61_pos <= Cr71_pos;	   
		Cr61_neg <= Cr71_neg;
		Cr61_msb <= Cr71_msb;
		Cr61_et_zero <= Cr71_et_zero;
		Cr71_pos <= Cr62_pos;	   
		Cr71_neg <= Cr62_neg;
		Cr71_msb <= Cr62_msb;
		Cr71_et_zero <= Cr62_et_zero;
		Cr62_pos <= Cr53_pos;	   
		Cr62_neg <= Cr53_neg;
		Cr62_msb <= Cr53_msb;
		Cr62_et_zero <= Cr53_et_zero;
		Cr53_pos <= Cr44_pos;	   
		Cr53_neg <= Cr44_neg;
		Cr53_msb <= Cr44_msb;
		Cr53_et_zero <= Cr44_et_zero;
		Cr44_pos <= Cr35_pos;	   
		Cr44_neg <= Cr35_neg;
		Cr44_msb <= Cr35_msb;
		Cr44_et_zero <= Cr35_et_zero;
		Cr35_pos <= Cr26_pos;	   
		Cr35_neg <= Cr26_neg;
		Cr35_msb <= Cr26_msb;
		Cr35_et_zero <= Cr26_et_zero;
		Cr26_pos <= Cr17_pos;	   
		Cr26_neg <= Cr17_neg;
		Cr26_msb <= Cr17_msb;
		Cr26_et_zero <= Cr17_et_zero;
		Cr17_pos <= Cr18_pos;	   
		Cr17_neg <= Cr18_neg;
		Cr17_msb <= Cr18_msb;
		Cr17_et_zero <= Cr18_et_zero;
		Cr18_pos <= Cr27_pos;	   
		Cr18_neg <= Cr27_neg;
		Cr18_msb <= Cr27_msb;
		Cr18_et_zero <= Cr27_et_zero;
		Cr27_pos <= Cr36_pos;	   
		Cr27_neg <= Cr36_neg;
		Cr27_msb <= Cr36_msb;
		Cr27_et_zero <= Cr36_et_zero;
		Cr36_pos <= Cr45_pos;	   
		Cr36_neg <= Cr45_neg;
		Cr36_msb <= Cr45_msb;
		Cr36_et_zero <= Cr45_et_zero;
		Cr45_pos <= Cr54_pos;	   
		Cr45_neg <= Cr54_neg;
		Cr45_msb <= Cr54_msb;
		Cr45_et_zero <= Cr54_et_zero;
		Cr54_pos <= Cr63_pos;	   
		Cr54_neg <= Cr63_neg;
		Cr54_msb <= Cr63_msb;
		Cr54_et_zero <= Cr63_et_zero;
		Cr63_pos <= Cr72_pos;	   
		Cr63_neg <= Cr72_neg;
		Cr63_msb <= Cr72_msb;
		Cr63_et_zero <= Cr72_et_zero;
		Cr72_pos <= Cr81_pos;	   
		Cr72_neg <= Cr81_neg;
		Cr72_msb <= Cr81_msb;
		Cr72_et_zero <= Cr81_et_zero;
		Cr81_pos <= Cr82_pos;	   
		Cr81_neg <= Cr82_neg;
		Cr81_msb <= Cr82_msb;
		Cr81_et_zero <= Cr82_et_zero;
		Cr82_pos <= Cr73_pos;	   
		Cr82_neg <= Cr73_neg;
		Cr82_msb <= Cr73_msb;
		Cr82_et_zero <= Cr73_et_zero;
		Cr73_pos <= Cr64_pos;	   
		Cr73_neg <= Cr64_neg;
		Cr73_msb <= Cr64_msb;
		Cr73_et_zero <= Cr64_et_zero;
		Cr64_pos <= Cr55_pos;	   
		Cr64_neg <= Cr55_neg;
		Cr64_msb <= Cr55_msb;
		Cr64_et_zero <= Cr55_et_zero;
		Cr55_pos <= Cr46_pos;	   
        Cr55_neg <= Cr46_neg;
		Cr55_msb <= Cr46_msb;
		Cr55_et_zero <= Cr46_et_zero;
		Cr46_pos <= Cr37_pos;	   
		Cr46_neg <= Cr37_neg;
		Cr46_msb <= Cr37_msb;
		Cr46_et_zero <= Cr37_et_zero;
		Cr37_pos <= Cr28_pos;	   
		Cr37_neg <= Cr28_neg;
		Cr37_msb <= Cr28_msb;
		Cr37_et_zero <= Cr28_et_zero;
		Cr28_pos <= Cr38_pos;	   
		Cr28_neg <= Cr38_neg;
		Cr28_msb <= Cr38_msb;
		Cr28_et_zero <= Cr38_et_zero;
		Cr38_pos <= Cr47_pos;	   
		Cr38_neg <= Cr47_neg;
		Cr38_msb <= Cr47_msb;
		Cr38_et_zero <= Cr47_et_zero;
		Cr47_pos <= Cr56_pos;	   
		Cr47_neg <= Cr56_neg;
		Cr47_msb <= Cr56_msb;
		Cr47_et_zero <= Cr56_et_zero;
		Cr56_pos <= Cr65_pos;	   
		Cr56_neg <= Cr65_neg;
		Cr56_msb <= Cr65_msb;
		Cr56_et_zero <= Cr65_et_zero;
		Cr65_pos <= Cr74_pos;	   
		Cr65_neg <= Cr74_neg;
		Cr65_msb <= Cr74_msb;
		Cr65_et_zero <= Cr74_et_zero;
		Cr74_pos <= Cr83_pos;	   
		Cr74_neg <= Cr83_neg;
		Cr74_msb <= Cr83_msb;
		Cr74_et_zero <= Cr83_et_zero;
		Cr83_pos <= Cr84_pos;	   
		Cr83_neg <= Cr84_neg;
		Cr83_msb <= Cr84_msb;
		Cr83_et_zero <= Cr84_et_zero;
		Cr84_pos <= Cr75_pos;	   
		Cr84_neg <= Cr75_neg;
		Cr84_msb <= Cr75_msb;
		Cr84_et_zero <= Cr75_et_zero;
        Cr75_pos <= Cr66_pos;	   
		Cr75_neg <= Cr66_neg;
		Cr75_msb <= Cr66_msb;
		Cr75_et_zero <= Cr66_et_zero;
		Cr66_pos <= Cr57_pos;	   
		Cr66_neg <= Cr57_neg;
		Cr66_msb <= Cr57_msb;
		Cr66_et_zero <= Cr57_et_zero;
		Cr57_pos <= Cr48_pos;	   
		Cr57_neg <= Cr48_neg;
		Cr57_msb <= Cr48_msb;
		Cr57_et_zero <= Cr48_et_zero;
		Cr48_pos <= Cr58_pos;	   
		Cr48_neg <= Cr58_neg;
		Cr48_msb <= Cr58_msb;
		Cr48_et_zero <= Cr58_et_zero;
		Cr58_pos <= Cr67_pos;	   
		Cr58_neg <= Cr67_neg;
		Cr58_msb <= Cr67_msb;
		Cr58_et_zero <= Cr67_et_zero;
		Cr67_pos <= Cr76_pos;	   
		Cr67_neg <= Cr76_neg;
		Cr67_msb <= Cr76_msb;
		Cr67_et_zero <= Cr76_et_zero;
		Cr76_pos <= Cr85_pos;	   
		Cr76_neg <= Cr85_neg;
		Cr76_msb <= Cr85_msb;
		Cr76_et_zero <= Cr85_et_zero;
		Cr85_pos <= Cr86_pos;	   
		Cr85_neg <= Cr86_neg;
		Cr85_msb <= Cr86_msb;
		Cr85_et_zero <= Cr86_et_zero;
		Cr86_pos <= Cr77_pos;	   
		Cr86_neg <= Cr77_neg;
		Cr86_msb <= Cr77_msb;
		Cr86_et_zero <= Cr77_et_zero;
		Cr77_pos <= Cr68_pos;	   
		Cr77_neg <= Cr68_neg;
		Cr77_msb <= Cr68_msb;
		Cr77_et_zero <= Cr68_et_zero;
		Cr68_pos <= Cr78_pos;	   
		Cr68_neg <= Cr78_neg;
		Cr68_msb <= Cr78_msb;
		Cr68_et_zero <= Cr78_et_zero;
		Cr78_pos <= Cr87_pos;	   
		Cr78_neg <= Cr87_neg;
		Cr78_msb <= Cr87_msb;
		Cr78_et_zero <= Cr87_et_zero;
		Cr87_pos <= Cr88_pos;	   
		Cr87_neg <= Cr88_neg;
		Cr87_msb <= Cr88_msb;
		Cr87_et_zero <= Cr88_et_zero;
		Cr88_pos <= 0;	   
		Cr88_neg <= 0;
		Cr88_msb <= 0;
		Cr88_et_zero <= 1;
		end
end	 

// Compute Cr11 difference and sign extension for amplitude
always_ff @(posedge clk) begin
	if (rst) begin
		Cr11_diff <= 12'd0;     // Reset signed difference
		Cr11_1    <= 12'd0;     // Reset sign-extended Cr11
	end
	else if (enable) begin
		// Sign extend Cr11 to 12 bits, then subtract previous value
		// {Cr11[10], Cr11} adds sign bit as MSB
		Cr11_diff <= {Cr11[10], Cr11} - Cr11_previous;

		// Store sign-extended Cr11 (positive or negative form)
		Cr11_1    <= Cr11[10] ? {1'b1, Cr11} : {1'b0, Cr11};
	end
end

// Determine the number of bits needed to represent Cr11_1_pos (unsigned magnitude)
always_ff @(posedge clk) begin
	if (rst) begin
		Cr11_bits_pos <= 4'd0;  // Number of bits reset
	end
	else if (Cr11_1_pos[10]) begin
		Cr11_bits_pos <= 4'd11;
	end
	else if (Cr11_1_pos[9]) begin
		Cr11_bits_pos <= 4'd10;
	end
	else if (Cr11_1_pos[8]) begin
		Cr11_bits_pos <= 4'd9;
	end
	else if (Cr11_1_pos[7]) begin
		Cr11_bits_pos <= 4'd8;
	end
	else if (Cr11_1_pos[6]) begin
		Cr11_bits_pos <= 4'd7;
	end
	else if (Cr11_1_pos[5]) begin
		Cr11_bits_pos <= 4'd6;
	end
	else if (Cr11_1_pos[4]) begin
		Cr11_bits_pos <= 4'd5;
	end
	else if (Cr11_1_pos[3]) begin
		Cr11_bits_pos <= 4'd4;
	end
	else if (Cr11_1_pos[2]) begin
		Cr11_bits_pos <= 4'd3;
	end
	else if (Cr11_1_pos[1]) begin
		Cr11_bits_pos <= 4'd2;
	end
	else if (Cr11_1_pos[0]) begin
		Cr11_bits_pos <= 4'd1;
	end
	else begin
		Cr11_bits_pos <= 4'd0;
	end
end

// Count number of bits needed to represent the negative Cr11 value
always_ff @(posedge clk) begin
	if (rst) begin
		Cr11_bits_neg <= 4'd0;  // Reset bit width
	end
	else if (Cr11_1_neg[10] == 1'b0) begin
		Cr11_bits_neg <= 4'd11;
	end
	else if (Cr11_1_neg[9] == 1'b0) begin
		Cr11_bits_neg <= 4'd10;
	end
	else if (Cr11_1_neg[8] == 1'b0) begin
		Cr11_bits_neg <= 4'd9;
	end
	else if (Cr11_1_neg[7] == 1'b0) begin
		Cr11_bits_neg <= 4'd8;
	end
	else if (Cr11_1_neg[6] == 1'b0) begin
		Cr11_bits_neg <= 4'd7;
	end
	else if (Cr11_1_neg[5] == 1'b0) begin
		Cr11_bits_neg <= 4'd6;
	end
	else if (Cr11_1_neg[4] == 1'b0) begin
		Cr11_bits_neg <= 4'd5;
	end
	else if (Cr11_1_neg[3] == 1'b0) begin
		Cr11_bits_neg <= 4'd4;
	end
	else if (Cr11_1_neg[2] == 1'b0) begin
		Cr11_bits_neg <= 4'd3;
	end
	else if (Cr11_1_neg[1] == 1'b0) begin
		Cr11_bits_neg <= 4'd2;
	end
	else if (Cr11_1_neg[0] == 1'b0) begin
		Cr11_bits_neg <= 4'd1;
	end
	else begin
		Cr11_bits_neg <= 4'd0;
	end
end

// Count number of bits needed to represent the positive Cr12 value
always_ff @(posedge clk) begin
	if (rst) begin
		Cr12_bits_pos <= 4'd0;
	end
	else if (Cr12_pos[9]) begin
		Cr12_bits_pos <= 4'd10;
	end
	else if (Cr12_pos[8]) begin
		Cr12_bits_pos <= 4'd9;
	end
	else if (Cr12_pos[7]) begin
		Cr12_bits_pos <= 4'd8;
	end
	else if (Cr12_pos[6]) begin
		Cr12_bits_pos <= 4'd7;
	end
	else if (Cr12_pos[5]) begin
		Cr12_bits_pos <= 4'd6;
	end
	else if (Cr12_pos[4]) begin
		Cr12_bits_pos <= 4'd5;
	end
	else if (Cr12_pos[3]) begin
		Cr12_bits_pos <= 4'd4;
	end
	else if (Cr12_pos[2]) begin
		Cr12_bits_pos <= 4'd3;
	end
	else if (Cr12_pos[1]) begin
		Cr12_bits_pos <= 4'd2;
	end
	else if (Cr12_pos[0]) begin
		Cr12_bits_pos <= 4'd1;
	end
	else begin
		Cr12_bits_pos <= 4'd0;
	end
end
// Calculate number of bits required to represent Cr12_neg (for negative values)
always_ff @(posedge clk) begin
	if (rst) begin
		Cr12_bits_neg <= 4'd0;
	end
	else if (Cr12_neg[9] == 1'b0) begin
		Cr12_bits_neg <= 4'd10;
	end
	else if (Cr12_neg[8] == 1'b0) begin
		Cr12_bits_neg <= 4'd9;
	end
	else if (Cr12_neg[7] == 1'b0) begin
		Cr12_bits_neg <= 4'd8;
	end
	else if (Cr12_neg[6] == 1'b0) begin
		Cr12_bits_neg <= 4'd7;
	end
	else if (Cr12_neg[5] == 1'b0) begin
		Cr12_bits_neg <= 4'd6;
	end
	else if (Cr12_neg[4] == 1'b0) begin
		Cr12_bits_neg <= 4'd5;
	end
	else if (Cr12_neg[3] == 1'b0) begin
		Cr12_bits_neg <= 4'd4;
	end
	else if (Cr12_neg[2] == 1'b0) begin
		Cr12_bits_neg <= 4'd3;
	end
	else if (Cr12_neg[1] == 1'b0) begin
		Cr12_bits_neg <= 4'd2;
	end
	else if (Cr12_neg[0] == 1'b0) begin
		Cr12_bits_neg <= 4'd1;
	end
	else begin
		Cr12_bits_neg <= 4'd0;
	end
end

// Enable the module one cycle after 'enable' becomes high
always_ff @(posedge clk) begin
	if (rst) begin
		enable_module <= 1'b0;
	end
	else if (enable) begin
		enable_module <= 1'b1;
	end
end

// Latch enable signal at stage 7
always_ff @(posedge clk) begin
	if (rst) begin
		enable_latch_7 <= 1'b0;
	end
	else if (block_counter == 8'd68) begin
		enable_latch_7 <= 1'b0;  // Disable when block_counter reaches 68
	end
	else if (enable_6) begin
		enable_latch_7 <= 1'b1;
	end
end

// Latch enable signal at stage 8
always_ff @(posedge clk) begin
	if (rst) begin
		enable_latch_8 <= 1'b0;
	end
	else if (enable_7) begin
		enable_latch_8 <= 1'b1;
	end
end

// Delay the 'enable' signal across 13 pipeline stages
always_ff @(posedge clk) begin
	if (rst) begin
		enable_1  <= 1'b0; enable_2  <= 1'b0; enable_3  <= 1'b0;
		enable_4  <= 1'b0; enable_5  <= 1'b0; enable_6  <= 1'b0;
		enable_7  <= 1'b0; enable_8  <= 1'b0; enable_9  <= 1'b0;
		enable_10 <= 1'b0; enable_11 <= 1'b0; enable_12 <= 1'b0;
		enable_13 <= 1'b0;
	end
	else begin
		enable_1  <= enable;
		enable_2  <= enable_1;
		enable_3  <= enable_2;
		enable_4  <= enable_3;
		enable_5  <= enable_4;
		enable_6  <= enable_5;
		enable_7  <= enable_6;
		enable_8  <= enable_7;
		enable_9  <= enable_8;
		enable_10 <= enable_9;
		enable_11 <= enable_10;
		enable_12 <= enable_11;
		enable_13 <= enable_12;
	end
end


always_ff @(posedge clk) begin
    if (rst) begin
        JPEG_bitstream[31] <= 1'b0;
    end else if (enable_module && (rollover_7 || orc_8 == 0)) begin
        JPEG_bitstream[31] <= JPEG_bs_5[31];
    end
end

always_ff @(posedge clk) begin
    if (rst) begin
        JPEG_bitstream[30] <= 1'b0;
    end else if (enable_module && (rollover_7 || orc_8 <= 1)) begin
        JPEG_bitstream[30] <= JPEG_bs_5[30];
    end
end

always_ff @(posedge clk) begin
    if (rst) begin
        JPEG_bitstream[29] <= 1'b0;
    end else if (enable_module && (rollover_7 || orc_8 <= 2)) begin
        JPEG_bitstream[29] <= JPEG_bs_5[29];
    end
end

always_ff @(posedge clk) begin
    if (rst) begin
        JPEG_bitstream[28] <= 1'b0;
    end else if (enable_module && (rollover_7 || orc_8 <= 3)) begin
        JPEG_bitstream[28] <= JPEG_bs_5[28];
    end
end

always_ff @(posedge clk) begin
    if (rst) begin
        JPEG_bitstream[27] <= 1'b0;
    end else if (enable_module && (rollover_7 || orc_8 <= 4)) begin
        JPEG_bitstream[27] <= JPEG_bs_5[27];
    end
end

always_ff @(posedge clk) begin
    if (rst) begin
        JPEG_bitstream[26] <= 1'b0;
    end else if (enable_module && (rollover_7 || orc_8 <= 5)) begin
        JPEG_bitstream[26] <= JPEG_bs_5[26];
    end
end

always_ff @(posedge clk) begin
    if (rst) begin
        JPEG_bitstream[25] <= 1'b0;
    end else if (enable_module && (rollover_7 || orc_8 <= 6)) begin
        JPEG_bitstream[25] <= JPEG_bs_5[25];
    end
end

// Update JPEG_bitstream[24] on rising edge of clock
// Select from JPEG_bs_5 if rollover_7 is active or orc_8 <= 7
always_ff @(posedge clk) begin
	if (rst)
		JPEG_bitstream[24] <= 1'b0;
	else if (enable_module && (rollover_7 || orc_8 <= 7))
		JPEG_bitstream[24] <= JPEG_bs_5[24];
end

// Update JPEG_bitstream[23]
always_ff @(posedge clk) begin
	if (rst)
		JPEG_bitstream[23] <= 1'b0;
	else if (enable_module && (rollover_7 || orc_8 <= 8))
		JPEG_bitstream[23] <= JPEG_bs_5[23];
end

// Update JPEG_bitstream[22]
always_ff @(posedge clk) begin
	if (rst)
		JPEG_bitstream[22] <= 1'b0;
	else if (enable_module && (rollover_7 || orc_8 <= 9))
		JPEG_bitstream[22] <= JPEG_bs_5[22];
end

// Update JPEG_bitstream[21]
always_ff @(posedge clk) begin
	if (rst)
		JPEG_bitstream[21] <= 1'b0;
	else if (enable_module && (rollover_7 || orc_8 <= 10))
		JPEG_bitstream[21] <= JPEG_bs_5[21];
end

// Update JPEG_bitstream[20]
always_ff @(posedge clk) begin
	if (rst)
		JPEG_bitstream[20] <= 1'b0;
	else if (enable_module && (rollover_7 || orc_8 <= 11))
		JPEG_bitstream[20] <= JPEG_bs_5[20];
end

// Update JPEG_bitstream[19]
always_ff @(posedge clk) begin
	if (rst)
		JPEG_bitstream[19] <= 1'b0;
	else if (enable_module && (rollover_7 || orc_8 <= 12))
		JPEG_bitstream[19] <= JPEG_bs_5[19];
end

// Update JPEG_bitstream[18]
always_ff @(posedge clk) begin
	if (rst)
		JPEG_bitstream[18] <= 1'b0;
	else if (enable_module && (rollover_7 || orc_8 <= 13))
		JPEG_bitstream[18] <= JPEG_bs_5[18];
end

// Update JPEG_bitstream[17]
always_ff @(posedge clk) begin
	if (rst)
		JPEG_bitstream[17] <= 1'b0;
	else if (enable_module && (rollover_7 || orc_8 <= 14))
		JPEG_bitstream[17] <= JPEG_bs_5[17];
end

// Update JPEG_bitstream[16]
always_ff @(posedge clk) begin
	if (rst)
		JPEG_bitstream[16] <= 1'b0;
	else if (enable_module && (rollover_7 || orc_8 <= 15))
		JPEG_bitstream[16] <= JPEG_bs_5[16];
end

// Update JPEG_bitstream[15]
// Select value from JPEG_bs_5[15] when rollover_7 is active or orc_8 <= 16
always_ff @(posedge clk) begin
	if (rst)
		JPEG_bitstream[15] <= 1'b0;
	else if (enable_module && (rollover_7 || orc_8 <= 16))
		JPEG_bitstream[15] <= JPEG_bs_5[15];
end

// JPEG_bitstream[14] logic
always_ff @(posedge clk) begin
	if (rst)
		JPEG_bitstream[14] <= 1'b0;
	else if (enable_module && (rollover_7 || orc_8 <= 17))
		JPEG_bitstream[14] <= JPEG_bs_5[14];
end

// JPEG_bitstream[13] logic
always_ff @(posedge clk) begin
	if (rst)
		JPEG_bitstream[13] <= 1'b0;
	else if (enable_module && (rollover_7 || orc_8 <= 18))
		JPEG_bitstream[13] <= JPEG_bs_5[13];
end

// JPEG_bitstream[12] logic
always_ff @(posedge clk) begin
	if (rst)
		JPEG_bitstream[12] <= 1'b0;
	else if (enable_module && (rollover_7 || orc_8 <= 19))
		JPEG_bitstream[12] <= JPEG_bs_5[12];
end

// JPEG_bitstream[11] logic
always_ff @(posedge clk) begin
	if (rst)
		JPEG_bitstream[11] <= 1'b0;
	else if (enable_module && (rollover_7 || orc_8 <= 20))
		JPEG_bitstream[11] <= JPEG_bs_5[11];
end

// JPEG_bitstream[10] logic
always_ff @(posedge clk) begin
	if (rst)
		JPEG_bitstream[10] <= 1'b0;
	else if (enable_module && (rollover_7 || orc_8 <= 21))
		JPEG_bitstream[10] <= JPEG_bs_5[10];
end

// JPEG_bitstream[9] logic
always_ff @(posedge clk) begin
	if (rst)
		JPEG_bitstream[9] <= 1'b0;
	else if (enable_module && (rollover_7 || orc_8 <= 22))
		JPEG_bitstream[9] <= JPEG_bs_5[9];
end

// JPEG_bitstream[8] logic
always_ff @(posedge clk) begin
	if (rst)
		JPEG_bitstream[8] <= 1'b0;
	else if (enable_module && (rollover_7 || orc_8 <= 23))
		JPEG_bitstream[8] <= JPEG_bs_5[8];
end

// Set bit 7 of JPEG_bitstream based on rollover or output register count (orc_8)
always_ff @(posedge clk) begin
	if (rst)
		JPEG_bitstream[7] <= 1'b0;
	else if (enable_module && (rollover_7 || orc_8 <= 24))
		JPEG_bitstream[7] <= JPEG_bs_5[7];
end

// Set bit 6
always_ff @(posedge clk) begin
	if (rst)
		JPEG_bitstream[6] <= 1'b0;
	else if (enable_module && (rollover_7 || orc_8 <= 25))
		JPEG_bitstream[6] <= JPEG_bs_5[6];
end

// Set bit 5
always_ff @(posedge clk) begin
	if (rst)
		JPEG_bitstream[5] <= 1'b0;
	else if (enable_module && (rollover_7 || orc_8 <= 26))
		JPEG_bitstream[5] <= JPEG_bs_5[5];
end

// Set bit 4
always_ff @(posedge clk) begin
	if (rst)
		JPEG_bitstream[4] <= 1'b0;
	else if (enable_module && (rollover_7 || orc_8 <= 27))
		JPEG_bitstream[4] <= JPEG_bs_5[4];
end

// Set bit 3
always_ff @(posedge clk) begin
	if (rst)
		JPEG_bitstream[3] <= 1'b0;
	else if (enable_module && (rollover_7 || orc_8 <= 28))
		JPEG_bitstream[3] <= JPEG_bs_5[3];
end

// Set bit 2
always_ff @(posedge clk) begin
	if (rst)
		JPEG_bitstream[2] <= 1'b0;
	else if (enable_module && (rollover_7 || orc_8 <= 29))
		JPEG_bitstream[2] <= JPEG_bs_5[2];
end

// Set bit 1
always_ff @(posedge clk) begin
	if (rst)
		JPEG_bitstream[1] <= 1'b0;
	else if (enable_module && (rollover_7 || orc_8 <= 30))
		JPEG_bitstream[1] <= JPEG_bs_5[1];
end

// Set bit 0
always_ff @(posedge clk) begin
	if (rst)
		JPEG_bitstream[0] <= 1'b0;
	else if (enable_module && (rollover_7 || orc_8 <= 31))
		JPEG_bitstream[0] <= JPEG_bs_5[0];
end
endmodule
