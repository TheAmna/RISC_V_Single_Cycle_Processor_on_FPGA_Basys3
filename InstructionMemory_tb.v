`timescale 1ns / 1ps
// InstructionMemory_tb
// Walks through every instruction address and checks the output
// matches the expected machine code from program.mem
module InstructionMemory_tb;
    reg  [31:0] addr;
    wire [31:0] instr;
    // instantiate - name matches module exactly (capital I)
    InstructionMemory uut (
        .instAddress (addr),
        .instruction (instr)
    );
    // task to apply address, wait, and check expected value
    task check;
        input [31:0] address;
        input [31:0] expected;
        begin
            addr = address;
            #10;
            if (instr === expected)
                $display("PASS  addr=0x%02X  instr=0x%08X", address, instr);
            else
                $display("FAIL  addr=0x%02X  got=0x%08X  expected=0x%08X",
                          address, instr, expected);
        end
    endtask
    initial begin
        $dumpfile("InstructionMemory_tb.vcd");
        $dumpvars(0, InstructionMemory_tb);

        // each check: (byte address, expected 32-bit word)
        check(32'h00, 32'h1fc00113); // li x2, 0x1FC       -> addi x2,x0,0x1FC
        check(32'h04, 32'h40000413); // li x8, 0x400       -> addi x8,x0,0x400
        check(32'h08, 32'h000014b7); // lui x9, 1          (first half of 0x800)
        check(32'h0C, 32'h80048493); // addi x9,x9,-0x800  (second half)
        check(32'h10, 32'h00001937); // lui x18, 1         (first half of 0xC00)
        check(32'h14, 32'hc0090913); // addi x18,x18,-0x400 (second half)
        check(32'h18, 32'h0004a023); // WAIT: sw x0,0(x9)  clear LEDs
        check(32'h1C, 32'h00042303); // WAIT_POLL: lw x6,0(x8) read switches
        check(32'h20, 32'hfe030ee3); // beq x6,x0,WAIT_POLL  loop if zero
        check(32'h24, 32'h0064a023); // sw x6,0(x9)  show value on LEDs
        check(32'h28, 32'h00030513); // addi x10,x6,0  copy to argument
        check(32'h2C, 32'h008000ef); // jal x1,COUNTDOWN
        check(32'h30, 32'hfe9ff06f); // jal x0,WAIT
        check(32'h34, 32'hff410113); // COUNTDOWN: addi x2,x2,-12  stack frame
        check(32'h38, 32'h00112423); // sw x1,8(x2)  save ra
        check(32'h3C, 32'h00812223); // sw x8,4(x2)  save switch addr
        check(32'h40, 32'h00912023); // sw x9,0(x2)  save LED addr
        check(32'h44, 32'h00050393); // addi x7,x10,0  counter = argument
        check(32'h48, 32'h00092303); // COUNT_LOOP: lw x6,0(x18) read reset
        check(32'h4C, 32'h00031a63); // bne x6,x0,COUNT_RESET
        check(32'h50, 32'h00038a63); // beq x7,x0,COUNT_DONE
        check(32'h54, 32'h0074a023); // sw x7,0(x9)  LEDs = counter
        check(32'h58, 32'hfff38393); // addi x7,x7,-1  decrement
        check(32'h5C, 32'hfedff06f); // jal x0,COUNT_LOOP
        check(32'h60, 32'h0004a023); // COUNT_RESET: sw x0,0(x9) clear LEDs
        check(32'h64, 32'h00012483); // COUNT_DONE: lw x9,0(x2)  restore
        check(32'h68, 32'h00412403); // lw x8,4(x2)  restore
        check(32'h6C, 32'h00812083); // lw x1,8(x2)  restore ra
        check(32'h70, 32'h00c10113); // addi x2,x2,12  free stack
        check(32'h74, 32'h00008067); // jalr x0,x1,0  return
        $display("--- done ---");
        $finish;
    end

endmodule