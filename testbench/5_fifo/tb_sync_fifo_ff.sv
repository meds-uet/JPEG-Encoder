// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// Module Name: tb_sync_fifo_ff
// Description:
//    This testbench is designed to thoroughly verify the functionality of the
//    `sync_fifo_ff` module, which is a synchronous FIFO with a unique `rollover_write`
//    feature. This FIFO handles 91-bit wide data. It has standard FIFO inputs like
//    clock, reset, read request, write data, and write enable, and outputs for
//    read data, fifo empty status, and read data valid. The `rollover_write` input
//    is specifically tested to understand its impact on the FIFO's behavior,
//    likely causing a skip in an entry.
//
//    The testbench generates a 100 MHz clock. The test sequence is divided into
//    two main parts:
//    1.  **Standard Write and Read:** It first initializes the FIFO by asserting and
//        deasserting reset. Then, it writes four distinct 91-bit data values sequentially
//        into the FIFO using the `write_to_fifo` task. Subsequently, it reads back
//        all four values using the `read_from_fifo` task, which includes a `wait`
//        condition for `rdata_valid` to ensure that valid data is available before reading.
//    2.  **Rollover Write Test:** This section specifically targets the `rollover_write`
//        functionality. It performs a `write_rollover` operation, which is intended
//        to cause a 1-entry skip in the FIFO, followed by two regular writes. The
//        test then reads back data, observing the effect of the `rollover_write`
//        on the sequence of read data.
// Author:Navaal Noshi
// Date:22nd July,2025.

`timescale 1ns / 100ps

module tb_sync_fifo_ff;

    // DUT Signals
    logic clk;
    logic rst;
    logic read_req;
    logic [90:0] write_data;
    logic write_enable;
    logic rollover_write;
    logic [90:0] read_data;
    logic fifo_empty;
    logic rdata_valid;

    // Instantiate the DUT
    sync_fifo_ff dut (
        .clk(clk),
        .rst(rst),
        .read_req(read_req),
        .write_data(write_data),
        .write_enable(write_enable),
        .rollover_write(rollover_write),
        .read_data(read_data),
        .fifo_empty(fifo_empty),
        .rdata_valid(rdata_valid)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Test sequence
    initial begin
        $display("=== Test: Write and Read ===");

        // Initialize signals
        clk = 0;
        rst = 1;
        read_req = 0;
        write_data = 0;
        write_enable = 0;
        rollover_write = 0;

        // Reset the DUT
        repeat (2) @(posedge clk);
        rst = 0;

        // Write 4 values
        write_to_fifo(91'd100);
        write_to_fifo(91'd101);
        write_to_fifo(91'd102);
        write_to_fifo(91'd103);

        // Read 4 values
        read_from_fifo();
        read_from_fifo();
        read_from_fifo();
        read_from_fifo();

        // Rollover write test
        $display("=== Test: Rollover Write ===");

        write_rollover(91'd500);     // causes 1-entry skip in FIFO
        write_to_fifo(91'd999);
        write_to_fifo(91'd777);

        // Read back
        read_from_fifo();
        read_from_fifo();
        read_from_fifo();  // this one might return skipped or default
        read_from_fifo();

        $display("=== Test Complete ===");
        $finish;
    end

    // Task to write to FIFO
    task write_to_fifo(input logic [90:0] data);
        begin
            @(posedge clk);
            write_data     <= data;
            write_enable   <= 1;
            rollover_write <= 0;
            @(posedge clk);
            write_enable   <= 0;
            rollover_write <= 0;
        end
    endtask

    // Task to write to FIFO with rollover (inserts bubble)
    task write_rollover(input logic [90:0] data);
        begin
            @(posedge clk);
            write_data     <= data;
            write_enable   <= 1;
            rollover_write <= 1;
            @(posedge clk);
            write_enable   <= 0;
            rollover_write <= 0;
        end
    endtask

    // Task to read from FIFO with synchronization
    task read_from_fifo;
        begin
            @(posedge clk);
            read_req <= 1;
            @(posedge clk);
            read_req <= 0;
            wait (rdata_valid === 1);
            @(posedge clk);
            $display("Read data: %0d", read_data);
        end
    endtask

endmodule
