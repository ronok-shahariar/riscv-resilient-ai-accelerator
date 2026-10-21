// Copyright 2026 Md Shahariar Hassan
// SPDX-License-Identifier: Apache-2.0
// Original repository: https://github.com/ronok-shahariar/riscv-resilient-ai-accelerator

`timescale 1ns/1ps

module int8_mac_mmio #(
    parameter [31:0] BASE_ADDR = 32'h80000000
)(
    input  wire        clk,
    input  wire        resetn,

    // PicoRV32 native memory interface
    input  wire        mem_valid,
    input  wire [31:0] mem_addr,
    input  wire [31:0] mem_wdata,
    input  wire [3:0]  mem_wstrb,

    output reg         mem_ready,
    output reg  [31:0] mem_rdata
);

    // Register offsets
    localparam [4:0] REG_ACTIVATION   = 5'h00;
    localparam [4:0] REG_WEIGHT       = 5'h04;
    localparam [4:0] REG_CONTROL      = 5'h08;
    localparam [4:0] REG_STATUS       = 5'h0C;
    localparam [4:0] REG_RESULT       = 5'h10;
    localparam [4:0] REG_FAULT_CONFIG = 5'h14;
    localparam [4:0] REG_PROTECTION   = 5'h18;
    localparam [4:0] REG_CLAMP_BOUND  = 5'h1C;

    // Operand registers
    reg signed [7:0]  activation_reg;
    reg signed [7:0]  weight_reg;

    // Fault injection & Resilience registers
    reg [7:0]         fault_config_reg; // [0] en, [2:1] target, [7:3] bit
    reg               clamp_en_reg;
    reg signed [31:0] clamp_bound_reg;

    // MAC control pulses
    reg mac_start;
    reg mac_clear;

    // Sticky status flags
    reg done;
    wire mac_clamp_hit;

    // Handshake control
    reg request_armed;

    // MAC outputs
    wire signed [31:0] mac_result;
    wire mac_result_valid;

    // Address decoding (32-byte region)
    wire address_match;
    wire aligned;

    assign address_match = (mem_addr[31:5] == BASE_ADDR[31:5]);
    assign aligned       = (mem_addr[1:0] == 2'b00);

    // Instantiated resilient MAC
    int8_mac mac_unit (
        .clk          (clk),
        .resetn       (resetn),
        .clear        (mac_clear),
        .mac_en       (mac_start),
        .activation   (activation_reg),
        .weight       (weight_reg),
        .fault_en     (fault_config_reg[0]),
        .fault_target (fault_config_reg[2:1]),
        .fault_bit    (fault_config_reg[7:3]),
        .clamp_en     (clamp_en_reg),
        .clamp_bound  (clamp_bound_reg),
        .acc_result   (mac_result),
        .result_valid (mac_result_valid),
        .clamp_hit    (mac_clamp_hit)
    );

    always @(posedge clk) begin
        if (!resetn) begin
            activation_reg   <= 8'sd0;
            weight_reg       <= 8'sd0;
            fault_config_reg <= 8'h00;
            clamp_en_reg     <= 1'b0;
            clamp_bound_reg  <= 32'sd127;

            mac_start        <= 1'b0;
            mac_clear        <= 1'b0;
            done             <= 1'b0;

            mem_ready        <= 1'b0;
            mem_rdata        <= 32'b0;
            request_armed    <= 1'b1;
        end else begin
            mac_start <= 1'b0;
            mac_clear <= 1'b0;
            mem_ready <= 1'b0;

            if (!mem_valid)
                request_armed <= 1'b1;

            if (mac_result_valid)
                done <= 1'b1;

            if (mem_valid && request_armed && address_match) begin
                request_armed <= 1'b0;
                mem_ready     <= 1'b1;
                mem_rdata     <= 32'b0;

                if (aligned) begin
                    // Full-word write transactions
                    if (mem_wstrb == 4'b1111) begin
                        case (mem_addr[4:0])
                            REG_ACTIVATION:   activation_reg   <= mem_wdata[7:0];
                            REG_WEIGHT:       weight_reg       <= mem_wdata[7:0];
                            REG_FAULT_CONFIG: fault_config_reg <= mem_wdata[7:0];
                            REG_PROTECTION:   clamp_en_reg     <= mem_wdata[0];
                            REG_CLAMP_BOUND:  clamp_bound_reg  <= mem_wdata;
                            REG_CONTROL: begin
                                if (mem_wdata[1]) begin
                                    mac_clear <= 1'b1;
                                    done      <= 1'b0;
                                end else if (mem_wdata[0]) begin
                                    mac_start <= 1'b1;
                                    done      <= 1'b0;
                                end
                            end
                            default: ;
                        endcase
                    end
                    // Full-word read transactions
                    else if (mem_wstrb == 4'b0000) begin
                        case (mem_addr[4:0])
                            REG_STATUS:       mem_rdata <= {30'b0, mac_clamp_hit, done};
                            REG_RESULT:       mem_rdata <= mac_result;
                            REG_FAULT_CONFIG: mem_rdata <= {24'b0, fault_config_reg};
                            REG_PROTECTION:   mem_rdata <= {31'b0, clamp_en_reg};
                            REG_CLAMP_BOUND:  mem_rdata <= clamp_bound_reg;
                            default:          mem_rdata <= 32'b0;
                        endcase
                    end
                end
            end
        end
    end

endmodule
