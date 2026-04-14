`timescale 1ns / 1ps
module debouncer #(
    parameter STABLE_MAX = 500_000
)(
    input  wire clk,
    input  wire pbin,
    output reg  pbout
);
    reg [$clog2(STABLE_MAX+1)-1 : 0] stable_cnt;
    reg prev_in;
    initial begin
        pbout      = 1'b0;
        prev_in    = 1'b0;
        stable_cnt = 0;
    end
    always @(posedge clk) begin
        if (pbin == prev_in) begin
            if (stable_cnt < STABLE_MAX) begin
                stable_cnt <= stable_cnt + 1;
            end else begin
                pbout <= prev_in;
            end
        end else begin
            prev_in    <= pbin;
            stable_cnt <= 0;
        end
    end
endmodule
