
/* This module is the Huffman encoder.  It takes in the quantized outputs
from the quantizer, and creates the Huffman codes from these value.  The 
output from this module is the jpeg code of the actual pixel data.  The jpeg
file headers will need to be generated separately.  The Huffman codes are constant, 
and they can be changed by changing the parameters in this module. */

`timescale 1ns / 100ps
`include "cb_huff_constants.svh"
		
module cb_huff (
    input  logic         clk,
    input  logic         rst,
    input  logic         enable,

    input  logic [10:0]  Cb11, Cb12, Cb13, Cb14, Cb15, Cb16, Cb17, Cb18,
    input  logic [10:0]  Cb21, Cb22, Cb23, Cb24, Cb25, Cb26, Cb27, Cb28,
    input  logic [10:0]  Cb31, Cb32, Cb33, Cb34, Cb35, Cb36, Cb37, Cb38,
    input  logic [10:0]  Cb41, Cb42, Cb43, Cb44, Cb45, Cb46, Cb47, Cb48,
    input  logic [10:0]  Cb51, Cb52, Cb53, Cb54, Cb55, Cb56, Cb57, Cb58,
    input  logic [10:0]  Cb61, Cb62, Cb63, Cb64, Cb65, Cb66, Cb67, Cb68,
    input  logic [10:0]  Cb71, Cb72, Cb73, Cb74, Cb75, Cb76, Cb77, Cb78,
    input  logic [10:0]  Cb81, Cb82, Cb83, Cb84, Cb85, Cb86, Cb87, Cb88,

    output logic [31:0]  JPEG_bitstream,
    output logic         data_ready,
    output logic [4:0]   output_reg_count,
    output logic         end_of_block_empty
);

// All register declarations converted to SystemVerilog style

logic [7:0] block_counter;
logic [11:0] Cb11_amp, Cb11_1_pos, Cb11_1_neg, Cb11_diff;
logic [11:0] Cb11_previous, Cb11_1;

logic [10:0] Cb12_amp, Cb12_pos, Cb12_neg;
// Declaring all positional registers for AC coefficients
logic [10:0] Cb21_pos, Cb21_neg, Cb31_pos, Cb31_neg, Cb22_pos, Cb22_neg;
logic [10:0] Cb13_pos, Cb13_neg, Cb14_pos, Cb14_neg, Cb15_pos, Cb15_neg;
logic [10:0] Cb16_pos, Cb16_neg, Cb17_pos, Cb17_neg, Cb18_pos, Cb18_neg;
logic [10:0] Cb23_pos, Cb23_neg, Cb24_pos, Cb24_neg, Cb25_pos, Cb25_neg;
logic [10:0] Cb26_pos, Cb26_neg, Cb27_pos, Cb27_neg, Cb28_pos, Cb28_neg;
logic [10:0] Cb32_pos, Cb32_neg;
logic [10:0] Cb33_pos, Cb33_neg, Cb34_pos, Cb34_neg, Cb35_pos, Cb35_neg;
logic [10:0] Cb36_pos, Cb36_neg, Cb37_pos, Cb37_neg, Cb38_pos, Cb38_neg;
logic [10:0] Cb41_pos, Cb41_neg, Cb42_pos, Cb42_neg;
logic [10:0] Cb43_pos, Cb43_neg, Cb44_pos, Cb44_neg, Cb45_pos, Cb45_neg;
logic [10:0] Cb46_pos, Cb46_neg, Cb47_pos, Cb47_neg, Cb48_pos, Cb48_neg;
logic [10:0] Cb51_pos, Cb51_neg, Cb52_pos, Cb52_neg;
logic [10:0] Cb53_pos, Cb53_neg, Cb54_pos, Cb54_neg, Cb55_pos, Cb55_neg;
logic [10:0] Cb56_pos, Cb56_neg, Cb57_pos, Cb57_neg, Cb58_pos, Cb58_neg;
logic [10:0] Cb61_pos, Cb61_neg, Cb62_pos, Cb62_neg;
logic [10:0] Cb63_pos, Cb63_neg, Cb64_pos, Cb64_neg, Cb65_pos, Cb65_neg;
logic [10:0] Cb66_pos, Cb66_neg, Cb67_pos, Cb67_neg, Cb68_pos, Cb68_neg;
logic [10:0] Cb71_pos, Cb71_neg, Cb72_pos, Cb72_neg;
logic [10:0] Cb73_pos, Cb73_neg, Cb74_pos, Cb74_neg, Cb75_pos, Cb75_neg;
logic [10:0] Cb76_pos, Cb76_neg, Cb77_pos, Cb77_neg, Cb78_pos, Cb78_neg;
logic [10:0] Cb81_pos, Cb81_neg, Cb82_pos, Cb82_neg;
logic [10:0] Cb83_pos, Cb83_neg, Cb84_pos, Cb84_neg, Cb85_pos, Cb85_neg;
logic [10:0] Cb86_pos, Cb86_neg, Cb87_pos, Cb87_neg, Cb88_pos, Cb88_neg;

logic [3:0] Cb11_bits_pos, Cb11_bits_neg, Cb11_bits, Cb11_bits_1;
logic [3:0] Cb12_bits_pos, Cb12_bits_neg, Cb12_bits, Cb12_bits_1;
logic [3:0] Cb12_bits_2, Cb12_bits_3;

// Zero flags for specific AC coefficients used in encoding logic
logic Cb32_et_zero;
logic Cb33_et_zero;
logic Cb41_et_zero;
logic Cb42_et_zero;
logic Cb51_et_zero;


logic 
    Cb32_msb, Cb33_msb, Cb34_msb, Cb35_msb, Cb36_msb, Cb37_msb, Cb38_msb,
    Cb41_msb, Cb42_msb, Cb43_msb, Cb44_msb, Cb45_msb, Cb46_msb, Cb47_msb, Cb48_msb,
    Cb51_msb, Cb52_msb, Cb53_msb, Cb54_msb, Cb55_msb, Cb56_msb, Cb57_msb, Cb58_msb,
    Cb61_msb, Cb62_msb, Cb63_msb, Cb64_msb, Cb65_msb, Cb66_msb, Cb67_msb, Cb68_msb,
    Cb71_msb, Cb72_msb, Cb73_msb, Cb74_msb, Cb75_msb, Cb76_msb, Cb77_msb, Cb78_msb,
    Cb81_msb, Cb82_msb, Cb83_msb, Cb84_msb, Cb85_msb, Cb86_msb, Cb87_msb, Cb88_msb;

logic Cb11_msb, Cb12_msb, Cb12_msb_1;
logic enable_1, enable_2, enable_3, enable_4, enable_5, enable_6;
logic enable_7, enable_8, enable_9, enable_10, enable_11, enable_12;
logic enable_13, enable_module, enable_latch_7, enable_latch_8;

logic Cb12_et_zero, rollover, rollover_1, rollover_2, rollover_3;
logic rollover_4, rollover_5, rollover_6, rollover_7;

// All zero checks and MSB checks for each coefficient
logic Cb21_et_zero, Cb21_msb, Cb31_et_zero, Cb31_msb;
logic Cb22_et_zero, Cb22_msb, Cb13_et_zero, Cb13_msb;
logic Cb14_et_zero, Cb14_msb, Cb15_et_zero, Cb15_msb;
logic Cb16_et_zero, Cb16_msb, Cb17_et_zero, Cb17_msb;
logic Cb18_et_zero, Cb18_msb;

logic Cb23_et_zero, Cb23_msb, Cb24_et_zero, Cb24_msb;
logic Cb25_et_zero, Cb25_msb, Cb26_et_zero, Cb26_msb;
logic Cb27_et_zero, Cb27_msb, Cb28_et_zero, Cb28_msb;

// Helper flags to detect zero-valued coefficients
logic Cb34_et_zero, Cb43_et_zero, Cb52_et_zero, Cb61_et_zero;
logic Cb71_et_zero, Cb62_et_zero, Cb53_et_zero, Cb44_et_zero;
logic Cb35_et_zero, Cb36_et_zero, Cb45_et_zero, Cb54_et_zero;
logic Cb63_et_zero, Cb72_et_zero, Cb81_et_zero, Cb82_et_zero;
logic Cb73_et_zero, Cb64_et_zero, Cb55_et_zero, Cb46_et_zero;
logic Cb37_et_zero, Cb38_et_zero, Cb47_et_zero, Cb56_et_zero;
logic Cb65_et_zero, Cb74_et_zero, Cb83_et_zero, Cb84_et_zero;
logic Cb75_et_zero, Cb66_et_zero, Cb57_et_zero, Cb48_et_zero;
logic Cb58_et_zero, Cb67_et_zero, Cb76_et_zero, Cb85_et_zero;
logic Cb86_et_zero, Cb77_et_zero, Cb68_et_zero, Cb78_et_zero;
logic Cb87_et_zero, Cb88_et_zero;


logic Cb12_et_zero_1, Cb12_et_zero_2, Cb12_et_zero_3, Cb12_et_zero_4, Cb12_et_zero_5;


// Huffman data registers
logic [10:0] Cb11_Huff, Cb11_Huff_1, Cb11_Huff_2;
logic [15:0] Cb12_Huff, Cb12_Huff_1, Cb12_Huff_2;
logic [3:0]  Cb11_Huff_count, Cb11_Huff_shift, Cb11_Huff_shift_1, Cb11_amp_shift, Cb12_amp_shift;
logic [3:0]  Cb12_Huff_shift, Cb12_Huff_shift_1, zero_run_length, zrl_1, zrl_2, zrl_3;
logic [4:0]  Cb12_Huff_count, Cb12_Huff_count_1;
logic [4:0]  Cb11_output_count, old_orc_1, old_orc_2;
logic [4:0]  old_orc_3, old_orc_4, old_orc_5, old_orc_6, Cb12_oc_1;
logic [4:0]  orc_3, orc_4, orc_5, orc_6, orc_7, orc_8;
logic [4:0]  Cb12_output_count;
logic [4:0]  Cb12_edge, Cb12_edge_1, Cb12_edge_2, Cb12_edge_3, Cb12_edge_4;

