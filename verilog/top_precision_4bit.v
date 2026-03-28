// top_precision_4bit.v — wrapper for synthesis with 4-bit forced
`timescale 1ns/1ps
module top_precision_4bit #(parameter N=4, WIDTH=8)(
    input  clk,
    input  rst,
    input  signed [N*N*WIDTH-1:0] A_flat,
    input  signed [N*N*WIDTH-1:0] B_flat,
    output signed [N*N*WIDTH-1:0] result_flat,
    output [31:0] total_mac,
    output [31:0] total_skip,
    output [31:0] total_prec4
);
    top_precision #(N, WIDTH) inst (
        .clk(clk), .rst(rst),
        .precision_mode(1'b1),  // FORCED 4-bit
        .A_flat(A_flat), .B_flat(B_flat),
        .result_flat(result_flat),
        .total_mac(total_mac),
        .total_skip(total_skip),
        .total_prec4(total_prec4)
    );
endmodule