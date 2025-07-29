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

  logic clk, rst, enable;
  logic signed [10:0] Z [0:7][0:7];
  logic signed [10:0] Q [0:7][0:7];
  logic out_enable;

  y_quantizer dut (
    .clk(clk),
    .rst(rst),
    .enable(enable),
    .Z(Z),
    .Q(Q),
    .out_enable(out_enable)
  );

  always #5 clk = ~clk;

  logic signed [10:0] test_input [0:7][0:7];
  logic signed [10:0] expected_output [0:7][0:7];

  // Reusable task: Apply Z and expected_output to DUT
  task automatic run_test(string test_name);
    begin
      $display("\n=== Running Test: %s ===", test_name);

      // Reset
      rst = 1; enable = 0;
      #10;
      rst = 0;
      #10;

      // Apply test input to DUT
      for (int i = 0; i < 8; i++)
        for (int j = 0; j < 8; j++)
          Z[i][j] = test_input[i][j];

      // Enable signal (1-cycle pulse)
      enable = 1;
      #10;
      enable = 0;

      // Wait for pipeline to finish
      wait (out_enable == 1);
      #10;

      // Check results
      check_results();
    end
  endtask

  // Generate expected output: Q = (Z * 4096) >>> 12
  task automatic compute_expected_output;
    for (int i = 0; i < 8; i++)
      for (int j = 0; j < 8; j++)
        expected_output[i][j] = (test_input[i][j] * 4096) >>> 12;
  endtask

  // Compare DUT output vs expected
  task automatic check_results;
    int errors = 0;
    for (int i = 0; i < 8; i++) begin
      for (int j = 0; j < 8; j++) begin
        if (Q[i][j] !== expected_output[i][j]) begin
          $display("Mismatch at [%0d][%0d]: Expected %0d, Got %0d", i, j, expected_output[i][j], Q[i][j]);
          errors++;
        end else begin
          $display("Match at [%0d][%0d]: %0d", i, j, Q[i][j]);
        end
      end
    end
    if (errors == 0)
      $display("Test Passed!");
    else
      $display("Test Failed with %0d mismatches", errors);
  endtask

 
  // Main testbench sequence
  initial begin
    clk = 0;

    // Test 1: Ramp pattern (0 to 63)
    for (int i = 0; i < 8; i++)
      for (int j = 0; j < 8; j++)
        test_input[i][j] = i * 8 + j;
    compute_expected_output();
    run_test("Ramp Pattern");

    // Test 2: All Zeros
    for (int i = 0; i < 8; i++)
      for (int j = 0; j < 8; j++)
        test_input[i][j] = 0;
    compute_expected_output();
    run_test("All Zeros");

    // Test 3: All Maximum (+1023)
    for (int i = 0; i < 8; i++)
      for (int j = 0; j < 8; j++)
        test_input[i][j] = 11'sd1023;
    compute_expected_output();
    run_test("All Maximum");

    // Test 4: All Minimum (-1024)
    for (int i = 0; i < 8; i++)
      for (int j = 0; j < 8; j++)
        test_input[i][j] = -11'sd1024;
    compute_expected_output();
    run_test("All Minimum");

      // Test 5: Checkerboard (expected output should be +1023 and -1024)
    for (int i = 0; i < 8; i++)
      for (int j = 0; j < 8; j++)
        test_input[i][j] = ((i + j) % 2 == 0) ? 11'sd1023 : -11'sd1024;
    compute_expected_output();
    run_test("Checkerboard Pattern");

    $finish;
  end

endmodule
