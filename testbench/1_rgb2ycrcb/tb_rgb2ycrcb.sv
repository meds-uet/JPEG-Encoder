`timescale 1ns / 1ps

module tb_rgb2ycrcb;

    // DUT inputs
    logic clk;
    logic rst;
    logic enable;
    logic [23:0] data_in;

    // DUT outputs
    logic [23:0] data_out;
    logic enable_out;

    // Internal testbench variables
    integer valid_count;
    integer outputs_expected;

    // Instantiate the DUT
    rgb2ycrcb dut (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .data_in(data_in),
        .data_out(data_out),
        .enable_out(enable_out)
    );

    // Clock generation (100 MHz)
    always #5 clk = ~clk;

    // Task to apply RGB input
    task apply_rgb(input [7:0] R, input [7:0] G, input [7:0] B);
        begin
            @(negedge clk);
            enable  = 1;
            data_in = {B, G, R};
            @(negedge clk);
            enable  = 0;
        end
    endtask

    // Initial block
    initial begin
        $display("Starting RGB to YCbCr Testbench...");

        // Initialize
        clk = 0;
        rst = 1;
        enable = 0;
        data_in = 24'h0;
        valid_count = 0;
        outputs_expected = 7;

        // Reset
        repeat (2) @(posedge clk);
        rst = 0;

        // Apply test vectors with delay between each for pipeline
        apply_rgb(8'd255, 8'd0,   8'd0);     // Red
        repeat (3) @(posedge clk);

        apply_rgb(8'd0,   8'd255, 8'd0);     // Green
        repeat (3) @(posedge clk);

        apply_rgb(8'd0,   8'd0,   8'd255);   // Blue
        repeat (3) @(posedge clk);

        apply_rgb(8'd255, 8'd255, 8'd255);   // White
        repeat (3) @(posedge clk);

        apply_rgb(8'd0,   8'd0,   8'd0);     // Black
        repeat (3) @(posedge clk);

        apply_rgb(8'd128, 8'd128, 8'd128);   // Gray
        repeat (3) @(posedge clk);

        apply_rgb(8'd50,  8'd100, 8'd150);   // Custom
        repeat (3) @(posedge clk);

        // Wait and capture outputs
        repeat (100) begin
            @(posedge clk);
            if (enable_out) begin
                $display("RGB: R=%0d G=%0d B=%0d => Y=%0d Cb=%0d Cr=%0d",
                    dut.R, dut.G, dut.B,
                    data_out[7:0],       // Y
                    data_out[15:8],      // Cb
                    data_out[23:16]      // Cr
                );
                valid_count++;
                if (valid_count == outputs_expected)
                    break;
            end
        end

        $display("Testbench completed. Valid outputs received: %0d", valid_count);
        $finish;
    end

endmodule
