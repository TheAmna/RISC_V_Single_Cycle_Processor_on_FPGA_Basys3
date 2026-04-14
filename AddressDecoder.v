`timescale 1ns / 1ps
module AddressDecoder (
    input  wire        readEnable,  
    input  wire        writeEnable,  
    input  wire [31:0] address,  
    output wire        DataMemWrite,
    output wire        DataMemRead,
    output wire        LEDWrite,
    output wire        SwitchReadEnable
);
    wire [1:0] devSel = address[9:8];
    // Data Memory: address[9] = 0  (ranges 0x000-0x1FF, i.e. devSel=00 or 01)
    assign DataMemWrite     = writeEnable & (address[9] == 1'b0);
    assign DataMemRead      = readEnable  & (address[9] == 1'b0);
    // LEDs: address[9:8] = 10  (range 0x200-0x2FF, 512-767)
    assign LEDWrite         = writeEnable & (devSel == 2'b10);
    // Switches: address[9:8] = 11  (range 0x300-0x3FF, 768-1023)
    assign SwitchReadEnable = readEnable  & (devSel == 2'b11);
endmodule