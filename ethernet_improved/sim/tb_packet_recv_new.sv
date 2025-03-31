`timescale 1ns / 1ns

import ethernet_header_pkg::*;

module tb_packet_recv_new;
  logic clk, rst;

  always #10 clk = ~clk;  //20ns or 50MHz clk

  logic [1:0] RXD;
  logic RXDV;
  // logic bad_frame;

  //output signals from the DUT
  logic    m_axis_tvalid;
  logic [7 : 0]   m_axis_tdata;
  logic    m_axis_tlast;
  logic    m_axis_tready;

  logic header_valid;
  logic header_rd;
  logic [47:0] dest_mac;
  logic [47:0] src_mac;
  logic [15:0] ethertype;

  task static initialize();
    clk = 0;
    rst = 1;
    RXDV = 0;
    RXD = '0;
    header_rd = 1'b0;
    #17 rst = 0;
  endtask

  typedef struct packed {
    logic [6:0][7:0]  pre;
    logic [7:0]       sfd;
    logic [5:0][7:0]  dest_mac;
    logic [5:0][7:0]  src_mac;
    logic [1:0][7:0]  len;
    logic [63:0][7:0] payload;
    logic [3:0][7:0]  fcs;
  } frame_t;

  // total cycles to transmit
  frame_t frame;

  function automatic logic [7:0] reverse_bits(input logic [7:0] my_byte);
    logic [7:0] reversed_byte;

    for (int i = 0; i < 8; i++) begin
      reversed_byte[i] = my_byte[7-i];
    end

    return reversed_byte;
  endfunction : reverse_bits

  function automatic frame_t build_frame_llc(
      input logic [5:0][7:0] dest_mac = 48'h00_18_3e_04_b3_f2,
      input logic [5:0][7:0] src_mac = 48'h54_e1_ad_33_0d_32,
      input logic [1:0][7:0] ethertype = 16'h0040,
      input logic [63:0][7:0] payload = {{63{8'hAA}}, {8'hFF}},
      input logic [3:0][7:0] fcs = 32'hDA_87_4E_20);

    // LLC frame
    frame_t frame;
    frame.pre = {7{8'h55}};  //LSB first
    frame.sfd = 8'hd5;
    frame.dest_mac = dest_mac;
    frame.src_mac = src_mac;
    frame.len = ethertype;
    frame.payload = payload;
    frame.fcs = fcs;

    foreach (frame.pre[i]) begin
      frame.pre[i] = reverse_bits(frame.pre[i]);
    end
    frame.sfd = reverse_bits(frame.sfd);
    foreach (frame.dest_mac[i]) begin
      frame.dest_mac[i] = reverse_bits(frame.dest_mac[i]);
    end
    foreach (frame.src_mac[i]) begin
      frame.src_mac[i] = reverse_bits(frame.src_mac[i]);
    end
    foreach (frame.len[i]) begin
      frame.len[i] = reverse_bits(frame.len[i]);
    end
    foreach (frame.payload[i]) begin
      frame.payload[i] = reverse_bits(frame.payload[i]);
    end
    foreach (frame.fcs[i]) begin
      frame.fcs[i] = reverse_bits(frame.fcs[i]);
    end

    return frame;
  endfunction : build_frame_llc

  // task automatic tx_frame(input frame_t frame  /*, ref logic [1:0] RXD, ref logic RXDV*/);
  //   if (rst) @(negedge rst);

  //   @(negedge clk);
  //   RXDV = 1;
  //   for (int i = $bits(frame_t) - 8; i >= 0; i -= 8) begin
  //     for (int j = 0; j < 8; j += 2) begin
  //       $display("Transmit: [%d], [%d]  = %b, %b", i, j, frame[i+j+1], frame[i+j]);
  //       RXD[1] = frame[i+(j+1)];
  //       RXD[0] = frame[i+j];
  //       @(posedge clk);
  //     end
  //   end
  //   RXDV = 0;
  // endtask : tx_frame

  task automatic tx_frame(input frame_t frame);
    int count = 0;
    if (rst) @(negedge rst);

    @(negedge clk);
    RXDV <= 1;
    for (int i = $bits(frame) - 1; i >= 0; i -= 2) begin
      RXD[1] <= frame[i-1];
      RXD[0] <= frame[i];
      count += 1;
      @(posedge clk);
    end
    RXDV <= 0;
  endtask

  task automatic frame_gap();
    for (int i = 0; i < 96; i++) begin
      RXDV <= 0;
      @(posedge clk);
    end
  endtask

  initial begin
    fork
      initialize();
      frame = build_frame_llc(.payload({{63{8'hAA}}, {8'hFF}}), .fcs(32'hDA_87_4E_20));
      tx_frame(frame);
    join
    frame_gap();
    frame = build_frame_llc(.payload(), .fcs(32'h0));
    tx_frame(frame);
  end
  assign m_axis_tready = 1'b0;

  packet_recv DUT (.*);
endmodule

