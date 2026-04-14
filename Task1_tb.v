//`timescale 1ns / 1ps

//// Wires all five Task 1 modules together exactly as they
//// will appear inside TopLevelProcessor.v.
////   TEST 1 - Sequential (PCSrc=0):
////     PC should count  0x00 -> 0x04 -> 0x08 -> 0x0C -> 0x10
////     PC_Plus4 is always PC + 4
////
////   TEST 2 - I-type immediates (immGen):
////     instruction = 0x06400093  -> imm_out = 0x00000064  (+100)
////     instruction = 0xFFC00093  -> imm_out = 0xFFFFFFFC  (-4)
////
////   TEST 3 - S-type immediates (immGen):
////     instruction = 0x00112423  -> imm_out = 0x00000008  (+8)
////     instruction = 0xFE112EA3  -> imm_out = 0xFFFFFFFC  (-4)
////
////   TEST 4 - B-type immediates (immGen):
////     instruction = 0x04000063  -> imm_out = 0x00000004  (+4, branch +8 bytes)
////     instruction = 0xFE000CE3  -> imm_out = 0xFFFFFFFC  (-4, branch -8 bytes)
////
////   TEST 5 - Branch taken (PCSrc=1):
////     PC should jump by (imm_out << 1) each cycle
////     instead of incrementing by 4
////
////   TEST 6 - Back to sequential (PCSrc=0):
////     PC increments by 4 again normally
////
////   TEST 7 - Reset:
////     PC drops back to 0x00000000
////     then resumes counting from 0
//// ============================================================
//module Task1_tb;

//    // -------------------------------------------------------
//    // Testbench driven signals
//    // -------------------------------------------------------
//    reg         clk;
//    reg         rst;
//    reg         PCSrc;          // manually driven here
//                                // in full processor: Branch AND Zero
//    reg  [31:0] instruction;    // manually driven to test immGen

//    // -------------------------------------------------------
//    // Wires connecting the five modules
//    // -------------------------------------------------------
//    wire [31:0] PC;             // output of ProgramCounter
//    wire [31:0] PC_Plus4;       // output of pcAdder
//    wire [31:0] imm_out;        // output of immGen
//    wire [31:0] BranchTarget;   // output of branchAdder
//    wire [31:0] PC_Next;        // output of mux2 -> feeds back into PC

//    // -------------------------------------------------------
//    // Module instantiations
//    // -------------------------------------------------------

//    // 1. Program Counter
//    //    Holds current PC, updates every rising clock edge
//    ProgramCounter u_pc (
//        .clk     (clk),
//        .rst     (rst),
//        .PC_Next (PC_Next),
//        .PC      (PC)
//    );

//    // 2. PC + 4 adder
//    //    Always computes PC + 4, purely combinational
//    pcAdder u_pcAdder (
//        .PC       (PC),
//        .PC_Plus4 (PC_Plus4)
//    );

//    // 3. Immediate generator
//    //    Extracts and sign-extends immediate from instruction word
//    immGen u_immGen (
//        .instruction (instruction),
//        .imm_out     (imm_out)
//    );

//    // 4. Branch target adder
//    //    Computes PC + (imm << 1)
//    branchAdder u_branchAdder (
//        .PC           (PC),
//        .imm          (imm_out),
//        .BranchTarget (BranchTarget)
//    );

//    // 5. Next-PC mux
//    //    sel=0 -> PC+4 (sequential)
//    //    sel=1 -> BranchTarget (branch taken)
//    mux2 u_mux2 (
//        .sel  (PCSrc),
//        .in0  (PC_Plus4),
//        .in1  (BranchTarget),
//        .out  (PC_Next)
//    );

//    // -------------------------------------------------------
//    // 100 MHz clock
//    // -------------------------------------------------------
//    initial clk = 0;
//    always #5 clk = ~clk;

//    // -------------------------------------------------------
//    // Waveform dump - open this vcd in viewer
//    // -------------------------------------------------------
//    initial begin
//        $dumpfile("Task1_tb.vcd");
//        $dumpvars(0, Task1_tb);
//    end

