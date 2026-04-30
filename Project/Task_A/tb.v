`timescale 1ns / 1ps

module tb_ProcessorFPGA;
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

    // Both overrides needed for simulation to work
    defparam uut.u_clk_div.MAX_COUNT   = 10;   // slow_clk every 10 cycles
    defparam uut.u_debounce.STABLE_MAX = 10;   // debouncer fires after 10 cycles

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        rst_raw = 1;
        sw      = 16'd0;
        repeat(50) @(posedge clk);   // 50 cycles >> STABLE_MAX=10, debouncer fires

        rst_raw = 0;
        repeat(300) @(posedge clk);  // polling phase, sw=0

        sw = 16'd5;
        repeat(2000) @(posedge clk); // countdown from 5

        sw = 16'd0;
        repeat(300) @(posedge clk);

        sw = 16'd3;
        repeat(1500) @(posedge clk); // countdown from 3

        sw = 16'd0;
        repeat(300) @(posedge clk);

        $finish;
    end

endmodule
