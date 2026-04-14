`timescale 1ns / 1ps


module RegisterFile_tb;

    // inputs
    reg         clk;
    reg         rst;
    reg         WriteEnable;
    reg  [4:0]  rs1, rs2, rd;
    reg  [31:0] WriteData;
    wire [31:0] ReadData1, ReadData2;

    // registerfile
    RegisterFile dut (
        .clk        (clk),
        .rst        (rst),
        .WriteEnable(WriteEnable),
        .rs1        (rs1),
        .rs2        (rs2),
        .rd         (rd),
        .WriteData  (WriteData),
        .ReadData1  (ReadData1),
        .ReadData2  (ReadData2)
    );

    
    initial clk = 0;
    always #5 clk = ~clk;

 
    task do_write;
        input [4:0]  addr;
        input [31:0] data;
        begin
            @(negedge clk);          // set up before rising edge
            rd          = addr;
            WriteData   = data;
            WriteEnable = 1'b1;
            @(posedge clk);          // write captured here
            #1;                      // tiny settle
            WriteEnable = 1'b0;
        end
    endtask

   

    integer i;

    initial begin
     // intialise
        rst         = 1'b1;
        WriteEnable = 1'b0;
        rs1         = 5'd0;
        rs2         = 5'd0;
        rd          = 5'd0;
        WriteData   = 32'd0;
        repeat(3) @(posedge clk);
        rst = 1'b0;
        @(negedge clk);

       
        // Test 1: Write to x5 = 0xDEADBEEF, then read it back
        
        
        do_write(5'd5, 32'hDEADBEEF);
        rs1 = 5'd5;
        #1;  // combinational read settles immediately
        check(ReadData1, 32'hDEADBEEF, "T1_read_x5");

        
        // Test 2: Write to x0 - must stay zero
       
       
        do_write(5'd0, 32'hFFFFFFFF);
        rs1 = 5'd0;
        #1;
        check(ReadData1, 32'h00000000, "T2_x0_protect");


        // Test 3: Simultaneous dual-port read
  
        $display("--- Test 3: Simultaneous dual-port read ---");
        do_write(5'd10, 32'hAAAA5555);
        do_write(5'd11, 32'h5555AAAA);
        rs1 = 5'd10;
        rs2 = 5'd11;
        #1;
        check(ReadData1, 32'hAAAA5555, "T3_port1_x10");
        check(ReadData2, 32'h5555AAAA, "T3_port2_x11");

      
        // Test 4: Overwrite a register
       
        $display("--- Test 4: Overwrite x5 ---");
        do_write(5'd5, 32'h12345678);
        rs1 = 5'd5;
        #1;
        check(ReadData1, 32'h12345678, "T4_overwrite");


        // Test 5: Reset restores values
        $display("--- Test 5: Reset restores initial (debug) values ---");
      
        do_write(5'd1, 32'hDEAD0001);
        do_write(5'd7, 32'hDEAD0007);
        // Apply reset
        @(negedge clk);
        rst = 1'b1;
        @(posedge clk); #1;
        rst = 1'b0;
        @(negedge clk);
        // After reset x1 should be 1, x7 should be 7 
        rs1 = 5'd1;
        rs2 = 5'd7;
        #1;
        check(ReadData1, 32'd1, "T5_rst_x1");
        check(ReadData2, 32'd7, "T5_rst_x7");
        // x0 must still be 0
        rs1 = 5'd0;
        #1;
        check(ReadData1, 32'h00000000, "T5_rst_x0");

        
        // Test 6: Read-after-write timing
        // Write x15, read it back the very next clock edge
       
     
        @(negedge clk);
        rd          = 5'd15;
        WriteData   = 32'hCAFEBABE;
        WriteEnable = 1'b1;
        rs1         = 5'd15;         // point read port BEFORE the edge
        @(posedge clk); #1;          // write happens; async read updates
        WriteEnable = 1'b0;
        check(ReadData1, 32'hCAFEBABE, "T6_raw_timing");

        $display("\n=== All tests complete ===\n");
        $finish;
    end


    initial begin
        $dumpfile("RegisterFile_tb.vcd");
        $dumpvars(0, RegisterFile_tb);
    end

endmodule
