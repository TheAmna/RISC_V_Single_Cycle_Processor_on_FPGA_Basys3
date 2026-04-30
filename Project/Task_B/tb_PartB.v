`timescale 1ns / 1ps
module tb_PartB;

    reg         clk;
    reg         rst;
    wire [31:0] mem_address;
    wire [31:0] mem_write_data;
    wire        mem_write_en;
    wire        mem_read_en;
    reg  [31:0] mem_read_data;

    TopLevelProcessor uut (
        .clk            (clk),
        .clk_en         (1'b1),
        .rst            (rst),
        .mem_address    (mem_address),
        .mem_write_data (mem_write_data),
        .mem_write_en   (mem_write_en),
        .mem_read_en    (mem_read_en),
        .mem_read_data  (mem_read_data)
    );

    reg [31:0] dmem [0:255];
    integer mi;
    initial for (mi = 0; mi < 256; mi = mi + 1) dmem[mi] = 32'd0;
    always @(posedge clk)
        if (mem_write_en) dmem[mem_address[9:2]] <= mem_write_data;
    always @(*)
        mem_read_data = mem_read_en ? dmem[mem_address[9:2]] : 32'd0;

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        rst = 1;
        repeat(3) @(posedge clk);
        rst = 0;
        repeat(40) @(posedge clk);
        $finish;
    end

endmodule
