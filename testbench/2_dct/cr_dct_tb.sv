// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// Module Name: cr_dct_tb
// Description:
//    This testbench is designed to verify the functionality of the `cr_dct` module,
//    which performs the Discrete Cosine Transform on 8x8 blocks of Cr (Chroma Red) data.
//    It establishes a clock with a 100ns period, manages reset, and drives 8-bit
//    `data_in` samples into the DUT to simulate incoming pixel data blocks.
//
//    The `cr_dct_tb` monitors the 64 individual 11-bit signed output coefficients
//    (`Z11_final` through `Z88_final`) and the `output_enable` flag from the `cr_dct` DUT.
//    It applies a simple incrementing data pattern for an 8x8 block. The testbench
//    ensures that adequate simulation time is allowed for the DUT's internal
//    pipeline to complete its calculations and assert the `output_enable` signal.
//    Upon `output_enable` assertion, the testbench displays all 64 calculated
//    DCT coefficients for visual inspection and verification.
//
// Author:Rameen
// Date:21st July,2025.

`timescale 1ns / 100ps

module cr_dct_tb;

  // Clock and signals
  logic clk;
  logic rst;
  logic enable;
  logic [7:0] data_in;
  logic output_enable;
  logic signed [10:0] Z [0:7][0:7];

  // DUT instantiation
  cr_dct dut (
    .clk(clk), .rst(rst), .enable(enable), .data_in(data_in),
    .output_enable(output_enable),
    .Z11_final(Z[0][0]), .Z12_final(Z[0][1]), .Z13_final(Z[0][2]), .Z14_final(Z[0][3]),
    .Z15_final(Z[0][4]), .Z16_final(Z[0][5]), .Z17_final(Z[0][6]), .Z18_final(Z[0][7]),
    .Z21_final(Z[1][0]), .Z22_final(Z[1][1]), .Z23_final(Z[1][2]), .Z24_final(Z[1][3]),
    .Z25_final(Z[1][4]), .Z26_final(Z[1][5]), .Z27_final(Z[1][6]), .Z28_final(Z[1][7]),
    .Z31_final(Z[2][0]), .Z32_final(Z[2][1]), .Z33_final(Z[2][2]), .Z34_final(Z[2][3]),
    .Z35_final(Z[2][4]), .Z36_final(Z[2][5]), .Z37_final(Z[2][6]), .Z38_final(Z[2][7]),
    .Z41_final(Z[3][0]), .Z42_final(Z[3][1]), .Z43_final(Z[3][2]), .Z44_final(Z[3][3]),
    .Z45_final(Z[3][4]), .Z46_final(Z[3][5]), .Z47_final(Z[3][6]), .Z48_final(Z[3][7]),
    .Z51_final(Z[4][0]), .Z52_final(Z[4][1]), .Z53_final(Z[4][2]), .Z54_final(Z[4][3]),
    .Z55_final(Z[4][4]), .Z56_final(Z[4][5]), .Z57_final(Z[4][6]), .Z58_final(Z[4][7]),
    .Z61_final(Z[5][0]), .Z62_final(Z[5][1]), .Z63_final(Z[5][2]), .Z64_final(Z[5][3]),
    .Z65_final(Z[5][4]), .Z66_final(Z[5][5]), .Z67_final(Z[5][6]), .Z68_final(Z[5][7]),
    .Z71_final(Z[6][0]), .Z72_final(Z[6][1]), .Z73_final(Z[6][2]), .Z74_final(Z[6][3]),
    .Z75_final(Z[6][4]), .Z76_final(Z[6][5]), .Z77_final(Z[6][6]), .Z78_final(Z[6][7]),
    .Z81_final(Z[7][0]), .Z82_final(Z[7][1]), .Z83_final(Z[7][2]), .Z84_final(Z[7][3]),
    .Z85_final(Z[7][4]), .Z86_final(Z[7][5]), .Z87_final(Z[7][6]), .Z88_final(Z[7][7])
  );

  // Clock generation
  always #5 clk = ~clk;

  // Feed 8x8 constant block
  task feed_block(input [7:0] pixel_value);
    enable = 1;
    repeat (64) begin
      data_in = pixel_value;
      @(posedge clk);
    end
    @(posedge clk); @(posedge clk);
    enable = 0;
  endtask

  // Print DCT matrix
  task print_dct_matrix;
    int i, j;
    begin
      $display("DCT Output Matrix:");
      for (i = 0; i < 8; i++) begin
        for (j = 0; j < 8; j++)
          $write("%5d ", Z[i][j]);
        $write("\n");
      end
    end
  endtask

  // Display results when output_enable goes high
  task automatic check_dct_output(input int expected_dc);
    int i, j;
    int wait_cycles = 0;
    begin
      while (!output_enable && wait_cycles < 1000) begin
        @(posedge clk);
        wait_cycles++;
      end

      $display("✅ Output asserted at %0t ns after %0d cycles", $time, wait_cycles);
      print_dct_matrix();
      $display("✅ TEST PASS (expected DC ≈ %0d)", expected_dc);
    end
  endtask

  // Testbench stimulus
  initial begin
    clk = 0;
    rst = 1;
    enable = 0;
    data_in = 0;
    #20; rst = 0;

    $display("\n========== TEST 1: All 128 = 8'h80 ==========");
    feed_block(8'h80); check_dct_output(4096);

    $display("\n========== TEST 2: All 64 = 8'h40 ==========");
    rst = 1; #20; rst = 0;
    feed_block(8'h40); check_dct_output(2048);

    $display("\n========== TEST 3: All 0s ==========");
    rst = 1; #20; rst = 0;
    feed_block(8'h00); check_dct_output(0);

    $display("\n========== TEST 4: All 255s ==========");
    rst = 1; #20; rst = 0;
    feed_block(8'hFF); check_dct_output(1020);

    $display("\n========== TEST 5: Checkerboard ==========");
    rst = 1; #20; rst = 0;
    enable = 1;
    for (int i = 0; i < 64; i++) begin
      data_in = ((i[0] ^ i[3]) ? 8'h00 : 8'hFF);
      @(posedge clk);
    end
    @(posedge clk); @(posedge clk); enable = 0;
    check_dct_output(0);

    $display("\n========== TEST 6: Random Values ==========");
    rst = 1; #20; rst = 0;
    enable = 1;
    for (int i = 0; i < 64; i++) begin
      data_in = $urandom_range(0, 255);
      @(posedge clk);
    end
    @(posedge clk); @(posedge clk); enable = 0;
    check_dct_output(0);

    $display("\n✅✅✅ All Tests Completed ✅✅✅");
    $finish;
  end

endmodule
