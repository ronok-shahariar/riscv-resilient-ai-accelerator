`timescale 1ns/1ps

module tb_int8_mac_exhaustive;

    reg clk = 0;
    reg resetn = 0;
    reg clear = 0;
    reg mac_en = 0;

    reg signed [7:0] activation = 0;
    reg signed [7:0] weight = 0;

    wire signed [31:0] acc_result;
    wire result_valid;

    reg signed [31:0] expected_acc = 0;
    reg signed [31:0] product_ref;

    integer a;
    integer w;
    integer checks = 0;

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

    initial begin
        $display("========================================");
        $display("INT8 MAC EXHAUSTIVE VERIFICATION");
        $display("========================================");

        // Hold reset across two rising edges.
        repeat (2) @(negedge clk);
        resetn = 1;

        // Test every signed INT8 operand combination.
        for (a = -128; a <= 127; a = a + 1) begin
            for (w = -128; w <= 127; w = w + 1) begin

                @(negedge clk);

                activation = a;
                weight = w;
                mac_en = 1;
                clear = 0;

                // Independent integer reference arithmetic.
                product_ref = a * w;
                expected_acc = expected_acc + product_ref;

                @(posedge clk);
                #1;

                if (acc_result !== expected_acc ||
                    result_valid !== 1'b1) begin

                    $display("[FAIL] A=%0d W=%0d", a, w);
                    $display("Expected=%0d Actual=%0d",
                             expected_acc, acc_result);

                    $fatal(1, "Exhaustive MAC test failed");
                end

                checks = checks + 1;
            end
        end

        @(negedge clk);
        mac_en = 0;

        $display("========================================");
        $display("[PASS] Exhaustive INT8 MAC verification");
        $display("Operand combinations checked: %0d", checks);
        $display("========================================");

        $finish;
    end

    initial begin
        #2000000;
        $fatal(1, "Exhaustive simulation timeout");
    end

endmodule
