`timescale 1ns / 1ps
// ============================================================
// ProgramCounter.v
// Lab 11 - Task 1
//
// Stores the current instruction address.
// Updates on every rising clock edge.
// Synchronous reset sets PC back to 0x00000000.
// ============================================================
module ProgramCounter (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] PC_Next,   // next address (from mux2)
    output reg  [31:0] PC         // current address (to instruction memory)
);

    always @(posedge clk) begin
        if (rst)
            PC <= 32'h00000000;   // reset: start from address 0
        else
            PC <= PC_Next;        // update to next address every cycle
    end

endmodule