// Bitstream data
logic [31:0] JPEG_bs, JPEG_bs_1, JPEG_bs_2, JPEG_bs_3, JPEG_bs_4, JPEG_bs_5;
logic [31:0] JPEG_Cb12_bs, JPEG_Cb12_bs_1, JPEG_Cb12_bs_2, JPEG_Cb12_bs_3, JPEG_Cb12_bs_4;
logic [31:0] JPEG_ro_bs, JPEG_ro_bs_1, JPEG_ro_bs_2, JPEG_ro_bs_3, JPEG_ro_bs_4;

logic [21:0] Cb11_JPEG_LSBs_3;
logic [10:0] Cb11_JPEG_LSBs, Cb11_JPEG_LSBs_1, Cb11_JPEG_LSBs_2;
logic [9:0]  Cb12_JPEG_LSBs, Cb12_JPEG_LSBs_1, Cb12_JPEG_LSBs_2, Cb12_JPEG_LSBs_3;
logic [25:0] Cb11_JPEG_bits, Cb11_JPEG_bits_1, Cb12_JPEG_bits, Cb12_JPEG_LSBs_4;

logic [7:0] Cb12_code_entry;
logic third_8_all_0s, fourth_8_all_0s, fifth_8_all_0s, sixth_8_all_0s, seventh_8_all_0s;
logic eighth_8_all_0s, end_of_block, end_of_block_output, code_15_0, zrl_et_15;


// Constant derived signal
logic [7:0] code_index = { zrl_2, Cb12_bits };

always_ff @(posedge clk)

begin
	if (rst) begin
		third_8_all_0s <= 0; fourth_8_all_0s <= 0;
		fifth_8_all_0s <= 0; sixth_8_all_0s <= 0; seventh_8_all_0s <= 0;
		eighth_8_all_0s <= 0;
		end
	else if (enable_1) begin
		third_8_all_0s <= Cb25_et_zero & Cb34_et_zero & Cb43_et_zero & Cb52_et_zero
					  & Cb61_et_zero & Cb71_et_zero & Cb62_et_zero & Cb53_et_zero;
		fourth_8_all_0s <= Cb44_et_zero & Cb35_et_zero & Cb26_et_zero & Cb17_et_zero
					  & Cb18_et_zero & Cb27_et_zero & Cb36_et_zero & Cb45_et_zero;
		fifth_8_all_0s <= Cb54_et_zero & Cb63_et_zero & Cb72_et_zero & Cb81_et_zero
					  & Cb82_et_zero & Cb73_et_zero & Cb64_et_zero & Cb55_et_zero;
		sixth_8_all_0s <= Cb46_et_zero & Cb37_et_zero & Cb28_et_zero & Cb38_et_zero
					  & Cb47_et_zero & Cb56_et_zero & Cb65_et_zero & Cb74_et_zero;
		seventh_8_all_0s <= Cb83_et_zero & Cb84_et_zero & Cb75_et_zero & Cb66_et_zero
					  & Cb57_et_zero & Cb48_et_zero & Cb58_et_zero & Cb67_et_zero;
		eighth_8_all_0s <= Cb76_et_zero & Cb85_et_zero & Cb86_et_zero & Cb77_et_zero
					  & Cb68_et_zero & Cb78_et_zero & Cb87_et_zero & Cb88_et_zero;						  			  
		end
end	 


/* end_of_block checks to see if there are any nonzero elements left in the block
If there aren't any nonzero elements left, then the last bits in the JPEG stream
will be the end of block code.  The purpose of this register is to determine if the
zero run length code 15-0 should be used or not.  It should be used if there are 15 or more
zeros in a row, followed by a nonzero value.  If there are only zeros left in the block,
then end_of_block will be 1.  If there are any nonzero values left in the block, end_of_block 
will be 0. */

always_ff @(posedge clk)
begin
	if (rst) 
		end_of_block <= 0;
	else if (enable)
		end_of_block <= 0;
	else if (enable_module & block_counter < 32)
		end_of_block <= third_8_all_0s & fourth_8_all_0s & fifth_8_all_0s
					& sixth_8_all_0s & seventh_8_all_0s & eighth_8_all_0s;
	else if (enable_module & block_counter < 48)
		end_of_block <= fifth_8_all_0s & sixth_8_all_0s & seventh_8_all_0s 
					& eighth_8_all_0s;
	else if (enable_module & block_counter <= 64)
		end_of_block <= seventh_8_all_0s & eighth_8_all_0s;
	else if (enable_module & block_counter > 64)
		end_of_block <= 1;
end	 

always_ff @(posedge clk)
begin
	if (rst) begin
		block_counter <= 0;
		end
	else if (enable) begin
		block_counter <= 0;
		end	
	else if (enable_module) begin
		block_counter <= block_counter + 1;
		end
end	 

always_ff @(posedge clk)
begin
	if (rst) begin
		output_reg_count <= 0;
		end
	else if (end_of_block_output) begin
		output_reg_count <= 0;
		end
	else if (enable_6) begin
		output_reg_count <= output_reg_count + Cb11_output_count;
		end	
	else if (enable_latch_7) begin
		output_reg_count <= output_reg_count + Cb12_oc_1;
		end
end	 

always_ff @(posedge clk)
begin
	if (rst) begin
		old_orc_1 <= 0;
		end
	else if (end_of_block_output) begin
		old_orc_1 <= 0;
		end
	else if (enable_module) begin
		old_orc_1 <= output_reg_count;
		end
end

always_ff @(posedge clk)
begin
	if (rst) begin
		rollover <= 0; rollover_1 <= 0; rollover_2 <= 0;
		rollover_3 <= 0; rollover_4 <= 0; rollover_5 <= 0;
		rollover_6 <= 0; rollover_7 <= 0;
		old_orc_2 <= 0; 
		orc_3 <= 0; orc_4 <= 0; orc_5 <= 0; orc_6 <= 0; 
		orc_7 <= 0; orc_8 <= 0; data_ready <= 0;
		end_of_block_output <= 0; end_of_block_empty <= 0;
		end
	else if (enable_module) begin
		rollover <= (old_orc_1 > output_reg_count); 
		rollover_1 <= rollover;
		rollover_2 <= rollover_1;
		rollover_3 <= rollover_2;
		rollover_4 <= rollover_3;
		rollover_5 <= rollover_4;
		rollover_6 <= rollover_5;
		rollover_7 <= rollover_6;
		old_orc_2 <= old_orc_1;
		orc_3 <= old_orc_2;
		orc_4 <= orc_3; orc_5 <= orc_4;
		orc_6 <= orc_5; orc_7 <= orc_6;
		orc_8 <= orc_7;
		data_ready <= rollover_6 | block_counter == 77;
		end_of_block_output <= block_counter == 77;
		end_of_block_empty <= rollover_7 & block_counter == 77 & output_reg_count == 0;
		end
end	 

always_ff @(posedge clk) begin
	if (rst) begin
		JPEG_bs_5 <= 32'd0;
	end
	else if (enable_module) begin
		// Bits 31 down to 1 using loop
		for (int i = 31; i > 0; i--) begin
			JPEG_bs_5[i] <= (rollover_6 && orc_7 > (31 - i)) ? JPEG_ro_bs_4[i] : JPEG_bs_4[i];
		end
		// Bit 0 is always copied directly
		JPEG_bs_5[0] <= JPEG_bs_4[0];
	end
end

always_ff @(posedge clk)
begin
	if (rst) begin
		JPEG_bs_4 <= 0; JPEG_ro_bs_4 <= 0;
		end
	else if (enable_module) begin 
		JPEG_bs_4 <= (old_orc_6 == 1) ? JPEG_bs_3 >> 1 : JPEG_bs_3;
		JPEG_ro_bs_4 <= (Cb12_edge_4 <= 1) ? JPEG_ro_bs_3 << 1 : JPEG_ro_bs_3;
		end
end	

always_ff @(posedge clk)
begin
	if (rst) begin
		JPEG_bs_3 <= 0; old_orc_6 <= 0; JPEG_ro_bs_3 <= 0;
		Cb12_edge_4 <= 0; 
		end
	else if (enable_module) begin 
		JPEG_bs_3 <= (old_orc_5 >= 2) ? JPEG_bs_2 >> 2 : JPEG_bs_2;
		old_orc_6 <= (old_orc_5 >= 2) ? old_orc_5 - 2 : old_orc_5;
		JPEG_ro_bs_3 <= (Cb12_edge_3 <= 2) ? JPEG_ro_bs_2 << 2 : JPEG_ro_bs_2;
		Cb12_edge_4 <= (Cb12_edge_3 <= 2) ? Cb12_edge_3 : Cb12_edge_3 - 2;
		end
end	

always_ff @(posedge clk)
begin
	if (rst) begin
		JPEG_bs_2 <= 0; old_orc_5 <= 0; JPEG_ro_bs_2 <= 0;
		Cb12_edge_3 <= 0; 
		end
	else if (enable_module) begin 
		JPEG_bs_2 <= (old_orc_4 >= 4) ? JPEG_bs_1 >> 4 : JPEG_bs_1;
		old_orc_5 <= (old_orc_4 >= 4) ? old_orc_4 - 4 : old_orc_4;
		JPEG_ro_bs_2 <= (Cb12_edge_2 <= 4) ? JPEG_ro_bs_1 << 4 : JPEG_ro_bs_1;
		Cb12_edge_3 <= (Cb12_edge_2 <= 4) ? Cb12_edge_2 : Cb12_edge_2 - 4;
		end
end	

always_ff @(posedge clk)
begin
	if (rst) begin
		JPEG_bs_1 <= 0; old_orc_4 <= 0; JPEG_ro_bs_1 <= 0; 
		Cb12_edge_2 <= 0; 
		end
	else if (enable_module) begin 
		JPEG_bs_1 <= (old_orc_3 >= 8) ? JPEG_bs >> 8 : JPEG_bs;
		old_orc_4 <= (old_orc_3 >= 8) ? old_orc_3 - 8 : old_orc_3;
		JPEG_ro_bs_1 <= (Cb12_edge_1 <= 8) ? JPEG_ro_bs << 8 : JPEG_ro_bs;
		Cb12_edge_2 <= (Cb12_edge_1 <= 8) ? Cb12_edge_1 : Cb12_edge_1 - 8;
		end
end	

