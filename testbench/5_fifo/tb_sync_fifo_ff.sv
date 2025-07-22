`timescale 1ns / 100ps

module tb_sync_fifo_ff;

    // DUT Signals
    logic clk;
    logic rst;
    logic read_req;
    logic [90:0] write_data;
    logic write_enable;
    logic rollover_write;
    logic [90:0] read_data;
    logic fifo_empty;
    logic rdata_valid;

    // Instantiate the DUT
    sync_fifo_ff dut (
        .clk(clk),
        .rst(rst),
        .read_req(read_req),
        .write_data(write_data),
        .write_enable(write_enable),
        .rollover_write(rollover_write),
        .read_data(read_data),
        .fifo_empty(fifo_empty),
        .rdata_valid(rdata_valid)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Test sequence
    initial begin
        $display("=== Test: Write and Read ===");

        // Initialize signals
        clk = 0;
        rst = 1;
        read_req = 0;
        write_data = 0;
        write_enable = 0;
        rollover_write = 0;

        // Reset the DUT
        repeat (2) @(posedge clk);
        rst = 0;

        // Write 4 values
        write_to_fifo(91'd100);
        write_to_fifo(91'd101);
        write_to_fifo(91'd102);
        write_to_fifo(91'd103);

        // Read 4 values
        read_from_fifo();
        read_from_fifo();
        read_from_fifo();
        read_from_fifo();

        // Rollover write test
        $display("=== Test: Rollover Write ===");

        write_rollover(91'd500);     // causes 1-entry skip in FIFO
        write_to_fifo(91'd999);
        write_to_fifo(91'd777);

        // Read back
        read_from_fifo();
        read_from_fifo();
        read_from_fifo();  // this one might return skipped or default
        read_from_fifo();

        $display("=== Test Complete ===");
        $finish;
    end

    // Task to write to FIFO
    task write_to_fifo(input logic [90:0] data);
        begin
            @(posedge clk);
            write_data     <= data;
            write_enable   <= 1;
            rollover_write <= 0;
            @(posedge clk);
            write_enable   <= 0;
            rollover_write <= 0;
        end
    endtask

    // Task to write to FIFO with rollover (inserts bubble)
    task write_rollover(input logic [90:0] data);
        begin
            @(posedge clk);
            write_data     <= data;
            write_enable   <= 1;
            rollover_write <= 1;
            @(posedge clk);
            write_enable   <= 0;
            rollover_write <= 0;
        end
    endtask

    // Task to read from FIFO with synchronization
    task read_from_fifo;
        begin
            @(posedge clk);
            read_req <= 1;
            @(posedge clk);
            read_req <= 0;
            wait (rdata_valid === 1);
            @(posedge clk);
            $display("Read data: %0d", read_data);
        end
    endtask

endmodule
