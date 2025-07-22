// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// Module Name: y_huff_tb
// Description:
//    This testbench is designed to verify the functionality of the `y_huff` module,
//    which performs Huffman encoding on quantized Discrete Cosine Transform (DCT)
//    coefficients for the Y (Luma) component. The DUT expects 11-bit signed
//    quantized coefficients for an 8x8 block (Y11 through Y88).
//
//    The testbench generates a 100 MHz clock and applies a reset sequence. It then
//    provides two test cases. The first test case sets specific non-zero values
//    for a few coefficients (Y11, Y21, Y13) and initializes all other coefficients
//    to zero, simulating a typical sparse DCT block. The second test case applies
//    different values to Y11 and Y21 after a reset. For both cases, the testbench
//    asserts `enable` to initiate encoding and then deasserts it, allowing the DUT
//    to process the block.
//
// Author:Rameen
// Date:21st July,2025.

`timescale 1ns / 100ps

module y_huff_tb;

    // Testbench signals
    logic        clk;
    logic        rst;
    logic        enable;
    logic [10:0] Y11, Y12, Y13, Y14, Y15, Y16, Y17, Y18;
    logic [10:0] Y21, Y22, Y23, Y24, Y25, Y26, Y27, Y28;
    logic [10:0] Y31, Y32, Y33, Y34, Y35, Y36, Y37, Y38;
    logic [10:0] Y41, Y42, Y43, Y44, Y45, Y46, Y47, Y48;
    logic [10:0] Y51, Y52, Y53, Y54, Y55, Y56, Y57, Y58;
    logic [10:0] Y61, Y62, Y63, Y64, Y65, Y66, Y67, Y68;
    logic [10:0] Y71, Y72, Y73, Y74, Y75, Y76, Y77, Y78;
    logic [10:0] Y81, Y82, Y83, Y84, Y85, Y86, Y87, Y88;
    logic [31:0] JPEG_bitstream;
    logic        data_ready;
    logic [4:0]  output_reg_count;
    logic        end_of_block_output;
    logic        end_of_block_empty;

    // Instantiate the y_huff module
    y_huff dut (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .Y11(Y11), .Y12(Y12), .Y13(Y13), .Y14(Y14), .Y15(Y15), .Y16(Y16), .Y17(Y17), .Y18(Y18),
        .Y21(Y21), .Y22(Y22), .Y23(Y23), .Y24(Y24), .Y25(Y25), .Y26(Y26), .Y27(Y27), .Y28(Y28),
        .Y31(Y31), .Y32(Y32), .Y33(Y33), .Y34(Y34), .Y35(Y35), .Y36(Y36), .Y37(Y37), .Y38(Y38),
        .Y41(Y41), .Y42(Y42), .Y43(Y43), .Y44(Y44), .Y45(Y45), .Y46(Y46), .Y47(Y47), .Y48(Y48),
        .Y51(Y51), .Y52(Y52), .Y53(Y53), .Y54(Y54), .Y55(Y55), .Y56(Y56), .Y57(Y57), .Y58(Y58),
        .Y61(Y61), .Y62(Y62), .Y63(Y63), .Y64(Y64), .Y65(Y65), .Y66(Y66), .Y67(Y67), .Y68(Y68),
        .Y71(Y71), .Y72(Y72), .Y73(Y73), .Y74(Y74), .Y75(Y75), .Y76(Y76), .Y77(Y77), .Y78(Y78),
        .Y81(Y81), .Y82(Y82), .Y83(Y83), .Y84(Y84), .Y85(Y85), .Y86(Y86), .Y87(Y87), .Y88(Y88),
        .JPEG_bitstream(JPEG_bitstream),
        .data_ready(data_ready),
        .output_reg_count(output_reg_count),
        .end_of_block_output(end_of_block_output),
        .end_of_block_empty(end_of_block_empty)
    );

    // Clock generation: 100 MHz (10ns period)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test stimulus
    initial begin
        // Initialize signals
        rst = 1;
        enable = 0;
        Y11 = 11'd50;  // DC coefficient
        Y21 = 11'd3;   // Non-zero AC coefficient
        Y31 = 11'd0;   // Zero
        Y22 = 11'd0;   // Zero
        Y13 = 11'd2;   // Non-zero AC coefficient
        Y14 = 11'd0;   // Zero
        Y15 = 11'd0;   // Zero
        Y16 = 11'd0;   // Zero
        Y17 = 11'd0;   // Zero
        Y18 = 11'd0;   // Zero
        Y23 = 11'd0;   // Zero
        Y24 = 11'd0;   // Zero
        Y25 = 11'd0;   // Zero
        Y26 = 11'd0;   // Zero
        Y27 = 11'd0;   // Zero
        Y28 = 11'd0;   // Zero
        Y32 = 11'd0;   // Zero
        Y33 = 11'd0;   // Zero
        Y34 = 11'd0;   // Zero
        Y35 = 11'd0;   // Zero
        Y36 = 11'd0;   // Zero
        Y37 = 11'd0;   // Zero
        Y38 = 11'd0;   // Zero
        Y41 = 11'd0;   // Zero
        Y42 = 11'd0;   // Zero
        Y43 = 11'd0;   // Zero
        Y44 = 11'd0;   // Zero
        Y45 = 11'd0;   // Zero
        Y46 = 11'd0;   // Zero
        Y47 = 11'd0;   // Zero
        Y48 = 11'd0;   // Zero
        Y51 = 11'd0;   // Zero
        Y52 = 11'd0;   // Zero
        Y53 = 11'd0;   // Zero
        Y54 = 11'd0;   // Zero
        Y55 = 11'd0;   // Zero
        Y56 = 11'd0;   // Zero
        Y57 = 11'd0;   // Zero
        Y58 = 11'd0;   // Zero
        Y61 = 11'd0;   // Zero
        Y62 = 11'd0;   // Zero
        Y63 = 11'd0;   // Zero
        Y64 = 11'd0;   // Zero
        Y65 = 11'd0;   // Zero
        Y66 = 11'd0;   // Zero
        Y67 = 11'd0;   // Zero
        Y68 = 11'd0;   // Zero
        Y71 = 11'd0;   // Zero
        Y72 = 11'd0;   // Zero
        Y73 = 11'd0;   // Zero
        Y74 = 11'd0;   // Zero
        Y75 = 11'd0;   // Zero
        Y76 = 11'd0;   // Zero
        Y77 = 11'd0;   // Zero
        Y78 = 11'd0;   // Zero
        Y81 = 11'd0;   // Zero
        Y82 = 11'd0;   // Zero
        Y83 = 11'd0;   // Zero
        Y84 = 11'd0;   // Zero
        Y85 = 11'd0;   // Zero
        Y86 = 11'd0;   // Zero
        Y87 = 11'd0;   // Zero
        Y88 = 11'd0;   // Zero

        // Reset sequence
        #20 rst = 0;  // Deassert reset after 20ns

        // Enable the module
        #10 enable = 1;
        #10 enable = 0;

        // Run for sufficient cycles to process the entire block
        #1000;

        // Second test case: Change DC coefficient and one AC coefficient
        rst = 1;
        #10 rst = 0;
        Y11 = 11'd100;  // New DC coefficient
        Y21 = 11'd5;    // New non-zero AC coefficient
        #10 enable = 1;
        #10 enable = 0;

        // Run for sufficient cycles to process the second block
        #1000;

        // End simulation
        $display("Simulation completed.");
        $finish;
    end

    // Monitor outputs
    initial begin
        $monitor("Time=%0t rst=%b enable=%b data_ready=%b output_reg_count=%0d end_of_block_output=%b end_of_block_empty=%b JPEG_bitstream=%h",
                 $time, rst, enable, data_ready, output_reg_count, end_of_block_output, end_of_block_empty, JPEG_bitstream);
    end

    // Dump variables for waveform analysis
    initial begin
        $dumpfile("y_huff_tb.vcd");
        $dumpvars(0, y_huff_tb);
    end

endmodule
