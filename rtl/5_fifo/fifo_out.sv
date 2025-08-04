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

module fifo_out(
    input logic clk,
    input logic rst,
    input logic enable,
    input logic [23:0] data_in,
    output logic [31:0] JPEG_bitstream,
    output logic data_ready,
    output logic [4:0] orc_reg
);

logic [31:0] cb_JPEG_bitstream, cr_JPEG_bitstream, y_JPEG_bitstream;
logic [4:0] cr_orc, cb_orc, y_orc;
logic [31:0] y_bits_out;
logic y_out_enable;
logic cb_data_ready, cr_data_ready, y_data_ready;
logic end_of_block_output, y_eob_empty;
logic cb_eob_empty, cr_eob_empty;
logic y_fifo_empty;

logic [4:0] orc, orc_cb, orc_cr, old_orc_reg, sorc_reg, roll_orc_reg;
logic [4:0] orc_1, orc_2, orc_3, orc_4, orc_5, orc_reg_delay;
logic [4:0] static_orc_1, static_orc_2, static_orc_3, static_orc_4, static_orc_5;
logic [4:0] static_orc_6;
logic [4:0] edge_ro_1, edge_ro_2, edge_ro_3, edge_ro_4, edge_ro_5;
logic [31:0] jpeg_ro_1, jpeg_ro_2, jpeg_ro_3, jpeg_ro_4, jpeg_ro_5, jpeg_delay;
logic [31:0] jpeg, jpeg_1, jpeg_2, jpeg_3, jpeg_4, jpeg_5, jpeg_6;
logic [4:0] cr_orc_1, cb_orc_1, y_orc_1;
logic cr_out_enable_1, cb_out_enable_1, y_out_enable_1, eob_1;
logic eob_2, eob_3, eob_4;
logic enable_1, enable_2, enable_3, enable_4, enable_5;
logic enable_6, enable_7, enable_8, enable_9, enable_10;
logic enable_11, enable_12, enable_13, enable_14, enable_15;
logic enable_16, enable_17, enable_18, enable_19, enable_20;
logic enable_21, enable_22, enable_23, enable_24, enable_25;
logic enable_26, enable_27, enable_28, enable_29, enable_30;
logic enable_31, enable_32, enable_33, enable_34, enable_35;
logic [2:0] bits_mux, old_orc_mux, read_mux;
logic bits_ready, br_1, br_2, br_3, br_4, br_5, br_6, br_7, br_8;
logic rollover, rollover_1, rollover_2, rollover_3, rollover_eob;
logic rollover_4, rollover_5, rollover_6, rollover_7;
logic eobe_1, cb_read_req, cr_read_req, y_read_req;
logic eob_early_out_enable, fifo_mux;

logic [31:0] cr_bits_out1, cr_bits_out2, cb_bits_out1, cb_bits_out2;
logic cr_fifo_empty1, cr_fifo_empty2, cb_fifo_empty1, cb_fifo_empty2;
logic cr_out_enable1, cr_out_enable2, cb_out_enable1, cb_out_enable2;

logic cb_write_enable = cb_data_ready && !cb_eob_empty;
logic cr_write_enable = cr_data_ready && !cr_eob_empty;
logic y_write_enable = y_data_ready && !y_eob_empty;

logic cr_read_req1 = fifo_mux ? 1'b0 : cr_read_req;
logic cr_read_req2 = fifo_mux ? cr_read_req : 1'b0;
logic [31:0] cr_JPEG_bitstream1 = fifo_mux ? cr_JPEG_bitstream : 32'b0;
logic [31:0] cr_JPEG_bitstream2 = fifo_mux ? 32'b0 : cr_JPEG_bitstream;
logic cr_write_enable1 = fifo_mux && cr_write_enable;
logic cr_write_enable2 = !fifo_mux && cr_write_enable;
logic [31:0] cr_bits_out = fifo_mux ? cr_bits_out2 : cr_bits_out1;
logic cr_fifo_empty = fifo_mux ? cr_fifo_empty2 : cr_fifo_empty1;
logic cr_out_enable = fifo_mux ? cr_out_enable2 : cr_out_enable1;

logic cb_read_req1 = fifo_mux ? 1'b0 : cb_read_req;
logic cb_read_req2 = fifo_mux ? cb_read_req : 1'b0;
logic [31:0] cb_JPEG_bitstream1 = fifo_mux ? cb_JPEG_bitstream : 32'b0;
logic [31:0] cb_JPEG_bitstream2 = fifo_mux ? 32'b0 : cb_JPEG_bitstream;
logic cb_write_enable1 = fifo_mux && cb_write_enable;
logic cb_write_enable2 = !fifo_mux && cb_write_enable;
logic [31:0] cb_bits_out = fifo_mux ? cb_bits_out2 : cb_bits_out1;
logic cb_fifo_empty = fifo_mux ? cb_fifo_empty2 : cb_fifo_empty1;
logic cb_out_enable = fifo_mux ? cb_out_enable2 : cb_out_enable1;


