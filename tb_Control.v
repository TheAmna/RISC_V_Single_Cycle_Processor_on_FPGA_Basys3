`timescale 1ns / 1ps

module tb_Control;

    //inputs
    reg  [6:0] opcode;
    reg  [2:0] funct3;
    reg  [6:0] funct7;

    // MainControl outputs
    wire       RegWrite;
    wire       ALUSrc;
    wire       MemRead;
    wire       MemWrite;
    wire       MemtoReg;
    wire       Branch;
    wire [1:0] ALUOp;

    // ALUControl output
    wire [3:0] ALUControl;

    // instantiate MainControl
    MainControl u_main (
        .opcode   (opcode),
        .RegWrite (RegWrite),
        .ALUSrc   (ALUSrc),
        .MemRead  (MemRead),
        .MemWrite (MemWrite),
        .MemtoReg (MemtoReg),
        .Branch   (Branch),
        .ALUOp    (ALUOp)
    );

    // instantiate ALUControl
    ALUControl u_alu_ctrl (
        .ALUOp      (ALUOp),
        .funct3     (funct3),
        .funct7     (funct7),
        .ALUControl (ALUControl)
    );

    initial begin
        $dumpfile("tb_Control.vcd");
        $dumpvars(0, tb_Control);

        // R-type: opcode = 0110011

        // ADD  funct3=000 funct7=0000000
        opcode=7'b0110011; funct3=3'b000; funct7=7'b0000000; #10;

        // SUB  funct3=000 funct7=0100000
        opcode=7'b0110011; funct3=3'b000; funct7=7'b0100000; #10;

        // SLL  funct3=001 funct7=0000000
        opcode=7'b0110011; funct3=3'b001; funct7=7'b0000000; #10;

        // SRL  funct3=101 funct7=0000000
        opcode=7'b0110011; funct3=3'b101; funct7=7'b0000000; #10;

        // AND  funct3=111 funct7=0000000
        opcode=7'b0110011; funct3=3'b111; funct7=7'b0000000; #10;

        // OR   funct3=110 funct7=0000000
        opcode=7'b0110011; funct3=3'b110; funct7=7'b0000000; #10;

        // XOR  funct3=100 funct7=0000000
        opcode=7'b0110011; funct3=3'b100; funct7=7'b0000000; #10;

        // I-type arithmetic: opcode = 0010011 

        // ADDI funct3=000
        opcode=7'b0010011; funct3=3'b000; funct7=7'b0000000; #10;

        // Load: opcode = 0000011 

        // LW   funct3=010
        opcode=7'b0000011; funct3=3'b010; funct7=7'b0000000; #10;

        // LH   funct3=001
        opcode=7'b0000011; funct3=3'b001; funct7=7'b0000000; #10;

        // LB   funct3=000
        opcode=7'b0000011; funct3=3'b000; funct7=7'b0000000; #10;

        // Store: opcode = 0100011 -

        // SW   funct3=010
        opcode=7'b0100011; funct3=3'b010; funct7=7'b0000000; #10;

        // SH   funct3=001
        opcode=7'b0100011; funct3=3'b001; funct7=7'b0000000; #10;

        // SB   funct3=000
        opcode=7'b0100011; funct3=3'b000; funct7=7'b0000000; #10;

        // Branch: opcode = 1100011 

        // BEQ  funct3=000
        opcode=7'b1100011; funct3=3'b000; funct7=7'b0000000; #10;

        $finish;
    end

endmodule