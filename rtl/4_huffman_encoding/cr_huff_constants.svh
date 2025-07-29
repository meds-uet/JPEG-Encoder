// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// Description:
//    Header file containing localparam definitions for Y (Luma) Huffman encoding.
//    These parameters define the DC and AC Huffman code lengths and codes,
//    as well as the AC run-length Huffman mapping.
//
// Author:Rameen
// Date:15th July,2025.

`ifndef CR_HUFF_CONSTANTS_SVH
`define CR_HUFF_CONSTANTS_SVH

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

`endif
