`timescale 1ns / 1ps
module MemorySystem_tb;
    reg         clk;
    reg         rst;
    reg  [31:0] address;
    reg         readEnable;
    reg         writeEnable;
    reg  [31:0] writeData;
    reg  [15:0] switches;
    wire [31:0] readData;
    wire [15:0] leds;
    wire DataMemWrite     = uut.DataMemWrite;
    wire DataMemRead      = uut.DataMemRead;
    wire LEDWrite         = uut.LEDWrite;
    wire SwitchReadEnable = uut.SwitchReadEnable;
    addressDecoderTop uut (
        .clk         (clk),
        .rst         (rst),
        .address     (address),
        .readEnable  (readEnable),
        .writeEnable (writeEnable),
        .writeData   (writeData),
        .switches    (switches),
        .readData    (readData),
        .leds        (leds)
    );

    initial clk = 0;
    always  #5 clk = ~clk;
    task do_write;
        input [31:0] addr;
        input [31:0] data;
        begin
            @(negedge clk);
            address     = addr;
            writeData   = data;
            writeEnable = 1;
            readEnable  = 0;
            @(posedge clk); #1;
            writeEnable = 0;
            address     = 32'd0;
            writeData   = 32'd0;
        end
    endtask
    task do_read;
        input [31:0] addr;
        begin
            @(negedge clk);
            address     = addr;
            writeEnable = 0;
            readEnable  = 1;
            @(posedge clk); #1;
            readEnable  = 0;
            address     = 32'd0;
        end
    endtask
    task bus_idle;
        input integer cycles;
        begin
            address     = 32'd0;
            writeEnable = 0;
            readEnable  = 0;
            writeData   = 32'd0;
            repeat(cycles) @(posedge clk);
            #1;
        end
    endtask
    initial begin
        address     = 32'd0;
        writeEnable = 0;
        readEnable  = 0;
        writeData   = 32'd0;
        switches    = 16'd0;
        rst = 1;
        repeat(4) @(posedge clk); #1;
        rst = 0;
        bus_idle(2);
        do_write(32'h004, 32'hDEADBEEF);   // DataMem[4]   <- 0xDEADBEEF
        bus_idle(1);
        do_write(32'h008, 32'hCAFEBABE);   // DataMem[8]   <- 0xCAFEBABE
        bus_idle(1);
        do_write(32'h064, 32'hAABBCCDD);   // DataMem[100] <- 0xAABBCCDD
        bus_idle(2);
        do_read(32'h004);
        bus_idle(1);
        do_read(32'h008);
        bus_idle(1);
        do_read(32'h064);
        bus_idle(1);
        do_read(32'h010);   // uninitialised location
        bus_idle(2);
        do_write(32'h200, 32'h0000AAAA);   // LEDs <- 0xAAAA
        bus_idle(1);
        do_write(32'h201, 32'h00005555);   // LEDs <- 0x5555
        bus_idle(2);
        do_read(32'h000);                  // DataMem[0] must still be 0x00000000
        bus_idle(2);
        switches = 16'hF0F0;
        bus_idle(3);
        do_read(32'h300);
        bus_idle(1);

        switches = 16'h0F0F;
        bus_idle(3);
        do_read(32'h300);
        bus_idle(2);
        @(negedge clk);
        address = 32'h010; writeEnable = 1; readEnable = 1;
        writeData = 32'hFFFFFFFF;
        @(posedge clk); #1;
        writeEnable = 0; readEnable = 0;
        bus_idle(1);

        @(negedge clk);
        address = 32'h200; writeEnable = 1; readEnable = 1;
        writeData = 32'hFFFFFFFF;
        @(posedge clk); #1;
        writeEnable = 0; readEnable = 0;
        bus_idle(1);

        @(negedge clk);
        address = 32'h300; writeEnable = 1; readEnable = 1;
        writeData = 32'hFFFFFFFF;
        @(posedge clk); #1;
        writeEnable = 0; readEnable = 0;
        bus_idle(1);

        @(negedge clk);
        address = 32'h1C0; writeEnable = 1; readEnable = 1;
        writeData = 32'hFFFFFFFF;
        @(posedge clk); #1;
        writeEnable = 0; readEnable = 0;
        bus_idle(2);
        do_write(32'h005, 32'hABCD1234);
        bus_idle(1);
        do_write(32'h205, 32'hFFFFFFFF);   // LED write - must not corrupt DataMem[5]
        bus_idle(1);
        do_read(32'h005);                  // readData must still be 0xABCD1234
        bus_idle(3);

        $finish;
    end
    initial begin
        #20000;
        $finish;
    end
endmodule