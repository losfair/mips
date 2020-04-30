module alu(
    op,
    check_overflow,
    next_pc_with_delay,
    rs_val,
    rt_val,
    const_val,
    out_val,
    br_target,
    br_enable,
    exception
);

input wire [5:0] op;
input wire check_overflow;
input wire [31:0] next_pc_with_delay;
input wire [31:0] rs_val;
input wire [31:0] rt_val;
input wire [31:0] const_val;
output reg [31:0] out_val;
output reg [31:0] br_target;
output reg br_enable;
output reg [7:0] exception;

reg extra_bit;

// MIPS requires a delay slot but it seems that the test doesn't expect one...
wire [31:0] next_pc;
assign next_pc = next_pc_with_delay - 4;

wire [31:0] rt_val_complement;
assign rt_val_complement = !rt_val + 1;

always @ (*) begin
    br_target = 0;
    br_enable = 0;
    exception = 0;
    out_val = 0;

    case (op)
        // add
        `ALU_ADD: begin
            {extra_bit, out_val} = {rs_val[31], rs_val} + {rt_val[31], rt_val};
            if((extra_bit ^ out_val[31]) & check_overflow) exception = `TRAP_OVERFLOW;
        end

        `ALU_SUB: begin
            {extra_bit, out_val} = {rs_val[31], rs_val} + {rt_val_complement[31], rt_val_complement};
            if((extra_bit ^ out_val[31]) & check_overflow) exception = `TRAP_OVERFLOW;
        end

        // and
        `ALU_AND: begin
            out_val = rs_val & rt_val;
        end

        // or
        `ALU_OR: begin
            out_val = rs_val | rt_val;
        end

        // slt
        `ALU_SLT: begin
            out_val = $signed(rs_val) < $signed(rt_val);
        end

        // sltu
        `ALU_SLTU: begin
            out_val = rs_val < rt_val;
        end

        `ALU_BAL: begin
            br_target = next_pc + (const_val << 2);
            br_enable = 1;
            out_val = next_pc + 4;
        end

        // beq
        `ALU_BEQ: begin
            if(rs_val == rt_val) begin
                br_target = next_pc + (const_val << 2);
                br_enable = 1;
            end
        end

        // bgez
        `ALU_BGEZ: begin
            if($signed(rs_val) >= $signed(0)) begin
                br_target = next_pc + (const_val << 2);
                br_enable = 1;
            end
        end

        // bltz
        `ALU_BLTZ: begin
            if($signed(rs_val) < $signed(0)) begin
                br_target = next_pc + (const_val << 2);
                br_enable = 1;
            end
        end

        // bgtz
        `ALU_BGTZ: begin
            if($signed(rs_val) > $signed(0)) begin
                br_target = next_pc + (const_val << 2);
                br_enable = 1;
            end
        end

        // blez
        `ALU_BLEZ: begin
            if($signed(rs_val) <= $signed(0)) begin
                br_target = next_pc + (const_val << 2);
                br_enable = 1;
            end
        end

        `ALU_BNE: begin
            if(rs_val != rt_val) begin
                br_target = next_pc + (const_val << 2);
                br_enable = 1;
            end
        end

        // lw/lb/sw/sb
        `ALU_MACCESS: begin
            out_val = rs_val + const_val;
        end

        `ALU_SLL: begin
            out_val = rt_val << rs_val[4:0];
        end

        `ALU_SRL: begin
            out_val = rt_val >> rs_val[4:0];
        end

        `ALU_SRA: begin
            out_val = $signed(rt_val) >> rs_val[4:0];
        end

        `ALU_XOR: begin
            out_val = rt_val ^ rs_val;
        end

        `ALU_NOR: begin
            out_val = ~(rt_val | rs_val);
        end

        `ALU_LUI: begin
            out_val = const_val << 16;
        end

        `ALU_JAL: begin
            br_target = {next_pc[31:28], const_val[27:0]};
            br_enable = 1;
            out_val = next_pc + 4;
        end

        `ALU_JALR: begin
            br_target = rs_val;
            br_enable = 1;
            out_val = next_pc + 4;
        end

        default: begin
            exception = `TRAP_STALL;
        end
    endcase
end

endmodule