`timescale 1ns/1ps

module int8_mac (
    input  wire               clk,
    input  wire               resetn,
    input  wire               clear,
    input  wire               mac_en,

    input  wire signed [7:0]  activation,
    input  wire signed [7:0]  weight,

    output reg  signed [31:0] acc_result,
    output reg                result_valid
);

    // Signed INT8 x INT8 -> INT16 product
    wire signed [15:0] product;

    assign product = activation * weight;

    // Sign-extend INT16 product to INT32
    wire signed [31:0] extended_product;

    assign extended_product = {
        {16{product[15]}},
        product
    };

    // Synchronous accumulation
    always @(posedge clk) begin

        if (!resetn) begin
            acc_result  <= 32'sd0;
            result_valid <= 1'b0;
        end

        else if (clear) begin
            acc_result  <= 32'sd0;
            result_valid <= 1'b0;
        end

        else begin
            result_valid <= mac_en;

            if (mac_en) begin
                acc_result <= acc_result + extended_product;
            end
        end
    end

endmodule
