#   x6  - switch value read / temp
#   x7  - countdown counter
#   x8  - switch base address  (0x300 = 768)
#   x9  - LED base address     (0x200 = 512)

_start:
    addi x8, x0, 768        # x8 = 0x300 = switch address
    addi x9, x0, 512        # x9 = 0x200 = LED address

WAIT:
    sw   x0, 0(x9)          # clear LEDs

WAIT_POLL:
    lw   x6, 0(x8)          # read switches into x6
    beq  x6, x0, WAIT_POLL  # if zero, keep polling
    # non-zero detected
    sw   x6, 0(x9)          # show initial value on LEDs
    addi x7, x6, 0          # x7 = counter = switch value

COUNT_LOOP:
    beq  x7, x0, WAIT       # if counter = 0, go back to WAIT
    sw   x7, 0(x9)          # display counter on LEDs
    addi x7, x7, -1         # decrement counter
    beq  x0, x0, COUNT_LOOP # unconditional loop back (x0==x0 always)
