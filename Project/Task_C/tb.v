`timescale 1ns / 1ps
module tb_PartC;

    reg         clk;
    reg         rst_raw;
    reg  [15:0] sw;
    wire [15:0] led;
    wire [6:0]  seg;
    wire [3:0]  an;
    wire        dp;

    ProcessorFPGA uut (
        .clk     (clk),
        .rst_raw (rst_raw),
        .sw      (sw),
        .led     (led),
        .seg     (seg),
        .an      (an),
        .dp      (dp)
    );

    defparam uut.u_clkdiv.MAX_COUNT    = 10;   // clk_en every 10 cycles
    defparam uut.u_debounce.STABLE_MAX = 10;   // debouncer fires after 10 cycles

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        rst_raw = 1;
        sw      = 16'd0;
        // Hold reset well above STABLE_MAX=10 so debouncer fires
        repeat(50) @(posedge clk);
        rst_raw = 0;
        // Wait for debouncer to release rst and processor to start
        repeat(300) @(posedge clk);

        // TEST 1 - N=7
        // Expected LED sequence: 0,1,1,2,3,5,8,13
        sw = 16'd7;
        repeat(3000) @(posedge clk);

        // Pull switches low - processor returns to WAIT_ZERO
        sw = 16'd0;
        repeat(300) @(posedge clk);

        // TEST 2 - N=5
        // Expected LED sequence: 0,1,1,2,3,5
        sw = 16'd5;
        repeat(2000) @(posedge clk);

        sw = 16'd0;
        repeat(300) @(posedge clk);

        // TEST 3 - N=10
        // Expected LED sequence: 0,1,1,2,3,5,8,13,21,34,55
        sw = 16'd10;
        repeat(5000) @(posedge clk);

        sw = 16'd0;
        repeat(300) @(posedge clk);

        $finish;
    end
    // Timeout guard
    initial begin
        #200000;
        $finish;
    end
endmodule
