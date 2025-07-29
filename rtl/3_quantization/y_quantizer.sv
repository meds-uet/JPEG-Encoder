// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// Description:
//   This module performs quantization on an 8x8 block of luminance (Y) values
//   after 2D Discrete Cosine Transform (DCT). Quantization reduces the precision
//   of DCT coefficients, enabling lossy compression for JPEG encoding.
//   Instead of dividing each DCT coefficient by the corresponding value in a 
//   quantization matrix (Q), this module precomputes reciprocals scaled by 4096,
//   and performs multiplication followed by right-shift to approximate division.
//
// Author:Navaal Noshi
// Date:11th July,2025.

`timescale 1ns / 100ps

module y_quantizer (
    input  logic clk, rst, enable,
    input  logic signed [10:0] Z [0:7][0:7],
    output logic signed [10:0] Q [0:7][0:7],
    output logic out_enable
);

    // Q_MATRIX is constant with all 1s (for the testing purpose )
    localparam int Q_MATRIX [0:7][0:7] = '{default: 1};

    // QQ_MATRIX will store 4096 / Q_MATRIX[i][j], computed on reset
    logic [15:0] QQ_MATRIX [0:7][0:7];

    // Internal signals
    logic signed [31:0] Z_ext   [0:7][0:7];
    logic signed [22:0] Z_temp  [0:7][0:7];
    logic signed [22:0] Z_temp1 [0:7][0:7];
    logic [2:0] enable_pipe;

    // Compute QQ_MATRIX = 4096 / Q_MATRIX[i][j]
    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < 8; i++) begin
                for (int j = 0; j < 8; j++) begin
                    QQ_MATRIX[i][j] <= 4096 / Q_MATRIX[i][j];  // 4096 / 1 = 4096
                end
            end
        end
    end

    // Stage 1: Sign extension
    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < 8; i++) for (int j = 0; j < 8; j++)
                Z_ext[i][j] <= 0;
        end else if (enable) begin
            for (int i = 0; i < 8; i++) for (int j = 0; j < 8; j++)
                Z_ext[i][j] <= {{21{Z[i][j][10]}}, Z[i][j]};
        end
    end

    // Stage 2: Multiply with QQ_MATRIX
    always_ff @(posedge clk) begin
        if (rst)
            for (int i = 0; i < 8; i++) for (int j = 0; j < 8; j++)
                Z_temp[i][j] <= 0;
        else if (enable_pipe[0])
            for (int i = 0; i < 8; i++) for (int j = 0; j < 8; j++)
                Z_temp[i][j] <= Z_ext[i][j] * QQ_MATRIX[i][j];
    end

    // Stage 3: Pipeline buffer
    always_ff @(posedge clk) begin
        if (rst)
            Z_temp1 <= '{default: 0};
        else if (enable_pipe[1])
            Z_temp1 <= Z_temp;
    end

    // Stage 4: Rounding and output
    always_ff @(posedge clk) begin
        if (rst)
            Q <= '{default: 0};
        else if (enable_pipe[2])
            for (int i = 0; i < 8; i++) for (int j = 0; j < 8; j++)
                Q[i][j] <= Z_temp1[i][j][11] ? Z_temp1[i][j][22:12] + 1 : Z_temp1[i][j][22:12];
    end

    // Enable pipeline shift register
    always_ff @(posedge clk) begin
        if (rst) begin
            enable_pipe <= 3'b000;
            out_enable <= 0;
        end else begin
            enable_pipe <= {enable_pipe[1:0], enable};
            out_enable <= enable_pipe[2];
        end
    end

endmodule
