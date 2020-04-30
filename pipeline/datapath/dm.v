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
input wire [11:2] addr;
input wire [31:0] din;
input wire we;
input wire [7:0] exception_in;
output reg [31:0] dout;
output reg [7:0] exception;

reg [31:0] dm [1023:0]; // 1024 * 4 = 4096

integer i;

initial begin
    for(i = 0; i < 1024; i = i + 1) dm[i] <= 0;
end

always @ (*) begin
    dout <= dm[addr];
end

always @ (posedge clk) begin
    if(rst) exception <= `TRAP_STALL;
    else if(exception_in) exception <= exception_in;
    else begin
        if(we) dm[addr] <= din;
        exception <= 0;
    end
end

endmodule
