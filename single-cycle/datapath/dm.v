module dm_4k(
    addr, // Address In
    din, // Data In
    we, // Write Enable
    clk, // Asynchronous clock?
    dout // Data Out
);

input wire [11:2] addr;
input wire [31:0] din;
input wire clk, we;
output reg [31:0] dout;

reg [31:0] dm [1023:0]; // 1024 * 4 = 4096

always @ (posedge clk) begin
    if(we) begin
        dm[addr] <= din;
    end else begin
        dout <= dm[addr];
    end
end

endmodule
