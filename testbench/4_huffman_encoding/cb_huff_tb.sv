`timescale 1ns / 100ps

module cb_huff_tb;

  // Clock and Reset Signals
  logic clk;
  logic rst;
  logic enable;

  // Input DCT Coefficients for Cb (8x8 block, 11-bit each)
  logic [10:0] Cb11, Cb12, Cb13, Cb14, Cb15, Cb16, Cb17, Cb18;
  logic [10:0] Cb21, Cb22, Cb23, Cb24, Cb25, Cb26, Cb27, Cb28;
  logic [10:0] Cb31, Cb32, Cb33, Cb34, Cb35, Cb36, Cb37, Cb38;
  logic [10:0] Cb41, Cb42, Cb43, Cb44, Cb45, Cb46, Cb47, Cb48;
  logic [10:0] Cb51, Cb52, Cb53, Cb54, Cb55, Cb56, Cb57, Cb58;
  logic [10:0] Cb61, Cb62, Cb63, Cb64, Cb65, Cb66, Cb67, Cb68;
  logic [10:0] Cb71, Cb72, Cb73, Cb74, Cb75, Cb76, Cb77, Cb78;
  logic [10:0] Cb81, Cb82, Cb83, Cb84, Cb85, Cb86, Cb87, Cb88;

  // Output Signals
  logic [31:0] JPEG_bitstream;
  logic data_ready;
  logic [4:0] output_reg_count;
  logic end_of_block_empty;

  // Instantiate the Device Under Test (DUT)
  cb_huff dut (
    .clk(clk),
    .rst(rst),
    .enable(enable),
    .Cb11(Cb11), .Cb12(Cb12), .Cb13(Cb13), .Cb14(Cb14), .Cb15(Cb15), .Cb16(Cb16), .Cb17(Cb17), .Cb18(Cb18),
    .Cb21(Cb21), .Cb22(Cb22), .Cb23(Cb23), .Cb24(Cb24), .Cb25(Cb25), .Cb26(Cb26), .Cb27(Cb27), .Cb28(Cb28),
    .Cb31(Cb31), .Cb32(Cb32), .Cb33(Cb33), .Cb34(Cb34), .Cb35(Cb35), .Cb36(Cb36), .Cb37(Cb37), .Cb38(Cb38),
    .Cb41(Cb41), .Cb42(Cb42), .Cb43(Cb43), .Cb44(Cb44), .Cb45(Cb45), .Cb46(Cb46), .Cb47(Cb47), .Cb48(Cb48),
    .Cb51(Cb51), .Cb52(Cb52), .Cb53(Cb53), .Cb54(Cb54), .Cb55(Cb55), .Cb56(Cb56), .Cb57(Cb57), .Cb58(Cb58),
    .Cb61(Cb61), .Cb62(Cb62), .Cb63(Cb63), .Cb64(Cb64), .Cb65(Cb65), .Cb66(Cb66), .Cb67(Cb67), .Cb68(Cb68),
    .Cb71(Cb71), .Cb72(Cb72), .Cb73(Cb73), .Cb74(Cb74), .Cb75(Cb75), .Cb76(Cb76), .Cb77(Cb77), .Cb78(Cb78),
    .Cb81(Cb81), .Cb82(Cb82), .Cb83(Cb83), .Cb84(Cb84), .Cb85(Cb85), .Cb86(Cb86), .Cb87(Cb87), .Cb88(Cb88),
    .JPEG_bitstream(JPEG_bitstream),
    .data_ready(data_ready),
    .output_reg_count(output_reg_count),
    .end_of_block_empty(end_of_block_empty)
  );

  // Clock Generation
  always #5 clk = ~clk; // 10ns period, 100MHz clock

  initial begin
    // Initialize inputs
    clk = 0;
    rst = 1;
    enable = 0;

    // Initialize all Cb coefficients to 0
    Cb11 = 0; Cb12 = 0; Cb13 = 0; Cb14 = 0; Cb15 = 0; Cb16 = 0; Cb17 = 0; Cb18 = 0;
    Cb21 = 0; Cb22 = 0; Cb23 = 0; Cb24 = 0; Cb25 = 0; Cb26 = 0; Cb27 = 0; Cb28 = 0;
    Cb31 = 0; Cb32 = 0; Cb33 = 0; Cb34 = 0; Cb35 = 0; Cb36 = 0; Cb37 = 0; Cb38 = 0;
    Cb41 = 0; Cb42 = 0; Cb43 = 0; Cb44 = 0; Cb45 = 0; Cb46 = 0; Cb47 = 0; Cb48 = 0;
    Cb51 = 0; Cb52 = 0; Cb53 = 0; Cb54 = 0; Cb55 = 0; Cb56 = 0; Cb57 = 0; Cb58 = 0;
    Cb61 = 0; Cb62 = 0; Cb63 = 0; Cb64 = 0; Cb65 = 0; Cb66 = 0; Cb67 = 0; Cb68 = 0;
    Cb71 = 0; Cb72 = 0; Cb73 = 0; Cb74 = 0; Cb75 = 0; Cb76 = 0; Cb77 = 0; Cb78 = 0;
    Cb81 = 0; Cb82 = 0; Cb83 = 0; Cb84 = 0; Cb85 = 0; Cb86 = 0; Cb87 = 0; Cb88 = 0;

    // Dump waves for simulation
    $dumpfile("cb_huff.vcd");
    $dumpvars(0, cb_huff_tb);

    // Monitor signals
    $monitor("Time=%0t rst=%0d enable=%0d data_ready=%0d output_reg_count=%0d end_of_block_empty=%0d JPEG_bitstream=%h",
             $time, rst, enable, data_ready, output_reg_count, end_of_block_empty, JPEG_bitstream);

    // --- Test Case 1: All Zero Coefficients (Expect EOB after DC) ---
    #50; rst = 0; enable = 0; // De-assert reset
    #150; // Wait for stable state
    $display("\n--- Test Case 1: All Zero Coefficients (Expect EOB) ---");
    enable = 1; // Enable module
    #100; enable = 0; // De-assert enable

    // The module takes time to process and output data. Wait for processing to complete.
    // Based on cr_huff_tb.sv, a delay of #8000 might be appropriate for output to appear.
    #8000;
    // You would typically verify data_ready and JPEG_bitstream here
    // for expected EOB or other Huffman codes.

    // --- Test Case 2: Single Non-Zero DC and one AC Coefficient ---
    #100; // Small delay before next test case
    rst = 1; // Assert reset for next test
    #100; rst = 0; // De-assert reset

    $display("\n--- Test Case 2: Single Non-Zero DC and one AC Coefficient ---");
    // Set a non-zero DC coefficient (Cb11) and a non-zero AC coefficient (e.g., Cb12)
    // DC coefficient typically has a difference from previous, but for a standalone test, set directly.
    Cb11 = 10'd50; // Example DC value
    Cb12 = 10'd5;  // Example AC value
    // All other coefficients remain 0 from initial setting

    enable = 1; // Enable module
    #100; enable = 0; // De-assert enable

    #8000;
    // Verify outputs here.

    // Finish simulation
    #100;
    $finish;
  end

endmodule