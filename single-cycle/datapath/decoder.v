// Synchronous instruction decoder.

module decoder(
    ir,
    reg_write_en, // ok
    alu_const_as_rs, // ok
    alu_const_as_rt, // ok
    alu_const, // ok
    alu_op, // ok
    alu_check_overflow,
    mem_write_en, // ok
    mem2reg_en,
    maccess_width, // ok
    mem2reg_zext, // ok
    rs, rt, rd, // ok
    exception
);

input wire [31:0] ir;
output reg
    alu_check_overflow,
    reg_write_en, alu_const_as_rs, alu_const_as_rt,
    mem_write_en, mem2reg_en;
output reg [1:0] maccess_width;
output reg mem2reg_zext;
output reg [7:0] exception;

output wire [31:0] alu_const; // Sign extension
output reg [5:0] alu_op;
output wire [4:0] rs, rt, rd;

wire [31:0] alu_const_16bit;
wire [31:0] alu_const_shamt;
wire [31:0] alu_const_16bit_or_shamt;
wire [31:0] alu_const_j;
reg use_alu_const_j;
reg use_alu_const_shamt;

reg rt_as_rd; // ok

wire [5:0] func; // ok
reg zext; // ok
wire [15:0] const_sext, const_zext, mux2_sext_or_zext_out; // ok

wire [5:0] ir_op; // ok
assign ir_op = ir[31:26];
assign rs = ir[25:21];
assign rt = ir[20:16];

// MUX for rd
reg link_rd;
wire [4:0] thirty_one;
wire [4:0] rd_direct;
wire [4:0] rd_pre_link;

assign thirty_one = 31;
assign rd_direct = ir[15:11];
mux2 #(5) mux2_rd_pre_j(rt_as_rd, rd_direct, rt, rd_pre_link);
mux2 #(5) mux2_rd(link_rd, rd_pre_link, thirty_one, rd);

// what is 'shamt'?
assign func = ir[5:0];

assign alu_const_16bit[15:0] = ir[15:0];
assign alu_const_16bit[31:16] = mux2_sext_or_zext_out;
assign alu_const_shamt[4:0] = ir[10:6];
assign alu_const_shamt[31:5] = 27'b0;
assign alu_const_j[31:28] = 4'b0;
assign alu_const_j[27:2] = ir[25:0];
assign alu_const_j[1:0] = 2'b0;

mux2 #(32) mux2_alu_const_16bit_or_shamt(use_alu_const_shamt, alu_const_16bit, alu_const_shamt, alu_const_16bit_or_shamt);
mux2 #(32) mux2_alu_const(use_alu_const_j, alu_const_16bit_or_shamt, alu_const_j, alu_const);

assign const_sext = {16{ir[15]}};
assign const_zext = 16'b0;
mux2 #(16) mux2_sext_or_zext(zext, const_sext, const_zext, mux2_sext_or_zext_out);

