module npc(
    linear_next,
    br_offset_words,
    br_enable,
    next_pc
);

input wire [31:0] linear_next; // pc + 4
input wire [31:0] br_offset_words; // offset * 4
input wire br_enable;

output reg [31:0] next_pc;

wire [31:0] br_offset;
assign br_offset = br_offset_words << 2;

always @ (*) begin
    if(br_enable) begin
        next_pc <= linear_next + br_offset;
    end else begin
        next_pc <= linear_next;
    end
end

endmodule