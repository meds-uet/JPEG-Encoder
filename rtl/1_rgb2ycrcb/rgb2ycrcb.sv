// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// Description:
//   This module converts 8-bit RGB (Red, Green, Blue) pixel data into 8-bit
//   YCbCr format.The transformation uses a fixed-point approximation of the standard ITU-R
//   BT.601 matrix, with scaling by 2^13 to avoid floating point arithmetic.
//   A 2-stage pipeline performs the following:
//     - Stage 1: Multiplication of RGB with fixed-point coefficients
//     - Stage 2: Rounding and clamping to [0, 255]
//   Outputs are registered and synchronized using delayed enable signals.
//
// Author:Navaal Noshi
// Date:12th July,2025.

`timescale 1ns / 1ps

module rgb2ycrcb (
    input  logic        clk,
    input  logic        rst,
    input  logic        enable,
    input  logic [23:0] data_in,     // {B[23:16], G[15:8], R[7:0]}
    output logic [23:0] data_out,    // {Cr[23:16], Cb[15:8], Y[7:0]}
    output logic        enable_out
);

    // Fixed-point coefficients scaled by 2^14 = 16384
    localparam logic [14:0] Y1  = 15'd9798;   // 0.299  * 16384
    localparam logic [14:0] Y2  = 15'd19235;  // 0.587  * 16384
    localparam logic [14:0] Y3  = 15'd3730;   // 0.114  * 16384

    localparam logic [14:0] CB1 = 15'd5530;   // 0.1687 * 16384
    localparam logic [14:0] CB2 = 15'd10857;  // 0.3313 * 16384
    localparam logic [14:0] CB3 = 15'd16384;  // 0.5000 * 16384

    localparam logic [14:0] CR1 = 15'd16384;  // 0.5000 * 16384
    localparam logic [14:0] CR2 = 15'd13620;  // 0.4187 * 16384
    localparam logic [14:0] CR3 = 15'd2659;   // 0.0813 * 16384

    // Cb/Cr offset: 128 * 16384
    localparam logic [22:0] OFFSET = 23'd2097152;

    // Internal signals
    logic [7:0] R, G, B;

    logic [22:0] y_r, y_g, y_b, y_sum;
    logic [22:0] cb_r, cb_g, cb_b, cb_sum;
    logic [22:0] cr_r, cr_g, cr_b, cr_sum;

    logic [7:0] y_rounded, cb_rounded, cr_rounded;
    logic [7:0] y_out, cb_out, cr_out;

    logic enable_d1, enable_d2;

    assign data_out = {cr_out, cb_out, y_out};


    // Stage 1: Latch RGB inputs
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            R <= 0; G <= 0; B <= 0;
        end else if (enable) begin
            R <= data_in[7:0];
            G <= data_in[15:8];
            B <= data_in[23:16];
        end
    end

    
    // Stage 2: Multiply and Accumulate
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            y_sum  <= 0;
            cb_sum <= 0;
            cr_sum <= 0;
        end else if (enable_d1) begin
            // Y
            y_r = Y1 * R;
            y_g = Y2 * G;
            y_b = Y3 * B;
            y_sum = y_r + y_g + y_b;

            // Cb
            cb_r = CB1 * R;
            cb_g = CB2 * G;
            cb_b = CB3 * B;
            cb_sum = OFFSET - cb_r - cb_g + cb_b;

            // Cr
            cr_r = CR1 * R;
            cr_g = CR2 * G;
            cr_b = CR3 * B;
            cr_sum = OFFSET + cr_r - cr_g - cr_b;
        end
    end

 
    // Stage 3: Round and Clamp
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            y_out  <= 0;
            cb_out <= 0;
            cr_out <= 0;
        end else if (enable_d2) begin
            // Round (based on bit 14) and shift
            y_rounded  = y_sum[22:15]  + y_sum[14];
            cb_rounded = cb_sum[22:15] + cb_sum[14];
            cr_rounded = cr_sum[22:15] + cr_sum[14];

            // Clamp
            y_out  <= (y_rounded  > 8'd255) ? 8'd255 : y_rounded;
            cb_out <= (cb_rounded > 8'd255) ? 8'd255 : cb_rounded;
            cr_out <= (cr_rounded > 8'd255) ? 8'd255 : cr_rounded;
        end
    end

    // Enable pipeline alignment
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            enable_d1 <= 0;
            enable_d2 <= 0;
            enable_out <= 0;
        end else begin
            enable_d1  <= enable;
            enable_d2  <= enable_d1;
            enable_out <= enable_d2;
        end
    end

endmodule
