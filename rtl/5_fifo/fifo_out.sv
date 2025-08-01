// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// Description:
//    This testbench verifies the functionality of the `fifo_out` module,
//    which combines Y, Cb, and Cr data from the pre_fifo module into a single
//    JPEG bitstream using three FIFOs. The testbench generates a clock, applies
//    reset, and feeds various test patterns into the 24-bit data input, simulating
//    Y, Cb, and Cr components. After waiting for the `data_ready` signal, it prints
//    the input data, the generated JPEG bitstream, and output signals such as `orc_reg`
//    for verification.
//
// Author: Navaal Noshi
// Date: 29th July, 2025

`timescale 1ns / 100ps

module fifo_out (
    input  logic        clk, rst, enable,
    input  logic [23:0] data_in,
    output logic [31:0] JPEG_bitstream,
    output logic        data_ready,
    output logic [4:0]  orc_reg
);

    // Internal signals
    logic [31:0] cb_bits_out, cr_bits_out, y_bits_out;
    logic [4:0]  cr_orc, cb_orc, y_orc;
    logic        y_out_enable, cb_data_ready, cr_data_ready, y_data_ready;
    logic        end_of_block_output, y_eob_empty, cb_eob_empty, cr_eob_empty;
    logic        y_fifo_empty, fifo_mux;
    logic [4:0]  orc, orc_cb, orc_cr, old_orc_reg, sorc_reg, roll_orc_reg;
    logic [4:0]  orc_1, orc_2, orc_3, orc_4, orc_5, static_orc_5, static_orc_6;
    logic [4:0]  edge_ro_1, edge_ro_2, edge_ro_3, edge_ro_4, edge_ro_5;
    logic [31:0] jpeg, jpeg_1, jpeg_2, jpeg_3, jpeg_4, jpeg_5, jpeg_6;
    logic [31:0] jpeg_ro_1, jpeg_ro_2, jpeg_ro_3, jpeg_ro_4, jpeg_ro_5;
    logic [2:0]  bits_mux, old_orc_mux, read_mux;
    logic        bits_ready, br_1, br_2, br_3, br_4, br_5, br_6;
    logic        rollover, rollover_1, rollover_2, rollover_3, rollover_4, rollover_5;
    logic        rollover_eob, eob_1, eob_2, eob_3, eob_4, eob_early_out_enable;
    logic        cr_out_enable, cb_out_enable, cr_read_req, cb_read_req, y_read_req;
    logic [31:0] cr_JPEG_bitstream1, cr_JPEG_bitstream2, cb_JPEG_bitstream1, cb_JPEG_bitstream2;
    logic        cr_write_enable1, cr_write_enable2, cb_write_enable1, cb_write_enable2;
    logic        cr_fifo_empty, cb_fifo_empty;

    // FIFO write enables
    assign cb_write_enable = cb_data_ready && !cb_eob_empty;
    assign cr_write_enable = cr_data_ready && !cr_eob_empty;
    assign y_write_enable = y_data_ready && !y_eob_empty;

    // FIFO multiplexing
    assign cr_read_req1 = fifo_mux ? 0 : cr_read_req;
    assign cr_read_req2 = fifo_mux ? cr_read_req : 0;
    assign cr_JPEG_bitstream1 = fifo_mux ? cr_JPEG_bitstream : 0;
    assign cr_JPEG_bitstream2 = fifo_mux ? 0 : cr_JPEG_bitstream;
    assign cr_write_enable1 = fifo_mux && cr_write_enable;
    assign cr_write_enable2 = !fifo_mux && cr_write_enable;
    assign cr_bits_out = fifo_mux ? cr_bits_out2 : cr_bits_out1;
    assign cr_fifo_empty = fifo_mux ? cr_fifo_empty2 : cr_fifo_empty1;
    assign cr_out_enable = fifo_mux ? cr_out_enable2 : cr_out_enable1;
    assign cb_read_req1 = fifo_mux ? 0 : cb_read_req;
    assign cb_read_req2 = fifo_mux ? cb_read_req : 0;
    assign cb_JPEG_bitstream1 = fifo_mux ? cb_JPEG_bitstream : 0;
    assign cb_JPEG_bitstream2 = fifo_mux ? 0 : cb_JPEG_bitstream;
    assign cb_write_enable1 = fifo_mux && cb_write_enable;
    assign cb_write_enable2 = !fifo_mux && cb_write_enable;
    assign cb_bits_out = fifo_mux ? cb_bits_out2 : cb_bits_out1;
    assign cb_fifo_empty = fifo_mux ? cb_fifo_empty2 : cb_fifo_empty1;
    assign cb_out_enable = fifo_mux ? cb_out_enable2 : cb_out_enable1;

    // Module instantiations
    pre_fifo u14 (
        .clk(clk), .rst(rst), .enable(enable), .data_in(data_in),
        .cr_JPEG_bitstream(cr_JPEG_bitstream), .cr_data_ready(cr_data_ready),
        .cr_orc(cr_orc), .cb_JPEG_bitstream(cb_JPEG_bitstream),
        .cb_data_ready(cb_data_ready), .cb_orc(cb_orc),
        .y_JPEG_bitstream(y_JPEG_bitstream), .y_data_ready(y_data_ready),
        .y_orc(y_orc), .y_eob_output(end_of_block_output),
        .y_eob_empty(y_eob_empty), .cb_eob_empty(cb_eob_empty),
        .cr_eob_empty(cr_eob_empty)
    );

    sync_fifo_32 u15 (.clk(clk), .rst(rst), .read_req(cb_read_req1), .write_data(cb_JPEG_bitstream1), .write_enable(cb_write_enable1), .read_data(cb_bits_out1), .fifo_empty(cb_fifo_empty1), .rdata_valid(cb_out_enable1));
    sync_fifo_32 u25 (.clk(clk), .rst(rst), .read_req(cb_read_req2), .write_data(cb_JPEG_bitstream2), .write_enable(cb_write_enable2), .read_data(cb_bits_out2), .fifo_empty(cb_fifo_empty2), .rdata_valid(cb_out_enable2));
    sync_fifo_32 u16 (.clk(clk), .rst(rst), .read_req(cr_read_req1), .write_data(cr_JPEG_bitstream1), .write_enable(cr_write_enable1), .read_data(cr_bits_out1), .fifo_empty(cr_fifo_empty1), .rdata_valid(cr_out_enable1));
    sync_fifo_32 u24 (.clk(clk), .rst(rst), .read_req(cr_read_req2), .write_data(cr_JPEG_bitstream2), .write_enable(cr_write_enable2), .read_data(cr_bits_out2), .fifo_empty(cr_fifo_empty2), .rdata_valid(cr_out_enable2));
    sync_fifo_32 u17 (.clk(clk), .rst(rst), .read_req(y_read_req), .write_data(y_JPEG_bitstream), .write_enable(y_write_enable), .read_data(y_bits_out), .fifo_empty(y_fifo_empty), .rdata_valid(y_out_enable));

    // FIFO multiplexing control
    always_ff @(posedge clk) begin
        if (rst) fifo_mux <= 0;
        else if (end_of_block_output) fifo_mux <= fifo_mux + 1;
    end

    // Read request logic
    always_ff @(posedge clk) begin
        y_read_req <= (!y_fifo_empty && read_mux == 3'b001) ? 1 : 0;
        cb_read_req <= (!cb_fifo_empty && read_mux == 3'b010) ? 1 : 0;
        cr_read_req <= (!cr_fifo_empty && read_mux == 3'b100) ? 1 : 0;
    end

    // Pipeline registers
    always_ff @(posedge clk) begin
        if (rst) begin
            {br_1, br_2, br_3, br_4, br_5, br_6} <= '0;
            {static_orc_1, static_orc_2, static_orc_3, static_orc_4, static_orc_5, static_orc_6} <= '0;
            data_ready <= 0;
            eobe_1 <= 0;
        end else begin
            br_1 <= bits_ready & !eobe_1;
            {br_2, br_3, br_4, br_5, br_6} <= {br_1, br_2, br_3, br_4, br_5};
            static_orc_1 <= sorc_reg;
            {static_orc_2, static_orc_3, static_orc_4, static_orc_5, static_orc_6} <= {static_orc_1, static_orc_2, static_orc_3, static_orc_4, static_orc_5};
            data_ready <= br_6 & rollover_5;
            eobe_1 <= y_eob_empty;
        end
    end

    // Rollover logic
    always_ff @(posedge clk) begin
        if (rst) rollover_eob <= 0;
        else if (br_3) rollover_eob <= old_orc_reg >= roll_orc_reg;
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            {rollover_1, rollover_2, rollover_3, rollover_4, rollover_5, rollover_6, rollover_7} <= '0;
            {eob_1, eob_2, eob_3, eob_4} <= '0;
            eob_early_out_enable <= 0;
        end else begin
            rollover_1 <= rollover;
            {rollover_2, rollover_3, rollover_4} <= {rollover_1, rollover_2, rollover_3 | rollover_eob};
            {rollover_5, rollover_6, rollover_7} <= {rollover_4, rollover_5, rollover_6};
            {eob_1, eob_2, eob_3, eob_4} <= {end_of_block_output, eob_1, eob_2, eob_3};
            eob_early_out_enable <= y_out_enable & y_out_enable_1 & eob_2;
        end
    end

    always_ff @(posedge clk) begin
        case (bits_mux)
            3'b001: rollover <= y_out_enable_1 & !eob_4 & !eob_early_out_enable;
            3'b010: rollover <= cb_out_enable_1 & cb_out_enable;
            3'b100: rollover <= cr_out_enable_1 & cr_out_enable;
            default: rollover <= y_out_enable_1 & !eob_4;
        endcase
    end

    // ORC calculations
    always_ff @(posedge clk) begin
        if (rst) orc <= 0;
        else if (enable_20) orc <= orc_cr + cr_orc_1;
    end

    always_ff @(posedge clk) begin
        if (rst) orc_cb <= 0;
        else if (eob_1) orc_cb <= orc + y_orc_1;
    end

    always_ff @(posedge clk) begin
        if (rst) orc_cr <= 0;
        else if (enable_5) orc_cr <= orc_cb + cb_orc_1;
    end

    always_ff @(posedge clk) begin
        if (rst) {cr_out_enable_1, cb_out_enable_1, y_out_enable_1} <= '0;
        else {cr_out_enable_1, cb_out_enable_1, y_out_enable_1} <= {cr_out_enable, cb_out_enable, y_out_enable};
    end

    // Bitstream selection
    always_ff @(posedge clk) begin
        case (bits_mux)
            3'b001: jpeg <= y_bits_out;
            3'b010: jpeg <= cb_bits_out;
            3'b100: jpeg <= cr_bits_out;
            default: jpeg <= y_bits_out;
        endcase
    end

    always_ff @(posedge clk) begin
        case (bits_mux)
            3'b001: bits_ready <= y_out_enable;
            3'b010: bits_ready <= cb_out_enable;
            3'b100: bits_ready <= cr_out_enable;
            default: bits_ready <= y_out_enable;
        endcase
    end

    always_ff @(posedge clk) begin
        case (bits_mux)
            3'b001: {sorc_reg, orc_reg} <= {orc, orc};
            3'b010: {sorc_reg, orc_reg} <= {orc_cb, orc_cb};
            3'b100: {sorc_reg, orc_reg} <= {orc_cr, orc_cr};
            default: {sorc_reg, orc_reg} <= {orc, orc};
        endcase
    end

    always_ff @(posedge clk) begin
        case (old_orc_mux)
            3'b001: {roll_orc_reg, old_orc_reg} <= {orc, orc_cr};
            3'b010: {roll_orc_reg, old_orc_reg} <= {orc_cb, orc};
            3'b100: {roll_orc_reg, old_orc_reg} <= {orc_cr, orc_cb};
            default: {roll_orc_reg, old_orc_reg} <= {orc, orc_cr};
        endcase
    end

    // Mux control
    always_ff @(posedge clk) begin
        if (rst) bits_mux <= 3'b001;
        else if (enable_3) bits_mux <= 3'b010;
        else if (enable_19) bits_mux <= 3'b100;
        else if (enable_35) bits_mux <= 3'b001;
    end

    always_ff @(posedge clk) begin
        if (rst) old_orc_mux <= 3'b001;
        else if (enable_1) old_orc_mux <= 3'b010;
        else if (enable_6) old_orc_mux <= 3'b100;
        else if (enable_22) old_orc_mux <= 3'b001;
    end

    always_ff @(posedge clk) begin
        if (rst) read_mux <= 3'b001;
        else if (enable_1) read_mux <= 3'b010;
        else if (enable_17) read_mux <= 3'b100;
        else if (enable_33) read_mux <= 3'b001;
    end

    // ORC storage
    always_ff @(posedge clk) begin
        if (rst) {cr_orc_1, cb_orc_1, y_orc_1} <= '0;
        else if (end_of_block_output) {cr_orc_1, cb_orc_1, y_orc_1} <= {cr_orc, cb_orc, y_orc};
    end

    // Bitstream processing pipeline
    always_ff @(posedge clk) begin
        if (rst) {jpeg_ro_5, edge_ro_5} <= '0;
        else if (br_5) begin
            jpeg_ro_5 <= (edge_ro_4 <= 1) ? jpeg_ro_4 << 1 : jpeg_ro_4;
            edge_ro_5 <= (edge_ro_4 <= 1) ? edge_ro_4 : edge_ro_4 - 1;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) {jpeg_5, orc_5, jpeg_ro_4, edge_ro_4} <= '0;
        else if (br_4) begin
            jpeg_5 <= (orc_4 >= 1) ? jpeg_4 >> 1 : jpeg_4;
            orc_5 <= (orc_4 >= 1) ? orc_4 - 1 : orc_4;
            jpeg_ro_4 <= (edge_ro_3 <= 2) ? jpeg_ro_3 << 2 : jpeg_ro_3;
            edge_ro_4 <= (edge_ro_3 <= 2) ? edge_ro_3 : edge_ro_3 - 2;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) {jpeg_4, orc_4, jpeg_ro_3, edge_ro_3} <= '0;
        else if (br_3) begin
            jpeg_4 <= (orc_3 >= 2) ? jpeg_3 >> 2 : jpeg_3;
            orc_4 <= (orc_3 >= 2) ? orc_3 - 2 : orc_3;
            jpeg_ro_3 <= (edge_ro_2 <= 4) ? jpeg_ro_2 << 4 : jpeg_ro_2;
            edge_ro_3 <= (edge_ro_2 <= 4) ? edge_ro_2 : edge_ro_2 - 4;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) {jpeg_3, orc_3, jpeg_ro_2, edge_ro_2} <= '0;
        else if (br_2) begin
            jpeg_3 <= (orc_2 >= 4) ? jpeg_2 >> 4 : jpeg_2;
            orc_3 <= (orc_2 >= 4) ? orc_2 - 4 : orc_2;
            jpeg_ro_2 <= (edge_ro_1 <= 8) ? jpeg_ro_1 << 8 : jpeg_ro_1;
            edge_ro_2 <= (edge_ro_1 <= 8) ? edge_ro_1 : edge_ro_1 - 8;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) {jpeg_2, orc_2, jpeg_ro_1, edge_ro_1} <= '0;
        else if (br_1) begin
            jpeg_2 <= (orc_1 >= 8) ? jpeg_1 >> 8 : jpeg_1;
            orc_2 <= (orc_1 >= 8) ? orc_1 - 8 : orc_1;
            jpeg_ro_1 <= (orc_reg_delay <= 16) ? jpeg_delay << 16 : jpeg_delay;
            edge_ro_1 <= (orc_reg_delay <= 16) ? orc_reg_delay : orc_reg_delay - 16;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) {jpeg_1, orc_1, jpeg_delay, orc_reg_delay} <= '0;
        else if (bits_ready) begin
            jpeg_1 <= (orc_reg >= 16) ? jpeg >> 16 : jpeg;
            orc_1 <= (orc_reg >= 16) ? orc_reg - 16 : orc_reg;
            jpeg_delay <= jpeg;
            orc_reg_delay <= orc_reg;
        end
    end

    // Enable pipeline (consolidated)
    always_ff @(posedge clk) begin
        if (rst) begin
            {enable_1, enable_2, enable_3, enable_4, enable_5, enable_6, enable_7, enable_8,
             enable_9, enable_10, enable_11, enable_12, enable_13, enable_14, enable_15,
             enable_16, enable_17, enable_18, enable_19, enable_20, enable_21, enable_22,
             enable_23, enable_24, enable_25, enable_26, enable_27, enable_28, enable_29,
             enable_30, enable_31, enable_32, enable_33, enable_34, enable_35} <= '0;
        end else begin
            enable_1 <= end_of_block_output;
            {enable_2, enable_3, enable_4, enable_5, enable_6, enable_7, enable_8, enable_9,
             enable_10, enable_11, enable_12, enable_13, enable_14, enable_15, enable_16,
             enable_17, enable_18, enable_19, enable_20, enable_21, enable_22, enable_23,
             enable_24, enable_25, enable_26, enable_27, enable_28, enable_29, enable_30,
             enable_31, enable_32, enable_33, enable_34, enable_35} <=
            {enable_1, enable_2, enable_3, enable_4, enable_5, enable_6, enable_7, enable_8,
             enable_9, enable_10, enable_11, enable_12, enable_13, enable_14, enable_15,
             enable_16, enable_17, enable_18, enable_19, enable_20, enable_21, enable_22,
             enable_23, enable_24, enable_25, enable_26, enable_27, enable_28, enable_29,
             enable_30, enable_31, enable_32, enable_33, enable_34};
        end
    end

    // JPEG bitstream output (consolidated)
    always_ff @(posedge clk) begin
        if (rst) JPEG_bitstream <= 0;
        else begin
            for (int i = 31; i >= 0; i--) begin
                if (br_7 & rollover_6)
                    JPEG_bitstream[i] <= jpeg_6[i];
                else if (br_6 && static_orc_6 <= (31 - i))
                    JPEG_bitstream[i] <= jpeg_6[i];
            end
        end
    end

    always_ff @(posedge clk) begin
        if (rst) jpeg_6 <= 0;
        else if (br_5 | br_6) begin
            for (int i = 31; i >= 0; i--)
                jpeg_6[i] <= (rollover_5 && static_orc_5 > (31 - i)) ? jpeg_ro_5[i] : jpeg_5[i];
        end
    end

endmodule
