// ============================================================
// ai_skip_lut_8bit.v
// Hierarchical LUT for 8-bit inputs
// Uses two 256-entry LUTs instead of one 65536-entry LUT
// ============================================================
`timescale 1ns/1ps

module ai_skip_lut_8bit (
    input  [7:0] a,        // 8-bit operand A
    input  [7:0] b,        // 8-bit operand B
    output       skip       // 1=skip, 0=compute
);

    // Split into high and low nibbles
    wire [3:0] a_high = a[7:4];
    wire [3:0] a_low  = a[3:0];
    wire [3:0] b_high = b[7:4];
    wire [3:0] b_low  = b[3:0];

    // LUT 1: skip decision for HIGH nibbles
    // If high nibbles already produce large product → compute
    reg lut_high [0:255];
    initial $readmemb("ai_lut_high.mem", lut_high);
    wire skip_high = lut_high[{a_high, b_high}];

    // LUT 2: skip decision for LOW nibbles
    // Same 256-entry LUT as your original design
    reg lut_low [0:255];
    initial $readmemb("ai_lut.mem", lut_low);
    wire skip_low = lut_low[{a_low, b_low}];

    // Combined skip decision:
    // Skip only if BOTH high and low parts suggest skip
    // This is conservative — avoids false skips
    assign skip = skip_high & skip_low;

endmodule