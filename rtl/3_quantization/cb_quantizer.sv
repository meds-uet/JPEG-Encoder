// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0
// SPDX-License-Identifier: Apache-2.0
//
// Description:
//   This module performs quantization on an 8x8 block of chrominance (Cb) values
//   after 2D DCT. It replaces division with multiplication by 4096/Q[i][j]
//   followed by a right-shift for rounding.
//
// Author:Navaal Noshi
// Date: 16th July, 2025

`timescale 1ns / 1ps

module cb_quantizer #(
    parameter int Q_MATRIX[0:7][0:7] = '{default: 1}
)(
    input  logic clk,
    input  logic rst,
    input  logic enable,
    input  logic signed [10:0] Z[0:7][0:7],   // Input DCT coefficients
    output logic signed [10:0] Q[0:7][0:7],   // Quantized output
    output logic out_enable                   // Output enable signal
);

    logic signed [31:0] Z_stage1[8][8];
    logic signed [31:0] Z_stage2[8][8];
    logic signed [31:0] Z_stage3[8][8];

    logic [15:0] QQ[8][8];           // Reciprocal quantization factors
    logic [3:0] enable_shift;        // Pipeline control shift register

    assign out_enable = enable_shift[3];

    // Stage 0: Initialize quantization multipliers
    initial begin
        for (int i = 0; i < 8; i++)
            for (int j = 0; j < 8; j++)
                QQ[i][j] = 4096 / Q_MATRIX[i][j];
    end

    // Pipeline enable shift register
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            enable_shift <= 0;
        else
            enable_shift <= {enable_shift[2:0], enable};
    end

    // Stage 1: Sign extension of input DCT coefficients
    always_ff @(posedge clk) begin
        for (int i = 0; i < 8; i++)
            for (int j = 0; j < 8; j++)
                Z_stage1[i][j] <= {{21{Z[i][j][10]}}, Z[i][j]};
    end

    // Stage 2: Multiply by reciprocal quantization factor
    always_ff @(posedge clk) begin
        for (int i = 0; i < 8; i++)
            for (int j = 0; j < 8; j++)
                Z_stage2[i][j] <= Z_stage1[i][j] * QQ[i][j];
    end

    // Stage 3: Rounding and shift
    always_ff @(posedge clk) begin
        for (int i = 0; i < 8; i++) begin
            for (int j = 0; j < 8; j++) begin
                Z_stage3[i][j] <= Z_stage2[i][j];
                Q[i][j] <= Z_stage2[i][j][11] ?
                           (Z_stage2[i][j] >>> 12) + 1 :
                           (Z_stage2[i][j] >>> 12);
            end
        end
    end

endmodule
