////`timescale 1ns / 1ps
////`timescale 1ns/1ps

////module ALU_tb;

////    reg  [31:0] A;
////    reg  [31:0] B;
////    reg  [ 3:0] ALUControl;
////    wire [31:0] ALUResult;
////    wire        Zero;

////    ALU dut (
////        .A          (A),
////        .B          (B),
////        .ALUControl (ALUControl),
////        .ALUResult  (ALUResult),
////        .Zero       (Zero)
////    );

////    initial begin
////        $dumpfile("ALU_tb.vcd");
////        $dumpvars(0, ALU_tb);

////        A = 32'hFF00_FF00; B = 32'h0F0F_0F0F; ALUControl = 4'b0000; #20;

////        A = 32'hAAAA_AAAA; B = 32'h5555_5555; ALUControl = 4'b0000; #20;

////        A = 32'hFF00_0000; B = 32'h00FF_0000; ALUControl = 4'b0001; #20;

////        A = 32'h0000_0000; B = 32'h0000_0000; ALUControl = 4'b0001; #20;

////        A = 32'h0000_0005; B = 32'h0000_0003; ALUControl = 4'b0010; #20;

////        A = 32'hFFFF_FFFF; B = 32'h0000_0001; ALUControl = 4'b0010; #20;

////        A = 32'h0000_000A; B = 32'h0000_0003; ALUControl = 4'b0110; #20;

////        A = 32'h0000_0005; B = 32'h0000_0005; ALUControl = 4'b0110; #20;

////        A = 32'h0000_0000; B = 32'h0000_0001; ALUControl = 4'b0110; #20;

////        A = 32'hAAAA_AAAA; B = 32'h5555_5555; ALUControl = 4'b0011; #20;

////        A = 32'hDEAD_BEEF; B = 32'hDEAD_BEEF; ALUControl = 4'b0011; #20;

////        A = 32'h0000_0001; B = 32'h0000_0004; ALUControl = 4'b0100; #20;

////        A = 32'h0000_0001; B = 32'h0000_001F; ALUControl = 4'b0100; #20;

////        A = 32'hFFFF_FFFF; B = 32'h0000_0008; ALUControl = 4'b0100; #20;

////        A = 32'h8000_0000; B = 32'h0000_0001; ALUControl = 4'b0101; #20;

////        A = 32'hFFFF_FFFF; B = 32'h0000_0008; ALUControl = 4'b0101; #20;

////        A = 32'h8000_0000; B = 32'h0000_001F; ALUControl = 4'b0101; #20;

////        #20;
////        $finish;
////    end

////endmodule


//`timescale 1ns/1ps

//module ALU_tb;

//    reg        a;
//    reg        b;
//    reg        cin;
//    reg        ainvert;
//    reg        binvert;
//    reg [1:0]  operation;
//    wire       result;
//    wire       cout;

//    ALU_1bit dut (
//        .a         (a),
//        .b         (b),
//        .cin       (cin),
//        .ainvert   (ainvert),
//        .binvert   (binvert),
//        .operation (operation),
//        .result    (result),
//        .cout      (cout)
//    );

//    initial begin
//        $dumpfile("ALU_tb.vcd");
//        $dumpvars(0, ALU_tb);

//        ainvert = 0; binvert = 0; cin = 0; operation = 2'b00;
//        a = 0; b = 0; #20;
//        a = 0; b = 1; #20;
//        a = 1; b = 0; #20;
//        a = 1; b = 1; #20;

//        ainvert = 0; binvert = 0; cin = 0; operation = 2'b01;
//        a = 0; b = 0; #20;
//        a = 0; b = 1; #20;
//        a = 1; b = 0; #20;
//        a = 1; b = 1; #20;

//        ainvert = 0; binvert = 0; cin = 0; operation = 2'b10;
//        a = 0; b = 0; #20;
//        a = 0; b = 1; #20;
//        a = 1; b = 0; #20;
//        a = 1; b = 1; #20;

//        ainvert = 0; binvert = 0; cin = 1; operation = 2'b10;
//        a = 0; b = 0; #20;
//        a = 0; b = 1; #20;
//        a = 1; b = 0; #20;
//        a = 1; b = 1; #20;

//        ainvert = 0; binvert = 1; cin = 1; operation = 2'b10;
//        a = 0; b = 0; #20;
//        a = 0; b = 1; #20;
//        a = 1; b = 0; #20;
//        a = 1; b = 1; #20;

//        ainvert = 0; binvert = 0; cin = 0; operation = 2'b11;
//        a = 0; b = 0; #20;
//        a = 0; b = 1; #20;
//        a = 1; b = 0; #20;
//        a = 1; b = 1; #20;

//        #20;
//        $finish;
//    end

//endmodule

`timescale 1ns / 1ps

module ALU_TOP_tb;

    reg clk;
    reg rst_raw;               
    reg [3:0] sw;      // only 4 bits are used
    wire [15:0] led;

    ALU_TOP dut (
        .clk(clk),
        .rst_raw(rst_raw),
        .sw(sw),
        .led(led)
    );

    // 100 MHz clock 
    always #5 clk = ~clk;

    initial begin
        $dumpfile("ALU_TOP_tb.vcd");
        $dumpvars(0, ALU_TOP_tb);

        // Initialize
        clk     = 0;
        rst_raw = 1;            // assert reset
        sw      = 4'b0000;

        #100;                   // hold reset for 100 ns
        rst_raw = 0;            // release reset

        #100;                   // wait after reset release

        // Test valid operations 
        sw = 4'b0000;   #300;   // AND
        sw = 4'b0001;   #300;   // OR
        sw = 4'b0010;   #300;   // ADD
        sw = 4'b0110;   #300;   // SUB
        sw = 4'b0100;   #300;   // XOR
        sw = 4'b1000;   #300;   // SLL
        sw = 4'b1001;   #300;   // SRL

        // Optional: test default case (invalid code)
        sw = 4'b0011;   #200;   // should give 0

        #100;
        $finish;
    end

endmodule