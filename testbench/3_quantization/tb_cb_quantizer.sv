// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// Description:     
//   This SystemVerilog testbench is designed to verify the functionality of the cb_quantizer module, which
//   performs quantization on an 8×8 block of Cb (Chrominance-Blue) DCT coefficients as part of the JPEG
//   encoding pipeline. It generates a structured test pattern to evaluate the quantizer’s performance across
//   varying frequency components.
//
// Author:Navaal Noshi
// Date:16th July,2025.

`timescale 1ns / 100ps

module tb_cb_dct;

    logic clk, rst, enable;
    logic [7:0] data_in;
    logic [10:0] Z_final [1:8][1:8];
    logic output_enable;

    // Instantiate DUT
    cb_dct dut (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .data_in(data_in),
        .Z_final(Z_final),
        .output_enable(output_enable)
    );

    // Clock Generation
    always #5 clk = ~clk;

    // Input stimulus
    logic [7:0] test_data [0:63];

    initial begin
        clk = 0;
        rst = 1;
        enable = 0;
        data_in = 0;

        // Fill test data with a simple gradient
        for (int i = 0; i < 64; i++) begin
            test_data[i] = i;
        end

        // Release reset
        #20;
        rst = 0;

        // Feed pixel data (8x8 block, serially)
        for (int i = 0; i < 64; i++) begin
            @(negedge clk);
            enable = 1;
            data_in = test_data[i];
        end

        // Stop feeding input
        @(negedge clk);
        enable = 0;

        // Wait for output_enable
        wait (output_enable == 1'b1);
        @(posedge clk);

        $display("\n---- Cb DCT Output Matrix ----");
        for (int i = 1; i <= 8; i++) begin
            for (int j = 1; j <= 8; j++) begin
                $write("%0d ", Z_final[i][j]);
            end
            $display();
        end

        $finish;
    end

endmodule
