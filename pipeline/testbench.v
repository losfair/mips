module testbench();

reg clk;
reg rst;
wire halted;

mips mips_1(clk, rst, halted);

reg first;

initial begin
    clk <= 0;
    rst <= 1;
end

always begin
    #5 clk <= 1;
    #5 clk <= 0;
    rst <= 0;
    if(halted) $finish();
end

endmodule