pre_fifo u14 (
    .clk(clk),
    .rst(rst),
    .enable(enable),
    .data_in(data_in),
    .cr_JPEG_bitstream(cr_JPEG_bitstream),
    .cr_data_ready(cr_data_ready),
    .cr_orc(cr_orc),
    .cb_JPEG_bitstream(cb_JPEG_bitstream),
    .cb_data_ready(cb_data_ready),
    .cb_orc(cb_orc),
    .y_JPEG_bitstream(y_JPEG_bitstream),
    .y_data_ready(y_data_ready),
    .y_orc(y_orc),
    .y_eob_output(end_of_block_output),
    .y_eob_empty(y_eob_empty),
    .cb_eob_empty(cb_eob_empty),
    .cr_eob_empty(cr_eob_empty)
);

sync_fifo_32 u15 (
    .clk(clk),
    .rst(rst),
    .read_req(cb_read_req1),
    .write_data(cb_JPEG_bitstream1),
    .write_enable(cb_write_enable1),
    .read_data(cb_bits_out1),
    .fifo_empty(cb_fifo_empty1),
    .rdata_valid(cb_out_enable1)
);

sync_fifo_32 u25 (
    .clk(clk),
    .rst(rst),
    .read_req(cb_read_req2),
    .write_data(cb_JPEG_bitstream2),
    .write_enable(cb_write_enable2),
    .read_data(cb_bits_out2),
    .fifo_empty(cb_fifo_empty2),
    .rdata_valid(cb_out_enable2)
);

sync_fifo_32 u16 (
    .clk(clk),
    .rst(rst),
    .read_req(cr_read_req1),
    .write_data(cr_JPEG_bitstream1),
    .write_enable(cr_write_enable1),
    .read_data(cr_bits_out1),
    .fifo_empty(cr_fifo_empty1),
    .rdata_valid(cr_out_enable1)
);

sync_fifo_32 u24 (
    .clk(clk),
    .rst(rst),
    .read_req(cr_read_req2),
    .write_data(cr_JPEG_bitstream2),
    .write_enable(cr_write_enable2),
    .read_data(cr_bits_out2),
    .fifo_empty(cr_fifo_empty2),
    .rdata_valid(cr_out_enable2)
);

sync_fifo_32 u17 (
    .clk(clk),
    .rst(rst),
    .read_req(y_read_req),
    .write_data(y_JPEG_bitstream),
    .write_enable(y_write_enable),
    .read_data(y_bits_out),
    .fifo_empty(y_fifo_empty),
    .rdata_valid(y_out_enable)
);

always_ff @(posedge clk) begin
    if (rst) begin
        fifo_mux <= 1'b0;
    end else if (end_of_block_output) begin
        fifo_mux <= ~fifo_mux; // Toggles between 0 and 1
    end
end

