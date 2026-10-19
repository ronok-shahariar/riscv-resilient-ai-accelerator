`timescale 1ns/1ps

module tb_picorv32;

    reg clk = 0;
    reg resetn = 0;

    wire trap;
    wire mem_valid;
    wire mem_instr;
    reg  mem_ready = 0;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [3:0] mem_wstrb;
    reg  [31:0] mem_rdata = 0;

    reg [31:0] ram [0:255];
    integer i;
    integer cycles = 0;

    localparam [31:0] TEST_MMIO = 32'h10000000;

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
        for (i = 0; i < 256; i = i + 1)
            ram[i] = 32'h00000013;

        // addi x1, x0, 5
        ram[0] = 32'h00500093;

        // addi x2, x1, 7
        ram[1] = 32'h00708113;

        // lui x3, 0x10000
        ram[2] = 32'h100001b7;

        // sw x2, 0(x3)
        ram[3] = 32'h0021a023;

        // jal x0, 0
        ram[4] = 32'h0000006f;

        repeat (10) @(posedge clk);
        @(negedge clk);
        resetn = 1;
    end

    always @(posedge clk) begin
        mem_ready <= 0;

        if (resetn && mem_valid && !mem_ready) begin

            if (mem_addr == TEST_MMIO) begin
                if (mem_wstrb == 4'b1111) begin
                    $display("MMIO WRITE: value=%0d", mem_wdata);

                    if (mem_wdata == 32'd12) begin
                        $display("PASS: PicoRV32 executed RV32I instructions correctly.");
                        $finish;
                    end else begin
                        $fatal(1, "FAIL: Expected 12, got %0d", mem_wdata);
                    end
                end else begin
                    $fatal(1, "FAIL: Invalid MMIO access");
                end
            end else if (mem_addr < 1024) begin
                mem_ready <= 1;

                if (mem_wstrb == 0) begin
                    mem_rdata <= ram[mem_addr[9:2]];
                end else begin
                    $fatal(1, "FAIL: Unexpected RAM write");
                end
            end else begin
                $fatal(1, "FAIL: Invalid memory address %h", mem_addr);
            end
        end
    end

    always @(posedge clk) begin
        if (resetn) begin
            cycles <= cycles + 1;

            if (trap)
                $fatal(1, "FAIL: CPU entered trap state");

            if (cycles > 2000)
                $fatal(1, "FAIL: Simulation timeout");
        end
    end

endmodule
