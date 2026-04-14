`timescale 1ns / 1ps
module DataMemory (
    input  wire        clk,
    input  wire        MemWrite,   // write enable 
    input  wire        MemRead,    // read  enable 
    input  wire [31:0] address,    // full address
    input  wire [31:0] write_data,
    output reg  [31:0] read_data
);
    // 512 words of 32 bits
    reg [31:0] mem [0:511];
    integer i; //initialising 
    initial begin
        for (i = 0; i < 512; i = i + 1)
            mem[i] = 32'd0;
    end
    // Synchronous write
    always @(posedge clk) begin
        if (MemWrite)
            mem[address[8:0]] <= write_data;
    end
    // Asynchronous (combinational) read
    always @(MemRead or address) begin
        if (MemRead)
            read_data = mem[address[8:0]];
        else
            read_data = 32'd0;
    end
endmodule