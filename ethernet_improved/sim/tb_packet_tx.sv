`timescale 1ns / 1ps

import ethernet_header_pkg::*;

module tb_packet_tx;

  logic clk, rst;

  // input signals
  logic [7:0] s_axis_tdata;
  logic s_axis_tvalid;
  logic s_axis_tlast;
  logic s_axis_tready;

  // logic [111:0] header;
  ethernet_header header;
  logic header_valid;
  logic header_rd;

  // output signals
  logic tx_en;
  logic [1:0] txd;

  initial begin
    clk = 0;
  end

  always #5 clk = ~clk;

  initial begin
    rst = 1;
    #7 rst = 0;
  end

  task automatic initialize();
    s_axis_tvalid <= 0;
    s_axis_tlast <= 0;
    s_axis_tdata <= '0;

    header <= '0;
    header_valid <= 0;
    // header_rd <= 0;
  endtask

  // task automatic make_header(input logic [47:0] dest_mac, src_mac, input logic [15:0] ether_type);
  //   header <
  // endtask

  task automatic axis_write_packet(input logic [7:0] word = 'hAA, input int len = 64);
    int i;
    if (rst) @(negedge rst);

    @(posedge clk);
    header <= {96'h54e1ad330d32_00183e04b3f2, 16'(len)};
    // header <= 112'h54e1ad330d32_00183e04b3f2_0001;
    // header.eth_type_length <= 16'h002e;
    // header.mac_source <= 48'h00_18_3e_04_b3_f2;
    // header.mac_destination <= 48'h54_e1_ad_33_0d_32;
    // header <= '1;
    header_valid <= 1;

    for (i = 0; i < len; i++) begin
      s_axis_tvalid <= 1;
      s_axis_tdata  <= (i == len - 1) ? 'hFF : word;
      s_axis_tlast  <= (i == len - 1) ? 1 : 0;
      while (~s_axis_tready);
      @(posedge clk);
    end

    s_axis_tvalid <= 0;
    s_axis_tlast <= 0;
    s_axis_tdata <= '0;

    header <= '0;
    header_valid <= 0;
  endtask

  packet_tx TX_DUT (.*);
  initial begin
    initialize();
    @(negedge rst);
    #15;
    // fork
    //   axis_write_packet(.len(46));
    //   axis_write_packet(.len(1));
    // join
    axis_write_packet(.len(46));
    axis_write_packet(.len(1));
    axis_write_packet(.len(100));
  end
endmodule
