// Synchronous instruction decoder.

module decoder(
    ir,
    reg_dst_en,
    reg_write_en,
    alu_src_en,
    alu_const, // ok
    alu_op,
    mem_write_en,
    mem_read_en,
    mem2reg_en,
    rs, rt, rd, // ok
    exception
);

input wire [31:0] ir;
output reg
    reg_dst_en, reg_write_en, alu_src_en,
    mem_write_en, mem_read_en, mem2reg_en,
    exception;

output wire [31:0] alu_const; // Sign extension
output reg [5:0] alu_op;
output wire [4:0] rs, rt, rd;

wire [5:0] func;
reg zext;
wire [15:0] const_sext, const_zext, mux2_sext_or_zext_out;

wire [5:0] ir_op; // ok
assign ir_op = ir[31:26];
assign rs = ir[25:21];
assign rt = ir[20:16];
assign rd = ir[15:11];
// what is 'shamt'?
assign func = ir[5:0];

assign alu_const[15:0] = ir[15:0];
assign alu_const[31:16] = mux2_sext_or_zext_out;
assign const_sext = {16{ir[15]}};
assign const_zext = 16'b0;

mux2 #(16) mux2_sext_or_zext(zext, const_sext, const_zext, mux2_sext_or_zext_out);

always @ (*) begin
    // MUST ASSIGN:
    // - exception
    // - alu_src_en (if not exception)
    // - alu_op (if not exception)
    // - zext (if (not exception) and alu_src_en)
    case (ir_op)
        // lw
        6'b100011: begin
            alu_src_en <= 1;
            exception <= 0;
            alu_op <= 6'b000110; // lw
            zext <= 0; // sign extend
        end

        // sw
        6'b101011: begin
            alu_src_en <= 1;
            exception <= 0;
            alu_op <= 6'b000111; // sw
            zext <= 0; // sign extend
        end

        // beq
        6'b000100: begin
            alu_src_en <= 1;
            exception <= 0;
            alu_op <= 6'b000101; // beq
            zext <= 1;
        end

        // SPECIAL
        6'b000000: begin
            alu_src_en <= 0;
            case (func)
                6'b100000: begin
                    exception <= 0;
                    alu_op <= 6'b000000; // add
                end
                6'b100010: begin
                    exception <= 0;
                    alu_op <= 6'b000001; // sub
                end
                6'b100100: begin
                    exception <= 0;
                    alu_op <= 6'b000010; // and
                end
                6'b100101: begin
                    exception <= 0;
                    alu_op <= 6'b000011; // or
                end
                6'b101010: begin
                    exception <= 0;
                    alu_op <= 6'b000100; // slt
                end
                default: exception <= 1;
            endcase
        end

        // addi
        6'b001000: begin
            alu_src_en <= 1;
            exception <= 0;
            alu_op <= 6'b000000; // add
            zext <= 0;
        end

        // andi
        6'b001100: begin
            alu_src_en <= 1;
            exception <= 0;
            alu_op <= 6'b000010; // and
            zext <= 1;
        end

        // ori
        6'b001101: begin
            alu_src_en <= 1;
            exception <= 0;
            alu_op <= 6'b000011; // or
            zext <= 1;
        end

        // slti
        6'b001010: begin
            alu_src_en <= 1;
            exception <= 0;
            alu_op <= 6'b000100; // or
            zext <= 1;
        end

        
        default: begin
            exception <= 1;
        end
    endcase
end

endmodule