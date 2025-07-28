// rgb2ycbcr_constants.svh
// Description: Fixed-point constants for RGB to YCbCr color conversion
//              Coefficients are scaled by 2^13 (8192)

localparam logic [13:0] Y1  = 14'd4899;   // 0.299  * 8192
localparam logic [13:0] Y2  = 14'd9617;   // 0.587  * 8192
localparam logic [13:0] Y3  = 14'd1868;   // 0.114  * 8192

localparam logic [13:0] CB1 = 14'd2764;   // -0.1687 * 8192
localparam logic [13:0] CB2 = 14'd5428;   // -0.3313 * 8192
localparam logic [13:0] CB3 = 14'd8192;   // 0.5     * 8192

localparam logic [13:0] CR1 = 14'd8192;   // 0.5     * 8192
localparam logic [13:0] CR2 = 14'd6860;   // -0.4187 * 8192
localparam logic [13:0] CR3 = 14'd1332;   // -0.0813 * 8192

localparam logic [21:0] OFFSET_CBCR = 22'd2097152; // 128 * 2^14
