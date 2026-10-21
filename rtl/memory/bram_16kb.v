// Copyright 2026 Md Shahariar Hassan
// SPDX-License-Identifier: Apache-2.0
// Original repository: https://github.com/ronok-shahariar/riscv-resilient-ai-accelerator

`timescale 1ns/1ps

module bram_16kb (
    input  wire        clk,
    input  wire        resetn,
    input  wire        mem_valid,
    input  wire [31:0] mem_addr,
    input  wire [31:0] mem_wdata,
    input  wire [3:0]  mem_wstrb,
    output reg         mem_ready,
    output reg  [31:0] mem_rdata
);

    // 16 KB RAM = 4096 words of 32 bits
    (* ram_style = "block" *) reg [31:0] ram [0:4095];

    // Initialize RAM with compiled RISC-V firmware hex
    initial begin
        $readmemh("/home/ronok/Documents/riscv-resilient-ai-accelerator/firmware/build/firmware.hex", ram);
    end

    // Address word index
    wire [11:0] word_addr = mem_addr[13:2];

    reg valid_q;

    always @(posedge clk) begin
        if (!resetn) begin
            valid_q   <= 1'b0;
            mem_ready <= 1'b0;
            mem_rdata <= 32'b0;
        end else begin
            valid_q   <= mem_valid;
            mem_ready <= mem_valid && !valid_q;

            if (mem_valid) begin
                if (mem_wstrb[0]) ram[word_addr][ 7: 0] <= mem_wdata[ 7: 0];
                if (mem_wstrb[1]) ram[word_addr][15: 8] <= mem_wdata[15: 8];
                if (mem_wstrb[2]) ram[word_addr][23:16] <= mem_wdata[23:16];
                if (mem_wstrb[3]) ram[word_addr][31:24] <= mem_wdata[31:24];

                mem_rdata <= ram[word_addr];
            end
        end
    end

endmodule