always_ff @(posedge clk)
begin
	if (rst) begin
		JPEG_bs <= 0; old_orc_3 <= 0; JPEG_ro_bs <= 0;
		Cb12_edge_1 <= 0; Cb11_JPEG_bits_1 <= 0;
		end
	else if (enable_module) begin 
		JPEG_bs <= (old_orc_2 >= 16) ? Cb11_JPEG_bits >> 10 : Cb11_JPEG_bits << 6;
		old_orc_3 <= (old_orc_2 >= 16) ? old_orc_2 - 16 : old_orc_2;
		JPEG_ro_bs <= (Cb12_edge <= 16) ? Cb11_JPEG_bits_1 << 16 : Cb11_JPEG_bits_1;
		Cb12_edge_1 <= (Cb12_edge <= 16) ? Cb12_edge : Cb12_edge - 16;
		Cb11_JPEG_bits_1 <= Cb11_JPEG_bits;
		end
end	
always_ff @(posedge clk) begin
	if (rst) begin
		Cb12_JPEG_bits <= 26'd0;
		Cb12_edge <= 0;
	end
	else if (enable_module) begin
		// Loop for bits 25 down to 10
		for (int i = 25; i >= 10; i--) begin
			Cb12_JPEG_bits[i] <= (Cb12_Huff_shift_1 >= (i - 9)) ? Cb12_JPEG_LSBs_4[i] : Cb12_Huff_2[i - 10];
		end

		// Bits 9 down to 0 are directly copied
		Cb12_JPEG_bits[9:0] <= Cb12_JPEG_LSBs_4[9:0];

		// Edge update
		Cb12_edge <= old_orc_2 + 26;
	end
end

always_ff @(posedge clk) begin
	if (rst) begin
		Cb11_JPEG_bits <= 26'd0;
	end
	else if (enable_7) begin
		// Loop for bits 25 down to 15
		for (int i = 25; i >= 15; i--) begin
			Cb11_JPEG_bits[i] <= (Cb11_Huff_shift_1 >= (i - 14)) ? Cb11_JPEG_LSBs_3[i - 4] : Cb11_Huff_2[i - 15];
		end

		// Assign bits 14 to 4 directly
		Cb11_JPEG_bits[14:4] <= Cb11_JPEG_LSBs_3[10:0];
	end
	else if (enable_latch_8) begin
		Cb11_JPEG_bits <= Cb12_JPEG_bits;
	end
end



always_ff @(posedge clk)
begin
	if (rst) begin
		Cb12_oc_1 <= 0; Cb12_JPEG_LSBs_4 <= 0;
		Cb12_Huff_2 <= 0; Cb12_Huff_shift_1 <= 0;
		end
	else if (enable_module) begin 
		Cb12_oc_1 <= (Cb12_et_zero_5 & !code_15_0 & block_counter != 67) ? 0 : 
			Cb12_bits_3 + Cb12_Huff_count_1;
		Cb12_JPEG_LSBs_4 <= Cb12_JPEG_LSBs_3 << Cb12_Huff_shift;
		Cb12_Huff_2 <= Cb12_Huff_1;
		Cb12_Huff_shift_1 <= Cb12_Huff_shift;
		end
end

always_ff @(posedge clk)
begin
	if (rst) begin
		Cb11_JPEG_LSBs_3 <= 0; Cb11_Huff_2 <= 0; 
		Cb11_Huff_shift_1 <= 0; 
		end
	else if (enable_6) begin 
		Cb11_JPEG_LSBs_3 <= Cb11_JPEG_LSBs_2 << Cb11_Huff_shift;
		Cb11_Huff_2 <= Cb11_Huff_1;
		Cb11_Huff_shift_1 <= Cb11_Huff_shift;
		end
end	


always_ff @(posedge clk)
begin
	if (rst) begin
		Cb12_Huff_shift <= 0;
		Cb12_Huff_1 <= 0; Cb12_JPEG_LSBs_3 <= 0; Cb12_bits_3 <= 0;
		Cb12_Huff_count_1 <= 0; Cb12_et_zero_5 <= 0; code_15_0 <= 0;
		end
	else if (enable_module) begin 
		Cb12_Huff_shift <= 16 - Cb12_Huff_count;
		Cb12_Huff_1 <= Cb12_Huff;
		Cb12_JPEG_LSBs_3 <= Cb12_JPEG_LSBs_2;
		Cb12_bits_3 <= Cb12_bits_2;
		Cb12_Huff_count_1 <= Cb12_Huff_count;
		Cb12_et_zero_5 <= Cb12_et_zero_4;
		code_15_0 <= zrl_et_15 & !end_of_block;
		end
end	

always_ff @(posedge clk)
begin
	if (rst) begin
		Cb11_output_count <= 0; Cb11_JPEG_LSBs_2 <= 0; Cb11_Huff_shift <= 0;
		Cb11_Huff_1 <= 0;
		end
	else if (enable_5) begin 
		Cb11_output_count <= Cb11_bits_1 + Cb11_Huff_count;
		Cb11_JPEG_LSBs_2 <= Cb11_JPEG_LSBs_1 << Cb11_amp_shift;
		Cb11_Huff_shift <= 11 - Cb11_Huff_count;
		Cb11_Huff_1 <= Cb11_Huff;
		end
end	


always_ff @(posedge clk)
begin
	if (rst) begin
		Cb12_JPEG_LSBs_2 <= 0;
		Cb12_Huff <= 0; Cb12_Huff_count <= 0; Cb12_bits_2 <= 0;
		Cb12_et_zero_4 <= 0; zrl_et_15 <= 0; zrl_3 <= 0;
		end
	else if (enable_module) begin
		Cb12_JPEG_LSBs_2 <= Cb12_JPEG_LSBs_1 << Cb12_amp_shift;
		Cb12_Huff <= Cb_AC[Cb12_code_entry];
		Cb12_Huff_count <= Cb_AC_code_length[Cb12_code_entry];
		Cb12_bits_2 <= Cb12_bits_1;
		Cb12_et_zero_4 <= Cb12_et_zero_3;
		zrl_et_15 <= zrl_3 == 15;
		zrl_3 <= zrl_2;
		end
end	

always_ff @(posedge clk)
begin
	if (rst) begin
		Cb11_Huff <= 0; Cb11_Huff_count <= 0; Cb11_amp_shift <= 0;
		Cb11_JPEG_LSBs_1 <= 0; Cb11_bits_1 <= 0; 
		end
	else if (enable_4) begin
		Cb11_Huff[10:0] <= Cb_DC[Cb11_bits];
		Cb11_Huff_count <= Cb_DC_code_length[Cb11_bits];
		Cb11_amp_shift <= 11 - Cb11_bits;
		Cb11_JPEG_LSBs_1 <= Cb11_JPEG_LSBs;
		Cb11_bits_1 <= Cb11_bits;
		end
end	

always_ff @(posedge clk)
begin
	if (rst) begin
		Cb12_code_entry <= 0; Cb12_JPEG_LSBs_1 <= 0; Cb12_amp_shift <= 0; 
		Cb12_bits_1 <= 0; Cb12_et_zero_3 <= 0; zrl_2 <= 0;
		end
	else if (enable_module) begin
		Cb12_code_entry <= Cb_AC_run_code[code_index];
		Cb12_JPEG_LSBs_1 <= Cb12_JPEG_LSBs;
		Cb12_amp_shift <= 10 - Cb12_bits;
		Cb12_bits_1 <= Cb12_bits;
		Cb12_et_zero_3 <= Cb12_et_zero_2;
		zrl_2 <= zrl_1;
		end
end	

always_ff @(posedge clk)
begin
	if (rst) begin
		Cb11_bits <= 0; Cb11_JPEG_LSBs <= 0; 
		end
	else if (enable_3) begin
		Cb11_bits <= Cb11_msb ? Cb11_bits_neg : Cb11_bits_pos;
		Cb11_JPEG_LSBs <= Cb11_amp[10:0]; // The top bit of Cb11_amp is the sign bit
		end
end	

always_ff @(posedge clk)
begin
	if (rst) begin
		Cb12_bits <= 0; Cb12_JPEG_LSBs <= 0; zrl_1 <= 0;
		Cb12_et_zero_2 <= 0;
		end
	else if (enable_module) begin 
		Cb12_bits <= Cb12_msb_1 ? Cb12_bits_neg : Cb12_bits_pos;
		Cb12_JPEG_LSBs <= Cb12_amp[9:0]; // The top bit of Cb12_amp is the sign bit
		zrl_1 <= block_counter == 62 & Cb12_et_zero ? 0 : zero_run_length;
		Cb12_et_zero_2 <= Cb12_et_zero_1;
		end
end	

// Cb11_amp is the amplitude that will be represented in bits in the 
// JPEG code, following the run length code
always_ff @(posedge clk)
begin
	if (rst) begin
		Cb11_amp <= 0;
		end
	else if (enable_2) begin 
		Cb11_amp <= Cb11_msb ? Cb11_1_neg : Cb11_1_pos;
		end
end	


always_ff @(posedge clk)
begin
	if (rst) 
		zero_run_length <= 0; 
	else if (enable)
		zero_run_length <= 0; 
	else if (enable_module) 
		zero_run_length <= Cb12_et_zero ? zero_run_length + 1: 0;
end	 

always_ff @(posedge clk)
begin
	if (rst) begin
		Cb12_amp <= 0;  
		Cb12_et_zero_1 <= 0; Cb12_msb_1 <= 0;
		end
	else if (enable_module) begin
		Cb12_amp <= Cb12_msb ? Cb12_neg : Cb12_pos;
		Cb12_et_zero_1 <= Cb12_et_zero;
		Cb12_msb_1 <= Cb12_msb;
		end
end	 
	
always_ff @(posedge clk)
begin
	if (rst) begin
		Cb11_1_pos <= 0; Cb11_1_neg <= 0; Cb11_msb <= 0;
		Cb11_previous <= 0; 
		end
	else if (enable_1) begin
		Cb11_1_pos <= Cb11_diff;
		Cb11_1_neg <= Cb11_diff - 1;
		Cb11_msb <= Cb11_diff[11];
		Cb11_previous <= Cb11_1;
		end
end	 

