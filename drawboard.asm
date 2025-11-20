# ===== Board drawing =====
        .data
top_line:       .asciiz "+---+---+---+---+---+---+---+---+---+\n"
newline:        .asciiz "\n"

        .text
print_char:
        li   $v0, 11
        syscall
        jr   $ra

print_3_spaces:
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)
        li    $a0, ' '
        jal   print_char
        li    $a0, ' '
        jal   print_char
        li    $a0, ' '
        jal   print_char
        lw    $ra, 0($sp)
        addiu $sp, $sp, 4
        jr    $ra

print_padded_int3:
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)
        move  $t0, $a0
        li    $t1, 10
        blt   $t0, $t1, .ppi3_1
        li    $t1, 100
        blt   $t0, $t1, .ppi3_2
        li    $v0, 1
        move  $a0, $t0
        syscall
        j     .ppi3_done
.ppi3_2:
        li    $a0, ' '
        jal   print_char
        li    $v0, 1
        move  $a0, $t0
        syscall
        j     .ppi3_done
.ppi3_1:
        li    $a0, ' '
        jal   print_char
        li    $a0, ' '
        jal   print_char
        li    $v0, 1
        move  $a0, $t0
        syscall
.ppi3_done:
        lw    $ra, 0($sp)
        addiu $sp, $sp, 4
        jr    $ra

        .globl draw_board
draw_board:
        addiu $sp, $sp, -16
        sw    $ra, 12($sp)

        move  $t0, $a0    # mode
        move  $t1, $a1    # bin_ptr
        move  $t2, $a2    # dec_val

        li    $v0, 4
        la    $a0, top_line
        syscall

        li    $t3, 0
.db_loop:
        li    $a0, '|'
        jal   print_char

        li    $t4, 8
        blt   $t3, $t4, .db_first8

        beqz  $t0, .db_last_blank
        move  $a0, $t2
        jal   print_padded_int3
        j     .db_after
.db_last_blank:
        jal   print_3_spaces
        j     .db_after

.db_first8:
        beqz  $t0, .db_bit
        jal   print_3_spaces
        j     .db_after

.db_bit:
        li    $a0, ' '
        jal   print_char
        addu  $t5, $t1, $t3
        lb    $a0, 0($t5)
        jal   print_char
        li    $a0, ' '
        jal   print_char

.db_after:
        addi  $t3, $t3, 1
        li    $t4, 9
        blt   $t3, $t4, .db_loop

        li    $a0, '|'
        jal   print_char

        li    $v0, 4
        la    $a0, newline
        syscall

        li    $v0, 4
        la    $a0, top_line
        syscall

        lw    $ra, 12($sp)
        addiu $sp, $sp, 16
        jr    $ra