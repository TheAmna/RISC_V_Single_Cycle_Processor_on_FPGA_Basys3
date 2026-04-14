`timescale 1ns / 1ps
//
//   From Lab 11 Task 1:
//     ProgramCounter   - holds current PC
//     pcAdder          - computes PC + 4
//     branchAdder      - computes PC + (imm << 1)
//     mux2 (x3)        - PC select, ALU-B select, writeback select
//     immGen           - extracts I/S/B immediates

//     InstructionMemory - holds program as machine code
//   From Lab 9:
//     MainControl      - generates 7 control signals from opcode
//     ALUControl       - generates 4-bit ALU op from ALUOp+funct3+funct7
//     RegisterFile     - 32x32 register file, 2 read 1 write port
//   From Lab 6:
//     ALU              - 32-bit ALU with Zero flag
//   From Lab 8:
//     DataMemory       - 512-word data RAM
//
// Signal flow per instruction type:
//
//   R-type (ADD SUB AND OR XOR SLL SRL):
//     PC -> InstrMem -> decode fields -> RegisterFile read
//     -> ALU (A=rs1, B=rs2, op from ALUControl)
//     -> mux_wb (ALUSrc=0, MemtoReg=0) -> RegisterFile write
//     -> PC+4
//
//   I-type (ADDI):
//     PC -> InstrMem -> decode -> RegisterFile read
//     -> ALU (A=rs1, B=imm, ALUSrc=1)
//     -> mux_wb (MemtoReg=0) -> RegisterFile write
//     -> PC+4
//
//   Load (LW LH LB):
//     PC -> InstrMem -> decode -> RegisterFile read
//     -> ALU (A=rs1, B=imm, ALUSrc=1) computes address
//     -> DataMemory read (MemRead=1)
//     -> mux_wb (MemtoReg=1) -> RegisterFile write
//     -> PC+4
//
//   Store (SW SH SB):
//     PC -> InstrMem -> decode -> RegisterFile read
//     -> ALU computes address, rs2 -> DataMemory write (MemWrite=1)
//     -> no writeback (RegWrite=0)
//     -> PC+4
//
//   Branch (BEQ):
//     PC -> InstrMem -> decode -> RegisterFile read
//     -> ALU SUB (A=rs1, B=rs2) -> Zero flag
//     -> PCSrc = Branch AND Zero
//     -> if taken: PC = PC + (imm<<1), else PC = PC+4
//     -> no writeback (RegWrite=0)
//
// Wires named to match Patterson & Hennessy textbook
// for easy cross-reference.
// ============================================================
module TopLevelProcessor (
    input  wire        clk,
    input  wire        rst
);

    // SECTION 1: PC DATAPATH WIRES
    // ==========================================================
    wire [31:0] PC;             // current program counter
    wire [31:0] PC_Plus4;       // PC + 4 (from pcAdder)
    wire [31:0] BranchTarget;   // PC + (imm << 1) (from branchAdder)
    wire [31:0] PC_Next;        // selected next PC (from mux_pc)
    wire        PCSrc;          // 1 = branch taken, 0 = sequential

    // ==========================================================
    // SECTION 2: INSTRUCTION MEMORY WIRES
    // ==========================================================
    wire [31:0] instruction;    // 32-bit instruction word

    // ==========================================================
    // SECTION 3: INSTRUCTION FIELD WIRES
    // Sliced directly from instruction word
    // ==========================================================
    wire [6:0]  opcode;         // instruction[6:0]
    wire [4:0]  rs1_addr;       // instruction[19:15]
    wire [4:0]  rs2_addr;       // instruction[24:20]
    wire [4:0]  rd_addr;        // instruction[11:7]
    wire [2:0]  funct3;         // instruction[14:12]
    wire [6:0]  funct7;         // instruction[31:25]

    // Slice instruction fields combinationally
    assign opcode   = instruction[6:0];
    assign rd_addr  = instruction[11:7];
    assign funct3   = instruction[14:12];
    assign rs1_addr = instruction[19:15];
    assign rs2_addr = instruction[24:20];
    assign funct7   = instruction[31:25];

    // ==========================================================
    // SECTION 4: CONTROL SIGNAL WIRES
    // ==========================================================
    wire        RegWrite;       // 1 = write result to register file
    wire        ALUSrc;         // 1 = ALU B input is immediate
    wire        MemRead;        // 1 = read from data memory
    wire        MemWrite;       // 1 = write to data memory
    wire        MemtoReg;       // 1 = writeback from memory, 0 = from ALU
    wire        Branch;         // 1 = instruction is a branch
    wire [1:0]  ALUOp;          // ALU operation class
    wire [3:0]  ALUControl;     // specific ALU operation code

    // ==========================================================
    // SECTION 5: REGISTER FILE WIRES
    // ==========================================================
    wire [31:0] ReadData1;      // rs1 value from register file
    wire [31:0] ReadData2;      // rs2 value from register file
    wire [31:0] WriteData;      // data to write back to rd

    // ==========================================================
    // SECTION 6: IMMEDIATE AND ALU WIRES
    // ==========================================================
    wire [31:0] imm_out;        // sign-extended immediate from immGen
    wire [31:0] ALU_B;          // ALU second operand (from mux_alusrc)
    wire [31:0] ALUResult;      // ALU computation result
    wire        Zero;           // ALU zero flag (1 when result == 0)

    // ==========================================================
    // SECTION 7: DATA MEMORY WIRES
    // ==========================================================
    wire [31:0] MemReadData;    // data read from data memory

    // ==========================================================
    // SECTION 8: PCSrc LOGIC
    // Branch is taken only when Branch=1 AND ALU Zero=1
    // This is the only logic written directly in TopLevel
    // ==========================================================
    assign PCSrc = Branch & Zero;

    // ==========================================================
    // MODULE INSTANTIATIONS
    // ==========================================================

    // ----------------------------------------------------------
    // 1. Program Counter
    //    Clocked register, resets to 0x00000000
    //    Loads PC_Next on every rising edge
    // ----------------------------------------------------------
    ProgramCounter u_pc (
        .clk     (clk),
        .rst     (rst),
        .PC_Next (PC_Next),
        .PC      (PC)
    );

    // ----------------------------------------------------------
    // 2. PC + 4 Adder
    //    Purely combinational, always active
    // ----------------------------------------------------------
    pcAdder u_pcAdder (
        .PC       (PC),
        .PC_Plus4 (PC_Plus4)
    );

    // ----------------------------------------------------------
    // 3. Immediate Generator
    //    Extracts and sign-extends I, S, B type immediates
    //    B-type: outputs bits[12:1] sign-extended (halfword count)
    //    branchAdder shifts left 1 to get byte offset
    // ----------------------------------------------------------
    immGen u_immGen (
        .instruction (instruction),
        .imm_out     (imm_out)
    );

    // ----------------------------------------------------------
    // 4. Branch Target Adder
    //    Computes PC + (imm << 1) as per manual
    //    imm from immGen is halfword count for B-type
    // ----------------------------------------------------------
    branchAdder u_branchAdder (
        .PC           (PC),
        .imm          (imm_out),
        .BranchTarget (BranchTarget)
    );

    // ----------------------------------------------------------
    // 5. PC Select Mux  (mux instance 1)
    //    PCSrc=0 -> PC+4 (sequential)
    //    PCSrc=1 -> BranchTarget (branch taken)
    // ----------------------------------------------------------
    mux2 u_mux_pc (
        .sel  (PCSrc),
        .in0  (PC_Plus4),
        .in1  (BranchTarget),
        .out  (PC_Next)
    );

    // ----------------------------------------------------------
    // 6. Instruction Memory
    //    PC is byte address, module divides by 4 internally
    //    Loads program from instruction.mem at startup
    // ----------------------------------------------------------
    InstructionMemory u_instmem (
        .instAddress (PC),
        .instruction (instruction)
    );

    // ----------------------------------------------------------
    // 7. Main Control Unit
    //    Decodes opcode -> 7 control signals + ALUOp
    // ----------------------------------------------------------
    MainControl u_main_ctrl (
        .opcode   (opcode),
        .RegWrite (RegWrite),
        .ALUSrc   (ALUSrc),
        .MemRead  (MemRead),
        .MemWrite (MemWrite),
        .MemtoReg (MemtoReg),
        .Branch   (Branch),
        .ALUOp    (ALUOp)
    );

    // ----------------------------------------------------------
    // 8. ALU Control Unit
    //    Decodes ALUOp + funct3 + funct7 -> 4-bit ALU op code
    // ----------------------------------------------------------
    ALUControl u_alu_ctrl (
        .ALUOp      (ALUOp),
        .funct3     (funct3),
        .funct7     (funct7),
        .ALUControl (ALUControl)
    );

    // ----------------------------------------------------------
    // 9. Register File
    //    Two async read ports, one sync write port
    //    x0 hardwired to zero
    //    rs1, rs2, rd sliced from instruction word
    // ----------------------------------------------------------
    RegisterFile u_regfile (
        .clk         (clk),
        .rst         (rst),
        .WriteEnable (RegWrite),
        .rs1         (rs1_addr),
        .rs2         (rs2_addr),
        .rd          (rd_addr),
        .WriteData   (WriteData),
        .ReadData1   (ReadData1),
        .ReadData2   (ReadData2)
    );

    // ----------------------------------------------------------
    // 10. ALU Source Mux  (mux instance 2)
    //     ALUSrc=0 -> ReadData2 from register file (R-type)
    //     ALUSrc=1 -> imm_out from immGen (I/S/B-type)
    // ----------------------------------------------------------
    mux2 u_mux_alusrc (
        .sel  (ALUSrc),
        .in0  (ReadData2),
        .in1  (imm_out),
        .out  (ALU_B)
    );

    // ----------------------------------------------------------
    // 11. ALU
    //     A = ReadData1 (rs1)
    //     B = ALU_B (rs2 or immediate, selected by mux above)
    //     ALUResult used as: address for memory, result for writeback
    //     Zero used for: branch decision
    // ----------------------------------------------------------
    ALU u_alu (
        .A         (ReadData1),
        .B         (ALU_B),
        .ALUControl(ALUControl),
        .ALUResult (ALUResult),
        .Zero      (Zero)
    );

    // ----------------------------------------------------------
    // 12. Data Memory
    //     address = ALUResult (effective address from ALU)
    //     write_data = ReadData2 (rs2, for store instructions)
    //     MemWrite and MemRead gated by control signals
    // ----------------------------------------------------------
    DataMemory u_datamem (
        .clk        (clk),
        .MemWrite   (MemWrite),
        .MemRead    (MemRead),
        .address    (ALUResult),
        .write_data (ReadData2),
        .read_data  (MemReadData)
    );

    // ----------------------------------------------------------
    // 13. Writeback Mux  (mux instance 3)
    //     MemtoReg=0 -> ALUResult (R-type, I-arithmetic)
    //     MemtoReg=1 -> MemReadData (load instructions)
    //     Output goes to RegisterFile WriteData port
    // ----------------------------------------------------------
    mux2 u_mux_wb (
        .sel  (MemtoReg),
        .in0  (ALUResult),
        .in1  (MemReadData),
        .out  (WriteData)
    );

endmodule