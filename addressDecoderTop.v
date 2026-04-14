`timescale 1ns / 1ps
module addressDecoderTop (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] address,
    input  wire        readEnable,
    input  wire        writeEnable,
    input  wire [31:0] writeData,
    input  wire [15:0] switches,   
    output wire [31:0] readData,
    output wire [15:0] leds       
);
    wire DataMemWrite;
    wire DataMemRead;
    wire LEDWrite;
    wire SwitchReadEnable;
    AddressDecoder u_decoder (
        .readEnable       (readEnable),
        .writeEnable      (writeEnable),
        .address          (address),
        .DataMemWrite     (DataMemWrite),
        .DataMemRead      (DataMemRead),
        .LEDWrite         (LEDWrite),
        .SwitchReadEnable (SwitchReadEnable)
    );
    
    wire [31:0] dataMem_readData;
    DataMemory u_datamem (
        .clk        (clk),
        .MemWrite   (DataMemWrite),
        .MemRead    (DataMemRead),
        .address    (address),
        .write_data (writeData),
        .read_data  (dataMem_readData)
    );

    wire [31:0] led_readData;   
    leds u_leds (
        .clk         (clk),
        .rst         (rst),
        .btns        (16'd0),
        .writeData   (writeData),    
        .writeEnable (LEDWrite),    
        .readEnable  (1'b0),
        .memAddress  (address[29:0]),
        .switches    (switches),     // physical switch input - synchronised here
        .readData    (led_readData)  // synchronised switch value output
    );

    reg [15:0] led_reg;
    always @(posedge clk) begin
        if (rst)
            led_reg <= 16'd0;
        else if (LEDWrite)
            led_reg <= writeData[15:0];
    end
    assign leds = led_reg;
    wire [31:0] switch_readData_nc;
    switches u_switches (
        .clk         (clk),
        .rst         (rst),
        .writeData   (32'd0),
        .writeEnable (1'b0),
        .readEnable  (SwitchReadEnable),
        .memAddress  (address[29:0]),
        .readData    (switch_readData_nc),  // not connected - switches.v never drives this
        .leds        ()                     // not connected - LEDs driven by led_reg above
    );
    assign readData = (address[9] == 1'b0)        ? dataMem_readData :
                      (address[9:8] == 2'b11)     ? led_readData     :
                                              32'd0;
endmodule