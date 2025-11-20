# ===== Random (MARS syscall 42) =====
# IMPORTANT: On this MARS, syscall 42 returns the random result in $a0 (not $v0).
# rand_in_range(a0=lower, a1=upperExclusive) -> a0=result
        .text
        .globl rand_in_range
rand_in_range:
        li    $v0, 42
        # $a0 = lower, $a1 = upper (exclusive), per caller setup
        syscall         # result is returned in $a0 on this MARS
        jr    $ra