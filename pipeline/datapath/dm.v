module dm_4k(
    clk, rst,
    addr, // Address In
    din, // Data In
    we, // Write Enable
    dout, // Data Out
    exception_in,
    exception
);

input wire clk, rst;
input wire [11:0] addr;
input wire [31:0] din;
input wire we;
input wire [7:0] exception_in;
output wire [31:0] dout;
output reg [7:0] exception;

reg [31:0] dm [1023:0]; // 1024 * 4 = 4096

wire [9:0] addr_word;
assign addr_word = addr[11:2];

assign dout = dm[addr_word];

integer i;

initial begin
    for(i = 0; i < 1024; i = i + 1) dm[i] <= 0;
end

always @ (posedge clk) begin
    if(rst) begin
        exception <= `TRAP_STALL;
    end
    else if(exception_in) exception <= exception_in;
    else begin
        if(we) begin
            dm[addr_word] <= din;
            $display("DM write 0x%0x 0x%0x", addr_word, din);
        end
        exception <= 0;
    end
end

endmodule
