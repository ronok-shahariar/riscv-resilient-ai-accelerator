// Copyright 2026 Md Shahariar Hassan
// SPDX-License-Identifier: Apache-2.0
// Original repository: https://github.com/ronok-shahariar/riscv-resilient-ai-accelerator

`timescale 1ns/1ps

module tb_picorv32_accelerator;

    reg clk = 0;
    reg resetn = 0;

    wire trap;
    wire mem_valid;
    wire mem_instr;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [3:0] mem_wstrb;
    wire mem_ready;
    wire [31:0] mem_rdata;

    // 16 KB RAM
    reg [31:0] ram [0:4095];

    reg ram_ready = 0;
    reg [31:0] ram_rdata = 0;

    wire mac_ready;
    wire [31:0] mac_rdata;

    wire ram_select;
    wire mac_select;
    wire test_select;

    integer i;
    integer cycles = 0;
    integer mac_commands = 0;

    localparam [31:0] TEST_OUTPUT = 32'h10000000;

    always #5 clk = ~clk;

    assign ram_select =
        (mem_addr < 32'h00004000);

    assign mac_select =
        (mem_addr[31:5] == 27'h4000000);

    assign test_select =
        (mem_addr == TEST_OUTPUT);

    // Responses selected by the current bus address.
    assign mem_ready =
        ram_select  ? ram_ready :
        mac_select  ? mac_ready :
        test_select ? 1'b0 :
                      1'b0;

    assign mem_rdata =
        ram_select ? ram_rdata :
        mac_select ? mac_rdata :
                     32'b0;

    picorv32 #(
        .PROGADDR_RESET(32'h00000000),
        .COMPRESSED_ISA(0)
    ) cpu (
        .clk(clk),
        .resetn(resetn),
        .trap(trap),

        .mem_valid(mem_valid),
        .mem_instr(mem_instr),
        .mem_ready(mem_ready),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_wstrb(mem_wstrb),
        .mem_rdata(mem_rdata),

        .irq(32'b0),
        .eoi(),
        .trace_valid(),
        .trace_data(),

        .pcpi_valid(),
        .pcpi_insn(),
        .pcpi_rs1(),
        .pcpi_rs2(),
        .pcpi_wr(1'b0),
        .pcpi_rd(32'b0),
        .pcpi_wait(1'b0),
        .pcpi_ready(1'b0)
    );

    int8_mac_mmio accelerator (
        .clk(clk),
        .resetn(resetn),

        .mem_valid(mem_valid && mac_select),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_wstrb(mem_wstrb),

        .mem_ready(mac_ready),
        .mem_rdata(mac_rdata)
    );

    initial begin

        for (i = 0; i < 4096; i = i + 1)
            ram[i] = 32'h00000013;

        // Load accelerator firmware instead of Week 1 firmware.
        $readmemh(
            "firmware/accelerator/build/accelerator.hex",
            ram
        );

        $display("========================================");
        $display("WEEK 2: PICO RV32 + INT8 MAC SOC TEST");
        $display("========================================");
        $display("[INFO] RV32I firmware loaded");
        $display("[INFO] MAC MMIO base: 0x80000000");

        repeat (10) @(posedge clk);
        @(negedge clk);

        resetn = 1;
    end

    // RAM supports reads and byte-enabled writes.
    always @(posedge clk) begin
        ram_ready <= 0;

        if (resetn && mem_valid &&
            ram_select && !ram_ready) begin

            ram_ready <= 1;

            if (mem_wstrb == 4'b0000) begin

                ram_rdata <= ram[mem_addr[13:2]];

            end else begin

                if (mem_wstrb[0])
                    ram[mem_addr[13:2]][7:0]
                        <= mem_wdata[7:0];

                if (mem_wstrb[1])
                    ram[mem_addr[13:2]][15:8]
                        <= mem_wdata[15:8];

                if (mem_wstrb[2])
                    ram[mem_addr[13:2]][23:16]
                        <= mem_wdata[23:16];

                if (mem_wstrb[3])
                    ram[mem_addr[13:2]][31:24]
                        <= mem_wdata[31:24];

            end
        end
    end

    // Observe completed MMIO writes.
    always @(posedge clk) begin

        if (resetn && mem_valid &&
            mac_select && mac_ready &&
            mem_wstrb == 4'b1111 &&
            mem_addr == 32'h80000008 &&
            mem_wdata[0] && !mem_wdata[1]) begin

            mac_commands <= mac_commands + 1;

            $display(
                "[MAC] START command %0d",
                mac_commands + 1
            );
        end

        // The test-output address terminates the simulation.
        if (resetn && mem_valid && test_select &&
            mem_wstrb == 4'b1111) begin

            $display("[RESULT] Firmware reported: %0d",
                     mem_wdata);

            if (mem_wdata !== 32'd39)
                $fatal(1,
                    "Firmware reported an accelerator error");

            if (mac_commands !== 3)
                $fatal(1,
                    "Expected exactly 3 MAC START commands");

            if (accelerator.mac_result !== 32'sd39)
                $fatal(1,
                    "Final accelerator accumulator incorrect");

            $display("========================================");
            $display("[PASS] PicoRV32 controlled INT8 MAC");
            $display("[PASS] Three MAC commands completed");
            $display("[PASS] Final accumulator = 39");
            $display("========================================");

            $finish;
        end
    end

    // CPU trap and timeout detection.
    always @(posedge clk) begin

        if (resetn) begin

            cycles <= cycles + 1;

            if (trap)
                $fatal(1, "CPU entered trap state");

            if (mem_valid && !ram_select &&
                !mac_select && !test_select)
                $fatal(1,
                    "Invalid memory address: %h", mem_addr);

            if (cycles > 20000)
                $fatal(1,
                    "CPU accelerator simulation timeout");
        end
    end

endmodule
