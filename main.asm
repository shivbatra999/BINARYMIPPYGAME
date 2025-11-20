        .text
        .globl __start
__start:
        j     main
        nop

        .data
msg_welcome:    .asciiz "\n=== Binary/Decimal Game ===\nYou will play 10 rounds.\n+1 for correct, -1 for incorrect.\n\n"
msg_round:      .asciiz "Round "
msg_of:         .asciiz " of "
msg_nl:         .asciiz "\n"
msg_mode_b2d:   .asciiz "Mode: Binary -> Decimal\n"
msg_mode_d2b:   .asciiz "Mode: Decimal -> Binary\n"
msg_prompt_dec: .asciiz "Enter decimal (0-255): "
msg_prompt_bin: .asciiz "Enter 8-bit binary (e.g., 01010101): "
msg_correct:    .asciiz "Correct!\n"
msg_wrong:      .asciiz "Incorrect.\n"
msg_correct_was:.asciiz "Correct answer was: "
msg_score:      .asciiz "Score: "
msg_sep:        .asciiz " | "
msg_final:      .asciiz "\n=== Game Over ===\nFinal score: "

        .text
        .globl main
main:
        # Frame 64B:
        # [ 0] score
        # [ 4] total
        # [ 8] round
        # [12] value
        # [16] mode (0=b2d,1=d2b)
        # [20..35] binbuf (16 bytes; use first 9)
        # [56] $fp, [60] $ra
        addiu $sp, $sp, -64
        sw    $ra, 60($sp)
        sw    $fp, 56($sp)
        move  $fp, $sp

        # Banner
        li    $v0, 4
        la    $a0, msg_welcome
        syscall

        # Init
        sw    $zero, 0($fp)      # score=0
        li    $t0, 10
        sw    $t0, 4($fp)        # total=10
        li    $t0, 1
        sw    $t0, 8($fp)        # round=1

round_loop:
        # Round header
        li    $v0, 4
        la    $a0, msg_round
        syscall
        li    $v0, 1
        lw    $a0, 8($fp)
        syscall
        li    $v0, 4
        la    $a0, msg_of
        syscall
        li    $v0, 1
        lw    $a0, 4($fp)
        syscall
        li    $v0, 4
        la    $a0, msg_nl
        syscall

        # Mode: random 0 or 1 (syscall 42 returns result in $a0)
        # original: 
        # li    $v0, 42
        # addiu $a0, $zero, 0      # lower bound
        # addiu $a1, $zero, 2      # upper bound (exclusive)
        # syscall                   # random in $a0
        addiu $a0, $zero, 0        # lower bound
        addiu $a1, $zero, 2        # upper bound (exclusive)
        jal   rand_in_range        # random in $a0 (MARS returns in $a0)
        sw    $a0, 16($fp)         # store mode

        # Print mode line
        lw    $t0, 16($fp)
        beqz  $t0, .print_b2d
        li    $v0, 4
        la    $a0, msg_mode_d2b
        syscall
        j     .mode_done
.print_b2d:
        li    $v0, 4
        la    $a0, msg_mode_b2d
        syscall
.mode_done:

        # Value: random 0..255 (syscall 42 returns result in $a0)
        # original:
        # li    $v0, 42
        # addiu $a0, $zero, 0      # lower bound
        # addiu $a1, $zero, 256    # upper bound (exclusive)
        # syscall                   # random in $a0
        addiu $a0, $zero, 0        # lower bound
        addiu $a1, $zero, 256      # upper bound (exclusive)
        jal   rand_in_range        # random in $a0 (MARS returns in $a0)
        sw    $a0, 12($fp)         # store value

        # Branch by mode
        lw    $t0, 16($fp)
        beqz  $t0, do_bin_to_dec

