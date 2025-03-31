`timescale 1ns / 1ps
module tb_test;
  logic clk, rst;
  logic out1, out2;

  initial begin
    clk = 0;
    rst = 1;
    #7 rst = 0;
  end

  always #5 clk = ~clk;

  test DUT (.*);
endmodule
