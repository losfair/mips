module regfile(
    clk,
    rst,
    index_1,
    index_2,
    out_1, // ok
    out_2, // ok
    windex,
    wdata,
    wen, // Write enable
    exception_in,
    exception
);

integer i; // not actually synthesized

input wire clk, rst, wen;
input wire [4:0] index_1, index_2, windex;
input wire [31:0] wdata;
input wire [7:0] exception_in;
output reg [31:0] out_1, out_2;
output reg [7:0] exception;

reg [31:0] store[31:0];

always @ (*) begin
    out_1 <= store[index_1];
    out_2 <= store[index_2];
end

always @ (posedge clk) begin

    $display("WB: exception_in = %b", exception_in);
    if(rst) begin
        for(i = 0; i < 32; i = i + 1) store[i] <= 0;
        $display("t=%0d regfile reset\n",$time);
        exception <= `TRAP_STALL;
    end else if(exception_in) exception <= exception_in;
    else begin
        if(wen) begin
            if(windex != 0) store[windex] <= wdata;
        end
        exception <= 0;

        $write("[CYCLE@%0d] wen=%b windex=%0d wdata=0x%0x ", $time, wen, windex, wdata);
        for(i = 0; i < 32; i = i + 1) $write("%0d=%0d ", i, store[i]);
        $write("\n");
    end
end

endmodule