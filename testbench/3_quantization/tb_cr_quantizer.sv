// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// Module Name: tb_cr_quantizer
//
// Description:
//    This testbench verifies the functionality of the `cr_quantizer` module,
//    which performs quantization on 8x8 blocks of DCT coefficients for the Cr
//    (chrominance-red) component of a JPEG image. It applies reset, feeds test
//    patterns, and compares output with expected values calculated using the
//    standard JPEG chroma quantization matrix and fixed-point math.
//
// Author: Navaal Noshi
// Date: 29th July, 2025

`timescale 1ns / 100ps
`include "quantizer_constants.sv"

module tb_cr_quantizer;

  import QUANTIZER_constants::*;

  logic clk, rst, enable;
  logic signed [10:0] Z [0:7][0:7];
  logic signed [10:0] Q [0:7][0:7];
  logic out_enable;

  // Instantiate DUT
  cr_quantizer dut (
    .clk(clk),
    .rst(rst),
    .enable(enable),
    .Z(Z),
    .Q(Q),
    .out_enable(out_enable)
  );

  // Clock generation
  always #5 clk = ~clk;

  logic signed [10:0] test_input [0:7][0:7];
  logic signed [10:0] expected_output [0:7][0:7];

  // Compute expected output using (Z * 4096 / Q[i][j]) >> 12 with rounding
  task automatic compute_expected_output;
    for (int i = 0; i < 8; i++) begin
      for (int j = 0; j < 8; j++) begin
        int qq = 4096 / Q_CHROMA[i][j];
        int temp = test_input[i][j] * qq;
        expected_output[i][j] = (temp[11]) ? (temp >>> 12) + 1 : (temp >>> 12);
      end
    end
  endtask

  // Print input, expected, and output matrices
  task automatic print_all_matrices;
    $display("\n%-70s %-70s %-150s", "Input Matrix (Z)", "Expected Output", "Actual Output (Q)");
    $display("---------------------------------------------------------------------------------------------------------------------------------------------------------------------------");
    for (int i = 0; i < 8; i++) begin
      for (int j = 0; j < 8; j++) $write("%6d ", test_input[i][j]);
      $write("   ");
      for (int j = 0; j < 8; j++) $write("%6d ", expected_output[i][j]);
      $write("   ");
      for (int j = 0; j < 8; j++) $write("%6d ", Q[i][j]);
      $write("\n");
    end
  endtask

  task automatic run_test(string testname);
    $display("\n===============================");
    $display(" Running Test: %s", testname);
    $display("===============================\n");

    rst = 1; enable = 0; #10;
    rst = 0; #10;

    for (int i = 0; i < 8; i++)
      for (int j = 0; j < 8; j++)
        Z[i][j] = test_input[i][j];

    enable = 1; #10;
    enable = 0;

    wait (out_enable); #10;

    print_all_matrices();
  endtask

  initial begin
    clk = 0;

    // Test 1: All 1023
    for (int i = 0; i < 8; i++)
      for (int j = 0; j < 8; j++)
        test_input[i][j] = 11'sd1023;

    compute_expected_output();
    run_test("All 1023 Values");

    // Test 2: Ramp
    for (int i = 0; i < 8; i++)
      for (int j = 0; j < 8; j++)
        test_input[i][j] = i * 8 + j;

    compute_expected_output();
    run_test("Ramp Pattern");

    // Test 3: Alternating +1023/-1024
    for (int i = 0; i < 8; i++)
      for (int j = 0; j < 8; j++)
        test_input[i][j] = ((i + j) % 2 == 0) ? 1023 : -1024;

    compute_expected_output();
    run_test("Checkerboard Pattern");

    $finish;
  end
endmodule
