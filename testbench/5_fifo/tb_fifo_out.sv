`timescale 1ns / 100ps

module tb_fifo_out;

  // Inputs
  logic clk;
  logic rst;
  logic enable;
  logic [23:0] data_in;

  // Outputs
  logic [31:0] JPEG_bitstream;
  logic        data_ready;
  logic [4:0]  orc_reg;

  // Instantiate the DUT
  fifo_out uut (
    .clk(clk),
    .rst(rst),
    .enable(enable),
    .data_in(data_in),
    .JPEG_bitstream(JPEG_bitstream),
    .data_ready(data_ready),
    .orc_reg(orc_reg)
  );

  // Clock generation
  initial clk = 0;
  always #5 clk = ~clk; // 100 MHz clock

  // Stimulus
  initial begin
    $display("=== Starting fifo_out Testbench ===");
    rst = 1;
    enable = 0;
    data_in = 24'd0;
    #20;

    rst = 0;
    #10;

    // Apply some dummy input to trigger pre_fifo and fifo pipelines
    enable = 1;

    // Sending dummy stream (e.g., alternating values)
    for (int i = 0; i < 10; i++) begin
      data_in = 24'd123456 + i;
      #10;
    end

    enable = 0;

    // Let the pipeline run
    #200;

    $display("JPEG Output: %h", JPEG_bitstream);
    $display("ORC Register: %0d", orc_reg);
    $display("Data Ready: %b", data_ready);

    $display("=== Testbench Complete ===");
    $finish;
  end

endmodule
