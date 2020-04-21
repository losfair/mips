module testbench();

reg clk;
reg rst;

mips mips_1(clk, rst);

initial begin
    clk <= 0;
    rst <= 1;
end

always begin
    #5 clk <= 1;
    #5 clk <= 0;
    rst <= 0;
end

endmodule