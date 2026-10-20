`timescale 1ns/1ps

module tb_int8_mac_mmio;

    reg clk = 0;
    reg resetn = 0;

    reg mem_valid = 0;
    reg [31:0] mem_addr = 0;
    reg [31:0] mem_wdata = 0;
    reg [3:0] mem_wstrb = 0;

    wire mem_ready;
    wire [31:0] mem_rdata;

    localparam [31:0] BASE    = 32'h80000000;
    localparam [31:0] ACT     = BASE + 32'h00;
    localparam [31:0] WEIGHT  = BASE + 32'h04;
    localparam [31:0] CONTROL = BASE + 32'h08;
    localparam [31:0] STATUS  = BASE + 32'h0C;
    localparam [31:0] RESULT  = BASE + 32'h10;

    integer checks = 0;
    integer timeout;
    integer i;

    reg [31:0] read_value;

    always #5 clk = ~clk;

    int8_mac_mmio dut (
        .clk(clk),
        .resetn(resetn),
        .mem_valid(mem_valid),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_wstrb(mem_wstrb),
        .mem_ready(mem_ready),
        .mem_rdata(mem_rdata)
    );

    // Execute one memory-mapped transaction.
    task automatic transaction;
        input [31:0] addr;
        input [31:0] data;
        input [3:0] strobe;
        output [31:0] response;

        begin
            @(negedge clk);

            mem_addr = addr;
            mem_wdata = data;
            mem_wstrb = strobe;
            mem_valid = 1;

            timeout = 0;

            begin : wait_for_response
                forever begin
                    @(posedge clk);
                    #1;

                    if (mem_ready === 1'b1) begin
                        response = mem_rdata;
                        disable wait_for_response;
                    end

                    timeout = timeout + 1;

                    if (timeout > 20)
                        $fatal(1,
                            "MMIO transaction timeout at %h",
                            addr);
                end
            end

            // Complete the handshake and re-arm.
            @(negedge clk);
            mem_valid = 0;
            mem_wstrb = 0;

            @(posedge clk);
            @(negedge clk);
        end
    endtask

    task automatic write_reg;
        input [31:0] addr;
        input [31:0] data;
        begin
            transaction(addr, data, 4'b1111, read_value);
        end
    endtask

    task automatic read_reg;
        input [31:0] addr;
        output [31:0] data;
        begin
            transaction(addr, 0, 4'b0000, data);
        end
    endtask

    task automatic expect_value;
        input [31:0] actual;
        input [31:0] expected;
        begin
            checks = checks + 1;

            if (actual !== expected) begin
                $display(
                    "[FAIL] Check %0d: expected=%h actual=%h",
                    checks, expected, actual
                );
                $fatal(1, "MMIO verification failed");
            end
        end
    endtask

    task automatic wait_done;
        reg [31:0] status_value;
        integer attempts;
        begin
            status_value = 0;
            attempts = 0;

            while (status_value[0] == 0 && attempts < 20) begin
                read_reg(STATUS, status_value);
                attempts = attempts + 1;
            end

            expect_value(status_value, 32'd1);
        end
    endtask

    initial begin
        $display("========================================");
        $display("WEEK 2: INT8 MAC MMIO VERIFICATION");
        $display("========================================");

        // Reset
        repeat (4) @(negedge clk);
        resetn = 1;

        $display("[TEST] Reset state");

        read_reg(RESULT, read_value);
        expect_value(read_value, 0);

        read_reg(STATUS, read_value);
        expect_value(read_value, 0);

        // First MAC: 5 * 7 = 35
        $display("[TEST] Positive signed MAC");

        write_reg(ACT, 5);
        write_reg(WEIGHT, 7);
        write_reg(CONTROL, 1);

        wait_done();

        read_reg(RESULT, read_value);
        expect_value(read_value, 35);

        $display("[TEST] Sticky DONE status");

        read_reg(STATUS, read_value);
        expect_value(read_value, 1);

        // Second MAC: 35 + (-3 * 4) = 23
        $display("[TEST] Negative operand accumulation");

        write_reg(ACT, 32'hfffffffd);
        write_reg(WEIGHT, 4);
        write_reg(CONTROL, 1);

        wait_done();

        read_reg(RESULT, read_value);
        expect_value(read_value, 23);

        // Third MAC: 23 + (-8 * -2) = 39
        $display("[TEST] Negative times negative");

        write_reg(ACT, 32'hfffffff8);
        write_reg(WEIGHT, 32'hfffffffe);
        write_reg(CONTROL, 1);

        wait_done();

        read_reg(RESULT, read_value);
        expect_value(read_value, 39);

        $display("[TEST] Partial writes ignored");

        transaction(ACT, 100, 4'b0001, read_value);
        write_reg(CONTROL, 1);

        wait_done();

        read_reg(RESULT, read_value);
        expect_value(read_value, 55);

        // Previous activation -8 is preserved:
        // 39 + (-8 * -2) = 55

        $display("[TEST] Clear accumulator");

        write_reg(CONTROL, 2);

        // Allow synchronous clear to propagate.
        repeat (3) @(posedge clk);

        read_reg(RESULT, read_value);
        expect_value(read_value, 0);

        read_reg(STATUS, read_value);
        expect_value(read_value, 0);

        $display("[TEST] Reserved register read");

        read_reg(BASE + 32'h14, read_value);
        expect_value(read_value, 0);

        $display("[TEST] Held mem_valid handshake");

        write_reg(ACT, 5);
        write_reg(WEIGHT, 7);

        @(negedge clk);

        mem_addr = CONTROL;
        mem_wdata = 1;
        mem_wstrb = 4'b1111;
        mem_valid = 1;

        @(posedge clk);
        #1;

        if (mem_ready !== 1)
            $fatal(1, "First MMIO acknowledgment missing");

        // Keep request asserted for additional cycles.
        for (i = 0; i < 6; i = i + 1) begin
            @(posedge clk);
            #1;

            if (mem_ready !== 0)
                $fatal(1, "Duplicate MMIO acknowledgment");
        end

        @(negedge clk);
        mem_valid = 0;
        mem_wstrb = 0;

        @(posedge clk);
        @(negedge clk);

        wait_done();

        read_reg(RESULT, read_value);
        expect_value(read_value, 35);

        $display("========================================");
        $display("[PASS] All MMIO verification tests passed");
        $display("Checks completed: %0d", checks);
        $display("========================================");

        $finish;
    end

    initial begin
        #100000;
        $fatal(1, "MMIO simulation timeout");
    end

endmodule
