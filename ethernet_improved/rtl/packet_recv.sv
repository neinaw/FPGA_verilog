`timescale 1 ns / 1 ps

module packet_recv #(
    parameter [47:0] FPGA_MAC   = 48'h00_18_3e_04_b3_f2,
    parameter        DATA_WIDTH = 8,
    parameter        DEPTH      = 1024
) (
    input logic [1:0] RXD,
    input logic       RXDV,

    input logic clk,
    input logic rst,

    // header output
    output logic        header_valid,
    output logic [47:0] dest_mac,
    output logic [47:0] src_mac,
    output logic [15:0] ethertype,
    input  logic        header_rd,

    // data output
    output logic                    m_axis_tvalid,
    output logic [DATA_WIDTH-1 : 0] m_axis_tdata,
    output logic                    m_axis_tlast,
    input  logic                    m_axis_tready
);

  localparam [47:0] BROADCAST = 48'hFF_FF_FF_FF_FF_FF;

  localparam ADDR_SPACE_EXP = $clog2(DEPTH);

  logic [2:0][1:0] rxd_z;
  logic [2:0]                rxdv_z;

  always @(posedge clk) begin
    if (rst) begin
      rxd_z  <= 0;
      rxdv_z <= 0;
    end else begin
      rxd_z[0] <= RXD;
      rxd_z[2:1] <= rxd_z[1:0];

      rxdv_z[0] <= RXDV;
      rxdv_z[2:1] <= rxdv_z[1:0];
    end
  end

  typedef struct packed {
    // Ethernet Frame Header
    // no FCS, added later
    logic [1:0][7:0] eth_type_length;
    logic [5:0][7:0] mac_source;
    logic [5:0][7:0] mac_destination;
  } ethernet_header;

  // write in received data until packet has ended
  // this occurs when rxdv goes low.

  logic packet_done;
  logic packet_start;
  assign packet_start = (rxdv_z[2] == 0 && rxdv_z[1] == 1) ? 1 : 0;
  assign packet_done  = (rxdv_z[2] == 1 && rxdv_z[1] == 0) ? 1 : 0;
  logic crc_en;
  logic crc_rst, next_crc_rst;
  logic [3:0][7:0] running_crc;
  logic bad_frame;

  //dividing by 2 since we Rx/Tx 2 bits at a time
  localparam HEADER_CYCLES = $bits(ethernet_header) / 2;
  localparam PREAMBLE_SFD_CYCLES = 8 * 8 / 2;
  // localparam FCS_CYCLES = 4 * 8 / 2;

  // header and state buffers
  logic [ 7:0] data_buffer;
  logic [63:0] preamble_sfd_buffer;
  logic [63:0] preamble_sfd_buffer_next;
  ethernet_header header_buffer;

  // State machine
  typedef enum {
    IDLE,
    PREAMBLE_SFD,
    HEADER,
    DATA
  } state_type;

  state_type current_state = IDLE;
  state_type next_state    = IDLE;

  // count the time spent in each state
  logic [31:0]  state_counter;

  always_ff @(posedge clk) begin
    if (rst) begin
      state_counter <= '0;

    end else begin
      if (current_state != next_state) begin
        state_counter <= '0;

      end else begin
        // otherwise increment counter and shift buffer
        state_counter <= state_counter + 1'b1;
      end
    end
  end

  logic [47:0] packet_destination;

  assign packet_destination = {<<8{header_buffer.mac_destination}};

  always_comb begin
    next_state = current_state;
    crc_en = 1'b0;
    case (current_state)
      IDLE: begin
        if (packet_start) begin
          next_state = PREAMBLE_SFD;
        end
      end
      PREAMBLE_SFD: begin
        if (preamble_sfd_buffer_next == 64'hd555555555555555) begin
          next_state = HEADER;
        end
      end
      HEADER: begin
        crc_en = 1'b1;
        if (state_counter == HEADER_CYCLES - 1) begin
          next_state = DATA;
        end

        // packet has ended, go back to IDLE
        if (packet_done) next_state = IDLE;
      end
      DATA: begin
        crc_en = 1'b1;
        if (packet_destination != FPGA_MAC) next_state = IDLE;
        // uncomment below line later
        // if (packet_destination != BROADCAST) next_state = IDLE;
        // packet has ended, go back to IDLE
        if (packet_done) next_state = IDLE;
      end
      default: next_state = current_state;
    endcase
  end


  //2) register into that state
  always_ff @(posedge clk) begin
    if (rst) begin
      current_state <= IDLE;
    end else begin
      current_state <= next_state;
    end

  end

  logic data_last;

  logic h_fifo_empty;
  logic h_fifo_wr, next_h_fifo_wr;
  logic [111 : 0] h_fifo_wr_data, next_h_fifo_wr_data, h_fifo_rd_data;
  logic d_fifo_ready;

  assign preamble_sfd_buffer_next[63:62] = rst ? 0 : rxd_z[2];
  assign preamble_sfd_buffer_next[61:0]  = rst ? 64'b0 : preamble_sfd_buffer[63:2];

  // populate and shift buffers according to state
  logic [7:0] data_pipe [4];
  logic [15:0] valid_pipe;
  // logic rst_valid_pipe;
  assign data_last = packet_done;
  always_ff @(posedge clk) begin
    if (rst == 1) begin
      preamble_sfd_buffer <= 0;
      header_buffer       <= 0;
      data_buffer         <= 0;
      valid_pipe          <= 0;
      crc_rst <= 0;
    end else begin
      crc_rst <= next_crc_rst;
      

      case (current_state)
        PREAMBLE_SFD: begin
          preamble_sfd_buffer <= preamble_sfd_buffer_next;
        end

        HEADER: begin
          header_buffer[(HEADER_CYCLES*2)-1-:2] <= rxd_z[2];
          header_buffer[(HEADER_CYCLES*2)-3:0]  <= header_buffer[(HEADER_CYCLES*2)-1:2];
        end

        DATA: begin
          if(state_counter[1:0] == 'd3) begin
            data_pipe[0] <= {rxd_z[2], data_buffer[7:2]};
            data_pipe[1] <= data_pipe[0];
            data_pipe[2] <= data_pipe[1];
            data_pipe[3] <= data_pipe[2];

            valid_pipe <= {valid_pipe[14:0], 1'b1};
          end else begin
            data_buffer[7:6] <= rxd_z[2];
            data_buffer[5:0] <= data_buffer[7:2];
            valid_pipe <= {valid_pipe[14:0], 1'b0};
          end

        end

      endcase
      if(crc_rst) valid_pipe <= 0;
    end
  end

  wire rst_crc_gen = rst | crc_rst;
  crc_gen crc_rx (
      .data_in(rxd_z[2]),
      .crc_en(crc_en),
      .crc_out(running_crc),
      .rst(rst_crc_gen),
      .clk(clk)
  );

  logic [15:0] local_ethertype;
  logic [47:0] local_dest_mac, local_src_mac;

  endian_switch #(
      .INPUT_BYTES(2)
  ) type_switch (
      .in (header_buffer.eth_type_length),
      .out(local_ethertype)
  );

  endian_switch #(
      .INPUT_BYTES(6)
  ) src_switch (
      .in (header_buffer.mac_source),
      .out(local_src_mac)
  );

  endian_switch #(
      .INPUT_BYTES(6)
  ) dest_switch (
      .in (header_buffer.mac_destination),
      .out(local_dest_mac)
  );

  always_comb begin
    bad_frame = 1'b0;
    next_crc_rst = 1'b0;
    h_fifo_wr = 1'b0;
    h_fifo_wr_data = '0;

    if (current_state != IDLE && next_state == IDLE) next_crc_rst = 1'b1;
    if (packet_done && running_crc != 32'h2144DF1C) bad_frame = 1'b1;

    if (packet_done && ~bad_frame) begin
      // will header buffer ever be full before data?
      // only write if data fifo is ready
      if (d_fifo_ready) begin
        h_fifo_wr = 1'b1;
        h_fifo_wr_data = {local_dest_mac, local_src_mac, local_ethertype};
      end
    end
  end

  fwft_fifo #(
      .DATA_WIDTH(48 + 48 + 16)
  ) header_fifo (
      .clk(clk),
      .rst(rst),

      .wr_en(h_fifo_wr),
      .rd_en(header_rd),
      .din(h_fifo_wr_data),
      .dout(h_fifo_rd_data),
      .empty(h_fifo_empty),
      .full()
  );

  assign dest_mac = h_fifo_rd_data[111-:48];
  assign src_mac = h_fifo_rd_data[111-48-:48];
  assign ethertype = h_fifo_rd_data[111-48-48 : 0];
  assign header_valid = ~h_fifo_empty;

  axis_fifo_atomic #(
      .DATA_WIDTH(DATA_WIDTH),
      .ADDR_WIDTH($clog2(DEPTH))
  ) data_fifo (
      .clk(clk),
      .rst(rst),

      .s_axis_tdata(data_pipe[3]),
      .s_axis_tvalid(valid_pipe[15]),
      .s_axis_tlast(data_last),
      .s_axis_tready(d_fifo_ready),
      .s_axis_tuser(bad_frame),

      .m_axis_tdata (m_axis_tdata),
      .m_axis_tvalid(m_axis_tvalid),
      .m_axis_tlast (m_axis_tlast),
      .m_axis_tready(m_axis_tready)
  );

endmodule
