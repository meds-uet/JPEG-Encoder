// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// Module Name: tb_cb_quantizer
// Description:
//    This testbench is designed to verify the functionality of the `cb_quantizer` module,
//    which performs quantization on 8x8 blocks of Discrete Cosine Transform (DCT)
//    coefficients for the Cb (Chroma Blue) component. The DUT expects 11-bit signed input
//    DCT coefficients (`Z`) and outputs 11-bit signed quantized coefficients (`Q`).
//
//    The testbench generates a clock signal and applies a reset sequence to the DUT. It
//    then populates the `Z` input array with a custom test pattern: increasing large
//    values for elements above the secondary diagonal, a constant value (50) on the
//    secondary diagonal, and small varying values (-1, 0, or 1) for elements below it.
//    After providing this input matrix and asserting the `enable` signal, the testbench
//    waits for the `out_enable` signal from the DUT, which indicates the completion
//    of the quantization process. Finally, it displays the entire 8x8 `Q` (quantized)
//    output matrix for visual inspection and verification.
//
// Author:Navaal Noshi
// Date:21st July,2025.

`timescale 1ns / 1ps

module tb_cb_quantizer;

    logic clk = 0;
    logic rst;
    logic enable;
    logic signed [10:0] Z[0:7][0:7];
    logic signed [10:0] Q[0:7][0:7];
    logic out_enable;

    // Instantiate the DUT
    cb_quantizer dut (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .Z(Z),
        .Q(Q),
        .out_enable(out_enable)
    );

    // Clock generation
    always #5 clk = ~clk;

    integer i, j;
    integer hi;

    initial begin
        $display("=== Test: cb_quantizer — Opposite of secondary diagonal ===");

        rst = 1;
        enable = 0;
        #12; rst = 0; #10;

        hi = 200;
        // Fill matrix: upper triangle = large, diagonal = 50, lower = small
        for (i = 0; i < 8; i = i + 1) begin
            for (j = 0; j < 8; j = j + 1) begin
                if (i + j < 7)
                    Z[i][j] = hi++;
                else if (i + j == 7)
                    Z[i][j] = 50;
                else
                    Z[i][j] = ((i + j) % 3) - 1; // small values: -1, 0, 1
            end
        end

        enable = 1;
        #10;
        enable = 0;

        wait (out_enable);
        #10;

        $display("Quantized Output:");
        for (i = 0; i < 8; i = i + 1) begin
            for (j = 0; j < 8; j = j + 1)
                $write("%0d ", Q[i][j]);
            $write("\n");
        end

        #10 $finish;
    end

endmodule
