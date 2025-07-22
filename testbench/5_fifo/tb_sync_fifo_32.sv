`timescale 1ns / 100ps

module tb_sync_fifo_32;

    // DUT signals
    logic        clk;
    logic        rst;
    logic        read_req;
    logic [31:0] write_data;
    logic        write_enable;
    logic [31:0] read_data;
    logic        fifo_empty;
    logic        rdata_valid;

    // Instantiate the DUT
    sync_fifo_32 dut (
        .clk(clk),
        .rst(rst),
        .read_req(read_req),
        .write_data(write_data),
        .write_enable(write_enable),
        .read_data(read_data),
        .fifo_empty(fifo_empty),
        .rdata_valid(rdata_valid)
    );

    // Clock generation: 10ns period
    always #5 clk = ~clk;

    // Test logic
    initial begin
        $display("=== Test: sync_fifo_32 ===");

        // Initialize
        clk = 0;
        rst = 1;
        write_data = 0;
        write_enable = 0;
        read_req = 0;

        // Reset
        repeat (2) @(posedge clk);
        rst = 0;

        // Fill FIFO with 4 entries
        write_word(32'd10);
        write_word(32'd20);
        write_word(32'd30);
        write_word(32'd40);

        // Try reading back
        read_word();
        read_word();
        read_word();
        read_word();

        // Check empty status
        @(posedge clk);
        if (fifo_empty)
            $display("FIFO is empty as expected after all reads.");
        else
            $display("FIFO is NOT empty — ERROR!");

        $display("=== Test Complete ===");
        $finish;
    end

    // Task to write one word
    task write_word(input logic [31:0] value);
        @(posedge clk);
        write_data   <= value;
        write_enable <= 1;
        @(posedge clk);
        write_enable <= 0;
        $display("Wrote: %0d", value);
    endtask

    // Task to read one word (waits for rdata_valid)
    task read_word();
        @(posedge clk);
        read_req <= 1;
        @(posedge clk);
        read_req <= 0;
        wait (rdata_valid);
        @(posedge clk);
        $display("Read: %0d", read_data);
    endtask

endmodule
