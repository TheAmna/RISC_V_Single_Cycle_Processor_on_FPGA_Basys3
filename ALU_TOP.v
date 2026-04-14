//`timescale 1ns / 1ps

//module ALU_TOP(
//    input  wire        clk,
//    input  wire        rst,
//    input  wire [15:0] sw,
//    input  wire        btn_next,
//    output wire [15:0] led
//);

//    wire [31:0] A = 32'h1010_1010;
//    wire [31:0] B = 32'h0101_0101;
//    wire [3:0]  ALUControl;
//    wire [31:0] ALUResult;
//    wire        Zero;
//    wire btn_clean;
//    debouncer #(
//        .STABLE_MAX(500_000)
//    ) U_debounce (
//        .clk   (clk),
//        .pbin  (btn_next),
//        .pbout (btn_clean)
//    );

//    reg [3:0] op_reg;
//    reg       btn_prev;
//    always @(posedge clk) begin
//        if (rst) begin
//            op_reg   <= 4'b0000;
//            btn_prev <= 1'b0;
//        end else begin
//            btn_prev <= btn_clean;
//            if (btn_clean == 1'b1 && btn_prev == 1'b0) begin
//                if (op_reg == 4'b0110)
//                    op_reg <= 4'b0000;
//                else if (op_reg == 4'b0000)
//                    op_reg <= 4'b0001;
//                else if (op_reg == 4'b0001)
//                    op_reg <= 4'b0010;
//                else if (op_reg == 4'b0010)
//                    op_reg <= 4'b0011;
//                else if (op_reg == 4'b0011)
//                    op_reg <= 4'b0100;
//                else if (op_reg == 4'b0100)
//                    op_reg <= 4'b0101;
//                else if (op_reg == 4'b0101)
//                    op_reg <= 4'b0110;
//                else
//                    op_reg <= 4'b0000;
//            end
//        end
//    end
//    assign ALUControl = op_reg;

//    ALU U_ALU (
//        .A          (A),
//        .B          (B),
//        .ALUControl (ALUControl),
//        .ALUResult  (ALUResult),
//        .Zero       (Zero)
//    );

//    wire [31:0] sw_readData;

//    leds U_sw_reader (
//        .clk         (clk),
//        .rst         (rst),
//        .btns        (16'd0),
//        .writeData   (32'd0),
//        .writeEnable (1'b0),
//        .readEnable  (1'b1),
//        .memAddress  (30'd0),
//        .switches    (sw),
//        .readData    (sw_readData)
//    );

//    wire [31:0] led_readData;

//    switches U_led_driver (
//        .clk         (clk),
//        .rst         (rst),
//        .writeData   ({15'd0, Zero, ALUResult[15:0]}),
//        .writeEnable (1'b1),
//        .readEnable  (1'b0),
//        .memAddress  (30'd0),
//        .readData    (led_readData),
//        .leds        (led)
//    );

//endmodule
`timescale 1ns / 1ps

module ALU_TOP (
    input clk, // 100 MHz fr
    input rst_raw,  // raw reset button (U18) 
    input [3:0] sw,       // 4 switches V17-W17 
    output [15:0] led       // 16 LEDs
);

    
    wire rst;
    debouncer #(
        .STABLE_MAX(500_000)   // ~5 ms debounce
    ) db_rst (
        .clk(clk),
        .pbin(rst_raw),
        .pbout(rst)
    );

    // =============================================
    // Hardcoded A and B as per manual example
    // =============================================
    wire [31:0] A = 32'h10101010;
    wire [31:0] B = 32'h01010101;

    // ALUControl directly from switches (4 bits)
    wire [3:0] ALUControl = sw;

    // ALU outputs
    wire [31:0] ALUResult;
    wire Zero;

    // Instantiate ALU 
    ALU alu_inst (
        .A(A),
        .B(B),
        .ALUControl(ALUControl),
        .ALUResult(ALUResult),
        .Zero(Zero)
    );

    
    // LD15 (L1) = Zero flag
    // LD0-LD14 = lower 15 bits of result
    
    assign led[14:0] = ALUResult[14:0];
    assign led[15]   = Zero;

endmodule