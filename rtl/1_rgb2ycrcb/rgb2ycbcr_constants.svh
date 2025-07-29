`ifndef RGB2YCBCR_CONSTANTS_SVH
`define RGB2YCBCR_CONSTANTS_SVH

// -----------------------------------------------------------------------------
// File: rgb2ycbcr_constants.svh
// Description: Fixed-point constants for RGB to YCbCr color conversion
//              using ITU-R BT.601 standard coefficients scaled by 2^13 or 2^14
//              for hardware implementation.
// Author: Navaal Noshi
// Date: 29th July, 2025
// -----------------------------------------------------------------------------

// Coefficients scaled by 2^13 (8192) for fixed-point multiplication
localparam logic [13:0] Y1  = 14'd4899;   // 0.299  * 8192
localparam logic [13:0] Y2  = 14'd9617;   // 0.587  * 8192
localparam logic [13:0] Y3  = 14'd1868;   // 0.114  * 8192

localparam logic [13:0] CB1 = 14'd2764;   // -0.1687 * 8192
localparam logic [13:0] CB2 = 14'd5428;   // -0.3313 * 8192
localparam logic [13:0] CB3 = 14'd8192;   //  0.5    * 8192

localparam logic [13:0] CR1 = 14'd8192;   //  0.5    * 8192
localparam logic [13:0] CR2 = 14'd6860;   // -0.4187 * 8192
localparam logic [13:0] CR3 = 14'd1332;   // -0.0813 * 8192

// Offset added to Cb and Cr after conversion to shift range to unsigned [0,255]
// 128 * 2^14 = 2097152
localparam logic [21:0] OFFSET_CBCR = 22'd2097152;

`endif // RGB2YCBCR_CONSTANTS_SVH
