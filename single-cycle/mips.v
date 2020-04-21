module mips(
    clk,
    rst
);

input wire clk;
input wire rst;

// Connect up datapaths.

// PC
reg [31:0] pc;

// Current instruction and decoding information
wire [31:0] ir;

wire reg_dst_en,
    reg_write_en,
    alu_src_en,
    mem_write_en,
    mem_read_en,
    mem2reg_en,
    decoder_exception;

wire [31:0] alu_const;
wire [5:0] alu_op;
wire [4:0] rs, rt, rd;
wire [31:0] rs_val, rt_val;

decoder decoder_1(
    ir,
    reg_dst_en,
    reg_write_en,
    alu_src_en,
    alu_const,
    alu_op,
    mem_write_en,
    mem_read_en,
    mem2reg_en,
    rs, rt, rd,
    decoder_exception
);

// ALU
wire [31:0] alu_out;

// Register file
regfile regfile_1(
    clk, rst,
    rs, rt,
    rs_val, rt_val,
    rd,
    alu_out,
    reg_write_en
);

// IM

wire [11:2] im_addr;
assign im_addr = pc[11:2]; // FIXME: remove this?

im_4k im_4k_1(im_addr, ir);

// DM
wire [11:2] dm_addr;
wire [31:0] dm_din;
wire dm_we;
wire dm_clk;
wire [31:0] dm_dout;

dm_4k dm_4k_1(dm_addr, dm_din, dm_we, dm_clk, dm_dout);

// NPC
wire [31:0] npc_linear_next; // pc + 4
wire npc_br_enable; // TODO: Provided by ALU
wire [31:0] npc_next_pc;

assign npc_linear_next = pc + 4;
npc npc_1(npc_linear_next, alu_const /* br_offset_words */, npc_br_enable, npc_next_pc);

// TODO: Move this to a proper location.
always @ (posedge clk) begin
    if (rst) begin
        pc <= 32'h00003000;
    end else begin
        pc <= npc_next_pc;
    end
end

endmodule