always @ (*) begin
    // Blocking assignments
    alu_const_as_rs = 0;
    alu_const_as_rt = 0;
    exception = 0;
    zext = 0; // sign extend
    maccess_width = 2'b00;
    mem2reg_zext = 0;
    mem_write_en = 0;
    reg_write_en = 0;
    rt_as_rd = 0;
    alu_op = `ALU_STALL;
    alu_check_overflow = 0;
    use_alu_const_j = 0;
    use_alu_const_shamt = 0;
    link_rd = 0;
    mem2reg_en = 0;

    case (ir_op)
        // lw
        6'b100011: begin
            alu_op = `ALU_MACCESS;
            reg_write_en = 1;
            maccess_width = 2'b11; // 4 bytes
            mem2reg_en = 1;
            mem2reg_zext = 0;
            rt_as_rd = 1; // For the `lw` instruction, the destionation register is placed in `rt` instead of `rd`.
        end

        // lb
        6'b100000: begin
            alu_op = `ALU_MACCESS;
            reg_write_en = 1;
            maccess_width = 2'b01; // 1 byte
            mem2reg_en = 1;
            mem2reg_zext = 0;
            rt_as_rd = 1;
        end

        // lbu
        6'b100100: begin
            alu_op = `ALU_MACCESS;
            reg_write_en = 1;
            maccess_width = 2'b01; // 1 byte
            mem2reg_en = 1;
            mem2reg_zext = 1;
            rt_as_rd = 1;
        end

        // sw
        6'b101011: begin
            alu_op = `ALU_MACCESS;
            mem_write_en = 1;
            maccess_width = 2'b11; // 4 bytes
        end

        // sb
        6'b101000: begin
            alu_op = `ALU_MACCESS;
            mem_write_en = 1;
            maccess_width = 2'b01; // 1 byte
        end

        // beq
        6'b000100: begin
            alu_op = `ALU_BEQ;
        end

        // bne
        6'b000101: begin
            alu_op = `ALU_BNE;
        end

        // REGIMM
        6'b000001: begin
            case (rt)
                5'b00000: begin
                    alu_op = `ALU_BLTZ;
                end
                5'b00001: begin
                    alu_op = `ALU_BGEZ;
                end
                5'b10001: begin
                    alu_op = `ALU_BAL;
                    link_rd = 1;
                    reg_write_en = 1;
                end
                default: begin
                    exception = `TRAP_BAD_INSTRUCTION;
                end
            endcase
        end

        // bgtz
        6'b000111: alu_op = `ALU_BGTZ;

        // blez
        6'b000110: alu_op = `ALU_BLEZ;

        // SPECIAL
        6'b000000: begin
            case (func)
                // add
                6'b100000: begin
                    alu_op = `ALU_ADD;
                    reg_write_en = 1;
                    alu_check_overflow = 1;
                end

                // addu
                6'b100001: begin
                    alu_op = `ALU_ADD;
                    reg_write_en = 1;
                end

                // sub
                6'b100010: begin
                    alu_op = `ALU_SUB;
                    reg_write_en = 1;
                    alu_check_overflow = 1;
                end

                // subu
                6'b100011: begin
                    alu_op = `ALU_SUB;
                    reg_write_en = 1;
                end

                // and
                6'b100100: begin
                    alu_op = `ALU_AND; // and
                    reg_write_en = 1;
                end

                // or
                6'b100101: begin
                    alu_op = `ALU_OR; // or
                    reg_write_en = 1;
                end

                // nor
                6'b100111: begin
                    alu_op = `ALU_NOR;
                    reg_write_en = 1;
                end

                // xor
                6'b100110: begin
                    alu_op = `ALU_XOR;
                    reg_write_en = 1;
                end

                // slt
                6'b101010: begin
                    alu_op = `ALU_SLT;
                    reg_write_en = 1;
                end

                // sltu
                6'b101011: begin
                    alu_op = `ALU_SLTU;
                    reg_write_en = 1;
                end

                // sll
                6'b000000: begin
                    alu_const_as_rs = 1;
                    use_alu_const_shamt = 1;
                    alu_op = `ALU_SLL; // sll
                    reg_write_en = 1;
                end

                // sllv
                6'b000100: begin
                    alu_op = `ALU_SLL;
                    reg_write_en = 1;
                end

                // srl
                6'b000010: begin
                    alu_const_as_rs = 1;
                    use_alu_const_shamt = 1;
                    alu_op = `ALU_SRL;
                    reg_write_en = 1;
                end

                // srlv
                6'b000110: begin
                    alu_op = `ALU_SRL;
                    reg_write_en = 1;
                end

                // sra
                6'b000011: begin
                    alu_const_as_rs = 1;
                    use_alu_const_shamt = 1;
                    alu_op = `ALU_SRA;
                    reg_write_en = 1;
                end

                // srav
                6'b000111: begin
                    alu_op = `ALU_SRA;
                    reg_write_en = 1;
                end

                // jr
                6'b001000: begin
                    alu_op = `ALU_JALR;
                end

                // jalr
                6'b001001: begin
                    alu_op = `ALU_JALR;
                    link_rd = 1;
                    reg_write_en = 1;
                end

                // syscall
                6'b001100: begin
                    exception = `TRAP_SYSCALL;
                end

                default: begin
                    exception = `TRAP_BAD_INSTRUCTION;
                end
            endcase
        end

        // addi
        6'b001000: begin
            alu_const_as_rt = 1;
            rt_as_rd = 1;
            alu_op = `ALU_ADD;
            reg_write_en = 1;
            alu_check_overflow = 1;
        end

        // addiu
        6'b001001: begin
            alu_const_as_rt = 1;
            rt_as_rd = 1;
            alu_op = `ALU_ADD;
            reg_write_en = 1;
        end

        // andi
        6'b001100: begin
            alu_const_as_rt = 1;
            rt_as_rd = 1;
            alu_op = `ALU_AND;
            reg_write_en = 1;
            zext = 1;
        end

        // ori
        6'b001101: begin
            alu_const_as_rt = 1;
            rt_as_rd = 1;
            alu_op = `ALU_OR;
            reg_write_en = 1;
            zext = 1;
        end

        // xori
        6'b001110: begin
            alu_const_as_rt = 1;
            rt_as_rd = 1;
            alu_op = `ALU_XOR;
            reg_write_en = 1;
            zext = 1;
        end

        // slti
        6'b001010: begin
            alu_const_as_rt = 1;
            rt_as_rd = 1;
            alu_op = `ALU_SLT;
            reg_write_en = 1;
        end

        // sltiu
        6'b001011: begin
            alu_const_as_rt = 1;
            rt_as_rd = 1;
            alu_op = `ALU_SLTU;
            reg_write_en = 1;
        end

        // lui
        6'b001111: begin
            rt_as_rd = 1;
            alu_op = `ALU_LUI;
            reg_write_en = 1;
        end

        // j
        6'b000010: begin
            use_alu_const_j = 1;
            alu_op = `ALU_JAL;
            // do not enable register write (no link)
        end

        // jal
        6'b000011: begin
            use_alu_const_j = 1;
            alu_op = `ALU_JAL;
            link_rd = 1;
            reg_write_en = 1;
        end

        default: begin
            //$display("bad instruction: %b/%b", ir_op, ir);
            exception = `TRAP_BAD_INSTRUCTION;
        end
    endcase
end

endmodule