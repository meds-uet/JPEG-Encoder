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

  // Clock period
  parameter CLK_PERIOD = 50; // 100ns period (50ns high, 50ns low)

  // Signals
  reg clk;
  reg rst;
  reg enable;
  reg [7:0] data_in; // 8-bit input data

  // DCT output signals (Corrected to 11-bit signed based on warnings)
  wire signed [10:0] Z11_final, Z12_final, Z13_final, Z14_final, Z15_final, Z16_final, Z17_final, Z18_final;
  wire signed [10:0] Z21_final, Z22_final, Z23_final, Z24_final, Z25_final, Z26_final, Z27_final, Z28_final;
  wire signed [10:0] Z31_final, Z32_final, Z33_final, Z34_final, Z35_final, Z36_final, Z37_final, Z38_final;
  wire signed [10:0] Z41_final, Z42_final, Z43_final, Z44_final, Z45_final, Z46_final, Z47_final, Z48_final;
  wire signed [10:0] Z51_final, Z52_final, Z53_final, Z54_final, Z55_final, Z56_final, Z57_final, Z58_final;
  wire signed [10:0] Z61_final, Z62_final, Z63_final, Z64_final, Z65_final, Z66_final, Z67_final, Z68_final;
  wire signed [10:0] Z71_final, Z72_final, Z73_final, Z74_final, Z75_final, Z76_final, Z77_final, Z78_final;
  wire signed [10:0] Z81_final, Z82_final, Z83_final, Z84_final, Z85_final, Z86_final, Z87_final, Z88_final;

  wire output_enable;

  // Instantiate the Device Under Test (DUT)
  cr_dct dut (
    .clk(clk),
    .rst(rst),
    .enable(enable),
    .data_in(data_in),
    .Z11_final(Z11_final), .Z12_final(Z12_final), .Z13_final(Z13_final), .Z14_final(Z14_final),
    .Z15_final(Z15_final), .Z16_final(Z16_final), .Z17_final(Z17_final), .Z18_final(Z18_final),
    .Z21_final(Z21_final), .Z22_final(Z22_final), .Z23_final(Z23_final), .Z24_final(Z24_final),
    .Z25_final(Z25_final), .Z26_final(Z26_final), .Z27_final(Z27_final), .Z28_final(Z28_final),
    .Z31_final(Z31_final), .Z32_final(Z32_final), .Z33_final(Z33_final), .Z34_final(Z34_final),
    .Z35_final(Z35_final), .Z36_final(Z36_final), .Z37_final(Z37_final), .Z38_final(Z38_final),
    .Z41_final(Z41_final), .Z42_final(Z42_final), .Z43_final(Z43_final), .Z44_final(Z44_final),
    .Z45_final(Z45_final), .Z46_final(Z46_final), .Z47_final(Z47_final), .Z48_final(Z48_final),
    .Z51_final(Z51_final), .Z52_final(Z52_final), .Z53_final(Z53_final), .Z54_final(Z54_final),
    .Z55_final(Z55_final), .Z56_final(Z56_final), .Z57_final(Z57_final), .Z58_final(Z58_final),
    .Z61_final(Z61_final), .Z62_final(Z62_final), .Z63_final(Z63_final), .Z64_final(Z64_final),
    .Z65_final(Z65_final), .Z66_final(Z66_final), .Z67_final(Z67_final), .Z68_final(Z68_final),
    .Z71_final(Z71_final), .Z72_final(Z72_final), .Z73_final(Z73_final), .Z74_final(Z74_final),
    .Z75_final(Z75_final), .Z76_final(Z76_final), .Z77_final(Z77_final), .Z78_final(Z78_final),
    .Z81_final(Z81_final), .Z82_final(Z82_final), .Z83_final(Z83_final), .Z84_final(Z84_final),
    .Z85_final(Z85_final), .Z86_final(Z86_final), .Z87_final(Z87_final), .Z88_final(Z88_final),
    .output_enable(output_enable)
  );

  // Clock generation
  initial begin
    clk = 0;
    forever #(CLK_PERIOD/2) clk = ~clk;
  end

  // Test sequence
  initial begin
    // Initialize
    rst = 1;
    enable = 0;
    data_in = 0;
    #(CLK_PERIOD); // Wait 1 clock cycle for reset

    rst = 0;
    #(CLK_PERIOD); // Wait 1 clock cycle

    // Apply 64 input values
    enable = 1;
    for (int i = 0; i < 64; i = i + 1) begin
      data_in = i + 10; // Example input data
      #80;
    end
    enable = 0; // Disable further input

    // Keep simulation running to allow output to stabilize/assert
    #7000; // Extend simulation time to ensure DCT calculation finishes
    $finish;
  end

  // Display DCT Output only when output_enable asserts
  always @(posedge output_enable) begin
    $display("\nDCT Output (Zxx_final) at Time %0d:", $time);
    $display("----------------------------------------");
    $display("Z11=%d Z12=%d Z13=%d Z14=%d Z15=%d Z16=%d Z17=%d Z18=%d",
             Z11_final, Z12_final, Z13_final, Z14_final, Z15_final, Z16_final, Z17_final, Z18_final);
    $display("Z21=%d Z22=%d Z23=%d Z24=%d Z25=%d Z26=%d Z27=%d Z28=%d",
             Z21_final, Z22_final, Z23_final, Z24_final, Z25_final, Z26_final, Z27_final, Z28_final);
    $display("Z31=%d Z32=%d Z33=%d Z34=%d Z35=%d Z36=%d Z37=%d Z38=%d",
             Z31_final, Z32_final, Z33_final, Z34_final, Z35_final, Z36_final, Z37_final, Z38_final);
    $display("Z41=%d Z42=%d Z43=%d Z44=%d Z45=%d Z46=%d Z47=%d Z48=%d",
             Z41_final, Z42_final, Z43_final, Z44_final, Z45_final, Z46_final, Z47_final, Z48_final);
    $display("Z51=%d Z52=%d Z53=%d Z54=%d Z55=%d Z56=%d Z57=%d Z58=%d",
             Z51_final, Z52_final, Z53_final, Z54_final, Z55_final, Z56_final, Z57_final, Z58_final);
    $display("Z61=%d Z62=%d Z63=%d Z64=%d Z65=%d Z66=%d Z67=%d Z68=%d",
             Z61_final, Z62_final, Z63_final, Z64_final, Z65_final, Z66_final, Z67_final, Z68_final);
    $display("Z71=%d Z72=%d Z73=%d Z74=%d Z75=%d Z76=%d Z77=%d Z78=%d",
             Z71_final, Z72_final, Z73_final, Z74_final, Z75_final, Z76_final, Z77_final, Z78_final);
    $display("Z81=%d Z82=%d Z83=%d Z84=%d Z85=%d Z86=%d Z87=%d Z88=%d",
             Z81_final, Z82_final, Z83_final, Z84_final, Z85_final, Z86_final, Z87_final, Z88_final);
    $display("----------------------------------------");
  end

endmodule
