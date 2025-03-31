`timescale 1ns / 1ps

module eth_top (
    input CLK,  // global 100MHz clock
    input RST_N,  // external reset button ACTIVE LOW
    output ETH_MDC,
    inout ETH_MDIO,
    output ETH_RSTN,  // PHY reset, driven by MAC
    inout ETH_CRSDV,  // why inout?
    input ETH_RXERR,  // NC
    inout [1:0] ETH_RXD,
    output ETH_TXEN,
    output [1:0] ETH_TXD,
    output ETH_REFCLK,
    input ETH_INTN  //NC
);

  logic rst;

  rst_gen rst_gen_i (
      .clk_in(CLK),  // global clk
      .rst_in(~RST_N),
      .rst_out(rst)  // active high reset in 100MHz domain

  );

  logic eth_clk;  // 50MHz 0deg clock
  logic eth_rst;  // reset in 50MHz 0deg domain for MAC

  logic M_AXIS_TVALID;
  logic [7:0] M_AXIS_TDATA;
  logic M_AXIS_TLAST;
  logic M_AXIS_TREADY;

  logic header_valid;
  logic header_rd;
  logic [47:0] dest_mac, src_mac;
  logic [15:0] ethertype;


  packet_recv receiver (
      .RXD (ETH_RXD),
      .RXDV(ETH_CRSDV),
      .clk (eth_clk),
      .rst (eth_rst),

      .header_valid(header_valid),
      .dest_mac(dest_mac),
      .src_mac(src_mac),
      .ethertype(ethertype),
      .header_rd(header_rd),

      .m_axis_tvalid(M_AXIS_TVALID),
      .m_axis_tdata (M_AXIS_TDATA),
      .m_axis_tlast (M_AXIS_TLAST),
      .m_axis_tready(M_AXIS_TREADY)
  );

  // localparam [47:0] dest = 48'h54_e1_ad_33_0d_32;
  // localparam [47:0] broadcast = {6{8'hFF}};
  packet_tx transmitter (
      .clk(eth_clk),
      .rst(eth_rst),
      .s_axis_tdata(M_AXIS_TDATA),
      .s_axis_tvalid(M_AXIS_TVALID),
      .s_axis_tlast(M_AXIS_TLAST),
      .s_axis_tready(M_AXIS_TREADY),

      .header({src_mac, dest_mac, ethertype}),
      .header_valid(header_valid),
      .header_rd(header_rd),

      .tx_en(ETH_TXEN),
      .txd  (ETH_TXD)
  );
  //  ila_0 debug_i (
  //	.clk(eth_clk), // input wire clk


  //	.probe0(ETH_TXEN), // input wire [0:0]  probe0  
  //	.probe1(header_rd), // input wire [0:0]  probe1 
  //	.probe2(dest_mac), // input wire [47:0]  probe2 
  //	.probe3(src_mac), // input wire [47:0]  probe3 
  //	.probe4(ethertype), // input wire [15:0]  probe4 
  //	.probe5(M_AXIS_TVALID), // input wire [0:0]  probe5 
  //	.probe6(M_AXIS_TDATA), // input wire [7:0]  probe6 
  //	.probe7(M_AXIS_TLAST), // input wire [0:0]  probe7 
  //	.probe8(M_AXIS_TREADY) // input wire [0:0]  probe8
  //);

  // No mdio interface
  assign ETH_MDC = 0;

  eth_rst_gen eth_rst_gen_i (
      .clk(CLK),
      .rst(rst),
      .eth_clk_out(eth_clk),
      .eth_rst_out(eth_rst),
      .ETH_REFCLK(ETH_REFCLK),
      .ETH_RSTN(ETH_RSTN)
  );
endmodule

