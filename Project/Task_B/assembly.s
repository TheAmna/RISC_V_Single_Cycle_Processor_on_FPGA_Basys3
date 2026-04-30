# Part B Test Program - Tests BNE, JAL, JALR 
# BNE TEST 
addi x1, x0, 5        # x1 = 5 
addi x2, x0, 3        # x2 = 3 
bne  x1, x2, +8       # BNE: 5!=3 TAKEN, skip next instruction 
addi x3, x0, 0xBAD    # SKIPPED (proves BNE jumped) 
addi x4, x0, 0x11     # x4=0x11, BNE landed here 

# JAL TEST 
jal  x5, +12          # JAL: x5=PC+4=0x18, jump to 0x20 
addi x6, x0, 0xBAD    # SKIPPED 
addi x6, x0, 0xBAD    # SKIPPED 
addi x7, x0, 0x22     # x7=0x22, JAL landed here 

# JALR TEST 
addi x8, x0, 0x38     # x8 = 0x38 (target address) 
jalr x9, 0(x8)        # JALR: x9=PC+4=0x2C, jump to x8=0x38 
addi x10, x0, 0xBAD   # SKIPPED 
add x0,x0,x0             # gap 
add x0,x0,x0                 # gap 
addi x10, x0, 0x33    # x10=0x33, JALR landed here 
# HALT 

beq  x0, x0, 0        # infinite loop 
