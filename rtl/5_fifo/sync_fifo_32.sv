// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// Description:
//    This module implements a synchronous First-In, First-Out (FIFO) buffer.
//    It is configured with a 32-bit data width and has a storage capacity of 16 entries.
//    The FIFO provides `read_data` output for the dequeued item, a `fifo_empty` signal
//    to indicate its empty status, and an `rdata_valid` signal to indicate when valid
//    data is available on the `read_data` output. This FIFO is typically used for
//    data staging in various pipelined architectures, such as JPEG processing chains.
//
// Author:Navaal Noshi
// Date:16th July,2025.

`timescale 1ns / 100ps

module sync_fifo_32 (
    input  logic        clk,
    input  logic        rst,
    input  logic        read_req,
    input  logic [31:0] write_data,
    input  logic        write_enable,
    output logic [31:0] read_data,
    output logic        fifo_empty,
    output logic        rdata_valid
);

   
    // FIFO memory and control signals
    logic [4:0]  read_ptr;          // Full pointer for depth management (5 bits = up to 32)
    logic [4:0]  write_ptr;
    logic [31:0] mem [0:15];        // FIFO storage for 16 entries

    // Address width calculation
    localparam FIFO_DEPTH = 16;
    localparam ADDR_WIDTH = $clog2(FIFO_DEPTH);  // = 4 for 16 entries

    logic [ADDR_WIDTH-1:0] write_addr;
    logic [ADDR_WIDTH-1:0] read_addr;

    assign write_addr = write_ptr[ADDR_WIDTH-1:0];
    assign read_addr  = read_ptr[ADDR_WIDTH-1:0];
  
    // Read enable logic (combinational)
    // Only allow read if FIFO is not empty
    logic read_enable_int;
    assign fifo_empty      = (read_ptr == write_ptr);
    assign read_enable_int = read_req && !fifo_empty;

    // Write pointer increment logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            write_ptr <= '0;
        else if (write_enable)
            write_ptr <= write_ptr + 1;
    end
  
    // Read pointer increment logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            read_ptr <= '0;
        else if (read_enable_int)
            read_ptr <= read_ptr + 1;
    end

    // Memory write logic
    always_ff @(posedge clk) begin
        if (write_enable)
            mem[write_addr] <= write_data;
    end

    // Memory read logic
    // Data only updated on read_enable
    // Holds previous value otherwise
    always_ff @(posedge clk) begin
        if (read_enable_int)
            read_data <= mem[read_addr];
    end
  
    // Read data valid flag logic
    // Asserted for 1 cycle when data is read
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            rdata_valid <= 1'b0;
        else
            rdata_valid <= read_enable_int;
    end

endmodule
