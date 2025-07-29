// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// Module Name: cr_huff_tb
// Description:
//    This testbench is designed to verify the functionality of the `cr_huff` module,
//    which performs Huffman encoding on quantized Discrete Cosine Transform (DCT)
//    coefficients for the Cr (Chroma Red) component. The DUT expects 11-bit signed
//    quantized coefficients for an 8x8 block (Cr11 through Cr88).
//
//    The testbench generates a 100 MHz clock and applies a reset sequence. It includes
//    two distinct test cases. The first test case provides an input block where all
//    Cr coefficients are zero, which should result in an End-of-Block (EOB) marker
//    from the Huffman encoder. The second test case sets a non-zero DC coefficient
//    (Cr11) and one non-zero AC coefficient (Cr12), with all other coefficients
//    being zero, to test the encoding of a sparse block. For both cases, the testbench
//    asserts `enable` to initiate encoding and then deasserts it, allowing the DUT
//    to process the block.
//
// Author:Rameen
// Date:22nd July,2025.

`timescale 1ns / 100ps

`include "cr_huff_constants.svh"

module cr_huff_tb;

    // Testbench signals
    logic        clk;
    logic        rst;
    logic        enable;
    logic [10:0] Cr11, Cr12, Cr13, Cr14, Cr15, Cr16, Cr17, Cr18;
    logic [10:0] Cr21, Cr22, Cr23, Cr24, Cr25, Cr26, Cr27, Cr28;
    logic [10:0] Cr31, Cr32, Cr33, Cr34, Cr35, Cr36, Cr37, Cr38;
    logic [10:0] Cr41, Cr42, Cr43, Cr44, Cr45, Cr46, Cr47, Cr48;
    logic [10:0] Cr51, Cr52, Cr53, Cr54, Cr55, Cr56, Cr57, Cr58;
    logic [10:0] Cr61, Cr62, Cr63, Cr64, Cr65, Cr66, Cr67, Cr68;
    logic [10:0] Cr71, Cr72, Cr73, Cr74, Cr75, Cr76, Cr77, Cr78;
    logic [10:0] Cr81, Cr82, Cr83, Cr84, Cr85, Cr86, Cr87, Cr88;
    logic [31:0] JPEG_bitstream;
    logic        data_ready;
    logic [4:0]  output_reg_count;
    logic        end_of_block_empty; // Note: The cr_huff module has end_of_block_empty, not end_of_block_output

    // Instantiate the cr_huff module
    cr_huff dut (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .Cr11(Cr11), .Cr12(Cr12), .Cr13(Cr13), .Cr14(Cr14), .Cr15(Cr15), .Cr16(Cr16), .Cr17(Cr17), .Cr18(Cr18),
        .Cr21(Cr21), .Cr22(Cr22), .Cr23(Cr23), .Cr24(Cr24), .Cr25(Cr25), .Cr26(Cr26), .Cr27(Cr27), .Cr28(Cr28),
        .Cr31(Cr31), .Cr32(Cr32), .Cr33(Cr33), .Cr34(Cr34), .Cr35(Cr35), .Cr36(Cr36), .Cr37(Cr37), .Cr38(Cr38),
        .Cr41(Cr41), .Cr42(Cr42), .Cr43(Cr43), .Cr44(Cr44), .Cr45(Cr45), .Cr46(Cr46), .Cr47(Cr47), .Cr48(Cr48),
        .Cr51(Cr51), .Cr52(Cr52), .Cr53(Cr53), .Cr54(Cr54), .Cr55(Cr55), .Cr56(Cr56), .Cr57(Cr57), .Cr58(Cr58),
        .Cr61(Cr61), .Cr62(Cr62), .Cr63(Cr63), .Cr64(Cr64), .Cr65(Cr65), .Cr66(Cr66), .Cr67(Cr67), .Cr68(Cr68),
        .Cr71(Cr71), .Cr72(Cr72), .Cr73(Cr73), .Cr74(Cr74), .Cr75(Cr75), .Cr76(Cr76), .Cr77(Cr77), .Cr78(Cr78),
        .Cr81(Cr81), .Cr82(Cr82), .Cr83(Cr83), .Cr84(Cr84), .Cr85(Cr85), .Cr86(Cr86), .Cr87(Cr87), .Cr88(Cr88),
        .JPEG_bitstream(JPEG_bitstream),
        .data_ready(data_ready),
        .output_reg_count(output_reg_count),
        .end_of_block_empty(end_of_block_empty) // Using the correct port name from cr_huff
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
        // Initialize all Cr coefficients to 0 for the first test case
        Cr11 = 0; Cr12 = 0; Cr13 = 0; Cr14 = 0; Cr15 = 0; Cr16 = 0; Cr17 = 0; Cr18 = 0;
        Cr21 = 0; Cr22 = 0; Cr23 = 0; Cr24 = 0; Cr25 = 0; Cr26 = 0; Cr27 = 0; Cr28 = 0;
        Cr31 = 0; Cr32 = 0; Cr33 = 0; Cr34 = 0; Cr35 = 0; Cr36 = 0; Cr37 = 0; Cr38 = 0;
        Cr41 = 0; Cr42 = 0; Cr43 = 0; Cr44 = 0; Cr45 = 0; Cr46 = 0; Cr47 = 0; Cr48 = 0;
        Cr51 = 0; Cr52 = 0; Cr53 = 0; Cr54 = 0; Cr55 = 0; Cr56 = 0; Cr57 = 0; Cr58 = 0;
        Cr61 = 0; Cr62 = 0; Cr63 = 0; Cr64 = 0; Cr65 = 0; Cr66 = 0; Cr67 = 0; Cr68 = 0;
        Cr71 = 0; Cr72 = 0; Cr73 = 0; Cr74 = 0; Cr75 = 0; Cr76 = 0; Cr77 = 0; Cr78 = 0;
        Cr81 = 0; Cr82 = 0; Cr83 = 0; Cr84 = 0; Cr85 = 0; Cr86 = 0; Cr87 = 0; Cr88 = 0;

        // Reset sequence
        #20 rst = 0; // Deassert reset after 20ns

        // Test Case 1: All Zero Coefficients (Expect EOB)
        $display("--- Test Case 1: All Zero Coefficients (Expect EOB) ---");
        #10 enable = 1; // Assert enable
        #10 enable = 0; // Deassert enable to start processing

        // Run for sufficient cycles to process the entire block (or wait for data_ready/end_of_block_empty)
        #1000;

        // Second test case: Change DC coefficient and one AC coefficient
        $display("--- Test Case 2: Single Non-Zero DC and one AC Coefficient ---");
        rst = 1; // Assert reset for the next test case
        #10 rst = 0; // Deassert reset
        
        // Apply new input values
        Cr11 = 11'd100; // New DC coefficient
        Cr12 = 11'd5;   // New non-zero AC coefficient
        Cr13 = 11'd0; Cr14 = 11'd0; Cr15 = 11'd0; Cr16 = 11'd0; Cr17 = 11'd0; Cr18 = 11'd0;
        Cr21 = 11'd0; Cr22 = 11'd0; Cr23 = 11'd0; Cr24 = 11'd0; Cr25 = 11'd0; Cr26 = 11'd0; Cr27 = 11'd0; Cr28 = 11'd0;
        // ... set all other Cr coefficients to 0 or desired values for this test case
        
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
        $monitor("Time=%0t rst=%b enable=%b data_ready=%b output_reg_count=%0d end_of_block_empty=%b JPEG_bitstream=%h",
                 $time, rst, enable, data_ready, output_reg_count, end_of_block_empty, JPEG_bitstream);
    end

    // Dump variables for waveform analysis
    initial begin
        $dumpfile("cr_huff_tb.vcd");
        $dumpvars(0, cr_huff_tb);
    end

endmodule
