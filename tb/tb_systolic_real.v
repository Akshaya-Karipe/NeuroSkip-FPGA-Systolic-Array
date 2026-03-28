// ============================================================
// tb_systolic_real.v
// Testbench for real systolic array
//
// CRITICAL: Data must be fed DIAGONALLY
// Row i starts feeding at cycle i (delayed by i cycles)
// Column j starts feeding at cycle j (delayed by j cycles)
//
// This is the WAVEFRONT SCHEDULING used in Google TPU
// ============================================================
`timescale 1ns/1ps

module tb_systolic_real;

    parameter WIDTH = 8;
    parameter N     = 4;

    reg clk, rst;

    // A row inputs
    reg signed [WIDTH-1:0] a_row0, a_row1, a_row2, a_row3;
    // B column inputs
    reg signed [WIDTH-1:0] b_col0, b_col1, b_col2, b_col3;

    // C outputs (wires from DUT)
    wire signed [2*WIDTH:0] c00, c01, c02, c03;
    wire signed [2*WIDTH:0] c10, c11, c12, c13;
    wire signed [2*WIDTH:0] c20, c21, c22, c23;
    wire signed [2*WIDTH:0] c30, c31, c32, c33;

    // ── 2D arrays for waveform display (same format as A and B) ──
    reg signed [WIDTH-1:0]    A [0:3][0:3];
    reg signed [WIDTH-1:0]    B [0:3][0:3];
    reg signed [2*WIDTH:0]    C [0:3][0:3];   // <<< NEW: C matrix for waveform

    // Instantiate DUT
    systolic_real #(N, WIDTH) DUT (
        .clk(clk), .rst(rst),
        .a_row0(a_row0), .a_row1(a_row1),
        .a_row2(a_row2), .a_row3(a_row3),
        .b_col0(b_col0), .b_col1(b_col1),
        .b_col2(b_col2), .b_col3(b_col3),
        .c00(c00),.c01(c01),.c02(c02),.c03(c03),
        .c10(c10),.c11(c11),.c12(c12),.c13(c13),
        .c20(c20),.c21(c21),.c22(c22),.c23(c23),
        .c30(c30),.c31(c31),.c32(c32),.c33(c33)
    );

    // ── Clock ────────────────────────────────────────────────
    always #5 clk = ~clk;

    // ── Continuously mirror wire outputs into C array ────────
    // This makes C[0:3][0:3] visible as a grouped 2D array
    // in Vivado waveform - same display format as A and B
    always @(*) begin
        C[0][0] = c00; C[0][1] = c01; C[0][2] = c02; C[0][3] = c03;
        C[1][0] = c10; C[1][1] = c11; C[1][2] = c12; C[1][3] = c13;
        C[2][0] = c20; C[2][1] = c21; C[2][2] = c22; C[2][3] = c23;
        C[3][0] = c30; C[3][1] = c31; C[3][2] = c32; C[3][3] = c33;
    end

    // ── Matrix definitions ───────────────────────────────────
    // A = | 4  6  3  9 |      B = | 2  3  9  7 |
    //     | 2  3  1  6 |          | 5  4  6  2 |
    //     | 9  7  3  5 |          | 3  6  6  4 |
    //     | 4  2  6  6 |          | 1  3  2  8 |

    initial begin
        // Define A matrix
        A[0][0]=4; A[0][1]=6; A[0][2]=3; A[0][3]=9;
        A[1][0]=2; A[1][1]=3; A[1][2]=1; A[1][3]=6;
        A[2][0]=9; A[2][1]=7; A[2][2]=3; A[2][3]=5;
        A[3][0]=4; A[3][1]=2; A[3][2]=6; A[3][3]=6;

        // Define B matrix
        B[0][0]=2; B[0][1]=3; B[0][2]=9; B[0][3]=7;
        B[1][0]=5; B[1][1]=4; B[1][2]=6; B[1][3]=2;
        B[2][0]=3; B[2][1]=6; B[2][2]=6; B[2][3]=4;
        B[3][0]=1; B[3][1]=3; B[3][2]=2; B[3][3]=8;
    end

    // ── Stimulus ─────────────────────────────────────────────
    initial begin
        clk    = 0; rst = 1;
        a_row0 = 0; a_row1 = 0; a_row2 = 0; a_row3 = 0;
        b_col0 = 0; b_col1 = 0; b_col2 = 0; b_col3 = 0;

        #15 rst = 0;

        $display("=== REAL SYSTOLIC ARRAY - WAVEFRONT FEEDING ===");
        $display("Matrix A:");
        $display("  | 4 6 3 9 |");
        $display("  | 2 3 1 6 |");
        $display("  | 9 7 3 5 |");
        $display("  | 4 2 6 6 |");
        $display("Matrix B:");
        $display("  | 2 3 9 7 |");
        $display("  | 5 4 6 2 |");
        $display("  | 3 6 6 4 |");
        $display("  | 1 3 2 8 |");
        $display("");

        // ── Wavefront diagonal feed ───────────────────────────
        // Row i of A is delayed by i cycles
        // Col j of B is delayed by j cycles
        // Ensures correct pairs meet at the right PE

        // Cycle 1: Row0[0], Col0[0]
        @(posedge clk); #1;
        a_row0 = A[0][0]; b_col0 = B[0][0];
        a_row1 = 0;       b_col1 = 0;
        a_row2 = 0;       b_col2 = 0;
        a_row3 = 0;       b_col3 = 0;

        // Cycle 2: Row0[1], Row1[0], Col0[1], Col1[0]
        @(posedge clk); #1;
        a_row0 = A[0][1]; b_col0 = B[1][0];
        a_row1 = A[1][0]; b_col1 = B[0][1];
        a_row2 = 0;       b_col2 = 0;
        a_row3 = 0;       b_col3 = 0;

        // Cycle 3
        @(posedge clk); #1;
        a_row0 = A[0][2]; b_col0 = B[2][0];
        a_row1 = A[1][1]; b_col1 = B[1][1];
        a_row2 = A[2][0]; b_col2 = B[0][2];
        a_row3 = 0;       b_col3 = 0;

        // Cycle 4
        @(posedge clk); #1;
        a_row0 = A[0][3]; b_col0 = B[3][0];
        a_row1 = A[1][2]; b_col1 = B[2][1];
        a_row2 = A[2][1]; b_col2 = B[1][2];
        a_row3 = A[3][0]; b_col3 = B[0][3];

        // Cycle 5
        @(posedge clk); #1;
        a_row0 = 0;       b_col0 = 0;
        a_row1 = A[1][3]; b_col1 = B[3][1];
        a_row2 = A[2][2]; b_col2 = B[2][2];
        a_row3 = A[3][1]; b_col3 = B[1][3];

        // Cycle 6
        @(posedge clk); #1;
        a_row0 = 0;       b_col0 = 0;
        a_row1 = 0;       b_col1 = 0;
        a_row2 = A[2][3]; b_col2 = B[3][2];
        a_row3 = A[3][2]; b_col3 = B[2][3];

        // Cycle 7 - last elements
        @(posedge clk); #1;
        a_row0 = 0;        b_col0 = 0;
        a_row1 = 0;        b_col1 = 0;
        a_row2 = 0;        b_col2 = 0;
        a_row3 = A[3][3];  b_col3 = B[3][3];

        // Zero out inputs after feeding
        @(posedge clk); #1;
        a_row0 = 0; a_row1 = 0; a_row2 = 0; a_row3 = 0;
        b_col0 = 0; b_col1 = 0; b_col2 = 0; b_col3 = 0;

        // Wait for pipeline to fully drain (N-1 = 3 extra cycles)
        @(posedge clk); #1;
        @(posedge clk); #1;
        @(posedge clk); #1;

        // ── Display results ───────────────────────────────────
        $display("=== RESULTS: C = A x B ===");
        $display("C[0][0]=%0d  C[0][1]=%0d  C[0][2]=%0d  C[0][3]=%0d",
                  c00, c01, c02, c03);
        $display("C[1][0]=%0d  C[1][1]=%0d  C[1][2]=%0d  C[1][3]=%0d",
                  c10, c11, c12, c13);
        $display("C[2][0]=%0d  C[2][1]=%0d  C[2][2]=%0d  C[2][3]=%0d",
                  c20, c21, c22, c23);
        $display("C[3][0]=%0d  C[3][1]=%0d  C[3][2]=%0d  C[3][3]=%0d",
                  c30, c31, c32, c33);

        $display("");
        $display("=== EXPECTED (manual A x B) ===");
        $display("C[0] = [68, 111, 96, 119]");
        $display("C[1] = [31,  54,  45,  73]");
        $display("C[2] = [73, 108, 147, 141]");
        $display("C[3] = [44,  66,  84,  96]");

        $finish;
    end

endmodule