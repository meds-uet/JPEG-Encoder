
`timescale 1ns / 100ps

module cb_dct_tb;

    // Testbench signals
    logic clk;
    logic rst;
    logic enable;
    logic [7:0] data_in;
    logic output_enable;
    logic [10:0] Z11_final, Z12_final, Z13_final, Z14_final, Z15_final, Z16_final, Z17_final, Z18_final;
    logic [10:0] Z21_final, Z22_final, Z23_final, Z24_final, Z25_final, Z26_final, Z27_final, Z28_final;
    logic [10:0] Z31_final, Z32_final, Z33_final, Z34_final, Z35_final, Z36_final, Z37_final, Z38_final;
    logic [10:0] Z41_final, Z42_final, Z43_final, Z44_final, Z45_final, Z46_final, Z47_final, Z48_final;
    logic [10:0] Z51_final, Z52_final, Z53_final, Z54_final, Z55_final, Z56_final, Z57_final, Z58_final;
    logic [10:0] Z61_final, Z62_final, Z63_final, Z64_final, Z65_final, Z66_final, Z67_final, Z68_final;
    logic [10:0] Z71_final, Z72_final, Z73_final, Z74_final, Z75_final, Z76_final, Z77_final, Z78_final;
    logic [10:0] Z81_final, Z82_final, Z83_final, Z84_final, Z85_final, Z86_final, Z87_final, Z88_final;

    // Instantiate the DUT
    cb_dct dut (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .data_in(data_in),
        .output_enable(output_enable),
        .Z11_final(Z11_final), .Z12_final(Z12_final), .Z13_final(Z13_final), .Z14_final(Z14_final),
        .Z15_final(Z15_final), .Z16_final(Z16_final), .Z17_final(Z17_final), .Z18_final(Z18_final),
        .Z21_final(Z21_final), .Z22_final(Z22_final), .Z23_final(Z23_final), .Z24_final(Z24_final),
        .Z25_final(Z25_final), .Z26_final(Z26_final), .Z27_final(Z27_final), .Z28_final(Z28_final),
        .Z31_final(Z31_final), .Z32_final(Z32_final), .Z33_final(Z33_final), .Z34_final(Z34_final),
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
        .Z85_final(Z85_final), .Z86_final(Z86_final), .Z87_final(Z87_final), .Z88_final(Z88_final)
    );

    // Clock generation (10 ns period)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test stimulus
    initial begin
        // Initialize signals
        rst = 1;
        enable = 0;
        data_in = 8'h00;
        #50; // Time=50 ns

        // Release reset
        rst = 0;
        #450; // Time=500 ns

        // Test Case 1: Constant input 8'h80
        enable = 1;
        data_in = 8'h80;
        repeat (64) begin
            #10; // 64 cycles = 640 ns
        end
        enable = 0;
        #690; // Wait 69 cycles (640 ns input + 50 ns pipeline delay)

        // Check outputs
        if (output_enable) begin
            $display("Test Case 1: Output enable asserted at time %0t", $time);
            $display("Z11_final = %d (Expected ~4096)", Z11_final);
            $display("Z12_final = %d (Expected ~0)", Z12_final);
            $display("Z21_final = %d (Expected ~0)", Z21_final);
            $display("Z22_final = %d (Expected ~0)", Z22_final);
            // Check if outputs are within expected range
            if (Z11_final >= 3900 && Z11_final <= 4200 &&
                Z12_final == 0 && Z21_final == 0 && Z22_final == 0 &&
                Z13_final == 0 && Z14_final == 0 && Z15_final == 0 && Z16_final == 0 &&
                Z17_final == 0 && Z18_final == 0 && Z23_final == 0 && Z24_final == 0 &&
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
                Z85_final == 0 && Z86_final == 0 && Z87_final == 0 && Z88_final == 0)
                $display("Test Case 1: PASS");
            else
                $display("Test Case 1: FAIL - Check DCT computation for incorrect outputs");
        end else begin
            $display("Test Case 1: Output enable not asserted at time %0t!", $time);
        end

        // Reset between test cases
        rst = 1;
        #200; // Time=11450 ns + 200 ns = 11650 ns
        rst = 0;
        #200; // Time=11850 ns

        // Test Case 2: Constant input 8'h40
        enable = 1;
        data_in = 8'h40;
        repeat (64) begin
            #10; // 64 cycles = 640 ns
        end
        enable = 0;
        #690; // Wait 69 cycles (640 ns input + 50 ns pipeline delay)

        // Check outputs
        if (output_enable) begin
            $display("Test Case 2: Output enable asserted at time %0t", $time);
            $display("Z11_final = %d (Expected ~2048)", Z11_final);
            $display("Z12_final = %d (Expected ~0)", Z12_final);
            $display("Z21_final = %d (Expected ~0)", Z21_final);
            $display("Z22_final = %d (Expected ~0)", Z22_final);
            // Check if outputs are within expected range
            if (Z11_final >= 1900 && Z11_final <= 2200 &&
                Z12_final == 0 && Z21_final == 0 && Z22_final == 0 &&
                Z13_final == 0 && Z14_final == 0 && Z15_final == 0 && Z16_final == 0 &&
                Z17_final == 0 && Z18_final == 0 && Z23_final == 0 && Z24_final == 0 &&
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
                Z85_final == 0 && Z86_final == 0 && Z87_final == 0 && Z88_final == 0)
                $display("Test Case 2: PASS");
            else
                $display("Test Case 2: FAIL - Check DCT computation for incorrect outputs");
        end 


        // End simulation
        #200;
        $finish;
    end

    // Monitor outputs
    initial begin
        $monitor("Time=%0t rst=%b enable=%b data_in=%h output_enable=%b count=%0d count_of=%0d Z11_final=%0d Z12_final=%0d",
                 $time, rst, enable, data_in, output_enable, dut.count, dut.count_of, Z11_final, Z12_final);
    end

endmodule
