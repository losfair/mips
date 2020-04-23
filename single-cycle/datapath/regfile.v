module regfile(
    clk,
    rst,
    index_1,
    index_2,
    out_1, // ok
    out_2, // ok
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

always @ (*) begin
    out_1 <= store[index_1];
    out_2 <= store[index_2];
end

always @ (posedge clk) begin
    if(rst) begin
        for(i = 0; i < 32; i = i + 1) store[i] <= 0;
        $display("t=%0d regfile reset\n",$time);
    end else begin
        if(wen) begin
            if(windex != 0) store[windex] <= wdata;
        end

        $write("[CYCLE@%0d] ", $time);
        for(i = 0; i < 32; i = i + 1) $write("%0d=%0d ", i, store[i]);
        $write("\n");
    end
end

endmodule