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

`ifndef Y_HUFF_CONSTANTS_SVH
`define Y_HUFF_CONSTANTS_SVH
// Inside your SystemVerilog module

// === DC Code Lengths ===
localparam int Y_DC_code_length [0:11] = '{
  2, 2, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
};

// === DC Huffman Codes ===
localparam logic [10:0] Y_DC [0:11] = '{
  11'b00000000000, 11'b01000000000, 11'b10000000000, 11'b11000000000,
  11'b11100000000, 11'b11110000000, 11'b11111000000, 11'b11111100000,
  11'b11111110000, 11'b11111111000, 11'b11111111100, 11'b11111111110
};

// === AC Code Lengths ===
localparam int Y_AC_code_length [0:161] = '{
  2, 2, 3, 4, 4, 4, 5, 5, 5, 6, 6, 7, 7, 7, 7, 8,
  8, 8, 9, 9, 9, 9, 9, 10, 10, 10, 10, 10, 11, 11, 11, 11,
  12, 12, 12, 12, 15, 16, 16, 16, 16, 16, 16, 16, 16, 16,
  16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16,
  16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16,
  16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16,
  16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16,
  16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16,
  16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16,
  16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16,
  16, 16
};

/// === AC Huffman Codes ===
localparam logic [15:0] Y_AC [0:161] = '{
    16'h0000, 16'h4000, 16'h8000, 16'hA000,
    16'hB000, 16'hC000, 16'hD000, 16'hD800,
    16'hE000, 16'hE800, 16'hEC00, 16'hF000,
    16'hF200, 16'hF400, 16'hF600, 16'hF800,
    16'hF900, 16'hFA00, 16'hFB00, 16'hFB80,
    16'hFC00, 16'hFC80, 16'hFD00, 16'hFD80,
    16'hFDC0, 16'hFE00, 16'hFE40, 16'hFE80,
    16'hFEC0, 16'hFEE0, 16'hFF00, 16'hFF20,
    16'hFF40, 16'hFF50, 16'hFF60, 16'hFF70,
    16'hFF80, 16'hFF82, 16'hFF83, 16'hFF84,
    16'hFF85, 16'hFF86, 16'hFF87, 16'hFF88,
    16'hFF89, 16'hFF8A, 16'hFF8B, 16'hFF8C,
    16'hFF8D, 16'hFF8E, 16'hFF8F, 16'hFF90,
    16'hFF91, 16'hFF92, 16'hFF93, 16'hFF94,
    16'hFF95, 16'hFF96, 16'hFF97, 16'hFF98,
    16'hFF99, 16'hFF9A, 16'hFF9B, 16'hFF9C,
    16'hFF9D, 16'hFF9E, 16'hFF9F, 16'hFFA0,
    16'hFFA1, 16'hFFA2, 16'hFFA3, 16'hFFA4,
    16'hFFA5, 16'hFFA6, 16'hFFA7, 16'hFFA8,
    16'hFFA9, 16'hFFAA, 16'hFFAB, 16'hFFAC,
    16'hFFAD, 16'hFFAE, 16'hFFAF, 16'hFFB0,
    16'hFFB1, 16'hFFB2, 16'hFFB3, 16'hFFB4,
    16'hFFB5, 16'hFFB6, 16'hFFB7, 16'hFFB8,
    16'hFFB9, 16'hFFBA, 16'hFFBB, 16'hFFBC,
    16'hFFBD, 16'hFFBE, 16'hFFBF, 16'hFFC0,
    16'hFFC1, 16'hFFC2, 16'hFFC3, 16'hFFC4,
    16'hFFC5, 16'hFFC6, 16'hFFC7, 16'hFFC8,
    16'hFFC9, 16'hFFCA, 16'hFFCB, 16'hFFCC,
    16'hFFCD, 16'hFFCE, 16'hFFCF, 16'hFFD0,
    16'hFFD1, 16'hFFD2, 16'hFFD3, 16'hFFD4,
    16'hFFD5, 16'hFFD6, 16'hFFD7, 16'hFFD8,
    16'hFFD9, 16'hFFDA, 16'hFFDB, 16'hFFDC,
    16'hFFDD, 16'hFFDE, 16'hFFDF, 16'hFFE0,
    16'hFFE1, 16'hFFE2, 16'hFFE3, 16'hFFE4,
    16'hFFE5, 16'hFFE6, 16'hFFE7, 16'hFFE8,
    16'hFFE9, 16'hFFEA, 16'hFFEB, 16'hFFEC,
    16'hFFED, 16'hFFEE, 16'hFFEF, 16'hFFF0,
    16'hFFF1, 16'hFFF2, 16'hFFF3, 16'hFFF4,
    16'hFFF5, 16'hFFF6, 16'hFFF7, 16'hFFF8,
    16'hFFF9, 16'hFFFA, 16'hFFFB, 16'hFFFC,
    16'hFFFD, 16'hFFFE
};


