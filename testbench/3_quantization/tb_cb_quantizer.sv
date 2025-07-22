`timescale 1ns / 1ps

module tb_cb_quantizer;

    logic clk = 0;
    logic rst;
    logic enable;
    logic signed [10:0] Z[0:7][0:7];
    logic signed [10:0] Q[0:7][0:7];
    logic out_enable;

    // Instantiate the DUT
    cb_quantizer dut (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .Z(Z),
        .Q(Q),
        .out_enable(out_enable)
    );

    // Clock generation
    always #5 clk = ~clk;

    integer i, j;
    integer hi;

    initial begin
        $display("=== Test: cb_quantizer — Opposite of secondary diagonal ===");

        rst = 1;
        enable = 0;
        #12; rst = 0; #10;

        hi = 200;
        // Fill matrix: upper triangle = large, diagonal = 50, lower = small
        for (i = 0; i < 8; i = i + 1) begin
            for (j = 0; j < 8; j = j + 1) begin
                if (i + j < 7)
                    Z[i][j] = hi++;
                else if (i + j == 7)
                    Z[i][j] = 50;
                else
                    Z[i][j] = ((i + j) % 3) - 1; // small values: -1, 0, 1
            end
        end

        enable = 1;
        #10;
        enable = 0;

        wait (out_enable);
        #10;

        $display("Quantized Output:");
        for (i = 0; i < 8; i = i + 1) begin
            for (j = 0; j < 8; j = j + 1)
                $write("%0d ", Q[i][j]);
            $write("\n");
        end

        #10 $finish;
    end

endmodule
