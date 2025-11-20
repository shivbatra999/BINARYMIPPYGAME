# ===== Conversions =====
        .text
        .globl binary8_to_int
binary8_to_int:
        move $t0, $a0
        li   $v0, 0
        li   $v1, 1
        li   $t1, 0
.b2i_loop:
        li   $t2, 8
        beq  $t1, $t2, .b2i_done
        lb   $t3, 0($t0)
        beq  $t3, $zero, .b2i_bad
        li   $t4, '0'
        beq   $t3, $t4, .b2i_step
        li   $t4, '1'
        beq   $t3, $t4, .b2i_add1
        j    .b2i_bad
.b2i_step:
        sll  $v0, $v0, 1
        addi $t0, $t0, 1
        addi $t1, $t1, 1
        j    .b2i_loop
.b2i_add1:
        sll  $v0, $v0, 1
        addi $v0, $v0, 1
        addi $t0, $t0, 1
        addi $t1, $t1, 1
        j    .b2i_loop
.b2i_bad:
        li   $v0, 0
        li   $v1, 0
        jr   $ra
.b2i_done:
        jr   $ra

        .globl int_to_binary8
int_to_binary8:
        andi $t0, $a0, 0x00FF
        move $t1, $a1
        li   $t2, 128
        li   $t6, 8
.itb8_loop:
        and  $t3, $t0, $t2
        beqz $t3, .itb8_zero
        li   $t4, '1'
        sb   $t4, 0($t1)
        j    .itb8_next
.itb8_zero:
        li   $t4, '0'
        sb   $t4, 0($t1)
.itb8_next:
        addi $t1, $t1, 1
        srl  $t2, $t2, 1
        addi $t6, $t6, -1
        bgtz $t6, .itb8_loop
        sb   $zero, 0($t1)
        jr   $ra