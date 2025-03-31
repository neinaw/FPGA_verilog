`timescale 1ns / 1ps
module tb_eth_top;
  logic CLK;  // global 100MHz clock
  logic RST_N;  // external reset button ACTIVE LOW
  logic ETH_MDC;
  logic ETH_MDIO;
  logic ETH_RSTN;  // PHY reset, driven by MAC
  logic ETH_CRSDV;  // why inout?
  logic ETH_RXERR;  // NC
  logic [1:0] ETH_RXD;
  logic ETH_TXEN;
  logic [1:0] ETH_TXD;
  logic ETH_REFCLK;
  logic ETH_INTN;

  initial begin
    CLK   = 0;
    RST_N = 0;
    #7 RST_N = 1;
  end

  always #5 clk = ~clk;
  assign ETH_MDC   = 0;
  assign ETH_MDIO  = 0;
  assign ETH_RXERR = 0;

  eth_top dut (.*);
endmodule
