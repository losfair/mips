module mips(
    clk,
    rst,
    pc
);

input wire clk;
input wire rst;

// Connect up datapaths.

// PC
output reg [31:0] pc;

// Current instruction and decoding information
wire [31:0] ir;

wire reg_write_en,
    alu_const_as_rs,
    alu_const_as_rt,
    mem_write_en,
    mem2reg_en,
    alu_check_overflow;
wire [1:0] maccess_width;
wire mem2reg_zext;
wire [7:0] decoder_exception;

wire [31:0] alu_const;
wire [5:0] alu_op;
wire [4:0] rs, rt, rd;
wire [31:0] rs_val_raw, rs_val, rt_val_raw, rt_val;
mux2 #(32) mux2_rs_val(alu_const_as_rs, rs_val_raw, alu_const, rs_val);
mux2 #(32) mux2_rt_val(alu_const_as_rt, rt_val_raw, alu_const, rt_val);

decoder decoder_1(
    ir,
    reg_write_en,
    alu_const_as_rs,
    alu_const_as_rt,
    alu_const,
    alu_op,
    alu_check_overflow,
    mem_write_en,
    mem2reg_en,
    maccess_width,
    mem2reg_zext,
    rs, rt, rd,
    decoder_exception
);

// ALU
wire [31:0] pc_linear_next;
wire [31:0] alu_out;
wire br_enable;
wire [31:0] br_target;
wire [7:0] alu_exception;

assign pc_linear_next = pc + 4;
alu alu_1(
    alu_op,
    alu_check_overflow,
    pc_linear_next,
    rs_val, rt_val,
    alu_const,
    alu_out,
    br_target, br_enable,
    alu_exception
);


// Exception.
wire [7:0] exception;
assign no_decoder_exception = decoder_exception == 0;
assign has_exception = exception != 0;
mux2 #(8) mux2_exception(no_decoder_exception, decoder_exception, alu_exception, exception);

// IM

wire [9:0] im_addr;
assign im_addr = pc[11:2]; // FIXME: remove this?
im_4k im_4k_1(im_addr, ir);

// DM
wire [31:0] dm_din;
wire [31:0] dm_dout;
wire [11:0] dm_addr;
assign dm_addr = alu_out[11:0];
assign dm_we = mem_write_en & !has_exception;
wire [3:0] dm_wbyte_enable;
dm_4k dm_4k_1(dm_addr[11:2], dm_din, dm_we, dm_wbyte_enable, clk, dm_dout);

// Memory access
wire [1:0] maccess_addrtail;
wire [31:0] maccess_dout;
assign maccess_addrtail = dm_addr[1:0];
mread mread_1(maccess_addrtail, maccess_width, mem2reg_zext, dm_dout, maccess_dout);
mwrite mwrite_1(maccess_addrtail, maccess_width, rt_val, dm_wbyte_enable, dm_din);

// Register file
assign reg_write_en_real = reg_write_en & !has_exception;
wire [31:0] reg_write_data;
mux2 #(32) mux2_reg_write_data(mem2reg_en, alu_out, maccess_dout, reg_write_data);
regfile regfile_1(
    clk, rst,
    rs, rt,
    rs_val_raw, rt_val_raw,
    rd,
    reg_write_data,
    reg_write_en_real
);

// NPC
wire [31:0] npc_next_pc;
assign br_enable_real = br_enable & !has_exception;
npc npc_1(pc_linear_next, br_target, br_enable_real, npc_next_pc);

reg halted;
reg [63:0] cycle_count;

// TODO: Move this to a proper location.
always @ (posedge clk) begin
    if(rst) begin
        $display("t=%0d mips reset\n", $time);
        halted <= 0;
        pc <= 32'h00003000;
        cycle_count <= 1;
    end else begin
        cycle_count <= cycle_count + 1;
        if(halted) begin
            $finish();
        end else begin
            if(decoder_exception != 0) begin
                $display("t=%0d HALTED for decoder exception. exc=%b pc=0x%0x ir=%b cycles=%0d", $time, decoder_exception, pc, ir, cycle_count);
                halted <= 1;
            end else if(alu_exception != 0 && alu_exception != `TRAP_STALL) begin
                $display("t=%0d HALTED for ALU exception. exc=%b pc=0x%0x ir=%b cycles=%0d", $time, alu_exception, pc, ir, cycle_count);
                halted <= 1;
            end
            $write("[CYCLE@%0d] pc=0x%0x\n", $time, pc);
            if(npc_next_pc == 0) halted <= 1;
            pc <= npc_next_pc;
        end
    end
end

endmodule