#   x6  - switch value read / temp
#   x7  - countdown counter
#   x8  - switch base address  (0x300 = 768)
#   x9  - LED base address     (0x200 = 512)


_start:
    addi x8, x0, 768
    addi x9, x0, 512
WAIT:
    sw   x0, 0(x9)
WAIT_ZERO:
    lw   x6, 0(x8)
    bne  x6, x0, WAIT_ZERO    # ← BNE here
WAIT_POLL:
    lw   x6, 0(x8)
    beq  x6, x0, WAIT_POLL    # ← BEQ here (not BNE)
    sw   x6, 0(x9)
    addi x7, x6, 0
COUNT_LOOP:
    beq  x7, x0, WAIT         # ← BEQ here
    sw   x7, 0(x9)
    addi x7, x7, -1
    beq  x0, x0, COUNT_LOOP   # ← BEQ here
