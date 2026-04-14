`timescale 1ns / 1ps


module RF_ALU_FSM_tb;

    // conrol signals
    reg  clk;
    reg  rst;

    // FSM ? RegisterFile
    wire        WriteEnable;
    wire [4:0]  rs1, rs2, rd;
    wire [31:0] WriteData;

    // FSM ? ALU
    wire [3:0]  alu_ctrl;

    // RegisterFile ? ALU
    wire [31:0] ReadData1, ReadData2;

    // ALU ? everything
    wire [31:0] ALUResult;
    wire        Zero;

    // clock
    initial clk = 0;
    always #5 clk = ~clk;   // 10 ns period = 100 MHz

    //Instantiate RegisterFile 
    RegisterFile rf (
        .clk        (clk),
        .rst        (rst),
        .WriteEnable(WriteEnable),
        .rs1        (rs1),
        .rs2        (rs2),
        .rd         (rd),
        .WriteData  (WriteData),
        .ReadData1  (ReadData1),
        .ReadData2  (ReadData2)
    );

    // Instantiate ALU 
    ALU alu (
        .A         (ReadData1),
        .B         (ReadData2),
        .ALUControl(alu_ctrl),
        .ALUResult (ALUResult),
        .Zero      (Zero)
    );

    // Instantiate FSM 
    // alu_result fed back so FSM can mux it into WriteData
    RF_ALU_FSM fsm (
        .clk        (clk),
        .rst        (rst),
        .alu_zero   (Zero),
        .alu_result (ALUResult),
        .WriteEnable(WriteEnable),
        .rs1        (rs1),
        .rs2        (rs2),
        .rd         (rd),
        .alu_ctrl   (alu_ctrl),
        .WriteData  (WriteData)
    );

    
    task print_reg;
        input [4:0]  addr;
        input [31:0] expected;
        input [127:0] label;
        reg  [31:0]  val;
        begin
            // Force rs1 to read the register\
            force rf.rs1   = addr;
            #1;
            val = rf.ReadData1;
            release rf.rs1;
            if (val === expected)
                $display("PASS  [%0s]  x%0d = 0x%08h", label, addr, val);
            else
                $display("FAIL  [%0s]  x%0d : expected 0x%08h  got 0x%08h",
                          label, addr, expected, val);
        end
    endtask

    
    integer cycle;

    initial begin
        ;

        // Reset for 3 cycles
        rst = 1'b1;
        repeat(3) @(posedge clk);
        rst = 1'b0;

        // Run enough cycles for FSM to reach DONE
        // States: IDLE WRITE_X1 WRITE_X2 WRITE_X3 ADD SUB AND OR XOR SLL SRL
        //         ZERO_CHECK FLAG_WRITE READ_AFTER DONE = 15 states
        repeat(20) @(posedge clk);
        #1; // let combinational settle

    

        // x1 = 0x10101010 (constant)
        print_reg(5'd1,  32'h10101010,  "WRITE_X1");
        // x2 = 0x01010101 (constant)
        print_reg(5'd2,  32'h01010101,  "WRITE_X2");
        // x3 = 0x00000005 (shift amount)
        print_reg(5'd3,  32'h00000005,  "WRITE_X3");
        // x4 = x1 + x2 = 0x11111111
        print_reg(5'd4,  32'h11111111,  "ADD x1+x2");
        // x5 = x1 - x2 = 0x0F0F0F0F
        print_reg(5'd5,  32'h0F0F0F0F,  "SUB x1-x2");
        // x6 = x1 & x2 = 0x00000000
        print_reg(5'd6,  32'h00000000,  "AND x1&x2");
        // x7 = x1 | x2 = 0x11111111
        print_reg(5'd7,  32'h11111111,  "OR  x1|x2");
        // x8 = x1 ^ x2 = 0x11111111
        print_reg(5'd8,  32'h11111111,  "XOR x1^x2");
        // x9 = x1 << 5 = 0x10101010 << 5
        print_reg(5'd9,  32'h10101010 << 5, "SLL x1<<5");
        // x10 = x1 >> 5 = 0x10101010 >> 5
        print_reg(5'd10, 32'h10101010 >> 5, "SRL x1>>5");
        // x11 = x1 - x1 = 0  (ZERO_CHECK state)
        print_reg(5'd11, 32'h00000000,  "ZERO_CHECK");
        // x12 = 1 because Zero was set in ZERO_CHECK
        print_reg(5'd12, 32'h00000001,  "FLAG(BEQ)");

        $display("\n--- Zero flag (BEQ check) ---");
        // At READ_AFTER state rs1=x12 rs2=x10, just observe
        $display("INFO  ReadData1 (x12) = 0x%08h  ReadData2 (x10) = 0x%08h",
                  rf.ReadData1, rf.ReadData2);

        $display("\n=== Simulation complete ===\n");
        $finish;
    end

    // ?? Waveform dump ????????????????????????????????????????????
    initial begin
        $dumpfile("RF_ALU_FSM_tb.vcd");
        $dumpvars(0, RF_ALU_FSM_tb);
    end

    // ?? Cycle monitor (uncomment for verbose trace) ??????????????
    // always @(posedge clk)
    //     $display("t=%0t  state=%0d  rd=%0d  WE=%b  WD=0x%08h  A=0x%08h  B=0x%08h  ALU=0x%08h  Z=%b",
    //               $time, fsm.state, rd, WriteEnable, WriteData,
    //               ReadData1, ReadData2, ALUResult, Zero);

endmodule
