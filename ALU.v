//`timescale 1ns / 1ps
//module ALU(
//    input  wire [31:0] A,
//    input  wire [31:0] B,
//    input  wire [3:0]  ALUControl,
//    output wire [31:0] ALUResult,
//    output wire        Zero
//);

//    wire        ainvert;
//    wire        binvert;
//    wire [1:0]  operation;
//    assign ainvert   = ALUControl[3];
//    assign binvert   = ALUControl[2];
//    assign operation = ALUControl[1:0];
//    wire [32:0] carry;
//    assign carry[0] = binvert;
//    wire [31:0] slice_result;
//    genvar i;
//    generate
//        for (i = 0; i < 32; i = i + 1) begin : SLICE
//            ALU_1bit U_slice (
//                .a         (A[i]),
//                .b         (B[i]),
//                .cin       (carry[i]),
//                .ainvert   (ainvert),
//                .binvert   (binvert),
//                .operation (operation),
//                .result    (slice_result[i]),
//                .cout      (carry[i+1])
//            );
//        end
//    endgenerate

//    wire [31:0] sll_result;
//    wire [31:0] srl_result;

//    assign sll_result = A << B[4:0];
//    assign srl_result = A >> B[4:0];

//    reg [31:0] alu_out;

//    always @(*) begin
//        if (ALUControl == 4'b0100)
//            alu_out = sll_result;
//        else if (ALUControl == 4'b0101)
//            alu_out = srl_result;
//        else
//            alu_out = slice_result;
//    end

//    assign ALUResult = alu_out;

//    reg zero_flag;

//    always @(*) begin
//        if (ALUResult == 32'b0)
//            zero_flag = 1;
//        else
//            zero_flag = 0;
//    end

//    assign Zero = zero_flag;

//endmodule


// ===============================================
// ALU.v   <-- This is the main 32-bit ALU you will use
// Inputs and outputs exactly as mentioned in the manual
// ===============================================
module ALU (
    input [31:0] A,           // 32-bit operand A
    input [31:0] B,           // 32-bit operand B
    input [3:0] ALUControl,   // 4-bit control signal
    output reg [31:0] ALUResult, // 32-bit result
    output Zero               // Zero flag for BEQ
);

    // =========================================
    // Operation codes (easy to read and change)
    // =========================================
    localparam AND_OP = 4'b0000;
    localparam OR_OP  = 4'b0001;
    localparam ADD_OP = 4'b0010;
    localparam SUB_OP = 4'b0110;
    localparam XOR_OP = 4'b0100;
    localparam SLL_OP = 4'b1000;
    localparam SRL_OP = 4'b1001;

    // =========================================
    // 1. Arithmetic: 32-bit ripple carry adder using FullAdder
    //    (shows Carry In / Carry Out clearly)
    // =========================================
    wire [31:0] B_for_adder;
    wire [32:0] carry;           // carry[0] = cin for LSB, carry[32] ignored
    wire [31:0] add_result;

    // B inversion for SUB (using if - no ternary)
    reg [31:0] B_temp;
    always @(*) begin
        if (ALUControl == SUB_OP)
            B_temp = ~B;      // invert for 2's complement subtraction
        else
            B_temp = B;
    end
    assign B_for_adder = B_temp;

    // Carry-in for LSB (1 only for SUB)
    reg cin_lsb;
    always @(*) begin
        if (ALUControl == SUB_OP)
            cin_lsb = 1'b1;
        else
            cin_lsb = 1'b0;
    end
    assign carry[0] = cin_lsb;

    // Instantiate 32 FullAdders (ripple carry)
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : ripple_adder
            FullAdder fa (
                .a(A[i]),
                .b(B_for_adder[i]),
                .cin(carry[i]),
                .sum(add_result[i]),
                .cout(carry[i+1])
            );
        end
    endgenerate

    // =========================================
    // 2. Logic operations (very simple bitwise)
    // =========================================
    wire [31:0] and_result = A & B;
    wire [31:0] or_result  = A | B;
    wire [31:0] xor_result = A ^ B;

    // =========================================
    // 3. Shift operations (simple and synthesizable)
    //    Only lower 5 bits of B are used as shift amount (RV32I standard)
    // =========================================
    wire [31:0] sll_result = A << B[4:0];   // Shift Left Logical
    wire [31:0] srl_result = A >> B[4:0];   // Shift Right Logical (zero fill)

    // =========================================
    // 4. Big multiplexer using only if-else (no ternary)
    // =========================================
    always @(*) begin
        if (ALUControl == AND_OP)
            ALUResult = and_result;
        else if (ALUControl == OR_OP)
            ALUResult = or_result;
        else if (ALUControl == XOR_OP)
            ALUResult = xor_result;
        else if (ALUControl == ADD_OP || ALUControl == SUB_OP)
            ALUResult = add_result;
        else if (ALUControl == SLL_OP)
            ALUResult = sll_result;
        else if (ALUControl == SRL_OP)
            ALUResult = srl_result;
        else
            ALUResult = 32'b0;   // default (safe)
    end

    // =========================================
    // 5. Zero flag (for BEQ instruction)
    // =========================================
    assign Zero = (ALUResult == 32'b0);

endmodule