`timescale 1ns/1ps
module threshold_skip(
    input [3:0] a,
    input [3:0] b,
    output      skip
);
    wire [7:0] product;
    assign product = a * b;
    assign skip = (product < 8'd10) ? 1'b1 : 1'b0;
endmodule
