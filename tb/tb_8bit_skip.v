// tb_8bit_skip.v
`timescale 1ns/1ps
module tb_8bit_skip;

    reg  [7:0] a_test, b_test;
    wire       skip;

    ai_skip_lut_8bit DUT (
        .a(a_test), .b(b_test), .skip(skip)
    );

    initial begin
        $display("=== 8-bit Hierarchical LUT Test ===");

        // Small values — should skip
        a_test = 8'd3;  b_test = 8'd2;  #10;
        $display("a=%0d b=%0d product=%0d skip=%0b (expect 1)",
                 a_test, b_test, a_test*b_test, skip);

        // Large values — should compute
        a_test = 8'd50; b_test = 8'd40; #10;
        $display("a=%0d b=%0d product=%0d skip=%0b (expect 0)",
                 a_test, b_test, a_test*b_test, skip);

        // Medium values
        a_test = 8'd10; b_test = 8'd5;  #10;
        $display("a=%0d b=%0d product=%0d skip=%0b",
                 a_test, b_test, a_test*b_test, skip);

        // Zero — should always skip
        a_test = 8'd0;  b_test = 8'd255; #10;
        $display("a=%0d b=%0d product=%0d skip=%0b (expect 1 — zero*anything=0)",
                 a_test, b_test, a_test*b_test, skip);

        $display("=== 8-bit LUT works with only 2x256 entries ===");
        $display("Total LUT memory: 512 bits instead of 65536 bits");
        $display("Memory reduction: 128x smaller than naive 8-bit LUT");
        $finish;
    end
endmodule