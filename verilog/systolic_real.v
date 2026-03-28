// ============================================================
// systolic_real.v — 4x4 Real Systolic Array
// Exactly like Google TPU weight-stationary systolic array
//
// A values feed from LEFT EDGE, flow RIGHT each cycle
// B values feed from TOP EDGE, flow DOWN each cycle
// C[i][j] accumulates dot product at PE[i][j]
// ============================================================
`timescale 1ns/1ps

module systolic_real #(
    parameter N     = 4,
    parameter WIDTH = 8
)(
    input                          clk,
    input                          rst,

    // A inputs — one per ROW, fed from left edge
    input  signed [WIDTH-1:0]      a_row0,
    input  signed [WIDTH-1:0]      a_row1,
    input  signed [WIDTH-1:0]      a_row2,
    input  signed [WIDTH-1:0]      a_row3,

    // B inputs — one per COLUMN, fed from top edge
    input  signed [WIDTH-1:0]      b_col0,
    input  signed [WIDTH-1:0]      b_col1,
    input  signed [WIDTH-1:0]      b_col2,
    input  signed [WIDTH-1:0]      b_col3,

    // C outputs — accumulated result at each PE
    output signed [2*WIDTH:0]      c00, c01, c02, c03,
    output signed [2*WIDTH:0]      c10, c11, c12, c13,
    output signed [2*WIDTH:0]      c20, c21, c22, c23,
    output signed [2*WIDTH:0]      c30, c31, c32, c33
);

    // Internal A wires — horizontal connections
    wire signed [WIDTH-1:0] a00_01, a01_02, a02_03;
    wire signed [WIDTH-1:0] a10_11, a11_12, a12_13;
    wire signed [WIDTH-1:0] a20_21, a21_22, a22_23;
    wire signed [WIDTH-1:0] a30_31, a31_32, a32_33;

    // Internal B wires — vertical connections
    wire signed [WIDTH-1:0] b00_10, b01_11, b02_12, b03_13;
    wire signed [WIDTH-1:0] b10_20, b11_21, b12_22, b13_23;
    wire signed [WIDTH-1:0] b20_30, b21_31, b22_32, b23_33;

    // ── ROW 0 ──────────────────────────────────────────────
    pe_real #(WIDTH) PE00 (.clk(clk),.rst(rst),
        .a_in(a_row0),   .b_in(b_col0),
        .a_out(a00_01),  .b_out(b00_10), .acc(c00));

    pe_real #(WIDTH) PE01 (.clk(clk),.rst(rst),
        .a_in(a00_01),   .b_in(b_col1),
        .a_out(a01_02),  .b_out(b01_11), .acc(c01));

    pe_real #(WIDTH) PE02 (.clk(clk),.rst(rst),
        .a_in(a01_02),   .b_in(b_col2),
        .a_out(a02_03),  .b_out(b02_12), .acc(c02));

    pe_real #(WIDTH) PE03 (.clk(clk),.rst(rst),
        .a_in(a02_03),   .b_in(b_col3),
        .a_out(),        .b_out(b03_13), .acc(c03));

    // ── ROW 1 ──────────────────────────────────────────────
    pe_real #(WIDTH) PE10 (.clk(clk),.rst(rst),
        .a_in(a_row1),   .b_in(b00_10),
        .a_out(a10_11),  .b_out(b10_20), .acc(c10));

    pe_real #(WIDTH) PE11 (.clk(clk),.rst(rst),
        .a_in(a10_11),   .b_in(b01_11),
        .a_out(a11_12),  .b_out(b11_21), .acc(c11));

    pe_real #(WIDTH) PE12 (.clk(clk),.rst(rst),
        .a_in(a11_12),   .b_in(b02_12),
        .a_out(a12_13),  .b_out(b12_22), .acc(c12));

    pe_real #(WIDTH) PE13 (.clk(clk),.rst(rst),
        .a_in(a12_13),   .b_in(b03_13),
        .a_out(),        .b_out(b13_23), .acc(c13));

    // ── ROW 2 ──────────────────────────────────────────────
    pe_real #(WIDTH) PE20 (.clk(clk),.rst(rst),
        .a_in(a_row2),   .b_in(b10_20),
        .a_out(a20_21),  .b_out(b20_30), .acc(c20));

    pe_real #(WIDTH) PE21 (.clk(clk),.rst(rst),
        .a_in(a20_21),   .b_in(b11_21),
        .a_out(a21_22),  .b_out(b21_31), .acc(c21));

    pe_real #(WIDTH) PE22 (.clk(clk),.rst(rst),
        .a_in(a21_22),   .b_in(b12_22),
        .a_out(a22_23),  .b_out(b22_32), .acc(c22));

    pe_real #(WIDTH) PE23 (.clk(clk),.rst(rst),
        .a_in(a22_23),   .b_in(b13_23),
        .a_out(),        .b_out(b23_33), .acc(c23));

    // ── ROW 3 ──────────────────────────────────────────────
    pe_real #(WIDTH) PE30 (.clk(clk),.rst(rst),
        .a_in(a_row3),   .b_in(b20_30),
        .a_out(a30_31),  .b_out(), .acc(c30));

    pe_real #(WIDTH) PE31 (.clk(clk),.rst(rst),
        .a_in(a30_31),   .b_in(b21_31),
        .a_out(a31_32),  .b_out(), .acc(c31));

    pe_real #(WIDTH) PE32 (.clk(clk),.rst(rst),
        .a_in(a31_32),   .b_in(b22_32),
        .a_out(a32_33),  .b_out(), .acc(c32));

    pe_real #(WIDTH) PE33 (.clk(clk),.rst(rst),
        .a_in(a32_33),   .b_in(b23_33),
        .a_out(),        .b_out(), .acc(c33));

endmodule