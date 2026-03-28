`timescale 1ns/1ps

module top_with_ai #(parameter N=4, WIDTH=8)(
    input  wire clk,
    input  wire rst,
    input  wire uart_rx,
    output wire uart_tx,
    output wire [3:0] led   // ✅ ADDED LEDs
);

    // =========================================================
    // INTERNAL DATA (NOW DYNAMIC)
    // =========================================================
    reg signed [N*N*WIDTH-1:0] A_flat = 0;
    reg signed [N*N*WIDTH-1:0] B_flat = 0;

    wire signed [N*N*WIDTH-1:0] result_flat;
    wire [31:0] total_mac;
    wire [31:0] total_skip;

    // =========================================================
    // PREVENT OPTIMIZATION (MAKE DATA CHANGE)
    // =========================================================
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            A_flat <= 0;
            B_flat <= 0;
        end else begin
            A_flat <= A_flat + 1;   // ✅ changing data
            B_flat <= B_flat + 2;
        end
    end

    // =========================================================
    // AI SKIP LOGIC
    // =========================================================
    wire [N*N-1:0] skip_matrix;
    wire [N*N-1:0] mac_flags;
    wire [N*N-1:0] skip_flags;

    genvar i, j;
    generate
        for (i = 0; i < N; i = i + 1) begin : row_gen
            for (j = 0; j < N; j = j + 1) begin : col_gen

                localparam IDX       = i*N + j;
                localparam BIT_START = IDX * WIDTH;

                ai_skip_lut AI_inst (
                    .a    (A_flat[BIT_START +: 4]),
                    .b    (B_flat[BIT_START +: 4]),
                    .skip (skip_matrix[IDX])
                );

            end
        end
    endgenerate

    // =========================================================
    // SYSTOLIC ARRAY
    // =========================================================
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

    // =========================================================
    // PERFORMANCE COUNTERS
    // =========================================================
    wire [4:0] mac_this_cycle  =
          mac_flags[0]  + mac_flags[1]  + mac_flags[2]  + mac_flags[3]
        + mac_flags[4]  + mac_flags[5]  + mac_flags[6]  + mac_flags[7]
        + mac_flags[8]  + mac_flags[9]  + mac_flags[10] + mac_flags[11]
        + mac_flags[12] + mac_flags[13] + mac_flags[14] + mac_flags[15];

    wire [4:0] skip_this_cycle =
          skip_flags[0]  + skip_flags[1]  + skip_flags[2]  + skip_flags[3]
        + skip_flags[4]  + skip_flags[5]  + skip_flags[6]  + skip_flags[7]
        + skip_flags[8]  + skip_flags[9]  + skip_flags[10] + skip_flags[11]
        + skip_flags[12] + skip_flags[13] + skip_flags[14] + skip_flags[15];

    reg [31:0] total_mac_reg  = 0;
    reg [31:0] total_skip_reg = 0;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            total_mac_reg  <= 0;
            total_skip_reg <= 0;
        end else begin
            total_mac_reg  <= total_mac_reg  + mac_this_cycle;
            total_skip_reg <= total_skip_reg + skip_this_cycle;
        end
    end

    assign total_mac  = total_mac_reg;
    assign total_skip = total_skip_reg;

    // =========================================================
    // OUTPUT CONNECTIONS (CRITICAL FIX)
    // =========================================================

    // UART loopback (kept)
    assign uart_tx = uart_rx;

    // LEDs show activity (prevents optimization)
    assign led[0] = |result_flat;     // result activity
    assign led[1] = |total_mac;       // MAC activity
    assign led[2] = |total_skip;      // skip activity
    assign led[3] = clk;              // clock visible on LED

endmodule