`timescale 1ns / 1ps

module tb_cr_quantizer;

    logic clk = 0;
    logic rst;
    logic enable;
    logic signed [10:0] Z[8][8];
    logic signed [10:0] Q[8][8];
    logic out_enable;

    // Use quantization matrix of all 1s (4096/Q = 4096)
    localparam int Q_MATRIX[8][8] = '{default: 1};

    // Instantiate the DUT
    cr_quantizer #(.Q_MATRIX(Q_MATRIX)) dut (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .Z(Z),
        .Q(Q),
        .out_enable(out_enable)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin : testbench
        integer i, j, hi;

        $display("=== Test: cr_quantizer — Opposite of secondary diagonal ===");

        rst = 1;
        enable = 0;
        #12; rst = 0; #10;

        // Initialize input matrix: upper half = large, diagonal = 50, lower = small
        hi = 200;
        for (i = 0; i < 8; i++) begin
            for (j = 0; j < 8; j++) begin
                if (i + j < 7)
                    Z[i][j] = hi++;
                else if (i + j == 7)
                    Z[i][j] = 50;
                else
                    Z[i][j] = (i + j) % 3 - 1; // -1, 0, 1 pattern
            end
        end

        enable = 1; #10;
        enable = 0;

        wait(out_enable);
        #10;

        $display("Quantized Output:");
        for (i = 0; i < 8; i++) begin
            for (j = 0; j < 8; j++)
                $write("%0d ", Q[i][j]);
            $write("\n");
        end

        #10 $finish;
    end

endmodule
