`timescale 1ns/1ps

module int8_mac_mmio #(
    parameter [31:0] BASE_ADDR = 32'h80000000
)(
    input  wire        clk,
    input  wire        resetn,

    // PicoRV32 native memory interface
    input  wire        mem_valid,
    input  wire [31:0] mem_addr,
    input  wire [31:0] mem_wdata,
    input  wire [3:0]  mem_wstrb,

    output reg         mem_ready,
    output reg  [31:0] mem_rdata
);

    // Register offsets
    localparam [4:0] REG_ACTIVATION = 5'h00;
    localparam [4:0] REG_WEIGHT     = 5'h04;
    localparam [4:0] REG_CONTROL    = 5'h08;
    localparam [4:0] REG_STATUS     = 5'h0C;
    localparam [4:0] REG_RESULT     = 5'h10;

    // Operand registers
    reg signed [7:0] activation_reg;
    reg signed [7:0] weight_reg;

    // MAC control pulses
    reg mac_start;
    reg mac_clear;

    // Sticky completion status
    reg done;

    // Prevent repeated acceptance of one held request
    reg request_armed;

    // MAC outputs
    wire signed [31:0] mac_result;
    wire mac_result_valid;

    // Address decoding: 32-byte MMIO region
    wire address_match;
    wire aligned;

    assign address_match =
        (mem_addr[31:5] == BASE_ADDR[31:5]);

    assign aligned = (mem_addr[1:0] == 2'b00);

    // Existing verified MAC module
    int8_mac mac_unit (
        .clk(clk),
        .resetn(resetn),
        .clear(mac_clear),
        .mac_en(mac_start),
        .activation(activation_reg),
        .weight(weight_reg),
        .acc_result(mac_result),
        .result_valid(mac_result_valid)
    );

    always @(posedge clk) begin

        if (!resetn) begin
            activation_reg <= 8'sd0;
            weight_reg     <= 8'sd0;

            mac_start <= 1'b0;
            mac_clear <= 1'b0;

            done <= 1'b0;

            mem_ready <= 1'b0;
            mem_rdata <= 32'b0;

            request_armed <= 1'b1;
        end

        else begin
            // Default: command pulses last one clock
            mac_start <= 1'b0;
            mac_clear <= 1'b0;

            // Default: memory response pulse
            mem_ready <= 1'b0;

            // Re-arm after request deassertion
            if (!mem_valid)
                request_armed <= 1'b1;

            // Capture MAC completion
            if (mac_result_valid)
                done <= 1'b1;

            // Accept one request per valid assertion
            if (mem_valid && request_armed &&
                address_match) begin

                request_armed <= 1'b0;
                mem_ready <= 1'b1;
                mem_rdata <= 32'b0;

                if (aligned) begin

                    // Full-word write transactions
                    if (mem_wstrb == 4'b1111) begin

                        case (mem_addr[4:0])

                            REG_ACTIVATION: begin
                                activation_reg <=
                                    mem_wdata[7:0];
                            end

                            REG_WEIGHT: begin
                                weight_reg <=
                                    mem_wdata[7:0];
                            end

                            REG_CONTROL: begin

                                // Clear takes priority
                                if (mem_wdata[1]) begin
                                    mac_clear <= 1'b1;
                                    done <= 1'b0;
                                end

                                else if (mem_wdata[0]) begin
                                    mac_start <= 1'b1;
                                    done <= 1'b0;
                                end
                            end

                            default: begin
                                // Reserved or read-only register:
                                // Ignore write.
                            end

                        endcase
                    end

                    // Full-word read transactions
                    else if (mem_wstrb == 4'b0000) begin

                        case (mem_addr[4:0])

                            REG_STATUS: begin
                                mem_rdata <= {31'b0, done};
                            end

                            REG_RESULT: begin
                                mem_rdata <= mac_result;
                            end

                            default: begin
                                mem_rdata <= 32'b0;
                            end

                        endcase
                    end

                    // Partial writes are acknowledged
                    // but do not modify registers.
                end
            end
        end
    end

endmodule
