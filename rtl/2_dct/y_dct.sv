// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// Description:
//   This module performs a Discrete Cosine Transform (DCT) on 8x8 blocks of Y (Luma) data.
//   It uses short integers for calculations and coefficients. Unlike typical DCTs,
//   it handles the DC offset by a final subtraction on the first coefficient,
//   rather than pre-subtracting 128 from each input pixel.
//
// Author:Rameen
// Date:11th July,2025.

`timescale 1ns / 100ps
module y_dct (
    input logic clk,
    input logic rst,
    input logic enable,
    input logic [7:0] data_in,
    output logic [10:0] Z11_final, Z12_final, Z13_final, Z14_final,
    output logic [10:0] Z15_final, Z16_final, Z17_final, Z18_final,
    output logic [10:0] Z21_final, Z22_final, Z23_final, Z24_final,
    output logic [10:0] Z25_final, Z26_final, Z27_final, Z28_final,
    output logic [10:0] Z31_final, Z32_final, Z33_final, Z34_final, 
    output logic [10:0] Z35_final, Z36_final, Z37_final, Z38_final,
    output logic [10:0] Z41_final, Z42_final, Z43_final, Z44_final,
    output logic [10:0] Z45_final, Z46_final, Z47_final, Z48_final,
    output logic [10:0] Z51_final, Z52_final, Z53_final, Z54_final,
    output logic [10:0] Z55_final, Z56_final, Z57_final, Z58_final,
    output logic [10:0] Z61_final, Z62_final, Z63_final, Z64_final,
    output logic [10:0] Z65_final, Z66_final, Z67_final, Z68_final,
    output logic [10:0] Z71_final, Z72_final, Z73_final, Z74_final,
    output logic [10:0] Z75_final, Z76_final, Z77_final, Z78_final,
    output logic [10:0] Z81_final, Z82_final, Z83_final, Z84_final,
    output logic [10:0] Z85_final, Z86_final, Z87_final, Z88_final,
    output logic output_enable
);

// Constants for DCT coefficients (should be fixed-point, but using integers as per original)
// NOTE: For a real DCT, these are typically derived from cos( (2n+1)k*pi / 16 ) * Ck
// and are fixed-point numbers. Ensure your integer values and bit widths are appropriate
// for the actual DCT math.
integer T1, T21, T22, T23, T24, T25, T26, T27, T28, T31, T32, T33, T34, T52;
integer Ti1, Ti21, Ti22, Ti23, Ti24, Ti25, Ti26, Ti27, Ti28, Ti31, Ti32, Ti33, Ti34, Ti52;

// Internal pipeline registers and intermediate signals
// Y_temp_11 is 25 bits: 8 (data_in) + 17 (T1 ~ 5793) -> max 25 bits
logic [24:0] Y_temp_11,Y_temp_21,Y_temp_31,Y_temp_41,Y_temp_51,Y_temp_61,Y_temp_71,Y_temp_81;
logic [24:0] Y11, Y21, Y31, Y41, Y51, Y61, Y71, Y81; // Accumulators for 8 points
logic [24:0] Y11_final, Y21_final, Y31_final, Y41_final,
             Y51_final, Y61_final, Y71_final, Y81_final; // Post-sum (or post-centering)
logic [24:0] Y21_final_prev, Y31_final_prev, Y41_final_prev, Y51_final_prev,
             Y61_final_prev, Y71_final_prev, Y81_final_prev; // Pipelined Y_final
logic [24:0] Y21_final_diff, Y31_final_diff, Y41_final_diff, Y51_final_diff,
             Y61_final_diff, Y71_final_diff, Y81_final_diff; // Differences

// Y_final_X are for the rounding stages, width is critical.
// Y11_final (25 bits), after rounding to 12 bits, needs sign extension to 32 for multiplication.
logic [12:0] Y11_final_1, Y21_final_1, Y31_final_1, Y41_final_1,
             Y51_final_1, Y61_final_1, Y71_final_1, Y81_final_1;
// Y_final_2 are sign-extended and delayed for multiplication in Z_temp
logic [31:0] Y11_final_2, Y21_final_2, Y31_final_2, Y41_final_2,
             Y51_final_2, Y61_final_2, Y71_final_2, Y81_final_2;
// Y_final_3 and Y_final_4 for pipeline delay
logic [31:0] Y11_final_3, Y11_final_4; // Assuming only Y11 needs this deep a pipeline for now

// Z_temp (32 bits): (13-bit Y_final_2 sign extended to 32) * (17-bit TiX_mul_input) -> max 49 bits.
// Your Z_temp is 31:0, which might truncate results if the full range is needed. Re-evaluate if 32 bits is enough.
// (Example: 2^12 * 2^16 ~ 2^28, so 32 bits should be sufficient if Y_final_2[12:0] is the input)
logic [31:0] Z_temp_11, Z_temp_12, Z_temp_13, Z_temp_14,
             Z_temp_15, Z_temp_16, Z_temp_17, Z_temp_18,
             Z_temp_21, Z_temp_22, Z_temp_23, Z_temp_24,
             Z_temp_25, Z_temp_26, Z_temp_27, Z_temp_28,
             Z_temp_31, Z_temp_32, Z_temp_33, Z_temp_34,
             Z_temp_35, Z_temp_36, Z_temp_37, Z_temp_38,
             Z_temp_41, Z_temp_42, Z_temp_43, Z_temp_44,
             Z_temp_45, Z_temp_46, Z_temp_47, Z_temp_48,
             Z_temp_51, Z_temp_52, Z_temp_53, Z_temp_54,
             Z_temp_55, Z_temp_56, Z_temp_57, Z_temp_58,
             Z_temp_61, Z_temp_62, Z_temp_63, Z_temp_64,
             Z_temp_65, Z_temp_66, Z_temp_67, Z_temp_68,
             Z_temp_71, Z_temp_72, Z_temp_73, Z_temp_74,
             Z_temp_75, Z_temp_76, Z_temp_77, Z_temp_78,
             Z_temp_81, Z_temp_82, Z_temp_83, Z_temp_84,
             Z_temp_85, Z_temp_86, Z_temp_87, Z_temp_88;

// Z accumulators (27 bits): If Z_temp is 32 bits, and you sum 8 of them, max is 32+3=35 bits.
// Your Z is 26:0, which is 27 bits. This will truncate the sum.
// Please check the required bit width carefully based on your DCT's dynamic range.
logic [34:0] Z11, Z12, Z13, Z14, Z15, Z16, Z17, Z18, // Increased width to avoid truncation for sum of 8x 32-bit values
             Z21, Z22, Z23, Z24, Z25, Z26, Z27, Z28,
             Z31, Z32, Z33, Z34, Z35, Z36, Z37, Z38,
             Z41, Z42, Z43, Z44, Z45, Z46, Z47, Z48,
             Z51, Z52, Z53, Z54, Z55, Z56, Z57, Z58,
             Z61, Z62, Z63, Z64, Z65, Z66, Z67, Z68,
             Z71, Z72, Z73, Z74, Z75, Z76, Z77, Z78,
             Z81, Z82, Z83, Z84, Z85, Z86, Z87, Z88;

// Pipelined data_in
logic [7:0] data_reg; // Registered data_in for pipeline alignment

// Multiplier inputs (Y_mul_input and Ti_mul_input are coefficients)
integer Y2_mul_input, Y3_mul_input, Y4_mul_input, Y5_mul_input;
integer Y6_mul_input, Y7_mul_input, Y8_mul_input;
integer Ti2_mul_input, Ti3_mul_input, Ti4_mul_input, Ti5_mul_input;
integer Ti6_mul_input, Ti7_mul_input, Ti8_mul_input;

// Counter and pipeline control signals
logic [5:0] cycle_count;
logic [2:0] count; // Counts 0 to 7 within each 8-sample row/column
logic [2:0] count_of; // Counts 0 to 7 for 8x8 blocks (i.e., column index for 2D IDCT)

// Pipeline control flags - these need careful timing to align with your pipeline stages
// `enable_1` is already in use, so `enable` passes through it.
// `block_end` signal indicates the last sample of a 64-sample block
logic block_end;
// Pipeline registers for control signals
logic enable_pipe1, enable_pipe2, enable_pipe3, enable_pipe4;
logic count_of_pipe1, count_of_pipe2, count_of_pipe3, count_of_pipe4;
logic count_pipe1, count_pipe2;

// Registered output_enable for robust output assertion
logic output_enable_reg;

// Assign output_enable directly from the registered signal
assign output_enable = !rst && output_enable_reg;


// --- Cycle Counter and Pipeline Control Logic ---
always @(posedge clk) begin
    if (rst) begin
        cycle_count <= 0;
        count <= 0;
        count_of <= 0;
        enable_pipe1 <= 0;
        enable_pipe2 <= 0;
        enable_pipe3 <= 0;
        enable_pipe4 <= 0;
        count_of_pipe1 <= 0;
        count_of_pipe2 <= 0;
        count_of_pipe3 <= 0;
        count_of_pipe4 <= 0;
        count_pipe1 <= 0;
        count_pipe2 <= 0;
        block_end <= 0;
        output_enable_reg <= 0;
    end else if (enable) begin
        // Pipeline enable signal
        enable_pipe1 <= enable;
        enable_pipe2 <= enable_pipe1;
        enable_pipe3 <= enable_pipe2;
        enable_pipe4 <= enable_pipe3;

        data_reg <= data_in; // Correctly pipeline data_in at the very first stage

        if (cycle_count == 63) begin
            cycle_count <= 0;
            count <= 0;
            count_of <= count_of + 1; // Increment column counter for the next 8x8 block
            block_end <= 1; // Assert for one cycle when a 64-sample block ends
            output_enable_reg <= 1; // Assert final output enable
        end else begin
            cycle_count <= cycle_count + 1;
            count <= (cycle_count + 1) % 8; // Row counter (0-7)
            block_end <= 0;
            output_enable_reg <= 0; // Deassert unless block_end
        end
        // Pipeline count_of (column index) and count (row index)
        count_of_pipe1 <= count_of;
        count_of_pipe2 <= count_of_pipe1;
        count_of_pipe3 <= count_of_pipe2;
        count_of_pipe4 <= count_of_pipe3;

        count_pipe1 <= count;
        count_pipe2 <= count_pipe1; // Further delayed if needed
    end else begin // If enable is low, reset pipeline controls
        cycle_count <= 0;
        count <= 0;
        count_of <= 0;
        enable_pipe1 <= 0;
        enable_pipe2 <= 0;
        enable_pipe3 <= 0;
        enable_pipe4 <= 0;
        count_of_pipe1 <= 0;
        count_of_pipe2 <= 0;
        count_of_pipe3 <= 0;
        count_of_pipe4 <= 0;
        count_pipe1 <= 0;
        count_pipe2 <= 0;
        block_end <= 0;
        output_enable_reg <= 0;
    end
end


// --- DCT Matrix Entries (Combinational for simplicity, or can be registered) ---
// For a real DCT, these values are typically loaded from a ROM or computed based on 'k'
// for a 2D DCT.
always_comb begin
    T1 = 5793;
    T21 = 8035; T22 = 6811; T23 = 4551; T24 = 1598;
    T25 = -1598; T26 = -4551; T27 = -6811; T28 = -8035;
    T31 = 7568; T32 = 3135; T33 = -3135; T34 = -7568;
    T52 = -5793;
end

// --- Inverse DCT Matrix Entries (Combinational for simplicity) ---
// These are the coefficients for the inverse transform.
// As noted before, the selection logic `case (count_of_copy)` or `case (count_of_pipeX)` needs to
// correctly provide the 64 unique IDCT coefficients based on the current (u,v) output pixel.
// The current setup looks like it only provides 8 unique 'columns' of coefficients, which is
// highly suspicious for a true 2D IDCT. You need to verify this against your IDCT algorithm.
always_comb begin
    Ti1 = 5793;
    Ti21 = 8035; Ti22 = 6811; Ti23 = 4551; Ti24 = 1598;
    Ti25 = -1598; Ti26 = -4551; Ti27 = -6811; Ti28 = -8035;
    Ti31 = 7568; Ti32 = 3135; Ti33 = -3135; Ti34 = -7568;
    Ti52 = -5793;

    // This section is critical and needs re-evaluation for a correct 2D IDCT implementation.
    // The coefficients `TiX_mul_input` should be selected based on both 'u' (row) and 'v' (column)
    // of the Z(u,v) output being calculated, effectively forming an 8x8 matrix of coefficients.
    // The current `count_of_pipeX` only effectively indexes one dimension.
    // This is a placeholder using your original structure.
    case (count_of_pipe4) // Using count_of_pipe4 to align with Z_temp computation stage
        3'b000: Ti2_mul_input = Ti28;
        3'b001: Ti2_mul_input = Ti21;
        3'b010: Ti2_mul_input = Ti22;
        3'b011: Ti2_mul_input = Ti23;
        3'b100: Ti2_mul_input = Ti24;
        3'b101: Ti2_mul_input = Ti25;
        3'b110: Ti2_mul_input = Ti26;
        3'b111: Ti2_mul_input = Ti27;
        default: Ti2_mul_input = Ti28;
    endcase

    case (count_of_pipe4)
        3'b000: Ti3_mul_input = Ti31;
        3'b001: Ti3_mul_input = Ti31;
        3'b010: Ti3_mul_input = Ti32;
        3'b011: Ti3_mul_input = Ti33;
        3'b100: Ti3_mul_input = Ti34;
        3'b101: Ti3_mul_input = Ti34;
        3'b110: Ti3_mul_input = Ti33;
        3'b111: Ti3_mul_input = Ti32;
        default: Ti3_mul_input = Ti31;
    endcase

    case (count_of_pipe4)
        3'b000: Ti4_mul_input = Ti27;
        3'b001: Ti4_mul_input = Ti22;
        3'b010: Ti4_mul_input = Ti25;
        3'b011: Ti4_mul_input = Ti28;
        3'b100: Ti4_mul_input = Ti26;
        3'b101: Ti4_mul_input = Ti23;
        3'b110: Ti4_mul_input = Ti21;
        3'b111: Ti4_mul_input = Ti24;
        default: Ti4_mul_input = Ti27;
    endcase

    case (count_of_pipe4)
        3'b000: Ti5_mul_input = Ti1;
        3'b001: Ti5_mul_input = Ti1;
        3'b010: Ti5_mul_input = Ti52;
        3'b011: Ti5_mul_input = Ti52;
        3'b100: Ti5_mul_input = Ti1;
        3'b101: Ti5_mul_input = Ti1;
        3'b110: Ti5_mul_input = Ti52;
        3'b111: Ti5_mul_input = Ti52;
        default: Ti5_mul_input = Ti1;
    endcase

    case (count_of_pipe4)
        3'b000: Ti6_mul_input = Ti26;
        3'b001: Ti6_mul_input = Ti23;
        3'b010: Ti6_mul_input = Ti28;
        3'b011: Ti6_mul_input = Ti24;
        3'b100: Ti6_mul_input = Ti22;
        3'b101: Ti6_mul_input = Ti27;
        3'b110: Ti6_mul_input = Ti25;
        3'b111: Ti6_mul_input = Ti21;
        default: Ti6_mul_input = Ti26;
    endcase

    case (count_of_pipe4)
        3'b000: Ti7_mul_input = Ti32;
        3'b001: Ti7_mul_input = Ti32;
        3'b010: Ti7_mul_input = Ti34;
        3'b011: Ti7_mul_input = Ti31;
        3'b100: Ti7_mul_input = Ti33;
        3'b101: Ti7_mul_input = Ti33;
        3'b110: Ti7_mul_input = Ti31;
        3'b111: Ti7_mul_input = Ti34;
        default: Ti7_mul_input = Ti32;
    endcase

    case (count_of_pipe4)
        3'b000: Ti8_mul_input = Ti25;
        3'b001: Ti8_mul_input = Ti24;
        3'b010: Ti8_mul_input = Ti26;
        3'b011: Ti8_mul_input = Ti22;
        3'b100: Ti8_mul_input = Ti28;
        3'b101: Ti8_mul_input = Ti21;
        3'b110: Ti8_mul_input = Ti27;
        3'b111: Ti8_mul_input = Ti23;
        default: Ti8_mul_input = Ti25;
    endcase
end


// --- Y_temp_X and Y_X Accumulations (First DCT pass, Row-wise) ---
// This section calculates Y coefficients. These would typically be the 1D DCT results.
always @(posedge clk) begin
    if (rst) begin
        Y_temp_11 <= 0; Y11 <= 0;
        Y_temp_21 <= 0; Y21 <= 0;
        Y_temp_31 <= 0; Y31 <= 0;
        Y_temp_41 <= 0; Y41 <= 0;
        Y_temp_51 <= 0; Y51 <= 0;
        Y_temp_61 <= 0; Y61 <= 0;
        Y_temp_71 <= 0; Y71 <= 0;
        Y_temp_81 <= 0; Y81 <= 0;
    end else if (enable_pipe1) begin // Use enable_pipe1 for first stage calculations
        // Y_temp computations (current input * coefficient)
        Y_temp_11 <= data_reg * T1;
        Y_temp_21 <= data_reg * Y2_mul_input; // Y2_mul_input is combinational, check its source
        Y_temp_31 <= data_reg * Y3_mul_input;
        Y_temp_41 <= data_reg * Y4_mul_input;
        Y_temp_51 <= data_reg * Y5_mul_input;
        Y_temp_61 <= data_reg * Y6_mul_input;
        Y_temp_71 <= data_reg * Y7_mul_input;
        Y_temp_81 <= data_reg * Y8_mul_input;

        // Y accumulators (sum over 8 data points)
        // Reset accumulators when starting a new 8-sample row (count == 0)
        if (count == 0) begin
            Y11 <= Y_temp_11;
            Y21 <= Y_temp_21;
            Y31 <= Y_temp_31;
            Y41 <= Y_temp_41;
            Y51 <= Y_temp_51;
            Y61 <= Y_temp_61;
            Y71 <= Y_temp_71;
            Y81 <= Y_temp_81;
        end else begin
            Y11 <= Y_temp_11 + Y11;
            Y21 <= Y_temp_21 + Y21;
            Y31 <= Y_temp_31 + Y31;
            Y41 <= Y_temp_41 + Y41;
            Y51 <= Y_temp_51 + Y51;
            Y61 <= Y_temp_61 + Y61;
            Y71 <= Y_temp_71 + Y71;
            Y81 <= Y_temp_81 + Y81;
        end
    end
end

// --- Y_mul_input Selection ---
// These coefficient selectors should ideally be registered or part of a more explicit FSM
// to ensure correct timing with the data pipeline. For now, kept as original `always_comb`.
// If `T` values are constant, these `always_comb` blocks imply fixed multipliers based on `count`.
always_comb begin : Y2_mul_input_selection
    case (count_pipe1) // Using count_pipe1 to align with Y_temp computation
        3'b000: Y2_mul_input = T21;
        3'b001: Y2_mul_input = T22;
        3'b010: Y2_mul_input = T23;
        3'b011: Y2_mul_input = T24;
        3'b100: Y2_mul_input = T25;
        3'b101: Y2_mul_input = T26;
        3'b110: Y2_mul_input = T27;
        3'b111: Y2_mul_input = T28;
        default: Y2_mul_input = 0; // Default to 0, or an appropriate error value
    endcase
end

always_comb begin : Y3_mul_input_selection
    case (count_pipe1)
        3'b000: Y3_mul_input = T31;
        3'b001: Y3_mul_input = T32;
        3'b010: Y3_mul_input = T33;
        3'b011: Y3_mul_input = T34;
        3'b100: Y3_mul_input = T34;
        3'b101: Y3_mul_input = T33;
        3'b110: Y3_mul_input = T32;
        3'b111: Y3_mul_input = T31;
        default: Y3_mul_input = 0;
    endcase
end

always_comb begin : Y4_mul_input_selection
    case (count_pipe1)
        3'b000: Y4_mul_input = T22;
        3'b001: Y4_mul_input = T25;
        3'b010: Y4_mul_input = T28;
        3'b011: Y4_mul_input = T26;
        3'b100: Y4_mul_input = T23;
        3'b101: Y4_mul_input = T21;
        3'b110: Y4_mul_input = T24;
        3'b111: Y4_mul_input = T27;
        default: Y4_mul_input = 0;
    endcase
end

always_comb begin : Y5_mul_input_selection
    case (count_pipe1)
        3'b000: Y5_mul_input = T1;
        3'b001: Y5_mul_input = T52;
        3'b010: Y5_mul_input = T52;
        3'b011: Y5_mul_input = T1;
        3'b100: Y5_mul_input = T1;
        3'b101: Y5_mul_input = T52;
        3'b110: Y5_mul_input = T52;
        3'b111: Y5_mul_input = T1;
        default: Y5_mul_input = 0;
    endcase
end

always_comb begin : Y6_mul_input_selection
    case (count_pipe1)
        3'b000: Y6_mul_input = T23;
        3'b001: Y6_mul_input = T28;
        3'b010: Y6_mul_input = T24;
        3'b011: Y6_mul_input = T22;
        3'b100: Y6_mul_input = T27;
        3'b101: Y6_mul_input = T25;
        3'b110: Y6_mul_input = T21;
        3'b111: Y6_mul_input = T26;
        default: Y6_mul_input = 0;
    endcase
end

always_comb begin : Y7_mul_input_selection
    case (count_pipe1)
        3'b000: Y7_mul_input = T32;
        3'b001: Y7_mul_input = T34;
        3'b010: Y7_mul_input = T31;
        3'b011: Y7_mul_input = T33;
        3'b100: Y7_mul_input = T33;
        3'b101: Y7_mul_input = T31;
        3'b110: Y7_mul_input = T34;
        3'b111: Y7_mul_input = T32;
        default: Y7_mul_input = 0;
    endcase
end

always_comb begin : Y8_mul_input_selection
    case (count_pipe1)
        3'b000: Y8_mul_input = T24;
        3'b001: Y8_mul_input = T26;
        3'b010: Y8_mul_input = T22;
        3'b011: Y8_mul_input = T28;
        3'b100: Y8_mul_input = T21;
        3'b101: Y8_mul_input = T27;
        3'b110: Y8_mul_input = T23;
        3'b111: Y8_mul_input = T25;
        default: Y8_mul_input = 0;
    endcase
end


// --- Y_final Centering and Pipelining (Pipelined stages after 1D DCT accumulation) ---
// These stages seem to implement part of the IDCT or a centering operation.
// The constant 25'd5932032 indicates a fixed offset, likely related to input range or scaling.
always @(posedge clk) begin
    if (rst) begin
        Y11_final <= 0;
        Y21_final <= 0; Y21_final_prev <= 0;
        Y31_final <= 0; Y31_final_prev <= 0;
        Y41_final <= 0; Y41_final_prev <= 0;
        Y51_final <= 0; Y51_final_prev <= 0;
        Y61_final <= 0; Y61_final_prev <= 0;
        Y71_final <= 0; Y71_final_prev <= 0;
        Y81_final <= 0; Y81_final_prev <= 0;
    end else if (enable_pipe2) begin // Ensure this stage is enabled
        // Y11_final is shifted by a constant
        Y11_final <= Y11 - 25'd5932032; // This is applied on every relevant clock cycle, not just block 0

        // YX1_final and YX1_final_prev for difference calculation
        // These should be updated when the 8-point accumulation for their respective YX1 completes.
        // Assuming `count_pipe2 == 7` means the YX1 values are ready from the previous stage.
        if (count_pipe2 == 7) begin // End of an 8-point accumulation
            Y21_final <= Y21; Y21_final_prev <= Y21_final;
            Y31_final <= Y31; Y31_final_prev <= Y31_final;
            Y41_final <= Y41; Y41_final_prev <= Y41_final;
            Y51_final <= Y51; Y51_final_prev <= Y51_final;
            Y61_final <= Y61; Y61_final_prev <= Y61_final;
            Y71_final <= Y71; Y71_final_prev <= Y71_final;
            Y81_final <= Y81; Y81_final_prev <= Y81_final;
        end
    end
end

// YX1_final_diff calculations (another pipeline stage)
always @(posedge clk) begin
    if (rst) begin
        Y21_final_diff <= 0; Y31_final_diff <= 0; Y41_final_diff <= 0;
        Y51_final_diff <= 0; Y61_final_diff <= 0; Y71_final_diff <= 0; Y81_final_diff <= 0;
    end else if (enable_pipe3) begin // Ensure this stage is enabled
        // Assuming YX1_final and YX1_final_prev are valid from previous pipeline stage
        // and these differences are needed when the previous stage's values are stable.
        if (count_pipe2 == 7) begin // Trigger when the YX1_final and _prev are new.
            Y21_final_diff <= Y21_final - Y21_final_prev;
            Y31_final_diff <= Y31_final - Y31_final_prev;
            Y41_final_diff <= Y41_final - Y41_final_prev;
            Y51_final_diff <= Y51_final - Y51_final_prev;
            Y61_final_diff <= Y61_final - Y61_final_prev;
            Y71_final_diff <= Y71_final - Y71_final_prev;
            Y81_final_diff <= Y81_final - Y81_final_prev;
        end
    end
end


// --- Rounding Stage (Y_final_1, Y_final_2, Y_final_3, Y_final_4) ---
// This stage prepares the Y coefficients for the second IDCT pass (multiplication with Ti coefficients).
always @(posedge clk) begin
    if (rst) begin
        Y11_final_1 <= 0; Y21_final_1 <= 0; Y31_final_1 <= 0; Y41_final_1 <= 0;
        Y51_final_1 <= 0; Y61_final_1 <= 0; Y71_final_1 <= 0; Y81_final_1 <= 0;
        Y11_final_2 <= 0; Y21_final_2 <= 0; Y31_final_2 <= 0; Y41_final_2 <= 0;
        Y51_final_2 <= 0; Y61_final_2 <= 0; Y71_final_2 <= 0; Y81_final_2 <= 0;
        Y11_final_3 <= 0; Y11_final_4 <= 0;
    end else if (enable_pipe4) begin // Ensure this stage is enabled
        // Rounding from 25-bit to 13-bit (by checking bit 11)
        Y11_final_1 <= Y11_final[11] ? Y11_final[24:12] + 1 : Y11_final[24:12];
        // Sign extend 13-bit Y11_final_1 to 32 bits for multiplication
        Y11_final_2 <= {{19{Y11_final_1[12]}}, Y11_final_1[12:0]}; // Fixed sign extension
        Y11_final_3 <= Y11_final_2; // Further pipeline delay
        Y11_final_4 <= Y11_final_3; // Further pipeline delay for multiplication

        // Apply rounding and sign extension to other YX1_final_diff outputs
        Y21_final_1 <= Y21_final_diff[11] ? Y21_final_diff[24:12] + 1 : Y21_final_diff[24:12];
        Y21_final_2 <= {{19{Y21_final_1[12]}}, Y21_final_1[12:0]};

        Y31_final_1 <= Y31_final_diff[11] ? Y31_final_diff[24:12] + 1 : Y31_final_diff[24:12];
        Y31_final_2 <= {{19{Y31_final_1[12]}}, Y31_final_1[12:0]};

        Y41_final_1 <= Y41_final_diff[11] ? Y41_final_diff[24:12] + 1 : Y41_final_diff[24:12];
        Y41_final_2 <= {{19{Y41_final_1[12]}}, Y41_final_1[12:0]};

        Y51_final_1 <= Y51_final_diff[11] ? Y51_final_diff[24:12] + 1 : Y51_final_diff[24:12];
        Y51_final_2 <= {{19{Y51_final_1[12]}}, Y51_final_1[12:0]};

        Y61_final_1 <= Y61_final_diff[11] ? Y61_final_diff[24:12] + 1 : Y61_final_diff[24:12];
        Y61_final_2 <= {{19{Y61_final_1[12]}}, Y61_final_1[12:0]};

        Y71_final_1 <= Y71_final_diff[11] ? Y71_final_diff[24:12] + 1 : Y71_final_diff[24:12];
        Y71_final_2 <= {{19{Y71_final_1[12]}}, Y71_final_1[12:0]};

        Y81_final_1 <= Y81_final_diff[11] ? Y81_final_diff[24:12] + 1 : Y81_final_diff[24:12];
        Y81_final_2 <= {{19{Y81_final_1[12]}}, Y81_final_1[12:0]};
    end
end


// --- Z_temp Assignments (Multiplication stage of IDCT) ---
// These calculations are part of the 2D IDCT, typically column-wise.
// They use the pipelined Y values and the inverse DCT coefficients.
always @(posedge clk) begin
    if (rst) begin
        Z_temp_11 <= 0; Z_temp_12 <= 0; Z_temp_13 <= 0; Z_temp_14 <= 0;
        Z_temp_15 <= 0; Z_temp_16 <= 0; Z_temp_17 <= 0; Z_temp_18 <= 0;
        Z_temp_21 <= 0; Z_temp_22 <= 0; Z_temp_23 <= 0; Z_temp_24 <= 0;
        Z_temp_25 <= 0; Z_temp_26 <= 0; Z_temp_27 <= 0; Z_temp_28 <= 0;
        Z_temp_31 <= 0; Z_temp_32 <= 0; Z_temp_33 <= 0; Z_temp_34 <= 0;
        Z_temp_35 <= 0; Z_temp_36 <= 0; Z_temp_37 <= 0; Z_temp_38 <= 0;
        Z_temp_41 <= 0; Z_temp_42 <= 0; Z_temp_43 <= 0; Z_temp_44 <= 0;
        Z_temp_45 <= 0; Z_temp_46 <= 0; Z_temp_47 <= 0; Z_temp_48 <= 0;
        Z_temp_51 <= 0; Z_temp_52 <= 0; Z_temp_53 <= 0; Z_temp_54 <= 0;
        Z_temp_55 <= 0; Z_temp_56 <= 0; Z_temp_57 <= 0; Z_temp_58 <= 0;
        Z_temp_61 <= 0; Z_temp_62 <= 0; Z_temp_63 <= 0; Z_temp_64 <= 0;
        Z_temp_65 <= 0; Z_temp_66 <= 0; Z_temp_67 <= 0; Z_temp_68 <= 0;
        Z_temp_71 <= 0; Z_temp_72 <= 0; Z_temp_73 <= 0; Z_temp_74 <= 0;
        Z_temp_75 <= 0; Z_temp_76 <= 0; Z_temp_77 <= 0; Z_temp_78 <= 0;
        Z_temp_81 <= 0; Z_temp_82 <= 0; Z_temp_83 <= 0; Z_temp_84 <= 0;
        Z_temp_85 <= 0; Z_temp_86 <= 0; Z_temp_87 <= 0; Z_temp_88 <= 0;
    end else if (enable_pipe4) begin // Enable this stage when Y_final_4, etc., are valid
        // Multiplications for the Z_temps
        // Assuming Y11_final_4 is for Z1X, Y21_final_2 for Z2X, etc.
        // This is a direct translation of your original assignments.
        Z_temp_11 <= Y11_final_4 * Ti1;
        Z_temp_12 <= Y11_final_4 * Ti2_mul_input; // TiX_mul_input selection is critical here
        Z_temp_13 <= Y11_final_4 * Ti3_mul_input;
        Z_temp_14 <= Y11_final_4 * Ti4_mul_input;
        Z_temp_15 <= Y11_final_4 * Ti5_mul_input;
        Z_temp_16 <= Y11_final_4 * Ti6_mul_input;
        Z_temp_17 <= Y11_final_4 * Ti7_mul_input;
        Z_temp_18 <= Y11_final_4 * Ti8_mul_input;
        Z_temp_21 <= Y21_final_2 * Ti1;
        Z_temp_22 <= Y21_final_2 * Ti2_mul_input;
        Z_temp_23 <= Y21_final_2 * Ti3_mul_input;
        Z_temp_24 <= Y21_final_2 * Ti4_mul_input;
        Z_temp_25 <= Y21_final_2 * Ti5_mul_input;
        Z_temp_26 <= Y21_final_2 * Ti6_mul_input;
        Z_temp_27 <= Y21_final_2 * Ti7_mul_input;
        Z_temp_28 <= Y21_final_2 * Ti8_mul_input;
        Z_temp_31 <= Y31_final_2 * Ti1;
        Z_temp_32 <= Y31_final_2 * Ti2_mul_input;
        Z_temp_33 <= Y31_final_2 * Ti3_mul_input;
        Z_temp_34 <= Y31_final_2 * Ti4_mul_input;
        Z_temp_35 <= Y31_final_2 * Ti5_mul_input;
        Z_temp_36 <= Y31_final_2 * Ti6_mul_input;
        Z_temp_37 <= Y31_final_2 * Ti7_mul_input;
        Z_temp_38 <= Y31_final_2 * Ti8_mul_input;
        Z_temp_41 <= Y41_final_2 * Ti1;
        Z_temp_42 <= Y41_final_2 * Ti2_mul_input;
        Z_temp_43 <= Y41_final_2 * Ti3_mul_input;
        Z_temp_44 <= Y41_final_2 * Ti4_mul_input;
        Z_temp_45 <= Y41_final_2 * Ti5_mul_input;
        Z_temp_46 <= Y41_final_2 * Ti6_mul_input;
        Z_temp_47 <= Y41_final_2 * Ti7_mul_input;
        Z_temp_48 <= Y41_final_2 * Ti8_mul_input;
        Z_temp_51 <= Y51_final_2 * Ti1;
        Z_temp_52 <= Y51_final_2 * Ti2_mul_input;
        Z_temp_53 <= Y51_final_2 * Ti3_mul_input;
        Z_temp_54 <= Y51_final_2 * Ti4_mul_input;
        Z_temp_55 <= Y51_final_2 * Ti5_mul_input;
        Z_temp_56 <= Y51_final_2 * Ti6_mul_input;
        Z_temp_57 <= Y51_final_2 * Ti7_mul_input;
        Z_temp_58 <= Y51_final_2 * Ti8_mul_input;
        Z_temp_61 <= Y61_final_2 * Ti1;
        Z_temp_62 <= Y61_final_2 * Ti2_mul_input;
        Z_temp_63 <= Y61_final_2 * Ti3_mul_input;
        Z_temp_64 <= Y61_final_2 * Ti4_mul_input;
        Z_temp_65 <= Y61_final_2 * Ti5_mul_input;
        Z_temp_66 <= Y61_final_2 * Ti6_mul_input;
        Z_temp_67 <= Y61_final_2 * Ti7_mul_input;
        Z_temp_68 <= Y61_final_2 * Ti8_mul_input;
        Z_temp_71 <= Y71_final_2 * Ti1;
        Z_temp_72 <= Y71_final_2 * Ti2_mul_input;
        Z_temp_73 <= Y71_final_2 * Ti3_mul_input;
        Z_temp_74 <= Y71_final_2 * Ti4_mul_input;
        Z_temp_75 <= Y71_final_2 * Ti5_mul_input;
        Z_temp_76 <= Y71_final_2 * Ti6_mul_input;
        Z_temp_77 <= Y71_final_2 * Ti7_mul_input;
        Z_temp_78 <= Y71_final_2 * Ti8_mul_input;
        Z_temp_81 <= Y81_final_2 * Ti1;
        Z_temp_82 <= Y81_final_2 * Ti2_mul_input;
        Z_temp_83 <= Y81_final_2 * Ti3_mul_input;
        Z_temp_84 <= Y81_final_2 * Ti4_mul_input;
        Z_temp_85 <= Y81_final_2 * Ti5_mul_input;
        Z_temp_86 <= Y81_final_2 * Ti6_mul_input;
        Z_temp_87 <= Y81_final_2 * Ti7_mul_input;
        Z_temp_88 <= Y81_final_2 * Ti8_mul_input;
    end
end


// --- Z Accumulators (Second DCT pass, Column-wise) ---
// These accumulate the Z_temp values.
always @(posedge clk) begin
    if (rst) begin
        Z11 <= 0; Z12 <= 0; Z13 <= 0; Z14 <= 0; Z15 <= 0; Z16 <= 0; Z17 <= 0; Z18 <= 0;
        Z21 <= 0; Z22 <= 0; Z23 <= 0; Z24 <= 0; Z25 <= 0; Z26 <= 0; Z27 <= 0; Z28 <= 0;
        Z31 <= 0; Z32 <= 0; Z33 <= 0; Z34 <= 0; Z35 <= 0; Z36 <= 0; Z37 <= 0; Z38 <= 0;
        Z41 <= 0; Z42 <= 0; Z43 <= 0; Z44 <= 0; Z45 <= 0; Z46 <= 0; Z47 <= 0; Z48 <= 0;
        Z51 <= 0; Z52 <= 0; Z53 <= 0; Z54 <= 0; Z55 <= 0; Z56 <= 0; Z57 <= 0; Z58 <= 0;
        Z61 <= 0; Z62 <= 0; Z63 <= 0; Z64 <= 0; Z65 <= 0; Z66 <= 0; Z67 <= 0; Z68 <= 0;
        Z71 <= 0; Z72 <= 0; Z73 <= 0; Z74 <= 0; Z75 <= 0; Z76 <= 0; Z77 <= 0; Z78 <= 0;
        Z81 <= 0; Z82 <= 0; Z83 <= 0; Z84 <= 0; Z85 <= 0; Z86 <= 0; Z87 <= 0; Z88 <= 0;
    end else if (enable_pipe4) begin // Accumulate when Z_temp values are ready.
        // Assuming `count_pipe2` (from an earlier stage) reaching 7 signifies the end of a column input for Z_temp
        if (count_pipe2 == 7) begin // If this is the last Z_temp for a column, reset accumulator.
            Z11 <= Z_temp_11; Z12 <= Z_temp_12; Z13 <= Z_temp_13; Z14 <= Z_temp_14;
            Z15 <= Z_temp_15; Z16 <= Z_temp_16; Z17 <= Z_temp_17; Z18 <= Z_temp_18;
            Z21 <= Z_temp_21; Z22 <= Z_temp_22; Z23 <= Z_temp_23; Z24 <= Z_temp_24;
            Z25 <= Z_temp_25; Z26 <= Z_temp_26; Z27 <= Z_temp_27; Z28 <= Z_temp_28;
            Z31 <= Z_temp_31; Z32 <= Z_temp_32; Z33 <= Z_temp_33; Z34 <= Z_temp_34;
            Z35 <= Z_temp_35; Z36 <= Z_temp_36; Z37 <= Z_temp_37; Z38 <= Z_temp_38;
            Z41 <= Z_temp_41; Z42 <= Z_temp_42; Z43 <= Z_temp_43; Z44 <= Z_temp_44;
            Z45 <= Z_temp_45; Z46 <= Z_temp_46; Z47 <= Z_temp_47; Z48 <= Z_temp_48;
            Z51 <= Z_temp_51; Z52 <= Z_temp_52; Z53 <= Z_temp_53; Z54 <= Z_temp_54;
            Z55 <= Z_temp_55; Z56 <= Z_temp_56; Z57 <= Z_temp_57; Z58 <= Z_temp_58;
            Z61 <= Z_temp_61; Z62 <= Z_temp_62; Z63 <= Z_temp_63; Z64 <= Z_temp_64;
            Z65 <= Z_temp_65; Z66 <= Z_temp_66; Z67 <= Z_temp_67; Z68 <= Z_temp_68;
            Z71 <= Z_temp_71; Z72 <= Z_temp_72; Z73 <= Z_temp_73; Z74 <= Z_temp_74;
            Z75 <= Z_temp_75; Z76 <= Z_temp_76; Z77 <= Z_temp_77; Z78 <= Z_temp_78;
            Z81 <= Z_temp_81; Z82 <= Z_temp_82; Z83 <= Z_temp_83; Z84 <= Z_temp_84;
            Z85 <= Z_temp_85; Z86 <= Z_temp_86; Z87 <= Z_temp_87; Z88 <= Z_temp_88;
        end else begin // Otherwise, accumulate
            Z11 <= Z_temp_11 + Z11; Z12 <= Z_temp_12 + Z12; Z13 <= Z_temp_13 + Z13; Z14 <= Z_temp_14 + Z14;
            Z15 <= Z_temp_15 + Z15; Z16 <= Z_temp_16 + Z16; Z17 <= Z_temp_17 + Z17; Z18 <= Z_temp_18 + Z18;
            Z21 <= Z_temp_21 + Z21; Z22 <= Z_temp_22 + Z22; Z23 <= Z_temp_23 + Z23; Z24 <= Z_temp_24 + Z24;
            Z25 <= Z_temp_25 + Z25; Z26 <= Z_temp_26 + Z26; Z27 <= Z_temp_27 + Z27; Z28 <= Z_temp_28 + Z28;
            Z31 <= Z_temp_31 + Z31; Z32 <= Z_temp_32 + Z32; Z33 <= Z_temp_33 + Z33; Z34 <= Z_temp_34 + Z34;
            Z35 <= Z_temp_35 + Z35; Z36 <= Z_temp_36 + Z36; Z37 <= Z_temp_37 + Z37; Z38 <= Z_temp_38 + Z38;
            Z41 <= Z_temp_41 + Z41; Z42 <= Z_temp_42 + Z42; Z43 <= Z_temp_43 + Z43; Z44 <= Z_temp_44 + Z44;
            Z45 <= Z_temp_45 + Z45; Z46 <= Z_temp_46 + Z46; Z47 <= Z_temp_47 + Z47; Z48 <= Z_temp_48 + Z48;
            Z51 <= Z_temp_51 + Z51; Z52 <= Z_temp_52 + Z52; Z53 <= Z_temp_53 + Z53; Z54 <= Z_temp_54 + Z54;
            Z55 <= Z_temp_55 + Z55; Z56 <= Z_temp_56 + Z56; Z57 <= Z_temp_57 + Z57; Z58 <= Z_temp_58 + Z58;
            Z61 <= Z_temp_61 + Z61; Z62 <= Z_temp_62 + Z62; Z63 <= Z_temp_63 + Z63; Z64 <= Z_temp_64 + Z64;
            Z65 <= Z_temp_65 + Z65; Z66 <= Z_temp_66 + Z66; Z67 <= Z_temp_67 + Z67; Z68 <= Z_temp_68 + Z68;
            Z71 <= Z_temp_71 + Z71; Z72 <= Z_temp_72 + Z72; Z73 <= Z_temp_73 + Z73; Z74 <= Z_temp_74 + Z74;
            Z75 <= Z_temp_75 + Z75; Z76 <= Z_temp_76 + Z76; Z77 <= Z_temp_77 + Z77; Z78 <= Z_temp_78 + Z78;
            Z81 <= Z_temp_81 + Z81; Z82 <= Z_temp_82 + Z82; Z83 <= Z_temp_83 + Z83; Z84 <= Z_temp_84 + Z84;
            Z85 <= Z_temp_85 + Z85; Z86 <= Z_temp_86 + Z86; Z87 <= Z_temp_87 + Z87; Z88 <= Z_temp_88 + Z88;
        end
    end
end

// --- Final Output Rounding and Saturation (to 11-bit output) ---
// The rounding logic assumes a 16-bit fractional part (bit 15).
// The output is 11-bit. If Z is 35 bits, Z[26:16] is 11 bits. This aligns.
always @(posedge clk) begin
    if (rst) begin
        Z11_final <= 0; Z12_final <= 0; Z13_final <= 0; Z14_final <= 0;
        Z15_final <= 0; Z16_final <= 0; Z17_final <= 0; Z18_final <= 0;
        Z21_final <= 0; Z22_final <= 0; Z23_final <= 0; Z24_final <= 0;
        Z25_final <= 0; Z26_final <= 0; Z27_final <= 0; Z28_final <= 0;
        Z31_final <= 0; Z32_final <= 0; Z33_final <= 0; Z34_final <= 0;
        Z35_final <= 0; Z36_final <= 0; Z37_final <= 0; Z38_final <= 0;
        Z41_final <= 0; Z42_final <= 0; Z43_final <= 0; Z44_final <= 0;
        Z45_final <= 0; Z46_final <= 0; Z47_final <= 0; Z48_final <= 0;
        Z51_final <= 0; Z52_final <= 0; Z53_final <= 0; Z54_final <= 0;
        Z55_final <= 0; Z56_final <= 0; Z57_final <= 0; Z58_final <= 0;
        Z61_final <= 0; Z62_final <= 0; Z63_final <= 0; Z64_final <= 0;
        Z65_final <= 0; Z66_final <= 0; Z67_final <= 0; Z68_final <= 0;
        Z71_final <= 0; Z72_final <= 0; Z73_final <= 0; Z74_final <= 0;
        Z75_final <= 0; Z76_final <= 0; Z77_final <= 0; Z78_final <= 0;
        Z81_final <= 0; Z82_final <= 0; Z83_final <= 0; Z84_final <= 0;
        Z85_final <= 0; Z86_final <= 0; Z87_final <= 0; Z88_final <= 0;
    end else if (output_enable_reg) begin // Assert when the final result is ready
        // Rounding logic for 11-bit output
        // Z[15] is the fractional bit, Z[26:16] is the integer part
        Z11_final <= Z11[15] ? Z11[26:16] + 1 : Z11[26:16];
        Z12_final <= Z12[15] ? Z12[26:16] + 1 : Z12[26:16];
        Z13_final <= Z13[15] ? Z13[26:16] + 1 : Z13[26:16];
        Z14_final <= Z14[15] ? Z14[26:16] + 1 : Z14[26:16];
        Z15_final <= Z15[15] ? Z15[26:16] + 1 : Z15[26:16];
        Z16_final <= Z16[15] ? Z16[26:16] + 1 : Z16[26:16];
        Z17_final <= Z17[15] ? Z17[26:16] + 1 : Z17[26:16];
        Z18_final <= Z18[15] ? Z18[26:16] + 1 : Z18[26:16];
        Z21_final <= Z21[15] ? Z21[26:16] + 1 : Z21[26:16];
        Z22_final <= Z22[15] ? Z22[26:16] + 1 : Z22[26:16];
        Z23_final <= Z23[15] ? Z23[26:16] + 1 : Z23[26:16];
        Z24_final <= Z24[15] ? Z24[26:16] + 1 : Z24[26:16];
        Z25_final <= Z25[15] ? Z25[26:16] + 1 : Z25[26:16];
        Z26_final <= Z26[15] ? Z26[26:16] + 1 : Z26[26:16];
        Z27_final <= Z27[15] ? Z27[26:16] + 1 : Z27[26:16];
        Z28_final <= Z28[15] ? Z28[26:16] + 1 : Z28[26:16];
        Z31_final <= Z31[15] ? Z31[26:16] + 1 : Z31[26:16];
        Z32_final <= Z32[15] ? Z32[26:16] + 1 : Z32[26:16];
        Z33_final <= Z33[15] ? Z33[26:16] + 1 : Z33[26:16];
        Z34_final <= Z34[15] ? Z34[26:16] + 1 : Z34[26:16];
        Z35_final <= Z35[15] ? Z35[26:16] + 1 : Z35[26:16];
        Z36_final <= Z36[15] ? Z36[26:16] + 1 : Z36[26:16];
        Z37_final <= Z37[15] ? Z37[26:16] + 1 : Z37[26:16];
        Z38_final <= Z38[15] ? Z38[26:16] + 1 : Z38[26:16];
        Z41_final <= Z41[15] ? Z41[26:16] + 1 : Z41[26:16];
        Z42_final <= Z42[15] ? Z42[26:16] + 1 : Z42[26:16];
        Z43_final <= Z43[15] ? Z43[26:16] + 1 : Z43[26:16];
        Z44_final <= Z44[15] ? Z44[26:16] + 1 : Z44[26:16];
        Z45_final <= Z45[15] ? Z45[26:16] + 1 : Z45[26:16];
        Z46_final <= Z46[15] ? Z46[26:16] + 1 : Z46[26:16];
        Z47_final <= Z47[15] ? Z47[26:16] + 1 : Z47[26:16];
        Z48_final <= Z48[15] ? Z48[26:16] + 1 : Z48[26:16];
        Z51_final <= Z51[15] ? Z51[26:16] + 1 : Z51[26:16];
        Z52_final <= Z52[15] ? Z52[26:16] + 1 : Z52[26:16];
        Z53_final <= Z53[15] ? Z53[26:16] + 1 : Z53[26:16];
        Z54_final <= Z54[15] ? Z54[26:16] + 1 : Z54[26:16];
        Z55_final <= Z55[15] ? Z55[26:16] + 1 : Z55[26:16];
        Z56_final <= Z56[15] ? Z56[26:16] + 1 : Z56[26:16];
        Z57_final <= Z57[15] ? Z57[26:16] + 1 : Z57[26:16]; // Corrected the bit slice to 26:16
        Z58_final <= Z58[15] ? Z58[26:16] + 1 : Z58[26:16];
        Z61_final <= Z61[15] ? Z61[26:16] + 1 : Z61[26:16];
        Z62_final <= Z62[15] ? Z62[26:16] + 1 : Z62[26:16];
        Z63_final <= Z63[15] ? Z63[26:16] + 1 : Z63[26:16];
        Z64_final <= Z64[15] ? Z64[26:16] + 1 : Z64[26:16];
        Z65_final <= Z65[15] ? Z65[26:16] + 1 : Z65[26:16];
        Z66_final <= Z66[15] ? Z66[26:16] + 1 : Z66[26:16];
        Z67_final <= Z67[15] ? Z67[26:16] + 1 : Z67[26:16];
        Z68_final <= Z68[15] ? Z68[26:16] + 1 : Z68[26:16];
        Z71_final <= Z71[15] ? Z71[26:16] + 1 : Z71[26:16];
        Z72_final <= Z72[15] ? Z72[26:16] + 1 : Z72[26:16];
        Z73_final <= Z73[15] ? Z73[26:16] + 1 : Z73[26:16];
        Z74_final <= Z74[15] ? Z74[26:16] + 1 : Z74[26:16];
        Z75_final <= Z75[15] ? Z75[26:16] + 1 : Z75[26:16];
        Z76_final <= Z76[15] ? Z76[26:16] + 1 : Z76[26:16];
        Z77_final <= Z77[15] ? Z77[26:16] + 1 : Z77[26:16];
        Z78_final <= Z78[15] ? Z78[26:16] + 1 : Z78[26:16];
        Z81_final <= Z81[15] ? Z81[26:16] + 1 : Z81[26:16];
        Z82_final <= Z82[15] ? Z82[26:16] + 1 : Z82[26:16];
        Z83_final <= Z83[15] ? Z83[26:16] + 1 : Z83[26:16];
        Z84_final <= Z84[15] ? Z84[26:16] + 1 : Z84[26:16];
        Z85_final <= Z85[15] ? Z85[26:16] + 1 : Z85[26:16];
        Z86_final <= Z86[15] ? Z86[26:16] + 1 : Z86[26:16];
        Z87_final <= Z87[15] ? Z87[26:16] + 1 : Z87[26:16];
        Z88_final <= Z88[15] ? Z88[26:16] + 1 : Z88[26:16];
    end
end

endmodule
