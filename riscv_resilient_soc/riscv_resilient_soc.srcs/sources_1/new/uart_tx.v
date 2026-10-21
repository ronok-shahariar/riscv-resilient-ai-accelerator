// Copyright 2026 Md Shahariar Hassan
// SPDX-License-Identifier: Apache-2.0

`timescale 1ns/1ps

module uart_tx #(
    parameter [31:0] BASE_ADDR = 32'h40000000,
    parameter integer CLK_FREQ = 50000000,
    parameter integer BAUD_RATE = 115200
)(
    input  wire        clk,
    input  wire        resetn,

    // PicoRV32 native memory interface
    input  wire        mem_valid,
    input  wire [31:0] mem_addr,
    input  wire [31:0] mem_wdata,
    input  wire [3:0]  mem_wstrb,

    output reg         mem_ready,
    output reg  [31:0] mem_rdata,

    // Physical UART TX pin output to FPGA package pin
    output reg         uart_tx
);

    localparam integer CYCLES_PER_BIT = CLK_FREQ / BAUD_RATE;

    wire address_match = (mem_addr[31:12] == BASE_ADDR[31:12]);

    reg [3:0]  state;
    reg [15:0] clk_count;
    reg [3:0]  bit_index;
    reg [9:0]  tx_shift_reg;
    reg        is_busy;

    always @(posedge clk) begin
        if (!resetn) begin
            uart_tx      <= 1'b1;
            mem_ready    <= 1'b0;
            mem_rdata    <= 32'b0;
            state        <= 4'd0;
            clk_count    <= 16'd0;
            bit_index    <= 4'd0;
            tx_shift_reg <= 10'b1111111111;
            is_busy      <= 1'b0;
        end else begin
            mem_ready <= 1'b0;

            // Handle incoming bus write requests to send characters
            if (mem_valid && !mem_ready && address_match && (mem_wstrb != 4'b0000) && !is_busy) begin
                mem_ready    <= 1'b1;
                tx_shift_reg <= {1'b1, mem_wdata[7:0], 1'b0}; // Stop bit, data byte, start bit
                is_busy      <= 1'b1;
                clk_count    <= 16'd0;
                bit_index    <= 4'd0;
            end else if (is_busy) begin
                if (clk_count < CYCLES_PER_BIT - 1) begin
                    clk_count <= clk_count + 1'b1;
                end else begin
                    clk_count <= 16'd0;
                    uart_tx   <= tx_shift_reg[0];
                    tx_shift_reg <= {1'b1, tx_shift_reg[9:1]};
                    
                    if (bit_index < 4'd9) begin
                        bit_index <= bit_index + 1'b1;
                    end else begin
                        is_busy   <= 1'b0;
                        uart_tx   <= 1'b1;
                    end
                end
            end
        end
    end

endmodule