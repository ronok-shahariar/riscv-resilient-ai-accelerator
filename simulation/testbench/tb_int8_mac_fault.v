// Copyright 2026 Md Shahariar Hassan
// SPDX-License-Identifier: Apache-2.0
// Original repository: https://github.com/ronok-shahariar/riscv-resilient-ai-accelerator

`timescale 1ns/1ps

module tb_int8_mac_fault;

    reg clk = 0;
    reg resetn = 0;
    reg clear = 0;
    reg mac_en = 0;

    reg signed [7:0]  activation = 0;
    reg signed [7:0]  weight = 0;
    reg               fault_en = 0;
    reg [1:0]         fault_target = 0;
    reg [4:0]         fault_bit = 0;
    reg               clamp_en = 0;
    reg signed [31:0] clamp_bound = 127;

    wire signed [31:0] acc_result;
    wire result_valid;
    wire clamp_hit;

    integer checks = 0;
    integer bit_idx;

    always #5 clk = ~clk;

    int8_mac dut (
        .clk          (clk),
        .resetn       (resetn),
        .clear        (clear),
        .mac_en       (mac_en),
        .activation   (activation),
        .weight       (weight),
        .fault_en     (fault_en),
        .fault_target (fault_target),
        .fault_bit    (fault_bit),
        .clamp_en     (clamp_en),
        .clamp_bound  (clamp_bound),
        .acc_result   (acc_result),
        .result_valid (result_valid),
        .clamp_hit    (clamp_hit)
    );

    task automatic run_mac(
        input signed [7:0] a,
        input signed [7:0] w,
        input f_en,
        input [1:0] f_tgt,
        input [4:0] f_b,
        input c_en,
        input signed [31:0] c_b
    );
        begin
            @(negedge clk);
            activation   = a;
            weight       = w;
            fault_en     = f_en;
            fault_target = f_tgt;
            fault_bit    = f_b;
            clamp_en     = c_en;
            clamp_bound  = c_b;
            mac_en       = 1;
            clear        = 0;

            @(posedge clk);
            #1;
            mac_en       = 0;
            fault_en     = 0;
        end
    endtask

    initial begin
        $display("========================================");
        $display("WEEK 3: FAULT INJECTION & RESILIENCE TEST");
        $display("========================================");

        repeat (2) @(negedge clk);
        resetn = 1;

        // 1. Bit-flip sweep on weights: 10 * 1 = 10
        $display("[TEST] Single-bit flip sweep on weights (0 to 7)");
        for (bit_idx = 0; bit_idx < 8; bit_idx = bit_idx + 1) begin
            @(negedge clk);
            clear = 1;
            @(posedge clk);
            #1;
            clear = 0;

            // Target = 1 (weight), flip bit_idx
            run_mac(10, 1, 1, 2'b01, bit_idx[4:0], 0, 127);
            checks = checks + 1;

            if (bit_idx == 0) begin
                // Weight becomes 1 ^ 1 = 0 -> 10 * 0 = 0
                if (acc_result !== 0) $fatal(1, "Bit 0 flip check failed");
            end else if (bit_idx == 7) begin
                // Weight becomes 1 ^ 128 = -127 -> 10 * (-127) = -1270
                if (acc_result !== -1270) $fatal(1, "Bit 7 MSB flip check failed");
            end
        end

        // 2. Dynamic clamping recovery test
        $display("[TEST] Clamping mitigation on MSB bit-flip");
        @(negedge clk);
        clear = 1;
        @(posedge clk);
        #1;
        clear = 0;

        // Re-run the MSB flip with clamp_bound = 100 enabled
        run_mac(10, 1, 1, 2'b01, 5'd7, 1, 100);
        checks = checks + 1;

        if (acc_result !== -100) begin
            $display("[FAIL] Expected clamped output -100, got %0d", acc_result);
            $fatal(1, "Clamping failure");
        end

        if (clamp_hit !== 1'b1) begin
            $fatal(1, "Sticky clamp_hit flag was not asserted");
        end

        $display("========================================");
        $display("[PASS] All Fault Resilience checks passed");
        $display("Checks completed: %0d", checks);
        $display("========================================");
        $finish;
    end

    initial begin
        #100000;
        $fatal(1, "Fault simulation timeout");
    end

endmodule
