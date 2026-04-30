# EE-CS-371-330-Computer-Architecture-Lab-Project

## Team Members 
- [Humna Khan](https://github.com/humna0809)
- [Amna Ali](https://github.com/TheAmna)
  
## Project Overview

Demonstrating a countdown and fibonacci sequence on the RISC V processor made in labs on the Digilent BASYS 3 FPGA (Field Programmble Gateway array). 



## Part A Demo



https://github.com/user-attachments/assets/c77e835b-abad-45af-859b-419cc19354fd



## Part C Demo


## Challenges

1. The biggest challenge was getting the ti,ing signals right for the demonstartion on the FPGA BASYS 3. We worked on another porject that just required pipelining the processor and verifying through simulaton. SO the timing was not a problem but here we had to synchronise everything with the clock signals and the clock frequency of the basys 3 which is 100 MHZ.



## Key Learnings

1. Learned the RISC V Single Cycle Processor core, it's working and the modules that it uses.  The core modules include the Program Counter which holds and advances the current instruction address, the Instruction Memory which fetches the 32-bit instruction at that address, the Immediate Generator which extracts and sign-extends the immediate value based on instruction type, the Register File which holds 32 general-purpose registers with two asynchronous read ports and one synchronous write port, the ALU which performs arithmetic and logic operations guided by the ALU Control unit, and the Main Control unit which decodes the opcode and drives all datapath control signals. The processor supports R-type, I-type, S-type, B-type and J-type instructions including ADD, SUB, AND, OR, XOR, SLL, SRL, SLT, ADDI, LW, SW, BEQ, BNE, BLT, BGE, JAL and JALR.
   
2. On the FPGA side, the processor interfaces with memory-mapped peripherals including physical LEDs, slide switches and a four-digit seven-segment display, all decoded through an address decoder that routes transactions based on address bits. A clock enable pattern was used instead of a divided clock to safely slow execution to a visible rate while keeping all logic on the 100MHz clock domain. Three assembly programs were written and tested: a countdown timer, a jump instruction demonstrator, and a Fibonacci sequence generator, each verified through Vivado behavioural simulation before deployment to hardware.
