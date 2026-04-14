//`timescale 1ns / 1ps
//module ALU_1bit (
//    input  wire       a,
//    input  wire       b,
//    input  wire       cin,
//    input  wire       ainvert,
//    input  wire       binvert,
//    input  wire [1:0] operation,
//    output reg        result,
//    output wire       cout
//);

//    reg a_in;
//    reg b_in;
//    always @(*) begin
//        if (ainvert == 1)
//            a_in = ~a;
//        else
//            a_in = a;
//    end
//    always @(*) begin
//        if (binvert == 1)
//            b_in = ~b;
//        else
//            b_in = b;
//    end

//    wire and_result = a_in & b_in;
//    wire or_result  = a_in | b_in;
//    wire xor_result = a_in ^ b_in;

//    wire sum;
//    FullAdder FA (
//        .a    (a_in),
//        .b    (b_in),
//        .cin  (cin),
//        .sum  (sum),
//        .cout (cout)
//    );

//    always @(*) begin
//        if (operation == 2'b00)
//            result = and_result;
//        else if (operation == 2'b01)
//            result = or_result;
//        else if (operation == 2'b10)
//            result = sum;
//        else if (operation == 2'b11)
//            result = xor_result;
//        else
//            result = 1'b0;
//    end

//endmodule

// ===============================================
// ALU_1bit.v
// 1-bit ALU slice (used to understand the basic building block)
// Supports: AND, OR, XOR, ADD, SUB (SUB uses inverted B + cin=1 from top level)
// Shifts are handled only in the 32-bit top module (as per standard design)
// ===============================================
module ALU_1bit (
    input a,                // 1-bit from A
    input b,                // 1-bit from B (already inverted if SUB)
    input cin,              // Carry in
    input [3:0] alucontrol, // Same control as top module
    output reg result,      // 1-bit result
    output reg cout         // Carry out (only used in ADD/SUB)
);

    // Basic logic operations (parallel)
    wire and_res = a & b;
    wire or_res  = a | b;
    wire xor_res = a ^ b;

    // Arithmetic using FullAdder
    wire fa_sum;
    wire fa_cout;
    FullAdder fa (
        .a(a),
        .b(b),
        .cin(cin),
        .sum(fa_sum),
        .cout(fa_cout)
    );

    always @(*) begin
        cout = fa_cout;   // Carry out only meaningful for ADD/SUB

        if (alucontrol == 4'b0000)      // AND
            result = and_res;
        else if (alucontrol == 4'b0001) // OR
            result = or_res;
        else if (alucontrol == 4'b0100) // XOR
            result = xor_res;
        else if (alucontrol == 4'b0010 || alucontrol == 4'b0110) // ADD or SUB
            result = fa_sum;
        else
            result = 1'b0; // default (never used in normal operation)
    end
endmodule