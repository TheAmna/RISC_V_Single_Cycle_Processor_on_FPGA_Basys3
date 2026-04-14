//`timescale 1ns / 1ps
//// ============================================================
//// branchAdder.v
//// Lab 11 - Task 1
////
//// Computes the branch target address: PC + (imm << 1)
////
//// Why << 1?
////   RISC-V branch immediates from immGen already have bit[0]=0
////   (branches are halfword aligned). The shift by 1 converts
////   the halfword-count offset into a byte address offset.
////   This gives the correct target byte address.
////
//// Pure combinational - no clock.
//// ============================================================
//module branchAdder (
//    input  wire [31:0] PC,          // current PC
//    input  wire [31:0] imm,         // sign-extended immediate from immGen
//    output wire [31:0] BranchTarget // PC + (imm << 1)
//);

//    assign BranchTarget = PC + (imm << 1);

//endmodule






`timescale 1ns / 1ps
// ============================================================
// branchAdder.v
// Lab 11 - Task 1
//
// Computes the branch target address: PC + (imm << 1)
//
// As specified in the Lab 11 manual (line 3282 and 3288):
//   "branchAdder must compute PC + (sign-extended immediate << 1)"
//
// How this works with immGen:
//   immGen for B-type outputs bits[12:1] of the byte offset,
//   sign-extended to 32 bits, WITHOUT bit 0 appended.
//   This is a halfword count.
//
//   branchAdder then shifts left by 1 (multiply by 2) to
//   convert the halfword count into a byte address offset,
//   then adds to PC.
//
//   Example: branch forward +8 bytes
//     immGen outputs: 0x00000004  (halfword count = 4)
//     branchAdder:    PC + (4 << 1) = PC + 8  (correct)
//
// Pure combinational - no clock.
// ============================================================
module branchAdder (
    input  wire [31:0] PC,          // current PC
    input  wire [31:0] imm,         // sign-extended immediate from immGen
    output wire [31:0] BranchTarget // PC + (imm << 1)
);

    assign BranchTarget = PC + (imm << 1);

endmodule