module im_4k(
    addr, // Address In
    dout // Data Out

    // Purely combinational... No clock?
);

input wire [11:2] addr;
output wire [31:0] dout;

reg [31:0] dm [1023:0]; // 1024 * 4 = 4096

initial begin
    $readmemh("code.txt", dm);
end

assign dout = dm[addr];

endmodule
