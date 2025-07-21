// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// Description:
//   typically obtained after applying a 2D Discrete Cosine Transform (DCT).
//   It replaces division with multiplication using precomputed scale factors
//   (4096 / Q[i][j]), followed by a right shift of 12 bits (i.e., division by 4096).
//
// Author:Navaal Noshi
// Date:11th July,2025.
`timescale 1ns / 100ps

module cr_quantizer #(
    parameter int Q_MATRIX[8][8] = '{default: 1}
)(
    input  logic clk,
    input  logic rst,
    input  logic enable,
    input  logic signed [10:0] Z[8][8],     // Input Cr DCT coefficients
    output logic signed [10:0] Q[8][8],     // Output quantized Cr coefficients
    output logic out_enable
);

    // Internal pipeline registers
    logic signed [31:0] Z_stage1[8][8];
    logic signed [31:0] Z_stage2[8][8];
    logic signed [31:0] Z_stage3[8][8];

    // Precomputed reciprocal values (scaled by 4096)
    logic [15:0] QQ[8][8];
    initial begin
        for (int i = 0; i < 8; i++)
            for (int j = 0; j < 8; j++)
                QQ[i][j] = 4096 / Q_MATRIX[i][j];
    end

    // Pipeline enable shift register
    logic [3:0] enable_shift;
    assign out_enable = enable_shift[3];

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            enable_shift <= 4'd0;
        else
            enable_shift <= {enable_shift[2:0], enable};
    end

    // Stage 1: Sign-extend inputs
    always_ff @(posedge clk) begin
        for (int i = 0; i < 8; i++)
            for (int j = 0; j < 8; j++)
                Z_stage1[i][j] <= {{21{Z[i][j][10]}}, Z[i][j]};
    end

    // Stage 2: Multiply with precomputed 4096/Q
    always_ff @(posedge clk) begin
        for (int i = 0; i < 8; i++)
            for (int j = 0; j < 8; j++)
                Z_stage2[i][j] <= Z_stage1[i][j] * QQ[i][j];
    end

    // Stage 3: Round and shift result
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
