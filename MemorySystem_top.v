`timescale 1ns / 1ps
module MemorySystem_top (
    input  wire        clk,        // 100 MHz - W5
    input  wire        rst_raw,    // BTNC raw (U18) - debounced below
    input  wire [15:0] sw,         // 16 switches
    output wire [15:0] led         // 16 LEDs
);
    wire rst;
    debouncer #(
        .STABLE_MAX(500_000)
    ) u_debouncer (
        .clk  (clk),
        .pbin (rst_raw),
        .pbout(rst)
    );
    wire slow_clk;
    clock_divider #(
        .MAX_COUNT(100_000_000)
    ) u_clkdiv (
        .clk     (clk),
        .rst     (rst),
        .slow_clk(slow_clk)
    );
    wire [31:0] fsm_address;
    wire        fsm_readEnable;
    wire        fsm_writeEnable;
    wire [31:0] fsm_writeData;
    wire [31:0] mem_readData;      // comes back from addressDecoderTop
    wire [15:0] fsm_leds;          // FSM result display output

    MemorySystem_FSM u_fsm (
        .clk        (clk),
        .rst        (rst),
        .slow_clk   (slow_clk),
        .address    (fsm_address),
        .readEnable (fsm_readEnable),
        .writeEnable(fsm_writeEnable),
        .writeData  (fsm_writeData),
        .readData   (mem_readData),
        .fsm_leds   (fsm_leds)
    );
    wire [15:0] mem_leds;   // LED peripheral output from addressDecoderTop
    addressDecoderTop u_mem_sys (
        .clk        (clk),
        .rst        (rst),
        .address    (fsm_address),
        .readEnable (fsm_readEnable),
        .writeEnable(fsm_writeEnable),
        .writeData  (fsm_writeData),
        .switches   (sw),           // physical switches wired in
        .readData   (mem_readData),
        .leds       (mem_leds)
    );
    assign led = sw[15] ? fsm_leds : sw[15:0];
endmodule