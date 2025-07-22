// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// Module Name: tb_y_quantizer
// Description:
//    This testbench is designed to verify the functionality of the `y_quantizer` module,
//    which performs quantization on 8x8 blocks of Discrete Cosine Transform (DCT)
//    coefficients for the Y (Luma) component. The DUT expects 11-bit signed input
//    DCT coefficients (`Z`) and outputs 11-bit signed quantized coefficients (`Q`).
//
//    The testbench generates a clock signal and applies reset to the DUT. It then
//    populates the `Z` input array with a custom pattern: large increasing values
//    above the secondary diagonal, a constant value on the secondary diagonal,
//    and small varying values below it. After providing the input `Z` matrix
//    and asserting `enable`, the testbench waits for the `out_enable` signal
//    from the DUT to confirm that the quantization process is complete.
//    Finally, it displays the entire 8x8 `Q` (quantized) output matrix for visual
//    inspection and verification of the quantization operation.
//
// Author:Navaal Noshi
// Date:20th July,2025.

`timescale 1ns / 100ps

module tb_y_quantizer;

    logic clk = 0;
    logic rst;
    logic enable;
    logic signed [10:0] Z[0:7][0:7];
    logic signed [10:0] Q[0:7][0:7];
    logic out_enable;

    y_quantizer dut (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .Z(Z),
        .Q(Q),
        .out_enable(out_enable)
    );

    // Clock generator
    always #5 clk = ~clk;

    initial begin
        int i, j;       // loop counters
        int hi;         // high-value initializer

        $display("Test: Opposite of secondary diagonal — top = large, bottom = small");

        rst = 1;
        enable = 0;
        #12; rst = 0; #10;

        hi = 100;
        for (i = 0; i < 8; i++) begin
            for (j = 0; j < 8; j++) begin
                if (i + j < 7)
                    Z[i][j] = hi++;             // large values
                else if (i + j == 7)
                    Z[i][j] = 50;               // diagonal value
                else
                    Z[i][j] = (i + j) % 3 - 1;   // small: -1, 0, 1
            end
        end

        enable = 1;
        #10;
        enable = 0;

        wait (out_enable);
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
