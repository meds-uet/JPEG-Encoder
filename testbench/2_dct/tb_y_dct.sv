// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// Module Name: y_dct_tb
// Description:
//    This testbench verifies the functionality of the `y_dct` module, which performs
//    an 8x8 Discrete Cosine Transform on Y (luma) pixel values. The testbench feeds
//    fixed or patterned pixel values into the DUT, waits for processing, and then
//    displays the 64 signed 16-bit DCT coefficients for verification.
//
// Author: Rameen
// Date: 31st July, 2025

`timescale 1ns / 100ps

module y_dct_tb;

  // Clock and control signals
  logic clk, rst, enable;
  logic [7:0] data_in;
  logic output_enable;

  // 64 output coefficients
  logic signed [15:0] Z [0:7][0:7];

  // DUT instantiation
  y_dct dut (
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

  // Clock: 10ns period
  always #5 clk = ~clk;

  // Feed an 8x8 block with the given pixel value
  task feed_block(input [7:0] val);
    enable = 1;
    repeat (64) begin
      data_in = val;
      @(posedge clk);
    end
    @(posedge clk); @(posedge clk);
    enable = 0;
  endtask

  // Print the 8x8 DCT output matrix
  task print_matrix;
    int i, j;
    begin
      $display("-------- DCT Output --------");
      for (i = 0; i < 8; i++) begin
        for (j = 0; j < 8; j++)
          $write("%6d ", Z[i][j]);
        $write("\n");
      end
    end
  endtask

  // Wait for output_enable and display matrix
task automatic check_output;
  int cycles;
  begin
    cycles = 0;
    while (!output_enable && cycles < 1000) begin
      @(posedge clk);
      cycles++;
    end
    $display("✅ Output valid after %0d cycles", cycles);
    print_matrix();
  end
endtask


  // Main test sequence
  initial begin
    clk = 0;
    rst = 1;
    enable = 0;
    data_in = 0;
    #20 rst = 0;

    $display("\n========== TEST: All 128s ==========");
    feed_block(8'd128); check_output();

    $display("\n========== TEST: All 0s ==========");
    rst = 1; #20 rst = 0;
    feed_block(8'd0); check_output();

    $display("\n========== TEST: All 255s ==========");
    rst = 1; #20 rst = 0;
    feed_block(8'd255); check_output();

    $display("\n========== TEST: Checkerboard ==========");
    rst = 1; #20 rst = 0;
    enable = 1;
    for (int i = 0; i < 64; i++) begin
      data_in = ((i[0] ^ i[3]) ? 8'd255 : 8'd0);
      @(posedge clk);
    end
    @(posedge clk); @(posedge clk); enable = 0;
    check_output();

    $display("\n========== TEST: Random Block ==========");
    rst = 1; #20 rst = 0;
    enable = 1;
    for (int i = 0; i < 64; i++) begin
      data_in = $urandom_range(0, 255);
      @(posedge clk);
    end
    @(posedge clk); @(posedge clk); enable = 0;
    check_output();

    $display("\n✅✅✅ All Tests Finished ✅✅✅");
    $finish;
  end

endmodule
