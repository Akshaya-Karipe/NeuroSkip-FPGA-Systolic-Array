// ============================================================
// tb_8x8.v — Testbench for 8x8 systolic array
// Place in: MyFPGAProject/tb/
// ============================================================
`timescale 1ns/1ps

module tb_8x8;

    parameter N     = 8;
    parameter WIDTH = 8;

    reg  clk, rst;
    reg  signed [N*N*WIDTH-1:0] A_flat;
    reg  signed [N*N*WIDTH-1:0] B_flat;

    wire signed [N*N*WIDTH-1:0] result_flat;
    wire [31:0] total_mac;
    wire [31:0] total_skip;

    top_with_ai #(N, WIDTH) DUT (
        .clk(clk), .rst(rst),
        .A_flat(A_flat), .B_flat(B_flat),
        .result_flat(result_flat),
        .total_mac(total_mac),
        .total_skip(total_skip)
    );

    always #5 clk = ~clk;

    // Task to set A value at position [row][col]
    task set_a;
        input integer row, col;
        input signed [WIDTH-1:0] val;
        begin
            A_flat[(row*N + col)*WIDTH +: WIDTH] = val;
        end
    endtask

    // Task to set B value at position [row][col]
    task set_b;
        input integer row, col;
        input signed [WIDTH-1:0] val;
        begin
            B_flat[(row*N + col)*WIDTH +: WIDTH] = val;
        end
    endtask

    integer r, c;

    initial begin
        clk = 0; rst = 1;
        A_flat = 0; B_flat = 0;
        #15 rst = 0;

        // ════════════════════════════════════════════
        // SCENARIO 1: Baseline — all non-zero (8x8)
        // 64 PEs all computing every cycle
        // ════════════════════════════════════════════
        for (r = 0; r < N; r = r+1)
            for (c = 0; c < N; c = c+1) begin
                set_a(r, c, 5 + r + c);  // values 5-21, all non-zero
                set_b(r, c, 3 + r + c);  // values 3-19, all non-zero
            end

        #100;

        $display("=== 8x8 SCENARIO 1: Baseline (all non-zero) ===");
        $display("    64 PEs active every cycle");
        $display("    MAC  = %0d", total_mac);
        $display("    SKIP = %0d", total_skip);

        // ════════════════════════════════════════════
        // SCENARIO 2: 50% sparse (32 of 64 zeros)
        // Half rows have zero activations
        // ════════════════════════════════════════════
        rst = 1; #15 rst = 0;

        for (r = 0; r < N; r = r+1)
            for (c = 0; c < N; c = c+1) begin
                if (r % 2 == 0)
                    set_a(r, c, 0);       // even rows: zero
                else
                    set_a(r, c, 5 + c);   // odd rows: non-zero
                set_b(r, c, 3 + c);
            end

        #100;

        $display("\n=== 8x8 SCENARIO 2: Sparse (32 of 64 zero) ===");
        $display("    MAC  = %0d", total_mac);
        $display("    SKIP = %0d", total_skip);

        // ════════════════════════════════════════════
        // SCENARIO 3: High sparse (48 of 64 zeros)
        // Three quarters of rows zero
        // ════════════════════════════════════════════
        rst = 1; #15 rst = 0;

        for (r = 0; r < N; r = r+1)
            for (c = 0; c < N; c = c+1) begin
                if (r < 6)
                    set_a(r, c, 0);       // rows 0-5: zero
                else
                    set_a(r, c, 8 + c);   // rows 6-7: non-zero
                set_b(r, c, 4 + c);
            end

        #100;

        $display("\n=== 8x8 SCENARIO 3: High Sparse (48 of 64 zero) ===");
        $display("    MAC  = %0d", total_mac);
        $display("    SKIP = %0d", total_skip);

        $display("\n====================================");
        $display("8x8 ARRAY SUMMARY FOR PAPER");
        $display("====================================");
        $display("Array size: 8x8 = 64 PEs");
        $display("Compare with 4x4 = 16 PEs (4x more PEs)");
        $display("Same skip logic scales automatically");
        $display("====================================");

        $finish;
    end

endmodule