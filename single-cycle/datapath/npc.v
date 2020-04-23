module npc(
    linear_next,
    br_target,
    br_enable,
    next_pc
);

input wire [31:0] linear_next; // pc + 4
input wire [31:0] br_target;
input wire br_enable;

output wire [31:0] next_pc;
mux2 #(32) mux2_next_pc(br_enable, linear_next, br_target, next_pc);

endmodule