always_ff @(posedge clk) begin
    if (y_fifo_empty || read_mux != 3'b001) begin
        y_read_req <= 1'b0;
    end else if (!y_fifo_empty && read_mux == 3'b001) begin
        y_read_req <= 1'b1;
    end
end

always_ff @(posedge clk) begin
    if (cb_fifo_empty || read_mux != 3'b010) begin
        cb_read_req <= 1'b0;
    end else if (!cb_fifo_empty && read_mux == 3'b010) begin
        cb_read_req <= 1'b1;
    end
end

always_ff @(posedge clk) begin
    if (cr_fifo_empty || read_mux != 3'b100) begin
        cr_read_req <= 1'b0;
    end else if (!cr_fifo_empty && read_mux == 3'b100) begin
        cr_read_req <= 1'b1;
    end
end

always_ff @(posedge clk) begin
    if (rst) begin
        br_1 <= 1'b0; br_2 <= 1'b0; br_3 <= 1'b0; br_4 <= 1'b0; br_5 <= 1'b0; br_6 <= 1'b0;
        br_7 <= 1'b0; br_8 <= 1'b0;
        static_orc_1 <= 5'b0; static_orc_2 <= 5'b0; static_orc_3 <= 5'b0;
        static_orc_4 <= 5'b0; static_orc_5 <= 5'b0; static_orc_6 <= 5'b0;
        data_ready <= 1'b0; eobe_1 <= 1'b0;
    end else begin
        br_1 <= bits_ready & !eobe_1; br_2 <= br_1; br_3 <= br_2;
        br_4 <= br_3; br_5 <= br_4; br_6 <= br_5;
        br_7 <= br_6; br_8 <= br_7;
        static_orc_1 <= sorc_reg; static_orc_2 <= static_orc_1;
        static_orc_3 <= static_orc_2; static_orc_4 <= static_orc_3;
        static_orc_5 <= static_orc_4; static_orc_6 <= static_orc_5;
        data_ready <= br_6 & rollover_5;
        eobe_1 <= y_eob_empty;
    end
end

always_ff @(posedge clk) begin
    if (rst) begin
        rollover_eob <= 1'b0;
    end else if (br_3) begin
        rollover_eob <= old_orc_reg >= roll_orc_reg;
    end
end

always_ff @(posedge clk) begin
    if (rst) begin
        rollover_1 <= 1'b0; rollover_2 <= 1'b0; rollover_3 <= 1'b0;
        rollover_4 <= 1'b0; rollover_5 <= 1'b0; rollover_6 <= 1'b0;
        rollover_7 <= 1'b0; eob_1 <= 1'b0; eob_2 <= 1'b0;
        eob_3 <= 1'b0; eob_4 <= 1'b0;
        eob_early_out_enable <= 1'b0;
    end else begin
        rollover_1 <= rollover; rollover_2 <= rollover_1;
        rollover_3 <= rollover_2;
        rollover_4 <= rollover_3 | rollover_eob;
        rollover_5 <= rollover_4; rollover_6 <= rollover_5;
        rollover_7 <= rollover_6; eob_1 <= end_of_block_output;
        eob_2 <= eob_1; eob_3 <= eob_2; eob_4 <= eob_3;
        eob_early_out_enable <= y_out_enable & y_out_enable_1 & eob_2;
    end
end

always_comb begin
    case (bits_mux)
        3'b001: rollover = y_out_enable_1 & !eob_4 & !eob_early_out_enable;
        3'b010: rollover = cb_out_enable_1 & cb_out_enable;
        3'b100: rollover = cr_out_enable_1 & cr_out_enable;
        default: rollover = y_out_enable_1 & !eob_4;
    endcase
end

always_ff @(posedge clk) begin
    if (rst) begin
        orc <= 5'b0;
    end else if (enable_20) begin
        orc <= orc_cr + cr_orc_1;
    end
end

always_ff @(posedge clk) begin
    if (rst) begin
        orc_cb <= 5'b0;
    end else if (eob_1) begin
        orc_cb <= orc + y_orc_1;
    end
end

always_ff @(posedge clk) begin
    if (rst) begin
        orc_cr <= 5'b0;
    end else if (enable_5) begin
        orc_cr <= orc_cb + cb_orc_1;
    end
end

always_ff @(posedge clk) begin
    if (rst) begin
        cr_out_enable_1 <= 1'b0; cb_out_enable_1 <= 1'b0; y_out_enable_1 <= 1'b0;
    end else begin
        cr_out_enable_1 <= cr_out_enable;
        cb_out_enable_1 <= cb_out_enable;
        y_out_enable_1 <= y_out_enable;
    end
end

always_comb begin
    case (bits_mux)
        3'b001: jpeg = y_bits_out;
        3'b010: jpeg = cb_bits_out;
        3'b100: jpeg = cr_bits_out;
        default: jpeg = y_bits_out;
    endcase
end

always_comb begin
    case (bits_mux)
        3'b001: bits_ready = y_out_enable;
        3'b010: bits_ready = cb_out_enable;
        3'b100: bits_ready = cr_out_enable;
        default: bits_ready = y_out_enable;
    endcase
end

always_comb begin
    case (bits_mux)
        3'b001: sorc_reg = orc;
        3'b010: sorc_reg = orc_cb;
        3'b100: sorc_reg = orc_cr;
        default: sorc_reg = orc;
    endcase
end

always_comb begin
    case (old_orc_mux)
        3'b001: roll_orc_reg = orc;
        3'b010: roll_orc_reg = orc_cb;
        3'b100: roll_orc_reg = orc_cr;
        default: roll_orc_reg = orc;
    endcase
end

always_comb begin
    case (bits_mux)
        3'b001: orc_reg = orc;
        3'b010: orc_reg = orc_cb;
        3'b100: orc_reg = orc_cr;
        default: orc_reg = orc;
    endcase
end

always_comb begin
    case (old_orc_mux)
        3'b001: old_orc_reg = orc_cr;
        3'b010: old_orc_reg = orc;
        3'b100: old_orc_reg = orc_cb;
        default: old_orc_reg = orc_cr;
    endcase
end

always_ff @(posedge clk) begin
    if (rst) begin
        bits_mux <= 3'b001; // Y
    end else if (enable_3) begin
        bits_mux <= 3'b010; // Cb
    end else if (enable_19) begin
        bits_mux <= 3'b100; // Cr
    end else if (enable_35) begin
        bits_mux <= 3'b001; // Y
    end
end

always_ff @(posedge clk) begin
    if (rst) begin
        old_orc_mux <= 3'b001; // Y
    end else if (enable_1) begin
        old_orc_mux <= 3'b010; // Cb
    end else if (enable_6) begin
        old_orc_mux <= 3'b100; // Cr
    end else if (enable_22) begin
        old_orc_mux <= 3'b001; // Y
    end
end

always_ff @(posedge clk) begin
    if (rst) begin
        read_mux <= 3'b001; // Y
    end else if (enable_1) begin
        read_mux <= 3'b010; // Cb
    end else if (enable_17) begin
        read_mux <= 3'b100; // Cr
    end else if (enable_33) begin
        read_mux <= 3'b001; // Y
    end
end

always_ff @(posedge clk) begin
    if (rst) begin
        cr_orc_1 <= 5'b0; cb_orc_1 <= 5'b0; y_orc_1 <= 5'b0;
    end else if (end_of_block_output) begin
        cr_orc_1 <= cr_orc;
        cb_orc_1 <= cb_orc;
        y_orc_1 <= y_orc;
    end
end

always_ff @(posedge clk) begin
    if (rst) begin
        jpeg_ro_5 <= 32'b0; edge_ro_5 <= 5'b0;
    end else if (br_5) begin
        jpeg_ro_5 <= (edge_ro_4 <= 5'd1) ? jpeg_ro_4 << 1 : jpeg_ro_4;
        edge_ro_5 <= (edge_ro_4 <= 5'd1) ? edge_ro_4 : edge_ro_4 - 5'd1;
    end
end

always_ff @(posedge clk) begin
    if (rst) begin
        jpeg_5 <= 32'b0; orc_5 <= 5'b0; jpeg_ro_4 <= 32'b0; edge_ro_4 <= 5'b0;
    end else if (br_4) begin
        jpeg_5 <= (orc_4 >= 5'd1) ? jpeg_4 >> 1 : jpeg_4;
        orc_5 <= (orc_4 >= 5'd1) ? orc_4 - 5'd1 : orc_4;
        jpeg_ro_4 <= (edge_ro_3 <= 5'd2) ? jpeg_ro_3 << 2 : jpeg_ro_3;
        edge_ro_4 <= (edge_ro_3 <= 5'd2) ? edge_ro_3 : edge_ro_3 - 5'd2;
    end
end

always_ff @(posedge clk) begin
    if (rst) begin
        jpeg_4 <= 32'b0; orc_4 <= 5'b0; jpeg_ro_3 <= 32'b0; edge_ro_3 <= 5'b0;
    end else if (br_3) begin
        jpeg_4 <= (orc_3 >= 5'd2) ? jpeg_3 >> 2 : jpeg_3;
        orc_4 <= (orc_3 >= 5'd2) ? orc_3 - 5'd2 : orc_3;
        jpeg_ro_3 <= (edge_ro_2 <= 5'd4) ? jpeg_ro_2 << 4 : jpeg_ro_2;
        edge_ro_3 <= (edge_ro_2 <= 5'd4) ? edge_ro_2 : edge_ro_2 - 5'd4;
    end
end

always_ff @(posedge clk) begin
    if (rst) begin
        jpeg_3 <= 32'b0; orc_3 <= 5'b0; jpeg_ro_2 <= 32'b0; edge_ro_2 <= 5'b0;
    end else if (br_2) begin
        jpeg_3 <= (orc_2 >= 5'd4) ? jpeg_2 >> 4 : jpeg_2;
        orc_3 <= (orc_2 >= 5'd4) ? orc_2 - 5'd4 : orc_2;
        jpeg_ro_2 <= (edge_ro_1 <= 5'd8) ? jpeg_ro_1 << 8 : jpeg_ro_1;
        edge_ro_2 <= (edge_ro_1 <= 5'd8) ? edge_ro_1 : edge_ro_1 - 5'd8;
    end
end

always_ff @(posedge clk) begin
    if (rst) begin
        jpeg_2 <= 32'b0; orc_2 <= 5'b0; jpeg_ro_1 <= 32'b0; edge_ro_1 <= 5'b0;
    end else if (br_1) begin
        jpeg_2 <= (orc_1 >= 5'd8) ? jpeg_1 >> 8 : jpeg_1;
        orc_2 <= (orc_1 >= 5'd8) ? orc_1 - 5'd8 : orc_1;
        jpeg_ro_1 <= (orc_reg_delay <= 5'd16) ? jpeg_delay << 16 : jpeg_delay;
        edge_ro_1 <= (orc_reg_delay <= 5'd16) ? orc_reg_delay : orc_reg_delay - 5'd16;
    end
end

always_ff @(posedge clk) begin
    if (rst) begin
        jpeg_1 <= 32'b0; orc_1 <= 5'b0; jpeg_delay <= 32'b0; orc_reg_delay <= 5'b0;
    end else if (bits_ready) begin
        jpeg_1 <= (orc_reg >= 5'd16) ? jpeg >> 16 : jpeg;
        orc_1 <= (orc_reg >= 5'd16) ? orc_reg - 5'd16 : orc_reg;
        jpeg_delay <= jpeg;
        orc_reg_delay <= orc_reg;
    end
end

always_ff @(posedge clk) begin
    if (rst) begin
        enable_1 <= 1'b0; enable_2 <= 1'b0; enable_3 <= 1'b0; enable_4 <= 1'b0; enable_5 <= 1'b0;
        enable_6 <= 1'b0; enable_7 <= 1'b0; enable_8 <= 1'b0; enable_9 <= 1'b0; enable_10 <= 1'b0;
        enable_11 <= 1'b0; enable_12 <= 1'b0; enable_13 <= 1'b0; enable_14 <= 1'b0; enable_15 <= 1'b0;
        enable_16 <= 1'b0; enable_17 <= 1'b0; enable_18 <= 1'b0; enable_19 <= 1'b0; enable_20 <= 1'b0;
        enable_21 <= 1'b0;
        enable_22 <= 1'b0; enable_23 <= 1'b0; enable_24 <= 1'b0; enable_25 <= 1'b0; enable_26 <= 1'b0;
        enable_27 <= 1'b0; enable_28 <= 1'b0; enable_29 <= 1'b0; enable_30 <= 1'b0;
        enable_31 <= 1'b0;
        enable_32 <= 1'b0; enable_33 <= 1'b0; enable_34 <= 1'b0; enable_35 <= 1'b0;
    end else begin
        enable_1 <= end_of_block_output; enable_2 <= enable_1;
        enable_3 <= enable_2; enable_4 <= enable_3; enable_5 <= enable_4;
        enable_6 <= enable_5; enable_7 <= enable_6; enable_8 <= enable_7;
        enable_9 <= enable_8; enable_10 <= enable_9; enable_11 <= enable_10;
        enable_12 <= enable_11; enable_13 <= enable_12; enable_14 <= enable_13;
        enable_15 <= enable_14; enable_16 <= enable_15; enable_17 <= enable_16;
        enable_18 <= enable_17; enable_19 <= enable_18; enable_20 <= enable_19;
        enable_21 <= enable_20;
        enable_22 <= enable_21; enable_23 <= enable_22; enable_24 <= enable_23;
        enable_25 <= enable_24; enable_26 <= enable_25; enable_27 <= enable_26;
        enable_28 <= enable_27; enable_29 <= enable_28; enable_30 <= enable_29;
        enable_31 <= enable_30;
        enable_32 <= enable_31; enable_33 <= enable_32; enable_34 <= enable_33;
        enable_35 <= enable_34;
    end
end

// These are better written as a single always_ff block for the entire JPEG_bitstream,
// or even a continuous assignment if the logic allows.
// For now, let's keep the original per-bit assignments for a direct translation.

always_ff @(posedge clk) begin : p_JPEG_bitstream_31
    if (rst) JPEG_bitstream[31] <= 1'b0;
    else if (br_7 & rollover_6) JPEG_bitstream[31] <= jpeg_6[31];
    else if (br_6 && static_orc_6 == 5'b0) JPEG_bitstream[31] <= jpeg_6[31];
end

always_ff @(posedge clk) begin : p_JPEG_bitstream_30
    if (rst) JPEG_bitstream[30] <= 1'b0;
    else if (br_7 & rollover_6) JPEG_bitstream[30] <= jpeg_6[30];
    else if (br_6 && static_orc_6 <= 5'd1) JPEG_bitstream[30] <= jpeg_6[30];
end

always_ff @(posedge clk) begin : p_JPEG_bitstream_29
    if (rst) JPEG_bitstream[29] <= 1'b0;
    else if (br_7 & rollover_6) JPEG_bitstream[29] <= jpeg_6[29];
    else if (br_6 && static_orc_6 <= 5'd2) JPEG_bitstream[29] <= jpeg_6[29];
end

always_ff @(posedge clk) begin : p_JPEG_bitstream_28
    if (rst) JPEG_bitstream[28] <= 1'b0;
    else if (br_7 & rollover_6) JPEG_bitstream[28] <= jpeg_6[28];
    else if (br_6 && static_orc_6 <= 5'd3) JPEG_bitstream[28] <= jpeg_6[28];
end

always_ff @(posedge clk) begin : p_JPEG_bitstream_27
    if (rst) JPEG_bitstream[27] <= 1'b0;
    else if (br_7 & rollover_6) JPEG_bitstream[27] <= jpeg_6[27];
    else if (br_6 && static_orc_6 <= 5'd4) JPEG_bitstream[27] <= jpeg_6[27];
end

always_ff @(posedge clk) begin : p_JPEG_bitstream_26
    if (rst) JPEG_bitstream[26] <= 1'b0;
    else if (br_7 & rollover_6) JPEG_bitstream[26] <= jpeg_6[26];
    else if (br_6 && static_orc_6 <= 5'd5) JPEG_bitstream[26] <= jpeg_6[26];
end

always_ff @(posedge clk) begin : p_JPEG_bitstream_25
    if (rst) JPEG_bitstream[25] <= 1'b0;
    else if (br_7 & rollover_6) JPEG_bitstream[25] <= jpeg_6[25];
    else if (br_6 && static_orc_6 <= 5'd6) JPEG_bitstream[25] <= jpeg_6[25];
end

always_ff @(posedge clk) begin : p_JPEG_bitstream_24
    if (rst) JPEG_bitstream[24] <= 1'b0;
    else if (br_7 & rollover_6) JPEG_bitstream[24] <= jpeg_6[24];
    else if (br_6 && static_orc_6 <= 5'd7) JPEG_bitstream[24] <= jpeg_6[24];
end

always_ff @(posedge clk) begin : p_JPEG_bitstream_23
    if (rst) JPEG_bitstream[23] <= 1'b0;
    else if (br_7 & rollover_6) JPEG_bitstream[23] <= jpeg_6[23];
    else if (br_6 && static_orc_6 <= 5'd8) JPEG_bitstream[23] <= jpeg_6[23];
end

always_ff @(posedge clk) begin : p_JPEG_bitstream_22
    if (rst) JPEG_bitstream[22] <= 1'b0;
    else if (br_7 & rollover_6) JPEG_bitstream[22] <= jpeg_6[22];
    else if (br_6 && static_orc_6 <= 5'd9) JPEG_bitstream[22] <= jpeg_6[22];
end

always_ff @(posedge clk) begin : p_JPEG_bitstream_21
    if (rst) JPEG_bitstream[21] <= 1'b0;
    else if (br_7 & rollover_6) JPEG_bitstream[21] <= jpeg_6[21];
    else if (br_6 && static_orc_6 <= 5'd10) JPEG_bitstream[21] <= jpeg_6[21];
end

always_ff @(posedge clk) begin : p_JPEG_bitstream_20
    if (rst) JPEG_bitstream[20] <= 1'b0;
    else if (br_7 & rollover_6) JPEG_bitstream[20] <= jpeg_6[20];
    else if (br_6 && static_orc_6 <= 5'd11) JPEG_bitstream[20] <= jpeg_6[20];
end

always_ff @(posedge clk) begin : p_JPEG_bitstream_19
    if (rst) JPEG_bitstream[19] <= 1'b0;
    else if (br_7 & rollover_6) JPEG_bitstream[19] <= jpeg_6[19];
    else if (br_6 && static_orc_6 <= 5'd12) JPEG_bitstream[19] <= jpeg_6[19];
end

always_ff @(posedge clk) begin : p_JPEG_bitstream_18
    if (rst) JPEG_bitstream[18] <= 1'b0;
    else if (br_7 & rollover_6) JPEG_bitstream[18] <= jpeg_6[18];
    else if (br_6 && static_orc_6 <= 5'd13) JPEG_bitstream[18] <= jpeg_6[18];
end

always_ff @(posedge clk) begin : p_JPEG_bitstream_17
    if (rst) JPEG_bitstream[17] <= 1'b0;
    else if (br_7 & rollover_6) JPEG_bitstream[17] <= jpeg_6[17];
    else if (br_6 && static_orc_6 <= 5'd14) JPEG_bitstream[17] <= jpeg_6[17];
end

always_ff @(posedge clk) begin : p_JPEG_bitstream_16
    if (rst) JPEG_bitstream[16] <= 1'b0;
    else if (br_7 & rollover_6) JPEG_bitstream[16] <= jpeg_6[16];
    else if (br_6 && static_orc_6 <= 5'd15) JPEG_bitstream[16] <= jpeg_6[16];
end

always_ff @(posedge clk) begin : p_JPEG_bitstream_15
    if (rst) JPEG_bitstream[15] <= 1'b0;
    else if (br_7 & rollover_6) JPEG_bitstream[15] <= jpeg_6[15];
    else if (br_6 && static_orc_6 <= 5'd16) JPEG_bitstream[15] <= jpeg_6[15];
end

always_ff @(posedge clk) begin : p_JPEG_bitstream_14
    if (rst) JPEG_bitstream[14] <= 1'b0;
    else if (br_7 & rollover_6) JPEG_bitstream[14] <= jpeg_6[14];
    else if (br_6 && static_orc_6 <= 5'd17) JPEG_bitstream[14] <= jpeg_6[14];
end

always_ff @(posedge clk) begin : p_JPEG_bitstream_13
    if (rst) JPEG_bitstream[13] <= 1'b0;
    else if (br_7 & rollover_6) JPEG_bitstream[13] <= jpeg_6[13];
    else if (br_6 && static_orc_6 <= 5'd18) JPEG_bitstream[13] <= jpeg_6[13];
end

always_ff @(posedge clk) begin : p_JPEG_bitstream_12
    if (rst) JPEG_bitstream[12] <= 1'b0;
    else if (br_7 & rollover_6) JPEG_bitstream[12] <= jpeg_6[12];
    else if (br_6 && static_orc_6 <= 5'd19) JPEG_bitstream[12] <= jpeg_6[12];
end

always_ff @(posedge clk) begin : p_JPEG_bitstream_11
    if (rst) JPEG_bitstream[11] <= 1'b0;
    else if (br_7 & rollover_6) JPEG_bitstream[11] <= jpeg_6[11];
    else if (br_6 && static_orc_6 <= 5'd20) JPEG_bitstream[11] <= jpeg_6[11];
end

always_ff @(posedge clk) begin : p_JPEG_bitstream_10
    if (rst) JPEG_bitstream[10] <= 1'b0;
    else if (br_7 & rollover_6) JPEG_bitstream[10] <= jpeg_6[10];
    else if (br_6 && static_orc_6 <= 5'd21) JPEG_bitstream[10] <= jpeg_6[10];
end

always_ff @(posedge clk) begin : p_JPEG_bitstream_9
    if (rst) JPEG_bitstream[9] <= 1'b0;
    else if (br_7 & rollover_6) JPEG_bitstream[9] <= jpeg_6[9];
    else if (br_6 && static_orc_6 <= 5'd22) JPEG_bitstream[9] <= jpeg_6[9];
end

always_ff @(posedge clk) begin : p_JPEG_bitstream_8
    if (rst) JPEG_bitstream[8] <= 1'b0;
    else if (br_7 & rollover_6) JPEG_bitstream[8] <= jpeg_6[8];
    else if (br_6 && static_orc_6 <= 5'd23) JPEG_bitstream[8] <= jpeg_6[8];
end

always_ff @(posedge clk) begin : p_JPEG_bitstream_7
    if (rst) JPEG_bitstream[7] <= 1'b0;
    else if (br_7 & rollover_6) JPEG_bitstream[7] <= jpeg_6[7];
    else if (br_6 && static_orc_6 <= 5'd24) JPEG_bitstream[7] <= jpeg_6[7];
end

always_ff @(posedge clk) begin : p_JPEG_bitstream_6
    if (rst) JPEG_bitstream[6] <= 1'b0;
    else if (br_7 & rollover_6) JPEG_bitstream[6] <= jpeg_6[6];
    else if (br_6 && static_orc_6 <= 5'd25) JPEG_bitstream[6] <= jpeg_6[6];
end

always_ff @(posedge clk) begin : p_JPEG_bitstream_5
    if (rst) JPEG_bitstream[5] <= 1'b0;
    else if (br_7 & rollover_6) JPEG_bitstream[5] <= jpeg_6[5];
    else if (br_6 && static_orc_6 <= 5'd26) JPEG_bitstream[5] <= jpeg_6[5];
end

always_ff @(posedge clk) begin : p_JPEG_bitstream_4
    if (rst) JPEG_bitstream[4] <= 1'b0;
    else if (br_7 & rollover_6) JPEG_bitstream[4] <= jpeg_6[4];
    else if (br_6 && static_orc_6 <= 5'd27) JPEG_bitstream[4] <= jpeg_6[4];
end

always_ff @(posedge clk) begin : p_JPEG_bitstream_3
    if (rst) JPEG_bitstream[3] <= 1'b0;
    else if (br_7 & rollover_6) JPEG_bitstream[3] <= jpeg_6[3];
    else if (br_6 && static_orc_6 <= 5'd28) JPEG_bitstream[3] <= jpeg_6[3];
end

always_ff @(posedge clk) begin : p_JPEG_bitstream_2
    if (rst) JPEG_bitstream[2] <= 1'b0;
    else if (br_7 & rollover_6) JPEG_bitstream[2] <= jpeg_6[2];
    else if (br_6 && static_orc_6 <= 5'd29) JPEG_bitstream[2] <= jpeg_6[2];
end

always_ff @(posedge clk) begin : p_JPEG_bitstream_1
    if (rst) JPEG_bitstream[1] <= 1'b0;
    else if (br_7 & rollover_6) JPEG_bitstream[1] <= jpeg_6[1];
    else if (br_6 && static_orc_6 <= 5'd30) JPEG_bitstream[1] <= jpeg_6[1];
end

always_ff @(posedge clk) begin : p_JPEG_bitstream_0
    if (rst) JPEG_bitstream[0] <= 1'b0;
    else if (br_7 & rollover_6) JPEG_bitstream[0] <= jpeg_6[0];
    else if (br_6 && static_orc_6 <= 5'd31) JPEG_bitstream[0] <= jpeg_6[0];
end

always_ff @(posedge clk) begin
    if (rst) begin
        jpeg_6 <= 32'b0;
    end else if (br_5 || br_6) begin
        jpeg_6[31] <= (rollover_5 && static_orc_5 > 5'd0) ? jpeg_ro_5[31] : jpeg_5[31];
        jpeg_6[30] <= (rollover_5 && static_orc_5 > 5'd1) ? jpeg_ro_5[30] : jpeg_5[30];
        jpeg_6[29] <= (rollover_5 && static_orc_5 > 5'd2) ? jpeg_ro_5[29] : jpeg_5[29];
        jpeg_6[28] <= (rollover_5 && static_orc_5 > 5'd3) ? jpeg_ro_5[28] : jpeg_5[28];
        jpeg_6[27] <= (rollover_5 && static_orc_5 > 5'd4) ? jpeg_ro_5[27] : jpeg_5[27];
        jpeg_6[26] <= (rollover_5 && static_orc_5 > 5'd5) ? jpeg_ro_5[26] : jpeg_5[26];
        jpeg_6[25] <= (rollover_5 && static_orc_5 > 5'd6) ? jpeg_ro_5[25] : jpeg_5[25];
        jpeg_6[24] <= (rollover_5 && static_orc_5 > 5'd7) ? jpeg_ro_5[24] : jpeg_5[24];
        jpeg_6[23] <= (rollover_5 && static_orc_5 > 5'd8) ? jpeg_ro_5[23] : jpeg_5[23];
        jpeg_6[22] <= (rollover_5 && static_orc_5 > 5'd9) ? jpeg_ro_5[22] : jpeg_5[22];
        jpeg_6[21] <= (rollover_5 && static_orc_5 > 5'd10) ? jpeg_ro_5[21] : jpeg_5[21];
        jpeg_6[20] <= (rollover_5 && static_orc_5 > 5'd11) ? jpeg_ro_5[20] : jpeg_5[20];
        jpeg_6[19] <= (rollover_5 && static_orc_5 > 5'd12) ? jpeg_ro_5[19] : jpeg_5[19];
        jpeg_6[18] <= (rollover_5 && static_orc_5 > 5'd13) ? jpeg_ro_5[18] : jpeg_5[18];
        jpeg_6[17] <= (rollover_5 && static_orc_5 > 5'd14) ? jpeg_ro_5[17] : jpeg_5[17];
        jpeg_6[16] <= (rollover_5 && static_orc_5 > 5'd15) ? jpeg_ro_5[16] : jpeg_5[16];
        jpeg_6[15] <= (rollover_5 && static_orc_5 > 5'd16) ? jpeg_ro_5[15] : jpeg_5[15];
        jpeg_6[14] <= (rollover_5 && static_orc_5 > 5'd17) ? jpeg_ro_5[14] : jpeg_5[14];
        jpeg_6[13] <= (rollover_5 && static_orc_5 > 5'd18) ? jpeg_ro_5[13] : jpeg_5[13];
        jpeg_6[12] <= (rollover_5 && static_orc_5 > 5'd19) ? jpeg_ro_5[12] : jpeg_5[12];
        jpeg_6[11] <= (rollover_5 && static_orc_5 > 5'd20) ? jpeg_ro_5[11] : jpeg_5[11];
        jpeg_6[10] <= (rollover_5 && static_orc_5 > 5'd21) ? jpeg_ro_5[10] : jpeg_5[10];
        jpeg_6[9] <= (rollover_5 && static_orc_5 > 5'd22) ? jpeg_ro_5[9] : jpeg_5[9];
        jpeg_6[8] <= (rollover_5 && static_orc_5 > 5'd23) ? jpeg_ro_5[8] : jpeg_5[8];
        jpeg_6[7] <= (rollover_5 && static_orc_5 > 5'd24) ? jpeg_ro_5[7] : jpeg_5[7];
        jpeg_6[6] <= (rollover_5 && static_orc_5 > 5'd25) ? jpeg_ro_5[6] : jpeg_5[6];
        jpeg_6[5] <= (rollover_5 && static_orc_5 > 5'd26) ? jpeg_ro_5[5] : jpeg_5[5];
        jpeg_6[4] <= (rollover_5 && static_orc_5 > 5'd27) ? jpeg_ro_5[4] : jpeg_5[4];
        jpeg_6[3] <= (rollover_5 && static_orc_5 > 5'd28) ? jpeg_ro_5[3] : jpeg_5[3];
        jpeg_6[2] <= (rollover_5 && static_orc_5 > 5'd29) ? jpeg_ro_5[2] : jpeg_5[2];
        jpeg_6[1] <= (rollover_5 && static_orc_5 > 5'd30) ? jpeg_ro_5[1] : jpeg_5[1];
        jpeg_6[0] <= jpeg_5[0];
    end
end

endmodule
