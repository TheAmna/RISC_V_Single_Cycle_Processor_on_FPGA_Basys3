`timescale 1ns / 1ps
// ============================================================
// mux2.v
// Lab 11 - Task 1
//
// 2-to-1 multiplexer, 32 bits wide.
//
// Used in THREE places in the full processor:
//
//   Instance 1 - PC select mux:
//     sel = PCSrc = (Branch AND Zero)
//     in0 = PC + 4       (sequential, branch not taken)
//     in1 = BranchTarget (branch taken)
//     out = PC_Next
//
//   Instance 2 - ALU operand B mux:
//     sel = ALUSrc
//     in0 = ReadData2 from register file (R-type)
//     in1 = imm_out from immGen          (I/S/B-type)
//     out = ALU input B
//
//   Instance 3 - Writeback data mux:
//     sel = MemtoReg
//     in0 = ALUResult   (R-type, I-arithmetic)
//     in1 = read_data   (Load instructions)
//     out = WriteData to register file
//
// Pure combinational - no clock.
// ============================================================
module mux2 (
    input  wire        sel,     // select signal
    input  wire [31:0] in0,     // input when sel = 0
    input  wire [31:0] in1,     // input when sel = 1
    output reg  [31:0] out      // selected output
);

    always @(*) begin
        if (sel == 1'b0) begin
            out = in0;
        end
        else begin
            out = in1;
        end
    end

endmodule