always_ff @(posedge clk)
begin
	if (rst) begin 
		Cb12_pos <= 0; Cb12_neg <= 0; Cb12_msb <= 0; Cb12_et_zero <= 0; 
		Cb13_pos <= 0; Cb13_neg <= 0; Cb13_msb <= 0; Cb13_et_zero <= 0;
		Cb14_pos <= 0; Cb14_neg <= 0; Cb14_msb <= 0; Cb14_et_zero <= 0; 
		Cb15_pos <= 0; Cb15_neg <= 0; Cb15_msb <= 0; Cb15_et_zero <= 0;
		Cb16_pos <= 0; Cb16_neg <= 0; Cb16_msb <= 0; Cb16_et_zero <= 0; 
		Cb17_pos <= 0; Cb17_neg <= 0; Cb17_msb <= 0; Cb17_et_zero <= 0;
		Cb18_pos <= 0; Cb18_neg <= 0; Cb18_msb <= 0; Cb18_et_zero <= 0; 
		Cb21_pos <= 0; Cb21_neg <= 0; Cb21_msb <= 0; Cb21_et_zero <= 0;
		Cb22_pos <= 0; Cb22_neg <= 0; Cb22_msb <= 0; Cb22_et_zero <= 0; 
		Cb23_pos <= 0; Cb23_neg <= 0; Cb23_msb <= 0; Cb23_et_zero <= 0;
		Cb24_pos <= 0; Cb24_neg <= 0; Cb24_msb <= 0; Cb24_et_zero <= 0; 
		Cb25_pos <= 0; Cb25_neg <= 0; Cb25_msb <= 0; Cb25_et_zero <= 0;
		Cb26_pos <= 0; Cb26_neg <= 0; Cb26_msb <= 0; Cb26_et_zero <= 0; 
		Cb27_pos <= 0; Cb27_neg <= 0; Cb27_msb <= 0; Cb27_et_zero <= 0;
		Cb28_pos <= 0; Cb28_neg <= 0; Cb28_msb <= 0; Cb28_et_zero <= 0; 
		Cb31_pos <= 0; Cb31_neg <= 0; Cb31_msb <= 0; Cb31_et_zero <= 0;  
		Cb32_pos <= 0; Cb32_neg <= 0; Cb32_msb <= 0; Cb32_et_zero <= 0; 
		Cb33_pos <= 0; Cb33_neg <= 0; Cb33_msb <= 0; Cb33_et_zero <= 0;
		Cb34_pos <= 0; Cb34_neg <= 0; Cb34_msb <= 0; Cb34_et_zero <= 0; 
		Cb35_pos <= 0; Cb35_neg <= 0; Cb35_msb <= 0; Cb35_et_zero <= 0;
		Cb36_pos <= 0; Cb36_neg <= 0; Cb36_msb <= 0; Cb36_et_zero <= 0; 
		Cb37_pos <= 0; Cb37_neg <= 0; Cb37_msb <= 0; Cb37_et_zero <= 0;
		Cb38_pos <= 0; Cb38_neg <= 0; Cb38_msb <= 0; Cb38_et_zero <= 0;
		Cb41_pos <= 0; Cb41_neg <= 0; Cb41_msb <= 0; Cb41_et_zero <= 0;  
		Cb42_pos <= 0; Cb42_neg <= 0; Cb42_msb <= 0; Cb42_et_zero <= 0; 
		Cb43_pos <= 0; Cb43_neg <= 0; Cb43_msb <= 0; Cb43_et_zero <= 0;
		Cb44_pos <= 0; Cb44_neg <= 0; Cb44_msb <= 0; Cb44_et_zero <= 0; 
		Cb45_pos <= 0; Cb45_neg <= 0; Cb45_msb <= 0; Cb45_et_zero <= 0;
		Cb46_pos <= 0; Cb46_neg <= 0; Cb46_msb <= 0; Cb46_et_zero <= 0; 
		Cb47_pos <= 0; Cb47_neg <= 0; Cb47_msb <= 0; Cb47_et_zero <= 0;
		Cb48_pos <= 0; Cb48_neg <= 0; Cb48_msb <= 0; Cb48_et_zero <= 0;
		Cb51_pos <= 0; Cb51_neg <= 0; Cb51_msb <= 0; Cb51_et_zero <= 0;  
		Cb52_pos <= 0; Cb52_neg <= 0; Cb52_msb <= 0; Cb52_et_zero <= 0; 
		Cb53_pos <= 0; Cb53_neg <= 0; Cb53_msb <= 0; Cb53_et_zero <= 0;
		Cb54_pos <= 0; Cb54_neg <= 0; Cb54_msb <= 0; Cb54_et_zero <= 0; 
		Cb55_pos <= 0; Cb55_neg <= 0; Cb55_msb <= 0; Cb55_et_zero <= 0;
		Cb56_pos <= 0; Cb56_neg <= 0; Cb56_msb <= 0; Cb56_et_zero <= 0; 
		Cb57_pos <= 0; Cb57_neg <= 0; Cb57_msb <= 0; Cb57_et_zero <= 0;
		Cb58_pos <= 0; Cb58_neg <= 0; Cb58_msb <= 0; Cb58_et_zero <= 0;
		Cb61_pos <= 0; Cb61_neg <= 0; Cb61_msb <= 0; Cb61_et_zero <= 0;  
		Cb62_pos <= 0; Cb62_neg <= 0; Cb62_msb <= 0; Cb62_et_zero <= 0; 
		Cb63_pos <= 0; Cb63_neg <= 0; Cb63_msb <= 0; Cb63_et_zero <= 0;
		Cb64_pos <= 0; Cb64_neg <= 0; Cb64_msb <= 0; Cb64_et_zero <= 0; 
		Cb65_pos <= 0; Cb65_neg <= 0; Cb65_msb <= 0; Cb65_et_zero <= 0;
		Cb66_pos <= 0; Cb66_neg <= 0; Cb66_msb <= 0; Cb66_et_zero <= 0; 
		Cb67_pos <= 0; Cb67_neg <= 0; Cb67_msb <= 0; Cb67_et_zero <= 0;
		Cb68_pos <= 0; Cb68_neg <= 0; Cb68_msb <= 0; Cb68_et_zero <= 0;
		Cb71_pos <= 0; Cb71_neg <= 0; Cb71_msb <= 0; Cb71_et_zero <= 0;  
		Cb72_pos <= 0; Cb72_neg <= 0; Cb72_msb <= 0; Cb72_et_zero <= 0; 
		Cb73_pos <= 0; Cb73_neg <= 0; Cb73_msb <= 0; Cb73_et_zero <= 0;
		Cb74_pos <= 0; Cb74_neg <= 0; Cb74_msb <= 0; Cb74_et_zero <= 0; 
		Cb75_pos <= 0; Cb75_neg <= 0; Cb75_msb <= 0; Cb75_et_zero <= 0;
		Cb76_pos <= 0; Cb76_neg <= 0; Cb76_msb <= 0; Cb76_et_zero <= 0; 
		Cb77_pos <= 0; Cb77_neg <= 0; Cb77_msb <= 0; Cb77_et_zero <= 0;
		Cb78_pos <= 0; Cb78_neg <= 0; Cb78_msb <= 0; Cb78_et_zero <= 0;
		Cb81_pos <= 0; Cb81_neg <= 0; Cb81_msb <= 0; Cb81_et_zero <= 0;  
		Cb82_pos <= 0; Cb82_neg <= 0; Cb82_msb <= 0; Cb82_et_zero <= 0; 
		Cb83_pos <= 0; Cb83_neg <= 0; Cb83_msb <= 0; Cb83_et_zero <= 0;
		Cb84_pos <= 0; Cb84_neg <= 0; Cb84_msb <= 0; Cb84_et_zero <= 0; 
		Cb85_pos <= 0; Cb85_neg <= 0; Cb85_msb <= 0; Cb85_et_zero <= 0;
		Cb86_pos <= 0; Cb86_neg <= 0; Cb86_msb <= 0; Cb86_et_zero <= 0; 
		Cb87_pos <= 0; Cb87_neg <= 0; Cb87_msb <= 0; Cb87_et_zero <= 0;
		Cb88_pos <= 0; Cb88_neg <= 0; Cb88_msb <= 0; Cb88_et_zero <= 0; 
		end
	else if (enable) begin 
		Cb12_pos <= Cb12;	   
		Cb12_neg <= Cb12 - 1;
		Cb12_msb <= Cb12[10];
		Cb12_et_zero <= !(|Cb12);
		Cb13_pos <= Cb13;	   
		Cb13_neg <= Cb13 - 1;
		Cb13_msb <= Cb13[10];
		Cb13_et_zero <= !(|Cb13);
		Cb14_pos <= Cb14;	   
		Cb14_neg <= Cb14 - 1;
		Cb14_msb <= Cb14[10];
		Cb14_et_zero <= !(|Cb14);
		Cb15_pos <= Cb15;	   
		Cb15_neg <= Cb15 - 1;
		Cb15_msb <= Cb15[10];
		Cb15_et_zero <= !(|Cb15);
		Cb16_pos <= Cb16;	   
		Cb16_neg <= Cb16 - 1;
		Cb16_msb <= Cb16[10];
		Cb16_et_zero <= !(|Cb16);
		Cb17_pos <= Cb17;	   
		Cb17_neg <= Cb17 - 1;
		Cb17_msb <= Cb17[10];
		Cb17_et_zero <= !(|Cb17);
		Cb18_pos <= Cb18;	   
		Cb18_neg <= Cb18 - 1;
		Cb18_msb <= Cb18[10];
		Cb18_et_zero <= !(|Cb18);
		Cb21_pos <= Cb21;	   
		Cb21_neg <= Cb21 - 1;
		Cb21_msb <= Cb21[10];
		Cb21_et_zero <= !(|Cb21);
		Cb22_pos <= Cb22;	   
		Cb22_neg <= Cb22 - 1;
		Cb22_msb <= Cb22[10];
		Cb22_et_zero <= !(|Cb22);
		Cb23_pos <= Cb23;	   
		Cb23_neg <= Cb23 - 1;
		Cb23_msb <= Cb23[10];
		Cb23_et_zero <= !(|Cb23);
		Cb24_pos <= Cb24;	   
		Cb24_neg <= Cb24 - 1;
		Cb24_msb <= Cb24[10];
		Cb24_et_zero <= !(|Cb24);
		Cb25_pos <= Cb25;	   
		Cb25_neg <= Cb25 - 1;
		Cb25_msb <= Cb25[10];
		Cb25_et_zero <= !(|Cb25);
		Cb26_pos <= Cb26;	   
		Cb26_neg <= Cb26 - 1;
		Cb26_msb <= Cb26[10];
		Cb26_et_zero <= !(|Cb26);
		Cb27_pos <= Cb27;	   
		Cb27_neg <= Cb27 - 1;
		Cb27_msb <= Cb27[10];
		Cb27_et_zero <= !(|Cb27);
		Cb28_pos <= Cb28;	   
		Cb28_neg <= Cb28 - 1;
		Cb28_msb <= Cb28[10];
		Cb28_et_zero <= !(|Cb28);
		Cb31_pos <= Cb31;	   
		Cb31_neg <= Cb31 - 1;
		Cb31_msb <= Cb31[10];
		Cb31_et_zero <= !(|Cb31);
		Cb32_pos <= Cb32;	   
		Cb32_neg <= Cb32 - 1;
		Cb32_msb <= Cb32[10];
		Cb32_et_zero <= !(|Cb32);
		Cb33_pos <= Cb33;	   
		Cb33_neg <= Cb33 - 1;
		Cb33_msb <= Cb33[10];
		Cb33_et_zero <= !(|Cb33);
		Cb34_pos <= Cb34;	   
		Cb34_neg <= Cb34 - 1;
		Cb34_msb <= Cb34[10];
		Cb34_et_zero <= !(|Cb34);
		Cb35_pos <= Cb35;	   
		Cb35_neg <= Cb35 - 1;
		Cb35_msb <= Cb35[10];
		Cb35_et_zero <= !(|Cb35);
		Cb36_pos <= Cb36;	   
		Cb36_neg <= Cb36 - 1;
		Cb36_msb <= Cb36[10];
		Cb36_et_zero <= !(|Cb36);
		Cb37_pos <= Cb37;	   
		Cb37_neg <= Cb37 - 1;
		Cb37_msb <= Cb37[10];
		Cb37_et_zero <= !(|Cb37);
		Cb38_pos <= Cb38;	   
		Cb38_neg <= Cb38 - 1;
		Cb38_msb <= Cb38[10];
		Cb38_et_zero <= !(|Cb38);
		Cb41_pos <= Cb41;	   
		Cb41_neg <= Cb41 - 1;
		Cb41_msb <= Cb41[10];
		Cb41_et_zero <= !(|Cb41);
		Cb42_pos <= Cb42;	   
		Cb42_neg <= Cb42 - 1;
		Cb42_msb <= Cb42[10];
		Cb42_et_zero <= !(|Cb42);
		Cb43_pos <= Cb43;	   
		Cb43_neg <= Cb43 - 1;
		Cb43_msb <= Cb43[10];
		Cb43_et_zero <= !(|Cb43);
		Cb44_pos <= Cb44;	   
		Cb44_neg <= Cb44 - 1;
		Cb44_msb <= Cb44[10];
		Cb44_et_zero <= !(|Cb44);
		Cb45_pos <= Cb45;	   
		Cb45_neg <= Cb45 - 1;
		Cb45_msb <= Cb45[10];
		Cb45_et_zero <= !(|Cb45);
		Cb46_pos <= Cb46;	   
		Cb46_neg <= Cb46 - 1;
		Cb46_msb <= Cb46[10];
		Cb46_et_zero <= !(|Cb46);
		Cb47_pos <= Cb47;	   
		Cb47_neg <= Cb47 - 1;
		Cb47_msb <= Cb47[10];
		Cb47_et_zero <= !(|Cb47);
		Cb48_pos <= Cb48;	   
		Cb48_neg <= Cb48 - 1;
		Cb48_msb <= Cb48[10];
		Cb48_et_zero <= !(|Cb48);
		Cb51_pos <= Cb51;	   
		Cb51_neg <= Cb51 - 1;
		Cb51_msb <= Cb51[10];
		Cb51_et_zero <= !(|Cb51);
		Cb52_pos <= Cb52;	   
		Cb52_neg <= Cb52 - 1;
		Cb52_msb <= Cb52[10];
		Cb52_et_zero <= !(|Cb52);
		Cb53_pos <= Cb53;	   
		Cb53_neg <= Cb53 - 1;
		Cb53_msb <= Cb53[10];
		Cb53_et_zero <= !(|Cb53);
		Cb54_pos <= Cb54;	   
		Cb54_neg <= Cb54 - 1;
		Cb54_msb <= Cb54[10];
		Cb54_et_zero <= !(|Cb54);
		Cb55_pos <= Cb55;	   
		Cb55_neg <= Cb55 - 1;
		Cb55_msb <= Cb55[10];
		Cb55_et_zero <= !(|Cb55);
		Cb56_pos <= Cb56;	   
		Cb56_neg <= Cb56 - 1;
		Cb56_msb <= Cb56[10];
		Cb56_et_zero <= !(|Cb56);
		Cb57_pos <= Cb57;	   
		Cb57_neg <= Cb57 - 1;
		Cb57_msb <= Cb57[10];
		Cb57_et_zero <= !(|Cb57);
		Cb58_pos <= Cb58;	   
		Cb58_neg <= Cb58 - 1;
		Cb58_msb <= Cb58[10];
		Cb58_et_zero <= !(|Cb58);
		Cb61_pos <= Cb61;	   
		Cb61_neg <= Cb61 - 1;
		Cb61_msb <= Cb61[10];
		Cb61_et_zero <= !(|Cb61);
		Cb62_pos <= Cb62;	   
		Cb62_neg <= Cb62 - 1;
		Cb62_msb <= Cb62[10];
		Cb62_et_zero <= !(|Cb62);
		Cb63_pos <= Cb63;	   
		Cb63_neg <= Cb63 - 1;
		Cb63_msb <= Cb63[10];
		Cb63_et_zero <= !(|Cb63);
		Cb64_pos <= Cb64;	   
		Cb64_neg <= Cb64 - 1;
		Cb64_msb <= Cb64[10];
		Cb64_et_zero <= !(|Cb64);
		Cb65_pos <= Cb65;	   
		Cb65_neg <= Cb65 - 1;
		Cb65_msb <= Cb65[10];
		Cb65_et_zero <= !(|Cb65);
		Cb66_pos <= Cb66;	   
		Cb66_neg <= Cb66 - 1;
		Cb66_msb <= Cb66[10];
		Cb66_et_zero <= !(|Cb66);
		Cb67_pos <= Cb67;	   
		Cb67_neg <= Cb67 - 1;
		Cb67_msb <= Cb67[10];
		Cb67_et_zero <= !(|Cb67);
		Cb68_pos <= Cb68;	   
		Cb68_neg <= Cb68 - 1;
		Cb68_msb <= Cb68[10];
		Cb68_et_zero <= !(|Cb68);
		Cb71_pos <= Cb71;	   
		Cb71_neg <= Cb71 - 1;
		Cb71_msb <= Cb71[10];
		Cb71_et_zero <= !(|Cb71);
		Cb72_pos <= Cb72;	   
		Cb72_neg <= Cb72 - 1;
		Cb72_msb <= Cb72[10];
		Cb72_et_zero <= !(|Cb72);
		Cb73_pos <= Cb73;	   
		Cb73_neg <= Cb73 - 1;
		Cb73_msb <= Cb73[10];
		Cb73_et_zero <= !(|Cb73);
		Cb74_pos <= Cb74;	   
		Cb74_neg <= Cb74 - 1;
		Cb74_msb <= Cb74[10];
		Cb74_et_zero <= !(|Cb74);
		Cb75_pos <= Cb75;	   
		Cb75_neg <= Cb75 - 1;
		Cb75_msb <= Cb75[10];
		Cb75_et_zero <= !(|Cb75);
		Cb76_pos <= Cb76;	   
		Cb76_neg <= Cb76 - 1;
		Cb76_msb <= Cb76[10];
		Cb76_et_zero <= !(|Cb76);
		Cb77_pos <= Cb77;	   
		Cb77_neg <= Cb77 - 1;
		Cb77_msb <= Cb77[10];
		Cb77_et_zero <= !(|Cb77);
		Cb78_pos <= Cb78;	   
		Cb78_neg <= Cb78 - 1;
		Cb78_msb <= Cb78[10];
		Cb78_et_zero <= !(|Cb78);
		Cb81_pos <= Cb81;	   
		Cb81_neg <= Cb81 - 1;
		Cb81_msb <= Cb81[10];
		Cb81_et_zero <= !(|Cb81);
		Cb82_pos <= Cb82;	   
		Cb82_neg <= Cb82 - 1;
		Cb82_msb <= Cb82[10];
		Cb82_et_zero <= !(|Cb82);
		Cb83_pos <= Cb83;	   
		Cb83_neg <= Cb83 - 1;
		Cb83_msb <= Cb83[10];
		Cb83_et_zero <= !(|Cb83);
		Cb84_pos <= Cb84;	   
		Cb84_neg <= Cb84 - 1;
		Cb84_msb <= Cb84[10];
		Cb84_et_zero <= !(|Cb84);
		Cb85_pos <= Cb85;	   
		Cb85_neg <= Cb85 - 1;
		Cb85_msb <= Cb85[10];
		Cb85_et_zero <= !(|Cb85);
		Cb86_pos <= Cb86;	   
		Cb86_neg <= Cb86 - 1;
		Cb86_msb <= Cb86[10];
		Cb86_et_zero <= !(|Cb86);
		Cb87_pos <= Cb87;	   
		Cb87_neg <= Cb87 - 1;
		Cb87_msb <= Cb87[10];
		Cb87_et_zero <= !(|Cb87);
		Cb88_pos <= Cb88;	   
		Cb88_neg <= Cb88 - 1;
		Cb88_msb <= Cb88[10];
		Cb88_et_zero <= !(|Cb88);
		end
	else if (enable_module) begin 
		Cb12_pos <= Cb21_pos;	   
		Cb12_neg <= Cb21_neg;
		Cb12_msb <= Cb21_msb;
		Cb12_et_zero <= Cb21_et_zero;
		Cb21_pos <= Cb31_pos;	   
		Cb21_neg <= Cb31_neg;
		Cb21_msb <= Cb31_msb;
		Cb21_et_zero <= Cb31_et_zero;
		Cb31_pos <= Cb22_pos;	   
		Cb31_neg <= Cb22_neg;
		Cb31_msb <= Cb22_msb;
		Cb31_et_zero <= Cb22_et_zero;
		Cb22_pos <= Cb13_pos;	   
		Cb22_neg <= Cb13_neg;
		Cb22_msb <= Cb13_msb;
		Cb22_et_zero <= Cb13_et_zero;
		Cb13_pos <= Cb14_pos;	   
		Cb13_neg <= Cb14_neg;
		Cb13_msb <= Cb14_msb;
		Cb13_et_zero <= Cb14_et_zero;
		Cb14_pos <= Cb23_pos;	   
		Cb14_neg <= Cb23_neg;
		Cb14_msb <= Cb23_msb;
		Cb14_et_zero <= Cb23_et_zero;
		Cb23_pos <= Cb32_pos;	   
		Cb23_neg <= Cb32_neg;
		Cb23_msb <= Cb32_msb;
		Cb23_et_zero <= Cb32_et_zero;
		Cb32_pos <= Cb41_pos;	   
		Cb32_neg <= Cb41_neg;
		Cb32_msb <= Cb41_msb;
		Cb32_et_zero <= Cb41_et_zero;
		Cb41_pos <= Cb51_pos;	   
		Cb41_neg <= Cb51_neg;
		Cb41_msb <= Cb51_msb;
		Cb41_et_zero <= Cb51_et_zero;
		Cb51_pos <= Cb42_pos;	   
		Cb51_neg <= Cb42_neg;
		Cb51_msb <= Cb42_msb;
		Cb51_et_zero <= Cb42_et_zero;
		Cb42_pos <= Cb33_pos;	   
		Cb42_neg <= Cb33_neg;
		Cb42_msb <= Cb33_msb;
		Cb42_et_zero <= Cb33_et_zero;
		Cb33_pos <= Cb24_pos;	   
		Cb33_neg <= Cb24_neg;
		Cb33_msb <= Cb24_msb;
		Cb33_et_zero <= Cb24_et_zero;
		Cb24_pos <= Cb15_pos;	   
		Cb24_neg <= Cb15_neg;
		Cb24_msb <= Cb15_msb;
		Cb24_et_zero <= Cb15_et_zero;
		Cb15_pos <= Cb16_pos;	   
		Cb15_neg <= Cb16_neg;
		Cb15_msb <= Cb16_msb;
		Cb15_et_zero <= Cb16_et_zero;
		Cb16_pos <= Cb25_pos;	   
		Cb16_neg <= Cb25_neg;
		Cb16_msb <= Cb25_msb;
		Cb16_et_zero <= Cb25_et_zero;
		Cb25_pos <= Cb34_pos;	   
		Cb25_neg <= Cb34_neg;
		Cb25_msb <= Cb34_msb;
		Cb25_et_zero <= Cb34_et_zero;
		Cb34_pos <= Cb43_pos;	   
		Cb34_neg <= Cb43_neg;
		Cb34_msb <= Cb43_msb;
		Cb34_et_zero <= Cb43_et_zero;
		Cb43_pos <= Cb52_pos;	   
		Cb43_neg <= Cb52_neg;
		Cb43_msb <= Cb52_msb;
		Cb43_et_zero <= Cb52_et_zero;
		Cb52_pos <= Cb61_pos;	   
		Cb52_neg <= Cb61_neg;
		Cb52_msb <= Cb61_msb;
		Cb52_et_zero <= Cb61_et_zero;
		Cb61_pos <= Cb71_pos;	   
		Cb61_neg <= Cb71_neg;
		Cb61_msb <= Cb71_msb;
		Cb61_et_zero <= Cb71_et_zero;
		Cb71_pos <= Cb62_pos;	   
		Cb71_neg <= Cb62_neg;
		Cb71_msb <= Cb62_msb;
		Cb71_et_zero <= Cb62_et_zero;
		Cb62_pos <= Cb53_pos;	   
		Cb62_neg <= Cb53_neg;
		Cb62_msb <= Cb53_msb;
		Cb62_et_zero <= Cb53_et_zero;
		Cb53_pos <= Cb44_pos;	   
		Cb53_neg <= Cb44_neg;
		Cb53_msb <= Cb44_msb;
		Cb53_et_zero <= Cb44_et_zero;
		Cb44_pos <= Cb35_pos;	   
		Cb44_neg <= Cb35_neg;
		Cb44_msb <= Cb35_msb;
		Cb44_et_zero <= Cb35_et_zero;
		Cb35_pos <= Cb26_pos;	   
		Cb35_neg <= Cb26_neg;
		Cb35_msb <= Cb26_msb;
		Cb35_et_zero <= Cb26_et_zero;
		Cb26_pos <= Cb17_pos;	   
		Cb26_neg <= Cb17_neg;
		Cb26_msb <= Cb17_msb;
		Cb26_et_zero <= Cb17_et_zero;
		Cb17_pos <= Cb18_pos;	   
		Cb17_neg <= Cb18_neg;
		Cb17_msb <= Cb18_msb;
		Cb17_et_zero <= Cb18_et_zero;
		Cb18_pos <= Cb27_pos;	   
		Cb18_neg <= Cb27_neg;
		Cb18_msb <= Cb27_msb;
		Cb18_et_zero <= Cb27_et_zero;
		Cb27_pos <= Cb36_pos;	   
		Cb27_neg <= Cb36_neg;
		Cb27_msb <= Cb36_msb;
		Cb27_et_zero <= Cb36_et_zero;
		Cb36_pos <= Cb45_pos;	   
		Cb36_neg <= Cb45_neg;
		Cb36_msb <= Cb45_msb;
		Cb36_et_zero <= Cb45_et_zero;
		Cb45_pos <= Cb54_pos;	   
		Cb45_neg <= Cb54_neg;
		Cb45_msb <= Cb54_msb;
		Cb45_et_zero <= Cb54_et_zero;
		Cb54_pos <= Cb63_pos;	   
		Cb54_neg <= Cb63_neg;
		Cb54_msb <= Cb63_msb;
		Cb54_et_zero <= Cb63_et_zero;
		Cb63_pos <= Cb72_pos;	   
		Cb63_neg <= Cb72_neg;
		Cb63_msb <= Cb72_msb;
		Cb63_et_zero <= Cb72_et_zero;
		Cb72_pos <= Cb81_pos;	   
		Cb72_neg <= Cb81_neg;
		Cb72_msb <= Cb81_msb;
		Cb72_et_zero <= Cb81_et_zero;
		Cb81_pos <= Cb82_pos;	   
		Cb81_neg <= Cb82_neg;
		Cb81_msb <= Cb82_msb;
		Cb81_et_zero <= Cb82_et_zero;
		Cb82_pos <= Cb73_pos;	   
		Cb82_neg <= Cb73_neg;
		Cb82_msb <= Cb73_msb;
		Cb82_et_zero <= Cb73_et_zero;
		Cb73_pos <= Cb64_pos;	   
		Cb73_neg <= Cb64_neg;
		Cb73_msb <= Cb64_msb;
		Cb73_et_zero <= Cb64_et_zero;
		Cb64_pos <= Cb55_pos;	   
		Cb64_neg <= Cb55_neg;
		Cb64_msb <= Cb55_msb;
		Cb64_et_zero <= Cb55_et_zero;
		Cb55_pos <= Cb46_pos;	   
		Cb55_neg <= Cb46_neg;
		Cb55_msb <= Cb46_msb;
		Cb55_et_zero <= Cb46_et_zero;
		Cb46_pos <= Cb37_pos;	   
		Cb46_neg <= Cb37_neg;
		Cb46_msb <= Cb37_msb;
		Cb46_et_zero <= Cb37_et_zero;
		Cb37_pos <= Cb28_pos;	   
		Cb37_neg <= Cb28_neg;
		Cb37_msb <= Cb28_msb;
		Cb37_et_zero <= Cb28_et_zero;
		Cb28_pos <= Cb38_pos;	   
		Cb28_neg <= Cb38_neg;
		Cb28_msb <= Cb38_msb;
		Cb28_et_zero <= Cb38_et_zero;
		Cb38_pos <= Cb47_pos;	   
		Cb38_neg <= Cb47_neg;
		Cb38_msb <= Cb47_msb;
		Cb38_et_zero <= Cb47_et_zero;
		Cb47_pos <= Cb56_pos;	   
		Cb47_neg <= Cb56_neg;
		Cb47_msb <= Cb56_msb;
		Cb47_et_zero <= Cb56_et_zero;
		Cb56_pos <= Cb65_pos;	   
		Cb56_neg <= Cb65_neg;
		Cb56_msb <= Cb65_msb;
		Cb56_et_zero <= Cb65_et_zero;
		Cb65_pos <= Cb74_pos;	   
		Cb65_neg <= Cb74_neg;
		Cb65_msb <= Cb74_msb;
		Cb65_et_zero <= Cb74_et_zero;
		Cb74_pos <= Cb83_pos;	   
		Cb74_neg <= Cb83_neg;
		Cb74_msb <= Cb83_msb;
		Cb74_et_zero <= Cb83_et_zero;
		Cb83_pos <= Cb84_pos;	   
		Cb83_neg <= Cb84_neg;
		Cb83_msb <= Cb84_msb;
		Cb83_et_zero <= Cb84_et_zero;
		Cb84_pos <= Cb75_pos;	   
		Cb84_neg <= Cb75_neg;
		Cb84_msb <= Cb75_msb;
		Cb84_et_zero <= Cb75_et_zero;
		Cb75_pos <= Cb66_pos;	   
		Cb75_neg <= Cb66_neg;
		Cb75_msb <= Cb66_msb;
		Cb75_et_zero <= Cb66_et_zero;
		Cb66_pos <= Cb57_pos;	   
		Cb66_neg <= Cb57_neg;
		Cb66_msb <= Cb57_msb;
		Cb66_et_zero <= Cb57_et_zero;
		Cb57_pos <= Cb48_pos;	   
		Cb57_neg <= Cb48_neg;
		Cb57_msb <= Cb48_msb;
		Cb57_et_zero <= Cb48_et_zero;
		Cb48_pos <= Cb58_pos;	   
		Cb48_neg <= Cb58_neg;
		Cb48_msb <= Cb58_msb;
		Cb48_et_zero <= Cb58_et_zero;
		Cb58_pos <= Cb67_pos;	   
		Cb58_neg <= Cb67_neg;
		Cb58_msb <= Cb67_msb;
		Cb58_et_zero <= Cb67_et_zero;
		Cb67_pos <= Cb76_pos;	   
		Cb67_neg <= Cb76_neg;
		Cb67_msb <= Cb76_msb;
		Cb67_et_zero <= Cb76_et_zero;
		Cb76_pos <= Cb85_pos;	   
		Cb76_neg <= Cb85_neg;
		Cb76_msb <= Cb85_msb;
		Cb76_et_zero <= Cb85_et_zero;
		Cb85_pos <= Cb86_pos;	   
		Cb85_neg <= Cb86_neg;
		Cb85_msb <= Cb86_msb;
		Cb85_et_zero <= Cb86_et_zero;
		Cb86_pos <= Cb77_pos;	   
		Cb86_neg <= Cb77_neg;
		Cb86_msb <= Cb77_msb;
		Cb86_et_zero <= Cb77_et_zero;
		Cb77_pos <= Cb68_pos;	   
		Cb77_neg <= Cb68_neg;
		Cb77_msb <= Cb68_msb;
		Cb77_et_zero <= Cb68_et_zero;
		Cb68_pos <= Cb78_pos;	   
		Cb68_neg <= Cb78_neg;
		Cb68_msb <= Cb78_msb;
		Cb68_et_zero <= Cb78_et_zero;
		Cb78_pos <= Cb87_pos;	   
		Cb78_neg <= Cb87_neg;
		Cb78_msb <= Cb87_msb;
		Cb78_et_zero <= Cb87_et_zero;
		Cb87_pos <= Cb88_pos;	   
		Cb87_neg <= Cb88_neg;
		Cb87_msb <= Cb88_msb;
		Cb87_et_zero <= Cb88_et_zero;
		Cb88_pos <= 0;	   
		Cb88_neg <= 0;
		Cb88_msb <= 0;
		Cb88_et_zero <= 1;
		end
