`timescale 1ns / 1ps
module MemorySystem_FSM (
    input  wire        clk,
    input  wire        rst,
    input  wire        slow_clk,    // 1 Hz enable pulse from clock_divider
    output reg  [31:0] address,
    output reg         readEnable,
    output reg         writeEnable,
    output reg  [31:0] writeData,
    input  wire [31:0] readData,    // from addressDecoderTop
    output reg  [15:0] fsm_leds    // FSM result display, muxed onto physical LEDs
);
    localparam [3:0]
        IDLE       = 4'd0,
        WRITE_MEM1 = 4'd1,   // DataMem[0x001] <- 0x0000A5A5
        WRITE_MEM2 = 4'd2,   // DataMem[0x002] <- 0x00005AA5
        WRITE_LED1 = 4'd3,   // LED 0x200      <- 0x0000FFFF
        WRITE_LED2 = 4'd4,   // LED 0x200      <- 0x00005555
        READ_MEM1  = 4'd5,   // read DataMem[0x001]
        HOLD_MEM1  = 4'd6,   // hold readData on LEDs
        READ_MEM2  = 4'd7,   // read DataMem[0x002]
        HOLD_MEM2  = 4'd8,   // hold readData on LEDs
        READ_SW    = 4'd9,   // read switches via 0x300
        HOLD_SW    = 4'd10,  // hold switch value on LEDs
        DONE       = 4'd11;  // sequence complete - stays until rst
    reg [3:0] state;
    reg [31:0] read_latch;
    always @(posedge clk) begin
        if (rst) begin
            state       <= IDLE;
            address     <= 32'd0;
            readEnable  <= 1'b0;
            writeEnable <= 1'b0;
            writeData   <= 32'd0;
            read_latch  <= 32'd0;
            fsm_leds    <= 16'd0;
        end else if (slow_clk) begin // Default: deassert bus signals each slow tick
            readEnable  <= 1'b0;
            writeEnable <= 1'b0;
            address     <= 32'd0;
            writeData   <= 32'd0;

            case (state)
                IDLE: begin
                    fsm_leds <= 16'd0;
                    state    <= WRITE_MEM1;
                end
                WRITE_MEM1: begin
                    address     <= 32'h001;
                    writeData   <= 32'h0000A5A5;
                    writeEnable <= 1'b1;
                    fsm_leds    <= 16'hA5A5;   // show value being written
                    state       <= WRITE_MEM2;
                end
                WRITE_MEM2: begin
                    address     <= 32'h002;
                    writeData   <= 32'h00005AA5;
                    writeEnable <= 1'b1;
                    fsm_leds    <= 16'h5AA5;
                    state       <= WRITE_LED1;
                end
                WRITE_LED1: begin
                    address     <= 32'h200;
                    writeData   <= 32'h0000FFFF;
                    writeEnable <= 1'b1;
                    fsm_leds    <= 16'hFFFF;
                    state       <= WRITE_LED2;
                end
                WRITE_LED2: begin
                    address     <= 32'h200;
                    writeData   <= 32'h00005555;
                    writeEnable <= 1'b1;
                    fsm_leds    <= 16'h5555;
                    state       <= READ_MEM1;
                end
                READ_MEM1: begin
                    address    <= 32'h001;
                    readEnable <= 1'b1;
                    read_latch <= readData;
                    state      <= HOLD_MEM1;
                end
                HOLD_MEM1: begin
                    fsm_leds <= read_latch[15:0];
                    state    <= READ_MEM2;
                end
                READ_MEM2: begin
                    address    <= 32'h002;
                    readEnable <= 1'b1;
                    read_latch <= readData;
                    state      <= HOLD_MEM2;
                end
                HOLD_MEM2: begin
                    fsm_leds <= read_latch[15:0];
                    state    <= READ_SW;
                end
                READ_SW: begin
                    address    <= 32'h300;
                    readEnable <= 1'b1;
                    read_latch <= readData;
                    state      <= HOLD_SW;
                end
                HOLD_SW: begin
                    fsm_leds <= read_latch[15:0];
                    state    <= DONE;
                end
                DONE: begin
                    fsm_leds <= read_latch[15:0];
                    state    <= IDLE;   // auto-loop for continuous demo
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule