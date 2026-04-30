#   x6  - switch value read / temp
#   x7  - countdown counter
#   x8  - switch base address  (0x300 = 768)
#   x9  - LED base address     (0x200 = 512)

_start:
    addi x8, x0, 768        # x8 = switch address (0x300)
    addi x9, x0, 512        # x9 = LED address (0x200)

WAIT:
    sw   x0, 0(x9)          # clear LEDs (write 0 to 0x200)

WAIT_ZERO:
    lw   x6, 0(x8)          # read switches into x6
    bne  x6, x0, WAIT_ZERO  # if switches still on, keep waiting

WAIT_POLL:
    lw   x6, 0(x8)          # read switches into x6
    beq  x6, x0, WAIT_POLL  # if switches are zero, keep polling

    sw   x6, 0(x9)          # show switch value on LEDs
    addi x7, x6, 0          # copy switch value into counter x7

COUNT_LOOP:
    beq  x7, x0, WAIT       # if counter = 0, go back to WAIT
    sw   x7, 0(x9)          # display current counter on LEDs
    addi x7, x7, -1         # decrement counter by 1
    beq  x0, x0, COUNT_LOOP # unconditional loop back (x0==x0 always true)
