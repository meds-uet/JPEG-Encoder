// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// File: QUANTIZER_CONSTANTS_SV
// Description:
//   This file defines the standard JPEG luminance quantization matrix used
//   for testing purposes in the quantizer modules (e.g., y_quantizer).
//   The 8x8 Q_MATRIX provided here is based on the ITU-T JPEG recommendation,
//   but in practical image compression, the actual quantization table may vary
//   depending on the image, compression quality, and encoder settings.
//   This matrix is used only in testbenches for validation of fixed quantization logic.
//
// Author: Navaal Noshi
// Date: 29th July, 2025
// -----------------------------------------------------------------------------

`ifndef QUANTIZER_CONSTANTS_SV
`define QUANTIZER_CONSTANTS_SV

// Matrix Size (8x8 for DCT)
localparam int MATRIX_SIZE = 8;

// Standard JPEG Luminance Quantization Matrix (Q_MATRIX)
// Note: This matrix is fixed for test cases and may vary across different images in real applications.
localparam int Q_MATRIX [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1] = '{
  '{16, 11, 10, 16, 24, 40, 51, 61},
  '{12, 12, 14, 19, 26, 58, 60, 55},
  '{14, 13, 16, 24, 40, 57, 69, 56},
  '{14, 17, 22, 29, 51, 87, 80, 62},
  '{18, 22, 37, 56, 68,109,103, 77},
  '{24, 35, 55, 64, 81,104,113, 92},
  '{49, 64, 78, 87,103,121,120,101},
  '{72, 92, 95, 98,112,100,103, 99}
};

`endif // QUANTIZER_CONSTANTS_SV
