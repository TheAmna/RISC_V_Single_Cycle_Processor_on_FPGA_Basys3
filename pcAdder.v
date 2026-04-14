`timescale 1ns / 1ps
// ============================================================
// pcAdder.v
// Lab 11 - Task 1
//
// Computes PC + 4.
// Pure combinational - no clock, no enable.
// Always active, always adds 4 to current PC.
// ============================================================
module pcAdder (
    input  wire [31:0] PC,          // current PC value
    output wire [31:0] PC_Plus4     // PC + 4
);

    assign PC_Plus4 = PC + 32'd4;

endmodule