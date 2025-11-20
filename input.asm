# ===== Input =====
        .text
        .globl read_binary8_string
read_binary8_string:
        addiu $sp, $sp, -48
        sw    $ra, 44($sp)

        move  $t0, $a0
        li    $v0, 8
        addiu $a0, $sp, 0
        li    $a1, 16
        syscall

        addiu $t1, $sp, 0
        move  $t2, $zero

.r_loop:
        lb    $t3, 0($t1)
        beqz  $t3, .r_end
        li    $t4, 10
        beq   $t3, $t4, .r_end
        li    $t4, 13
        beq   $t3, $t4, .r_end

        li    $t4, '0'
        beq   $t3, $t4, .r_isbit
        li    $t4, '1'
        beq   $t3, $t4, .r_isbit
        li    $v1, 0
        j     .r_fail

.r_isbit:
        li    $t5, 8
        bge   $t2, $t5, .r_toomany
        sb    $t3, 0($t0)
        addi  $t0, $t0, 1
        addi  $t2, $t2, 1
        addi  $t1, $t1, 1
        j     .r_loop

.r_toomany:
        li    $v1, 0
        j     .r_fail

.r_end:
        li    $t5, 8
        bne   $t2, $t5, .r_notenough
        sb    $zero, 0($t0)
        li    $v1, 1
        j     .r_done

.r_notenough:
        li    $v1, 0

.r_fail:
.r_done:
        lw    $ra, 44($sp)
        addiu $sp, $sp, 48
        jr    $ra

        .globl read_int_in_range
read_int_in_range:
        move  $t0, $a0   # lo
        move  $t1, $a1   # hi
        li    $v0, 5
        syscall
        move  $t2, $v0
        slt   $t3, $t2, $t0      # val < lo?
        bne   $t3, $zero, .rir_bad
        slt   $t3, $t1, $t2      # hi < val?
        bne   $t3, $zero, .rir_bad
        li    $v1, 1
        jr    $ra
.rir_bad:
        li    $v1, 0
        jr    $ra