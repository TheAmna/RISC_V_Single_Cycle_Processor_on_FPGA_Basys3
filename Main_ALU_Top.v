`timescale 1ns / 1ps

// Switch assignment 
//sw[6:0] opcode   (7 bits)
//sw[9:7]  funct3   (3 bits)
// sw[15]  funct7[5] (1 bit)

// LED display 
//led[0]   -> RegWrite
// led[1]   -> ALUSrc
// led[2]   -> MemRead
//led[3]   -> MemWrite
// led[4]   -> MemtoReg
// led[5]   -> Branch
// led[7:6] -> ALUOp[1:0]
// led[11:8]-> ALUControl[3:0]
//  led[15:12]-> 0 (unused)


module Main_ALU_Top #(
    parameter CLK_DIV_MAX   = 25_000_000,
    parameter DEBOUNCE_STAB = 500_000
)(
    input  wire        clk,
    input  wire        btn_reset_raw,   
    input  wire [15:0] sw_raw,
    output reg  [15:0] led_out
);

    // clock and reset
    wire slow_clk;
    wire btn_reset;

    clock_divider #(
        .MAX_COUNT(CLK_DIV_MAX)
    ) u_clkdiv (
        .clk      (clk),
        .rst      (1'b0),
        .slow_clk (slow_clk)
    );

    debouncer #(
        .STABLE_MAX(DEBOUNCE_STAB)
    ) u_debounce (
        .clk   (clk),
        .pbin  (btn_reset_raw),
        .pbout (btn_reset)
    );

   // switches
    wire [31:0] sw_synced_bus;
    wire [15:0] sw_synced;

    switches u_sw_sync (
        .clk         (clk),
        .rst         (btn_reset),
        .btns        (16'd0),
        .writeData   (32'd0),
        .writeEnable (1'b0),
        .readEnable  (1'b1),
        .memAddress  (30'd0),
        .switches    (sw_raw),
        .readData    (sw_synced_bus)
    );
    assign sw_synced = sw_synced_bus[15:0];

    // decoding switch inputs
    wire [6:0] opcode  = sw_synced[6:0];
    wire [2:0] funct3  = sw_synced[9:7];
    wire [6:0] funct7  = {1'b0, sw_synced[15], 5'b00000};

    // Control path
    wire       RegWrite, ALUSrc, MemRead, MemWrite, MemtoReg, Branch;
    wire [1:0] ALUOp;
    wire [3:0] ALUControl;

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

    ALUControl u_alu_ctrl (
        .ALUOp      (ALUOp),
        .funct3     (funct3),
        .funct7     (funct7),
        .ALUControl (ALUControl)
    );

    // FSM for FPGA verification
    // States:
    //   IDLE     : LEDs off, waiting for any switch to be set
    //   DISPLAY  : Show control signals on LEDs
    //   HOLD     : Keep display until switches change back to 0
    localparam IDLE    = 2'b00;
    localparam DISPLAY = 2'b01;
    localparam HOLD    = 2'b10;

    reg [1:0] state;
    reg [1:0] next_state;

    //State register
    always @(posedge clk) begin
        if (btn_reset)
            state <= IDLE;
        else
            state <= next_state;
    end

    //Next-state logic
    always @(*) begin
        case (state)
            IDLE:    next_state = (sw_synced != 16'd0) ? DISPLAY : IDLE;
            DISPLAY: next_state = HOLD;
            HOLD:    next_state = (sw_synced == 16'd0) ? IDLE : HOLD;
            default: next_state = IDLE;
        endcase
    end

    //Output logic: map control signals to LEDs
    always @(posedge clk) begin
        if (btn_reset) begin
            led_out <= 16'd0;
        end else begin
            case (state)
                IDLE: begin
                    led_out <= 16'd0;
                end

                DISPLAY, HOLD: begin
                    // LED mapping
                    led_out[0]    <= RegWrite;
                    led_out[1]    <= ALUSrc;
                    led_out[2]    <= MemRead;
                    led_out[3]    <= MemWrite;
                    led_out[4]    <= MemtoReg;
                    led_out[5]    <= Branch;
                    led_out[7:6]  <= ALUOp;
                    led_out[11:8] <= ALUControl;
                    led_out[15:12]<= 4'b0000;
                end

                default: led_out <= 16'd0;
            endcase
        end
    end

endmodule