# ============================================================
# Part C - Fibonacci Sequence with Switch Input
# Board: Basys3, Memory-mapped I/O
#
# Register usage:
#   x1  (ra)  - return address saved by JAL
#   x2  (sp)  - stack pointer (starts at 0x1FC)
#   x5        - fib_a (current fibonacci value)
#   x6        - fib_b (next fibonacci value)
#   x7        - loop counter inside subroutine
#   x8        - switch base address (0x300 = 768)
#   x9        - LED base address   (0x200 = 512)
#   x10       - subroutine argument = switch value = N
#   x11       - temp for fibonacci addition
#
# Memory Map:
#   0x200 = LED address  (SW instruction writes here)
#   0x300 = Switch address (LW instruction reads here)
#
# LED Layout on Basys3:
#   LD15 = BNE  indicator (HIGH when BNE loop fires)
#   LD14 = JAL  indicator (HIGH when subroutine called)
#   LD13 = JALR indicator (HIGH when subroutine returns)
#   LD12:LD0 = fibonacci value (lower 13 bits)
#
# Seven segment shows same fibonacci value in hex
#
# Flow:
#   _start -> WAIT -> WAIT_ZERO -> WAIT_POLL ->
#   read switches -> JAL FIBONACCI -> back to WAIT
#
# Fibonacci subroutine:
#   Input  x10 = N (number of fibonacci values to display)
#   Output x5  = last fibonacci value
#   Displays: fib(0), fib(1), ..., fib(N-1) on LEDs
#   Sequence: 0, 1, 1, 2, 3, 5, 8, 13, 21, 34, ...
#
# Instructions triggering indicators:
#   BNE  in FIB_LOOP -> LD15 blinks every loop iteration
#   JAL  FIBONACCI   -> LD14 lights when called
#   JALR x0,x1,0    -> LD13 lights when returning
# ============================================================

# ============================================================
# INITIALISATION - runs once at startup or after reset
# ============================================================
_start:
    addi x2, x0, 508       # sp = 0x1FC (top of data memory)
    addi x8, x0, 768       # x8 = 0x300 = switch base address
    addi x9, x0, 512       # x9 = 0x200 = LED base address

# ============================================================
# WAIT - clear LEDs and wait for switches to be zero first
# ============================================================
WAIT:
    sw   x0, 0(x9)         # clear all LEDs (write 0 to 0x200)

WAIT_ZERO:
    lw   x10, 0(x8)        # read switches
    bne  x10, x0, WAIT_ZERO  # if switches still ON wait here
                              # user must set switches to 0 first

# ============================================================
# WAIT_POLL - wait for user to set switches to non-zero value
# ============================================================
WAIT_POLL:
    lw   x10, 0(x8)        # read switches into x10
    beq  x10, x0, WAIT_POLL  # if zero keep polling

# ============================================================
# Non-zero switch value detected
# x10 = N = number of fibonacci values to display
# ============================================================
    sw   x10, 0(x9)        # show switch value on LEDs briefly
    jal  x1, FIBONACCI     # call FIBONACCI(N) -> LD14 lights up

# ============================================================
# After return from FIBONACCI:
# x5 = last fibonacci value (already displayed inside subroutine)
# Go back to WAIT so user can enter another number
# ============================================================
    beq  x0, x0, WAIT      # unconditional jump back to WAIT

# ============================================================
# FIBONACCI SUBROUTINE
# Input:  x10 = N (how many fibonacci numbers to display)
# Output: x5  = last fibonacci value
# Clobbers: x5, x6, x7, x11
#
# Stack frame (16 bytes):
#   sp+12 = saved x1  (return address)
#   sp+8  = saved x9  (LED address)
#   sp+4  = saved x8  (switch address)
#   sp+0  = saved x7  (loop counter)
#
# Sequence produced starting from N=1:
#   N=1 -> displays: 0
#   N=2 -> displays: 0, 1
#   N=3 -> displays: 0, 1, 1
#   N=4 -> displays: 0, 1, 1, 2
#   N=8 -> displays: 0, 1, 1, 2, 3, 5, 8, 13
# ============================================================
FIBONACCI:
    addi x2, x2, -16       # allocate 16-byte stack frame
    sw   x1,  12(x2)       # save return address
    sw   x9,  8(x2)        # save LED address
    sw   x8,  4(x2)        # save switch address
    sw   x7,  0(x2)        # save loop counter register

    addi x5,  x0, 0        # fib_a = 0
    addi x6,  x0, 1        # fib_b = 1
    addi x7,  x10, 0       # loop counter = N

FIB_LOOP:
    beq  x7, x0, FIB_DONE  # if counter = 0 we are done
    sw   x5, 0(x9)         # display fib_a on LEDs and seven seg
    add  x11, x5, x6       # x11 = fib_a + fib_b (next value)
    addi x5,  x6, 0        # fib_a = fib_b
    addi x6,  x11, 0       # fib_b = x11
    addi x7,  x7, -1       # decrement counter
    bne  x7, x0, FIB_LOOP  # if counter != 0 loop back -> LD15

FIB_DONE:
    lw   x7,  0(x2)        # restore x7
    lw   x8,  4(x2)        # restore x8
    lw   x9,  8(x2)        # restore x9
    lw   x1,  12(x2)       # restore return address
    addi x2,  x2, 16       # deallocate stack frame
    jalr x0,  x1, 0        # return to caller -> LD13 lights up
