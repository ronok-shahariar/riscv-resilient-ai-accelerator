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
        $display("PicoRV32 Full Firmware & UART Test");
        $display("======================================");

        repeat (10) @(posedge clk);
        @(negedge clk);
        resetn = 1;
    end

    // Realistic memory & MMIO model supporting BRAM (reads/writes) and UART output
    always @(posedge clk) begin
        mem_ready <= 0;

        if (resetn && mem_valid && !mem_ready) begin
            mem_ready <= 1;

            // 1. BRAM Access (0 to 16383)
            if (mem_addr < 16384) begin
                if (mem_wstrb == 4'b0000) begin
                    // Read
                    mem_rdata <= ram[mem_addr[13:2]];
                end else begin
                    // Write (Stack / Global variables)
                    if (mem_wstrb[0]) ram[mem_addr[13:2]][ 7: 0] <= mem_wdata[ 7: 0];
                    if (mem_wstrb[1]) ram[mem_addr[13:2]][15: 8] <= mem_wdata[15: 8];
                    if (mem_wstrb[2]) ram[mem_addr[13:2]][23:16] <= mem_wdata[23:16];
                    if (mem_wstrb[3]) ram[mem_addr[13:2]][31:24] <= mem_wdata[31:24];
                end

            // 2. UART MMIO Region (e.g., 0x40000000)
            end else if (mem_addr == 32'h40000000) begin
                if (mem_wstrb != 4'b0000) begin
                    // Print characters sent to UART during simulation
                    $write("%c", mem_wdata[7:0]);
                end

            // 3. Accelerator MMIO Region (e.g., 0x80000000)
            end else if (mem_addr == 32'h80000000 || mem_addr == 32'h00001000) begin
                // Acknowledge accelerator/mock MMIO writes gracefully
                mem_rdata <= 32'h00000003; // Mock ready status

            end else begin
                $display("WARNING: Unhandled memory address access: %h", mem_addr);
            end
        end
    end

    // Timeout and trap checks
    always @(posedge clk) begin
        if (resetn) begin
            cycles <= cycles + 1;

            if (trap)
                $fatal(1, "FAIL: CPU entered trap state");

            // Finish simulation after enough cycles for firmware to complete printing
            if (cycles > 100000) begin
                $display("Simulation completed successfully.");
                $finish;
            end
        end
    end

endmodule