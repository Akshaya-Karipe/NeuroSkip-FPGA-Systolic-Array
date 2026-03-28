// ============================================================
// pe.v  — place in: MyFPGAProject/verilog/
// Processing Element: multiply-accumulate with skip
// FIX: Added mac_count and skip_count outputs for measurement
// ============================================================
`timescale 1ns/1ps

module pe #(parameter WIDTH = 8)(
    input  signed [WIDTH-1:0] a,
    input  signed [WIDTH-1:0] b,
    input                     clk,
    input                     rst,
    input                     skip,       // 1 = skip this multiply

    output reg signed [WIDTH-1:0] result, // multiply result
    output reg                    mac_done,  // 1 when MAC executed
    output reg                    skip_done  // 1 when skip executed
);

always @(posedge clk or posedge rst) begin
    if (rst) begin
        result    <= 0;
        mac_done  <= 0;
        skip_done <= 0;
    end
    else if (skip) begin
        result    <= result;  // hold previous value
        mac_done  <= 0;
        skip_done <= 1;       // count this as a skip event
    end
    else begin
        result    <= a * b;   // compute multiply
        mac_done  <= 1;       // count this as a MAC event
        skip_done <= 0;
    end
end

endmodule