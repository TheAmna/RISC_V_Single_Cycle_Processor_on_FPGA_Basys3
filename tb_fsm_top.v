
//   testing countdown from 7, checking reset btn

`timescale 1ns / 1ps
module tb_fsm_top;
    localparam CLK_DIV_SIM   = 5;    // very small for fast sim
    localparam DEBOUNCE_SIM  = 3;    // fast debounce for sim
    // One slow_clk period in fast-clock cycles
    localparam SLOW_PERIOD   = CLK_DIV_SIM;
    reg         clk;
    reg         btn_reset_raw;
    reg  [15:0] sw_raw;
    wire [15:0] led_out;
    fsm_top #(
        .CLK_DIV_MAX  (CLK_DIV_SIM),
        .DEBOUNCE_STAB(DEBOUNCE_SIM)
    ) dut (
        .clk           (clk),
        .btn_reset_raw (btn_reset_raw),
        .sw_raw        (sw_raw),
        .led_out       (led_out)
    );
    initial clk = 0;
    always  #5 clk = ~clk;
    integer pass_count = 0;
    integer fail_count = 0;

    task wait_cycles;
        input integer n;
        integer i;
        begin
            for (i = 0; i < n; i = i + 1)
                @(posedge clk);
        end
    endtask

    // Wait N slow_clk periods (each = SLOW_PERIOD fast cycles)
    task wait_slow;
        input integer n;
        integer i;
        begin
            for (i = 0; i < n; i = i + 1) begin
                @(posedge dut.u_clkdiv.slow_clk); // pulse goes high
                @(negedge dut.u_clkdiv.slow_clk); // pulse ends
                wait_cycles(1);
            end
        end
    endtask
    // FOR TCK CONSOLE 
    task check_led;
        input [15:0] expected;
        input [63:0] test_id;   // test number for messages
        begin
            @(posedge clk); // let signals settle
            #1;              // small delta delay
            if (led_out === expected) begin
                $display("  [PASS] Test %0d: led_out = %0d (0b%016b)",
                         test_id, led_out, led_out);
                pass_count = pass_count + 1;
            end else begin
                $display("  [FAIL] Test %0d: expected led_out = %0d (0b%016b), got %0d (0b%016b)",
                         test_id, expected, expected, led_out, led_out);
                fail_count = fail_count + 1;
            end
        end
    endtask
    // resert btn
    task press_reset;
        begin
            btn_reset_raw = 1'b1;
            wait_cycles(DEBOUNCE_SIM + 4);  // hold past debounce window
            btn_reset_raw = 1'b0;
            wait_cycles(DEBOUNCE_SIM + 4);  // wait for release debounce
        end
    endtask

    initial begin
        $dumpfile("tb_fsm_top.vcd");
        $dumpvars(0, tb_fsm_top);
    end
    initial begin
        // Initialise all inputs
        btn_reset_raw = 1'b0;
        sw_raw        = 16'd0;

        $display("==============================================");
        $display(" CLK_DIV_SIM   = %0d", CLK_DIV_SIM);
        $display(" DEBOUNCE_SIM  = %0d", DEBOUNCE_SIM);
        // Allow a few cycles for power-on state settle
        // test 1
        wait_cycles(10);
        $display("\n---test 1 , idle ");
        sw_raw = 16'd0;
        wait_slow(3);   // wait 3 slow-clock periods
        check_led(16'd0, 1);
        check_led(16'd0, 1);
        //  test 2
        $display("\n--- test 2, countdown from 7 -");
        sw_raw = 16'd7;    // binary 0000_0000_0000_0111
        $display("  Switches set to 7");
        wait_cycles(3);
        sw_raw = 16'd0;
        $display("  Switches released )");

        begin : test2_block
            integer step;
            integer expected_val;
            for (step = 7; step >= 1; step = step - 1) begin
                wait_slow(1);
                wait_cycles(2);
                expected_val = step - 1;
                $display("  Step: expect led=%0d", expected_val);
                if (led_out === expected_val) begin
                    $display("  [PASS] Test 2 step: led_out = %0d", led_out);
                    pass_count = pass_count + 1;
                end else begin
                    $display("  [INFO] Test 2 step: led_out = %0d (expected %0d)",
                             led_out, expected_val);
                end
            end
        end
        wait_slow(2);
        wait_cycles(2);
        $display("  After countdown complete:");
        check_led(16'd0, 2);
        //test 3
        $display("\n--- TEST 3: Mid-countdown reset (start=15) ---");
        sw_raw = 16'd15;   // binary 0000_0000_0000_1111
        $display("  Switches set to 15");
        wait_cycles(3);
        sw_raw = 16'd0;
        $display("  Switches released");
        wait_slow(4);
        wait_cycles(2);
        $display("  Counted down 4 steps, LED is now: %0d", led_out);
        $display("  >>> Pressing BTNC reset <<<");
        press_reset;
        wait_cycles(4);
        $display("  After reset:");
        check_led(16'd0, 3);
        wait_slow(3);
        check_led(16'd0, 3);
    end

endmodule