// ============================================================
// ai_skip_lut.v  — place in: MyFPGAProject/verilog/
// AI-trained lookup table for skip decisions
//
// FIXES APPLIED:
//   1. Removed absolute path (C:/Users/aksha/...) — was the main bug
//      Now uses just "ai_lut.mem" — Vivado finds it via simulation settings
//   2. Input ports [3:0] match 256-entry LUT correctly
//   3. Index = a*16 + b gives 0..255 for 4-bit inputs
// ============================================================
`timescale 1ns/1ps

module ai_skip_lut(
    input [3:0] a,       // lower 4 bits of operand A (values 0-15)
    input [3:0] b,       // lower 4 bits of operand B (values 0-15)
    output      skip     // 1 = skip multiply, 0 = compute
);

    // 256-entry LUT: index [a*16 + b]
    reg skip_table [0:255];

    initial begin
        // ── IMPORTANT: "ai_lut.mem" must be in Vivado simulation directory ──
        // In Vivado: Simulation Settings → Simulation → add mem folder to path
        // OR copy ai_lut.mem directly to your project folder root
        $readmemb("C:/Users/aksha/Desktop/MyFPGAProject/mem/ai_lut.mem", skip_table);
    end

    assign skip = skip_table[{a, b}];  // {a,b} = a*16+b for 4-bit values

endmodule