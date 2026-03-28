// ============================================================
// top_with_ai.v  — place in: MyFPGAProject/verilog/
// Top module: connects AI LUT + Systolic Array
//
// FIX APPLIED:
//   Added generate block labels (required by some Vivado versions)
//   Uses flat port style matching systolic_array.v
//   Exposes total_mac and total_skip for testbench measurement
// ============================================================
`timescale 1ns/1ps

module top_with_ai #(parameter N=4, WIDTH=8)(
    input  clk,
    input  rst,

    input  signed [N*N*WIDTH-1:0] A_flat,
    input  signed [N*N*WIDTH-1:0] B_flat,

    output signed [N*N*WIDTH-1:0] result_flat,
    output reg    [31:0]          total_mac,
    output reg    [31:0]          total_skip
);

    // Skip decisions from AI LUT (one per PE)
    wire [N*N-1:0] skip_matrix;

    // MAC and skip event flags from array
    wire [N*N-1:0] mac_flags;
    wire [N*N-1:0] skip_flags;

    // ── Instantiate one AI LUT per PE ──
    genvar i, j;
    generate
        for (i = 0; i < N; i = i + 1) begin : row_gen
            for (j = 0; j < N; j = j + 1) begin : col_gen

                localparam IDX       = i*N + j;
                localparam BIT_START = IDX * WIDTH;

                // Feed lower 4 bits of each operand into the AI LUT
                ai_skip_lut AI_inst (
                    .a    (A_flat[BIT_START   +: 4]),  // lower 4 bits of A[i][j]
                    .b    (B_flat[BIT_START   +: 4]),  // lower 4 bits of B[i][j]
                    .skip (skip_matrix[IDX])
                );

            end
        end
    endgenerate

    // ── Instantiate systolic array ──
    systolic_array #(N, WIDTH) SA_inst (
        .clk         (clk),
        .rst         (rst),
        .A_flat      (A_flat),
        .B_flat      (B_flat),
        .skip_matrix (skip_matrix),
        .result_flat (result_flat),
        .mac_flags   (mac_flags),
        .skip_flags  (skip_flags)
    );

    // ── Count total MAC and SKIP events across all 16 PEs ──
    // Sum all 16 flags in one expression (no for-loop bug)
    wire [4:0] mac_this_cycle  = mac_flags[0]  + mac_flags[1]  + mac_flags[2]  + mac_flags[3]
                               + mac_flags[4]  + mac_flags[5]  + mac_flags[6]  + mac_flags[7]
                               + mac_flags[8]  + mac_flags[9]  + mac_flags[10] + mac_flags[11]
                               + mac_flags[12] + mac_flags[13] + mac_flags[14] + mac_flags[15];

    wire [4:0] skip_this_cycle = skip_flags[0]  + skip_flags[1]  + skip_flags[2]  + skip_flags[3]
                               + skip_flags[4]  + skip_flags[5]  + skip_flags[6]  + skip_flags[7]
                               + skip_flags[8]  + skip_flags[9]  + skip_flags[10] + skip_flags[11]
                               + skip_flags[12] + skip_flags[13] + skip_flags[14] + skip_flags[15];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            total_mac  <= 32'd0;
            total_skip <= 32'd0;
        end else begin
            total_mac  <= total_mac  + mac_this_cycle;
            total_skip <= total_skip + skip_this_cycle;
        end
    end

endmodule