end	 

always_ff  @(posedge clk)
begin
	if (rst) begin 
		Cb11_diff <= 0; Cb11_1 <= 0; 
		end
	else if (enable) begin // Need to sign extend Cb11 to 12 bits
		Cb11_diff <= {Cb11[10], Cb11} - Cb11_previous;
		Cb11_1 <= Cb11[10] ? { 1'b1, Cb11 } : { 1'b0, Cb11 };
		end
end	 

always_ff @(posedge clk)
begin
	if (rst) 
		Cb11_bits_pos <= 0;
	else if (Cb11_1_pos[10] == 1) 
		Cb11_bits_pos <= 11;	
	else if (Cb11_1_pos[9] == 1) 
		Cb11_bits_pos <= 10;
	else if (Cb11_1_pos[8] == 1) 
		Cb11_bits_pos <= 9;
	else if (Cb11_1_pos[7] == 1) 
		Cb11_bits_pos <= 8;
	else if (Cb11_1_pos[6] == 1) 
		Cb11_bits_pos <= 7;
	else if (Cb11_1_pos[5] == 1) 
		Cb11_bits_pos <= 6;
	else if (Cb11_1_pos[4] == 1) 
		Cb11_bits_pos <= 5;
	else if (Cb11_1_pos[3] == 1) 
		Cb11_bits_pos <= 4;
	else if (Cb11_1_pos[2] == 1) 
		Cb11_bits_pos <= 3;
	else if (Cb11_1_pos[1] == 1) 
		Cb11_bits_pos <= 2;
	else if (Cb11_1_pos[0] == 1) 
		Cb11_bits_pos <= 1;
	else 
	 	Cb11_bits_pos <= 0;
