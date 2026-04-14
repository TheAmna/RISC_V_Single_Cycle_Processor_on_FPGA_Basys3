`timescale 1ns / 1ps

module InstructionMemory #(
    parameter OPERAND_LENGTH = 31
)(
    input  [OPERAND_LENGTH:0] instAddress, // PC - byte address from processor
    output reg [31:0]         instruction  // 32-bit instruction word output
);
    // 64 words of 32 bits = 256 bytes
    // each line in the .mem file fills one word slot
    reg [31:0] memory [0:63];
    initial begin
        // load the .mem file - one hex word per line, word-addressed
        // make sure program.mem is in the Vivado project working directory
        $readmemh("instruction.mem", memory);
    end
    // combinational read
    // PC is a byte address so divide by 4 to get the word index
    always @(*) begin
        instruction = memory[instAddress >> 2];
    end
endmodule





