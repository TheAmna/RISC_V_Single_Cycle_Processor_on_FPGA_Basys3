/*
`timescale 1ns / 1ps
module leds (
    input              clk,
    input              rst,
    input  [15:0]      btns,
    input  [31:0]      writeData,
    input              writeEnable,
    input              readEnable,
    input  [29:0]      memAddress,
    input  [15:0]      switches,
    output reg [31:0]  readData
);
    reg [15:0] sync_stage1;
    always @(posedge clk) begin
        if (rst) begin
            sync_stage1      <= 16'd0;
            readData         <= 32'd0;
        end else begin
            sync_stage1      <= switches;
            readData[15:0]   <= sync_stage1;
            readData[31:16]  <= 16'd0;
        end
    end
endmodule*/

`timescale 1ns / 1ps

// leds module
// Drives the physical FPGA LEDs.
// When writeEnable is high it latches writeData[15:0] into the
// LED output register on the next rising clock edge.
// readData is always zero - LEDs are write-only from the processor's view.

module leds (
    input              clk,
    input              rst,
    input  [31:0]      writeData,   // data to show on LEDs, only [15:0] used
    input              writeEnable, // 1 = update LED outputs this cycle
    input              readEnable,  // unused - kept for bus compatibility
    input  [29:0]      memAddress,  // unused - kept for bus compatibility
    output reg [31:0]  readData,    // always 0, LEDs are not readable
    output reg [15:0]  leds         // physical LED outputs to FPGA pins
);

    initial readData = 32'd0;

    always @(posedge clk) begin
        if (rst) begin
            leds     <= 16'd0; // clear all LEDs on reset
            readData <= 32'd0;
        end else if (writeEnable) begin
            leds <= writeData[15:0]; // drive LEDs with lower 16 bits of write data
        end
    end

endmodule