end

always_ff @(posedge clk)
begin
	if (rst) 
		Cb11_bits_neg <= 0;
	else if (Cb11_1_neg[10] == 0) 
		Cb11_bits_neg <= 11;	
	else if (Cb11_1_neg[9] == 0) 
		Cb11_bits_neg <= 10;  
	else if (Cb11_1_neg[8] == 0) 
		Cb11_bits_neg <= 9;   
	else if (Cb11_1_neg[7] == 0) 
		Cb11_bits_neg <= 8;   
	else if (Cb11_1_neg[6] == 0) 
		Cb11_bits_neg <= 7;   
	else if (Cb11_1_neg[5] == 0) 
		Cb11_bits_neg <= 6;   
	else if (Cb11_1_neg[4] == 0) 
		Cb11_bits_neg <= 5;   
	else if (Cb11_1_neg[3] == 0) 
		Cb11_bits_neg <= 4;   
	else if (Cb11_1_neg[2] == 0) 
		Cb11_bits_neg <= 3;   
	else if (Cb11_1_neg[1] == 0) 
		Cb11_bits_neg <= 2;   
	else if (Cb11_1_neg[0] == 0) 
		Cb11_bits_neg <= 1;
	else 
	 	Cb11_bits_neg <= 0;
end


always_ff @(posedge clk)
begin
	if (rst) 
		Cb12_bits_pos <= 0;
	else if (Cb12_pos[9] == 1) 
		Cb12_bits_pos <= 10;
	else if (Cb12_pos[8] == 1) 
		Cb12_bits_pos <= 9;
	else if (Cb12_pos[7] == 1) 
		Cb12_bits_pos <= 8;
	else if (Cb12_pos[6] == 1) 
		Cb12_bits_pos <= 7;
	else if (Cb12_pos[5] == 1) 
		Cb12_bits_pos <= 6;
	else if (Cb12_pos[4] == 1) 
		Cb12_bits_pos <= 5;
	else if (Cb12_pos[3] == 1) 
		Cb12_bits_pos <= 4;
	else if (Cb12_pos[2] == 1) 
		Cb12_bits_pos <= 3;
	else if (Cb12_pos[1] == 1) 
		Cb12_bits_pos <= 2;
	else if (Cb12_pos[0] == 1) 
		Cb12_bits_pos <= 1;
	else 
	 	Cb12_bits_pos <= 0;
