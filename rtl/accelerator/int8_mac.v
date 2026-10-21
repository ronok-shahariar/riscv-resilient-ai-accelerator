// Copyright 2026 Md Shahariar Hassan
// SPDX-License-Identifier: Apache-2.0
// Original repository: https://github.com/ronok-shahariar/riscv-resilient-ai-accelerator

`timescale 1ns/1ps

module int8_mac (
    input  wire               clk,
    input  wire               resetn,
    input  wire               clear,
    input  wire               mac_en,

    input  wire signed [7:0]  activation,
    input  wire signed [7:0]  weight,

    // Week 3: Controlled fault injection
    input  wire               fault_en,
    input  wire [1:0]         fault_target, // 2'b00: Activation, 2'b01: Weight, 2'b10: Accumulator bit
    input  wire [4:0]         fault_bit,    // Bit position to flip (0 to 31)

    // Week 3: Dynamic saturation / clamping
    input  wire               clamp_en,
    input  wire signed [31:0] clamp_bound,

    output reg  signed [31:0] acc_result,
    output reg                result_valid,
    output reg                clamp_hit
);

    // Safeguard against unconnected ports in legacy testbenches (treat 'x/'z as 0)
    wire safe_fault_en = (fault_en === 1'b1);
    wire safe_clamp_en = (clamp_en === 1'b1);

    // 1. Transient operand corruption (single-event upset model)
    wire signed [7:0] activation_fused;
    wire signed [7:0] weight_fused;

    assign activation_fused = (safe_fault_en && (fault_target == 2'b00) && (fault_bit < 5'd8)) ?
                              (activation ^ (8'sd1 << fault_bit[2:0])) : activation;

    assign weight_fused     = (safe_fault_en && (fault_target == 2'b01) && (fault_bit < 5'd8)) ?
                              (weight ^ (8'sd1 << fault_bit[2:0])) : weight;

    // 2. Signed INT8 x INT8 -> INT16 multiplication
    wire signed [15:0] product;
    assign product = activation_fused * weight_fused;

    // 3. Sign-extension from INT16 to INT32
    wire signed [31:0] extended_product;
    assign extended_product = {
        {16{product[15]}},
        product
    };

    // 4. Accumulation stage with optional direct accumulator bit-flip
    wire signed [31:0] raw_acc = acc_result + extended_product;

    wire signed [31:0] faulted_acc = (safe_fault_en && (fault_target == 2'b10)) ?
                                     (raw_acc ^ (32'sd1 << fault_bit)) : raw_acc;

    // 5. Dynamic saturation clamping logic
    reg signed [31:0] next_acc;
    reg               clamp_exceeded;

    always @(*) begin
        clamp_exceeded = 1'b0;
        if (safe_clamp_en && (clamp_bound > 32'sd0)) begin
            if (faulted_acc > clamp_bound) begin
                next_acc       = clamp_bound;
                clamp_exceeded = 1'b1;
            end else if (faulted_acc < -clamp_bound) begin
                next_acc       = -clamp_bound;
                clamp_exceeded = 1'b1;
            end else begin
                next_acc       = faulted_acc;
            end
        end else begin
            next_acc = faulted_acc;
        end
    end

    // 6. Synchronous state update
    always @(posedge clk) begin
        if (!resetn) begin
            acc_result   <= 32'sd0;
            result_valid <= 1'b0;
            clamp_hit    <= 1'b0;
        end else if (clear) begin
            acc_result   <= 32'sd0;
            result_valid <= 1'b0;
            clamp_hit    <= 1'b0;
        end else begin
            result_valid <= mac_en;

            if (mac_en) begin
                acc_result <= next_acc;
                clamp_hit  <= clamp_hit | clamp_exceeded;
            end
        end
    end

endmodule
