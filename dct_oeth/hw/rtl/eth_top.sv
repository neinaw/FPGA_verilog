`timescale 1ns / 1ps

module eth_top(
    input CLK, // global 100MHz clock
    input RST_N, // external reset button ACTIVE LOW
    output ETH_MDC,
    inout ETH_MDIO,
    output ETH_RSTN, // PHY reset, driven by MAC
    input ETH_CRSDV, // why inout?
    input ETH_RXERR, // NC
    input [1:0] ETH_RXD, 
    output ETH_TXEN,
    output [1:0] ETH_TXD,
    output ETH_REFCLK,
    input ETH_INTN //NC
);

  logic rst;

  rst_gen rst_gen_i(
     .clk_in(CLK), // global clk
     .rst_in(~RST_N),
     .rst_out(rst) // active high reset in 100MHz domain

    );

    logic eth_clk; // 50MHz 0deg clock
    logic eth_rst; // reset in 50MHz 0deg domain for MAC
    
//    logic M_AXIS_TVALID;
//    logic [7:0] M_AXIS_TDATA;
//    logic M_AXIS_TLAST;
//    logic M_AXIS_TREADY;
    
    logic [7:0] tdata_in, tdata_out;
    logic tvalid_in, tvalid_out;
    logic tlast_in, tlast_out;
    logic tready_in, tready_out;

    packet_recv receiver(
        .RXD(ETH_RXD),
        .RXDV(ETH_CRSDV),
        .clk(eth_clk),
        .rst(eth_rst),
        .m_axis_tvalid(tvalid_in),
        .m_axis_tdata(tdata_in),
        .m_axis_tlast(tlast_in),
        .m_axis_tready(tready_in)
    );
    
    packet_tx transmitter(
        .clk(eth_clk),
        .rst(eth_rst),
        .s_axis_tdata(tdata_out),
        .s_axis_tvalid(tvalid_out),
        .s_axis_tlast(tlast_out),
        .s_axis_tready(tready_out),
        .tx_en(ETH_TXEN),
        .txd(ETH_TXD)
    ); 
//    ila_0 trasmit_debugger (
//	.clk(eth_clk), // input wire clk


//	.probe0(M_AXIS_TDATA), // input wire [7:0]  probe0  
//	.probe1(M_AXIS_TVALID), // input wire [0:0]  probe1 
//	.probe2(M_AXIS_TREADY), // input wire [0:0]  probe2 
//	.probe3(M_AXIS_TLAST), // input wire [0:0]  probe3 
//	.probe4(ETH_TXD), // input wire [1:0]  probe4 
//	.probe5(ETH_TXEN) // input wire [0:0]  probe5
//);
dct_stream_0 dct_unit (
  .ap_clk(eth_clk),                        // input wire ap_clk
  .ap_rst_n(~eth_rst),                    // input wire ap_rst_n
  .in_stream_TDATA(tdata_in),      // input wire [7 : 0] in_stream_TDATA
  .in_stream_TLAST(tlast_in),      // input wire [0 : 0] in_stream_TLAST
  .in_stream_TREADY(tready_in),    // output wire in_stream_TREADY
  .in_stream_TVALID(tvalid_in),    // input wire in_stream_TVALID
  .out_stream_TDATA(tdata_out),    // output wire [7 : 0] out_stream_TDATA
  .out_stream_TLAST(tlast_out),    // output wire [0 : 0] out_stream_TLAST
  .out_stream_TREADY(tready_out),  // input wire out_stream_TREADY
  .out_stream_TVALID(tvalid_out)  // output wire out_stream_TVALID
);

    // No mdio interface
    assign ETH_MDC = 0;

  eth_rst_gen eth_rst_gen_i(
     .clk(CLK),
     .rst(rst),
     .eth_clk_out(eth_clk),
     .eth_rst_out(eth_rst),
     .ETH_REFCLK(ETH_REFCLK),
     .ETH_RSTN(ETH_RSTN)
    );
endmodule