end

always_ff @(posedge clk)
begin
	if (rst) 
		Cb12_bits_neg <= 0;
	else if (Cb12_neg[9] == 0) 
		Cb12_bits_neg <= 10;  
	else if (Cb12_neg[8] == 0) 
		Cb12_bits_neg <= 9;   
	else if (Cb12_neg[7] == 0) 
		Cb12_bits_neg <= 8;   
	else if (Cb12_neg[6] == 0) 
		Cb12_bits_neg <= 7;   
	else if (Cb12_neg[5] == 0) 
		Cb12_bits_neg <= 6;   
	else if (Cb12_neg[4] == 0) 
		Cb12_bits_neg <= 5;   
	else if (Cb12_neg[3] == 0) 
		Cb12_bits_neg <= 4;   
	else if (Cb12_neg[2] == 0) 
		Cb12_bits_neg <= 3;   
	else if (Cb12_neg[1] == 0) 
		Cb12_bits_neg <= 2;   
	else if (Cb12_neg[0] == 0) 
		Cb12_bits_neg <= 1;
	else 
	 	Cb12_bits_neg <= 0;
end

always_ff @(posedge clk)
begin
	if (rst) begin
		enable_module <= 0; 
		end
	else if (enable) begin
		enable_module <= 1; 
		end
end	 

always_ff @(posedge clk)
begin
	if (rst) begin
		enable_latch_7 <= 0; 
		end
	else if (block_counter == 68)  begin
		enable_latch_7 <= 0; 
		end
	else if (enable_6) begin
		enable_latch_7 <= 1; 
		end
end	

always_ff @(posedge clk)
begin
	if (rst) begin
		enable_latch_8 <= 0; 
		end
	else if (enable_7) begin
		enable_latch_8 <= 1; 
		end
end	

always_ff @(posedge clk)
begin
	if (rst) begin
		enable_1 <= 0; enable_2 <= 0; enable_3 <= 0;
		enable_4 <= 0; enable_5 <= 0; enable_6 <= 0;
		enable_7 <= 0; enable_8 <= 0; enable_9 <= 0;
		enable_10 <= 0; enable_11 <= 0; enable_12 <= 0;
		enable_13 <= 0;
		end
	else begin
		enable_1 <= enable; enable_2 <= enable_1; enable_3 <= enable_2;
		enable_4 <= enable_3; enable_5 <= enable_4; enable_6 <= enable_5;
		enable_7 <= enable_6; enable_8 <= enable_7; enable_9 <= enable_8;
		enable_10 <= enable_9; enable_11 <= enable_10; enable_12 <= enable_11;
		enable_13 <= enable_12;
		end
end	 

/* These Cb DC and AC code lengths, run lengths, and bit codes
were created from the Huffman table entries in the JPEG file header.
For different Huffman tables for different images, these values
below will need to be changed.  I created a matlab file to automatically
create these entries from the already encoded JPEG image. This matlab program
won't be any help if you're starting from scratch with a .tif or other
raw image file format.  The values below come from a Huffman table, they
do not actually create the Huffman table based on the probabilities of
each code created from the image data.  Cbou will need another program to
create the optimal Huffman table, or you can go with a generic Huffman table,
which will have slightly less than the best compression.*/



always_ff @(posedge clk)
begin
	if (rst) 
		JPEG_bitstream[31] <= 0;
	else if (enable_module && rollover_7) 
		JPEG_bitstream[31] <= JPEG_bs_5[31];
	else if (enable_module && orc_8 == 0) 
		JPEG_bitstream[31] <= JPEG_bs_5[31];
end

always_ff @(posedge clk)
begin
	if (rst) 
		JPEG_bitstream[30] <= 0;
	else if (enable_module && rollover_7) 
		JPEG_bitstream[30] <= JPEG_bs_5[30];
	else if (enable_module && orc_8 <= 1) 
		JPEG_bitstream[30] <= JPEG_bs_5[30];
end

