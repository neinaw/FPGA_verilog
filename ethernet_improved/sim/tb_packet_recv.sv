`timescale 1ns / 1ns

import ethernet_header_pkg::*;

module tb_packet_recv;
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
    m_axis_tready = 0;
    header_rd = 1'b0;
    #17 rst = 0;
  endtask

  typedef struct packed {
    logic [55:0] pre;
    logic [7:0] sfd;
    logic [47:0] dest;
    logic [47:0] src;
    logic [15:0] len;
    logic [63:0][7:0] payload;
    logic [31:0] fcs;
  } frame_t;
  frame_t frame;
  initial begin
    fork
      begin
        initialize();
      end
      begin
        frame.pre = {7{8'h55}};  //LSB first
        frame.sfd = 8'hd5;
        frame.dest = 48'h00_18_3e_04_b3_f2;
        // frame.dest = 48'hFF_FF_FF_FF_FF_FA;
        frame.src = 48'h54_e1_ad_33_0d_32;
        frame.len = 16'h0040;
        frame.payload[63-:63] = {63{8'hAA}};
        frame.payload[0] = {8'hFF};
        frame.fcs = 32'hDA_87_4E_20;
      end
    join
    @(negedge RXDV);
    #110 m_axis_tready = 1'b1;
    header_rd = 1'b1;
    // frame.fcs = 32'hFFFF_FFFF;
  end

  logic [7:0] transmit_buffer = '0;
  logic [7:0] next_transmit_buffer;
  logic [9:0] counter = '0;

  always_ff @(posedge clk) begin
    if (rst) begin
      counter <= '0;
    end else begin
      counter <= counter + 1'b1;
    end
  end

  always_ff @(posedge clk) begin
    transmit_buffer <= next_transmit_buffer;
    if (~rst) frame <= frame << 2;
  end

  always_comb begin
    if (counter <= 10'd360) RXDV = 1'b1;
    else RXDV = 1'b0;
  end

  assign next_transmit_buffer = (counter[1:0] == 2'b00) ? frame[$bits(
      frame
  )-1-:8] : transmit_buffer >> 2;
  assign RXD = transmit_buffer[1:0];
  // assign RXDV = (frame.pre == '0) ? 1'b0 : 1'b1;

  packet_recv DUT (.*);
endmodule
