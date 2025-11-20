# ===== Verify =====
        .text
        .globl verify_equal
verify_equal:
        beq  $a0, $a1, .veq_ok
        li   $v0, 0
        jr   $ra
.veq_ok:
        li   $v0, 1
        jr   $ra