always_ff @(posedge clk)
begin
	if (rst) 
		JPEG_bitstream[29] <= 0;
	else if (enable_module && rollover_7)
		JPEG_bitstream[29] <= JPEG_bs_5[29];
	else if (enable_module && orc_8 <= 2) 
		JPEG_bitstream[29] <= JPEG_bs_5[29];
end

always_ff @(posedge clk)
begin
	if (rst) 
		JPEG_bitstream[28] <= 0;
	else if (enable_module && rollover_7)
		JPEG_bitstream[28] <= JPEG_bs_5[28];
	else if (enable_module && orc_8 <= 3) 
		JPEG_bitstream[28] <= JPEG_bs_5[28];
end

always_ff @(posedge clk)
begin
	if (rst) 
		JPEG_bitstream[27] <= 0;
	else if (enable_module && rollover_7)
		JPEG_bitstream[27] <= JPEG_bs_5[27];
	else if (enable_module && orc_8 <= 4) 
		JPEG_bitstream[27] <= JPEG_bs_5[27];
end

always_ff @(posedge clk)
begin
	if (rst) 
		JPEG_bitstream[26] <= 0;
	else if (enable_module && rollover_7)
		JPEG_bitstream[26] <= JPEG_bs_5[26];
	else if (enable_module && orc_8 <= 5) 
		JPEG_bitstream[26] <= JPEG_bs_5[26];
end

always_ff @(posedge clk)
begin
	if (rst) 
		JPEG_bitstream[25] <= 0;
	else if (enable_module && rollover_7)
		JPEG_bitstream[25] <= JPEG_bs_5[25];
	else if (enable_module && orc_8 <= 6) 
		JPEG_bitstream[25] <= JPEG_bs_5[25];
end

always_ff @(posedge clk)
begin
	if (rst) 
		JPEG_bitstream[24] <= 0;
	else if (enable_module && rollover_7)
		JPEG_bitstream[24] <= JPEG_bs_5[24];
	else if (enable_module && orc_8 <= 7) 
		JPEG_bitstream[24] <= JPEG_bs_5[24];
end

always_ff @(posedge clk)
begin
	if (rst) 
		JPEG_bitstream[23] <= 0;
	else if (enable_module && rollover_7)
		JPEG_bitstream[23] <= JPEG_bs_5[23];
	else if (enable_module && orc_8 <= 8) 
		JPEG_bitstream[23] <= JPEG_bs_5[23];
end

always_ff @(posedge clk)
begin
	if (rst) 
		JPEG_bitstream[22] <= 0;
	else if (enable_module && rollover_7)
		JPEG_bitstream[22] <= JPEG_bs_5[22];
	else if (enable_module && orc_8 <= 9) 
		JPEG_bitstream[22] <= JPEG_bs_5[22];
end

always_ff @(posedge clk)
begin
	if (rst) 
		JPEG_bitstream[21] <= 0;
	else if (enable_module && rollover_7)
		JPEG_bitstream[21] <= JPEG_bs_5[21];
	else if (enable_module && orc_8 <= 10) 
		JPEG_bitstream[21] <= JPEG_bs_5[21];
end

always_ff @(posedge clk)
begin
	if (rst) 
		JPEG_bitstream[20] <= 0;
	else if (enable_module && rollover_7)
		JPEG_bitstream[20] <= JPEG_bs_5[20];
	else if (enable_module && orc_8 <= 11) 
		JPEG_bitstream[20] <= JPEG_bs_5[20];
end

always_ff @(posedge clk)
begin
	if (rst) 
		JPEG_bitstream[19] <= 0;
	else if (enable_module && rollover_7)
		JPEG_bitstream[19] <= JPEG_bs_5[19];
	else if (enable_module && orc_8 <= 12) 
		JPEG_bitstream[19] <= JPEG_bs_5[19];
end

always_ff @(posedge clk)
begin
	if (rst) 
		JPEG_bitstream[18] <= 0;
	else if (enable_module && rollover_7)
		JPEG_bitstream[18] <= JPEG_bs_5[18];
	else if (enable_module && orc_8 <= 13) 
		JPEG_bitstream[18] <= JPEG_bs_5[18];
end

always_ff @(posedge clk)
begin
	if (rst) 
		JPEG_bitstream[17] <= 0;
	else if (enable_module && rollover_7)
		JPEG_bitstream[17] <= JPEG_bs_5[17];
	else if (enable_module && orc_8 <= 14) 
		JPEG_bitstream[17] <= JPEG_bs_5[17];
end

always_ff @(posedge clk)
begin
	if (rst) 
		JPEG_bitstream[16] <= 0;
	else if (enable_module && rollover_7)
		JPEG_bitstream[16] <= JPEG_bs_5[16];
	else if (enable_module && orc_8 <= 15) 
		JPEG_bitstream[16] <= JPEG_bs_5[16];
end

always_ff @(posedge clk)
begin
	if (rst) 
		JPEG_bitstream[15] <= 0;
	else if (enable_module && rollover_7)
		JPEG_bitstream[15] <= JPEG_bs_5[15];
	else if (enable_module && orc_8 <= 16) 
		JPEG_bitstream[15] <= JPEG_bs_5[15];
end

always_ff @(posedge clk)
begin
	if (rst) 
		JPEG_bitstream[14] <= 0;
	else if (enable_module && rollover_7)
		JPEG_bitstream[14] <= JPEG_bs_5[14];
	else if (enable_module && orc_8 <= 17) 
		JPEG_bitstream[14] <= JPEG_bs_5[14];
end

always_ff @(posedge clk)
begin
	if (rst) 
		JPEG_bitstream[13] <= 0;
	else if (enable_module && rollover_7)
		JPEG_bitstream[13] <= JPEG_bs_5[13];
	else if (enable_module && orc_8 <= 18) 
		JPEG_bitstream[13] <= JPEG_bs_5[13];
end

always_ff @(posedge clk)
begin
	if (rst) 
		JPEG_bitstream[12] <= 0;
	else if (enable_module && rollover_7)
		JPEG_bitstream[12] <= JPEG_bs_5[12];
	else if (enable_module && orc_8 <= 19) 
		JPEG_bitstream[12] <= JPEG_bs_5[12];
end

always_ff @(posedge clk)
begin
	if (rst) 
		JPEG_bitstream[11] <= 0;
	else if (enable_module && rollover_7)
		JPEG_bitstream[11] <= JPEG_bs_5[11];
	else if (enable_module && orc_8 <= 20) 
		JPEG_bitstream[11] <= JPEG_bs_5[11];
end

always_ff @(posedge clk)
begin
	if (rst) 
		JPEG_bitstream[10] <= 0;
	else if (enable_module && rollover_7)
		JPEG_bitstream[10] <= JPEG_bs_5[10];
	else if (enable_module && orc_8 <= 21) 
		JPEG_bitstream[10] <= JPEG_bs_5[10];
end

always_ff @(posedge clk)
begin
	if (rst) 
		JPEG_bitstream[9] <= 0;
	else if (enable_module && rollover_7)
		JPEG_bitstream[9] <= JPEG_bs_5[9];
	else if (enable_module && orc_8 <= 22) 
		JPEG_bitstream[9] <= JPEG_bs_5[9];
end

always_ff @(posedge clk)
begin
	if (rst) 
		JPEG_bitstream[8] <= 0;
	else if (enable_module && rollover_7)
		JPEG_bitstream[8] <= JPEG_bs_5[8];
	else if (enable_module && orc_8 <= 23) 
		JPEG_bitstream[8] <= JPEG_bs_5[8];
end

always_ff @(posedge clk)
begin
	if (rst) 
		JPEG_bitstream[7] <= 0;
	else if (enable_module && rollover_7)
		JPEG_bitstream[7] <= JPEG_bs_5[7];
	else if (enable_module && orc_8 <= 24) 
		JPEG_bitstream[7] <= JPEG_bs_5[7];
end

always_ff @(posedge clk)
begin
	if (rst) 
		JPEG_bitstream[6] <= 0;
	else if (enable_module && rollover_7)
		JPEG_bitstream[6] <= JPEG_bs_5[6];
	else if (enable_module && orc_8 <= 25) 
		JPEG_bitstream[6] <= JPEG_bs_5[6];
end

always_ff @(posedge clk)
begin
	if (rst) 
		JPEG_bitstream[5] <= 0;
	else if (enable_module && rollover_7)
		JPEG_bitstream[5] <= JPEG_bs_5[5];
	else if (enable_module && orc_8 <= 26) 
		JPEG_bitstream[5] <= JPEG_bs_5[5];
end

always_ff @(posedge clk)
begin
	if (rst) 
		JPEG_bitstream[4] <= 0;
	else if (enable_module && rollover_7)
		JPEG_bitstream[4] <= JPEG_bs_5[4];
	else if (enable_module && orc_8 <= 27) 
		JPEG_bitstream[4] <= JPEG_bs_5[4];
end

always_ff @(posedge clk)
begin
	if (rst) 
		JPEG_bitstream[3] <= 0;
	else if (enable_module && rollover_7)
		JPEG_bitstream[3] <= JPEG_bs_5[3];
	else if (enable_module && orc_8 <= 28) 
		JPEG_bitstream[3] <= JPEG_bs_5[3];
end

always_ff @(posedge clk)
begin
	if (rst) 
		JPEG_bitstream[2] <= 0;
	else if (enable_module && rollover_7)
		JPEG_bitstream[2] <= JPEG_bs_5[2];
	else if (enable_module && orc_8 <= 29) 
		JPEG_bitstream[2] <= JPEG_bs_5[2];
end

always_ff @(posedge clk)
begin
	if (rst) 
		JPEG_bitstream[1] <= 0;
	else if (enable_module && rollover_7)
		JPEG_bitstream[1] <= JPEG_bs_5[1];
	else if (enable_module && orc_8 <= 30) 
		JPEG_bitstream[1] <= JPEG_bs_5[1];
end

always_ff @(posedge clk)
begin
	if (rst) 
		JPEG_bitstream[0] <= 0;
	else if (enable_module && rollover_7)
		JPEG_bitstream[0] <= JPEG_bs_5[0];
	else if (enable_module && orc_8 <= 31) 
		JPEG_bitstream[0] <= JPEG_bs_5[0];
end
endmodule
