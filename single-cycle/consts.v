`define TRAP_BAD_INSTRUCTION       1
`define TRAP_SYSCALL               2
`define TRAP_OVERFLOW              3

`define TRAP_STALL                 8'b11111111

`define ALU_ADD                    0
`define ALU_SUB                    1
`define ALU_AND                    2
`define ALU_OR                     3
`define ALU_SLT                    4
`define ALU_BEQ                    5
`define ALU_MACCESS                6
`define ALU_SRA                    7
`define ALU_SLL                    8
`define ALU_SRL                    9
`define ALU_XOR                   10
`define ALU_BNE                   11
`define ALU_NOR                   12
`define ALU_LUI                   13
`define ALU_JAL                   14
`define ALU_JALR                  15
`define ALU_SLTU                  16
`define ALU_BGEZ                  17
`define ALU_BLTZ                  18
`define ALU_BGTZ                  19
`define ALU_BLEZ                  20
`define ALU_BAL                   21

`define ALU_STALL                  6'b111111