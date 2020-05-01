module alu(
    clk, rst,
    op,
    check_overflow,
    next_pc,
    br_trigger,
    rs_val,
    rt_val,
    const_val,
    out_val,
    br_target,
    br_enable,
    exception_in,
    exception
);

input wire clk, rst;
input wire [7:0] exception_in;
input wire [5:0] op;
input wire check_overflow;
input wire [31:0] next_pc;
input wire br_trigger;
input wire [31:0] rs_val;
input wire [31:0] rt_val;
input wire [31:0] const_val;
output reg [31:0] out_val;
output reg [31:0] br_target;
output reg br_enable;
output reg [7:0] exception;

reg extra_bit;
reg br_pending;

wire [31:0] rt_val_complement;
assign rt_val_complement = !rt_val + 1;

always @ (posedge clk) begin
    exception <= 0;
    out_val <= 0;
    br_enable <= 0;
    br_target <= 0;

    if(rst) begin
        exception <= `TRAP_STALL;
        br_pending <= 0;
    end
    else if(br_pending && !br_trigger) exception <= `TRAP_STALL;
    else if(exception_in) exception <= exception_in;
    else begin
        if(br_enable) br_pending <= 1; // Delay slot
        else br_pending <= 0;
        $write("[CYCLE@%0d] alu run pc=0x%0x op=%b br_enable=%b br_pending=%b br_trigger=%b\n", $time, next_pc - 4, op, br_enable, br_pending, br_trigger);
        case (op)
            // add
            `ALU_ADD: begin
                {extra_bit, out_val} <= {rs_val[31], rs_val} + {rt_val[31], rt_val};
                if((extra_bit ^ out_val[31]) & check_overflow) exception <= `TRAP_OVERFLOW;
            end

            `ALU_SUB: begin
                {extra_bit, out_val} <= {rs_val[31], rs_val} + {rt_val_complement[31], rt_val_complement};
                if((extra_bit ^ out_val[31]) & check_overflow) exception <= `TRAP_OVERFLOW;
            end

            // and
            `ALU_AND: begin
                out_val <= rs_val & rt_val;
            end

            // or
            `ALU_OR: begin
                out_val <= rs_val | rt_val;
            end

            // slt
            `ALU_SLT: begin
                out_val <= $signed(rs_val) < $signed(rt_val);
            end

            // sltu
            `ALU_SLTU: begin
                out_val <= rs_val < rt_val;
            end

            `ALU_BAL: begin
                br_target <= next_pc + (const_val << 2);
                br_enable <= 1;
                out_val <= next_pc + 4;
            end

            // beq
            `ALU_BEQ: begin
                if(rs_val == rt_val) begin
                    br_target <= next_pc + (const_val << 2);
                    br_enable <= 1;
                end
            end

            // bgez
            `ALU_BGEZ: begin
                if($signed(rs_val) >= $signed(0)) begin
                    br_target <= next_pc + (const_val << 2);
                    br_enable <= 1;
                end
            end

            // bltz
            `ALU_BLTZ: begin
                if($signed(rs_val) < $signed(0)) begin
                    br_target <= next_pc + (const_val << 2);
                    br_enable <= 1;
                end
            end

            // bgtz
            `ALU_BGTZ: begin
                if($signed(rs_val) > $signed(0)) begin
                    br_target <= next_pc + (const_val << 2);
                    br_enable <= 1;
                end
            end

            // blez
            `ALU_BLEZ: begin
                if($signed(rs_val) <= $signed(0)) begin
                    br_target <= next_pc + (const_val << 2);
                    br_enable <= 1;
                end
            end

            `ALU_BNE: begin
                if(rs_val != rt_val) begin
                    br_target <= next_pc + (const_val << 2);
                    br_enable <= 1;
                end
            end

            // lw/lb/sw/sb
            `ALU_MACCESS: begin
                out_val <= rs_val + const_val;
            end

            `ALU_SLL: begin
                out_val <= rt_val << rs_val[4:0];
            end

            `ALU_SRL: begin
                out_val <= rt_val >> rs_val[4:0];
            end

            `ALU_SRA: begin
                out_val <= $signed(rt_val) >> rs_val[4:0];
            end

            `ALU_XOR: begin
                out_val <= rt_val ^ rs_val;
            end

            `ALU_NOR: begin
                out_val <= ~(rt_val | rs_val);
            end

            `ALU_LUI: begin
                out_val <= const_val << 16;
            end

            `ALU_JAL: begin
                br_target <= {next_pc[31:28], const_val[27:0]};
                br_enable <= 1;
                out_val <= next_pc + 4;
            end

            `ALU_JALR: begin
                br_target <= rs_val;
                br_enable <= 1;
                out_val <= next_pc + 4;
            end

            default: begin
                exception <= `TRAP_STALL;
            end
        endcase
    end
end

endmodule