`timescale 1ns / 100ps // Standard for test benches: 1ns precision, 1ps resolution

module y_dct_tb;

    // --- Test Bench Signals ---
    logic clk;
    logic rst;
    logic enable;
    logic [7:0] data_in;

    // Outputs from the DUT (Device Under Test)
    logic [10:0] Z11_final, Z12_final, Z13_final, Z14_final;
    logic [10:0] Z15_final, Z16_final, Z17_final, Z18_final;
    logic [10:0] Z21_final, Z22_final, Z23_final, Z24_final;
    logic [10:0] Z25_final, Z26_final, Z27_final, Z28_final;
    logic [10:0] Z31_final, Z32_final, Z33_final, Z34_final; // Corrected Z34_final
    logic [10:0] Z35_final, Z36_final, Z37_final, Z38_final;
    logic [10:0] Z41_final, Z42_final, Z43_final, Z44_final;
    logic [10:0] Z45_final, Z46_final, Z47_final, Z48_final;
    logic [10:0] Z51_final, Z52_final, Z53_final, Z54_final;
    logic [10:0] Z55_final, Z56_final, Z57_final, Z58_final;
    logic [10:0] Z61_final, Z62_final, Z63_final, Z64_final;
    logic [10:0] Z65_final, Z66_final, Z67_final, Z68_final;
    logic [10:0] Z71_final, Z72_final, Z73_final, Z74_final;
    logic [10:0] Z75_final, Z76_final, Z77_final, Z78_final;
    logic [10:0] Z81_final, Z82_final, Z83_final, Z84_final;
    logic [10:0] Z85_final, Z86_final, Z87_final, Z88_final;
    logic output_enable;

    // Internal test bench variables
    integer i; // For loops
    integer test_data_idx; // To track current data input
    integer clk_period = 10; // 10 ns clock period (100 MHz)
    integer num_blocks = 2; // Number of 8x8 blocks to test
    integer data_value; // To hold the data_in value

    // --- Instantiate the Device Under Test (DUT) ---
    y_dct dut (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .data_in(data_in),
        .Z11_final(Z11_final), .Z12_final(Z12_final), .Z13_final(Z13_final), .Z14_final(Z14_final),
        .Z15_final(Z15_final), .Z16_final(Z16_final), .Z17_final(Z17_final), .Z18_final(Z18_final),
        .Z21_final(Z21_final), .Z22_final(Z22_final), .Z23_final(Z23_final), .Z24_final(Z24_final),
        .Z25_final(Z25_final), .Z26_final(Z26_final), .Z27_final(Z27_final), .Z28_final(Z28_final),
        .Z31_final(Z31_final), .Z32_final(Z32_final), .Z33_final(Z33_final), .Z34_final(Z34_final), // Corrected here
        .Z35_final(Z35_final), .Z36_final(Z36_final), .Z37_final(Z37_final), .Z38_final(Z38_final),
        .Z41_final(Z41_final), .Z42_final(Z42_final), .Z43_final(Z43_final), .Z44_final(Z44_final),
        .Z45_final(Z45_final), .Z46_final(Z46_final), .Z47_final(Z47_final), .Z48_final(Z48_final),
        .Z51_final(Z51_final), .Z52_final(Z52_final), .Z53_final(Z53_final), .Z54_final(Z54_final),
        .Z55_final(Z55_final), .Z56_final(Z56_final), .Z57_final(Z57_final), .Z58_final(Z58_final),
        .Z61_final(Z61_final), .Z62_final(Z62_final), .Z63_final(Z63_final), .Z64_final(Z64_final),
        .Z65_final(Z65_final), .Z66_final(Z66_final), .Z67_final(Z67_final), .Z68_final(Z68_final),
        .Z71_final(Z71_final), .Z72_final(Z72_final), .Z73_final(Z73_final), .Z74_final(Z74_final),
        .Z75_final(Z75_final), .Z76_final(Z76_final), .Z77_final(Z77_final), .Z78_final(Z78_final),
        .Z81_final(Z81_final), .Z82_final(Z82_final), .Z83_final(Z83_final), .Z84_final(Z84_final),
        .Z85_final(Z85_final), .Z86_final(Z86_final), .Z87_final(Z87_final), .Z88_final(Z88_final),
        .output_enable(output_enable)
    );

    // --- Clock Generation ---
    initial begin
        clk = 0;
        forever # (clk_period / 2) clk = ~clk; // 5ns high, 5ns low -> 10ns period
    end

    // --- Test Stimulus ---
    initial begin
        $display("-----------------------------------------------------");
        $display("           Starting y_dct Test Bench               ");
        $display("-----------------------------------------------------");

        // 1. Reset Sequence
        rst = 1;
        enable = 0;
        data_in = 0;
        # (clk_period * 2); // Hold reset for a few clock cycles
        rst = 0;
        $display("TIME: %0t - Reset Released.", $time);

        // 2. Main Test Loop: Process multiple 8x8 blocks
        for (i = 0; i < num_blocks; i = i + 1) begin
            $display("TIME: %0t - Starting Block %0d.", $time, i);
            enable = 1; // Start enabling the module
            data_value = 0; // Reset data value for each block
            test_data_idx = 0;

            // Send 64 samples for one 8x8 block
            while (test_data_idx < 64) begin
                @(posedge clk);
                // Simple data pattern: incrementing value for demonstration
                // For real testing, load from file or use specific test vectors
                data_in = data_value;
                $display("TIME: %0t - Input Sample %0d: data_in = %0d", $time, test_data_idx, data_in);
                data_value = data_value + 1; // Increment for next sample
                test_data_idx = test_data_idx + 1;
            end
            enable = 0; // Disable after sending 64 samples
            $display("TIME: %0t - All 64 samples sent for Block %0d.", $time, i);

            // 3. Wait for pipeline to drain and outputs to stabilize
            // The pipeline depth is significant. You need to wait enough cycles
            // for the last input to propagate to the Z_final outputs.
            // Estimate pipeline depth for Z_final:
            // data_in -> data_reg (1) -> Y_temp (1) -> Y_final (1) -> Y_final_diff (1) -> Y_final_X (1) -> Z_temp (1) -> Z (8 cycles to accumulate) -> Z_final (1)
            // Roughly 1+1+1+1+1+1+8+1 = ~15-16 cycles.
            // Add some margin. Let's wait for 20-30 cycles for `output_enable` to assert.
            # (clk_period * 20); // Wait for results to propagate

            // 4. Check results for the current block
            @(posedge clk);
            if (output_enable) begin
                $display("TIME: %0t - output_enable asserted for Block %0d. Checking outputs...", $time, i);
                // Basic self-check: Ensure at least one output is not zero
                // For robust testing, compare against known good golden reference values.
                if (Z11_final == 0 && Z12_final == 0 && Z13_final == 0 && Z14_final == 0 &&
                    Z15_final == 0 && Z16_final == 0 && Z17_final == 0 && Z18_final == 0 &&
                    Z21_final == 0 && Z22_final == 0 && Z23_final == 0 && Z24_final == 0 &&
                    Z25_final == 0 && Z26_final == 0 && Z27_final == 0 && Z28_final == 0 &&
                    Z31_final == 0 && Z32_final == 0 && Z33_final == 0 && Z34_final == 0 &&
                    Z35_final == 0 && Z36_final == 0 && Z37_final == 0 && Z38_final == 0 &&
                    Z41_final == 0 && Z42_final == 0 && Z43_final == 0 && Z44_final == 0 &&
                    Z45_final == 0 && Z46_final == 0 && Z47_final == 0 && Z48_final == 0 &&
                    Z51_final == 0 && Z52_final == 0 && Z53_final == 0 && Z54_final == 0 &&
                    Z55_final == 0 && Z56_final == 0 && Z57_final == 0 && Z58_final == 0 &&
                    Z61_final == 0 && Z62_final == 0 && Z63_final == 0 && Z64_final == 0 &&
                    Z65_final == 0 && Z66_final == 0 && Z67_final == 0 && Z68_final == 0 &&
                    Z71_final == 0 && Z72_final == 0 && Z73_final == 0 && Z74_final == 0 &&
                    Z75_final == 0 && Z76_final == 0 && Z77_final == 0 && Z78_final == 0 &&
                    Z81_final == 0 && Z82_final == 0 && Z83_final == 0 && Z84_final == 0 &&
                    Z85_final == 0 && Z86_final == 0 && Z87_final == 0 && Z88_final == 0
                ) begin
                    $error("TIME: %0t - ERROR: All Z_final outputs are zero for Block %0d!", $time, i);
                end else begin
                    $info("TIME: %0t - Z_final outputs are non-zero for Block %0d (PASS).", $time, i);
                    // Print a few sample outputs for visual inspection
                    $display("  Z11_final: %0d, Z12_final: %0d, Z13_final: %0d, Z14_final: %0d", Z11_final, Z12_final, Z13_final, Z14_final);
                    $display("  Z21_final: %0d, Z22_final: %0d, Z23_final: %0d, Z24_final: %0d", Z21_final, Z22_final, Z23_final, Z24_final);
                    $display("  Z88_final: %0d", Z88_final);
                end
            end else begin
                $warning("TIME: %0t - WARNING: output_enable did NOT assert for Block %0d as expected.", $time, i);
            end

            // Wait a bit before starting the next block, if any
            # (clk_period * 5);
        end

        $display("-----------------------------------------------------");
        $display("           Finishing y_dct Test Bench              ");
        $display("-----------------------------------------------------");
        $finish; // End simulation
    end

    // --- Optional: Monitor outputs continuously (can make logs very large) ---
    // initial begin
    //     $monitor("TIME: %0t | clk=%b rst=%b enable=%b data_in=%d | output_enable=%b Z11_final=%d",
    //              $time, clk, rst, enable, data_in, output_enable, Z11_final);
    // end

endmodule