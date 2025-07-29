// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// Module Name: tb_y_quantizer
//
// Description:
//    This testbench verifies the functionality of the `y_quantizer` module,
//    which performs quantization on 8x8 blocks of DCT (Discrete Cosine Transform)
//    coefficients corresponding to the y  component of a JPEG image. The testbench generates a clock, 
//    applies reset, and feeds various test patterns into the input matrix `Z`, including maximum values,
//    ramp sequences, and checkerboard alternating patterns.
//    It computes the expected quantized output using the same quantization matrix
//    as the `y_quantizer` module (standard JPEG chroma Q matrix) and a fixed-point
//    approximation: multiplying by (4096 / Q[i][j]) and right-shifting by 12,
//    with rounding.
//
//    After waiting for the pipeline to complete (signaled by `out_enable`),
//    the testbench prints the input, expected, and actual output matrices
//    side-by-side in a horizontal format for easy visual verification.
//
// Author: Navaal Noshi
// Date: 24th July, 2025

`timescale 1ns / 100ps
`include "quantizer_constants.svh"

module tb_y_quantizer;

  logic clk, rst, enable;
  logic signed [10:0] Z [0:7][0:7];
  logic signed [10:0] Q [0:7][0:7];
  logic out_enable;

  // Instantiate DUT
  y_quantizer dut (
    .clk(clk),
    .rst(rst),
    .enable(enable),
    .Z(Z),
    .Q(Q),
    .out_enable(out_enable)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Test data and reference matrices
  logic signed [10:0] test_input [0:7][0:7];
  logic signed [10:0] expected_output [0:7][0:7];

  // Compute expected output using (Z * 4096 / Q[i][j]) >> 12 with rounding
  task automatic compute_expected_output;
    for (int i = 0; i < 8; i++) begin
      for (int j = 0; j < 8; j++) begin
        int qq = 4096 / Q_MATRIX[i][j];
        int temp = test_input[i][j] * qq;
        expected_output[i][j] = (temp[11]) ? (temp >>> 12) + 1 : (temp >>> 12);
      end
    end
  endtask

  // Horizontally print Z, expected_output, and Q
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

  // Single test
  task automatic run_test(string testname);
    $display("\n===============================");
    $display(" Running Test: %s", testname);
    $display("===============================\n");

    // Reset
    rst = 1; enable = 0; #10;
    rst = 0; #10;

    // Apply input
    for (int i = 0; i < 8; i++)
      for (int j = 0; j < 8; j++)
        Z[i][j] = test_input[i][j];

    // Enable pulse
    enable = 1; #10;
    enable = 0;

    // Wait for pipeline
    wait (out_enable); #10;

    print_all_matrices();
  endtask

  // Main
  initial begin
    clk = 0;

    // Test: All 1023
    for (int i = 0; i < 8; i++)
      for (int j = 0; j < 8; j++)
        test_input[i][j] = 11'sd1023;

    compute_expected_output();
    run_test("All 1023 Values");

    // Test: Ramp
    for (int i = 0; i < 8; i++)
      for (int j = 0; j < 8; j++)
        test_input[i][j] = i * 8 + j;

    compute_expected_output();
    run_test("Ramp Pattern");

    // Test: Alternating +1023/-1024
    for (int i = 0; i < 8; i++)
      for (int j = 0; j < 8; j++)
        test_input[i][j] = ((i + j) % 2 == 0) ? 1023 : -1024;

    compute_expected_output();
    run_test("Checkerboard Pattern");

    // Test: Random Values
    for (int i = 0; i < 8; i++)
      for (int j = 0; j < 8; j++)
        test_input[i][j] = $urandom_range(-1024, 1023);

    compute_expected_output();
    run_test("Random Values");
    
    $finish;
  end
endmodule
