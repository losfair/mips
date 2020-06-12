module mread(
    addrtail,
    width,
    zext,
    inval,
    outval
);

input wire [1:0] addrtail;
input wire [1:0] width;
input wire zext;
input wire [31:0] inval;
output reg [31:0] outval;

wire [3:0] addrtail_width;
assign addrtail_width = {addrtail, width};

always @ (*) begin
    case (addrtail_width)
        // addr mod 4 == 0, width 1, 2, 4
        4'b00_01: begin
            if(zext) outval[31:8] <= 24'b0;
            else outval[31:8] <= {24{inval[7]}};
            outval[7:0] <= inval[7:0];
        end
        4'b00_11: begin
            outval <= inval;
        end

        // addr mod 4 == 1, width 1
        4'b01_01: begin
            if(zext) outval[31:8] <= 24'b0;
            else outval[31:8] <= {24{inval[15]}};
            outval[7:0] <= inval[15:8];
        end

        // addr mod 4 == 2, width 1
        4'b10_01: begin
            if(zext) outval[31:8] <= 24'b0;
            else outval[31:8] <= {24{inval[23]}};
            outval[7:0] <= inval[23:16];
        end

        // addr mod 4 == 3, width 1
        4'b11_01: begin
            if(zext) outval[31:8] <= 24'b0;
            else outval[31:8] <= {24{inval[31]}};
            outval[7:0] <= inval[31:24];
        end

        default: outval <= 0;
    endcase
end

endmodule

module mwrite(
    addrtail,
    width,
    inval,
    out_wbyte_enable,
    outval
);

input wire [1:0] addrtail;
input wire [1:0] width;
input wire [31:0] inval;
output reg [3:0] out_wbyte_enable;
output reg [31:0] outval;

wire [3:0] addrtail_width;
assign addrtail_width = {addrtail, width};

always @ (*) begin
    outval <= 32'b0;

    case (addrtail_width)
        // addr mod 4 == 0, width 1, 4
        4'b00_01: begin
            outval[7:0] <= inval[7:0];
            out_wbyte_enable <= 4'b0001;
        end
        4'b00_11: begin
            outval <= inval;
            out_wbyte_enable <= 4'b1111;
        end

        // addr mod 4 == 1, width 1
        4'b01_01: begin
            outval[15:8] <= inval[7:0];
            out_wbyte_enable <= 4'b0010;
        end

        // addr mod 4 == 2, width 1
        4'b10_01: begin
            outval[23:16] <= inval[7:0];
            out_wbyte_enable <= 4'b0100;
        end

        // addr mod 4 == 3, width 1
        4'b11_01: begin
            outval[31:24] <= inval[7:0];
            out_wbyte_enable <= 4'b1000;
        end

        default: begin
            out_wbyte_enable <= 4'b0000;
        end
    endcase
end

endmodule