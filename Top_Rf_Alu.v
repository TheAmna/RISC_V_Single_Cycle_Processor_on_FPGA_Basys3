`timescale 1ns / 1ps

module Top_Rf_Alu #(
    parameter CLK_DIV_MAX   = 25_000_000,
    parameter DEBOUNCE_STAB = 500_000
)(
    input  wire        clk,
    input  wire        btn_reset_raw,
    input  wire [15:0] sw_raw,
    output reg  [15:0] led_out
);

    //Reset debounce
    wire rst;
    debouncer #(.STABLE_MAX(DEBOUNCE_STAB)) u_deb (
        .clk   (clk),
        .pbin  (btn_reset_raw),
        .pbout (rst)
    );


    reg [15:0] sw_meta, sw_sync;
    always @(posedge clk) begin
        sw_meta <= sw_raw;
        sw_sync <= sw_meta;
    end

    // FSM wires 
    wire        fsm_WriteEnable;
    wire [4:0]  fsm_rs1, fsm_rs2, fsm_rd;
    wire [3:0]  fsm_alu_ctrl;
    wire [31:0] fsm_WriteData;
    wire        alu_zero;
    wire [31:0] alu_result;

    
    // sw_sync[15]=1 ? use sw_sync[3:0] as ALUControl directly.
    
    wire [3:0] alu_ctrl_sel = sw_sync[15] ? sw_sync[3:0]
                                           : fsm_alu_ctrl;

    //RegisterFile 
    wire [31:0] ReadData1, ReadData2;

    RegisterFile u_rf (
        .clk        (clk),
        .rst        (rst),
        .WriteEnable(fsm_WriteEnable),
        .rs1        (fsm_rs1),
        .rs2        (fsm_rs2),
        .rd         (fsm_rd),
        .WriteData  (fsm_WriteData),
        .ReadData1  (ReadData1),
        .ReadData2  (ReadData2)
    );

    // ALU 
    ALU u_alu (
        .A         (ReadData1),
        .B         (ReadData2),
        .ALUControl(alu_ctrl_sel),
        .ALUResult (alu_result),
        .Zero      (alu_zero)
    );

    //FSM 
    RF_ALU_FSM u_fsm (
        .clk        (clk),
        .rst        (rst),
        .alu_zero   (alu_zero),
        .alu_result (alu_result),
        .WriteEnable(fsm_WriteEnable),
        .rs1        (fsm_rs1),
        .rs2        (fsm_rs2),
        .rd         (fsm_rd),
        .alu_ctrl   (fsm_alu_ctrl),
        .WriteData  (fsm_WriteData)
    );

    //  LED register 
    
    always @(posedge clk) begin
        if (rst) begin
            led_out <= 16'd0;
        end else begin
            led_out[3:0]  <= u_fsm.state[3:0];
            led_out[14:5] <= alu_result[9:0];
            led_out[15]   <= alu_zero;
        end
    end

endmodule
