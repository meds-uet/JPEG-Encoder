// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// Description:
//    This testbench verifies the functionality of the `ff_checker` module,
//    which processes a JPEG bitstream to detect and handle 0xFF values by inserting
//    a 0x00 byte after each 0xFF, as required by the JPEG standard. The module ensures
//    proper bitstream formatting for downstream JPEG encoding processes.
//    The testbench generates a clock, applies reset, and feeds various test patterns
//    into the 32-bit JPEG input bitstream, including sequences with and without 0xFF values.
//
//    After waiting for the `data_ready_1` signal, the testbench prints the input
//    JPEG bitstream, the processed output bitstream (`JPEG_bitstream_1`), and other
//    output signals such as `orc_reg` and `eof_data_partial_ready` for verification.
//
// Author: Navaal Noshi
// Date: 29th July, 2025

`timescale 1ns / 100ps

module ff_checker (
    input  logic        clk,
    input  logic        rst,
    input  logic        end_of_file_signal,
    input  logic [31:0] JPEG_in,
    input  logic        data_ready_in,
    input  logic [4:0]  orc_reg_in,
    output logic [31:0] JPEG_bitstream_1,
    output logic        data_ready_1,
    output logic [4:0]  orc_reg,
    output logic        eof_data_partial_ready
);

    // Register declarations
    logic first_2bytes, second_2bytes, third_2bytes, fourth_2bytes;
    logic first_2bytes_eof, second_2bytes_eof, third_2bytes_eof;
    logic fourth_2bytes_eof, fifth_2bytes_eof, s2b, t2b;
    logic [79:0] JPEG_eof_6, JPEG_eof_7;
    logic [63:0] JPEG_5, JPEG_eof_5_1, JPEG_6, JPEG_7;
    logic [55:0] JPEG_4, JPEG_eof_3, JPEG_eof_4, JPEG_eof_5;
    logic [47:0] JPEG_3, JPEG_eof_2;
    logic [39:0] JPEG_2, JPEG_eof_1;
    logic [31:0] JPEG_1, JPEG_ro, JPEG_bitstream, JPEG_bitstream_1_reg;
    logic [31:0] JPEG_eof, JPEG_eof_ro;
    logic [31:0] JPEG_bitstream_eof;
    logic [15:0] JPEG_eof_ro_ro;
    logic [87:0] JPEG_out, JPEG_out_1, JPEG_pf;
    logic [23:0] JPEG_ro_ro;
    logic dr_in_1, dr_in_2, dr_in_3, dr_in_4, dr_in_5, dr_in_6;
    logic dr_in_7, dr_in_8;
    logic rollover, rollover_1, rollover_2, rollover_3, rollover_4, rollover_5;
    logic rollover_pf, rpf_1;
    logic [1:0] FF_count, FF_count_1, FF_eof_shift;
    logic [2:0] count_total, ct_1;
    logic [1:0] ffc_1, ffc_2, ffc_3, ffc_4, ffc_5, ffc_6, ffc_7;
    logic [1:0] ffc_postfifo, count_total_eof;
    logic [4:0] orc_input;
    logic [6:0] extra_bits_eof, extra_bits_eof_1;
    logic [90:0] read_data;
    logic [90:0] write_data;
    logic data_ready, data_ready_1_reg, write_enable, read_req, rdv_1;
    logic end_of_file_enable, eof_count_enable;
    logic eof_data_partial_ready_reg, eof_dpr_1, eof_dpr_2;
    logic end_of_file_enable_hold, eof_data_ready;
    logic eof_data_ready_1, eof_bits_1, eof_bits_2, eof_bits_3;
    logic [8:0] eof_count;
    logic fifo_empty, rdata_valid;

    // Assign outputs
    assign JPEG_bitstream_1 = JPEG_bitstream_1_reg;
    assign data_ready_1 = data_ready_1_reg;
    assign eof_data_partial_ready = eof_data_partial_ready_reg;
    assign write_data = { JPEG_out_1, ffc_7, rollover_5 };

    // FIFO instantiation
    sync_fifo_ff u18 (
        .clk(clk),
        .rst(rst),
        .read_req(read_req),
        .write_data(write_data),
        .write_enable(write_enable),
        .rollover_write(rollover_5),
        .read_data(read_data),
        .fifo_empty(fifo_empty),
        .rdata_valid(rdata_valid)
    );

    // EOF data partial ready
    always_ff @(posedge clk) begin
        if (rst)
            eof_data_partial_ready_reg <= 0;
        else if (eof_bits_1)
            eof_data_partial_ready_reg <= (extra_bits_eof_1 > 0) && (extra_bits_eof_1 < 32);
        else
            eof_data_partial_ready_reg <= eof_dpr_1;
    end

    always_ff @(posedge clk) begin
        if (rst)
            eof_dpr_1 <= 0;
        else if (eof_bits_1)
            eof_dpr_1 <= (extra_bits_eof_1 > 32) && (extra_bits_eof_1 < 64);
        else
            eof_dpr_1 <= eof_dpr_2;
    end

    always_ff @(posedge clk) begin
        if (rst)
            eof_dpr_2 <= 0;
        else if (eof_bits_1)
            eof_dpr_2 <= extra_bits_eof_1 > 64;
        else
            eof_dpr_2 <= 0;
    end

    // EOF data ready
    always_ff @(posedge clk) begin
        if (rst)
            eof_data_ready_1 <= 0;
        else if (end_of_file_enable)
            eof_data_ready_1 <= (extra_bits_eof_1 > 31);
        else if (eof_bits_1 || eof_bits_2)
            eof_data_ready_1 <= eof_data_ready;
    end

    always_ff @(posedge clk) begin
        if (rst)
            eof_data_ready <= 0;
        else if (end_of_file_enable)
            eof_data_ready <= (extra_bits_eof_1 > 63);
        else if (eof_bits_1)
            eof_data_ready <= 0;
    end

    // EOF bits pipeline
    always_ff @(posedge clk) begin
        if (rst) begin
            eof_bits_1 <= 0;
            eof_bits_2 <= 0;
            eof_bits_3 <= 0;
        end else begin
            eof_bits_1 <= end_of_file_enable;
            eof_bits_2 <= eof_bits_1;
            eof_bits_3 <= eof_bits_2;
        end
    end

    // JPEG bitstream EOF
    always_ff @(posedge clk) begin
        if (rst) begin
            JPEG_bitstream_eof <= 0;
            JPEG_eof_ro <= 0;
        end else if (end_of_file_enable) begin
            JPEG_bitstream_eof <= JPEG_eof_7[79:48];
            JPEG_eof_ro <= JPEG_eof_7[47:16];
        end else if (eof_bits_1 || eof_bits_2) begin
            JPEG_bitstream_eof <= JPEG_eof_ro;
            JPEG_eof_ro <= { JPEG_eof_ro_ro, {16{1'b0}} };
        end
    end

    always_ff @(posedge clk) begin
        if (rst)
            JPEG_eof_ro_ro <= 0;
        else if (end_of_file_enable)
            JPEG_eof_ro_ro <= JPEG_eof_7[15:0];
    end

    // EOF bitstream processing
    always_ff @(posedge clk) begin
        if (rst) begin
            JPEG_eof_7 <= 0;
            JPEG_eof_6 <= 0;
            JPEG_eof_5_1 <= 0;
            FF_eof_shift <= 0;
            FF_count_1 <= 0;
        end else begin
            JPEG_eof_7[79:72] <= (FF_count_1 > 0) ? JPEG_ro[31:24] : JPEG_eof_6[79:72];
            JPEG_eof_7[71:64] <= (FF_count_1 > 1) ? JPEG_ro[23:16] : JPEG_eof_6[71:64];
            JPEG_eof_7[63:56] <= (FF_count_1 > 2) ? JPEG_ro[15:8] : JPEG_eof_6[63:56];
            JPEG_eof_7[55:0] <= JPEG_eof_6[55:0];
            JPEG_eof_6 <= JPEG_eof_5_1 << { FF_eof_shift[1], 4'b0000 };
            JPEG_eof_5_1 <= JPEG_eof_5 << { FF_eof_shift[0], 3'b000 };
            FF_eof_shift <= 2'b11 - FF_count;
            FF_count_1 <= FF_count;
        end
    end

    // EOF bit generation
    always_ff @(posedge clk) begin
        if (rst) begin
            orc_reg <= 0;
            extra_bits_eof <= 0;
            extra_bits_eof_1 <= 0;
            count_total_eof <= 0;
            JPEG_eof_5 <= 0;
            fifth_2bytes_eof <= 0;
            JPEG_eof_4 <= 0;
            fourth_2bytes_eof <= 0;
            JPEG_eof_3 <= 0;
            third_2bytes_eof <= 0;
            JPEG_eof_2 <= 0;
            second_2bytes_eof <= 0;
            JPEG_eof_1 <= 0;
            first_2bytes_eof <= 0;
            s2b <= 0;
            t2b <= 0;
            orc_input <= 0;
        end else begin
            orc_reg <= extra_bits_eof_1[4:0];
            extra_bits_eof <= { 2'b00, orc_input } + { 2'b00, FF_count, 3'b000 };
            extra_bits_eof_1 <= extra_bits_eof + { 2'b00, count_total_eof, 3'b000 };
            count_total_eof <= first_2bytes_eof + s2b + t2b;
            JPEG_eof_5[55:16] <= JPEG_eof_4[55:16];
            JPEG_eof_5[15:8] <= fifth_2bytes_eof ? 8'b00000000 : JPEG_eof_4[15:8];
            JPEG_eof_5[7:0] <= fifth_2bytes_eof ? JPEG_eof_4[15:8] : JPEG_eof_4[7:0];
            fifth_2bytes_eof <= (JPEG_eof_4[23:16] == 8'b11111111);
            JPEG_eof_4[55:24] <= JPEG_eof_3[55:24];
            JPEG_eof_4[23:16] <= fourth_2bytes_eof ? 8'b00000000 : JPEG_eof_3[23:16];
            JPEG_eof_4[15:8] <= fourth_2bytes_eof ? JPEG_eof_3[23:16] : JPEG_eof_3[15:8];
            JPEG_eof_4[7:0] <= fourth_2bytes_eof ? JPEG_eof_3[15:8] : JPEG_eof_3[7:0];
            fourth_2bytes_eof <= (JPEG_eof_3[31:24] == 8'b11111111);
            JPEG_eof_3[55:32] <= JPEG_eof_2[47:24];
            JPEG_eof_3[31:24] <= third_2bytes_eof ? 8'b00000000 : JPEG_eof_2[23:16];
            JPEG_eof_3[23:16] <= third_2bytes_eof ? JPEG_eof_2[23:16] : JPEG_eof_2[15:8];
            JPEG_eof_3[15:8] <= third_2bytes_eof ? JPEG_eof_2[15:8] : JPEG_eof_2[7:0];
            JPEG_eof_3[7:0] <= third_2bytes_eof ? JPEG_eof_2[7:0] : 8'b00000000;
            third_2bytes_eof <= (JPEG_eof_2[31:24] == 8'b11111111);
            JPEG_eof_2[47:32] <= JPEG_eof_1[39:24];
            JPEG_eof_2[31:24] <= second_2bytes_eof ? 8'b00000000 : JPEG_eof_1[23:16];
            JPEG_eof_2[23:16] <= second_2bytes_eof ? JPEG_eof_1[23:16] : JPEG_eof_1[15:8];
            JPEG_eof_2[15:8] <= second_2bytes_eof ? JPEG_eof_1[15:8] : JPEG_eof_1[7:0];
            JPEG_eof_2[7:0] <= second_2bytes_eof ? JPEG_eof_1[7:0] : 8'b00000000;
            second_2bytes_eof <= (JPEG_eof_1[31:24] == 8'b11111111);
            JPEG_eof_1[39:32] <= JPEG_eof[31:24];
            JPEG_eof_1[31:24] <= first_2bytes_eof ? 8'b00000000 : JPEG_eof[23:16];
            JPEG_eof_1[23:16] <= first_2bytes_eof ? JPEG_eof[23:16] : JPEG_eof[15:8];
            JPEG_eof_1[15:8] <= first_2bytes_eof ? JPEG_eof[15:8] : JPEG_eof[7:0];
            JPEG_eof_1[7:0] <= first_2bytes_eof ? JPEG_eof[7:0] : 8'b00000000;
            first_2bytes_eof <= (JPEG_eof[31:24] == 8'b11111111);
            s2b <= (JPEG_eof[23:16] == 8'b11111111);
            t2b <= (JPEG_eof[15:8] == 8'b11111111);
            orc_input <= orc_reg_in;
        end
    end

    // JPEG EOF input
    always_ff @(posedge clk) begin
        if (rst) begin
            JPEG_eof <= 0;
        end else begin
            JPEG_eof[31] <= (orc_reg_in > 5'b00000) ? JPEG_in[31] : 1'b0;
            JPEG_eof[30] <= (orc_reg_in > 5'b00001) ? JPEG_in[30] : 1'b0;
            JPEG_eof[29] <= (orc_reg_in > 5'b00010) ? JPEG_in[29] : 1'b0;
            JPEG_eof[28] <= (orc_reg_in > 5'b00011) ? JPEG_in[28] : 1'b0;
            JPEG_eof[27] <= (orc_reg_in > 5'b00100) ? JPEG_in[27] : 1'b0;
            JPEG_eof[26] <= (orc_reg_in > 5'b00101) ? JPEG_in[26] : 1'b0;
            JPEG_eof[25] <= (orc_reg_in > 5'b00110) ? JPEG_in[25] : 1'b0;
            JPEG_eof[24] <= (orc_reg_in > 5'b00111) ? JPEG_in[24] : 1'b0;
            JPEG_eof[23] <= (orc_reg_in > 5'b01000) ? JPEG_in[23] : 1'b0;
            JPEG_eof[22] <= (orc_reg_in > 5'b01001) ? JPEG_in[22] : 1'b0;
            JPEG_eof[21] <= (orc_reg_in > 5'b01010) ? JPEG_in[21] : 1'b0;
            JPEG_eof[20] <= (orc_reg_in > 5'b01011) ? JPEG_in[20] : 1'b0;
            JPEG_eof[19] <= (orc_reg_in > 5'b01100) ? JPEG_in[19] : 1'b0;
            JPEG_eof[18] <= (orc_reg_in > 5'b01101) ? JPEG_in[18] : 1'b0;
            JPEG_eof[17] <= (orc_reg_in > 5'b01110) ? JPEG_in[17] : 1'b0;
            JPEG_eof[16] <= (orc_reg_in > 5'b01111) ? JPEG_in[16] : 1'b0;
            JPEG_eof[15] <= (orc_reg_in > 5'b10000) ? JPEG_in[15] : 1'b0;
            JPEG_eof[14] <= (orc_reg_in > 5'b10001) ? JPEG_in[14] : 1'b0;
            JPEG_eof[13] <= (orc_reg_in > 5'b10010) ? JPEG_in[13] : 1'b0;
            JPEG_eof[12] <= (orc_reg_in > 5'b10011) ? JPEG_in[12] : 1'b0;
            JPEG_eof[11] <= (orc_reg_in > 5'b10100) ? JPEG_in[11] : 1'b0;
            JPEG_eof[10] <= (orc_reg_in > 5'b10101) ? JPEG_in[10] : 1'b0;
            JPEG_eof[9]  <= (orc_reg_in > 5'b10110) ? JPEG_in[9]  : 1'b0;
            JPEG_eof[8]  <= (orc_reg_in > 5'b10111) ? JPEG_in[8]  : 1'b0;
            JPEG_eof[7]  <= (orc_reg_in > 5'b11000) ? JPEG_in[7]  : 1'b0;
            JPEG_eof[6]  <= (orc_reg_in > 5'b11001) ? JPEG_in[6]  : 1'b0;
            JPEG_eof[5]  <= (orc_reg_in > 5'b11010) ? JPEG_in[5]  : 1'b0;
            JPEG_eof[4]  <= (orc_reg_in > 5'b11011) ? JPEG_in[4]  : 1'b0;
            JPEG_eof[3]  <= (orc_reg_in > 5'b11100) ? JPEG_in[3]  : 1'b0;
            JPEG_eof[2]  <= (orc_reg_in > 5'b11101) ? JPEG_in[2]  : 1'b0;
            JPEG_eof[1]  <= (orc_reg_in > 5'b11110) ? JPEG_in[1]  : 1'b0;
            JPEG_eof[0]  <= 1'b0;
        end
    end

    // EOF control signals
    always_ff @(posedge clk) begin
        if (rst)
            eof_count_enable <= 0;
        else if (end_of_file_enable_hold)
            eof_count_enable <= 0;
        else if (end_of_file_signal)
            eof_count_enable <= 1;
    end

    always_ff @(posedge clk) begin
        if (rst)
            eof_count <= 0;
        else if (!eof_count_enable)
            eof_count <= 0;
        else if (eof_count_enable)
            eof_count <= eof_count + 1;
    end

    always_ff @(posedge clk) begin
        if (rst)
            end_of_file_enable <= 0;
        else if (eof_count != 9'b011110000)
            end_of_file_enable <= 0;
        else if (eof_count == 9'b011110000)
            end_of_file_enable <= 1;
    end

    always_ff @(posedge clk) begin
        if (rst)
            end_of_file_enable_hold <= 0;
        else if (end_of_file_enable)
            end_of_file_enable_hold <= 1;
    end

    // Output bitstream
    always_ff @(posedge clk) begin
        if (rst) begin
            data_ready_1_reg <= 0;
            JPEG_bitstream_1_reg <= 0;
        end else begin
            data_ready_1_reg <= data_ready || eof_data_ready_1;
            JPEG_bitstream_1_reg <= (eof_bits_1 || eof_bits_2 || eof_bits_3) ?
                                   JPEG_bitstream_eof : JPEG_bitstream;
        end
    end

    // Data ready control
    always_ff @(posedge clk) begin
        if (rst) begin
            data_ready <= 0;
            rdv_1 <= 0;
            rpf_1 <= 0;
        end else begin
            data_ready <= rdv_1 || rpf_1;
            rdv_1 <= rdata_valid;
            rpf_1 <= rollover_pf & !rpf_1;
        end
    end

    // Bitstream output generation
    always_ff @(posedge clk) begin
        if (rst)
            JPEG_bitstream[31:24] <= 0;
        else if (rdv_1 && ffc_postfifo == 0 && !rpf_1)
            JPEG_bitstream[31:24] <= JPEG_pf[87:80];
        else if (rpf_1 || (rdv_1 && ffc_postfifo > 0))
            JPEG_bitstream[31:24] <= JPEG_ro[31:24];
    end

    always_ff @(posedge clk) begin
        if (rst)
            JPEG_bitstream[23:16] <= 0;
        else if (rdv_1 && ffc_postfifo < 2 && !rpf_1)
            JPEG_bitstream[23:16] <= JPEG_pf[79:72];
        else if (rpf_1 || (rdv_1 && ffc_postfifo > 1))
            JPEG_bitstream[23:16] <= JPEG_ro[23:16];
    end

    always_ff @(posedge clk) begin
        if (rst)
            JPEG_bitstream[15:8] <= 0;
        else if (rdv_1 && ffc_postfifo < 3 && !rpf_1)
            JPEG_bitstream[15:8] <= JPEG_pf[71:64];
        else if (rpf_1 || (rdv_1 && ffc_postfifo == 3))
            JPEG_bitstream[15:8] <= JPEG_ro[15:8];
    end

    always_ff @(posedge clk) begin
        if (rst)
            JPEG_bitstream[7:0] <= 0;
        else if (rdv_1 && !rpf_1)
            JPEG_bitstream[7:0] <= JPEG_pf[63:56];
        else if (rpf_1)
            JPEG_bitstream[7:0] <= JPEG_ro[7:0];
    end

    // Rollover registers
    always_ff @(posedge clk) begin
        if (rst)
            JPEG_ro <= 0;
        else if (rdv_1 && !rpf_1)
            JPEG_ro <= JPEG_pf[55:24];
        else if (rpf_1)
            JPEG_ro[31:8] <= JPEG_ro_ro;
    end

    always_ff @(posedge clk) begin
        if (rst)
            JPEG_ro_ro <= 0;
        else if (rdv_1)
            JPEG_ro_ro <= JPEG_pf[23:0];
    end

    // FIFO read control
    always_ff @(posedge clk) begin
        if (fifo_empty)
            read_req <= 0;
        else if (!fifo_empty)
            read_req <= 1;
    end

    always_ff @(posedge clk) begin
        if (rst)
            rollover_pf <= 0;
        else if (!rdata_valid)
            rollover_pf <= 0;
        else if (rdata_valid)
            rollover_pf <= read_data[0];
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            JPEG_pf <= 0;
            ffc_postfifo <= 0;
        end else if (rdata_valid) begin
            JPEG_pf <= read_data[90:3];
            ffc_postfifo <= read_data[2:1];
        end
    end

    // FIFO write control
    always_ff @(posedge clk) begin
        if (!dr_in_8)
            write_enable <= 0;
        else if (dr_in_8)
            write_enable <= 1;
    end

    // Bitstream processing pipeline
    always_ff @(posedge clk) begin
        if (rst) begin
            JPEG_out_1 <= 0;
            ffc_7 <= 0;
        end else if (dr_in_8) begin
            JPEG_out_1 <= ffc_6[0] ? JPEG_out : JPEG_out << 8;
            ffc_7 <= ffc_6;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            JPEG_out <= 0;
            ffc_6 <= 0;
        end else if (dr_in_7) begin
            JPEG_out <= ffc_5[1] ? JPEG_7 : JPEG_7 << 16;
            ffc_6 <= ffc_5;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            JPEG_7 <= 0;
            ffc_5 <= 0;
        end else if (dr_in_6) begin
            JPEG_7[63:16] <= JPEG_6[63:16];
            JPEG_7[15:8] <= (JPEG_6[23:16] == 8'b11111111) ? 8'b00000000 : JPEG_6[15:8];
            JPEG_7[7:0] <= (JPEG_6[23:16] == 8'b11111111) ? JPEG_6[15:8] : JPEG_6[7:0];
            ffc_5 <= ffc_4;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            JPEG_6 <= 0;
            ffc_4 <= 0;
        end else if (dr_in_5) begin
            JPEG_6[63:24] <= JPEG_5[63:24];
            JPEG_6[23:16] <= (JPEG_5[31:24] == 8'b11111111) ? 8'b00000000 : JPEG_5[23:16];
            JPEG_6[15:8] <= (JPEG_5[31:24] == 8'b11111111) ? JPEG_5[23:16] : JPEG_5[15:8];
            JPEG_6[7:0] <= (JPEG_5[31:24] == 8'b11111111) ? JPEG_5[15:8] : JPEG_5[7:0];
            ffc_4 <= ffc_3;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            JPEG_5 <= 0;
            ffc_3 <= 0;
        end else if (dr_in_4) begin
            JPEG_5[63:32] <= JPEG_4[55:24];
            JPEG_5[31:24] <= (JPEG_4[31:24] == 8'b11111111) ? 8'b00000000 : JPEG_4[23:16];
            JPEG_5[23:16] <= (JPEG_4[31:24] == 8'b11111111) ? JPEG_4[23:16] : JPEG_4[15:8];
            JPEG_5[15:8] <= (JPEG_4[31:24] == 8'b11111111) ? JPEG_4[15:8] : JPEG_4[7:0];
            JPEG_5[7:0] <= (JPEG_4[31:24] == 8'b11111111) ? JPEG_4[7:0] : 8'b00000000;
            ffc_3 <= ffc_2;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            JPEG_4 <= 0;
            ffc_2 <= 0;
        end else if (dr_in_3) begin
            JPEG_4[55:32] <= JPEG_3[47:24];
            JPEG_4[31:24] <= (JPEG_3[31:24] == 8'b11111111) ? 8'b00000000 : JPEG_3[23:16];
            JPEG_4[23:16] <= (JPEG_3[31:24] == 8'b11111111) ? JPEG_3[23:16] : JPEG_3[15:8];
            JPEG_4[15:8] <= (JPEG_3[31:24] == 8'b11111111) ? JPEG_3[15:8] : JPEG_3[7:0];
            JPEG_4[7:0] <= (JPEG_3[31:24] == 8'b11111111) ? JPEG_3[7:0] : 8'b00000000;
            ffc_2 <= ffc_1;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            JPEG_3 <= 0;
            ct_1 <= 0;
            FF_count <= 0;
            ffc_1 <= 0;
        end else if (dr_in_2) begin
            JPEG_3[47:32] <= JPEG_2[39:24];
            JPEG_3[31:24] <= (JPEG_2[31:24] == 8'b11111111) ? 8'b00000000 : JPEG_2[23:16];
            JPEG_3[23:16] <= (JPEG_2[31:24] == 8'b11111111) ? JPEG_2[23:16] : JPEG_2[15:8];
            JPEG_3[15:8] <= (JPEG_2[31:24] == 8'b11111111) ? JPEG_2[15:8] : JPEG_2[7:0];
            JPEG_3[7:0] <= (JPEG_2[31:24] == 8'b11111111) ? JPEG_2[7:0] : 8'b00000000;
            ct_1 <= count_total;
            FF_count <= FF_count + count_total;
            ffc_1 <= FF_count;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            JPEG_2 <= 0;
            count_total <= 0;
        end else if (dr_in_1) begin
            JPEG_2[39:32] <= JPEG_1[31:24];
            JPEG_2[31:24] <= first_2bytes ? 8'b00000000 : JPEG_1[23:16];
            JPEG_2[23:16] <= first_2bytes ? JPEG_1[23:16] : JPEG_1[15:8];
            JPEG_2[15:8] <= first_2bytes ? JPEG_1[15:8] : JPEG_1[7:0];
            JPEG_2[7:0] <= first_2bytes ? JPEG_1[7:0] : 8'b00000000;
            count_total <= first_2bytes + second_2bytes + third_2bytes + fourth_2bytes;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            first_2bytes <= 0;
            second_2bytes <= 0;
            third_2bytes <= 0;
            fourth_2bytes <= 0;
            JPEG_1 <= 0;
        end else if (data_ready_in) begin
            first_2bytes <= JPEG_in[31:24] == 8'b11111111;
            second_2bytes <= JPEG_in[23:16] == 8'b11111111;
            third_2bytes <= JPEG_in[15:8] == 8'b11111111;
            fourth_2bytes <= JPEG_in[7:0] == 8'b11111111;
            JPEG_1 <= JPEG_in;
        end
    end

    // Rollover pipeline
    always_ff @(posedge clk) begin
        if (rst) begin
            rollover_1 <= 0;
            rollover_2 <= 0;
            rollover_3 <= 0;
            rollover_4 <= 0;
            rollover_5 <= 0;
        end else begin
            rollover_1 <= rollover;
            rollover_2 <= rollover_1;
            rollover_3 <= rollover_2;
            rollover_4 <= rollover_3;
            rollover_5 <= rollover_4;
        end
    end

    always_ff @(posedge clk) begin
        if (rst)
            rollover <= 0;
        else if (!dr_in_3)
            rollover <= 0;
        else if (dr_in_3)
            rollover <= (FF_count < ffc_1) | (ct_1 == 3'b100);
    end

    // Data ready pipeline
    always_ff @(posedge clk) begin
        if (rst) begin
            dr_in_1 <= 0;
            dr_in_2 <= 0;
            dr_in_3 <= 0;
            dr_in_4 <= 0;
            dr_in_5 <= 0;
            dr_in_6 <= 0;
            dr_in_7 <= 0;
            dr_in_8 <= 0;
        end else begin
            dr_in_1 <= data_ready_in;
            dr_in_2 <= dr_in_1;
            dr_in_3 <= dr_in_2;
            dr_in_4 <= dr_in_3;
            dr_in_5 <= dr_in_4;
            dr_in_6 <= dr_in_5;
            dr_in_7 <= dr_in_6;
            dr_in_8 <= dr_in_7;
        end
    end

endmodule
