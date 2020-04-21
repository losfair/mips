module regfile(
    clk,
    rst,
    index_1,
    index_2,
    out_1,
    out_2,
    windex,
    wdata,
    wen // Write enable
);

integer i; // not actually synthesized

input wire clk, rst, wen;
input wire [4:0] index_1, index_2, windex;
input wire [31:0] wdata;
output reg [31:0] out_1, out_2;

reg [31:0] store[31:0];

always @ (posedge clk) begin
    if(rst) begin
        for(i = 0; i < 32; i = i + 1) store[i] <= 0;
    end else begin
        if(wen) store[windex] <= wdata;

        out_1 <= store[index_1];
        out_2 <= store[index_2];
    end
end

endmodule