//    // -------------------------------------------------------
//    // Stimulus - no console output, analyse waveforms only
//    // -------------------------------------------------------
//    initial begin

//        // -- initialise all inputs --
//        rst         = 1'b1;
//        PCSrc       = 1'b0;
//        instruction = 32'h00000000;

//        // hold reset for 3 clock cycles
//        repeat(3) @(posedge clk);
//        rst = 1'b0;

//        // ======================================================
//        // TEST 1: Sequential execution
//        // PCSrc = 0 so mux picks PC+4 every cycle
//        // Watch PC in waveform: 0x00, 0x04, 0x08, 0x0C, 0x10
//        // ======================================================
//        PCSrc = 1'b0;
//        repeat(5) @(posedge clk);

//        // ======================================================
//        // TEST 2: immGen - I-type positive immediate
//        // ADDI x1, x0, +100
//        // instruction = 0x06400093
//        // imm_out should show 0x00000064 (100 decimal)
//        // ======================================================
//        instruction = 32'h06400093;
//        repeat(2) @(posedge clk);

//        // ======================================================
//        // TEST 2b: immGen - I-type negative immediate
//        // ADDI x1, x0, -4
//        // instruction = 0xFFC00093
//        // imm_out should show 0xFFFFFFFC
//        // ======================================================
//        instruction = 32'hFFC00093;
//        repeat(2) @(posedge clk);

//        // ======================================================
//        // TEST 3: immGen - S-type positive immediate
//        // SW x1, +8(x2)
//        // instruction = 0x00112423
//        // imm_out should show 0x00000008
//        // ======================================================
//        instruction = 32'h00112423;
//        repeat(2) @(posedge clk);

//        // ======================================================
//        // TEST 3b: immGen - S-type negative immediate
//        // SW x1, -4(x2)
//        // instruction = 0xFE112EA3
//        // imm_out should show 0xFFFFFFFC
//        // ======================================================
//        instruction = 32'hFE112EA3;
//        repeat(2) @(posedge clk);

//        // ======================================================
//        // TEST 4: immGen - B-type positive branch offset
//        // BEQ x0, x0, +8 bytes forward
//        // instruction = 0x04000063
//        // imm_out = 0x00000004
//        // BranchTarget = PC + (4 << 1) = PC + 8
//        // ======================================================
//        instruction = 32'h04000063;
//        repeat(2) @(posedge clk);

//        // ======================================================
//        // TEST 4b: immGen - B-type negative branch offset
//        // BEQ backward -8 bytes
//        // instruction = 0xFE000CE3
//        // imm_out = 0xFFFFFFFC (-4)
//        // BranchTarget = PC + (-4 << 1) = PC - 8
//        // ======================================================
//        instruction = 32'hFE000CE3;
//        repeat(2) @(posedge clk);

//        // ======================================================
//        // TEST 5: Branch taken
//        // Keep the B-type instruction loaded
//        // Set PCSrc = 1 so mux picks BranchTarget
//        // Watch PC jump by -8 each cycle instead of +4
//        // ======================================================
//        PCSrc = 1'b1;
//        repeat(4) @(posedge clk);

//        // ======================================================
//        // TEST 6: Back to sequential
//        // PCSrc = 0 again
//        // PC should resume incrementing by 4
//        // ======================================================
//        PCSrc       = 1'b0;
//        instruction = 32'h00000000;
//        repeat(4) @(posedge clk);

//        // ======================================================
//        // TEST 7: Reset during operation
//        // Assert rst - PC should immediately go to 0x00000000
//        // on the next rising edge
//        // After releasing rst, PC counts from 0 again
//        // ======================================================
//        rst = 1'b1;
//        repeat(3) @(posedge clk);
//        rst = 1'b0;

//        // confirm normal counting resumes from 0
//        PCSrc = 1'b0;
//        repeat(5) @(posedge clk);

