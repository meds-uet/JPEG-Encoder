// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// Description:
//    This module implements a synchronous FIFO (First-In, First-Out) buffer.
//    Its primary purpose is to store encoded data blocks and output them sequentially,
//    specifically designed to facilitate "FF checking" (e.g., for JPEG byte stuffing).
//    It includes a special "rollover_write" mechanism to introduce a controlled delay
//    or specific behavior after an FF escaping operation.
//    The FIFO has a fixed depth of 16 entries.
//    It provides a 'valid' output signal to indicate when valid data is available
//    and an 'empty' signal to indicate the FIFO's status.
//
// Author:Navaal Noshi
// Date:20ht July,2025.

`timescale 1ns / 100ps

module sync_fifo_ff (
    input  logic        clk,
    input  logic        rst,
    input  logic        read_req,
    input  logic [90:0] write_data,
    input  logic        write_enable,
    input  logic        rollover_write,
    output logic [90:0] read_data,
    output logic        fifo_empty,
    output logic        rdata_valid
);

// FIFO memory and pointers
logic [90:0] mem [15:0];        // FIFO memory: 16 entries of 91 bits
logic [4:0] write_ptr, read_ptr; // Full pointer for comparison
logic [3:0] write_addr, read_addr;

assign write_addr = write_ptr[3:0];
assign read_addr  = read_ptr[3:0];

// FIFO empty logic
assign fifo_empty = (write_ptr == read_ptr);

// Read enable: only allowed if FIFO is not empty
logic read_enable;
assign read_enable = read_req && !fifo_empty;


// Write pointer logic with rollover handling
always_ff @(posedge clk or posedge rst) begin
    if (rst)
        write_ptr <= 5'd0;
    else if (write_enable) begin
        if (rollover_write)
            write_ptr <= write_ptr + 5'd2;  // Skip one entry to give time for FF insert
        else
            write_ptr <= write_ptr + 5'd1;
    end
end

// FIFO write operation
always_ff @(posedge clk) begin
    if (write_enable)
        mem[write_addr] <= write_data;
end

// Read pointer logic
always_ff @(posedge clk or posedge rst) begin
    if (rst)
        read_ptr <= 5'd0;
    else if (read_enable)
        read_ptr <= read_ptr + 5'd1;
end

// FIFO read operation
always_ff @(posedge clk) begin
    if (read_enable)
        read_data <= mem[read_addr];
end


// Valid data flag generation
always_ff @(posedge clk or posedge rst) begin
    if (rst)
        rdata_valid <= 1'b0;
    else
        rdata_valid <= read_enable;
end

endmodule
