module mips(
    clk,
    rst
);

input wire clk;
input wire rst;

// Connect up datapaths.

// PC
reg [31:0] pc_id;
wire [31:0] pc_ex;

delay #(32) delay_pc_ex(clk, pc_id, pc_ex);

// Current instruction and decoding information
wire [31:0] ir;

wire
    alu_const_as_rs,
    alu_const_as_rt,
    mem_write_en_d0, mem_write_en_d1,
    reg_write_en_d0, reg_write_en_d1, reg_write_en_d2,
    mem2reg_en_d0, mem2reg_en_d1, mem2reg_en_d2,
    alu_check_overflow;
reg br_trigger_d0;
wire br_trigger_d1;

wire [1:0] maccess_width_d0, maccess_width_d1;
wire mem2reg_zext_d0, mem2reg_zext_d1;
wire [7:0] decoder_exception;

wire [31:0] alu_const;
wire [5:0] alu_op;
wire [4:0] rs, rt;
wire [4:0] rd_d0, rd_d1, rd_d2;
wire [31:0] rs_val_raw, rs_val, rt_val_raw, rt_val;
mux2 #(32) mux2_rs_val(alu_const_as_rs, rs_val_raw, alu_const, rs_val);
mux2 #(32) mux2_rt_val(alu_const_as_rt, rt_val_raw, alu_const, rt_val);

wire [7:0] if_exception, id_exception, ex_exception, mem_exception, wb_exception;

assign if_exception = 8'd0;

delay d1_br_trigger(clk, br_trigger_d0, br_trigger_d1);

delay d1_mem_write_en(clk, mem_write_en_d0, mem_write_en_d1);

delay #(2) d1_maccess_width(clk, maccess_width_d0, maccess_width_d1);

delay d1_reg_write_en(clk, reg_write_en_d0, reg_write_en_d1);
delay d2_reg_write_en(clk, reg_write_en_d1, reg_write_en_d2);

delay d1_mem2reg_en(clk, mem2reg_en_d0, mem2reg_en_d1);
delay d2_mem2reg_en(clk, mem2reg_en_d1, mem2reg_en_d2);

delay #(5) d1_rd(clk, rd_d0, rd_d1);
delay #(5) d2_rd(clk, rd_d1, rd_d2);

delay d1_mem2reg_zext(clk, mem2reg_zext_d0, mem2reg_zext_d1);

// Instruction memory
wire [9:0] im_addr;
assign im_addr = pc_id[11:2]; // FIXME: remove this?
im_4k im_4k_1(im_addr, ir);

// Stage 2: ID
decoder decoder_1(
    clk, rst,
    ir,
    reg_write_en_d0,
    alu_const_as_rs,
    alu_const_as_rt,
    alu_const,
    alu_op,
    alu_check_overflow,
    mem_write_en_d0,
    mem2reg_en_d0,
    maccess_width_d0,
    mem2reg_zext_d0,
    rs, rt, rd_d0,
    if_exception,
    id_exception
);

// Stage 3: ALU/EX
wire [31:0] pc_ex_linear_next;
wire [31:0] alu_out_d0, alu_out_d1;
wire br_enable;
wire [31:0] br_target;
wire [7:0] alu_exception;

delay #(32) d1_alu_out(clk, alu_out_d0, alu_out_d1);

assign pc_ex_linear_next = pc_ex + 4;
alu alu_1(
    clk, rst,
    alu_op,
    alu_check_overflow,
    pc_ex_linear_next,
    br_trigger_d1,
    rs_val, rt_val,
    alu_const,
    alu_out_d0,
    br_target, br_enable,
    id_exception,
    ex_exception
);

// Stage 4: DM/MEM
wire [31:0] dm_din;
wire [31:0] dm_dout;
wire [9:0] dm_addr;
assign dm_addr = alu_out_d0[9:0];
dm_4k dm_4k_1(clk, rst, dm_addr, dm_din, mem_write_en_d1, dm_dout, ex_exception, mem_exception);

// Memory access middleware
wire [1:0] maccess_addrtail;
wire [31:0] maccess_dout;
assign maccess_addrtail = dm_addr[1:0];
mread mread_1(maccess_addrtail, maccess_width_d1, mem2reg_zext_d1, dm_dout, maccess_dout);
mwrite mwrite_1(maccess_addrtail, maccess_width_d1, rt_val, dm_dout, dm_din);

// Stage 5: Register file/WB
wire [31:0] reg_write_data;
mux2 #(32) mux2_reg_write_data(mem2reg_en_d2, alu_out_d1, maccess_dout, reg_write_data);
regfile regfile_1(
    clk, rst,
    rs, rt,
    rs_val_raw, rt_val_raw,
    rd_d2,
    reg_write_data,
    reg_write_en_d2,
    mem_exception,
    wb_exception
);

reg halted;
reg [63:0] cycle_count;

// TODO: Move this to a proper location.
always @ (posedge clk) begin
    if(rst) begin
        $display("t=%0d mips reset\n", $time);
        halted <= 0;
        pc_id <= 32'h00003000;
        cycle_count <= 1;
        br_trigger_d0 <= 0;
    end else begin
        cycle_count <= cycle_count + 1;
        if(halted) begin
            $finish();
        end else begin
            if(wb_exception != 0 && wb_exception != `TRAP_STALL) begin
                $display("t=%0d HALTED for wb exception. exc=%b pc_id=0x%0x ir=%b cycles=%0d", $time, wb_exception, pc_id, ir, cycle_count);
                halted <= 1;
            end
            $write("[CYCLE@%0d] pc_id=0x%0x pc_ex=0x%0x\n", $time, pc_id, pc_ex);
            if(br_enable) begin
                pc_id <= br_target;
                br_trigger_d0 <= 1;
            end else begin
                pc_id <= pc_id + 4;
                br_trigger_d0 <= 0;
            end
        end
    end
end

endmodule