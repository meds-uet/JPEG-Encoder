// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// Module Name: tb_fifo_out
// Description:
//    This testbench is designed to verify the functionality of the `fifo_out` module,
//    which appears to act as an output buffering or formatting stage in a JPEG encoding
//    pipeline. It accepts 24-bit input data (`data_in`) and is expected to output
//    a 32-bit JPEG bitstream (`JPEG_bitstream`), along with control signals
//    `data_ready` and `orc_reg` (likely indicating output register count).
//
//    The testbench generates a 100 MHz clock and applies a standard reset sequence.
//    It then enables the DUT and feeds a short sequence of incrementing 24-bit
//    dummy data. After providing the input, the `enable` signal is deasserted,
//    allowing the internal pipelines of the `fifo_out` module to process and
//    output the buffered data. The testbench monitors and displays the final
//    values of `JPEG_bitstream`, `orc_reg`, and `data_ready` before concluding
//    the simulation. This setup helps in basic functional verification of data
//    transfer and output signaling within the `fifo_out` module.
//
// Author:Navaal Noshi
// Date:20thJuly,2025.

`timescale 1ns / 100ps

module tb_fifo_out;

  // Inputs
  logic clk;
  logic rst;
  logic enable;
  logic [23:0] data_in;

  // Outputs
  logic [31:0] JPEG_bitstream;
  logic        data_ready;
  logic [4:0]  orc_reg;

  // Instantiate the DUT
  fifo_out uut (
    .clk(clk),
    .rst(rst),
    .enable(enable),
    .data_in(data_in),
    .JPEG_bitstream(JPEG_bitstream),
    .data_ready(data_ready),
    .orc_reg(orc_reg)
  );

  // Clock generation
  initial clk = 0;
  always #5 clk = ~clk; // 100 MHz clock

  // Stimulus
  initial begin
    $display("=== Starting fifo_out Testbench ===");
    rst = 1;
    enable = 0;
    data_in = 24'd0;
    #20;

    rst = 0;
    #10;

    // Apply some dummy input to trigger pre_fifo and fifo pipelines
    enable = 1;

    // Sending dummy stream (e.g., alternating values)
    for (int i = 0; i < 10; i++) begin
      data_in = 24'd123456 + i;
      #10;
    end

    enable = 0;

    // Let the pipeline run
    #200;

    $display("JPEG Output: %h", JPEG_bitstream);
    $display("ORC Register: %0d", orc_reg);
    $display("Data Ready: %b", data_ready);

    $display("=== Testbench Complete ===");
    $finish;
  end

endmodule
