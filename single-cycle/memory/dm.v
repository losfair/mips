module dm_4k(
    addr, // Address In
    din, // Data In
    we, // Write Enable
    wbyte_enable, // Write Byte Enable
    clk, // Asynchronous clock?
    dout // Data Out
);

input wire [11:2] addr;
input wire [31:0] din;
input wire clk, we;
input wire [3:0] wbyte_enable;
output reg [31:0] dout;

reg [31:0] dm [1023:0]; // 1024 * 4 = 4096

integer i;

initial begin
    for(i = 0; i < 1024; i = i + 1) dm[i] <= 0;
end

always @ (*) begin
    dout <= dm[addr];
end

always @ (posedge clk) begin
    if(we) begin
        if(wbyte_enable[0]) dm[addr][7:0] <= din[7:0];
        if(wbyte_enable[1]) dm[addr][15:8] <= din[15:8];
        if(wbyte_enable[2]) dm[addr][23:16] <= din[23:16];
        if(wbyte_enable[3]) dm[addr][31:24] <= din[31:24];
    end
end

endmodule
