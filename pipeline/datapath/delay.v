module delay(clk, in, out);

parameter WIDTH = 1;

input wire clk;
input wire [WIDTH-1 : 0] in;
output reg [WIDTH-1 : 0] out;

always @ (posedge clk) begin
    out <= in;
end

endmodule
