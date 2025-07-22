// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// Module Name: tb_cr_quantizer
// Description:
//    This testbench is designed to verify the functionality of the `cr_quantizer` module,
//    which performs quantization on 8x8 blocks of Discrete Cosine Transform (DCT)
//    coefficients for the Cr (Chroma Red) component. The DUT expects 11-bit signed input
//    DCT coefficients (`Z`) and outputs 11-bit signed quantized coefficients (`Q`).
//
//    The testbench establishes a clock and applies a reset sequence to the DUT. It uses
//    a parameterized quantization matrix (set to all 1s in this testbench for simplified
//    verification, implying Q[i][j] will be equal to Z[i][j]). The `Z` input matrix
//    is populated with a custom test pattern: increasing large values for elements above
//    the secondary diagonal, a constant value on the secondary diagonal, and small
//    varying values below it. After providing input and asserting `enable`, the testbench
//    waits for the `out_enable` signal from the DUT, indicating completion of the
//    quantization process. Finally, it displays the entire 8x8 `Q` (quantized) output
//    matrix for visual inspection.
//
// Author:Navaal Noshi
// Date:21st July,2025.

`timescale 1ns / 100ps

module tb_cr_quantizer;

    logic clk = 0;
    logic rst;
    logic enable;
    logic signed [10:0] Z[8][8];
    logic signed [10:0] Q[8][8];
    logic out_enable;

    // Use quantization matrix of all 1s (4096/Q = 4096)
    localparam int Q_MATRIX[8][8] = '{default: 1};

    // Instantiate the DUT
    cr_quantizer #(.Q_MATRIX(Q_MATRIX)) dut (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .Z(Z),
        .Q(Q),
        .out_enable(out_enable)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin : testbench
        integer i, j, hi;

        $display("=== Test: cr_quantizer — Opposite of secondary diagonal ===");

        rst = 1;
        enable = 0;
        #12; rst = 0; #10;

        // Initialize input matrix: upper half = large, diagonal = 50, lower = small
        hi = 200;
        for (i = 0; i < 8; i++) begin
            for (j = 0; j < 8; j++) begin
                if (i + j < 7)
                    Z[i][j] = hi++;
                else if (i + j == 7)
                    Z[i][j] = 50;
                else
                    Z[i][j] = (i + j) % 3 - 1; // -1, 0, 1 pattern
            end
        end

        enable = 1; #10;
        enable = 0;

        wait(out_enable);
        #10;

        $display("Quantized Output:");
        for (i = 0; i < 8; i++) begin
            for (j = 0; j < 8; j++)
                $write("%0d ", Q[i][j]);
            $write("\n");
        end

        #10 $finish;
    end

endmodule
