// ============================================================
// pe_real.v — Real Systolic Processing Element
// Like Google TPU and NVIDIA accelerator PEs
//
// Every clock cycle:
//   1. Multiply a_in × b_in
//   2. Add to accumulated sum
//   3. Pass a_in to right neighbor
//   4. Pass b_in to bottom neighbor
// ============================================================
`timescale 1ns/1ps

module pe_real #(parameter WIDTH = 8)(
    input                          clk,
    input                          rst,
    input  signed [WIDTH-1:0]      a_in,   // from left
    input  signed [WIDTH-1:0]      b_in,   // from top
    output reg signed [WIDTH-1:0]  a_out,  // to right
    output reg signed [WIDTH-1:0]  b_out,  // to bottom
    output reg signed [2*WIDTH:0]  acc     // accumulated result
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            acc   <= 0;
            a_out <= 0;
            b_out <= 0;
        end
        else begin
            acc   <= acc + (a_in * b_in); // accumulate
            a_out <= a_in;                // pass right
            b_out <= b_in;                // pass down
        end
    end

endmodule