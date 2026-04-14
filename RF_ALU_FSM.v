
`timescale 1ns / 1ps

module RF_ALU_FSM (
    input  wire        clk,
    input  wire        rst,
    input  wire        alu_zero,
    input  wire [31:0] alu_result,
    output reg         WriteEnable,
    output reg  [4:0]  rd,
    output wire [4:0]  rs1,          // COMBINATIONAL - wire not reg
    output wire [4:0]  rs2,          // COMBINATIONAL - wire not reg
    output wire [3:0]  alu_ctrl,     // COMBINATIONAL - wire not reg
    output reg  [31:0] WriteData
);

    reg [4:0] state;

    // ?? State encoding ??????????????????????????????????????????
    parameter IDLE       = 5'd0;
    parameter WRITE_X1   = 5'd1;
    parameter WRITE_X2   = 5'd2;
    parameter WRITE_X3   = 5'd3;
    parameter ADD_OP     = 5'd4;
    parameter SUB_OP     = 5'd5;
    parameter AND_OP     = 5'd6;
    parameter OR_OP      = 5'd7;
    parameter XOR_OP     = 5'd8;
    parameter SLL_OP     = 5'd9;
    parameter SRL_OP     = 5'd10;
    parameter ZERO_CHECK = 5'd11;
    parameter FLAG_WRITE = 5'd12;
    parameter READ_AFTER = 5'd13;
    parameter DONE       = 5'd14;

    // ?? Combinational output decode ?????????????????????????????
    // rs1, rs2, alu_ctrl are pure functions of the current state.
    // They update in the SAME cycle the state changes, so the ALU
    // always has valid inputs before the next rising edge arrives.
    reg [4:0] rs1_r, rs2_r;
    reg [3:0] alu_ctrl_r;
    assign rs1      = rs1_r;
    assign rs2      = rs2_r;
    assign alu_ctrl = alu_ctrl_r;

    always @(*) begin
        case (state)
            ADD_OP:     begin rs1_r = 5'd1;  rs2_r = 5'd2;  alu_ctrl_r = 4'b0010; end
            SUB_OP:     begin rs1_r = 5'd1;  rs2_r = 5'd2;  alu_ctrl_r = 4'b0110; end
            AND_OP:     begin rs1_r = 5'd1;  rs2_r = 5'd2;  alu_ctrl_r = 4'b0000; end
            OR_OP:      begin rs1_r = 5'd1;  rs2_r = 5'd2;  alu_ctrl_r = 4'b0001; end
            XOR_OP:     begin rs1_r = 5'd1;  rs2_r = 5'd2;  alu_ctrl_r = 4'b0100; end
            SLL_OP:     begin rs1_r = 5'd1;  rs2_r = 5'd3;  alu_ctrl_r = 4'b1000; end
            SRL_OP:     begin rs1_r = 5'd1;  rs2_r = 5'd3;  alu_ctrl_r = 4'b1001; end
            ZERO_CHECK: begin rs1_r = 5'd1;  rs2_r = 5'd1;  alu_ctrl_r = 4'b0110; end
            READ_AFTER: begin rs1_r = 5'd12; rs2_r = 5'd10; alu_ctrl_r = 4'b0000; end
            default:    begin rs1_r = 5'd0;  rs2_r = 5'd0;  alu_ctrl_r = 4'b0000; end
        endcase
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state       <= IDLE;
            WriteEnable <= 1'b0;
            rd          <= 5'd0;
            WriteData   <= 32'd0;
        end
        else begin
            case (state)

                IDLE: begin
                    WriteEnable <= 1'b0;
                    state       <= WRITE_X1;
                end

                // ?? Write constants ??????????????????????????????
                WRITE_X1: begin
                    rd          <= 5'd1;
                    WriteData   <= 32'h10101010;
                    WriteEnable <= 1'b1;
                    state       <= WRITE_X2;
                end

                WRITE_X2: begin
                    rd          <= 5'd2;
                    WriteData   <= 32'h01010101;
                    WriteEnable <= 1'b1;
                    state       <= WRITE_X3;
                end

                WRITE_X3: begin
                    rd          <= 5'd3;
                    WriteData   <= 32'h00000005;
                    WriteEnable <= 1'b1;
                    state       <= ADD_OP;
                end

                // ?? ALU op states ????????????????????????????????
                // rs1/rs2/alu_ctrl are already live combinationally
                // the moment we enter this state.
                // We register rd and WriteData=alu_result so they
                // are stable at the NEXT posedge when the RF writes.

                ADD_OP: begin
                    rd          <= 5'd4;
                    WriteData   <= alu_result;
                    WriteEnable <= 1'b1;
                    state       <= SUB_OP;
                end

                SUB_OP: begin
                    rd          <= 5'd5;
                    WriteData   <= alu_result;
                    WriteEnable <= 1'b1;
                    state       <= AND_OP;
                end

                AND_OP: begin
                    rd          <= 5'd6;
                    WriteData   <= alu_result;
                    WriteEnable <= 1'b1;
                    state       <= OR_OP;
                end

                OR_OP: begin
                    rd          <= 5'd7;
                    WriteData   <= alu_result;
                    WriteEnable <= 1'b1;
                    state       <= XOR_OP;
                end

                XOR_OP: begin
                    rd          <= 5'd8;
                    WriteData   <= alu_result;
                    WriteEnable <= 1'b1;
                    state       <= SLL_OP;
                end

                SLL_OP: begin
                    rd          <= 5'd9;
                    WriteData   <= alu_result;
                    WriteEnable <= 1'b1;
                    state       <= SRL_OP;
                end

                SRL_OP: begin
                    rd          <= 5'd10;
                    WriteData   <= alu_result;
                    WriteEnable <= 1'b1;
                    state       <= ZERO_CHECK;
                end

                ZERO_CHECK: begin
                    rd          <= 5'd11;
                    WriteData   <= alu_result;
                    WriteEnable <= 1'b1;
                    state       <= FLAG_WRITE;
                end

                // alu_zero is a combinational wire from the ALU.
                // ZERO_CHECK already set rs1=rs2=x1, alu_ctrl=SUB
                // combinationally, so alu_zero is correct NOW.
                FLAG_WRITE: begin
                    rd          <= 5'd12;
                    WriteData   <= alu_zero ? 32'h00000001 : 32'h00000000;
                    WriteEnable <= 1'b1;
                    state       <= READ_AFTER;
                end

                READ_AFTER: begin
                    // rs1=x12, rs2=x10 driven combinationally above
                    WriteEnable <= 1'b0;
                    state       <= DONE;
                end

                DONE: begin
                    WriteEnable <= 1'b0;
                end

                default: state <= IDLE;

            endcase
        end
    end

endmodule