# Mode 1: Decimal -> Binary
do_dec_to_bin:
        # Draw: blanks in first 8, decimal in last
        li    $a0, 1
        move  $a1, $zero
        lw    $a2, 12($fp)
        jal   draw_board

        # Prompt + read binary
        li    $v0, 4
        la    $a0, msg_prompt_bin
        syscall

        addiu $a0, $fp, 20
        jal   read_binary8_string
        beqz  $v1, handle_incorrect

        # Convert
        addiu $a0, $fp, 20
        jal   binary8_to_int
        beqz  $v1, handle_incorrect

        # Verify
        move  $a0, $v0
        lw    $a1, 12($fp)
        jal   verify_equal
        beqz  $v0, handle_incorrect
        j     handle_correct

# Mode 0: Binary -> Decimal
do_bin_to_dec:
        # Build binbuf
        lw    $a0, 12($fp)
        addiu $a1, $fp, 20
        jal   int_to_binary8

        # Draw: bits shown, decimal cell blank
        li    $a0, 0
        addiu $a1, $fp, 20
        move  $a2, $zero
        jal   draw_board

        # Prompt + read decimal
        li    $v0, 4
        la    $a0, msg_prompt_dec
        syscall

        li    $a0, 0
        li    $a1, 255
        jal   read_int_in_range
        beqz  $v1, handle_incorrect

        # Verify
        move  $a0, $v0
        lw    $a1, 12($fp)
        jal   verify_equal
        beqz  $v0, handle_incorrect

handle_correct:
        li    $v0, 4
        la    $a0, msg_correct
        syscall
        lw    $t0, 0($fp)
        addi  $t0, $t0, 1
        sw    $t0, 0($fp)
        j     end_round_report

handle_incorrect:
        # "Incorrect.\n"
        li    $v0, 4
        la    $a0, msg_wrong
        syscall
        # "Correct answer was: "
        li    $v0, 4
        la    $a0, msg_correct_was
        syscall

        # If mode==1 (Decimal -> Binary), show correct answer as 8-bit binary string.
        # Else (Binary -> Decimal), show correct decimal.
        lw    $t0, 16($fp)         # mode
        bnez  $t0, .show_binary_correct

        # Show decimal (mode 0: Binary -> Decimal)
        li    $v0, 1
        lw    $a0, 12($fp)         # correct decimal
        syscall
        j     .after_correct_print

.show_binary_correct:
        # Convert correct decimal to 8-bit binary into binbuf and print it
        lw    $a0, 12($fp)         # correct decimal
        addiu $a1, $fp, 20         # binbuf
        jal   int_to_binary8
        li    $v0, 4
        addiu $a0, $fp, 20
        syscall

.after_correct_print:
        # Newline
        li    $v0, 4
        la    $a0, msg_nl
        syscall

        # score--
        lw    $t0, 0($fp)
        addi  $t0, $t0, -1
        sw    $t0, 0($fp)

end_round_report:
        # Score line
        li    $v0, 4
        la    $a0, msg_score
        syscall
        li    $v0, 1
        lw    $a0, 0($fp)
        syscall
        li    $v0, 4
        la    $a0, msg_sep
        syscall
        li    $v0, 4
        la    $a0, msg_round
        syscall
        li    $v0, 1
        lw    $a0, 8($fp)
        syscall
        li    $v0, 4
        la    $a0, msg_of
        syscall
        li    $v0, 1
        lw    $a0, 4($fp)
        syscall
        li    $v0, 4
        la    $a0, msg_nl
        syscall

        # round++
        lw    $t0, 8($fp)
        addi  $t0, $t0, 1
        sw    $t0, 8($fp)

        # while (round <= total)
        lw    $t1, 8($fp)
        lw    $t2, 4($fp)
        slt   $t3, $t2, $t1
        beq   $t3, $zero, round_loop

        # Final score and exit
        li    $v0, 4
        la    $a0, msg_final
        syscall
        li    $v0, 1
        lw    $a0, 0($fp)
        syscall
        li    $v0, 4
        la    $a0, msg_nl
        syscall

        lw    $fp, 56($sp)
        lw    $ra, 60($sp)
        addiu $sp, $sp, 64
        li    $v0, 10
        syscall

# Bring in other parts so assembling main.asm alone works
        .include "conversions.asm"
        .include "verification.asm"
        .include "random.asm"
        .include "drawboard.asm"
        .include "input.asm"