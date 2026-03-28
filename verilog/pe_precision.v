// ============================================================
// pe_precision.v
// Place in: Desktop\MyFPGAProject\verilog\
// Processing Element with adaptive precision AND skip logic
// ============================================================
`timescale 1ns/1ps

module pe_precision (
    input             clk,
    input             rst,
    input      [7:0]  a_in,           // activation input
    input      [7:0]  w_in,           // weight input
    input             precision_mode, // 0 = 8-bit   1 = 4-bit
    input             skip_in,        // 1 = skip this operation

    output reg [15:0] sum,            // accumulated result
    output reg        mac_count,      // 1 when MAC executed
    output reg        skip_count,     // 1 when skipped
    output reg        prec4_count     // 1 when 4-bit used
);

    // Precision selection — combinational
    // 8-bit mode: use full a_in and w_in
    // 4-bit mode: zero-pad upper bits, use lower 4 bits only
    wire [7:0] a_eff = precision_mode ?
                       {4'b0000, a_in[3:0]} : a_in;
    wire [7:0] w_eff = precision_mode ?
                       {4'b0000, w_in[3:0]} : w_in;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sum        <= 16'd0;
            mac_count  <= 1'b0;
            skip_count <= 1'b0;
            prec4_count <= 1'b0;
        end
        else begin
            // Reset event flags each cycle
            mac_count   <= 1'b0;
            skip_count  <= 1'b0;
            prec4_count <= 1'b0;

            if (skip_in) begin
                // AI LUT says skip — bypass multiply entirely
                skip_count <= 1'b1;
                // sum is NOT updated — holds previous value
            end
            else begin
                // Compute with selected precision
                sum <= sum + a_eff * w_eff;
                mac_count <= 1'b1;

                // Track if 4-bit precision was used
                if (precision_mode)
                    prec4_count <= 1'b1;
            end
        end
    end

endmodule
