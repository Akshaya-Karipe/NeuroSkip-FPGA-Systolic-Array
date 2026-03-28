// ============================================================
// ai_skip_lut_runtime.v
// Place in: Desktop\MyFPGAProject\verilog\
//
// Same as ai_skip_lut.v BUT adds a write port
// so the LUT can be updated at runtime without
// changing any hardware — just write new values
// ============================================================
`timescale 1ns/1ps

module ai_skip_lut_runtime (
    input        clk,
    input        rst,

    // ── Read port (same as original ai_skip_lut) ──
    input  [3:0] a,          // operand A (4-bit)
    input  [3:0] b,          // operand B (4-bit)
    output       skip,        // 1=skip this operation

    // ── Write port (NEW — for runtime update) ──
    input        we,          // write enable: 1=write this cycle
    input  [7:0] write_addr,  // which LUT entry to update (0-255)
    input        write_data   // new skip decision (0 or 1)
);

    // 256-entry LUT — 1 bit per entry
    reg lut_mem [0:255];

    // Load initial values from file (same as original)
    initial begin
        $readmemb("C:/Users/aksha/Desktop/MyFPGAProject/mem/ai_lut.mem",
                  lut_mem);
    end

    // Write port — updates one entry per clock when we=1
    always @(posedge clk) begin
        if (we)
            lut_mem[write_addr] <= write_data;
    end

    // Read port — combinational (same as original)
    assign skip = lut_mem[{a, b}];

endmodule