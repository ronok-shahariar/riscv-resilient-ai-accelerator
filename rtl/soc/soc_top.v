// Copyright 2026 Md Shahariar Hassan
// SPDX-License-Identifier: Apache-2.0
// Original repository: https://github.com/ronok-shahariar/riscv-resilient-ai-accelerator

`timescale 1ns/1ps

module soc_top (
    input  wire clk_p,
    input  wire clk_n,
    input  wire resetn,
    output wire trap,
    output wire uart_tx
);

    // Internal single-ended clock derived from differential board clock
    wire clk;

    IBUFDS ibufds_sys_clk (
        .I  (clk_p),
        .IB (clk_n),
        .O  (clk)
    );

    wire        mem_valid;
    wire        mem_instr;
    wire        mem_ready;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [3:0]  mem_wstrb;
    wire [31:0] mem_rdata;

    // Address decoders
    wire ram_select  = (mem_addr < 32'h00004000);                      // 0x0000_0000 - 0x0000_3FFF (16KB BRAM)
    wire uart_select = (mem_addr[31:12] == 20'h40000);                 // 0x4000_0000 - 0x4000_0FFF (UART TX)
    wire mac_select  = (mem_addr[31:5]  == 27'h4000000);                // 0x8000_0000 - 0x8000_001F (INT8 MAC Accelerator)

    wire        ram_ready;
    wire [31:0] ram_rdata;

    wire        uart_ready;
    wire [31:0] uart_rdata;

    wire        mac_ready;
    wire [31:0] mac_rdata;

    // Multiplex memory ready response
    assign mem_ready = ram_select  ? ram_ready  :
                       uart_select ? uart_ready :
                       mac_select  ? mac_ready  : 1'b0;

    // Multiplex memory read data response
    assign mem_rdata = ram_select  ? ram_rdata  :
                       uart_select ? uart_rdata :
                       mac_select  ? mac_rdata  : 32'b0;

    picorv32 #(
        .BARREL_SHIFTER(0),
        .ENABLE_COUNTERS(1),
        .ENABLE_REGS_16_31(1),
        .ENABLE_REGS_DUALPORT(1),
        .CATCH_MISALIGN(1),
        .CATCH_ILLINSN(1),
        .PROGADDR_RESET(32'h00000000)
    ) cpu (
        .clk       (clk),
        .resetn    (resetn),
        .trap      (trap),
        .mem_valid (mem_valid),
        .mem_instr (mem_instr),
        .mem_ready (mem_ready),
        .mem_addr  (mem_addr),
        .mem_wdata (mem_wdata),
        .mem_wstrb (mem_wstrb),
        .mem_rdata (mem_rdata)
    );

    bram_16kb memory (
        .clk       (clk),
        .resetn    (resetn),
        .mem_valid (mem_valid && ram_select),
        .mem_addr  (mem_addr),
        .mem_wdata (mem_wdata),
        .mem_wstrb (mem_wstrb),
        .mem_ready (ram_ready),
        .mem_rdata (ram_rdata)
    );

    uart_tx #(
        .BASE_ADDR (32'h40000000),
        .CLK_FREQ  (200000000),
        .BAUD_RATE (115200)
    ) uart_unit (
        .clk       (clk),
        .resetn    (resetn),
        .mem_valid (mem_valid && uart_select),
        .mem_addr  (mem_addr),
        .mem_wdata (mem_wdata),
        .mem_wstrb (mem_wstrb),
        .mem_ready (uart_ready),
        .mem_rdata (uart_rdata),
        .uart_tx   (uart_tx)
    );

    int8_mac_mmio #(
        .BASE_ADDR (32'h80000000)
    ) accelerator (
        .clk       (clk),
        .resetn    (resetn),
        .mem_valid (mem_valid && mac_select),
        .mem_addr  (mem_addr),
        .mem_wdata (mem_wdata),
        .mem_wstrb (mem_wstrb),
        .mem_ready (mac_ready),
        .mem_rdata (mac_rdata)
    );

endmodule