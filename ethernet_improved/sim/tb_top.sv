`timescale 1ns / 1ps

import ethernet_header_pkg::*;

module tb_top;

  logic clk, rst;
  always #10 clk = ~clk;

  logic [1:0] RXD;
  logic RXDV;

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
    #17 rst = 0;
  endtask

  typedef struct {
    logic [6:0][7:0]  pre;
    logic [0:0][7:0]  sfd;
    logic [5:0][7:0]  dest;
    logic [5:0][7:0]  src;
    logic [1:0][7:0]  len;
    logic [3:0][7:0]  fcs;
  } frame_t;

  // task automatic generate_frame(input [47:0] dst_mac, input [47:0] src_mac, input [15:0] len,
  //                               input int payload_bytes, input [31:0] fcs);


  //   logic [7:0] payload[];
  //   payload = new[payload_bytes];
  //   test_frame.payload = payload;
  //   foreach (test_frame.payload[i]) begin
  //     test_frame.payload[i] = (i == payload_bytes - 1) ? 8'hFF : 8'hAA;
  //   end

  //   test_frame.pre = {7{8'h55}};
  //   test_frame.sfd = 'hd5;
  //   test_frame.dest = dst_mac;
  //   test_frame.srd = src_mac;
  //   test_frame.len = len;
  //   test_frame.fcs = fcs;

  //   payload_size = payload_bytes;
  // endtask

  frame_t test_frame;
  logic [7:0] transmit_buffer;
  logic [21:0][7:0] start;
  task static transmit_frame(input [5:0][7:0] dst_mac = 48'h54_e1_ad_33_0d_32,
                                input [5:0][7:0] src_mac = 48'h00_18_3e_04_b3_f2,
                                input [1:0][7:0] len = '0,
                                input int payload_bytes = 0,
                                input [3:0][7:0] fcs = '0
  );

    int byte_count;

    if (rst) @(negedge rst);
    test_frame.pre  = {7{8'h55}};
    test_frame.sfd  = 'hd5;
    test_frame.dest = dst_mac;
    test_frame.src  = src_mac;
    test_frame.len  = len;
    test_frame.fcs  = fcs;
    start = {test_frame.pre, test_frame.sfd, test_frame.dest, test_frame.src, test_frame.len};

    byte_count = 7 + 1 + 6 + 6 + 2 + payload_bytes + 4;

    @(negedge clk);
    RXDV <= '0;


    @(posedge clk);
    for (int i=0; i<22; i++) begin
      transmit_buffer <= start[i];
      for (int i=0; i<4; i++) begin
        RXD <= transmit_buffer[1:0];
        transmit_buffer <= transmit_buffer >> 2;
        @(posedge clk);
      end
    end
    // for (int i = 0; i < 7; i++) begin
    //   transmit_buffer <= test_frame.pre[i];
    //   for (int j = 0; j < 4; j++) begin
    //     transmit_buffer <= transmit_buffer >> 2;
    //     RXD <= transmit_buffer[1:0];
    //     @(posedge clk);
    //   end
    // end

    // for (int i = 0; i < 1; i++) begin
    //   transmit_buffer <= test_frame.sfd[i];
    //   for (int j = 0; j < 4; j++) begin
    //     transmit_buffer <= transmit_buffer >> 2;
    //     RXD <= transmit_buffer[1:0];
    //     @(posedge clk);
    //   end
    // end

    // for (int i = 0; i < 6; i++) begin
    //   transmit_buffer <= test_frame.dest[i];
    //   for (int j = 0; j < 4; j++) begin
    //     transmit_buffer <= transmit_buffer >> 2;
    //     RXD <= transmit_buffer[1:0];
    //     @(posedge clk);
    //   end
    // end

    // for (int i = 0; i < 6; i++) begin
    //   transmit_buffer <= test_frame.src[i];
    //   for (int j = 0; j < 4; j++) begin
    //     transmit_buffer <= transmit_buffer >> 2;
    //     RXD <= transmit_buffer[1:0];
    //     @(posedge clk);
    //   end
    // end

    // for (int i = 0; i < 6; i++) begin
    //   transmit_buffer <= test_frame.dest[i];
    //   for (int j = 0; j < 4; j++) begin
    //     transmit_buffer <= transmit_buffer >> 2;
    //     RXD <= transmit_buffer[1:0];
    //     @(posedge clk);
    //   end
    // end

    // RXDV <= '0;

  endtask

  initial begin
    fork
      initialize();
      transmit_frame(.len('h0040), .payload_bytes(64), .fcs(32'hDA_87_4E_20));
      // begin
      //   initialize();
      // end
      // begin
      // frame.pre = {7{8'h55}};  //LSB first
      // frame.sfd = 8'hd5;
      // frame.dest = 48'h00_18_3e_04_b3_f2;
      // // frame.dest = 48'hFF_FF_FF_FF_FF_FA;
      // frame.src = 48'h54_e1_ad_33_0d_32;
      // frame.len = 16'h0040;
      // frame.payload[63-:63] = {63{8'hAA}};
      // frame.payload[0] = {8'hFF};
      // frame.fcs = 32'hDA_87_4E_20;
      // end
    join
    @(negedge RXDV);
  end

  // logic [7:0] transmit_buffer = '0;
  // logic [7:0] next_transmit_buffer;
  // logic [9:0] counter = '0;

  // always_ff @(posedge clk) begin
  //   if (rst) begin
  //     counter <= '0;
  //   end else begin
  //     counter <= counter + 1'b1;
  //   end
  // end

  // always_ff @(posedge clk) begin
  //   transmit_buffer <= next_transmit_buffer;
  //   if (~rst) frame <= frame << 2;
  // end

  // always_comb begin
  //   if (counter <= 10'd360) RXDV = 1'b1;
  //   else RXDV = 1'b0;
  // end

  // assign next_transmit_buffer = (counter[1:0] == 2'b00) ? frame[$bits(
  //     frame
  // )-1-:8] : transmit_buffer >> 2;
  // assign RXD = transmit_buffer[1:0];
  // // assign RXDV = (frame.pre == '0) ? 1'b0 : 1'b1;

  logic tx_en;
  logic [1:0] txd;
  // // logic [7:0] rx_echo;

  packet_recv rx_unit (.*);
  packet_tx tx_unit (
      .clk(clk),
      .rst(rst),

      .s_axis_tdata (m_axis_tdata),
      .s_axis_tvalid(m_axis_tvalid),
      .s_axis_tlast (m_axis_tlast),
      .s_axis_tready(m_axis_tready),

      .header({src_mac, dest_mac, ethertype}),
      .header_valid(header_valid),
      .header_rd(header_rd),
      .tx_en(tx_en),
      .txd(txd)
  );
endmodule
