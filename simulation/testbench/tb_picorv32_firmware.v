`timescale 1ns/1ps

module tb_picorv32_firmware;

    reg clk = 0;
    reg resetn = 0;

    wire trap;
    wire mem_valid;
    wire mem_instr;
    reg mem_ready = 0;

    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [3:0] mem_wstrb;
    reg [31:0] mem_rdata = 0;

    // 16 KB memory = 4096 words
    reg [31:0] ram [0:4095];

    integer i;
    integer cycles = 0;

    localparam [31:0] TEST_MMIO = 32'h10000000;

    // 100 MHz simulation clock
    always #5 clk = ~clk;

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

    initial begin
        // Initialize memory with RISC-V NOP instructions
        for (i = 0; i < 4096; i = i + 1)
            ram[i] = 32'h00000013;

        // Load GCC-generated instructions
        $readmemh("firmware/build/firmware.hex", ram);

        $display("======================================");
        $display("PicoRV32 Bare-Metal Firmware Test");
        $display("======================================");

        repeat (10) @(posedge clk);
        @(negedge clk);
        resetn = 1;
    end

    // One-cycle-response memory model
    always @(posedge clk) begin
        mem_ready <= 0;

        if (resetn && mem_valid && !mem_ready) begin

            if (mem_addr == TEST_MMIO) begin

                if (mem_wstrb == 4'b1111) begin
                    $display("MMIO WRITE: value=%0d", mem_wdata);

                    if (mem_wdata == 32'd12) begin
                        $display("PASS: Compiled C firmware executed successfully.");
                        $finish;
                    end else begin
                        $fatal(1, "FAIL: Incorrect MMIO value");
                    end

                end else begin
                    $fatal(1, "FAIL: Invalid MMIO write");
                end

            end else if (mem_addr < 16384) begin
                mem_ready <= 1;

                if (mem_wstrb == 0)
                    mem_rdata <= ram[mem_addr[13:2]];
                else
                    $fatal(1, "FAIL: Unexpected RAM write");

            end else begin
                $fatal(1, "FAIL: Invalid memory address %h", mem_addr);
            end
        end
    end

    // Timeout and trap checks
    always @(posedge clk) begin
        if (resetn) begin
            cycles <= cycles + 1;

            if (trap)
                $fatal(1, "FAIL: CPU entered trap state");

            if (cycles > 5000)
                $fatal(1, "FAIL: Simulation timeout");
        end
    end

endmodule
