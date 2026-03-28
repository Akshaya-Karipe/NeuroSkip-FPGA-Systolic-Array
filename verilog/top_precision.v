// ============================================================
// top_precision.v
// Place in: Desktop\MyFPGAProject\verilog\
// Top module: connects AI LUT + precision-aware PE array
// precision_mode input controls all 16 PEs simultaneously
// ============================================================
`timescale 1ns/1ps

module top_precision #(parameter N=4, WIDTH=8)(
    input  clk,
    input  rst,
    input  precision_mode,            // 0=8-bit  1=4-bit

    input  signed [N*N*WIDTH-1:0] A_flat,
    input  signed [N*N*WIDTH-1:0] B_flat,

    output signed [N*N*WIDTH-1:0] result_flat,
    output reg    [31:0]          total_mac,
    output reg    [31:0]          total_skip,
    output reg    [31:0]          total_prec4  // counts 4-bit MACs
);

    // Skip decisions from AI LUT
    wire [N*N-1:0] skip_matrix;

    // Event flags from each PE
    wire [N*N-1:0] mac_flags;
    wire [N*N-1:0] skip_flags;
    wire [N*N-1:0] prec4_flags;

    // Partial sum wires
    wire signed [N*N*WIDTH-1:0] sum_flat;

    // ── AI LUT: one per PE ──
    genvar i, j;
    generate
        for (i = 0; i < N; i = i+1) begin : row_gen
            for (j = 0; j < N; j = j+1) begin : col_gen
                localparam IDX   = i*N + j;
                localparam BSTART = IDX * WIDTH;

                ai_skip_lut AI_inst (
                    .a   (A_flat[BSTART   +: 4]),
                    .b   (B_flat[BSTART   +: 4]),
                    .skip(skip_matrix[IDX])
                );

                pe_precision PE_inst (
                    .clk           (clk),
                    .rst           (rst),
                    .a_in          (A_flat[BSTART +: WIDTH]),
                    .w_in          (B_flat[BSTART +: WIDTH]),
                    .precision_mode(precision_mode),
                    .skip_in       (skip_matrix[IDX]),
                    .sum           (sum_flat[BSTART +: WIDTH]),
                    .mac_count     (mac_flags[IDX]),
                    .skip_count    (skip_flags[IDX]),
                    .prec4_count   (prec4_flags[IDX])
                );
            end
        end
    endgenerate

    assign result_flat = sum_flat;

    // ── Sum all 16 PE events per cycle ──
    wire [4:0] mac_this =
        mac_flags[0]+mac_flags[1]+mac_flags[2]+mac_flags[3]+
        mac_flags[4]+mac_flags[5]+mac_flags[6]+mac_flags[7]+
        mac_flags[8]+mac_flags[9]+mac_flags[10]+mac_flags[11]+
        mac_flags[12]+mac_flags[13]+mac_flags[14]+mac_flags[15];

    wire [4:0] skip_this =
        skip_flags[0]+skip_flags[1]+skip_flags[2]+skip_flags[3]+
        skip_flags[4]+skip_flags[5]+skip_flags[6]+skip_flags[7]+
        skip_flags[8]+skip_flags[9]+skip_flags[10]+skip_flags[11]+
        skip_flags[12]+skip_flags[13]+skip_flags[14]+skip_flags[15];

    wire [4:0] prec4_this =
        prec4_flags[0]+prec4_flags[1]+prec4_flags[2]+prec4_flags[3]+
        prec4_flags[4]+prec4_flags[5]+prec4_flags[6]+prec4_flags[7]+
        prec4_flags[8]+prec4_flags[9]+prec4_flags[10]+prec4_flags[11]+
        prec4_flags[12]+prec4_flags[13]+prec4_flags[14]+prec4_flags[15];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            total_mac   <= 32'd0;
            total_skip  <= 32'd0;
            total_prec4 <= 32'd0;
        end
        else begin
            total_mac   <= total_mac   + mac_this;
            total_skip  <= total_skip  + skip_this;
            total_prec4 <= total_prec4 + prec4_this;
        end
    end

endmodule