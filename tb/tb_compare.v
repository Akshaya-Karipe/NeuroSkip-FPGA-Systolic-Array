`timescale 1ns/1ps
module tb_compare;

    reg [3:0] a_test;
    reg [3:0] b_test;

    wire skip_ai;
    wire skip_thresh;

    // Instantiate AI LUT
    ai_skip_lut AI_LUT (
        .a(a_test),
        .b(b_test),
        .skip(skip_ai)
    );

    // Instantiate Threshold
    threshold_skip THRESH (
        .a(a_test),
        .b(b_test),
        .skip(skip_thresh)
    );

    integer ai_skip_count;
    integer thresh_skip_count;
    integer agree_count;
    integer i;

    initial begin
        ai_skip_count    = 0;
        thresh_skip_count = 0;
        agree_count      = 0;

        $display("=== AI LUT vs Threshold Comparison ===");
        $display("Testing all 256 combinations of 4-bit a and b");

        // Test all 256 input combinations
        for (i = 0; i < 256; i = i + 1) begin
            a_test = i[3:0];   // lower 4 bits
            b_test = i[7:4];   // upper 4 bits
            #10;

            if (skip_ai)     ai_skip_count    = ai_skip_count + 1;
            if (skip_thresh) thresh_skip_count = thresh_skip_count + 1;
            if (skip_ai == skip_thresh) agree_count = agree_count + 1;
        end

        $display("");
        $display("--- RESULTS ---");
        $display("AI LUT skip count:         %0d / 256 = %0d%%",
                 ai_skip_count,
                 ai_skip_count * 100 / 256);
        $display("Threshold skip count:      %0d / 256 = %0d%%",
                 thresh_skip_count,
                 thresh_skip_count * 100 / 256);
        $display("Decisions that agree:      %0d / 256 = %0d%%",
                 agree_count,
                 agree_count * 100 / 256);
        $display("");
        $display("=== COPY THESE INTO YOUR PAPER TABLE ===");
        $display("AI LUT accuracy vs threshold: %0d%%",
                 agree_count * 100 / 256);

        $finish;
    end

endmodule
