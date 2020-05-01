module forward(
    clk, rst,
    ex_out_index, ex_regwrite_en_maybe, ex_out_val, ex_exception,
    mem_out_index, mem_mem2reg_en_maybe, mem_out_val, mem_exception,
    ex_rs_index, ex_rs_regfetch, ex_rs_val,
    ex_rt_index, ex_rt_regfetch, ex_rt_val
);

input wire clk, rst;

// EX stage output
input wire [4:0] ex_out_index;
input wire ex_regwrite_en_maybe;
input wire [31:0] ex_out_val;
input wire [7:0] ex_exception;

assign ex_regwrite_en = ex_regwrite_en_maybe && (ex_exception == 0);

// EX stage hold
reg [4:0] ex_out_index_hold[0:1];
reg ex_regwrite_en_hold[0:1];
reg [31:0] ex_out_val_hold[0:1];

// MEM stage output
input wire [4:0] mem_out_index;
input wire mem_mem2reg_en_maybe;
input wire [31:0] mem_out_val;
input wire [7:0] mem_exception;

assign mem_mem2reg_en = mem_mem2reg_en_maybe && (mem_exception == 0);

// MEM stage hold
reg [4:0] mem_out_index_hold;
reg mem_mem2reg_en_hold;
reg [31:0] mem_out_val_hold;

// ID stage output
input wire [4:0] ex_rs_index, ex_rt_index;
input wire [31:0] ex_rs_regfetch, ex_rt_regfetch;

// Usable by EX stage
output wire [31:0] ex_rs_val, ex_rt_val;

assign ex_rs_fwd_n = ex_regwrite_en && (ex_out_index == ex_rs_index);
assign ex_rt_fwd_n = ex_regwrite_en && (ex_out_index == ex_rt_index);

assign ex_rs_fwd_h0 = ex_regwrite_en_hold[0] && (ex_out_index_hold[0] == ex_rs_index);
assign ex_rt_fwd_h0 = ex_regwrite_en_hold[0] && (ex_out_index_hold[0] == ex_rt_index);

assign ex_rs_fwd_h1 = ex_regwrite_en_hold[1] && (ex_out_index_hold[1] == ex_rs_index);
assign ex_rt_fwd_h1 = ex_regwrite_en_hold[1] && (ex_out_index_hold[1] == ex_rt_index);

assign mem_rs_fwd_n = mem_mem2reg_en && (mem_out_index == ex_rs_index);
assign mem_rt_fwd_n = mem_mem2reg_en && (mem_out_index == ex_rt_index);

assign mem_rs_fwd_h0 = mem_mem2reg_en_hold && (mem_out_index_hold == ex_rs_index);
assign mem_rt_fwd_h0 = mem_mem2reg_en_hold && (mem_out_index_hold == ex_rt_index);

wire [31:0]
    ex_rs_val_memfwd_h0, ex_rt_val_memfwd_h0,
    ex_rs_val_memfwd_n, ex_rt_val_memfwd_n,
    ex_rs_val_exfwd_h1, ex_rt_val_exfwd_h1,
    ex_rs_val_exfwd_h0, ex_rt_val_exfwd_h0,
    ex_rs_val_exfwd_n, ex_rt_val_exfwd_n;

// mem2reg has a higher priority than ex_regwrite, since ex_regwrite is also enabled when
// the operation is actually a memory load.

assign ex_rs_val_exfwd_h1 = ex_rs_fwd_h1 ? ex_out_val_hold[1] : ex_rs_regfetch;
assign ex_rt_val_exfwd_h1 = ex_rt_fwd_h1 ? ex_out_val_hold[1] : ex_rt_regfetch;

assign ex_rs_val_exfwd_h0 = ex_rs_fwd_h0 ? ex_out_val_hold[0] : ex_rs_val_exfwd_h1;
assign ex_rt_val_exfwd_h0 = ex_rt_fwd_h0 ? ex_out_val_hold[0] : ex_rt_val_exfwd_h1;

assign ex_rs_val_exfwd_n = ex_rs_fwd_n ? ex_out_val : ex_rs_val_exfwd_h0;
assign ex_rt_val_exfwd_n = ex_rt_fwd_n ? ex_out_val : ex_rt_val_exfwd_h0;

assign ex_rs_val_memfwd_h0 = mem_rs_fwd_h0 ? mem_out_val_hold : ex_rs_val_exfwd_n;
assign ex_rt_val_memfwd_h0 = mem_rt_fwd_h0 ? mem_out_val_hold : ex_rt_val_exfwd_n;

assign ex_rs_val_memfwd_n = mem_rs_fwd_n ? mem_out_val : ex_rs_val_memfwd_h0;
assign ex_rt_val_memfwd_n = mem_rt_fwd_n ? mem_out_val : ex_rt_val_memfwd_h0;

assign ex_rs_val = (ex_rs_index == 0) ? 0 : ex_rs_val_memfwd_n;
assign ex_rt_val = (ex_rt_index == 0) ? 0 : ex_rt_val_memfwd_n;

always @ (posedge clk) begin
    if(rst) begin
        ex_out_index_hold[0] <= 0;
        ex_out_index_hold[1] <= 0;
        ex_regwrite_en_hold[0] <= 0;
        ex_regwrite_en_hold[1] <= 0;
        ex_out_val_hold[0] <= 0;
        ex_out_val_hold[1] <= 0;

        mem_out_index_hold <= 0;
        mem_mem2reg_en_hold <= 0;
        mem_out_val_hold <= 0;
    end else begin
        ex_out_index_hold[0] <= ex_out_index;
        ex_out_index_hold[1] <= ex_out_index_hold[0];
        ex_regwrite_en_hold[0] <= ex_regwrite_en;
        ex_regwrite_en_hold[1] <= ex_regwrite_en_hold[0];
        ex_out_val_hold[0] <= ex_out_val;
        ex_out_val_hold[1] <= ex_out_val_hold[0];

        mem_out_index_hold <= mem_out_index;
        mem_mem2reg_en_hold <= mem_mem2reg_en;
        mem_out_val_hold <= mem_out_val;

        $display("FORWARD t=%0d rs=0x%0x rs_val=0x%0x rs_fetch=0x%0x rt=0x%0x rt_val=0x%0x rt_fetch=0x%0x", $time, ex_rs_index, ex_rs_val, ex_rs_regfetch, ex_rt_index, ex_rt_val, ex_rt_regfetch);
        $display("\tex_out_index=0x%x 0x%x 0x%x", ex_out_index, ex_out_index_hold[0], ex_out_index_hold[1]);
        $display("\tex_regwrite_en=0x%x 0x%x 0x%x", ex_regwrite_en, ex_regwrite_en_hold[0], ex_regwrite_en_hold[1]);
        $display("\tex_out_val=0x%x 0x%x 0x%x", ex_out_val, ex_out_val_hold[0], ex_out_val_hold[1]);
    end
end

endmodule
