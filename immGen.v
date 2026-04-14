//`timescale 1ns / 1ps
//// ============================================================
//// immGen.v
//// Lab 11 - Task 1
////
//// Immediate Generator - extracts and sign-extends the
//// immediate value from a 32-bit RISC-V instruction.
////
//// Supports three formats as required by the manual:
////
////   I-type (loads, ADDI, JALR):
////     imm[11:0] = instr[31:20]
////     sign bit  = instr[31]
////
////   S-type (stores SW, SH, SB):
////     imm[11:5] = instr[31:25]
////     imm[4:0]  = instr[11:7]
////     sign bit  = instr[31]
////
////   B-type (branches BEQ, BNE, BLT, BGE):
////     imm[12]   = instr[31]
////     imm[10:5] = instr[30:25]
////     imm[4:1]  = instr[11:8]
////     imm[11]   = instr[7]
////     imm[0]    = 0 (always, branches are halfword aligned)
////     sign bit  = instr[31]
////
//// All outputs are sign-extended to 32 bits.
//// Opcode is used to select which format applies.
////
//// Opcode values:
////   0000011 = Load  (I-type)
////   0010011 = I-arithmetic (I-type)
////   1100111 = JALR  (I-type)
////   0100011 = Store (S-type)
////   1100011 = Branch (B-type)
//// ============================================================
//module immGen (
//    input  wire [31:0] instruction,   // full 32-bit instruction word
//    output reg  [31:0] imm_out        // sign-extended immediate
//);

//    wire [6:0] opcode = instruction[6:0];

//    // Opcode localparams for readability
//    localparam LOAD   = 7'b0000011;   // I-type
//    localparam I_ARITH= 7'b0010011;   // I-type
//    localparam JALR   = 7'b1100111;   // I-type
//    localparam STORE  = 7'b0100011;   // S-type
//    localparam BRANCH = 7'b1100011;   // B-type

//    always @(*) begin
//        case (opcode)

//            // --------------------------------------------------
//            // I-type: Load, ADDI/ANDI/ORI/XORI, JALR
//            // imm[11:0] = instr[31:20], sign-extended from bit 31
//            // --------------------------------------------------
//            LOAD, I_ARITH, JALR: begin
//                imm_out = {{20{instruction[31]}}, instruction[31:20]};
//            end

//            // --------------------------------------------------
//            // S-type: Store (SW, SH, SB)
//            // imm[11:5] = instr[31:25]
//            // imm[4:0]  = instr[11:7]
//            // Reassemble then sign-extend from bit 31
//            // --------------------------------------------------
//            STORE: begin
//                imm_out = {{20{instruction[31]}},
//                           instruction[31:25],
//                           instruction[11:7]};
//            end

//            // --------------------------------------------------
//            // B-type: Branch (BEQ, BNE, BLT, BGE, BLTU, BGEU)
//            // Bits are scrambled in the instruction word.
//            // Reassemble in correct order:
//            //   [12]   = instr[31]
//            //   [11]   = instr[7]
//            //   [10:5] = instr[30:25]
//            //   [4:1]  = instr[11:8]
//            //   [0]    = 0
//            // Sign-extend from bit 12 (bit 31 of instruction)
//            // --------------------------------------------------
//            BRANCH: begin
//                imm_out = {{19{instruction[31]}},
//                           instruction[31],
//                           instruction[7],
//                           instruction[30:25],
//                           instruction[11:8],
//                           1'b0};
//            end

//            // --------------------------------------------------
//            // Default: output zero for any unrecognised opcode
//            // --------------------------------------------------
//            default: begin
//                imm_out = 32'd0;
//            end

//        endcase
//    end

//endmodule


`timescale 1ns / 1ps
// ============================================================
// immGen.v
// Lab 11 - Task 1
//
// Immediate Generator - extracts and sign-extends the
// immediate value from a 32-bit RISC-V instruction.
//
// Lab 11 manual requires I, S and B type support only.
//
// Supported formats:
//
//   I-type (loads, ADDI, JALR):
//     imm[11:0] = instr[31:20]
//     sign-extended from bit 31 to 32 bits
//
//   S-type (stores SW, SH, SB):
//     imm[11:5] = instr[31:25]
//     imm[4:0]  = instr[11:7]
//     reassembled then sign-extended from bit 31 to 32 bits
//
//   B-type (branches BEQ, BNE, BLT, BGE etc.):
//     The instruction encodes bits [12:1] of the byte offset.
//     Bit 0 is always implicitly zero (2-byte aligned).
//
//     immGen outputs bits [12:1] sign-extended to 32 bits.
//     bit 0 is NOT appended here.
//
//     branchAdder then does PC + (imm << 1) per the manual,
//     which shifts bit 0 back in (as zero) giving the correct
//     byte offset.
//
//     Example: branch forward +8 bytes
//       Encoding stores bits[12:1] of 8 = 000000000100
//       immGen outputs: 0x00000004  (halfword count)
//       branchAdder:    PC + (4 << 1) = PC + 8  correct
//
//     Example: branch backward -8 bytes
//       Encoding stores bits[12:1] of -8 (signed) = 111111111100
//       immGen outputs: 0xFFFFFFFC  (-4 signed halfword count)
//       branchAdder:    PC + (-4 << 1) = PC - 8  correct
//
// Opcode values:
//   0000011 = Load     (I-type)
//   0010011 = I-arith  (I-type)
//   1100111 = JALR     (I-type)
//   0100011 = Store    (S-type)
//   1100011 = Branch   (B-type)
// ============================================================
module immGen (
    input  wire [31:0] instruction,   // full 32-bit instruction word
    output reg  [31:0] imm_out        // sign-extended immediate
);

    wire [6:0] opcode = instruction[6:0];

    localparam LOAD    = 7'b0000011;   // I-type
    localparam I_ARITH = 7'b0010011;   // I-type
    localparam JALR    = 7'b1100111;   // I-type
    localparam STORE   = 7'b0100011;   // S-type
    localparam BRANCH  = 7'b1100011;   // B-type

    always @(*) begin
        case (opcode)

            // --------------------------------------------------
            // I-type: Load, ADDI/ANDI/ORI/XORI, JALR
            // imm[11:0] from instr[31:20], sign-extended
            // --------------------------------------------------
            LOAD, I_ARITH, JALR: begin
                imm_out = {{20{instruction[31]}}, instruction[31:20]};
            end

            // --------------------------------------------------
            // S-type: Store (SW, SH, SB)
            // imm upper = instr[31:25], imm lower = instr[11:7]
            // reassembled and sign-extended
            // --------------------------------------------------
            STORE: begin
                imm_out = {{20{instruction[31]}},
                           instruction[31:25],
                           instruction[11:7]};
            end

            // --------------------------------------------------
            // B-type: Branch
            // Outputs bits[12:1] of the offset sign-extended.
            // bit 0 NOT appended - branchAdder shifts left 1.
            //
            // Bit assembly:
            //   imm[12]   = instr[31]   sign bit
            //   imm[11]   = instr[7]
            //   imm[10:5] = instr[30:25]
            //   imm[4:1]  = instr[11:8]
            //
            // Result is 12 bits assembled, sign-extended to 32
            // --------------------------------------------------
            BRANCH: begin
                imm_out = {{20{instruction[31]}},
                           instruction[31],
                           instruction[7],
                           instruction[30:25],
                           instruction[11:8]};
            end

            // --------------------------------------------------
            // Default: zero for unrecognised opcode
            // --------------------------------------------------
            default: begin
                imm_out = 32'd0;
            end

        endcase
    end

endmodule