//        $finish;
//    end

//endmodule





`timescale 1ns / 1ps

// ============================================================
// Task1_tb.v
// Lab 11 - Task 1 Testbench
//
// Wires all five Task 1 modules together exactly as they
// will appear inside TopLevelProcessor.v.
//
// What to look for in the waveform:
//
//   TEST 1 - Sequential (PCSrc=0):
//     PC should count  0x00 -> 0x04 -> 0x08 -> 0x0C -> 0x10
//     PC_Plus4 is always PC + 4
//
//   TEST 2 - I-type immediates (immGen):
//     instruction = 0x06400093  -> imm_out = 0x00000064  (+100)
//     instruction = 0xFFC00093  -> imm_out = 0xFFFFFFFC  (-4)
//
//   TEST 3 - S-type immediates (immGen):
//     instruction = 0x00112423  -> imm_out = 0x00000008  (+8)
//     instruction = 0xFE112EA3  -> imm_out = 0xFFFFFFFC  (-4)
//
//   TEST 4 - B-type immediates (immGen):
//     immGen outputs bits[12:1] sign-extended (halfword count)
//     branchAdder does PC + (imm << 1) per manual
//
//     instruction = 0x04000063  -> imm_out = 0x00000004
//       BranchTarget = PC + (4 << 1) = PC + 8
//
//     instruction = 0xFE000CE3  -> imm_out = 0xFFFFFFFC (-4)
//       BranchTarget = PC + (-4 << 1) = PC - 8
//
//   TEST 5 - Branch taken (PCSrc=1):
//     Load BEQ +8 instruction (imm_out=4)
//     PC should jump by +8 bytes each cycle
//
//   TEST 6 - Back to sequential (PCSrc=0):
//     PC increments by 4 again normally
//
//   TEST 7 - Reset:
//     PC drops back to 0x00000000
//     then resumes counting from 0
// ============================================================
module Task1_tb;

    // -------------------------------------------------------
    // Testbench driven signals
    // -------------------------------------------------------
    reg         clk;
    reg         rst;
    reg         PCSrc;          // manually driven here
                                // in full processor: Branch AND Zero
    reg  [31:0] instruction;    // manually driven to test immGen

    // -------------------------------------------------------
    // Wires connecting the five modules
    // -------------------------------------------------------
    wire [31:0] PC;             // output of ProgramCounter
    wire [31:0] PC_Plus4;       // output of pcAdder
    wire [31:0] imm_out;        // output of immGen
    wire [31:0] BranchTarget;   // output of branchAdder
    wire [31:0] PC_Next;        // output of mux2 -> feeds back into PC

    // -------------------------------------------------------
    // Module instantiations
    // -------------------------------------------------------

    // 1. Program Counter
    //    Holds current PC, updates every rising clock edge
    ProgramCounter u_pc (
        .clk     (clk),
        .rst     (rst),
        .PC_Next (PC_Next),
        .PC      (PC)
    );

    // 2. PC + 4 adder
    //    Always computes PC + 4, purely combinational
    pcAdder u_pcAdder (
        .PC       (PC),
        .PC_Plus4 (PC_Plus4)
    );

    // 3. Immediate generator
    //    Extracts and sign-extends immediate from instruction
    //    B-type outputs halfword count (no bit0)
    //    branchAdder shifts left by 1 to get byte offset
    immGen u_immGen (
        .instruction (instruction),
        .imm_out     (imm_out)
    );

    // 4. Branch target adder
    //    BranchTarget = PC + (imm << 1)
    //    as specified in Lab 11 manual
    branchAdder u_branchAdder (
        .PC           (PC),
        .imm          (imm_out),
        .BranchTarget (BranchTarget)
    );

    // 5. Next-PC mux
    //    sel=0 -> PC+4 (sequential)
    //    sel=1 -> BranchTarget (branch taken)
    mux2 u_mux2 (
        .sel  (PCSrc),
        .in0  (PC_Plus4),
        .in1  (BranchTarget),
        .out  (PC_Next)
    );

    // -------------------------------------------------------
    // 100 MHz clock
    // -------------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    // -------------------------------------------------------
    // Waveform dump
    // -------------------------------------------------------
    initial begin
        $dumpfile("Task1_tb.vcd");
        $dumpvars(0, Task1_tb);
    end

    // -------------------------------------------------------
    // Stimulus - no console output, waveforms only
    // -------------------------------------------------------
    initial begin

        rst         = 1'b1;
        PCSrc       = 1'b0;
        instruction = 32'h00000000;

        repeat(3) @(posedge clk);
        rst = 1'b0;

        // ======================================================
        // TEST 1: Sequential execution
        // PCSrc=0 so mux picks PC+4 every cycle
        // Watch PC: 0x00 -> 0x04 -> 0x08 -> 0x0C -> 0x10
        // ======================================================
        PCSrc = 1'b0;
        repeat(5) @(posedge clk);

        // ======================================================
        // TEST 2a: immGen - I-type positive immediate
        // ADDI x1, x0, +100
        // instruction = 0x06400093
        // imm_out should show 0x00000064
        // ======================================================
        instruction = 32'h06400093;
        repeat(2) @(posedge clk);

        // ======================================================
        // TEST 2b: immGen - I-type negative immediate
        // ADDI x1, x0, -4
        // instruction = 0xFFC00093
        // imm_out should show 0xFFFFFFFC
        // ======================================================
        instruction = 32'hFFC00093;
        repeat(2) @(posedge clk);

        // ======================================================
        // TEST 3a: immGen - S-type positive immediate
        // SW x1, +8(x2)
        // instruction = 0x00112423
        // imm_out should show 0x00000008
        // ======================================================
        instruction = 32'h00112423;
        repeat(2) @(posedge clk);

        // ======================================================
        // TEST 3b: immGen - S-type negative immediate
        // SW x1, -4(x2)
        // instruction = 0xFE112EA3
        // imm_out should show 0xFFFFFFFC
        // ======================================================
        instruction = 32'hFE112EA3;
        repeat(2) @(posedge clk);

        // ======================================================
        // TEST 4a: immGen - B-type positive branch
        // BEQ x0, x0, forward +8 bytes
        // instruction = 0x04000063
        // immGen outputs halfword count: imm_out = 0x00000004
        // BranchTarget = PC + (4 << 1) = PC + 8  correct
        // ======================================================
        instruction = 32'h04000063;
        repeat(2) @(posedge clk);

        // ======================================================
        // TEST 4b: immGen - B-type negative branch
        // BEQ backward -8 bytes
        // instruction = 0xFE000CE3
        // immGen outputs halfword count: imm_out = 0xFFFFFFFC (-4)
        // BranchTarget = PC + (-4 << 1) = PC - 8  correct
        // ======================================================
        instruction = 32'hFE000CE3;
        repeat(2) @(posedge clk);

        // ======================================================
        // TEST 5: Branch taken (PCSrc=1)
        // Load BEQ +8 instruction (imm_out = 4)
        // branchAdder: PC + (4 << 1) = PC + 8 each cycle
        // Watch PC jump forward by 8 bytes per cycle
        // ======================================================
        instruction = 32'h04000063;
        PCSrc = 1'b1;
        repeat(4) @(posedge clk);

        // ======================================================
        // TEST 6: Back to sequential (PCSrc=0)
        // PC should resume incrementing by 4
        // ======================================================
        PCSrc       = 1'b0;
        instruction = 32'h00000000;
        repeat(4) @(posedge clk);

        // ======================================================
        // TEST 7: Reset during operation
        // Assert rst - PC goes to 0x00000000 on next rising edge
        // After releasing rst, PC counts from 0 again
        // ======================================================
        rst = 1'b1;
        repeat(3) @(posedge clk);
        rst = 1'b0;

        PCSrc = 1'b0;
        repeat(5) @(posedge clk);

        $finish;
    end

endmodule