module mux2(
    selector,
    in0, in1,
    out
);
parameter width = 1;

input wire selector;
input wire [width-1:0] in0, in1;
output reg [width-1:0] out;

always @ (*) begin
    if(selector) out <= in1;
    else out <= in0;
end

endmodule