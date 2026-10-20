`timescale 1ns/1ps

module tb_int8_mac;

    reg clk = 0;
    reg resetn = 0;
    reg clear = 0;
    reg mac_en = 0;

    reg signed [7:0] activation = 0;
    reg signed [7:0] weight = 0;

    wire signed [31:0] acc_result;
    wire result_valid;

    reg signed [31:0] expected_acc = 0;
    reg expected_valid = 0;

    integer tests = 0;
    integer i;

    always #5 clk = ~clk;

    int8_mac dut (
        .clk(clk),
        .resetn(resetn),
        .clear(clear),
        .mac_en(mac_en),
        .activation(activation),
        .weight(weight),
        .acc_result(acc_result),
        .result_valid(result_valid)
    );

    task automatic check_result;
        begin
            if (acc_result !== expected_acc ||
                result_valid !== expected_valid) begin

                $display("[FAIL] Test %0d", tests);
                $display("Expected ACC=%0d, VALID=%b",
                         expected_acc, expected_valid);
                $display("Actual   ACC=%0d, VALID=%b",
                         acc_result, result_valid);

                $fatal(1, "MAC verification failed");
            end

            tests = tests + 1;
        end
    endtask

    task automatic run_cycle;
        input signed [7:0] a;
        input signed [7:0] w;
        input en;
        input clr;

        reg signed [31:0] product_ref;

        begin
            @(negedge clk);

            activation = a;
            weight = w;
            mac_en = en;
            clear = clr;

            product_ref = $signed(a) * $signed(w);

            if (clr) begin
                expected_acc = 0;
                expected_valid = 0;
            end else if (en) begin
                expected_acc = expected_acc + product_ref;
                expected_valid = 1;
            end else begin
                expected_valid = 0;
            end

            @(posedge clk);
            #1;
            check_result();
        end
    endtask

    initial begin
        $display("====================================");
        $display("WEEK 2: INT8 MAC VERIFICATION");
        $display("====================================");

        // Verify synchronous active-low reset
        repeat (2) @(posedge clk);
        #1;

        check_result();

        @(negedge clk);
        resetn = 1;

        $display("[TEST] Positive multiplication");
        run_cycle(5, 7, 1, 0);

        $display("[TEST] Negative multiplication");
        run_cycle(-3, 4, 1, 0);

        $display("[TEST] Negative times negative");
        run_cycle(-8, -2, 1, 0);

        $display("[TEST] Zero multiplication");
        run_cycle(0, 100, 1, 0);

        $display("[TEST] Idle cycle");
        run_cycle(10, 10, 0, 0);

        $display("[TEST] Clear accumulator");
        run_cycle(0, 0, 0, 1);

        $display("[TEST] Clear priority over MAC");
        run_cycle(127, 127, 1, 1);

        $display("[TEST] Signed INT8 boundaries");
        run_cycle(-128, -128, 1, 0);
        run_cycle(-128, 127, 1, 0);
        run_cycle(127, -128, 1, 0);
        run_cycle(127, 127, 1, 0);

        $display("[TEST] Randomized verification");

        for (i = 0; i < 200; i = i + 1) begin
            run_cycle(
                $random,
                $random,
                1,
                0
            );
        end

        $display("[TEST] 32-bit overflow wraparound");

        // White-box initialization for overflow testing.
        // This is testbench-only and is not synthesizable.
        @(negedge clk);

        // Disable MAC before the next rising edge.
        // Prevent an unintended accumulation during setup.
        mac_en = 0;

        dut.acc_result = 32'h7ffffff0;
        expected_acc = 32'h7ffffff0;

        run_cycle(127, 127, 1, 0);

        $display("====================================");
        $display("[PASS] All INT8 MAC tests passed");
        $display("Total checks: %0d", tests);
        $display("====================================");

        $finish;
    end

    initial begin
        #100000;
        $fatal(1, "Simulation timeout");
    end

endmodule
