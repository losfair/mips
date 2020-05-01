.section .text

start:
addi $sp, $zero, 0x800
addi $a0, $zero, 10
jal fib
syscall 42

fib:
addi $t0, $zero, 1
addi $t1, $zero, 2
beq $a0, $t0, fib_end
beq $a0, $t1, fib_end

addi $sp, $sp, -12
sw $ra, 8($sp)
sw $s0, 4($sp)
sw $s1, 0($sp)

addi $s0, $a0, -1
addi $a0, $s0, 0
jal fib
add $s1, $zero, $a0

addi $s0, $s0, -1
addi $a0, $s0, 0
jal fib
add $a0, $s1, $a0

lw $s1, 0($sp)
lw $s0, 4($sp)
lw $ra, 8($sp)
addi $sp, $sp, 12
jr $ra

fib_end:
addi $a0, $zero, 1
jr $ra