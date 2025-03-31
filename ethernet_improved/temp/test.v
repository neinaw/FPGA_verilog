`timescale 1ns / 1ps
module test (
    input clk,
    input rst,
    output reg out1,
    output reg out2
);

  reg next_out1, next_out2;
  reg [1:0] state, next_state;
  always @(posedge clk) begin
    if (rst) begin
      state <= 2'b0;
      out1  <= 0;
      out2  <= 0;
    end else begin
      state <= next_state;
      out1  <= next_out1;
      out2  <= next_out2;
    end
  end

  always @* begin
    case (state)
      2'b00:   next_state = 2'b01;
      2'b01:   next_state = 2'b10;
      2'b10:   next_state = 2'b11;
      2'b11:   next_state = 2'b00;
      default: next_state = state;
    endcase
  end

  always @* begin
    next_out1 = 1'b0;
    next_out2 = 1'b0;
    if (state == 2'b00 || state == 2'b01) next_out1 = 1;
    if (state == 2'b10 || state == 2'b11) next_out2 = 1;
  end
endmodule

module tb_test;
  reg clk, rst;
  wire out1, out2;

  initial begin
    clk = 0;
    rst = 1;
    #7 rst = 0;
  end

  initial begin
    $dumpfile("out.vcd");
    $dumpvars;
    #100 $finish;
  end

  always #5 clk = ~clk;

  test DUT (
      .clk (clk),
      .rst (rst),
      .out1(out1),
      .out2(out2)
  );
endmodule
