// ============================================================
// systolic_array.v  — place in: MyFPGAProject/verilog/
// 4x4 systolic array of PEs
//
// FIX APPLIED:
//   Original used SystemVerilog 2D array ports which cause
//   synthesis errors. Changed to flat port style that works
//   in both simulation AND synthesis on Vivado Artix-7.
// ============================================================
`timescale 1ns/1ps

module systolic_array #(parameter N=4, WIDTH=8)(
    input  clk,
    input  rst,

    // Matrix A — flattened: a[i][j] = A_flat[i*N*WIDTH + j*WIDTH +: WIDTH]
    input  signed [N*N*WIDTH-1:0] A_flat,
    input  signed [N*N*WIDTH-1:0] B_flat,
    input         [N*N-1:0]       skip_matrix,

    output signed [N*N*WIDTH-1:0] result_flat,
    output        [N*N-1:0]       mac_flags,
    output        [N*N-1:0]       skip_flags
);

genvar i, j;
generate
    for (i = 0; i < N; i = i + 1) begin : row_loop
        for (j = 0; j < N; j = j + 1) begin : col_loop

            localparam IDX       = i*N + j;
            localparam BIT_START = IDX * WIDTH;

            pe #(WIDTH) PE_inst (
                .a        (A_flat   [BIT_START +: WIDTH]),
                .b        (B_flat   [BIT_START +: WIDTH]),
                .clk      (clk),
                .rst      (rst),
                .skip     (skip_matrix[IDX]),
                .result   (result_flat[BIT_START +: WIDTH]),
                .mac_done (mac_flags[IDX]),
                .skip_done(skip_flags[IDX])
            );

        end
    end
endgenerate

endmodule