// === AC Run-Length Huffman Mapping (Y_AC_run_code) ===
// Format: (RUNLENGTH << 4) | SIZE, mapped to index 0–255
// This array gives the Huffman table index for (RUNLENGTH, SIZE) used in AC coefficient encoding.

localparam int Y_AC_run_code [0:255] = '{
  // Index = (RUNLENGTH << 4) | SIZE
  // Format: RUNLENGTH SIZE => Huffman Table Index

   0,   1,  2,   3,   4,   5,   6,   7,   8,   9,  10,  11, 162, 162, 162, 162,  // 0x0_0 to 0x0_F
  12,  13, 14,  15,  16,  17,  18,  19,  20,  21,  22,  23, 162, 162, 162, 162,  // 0x1_0 to 0x1_F
  24,  25, 26,  27,  28,  29,  30,  31,  32,  33,  34,  35, 162, 162, 162, 162,  // 0x2_0 to 0x2_F
  36,  37, 38,  39,  40,  41,  42,  43,  44,  45,  46,  47, 162, 162, 162, 162,  // 0x3_0 to 0x3_F
  48,  49, 50,  51,  52,  53,  54,  55,  56,  57,  58,  59, 162, 162, 162, 162,  // 0x4_0 to 0x4_F
  60,  61, 62,  63,  64,  65,  66,  67,  68,  69,  70,  71, 162, 162, 162, 162,  // 0x5_0 to 0x5_F
  72,  73, 74,  75,  76,  77,  78,  79,  80,  81,  82,  83, 162, 162, 162, 162,  // 0x6_0 to 0x6_F
  84,  85, 86,  87,  88,  89,  90,  91,  92,  93,  94,  95, 162, 162, 162, 162,  // 0x7_0 to 0x7_F
  96,  97, 98,  99, 100, 101, 102, 103, 104, 105, 106, 107, 162, 162, 162, 162,  // 0x8_0 to 0x8_F
 108, 109,110, 111,112, 113,114, 115,116, 117,118, 119, 162, 162, 162, 162,      // 0x9_0 to 0x9_F
 120,121,122,123,124,125,126,127,128,129,130,131, 162, 162, 162, 162,            // 0xA_0 to 0xA_F
 132,133,134,135,136,137,138,139,140,141,142,143, 162, 162, 162, 162,            // 0xB_0 to 0xB_F
 144,145,146,147,148,149,150,151,152,153,154,155, 162, 162, 162, 162,            // 0xC_0 to 0xC_F
 156,157,158,159,160,161,162,162,162,162,162,162, 162, 162, 162, 162,            // 0xD_0 to 0xD_F
 162,162,162,162,162,162,162,162,162,162,162,162, 162, 162, 162, 162,            // 0xE_0 to 0xE_F
 162,162,162,162,162,162,162,162,162,162,162,162, 162, 162, 162, 162             // 0xF_0 to 0xF_F
};
`endif 
