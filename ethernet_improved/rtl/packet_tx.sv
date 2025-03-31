`timescale 1ns / 1ps

import ethernet_header_pkg::*;

module packet_tx #(
    parameter MII_WIDTH  = 2,
    parameter WORD_BYTES = 1   // bytes per word
) (
    input clk,
    input rst,

    // data in
    input  [WORD_BYTES*8-1:0] s_axis_tdata,
    input                     s_axis_tvalid,
    input                     s_axis_tlast,
    output                    s_axis_tready,

    // header in
    input  logic [111:0] header,
    input  logic         header_valid,
    output logic         header_rd,

    output logic                 tx_en,
    output logic [MII_WIDTH-1:0] txd
);

  logic [$bits(ethernet_header)-1 : 0] header_tx_order;
  eth_header_gen header_gen (
      .src_mac(h_fifo_data[111-48-:48]),
      .dst_mac(h_fifo_data[111-:48]),
      .ethertype(h_fifo_data[15:0]),
      .output_header(header_tx_order)
  );

  // localparam PACKET_PAYLOAD_BYTES = PACKET_PAYLOAD_WORDS * WORD_BYTES;

  // create a first
  logic s_axis_tfirst;

  always_ff @(posedge clk) begin
    if (rst) s_axis_tfirst <= 1;

    else begin
      if (s_axis_tvalid && s_axis_tready) begin
        if (s_axis_tlast)
          // After tlast pulse, drive first high
          s_axis_tfirst <= 1;

        else
          // otherwise, drive it low on valid and ready
          s_axis_tfirst <= 0;
      end
    end
  end


  // header and state buffers
  ethernet_header                                header;
  logic           [$bits(ethernet_header)-1 : 0] header_buffer;
  //ethernet_header                    header_buffer;
  logic           [            WORD_BYTES*8-1:0] data_buffer;
  logic           [                     7*8-1:0] preamble_buffer;
  logic           [                     1*8-1:0] sfd_buffer;
  logic           [                     4*8-1:0] fcs;
  logic           [                     4*8-1:0] fcs_buffer;

  // Number of bytes transferred in each stage
  localparam HEADER_BYTES = $bits(ethernet_header) / 8;
  // localparam DATA_BYTES = PACKET_PAYLOAD_BYTES;
  localparam WAIT_BYTES = 12;
  localparam SFD_BYTES = 1;
  localparam PREAMBLE_BYTES = 7;
  localparam FCS_BYTES = 4;

  // RMII interface is MII_WIDTH bits wide, so divide by MII_WIDTH to get the correct
  // number of iterations(cycles) per each stage
  localparam HEADER_LENGTH = HEADER_BYTES * 8 / MII_WIDTH;
  localparam WAIT_LENGTH = WAIT_BYTES * 8 / MII_WIDTH;
  localparam SFD_LENGTH = SFD_BYTES * 8 / MII_WIDTH;
  localparam PREAMBLE_LENGTH = PREAMBLE_BYTES * 8 / MII_WIDTH;
  localparam FCS_LENGTH = FCS_BYTES * 8 / MII_WIDTH;
  // localparam DATA_LENGTH = DATA_BYTES * 8 / MII_WIDTH;
  localparam MIN_DATA_LENGTH = 46 * 8 / MII_WIDTH;
  localparam DATA_COUNTER_BITS = $clog2(WORD_BYTES * 8 / MII_WIDTH);

  // State machine
  typedef enum {
    IDLE,
    PREAMBLE,
    SFD,
    HEADER,
    DATA,
    PAD,
    FCS,
    WAIT
  } state_type_t;

  state_type_t                    current_state = IDLE;
  state_type_t                    next_state = IDLE;

  // Data fifo
  logic                           fifo_full;
  logic                           fifo_empty;
  logic        [             9:0] fifo_count;
  logic        [WORD_BYTES*8-1:0] fifo_out;
  logic                           fifo_rd_en;
  logic                           fifo_wr_en;
  logic                           packet_start_valid;
  logic                           packet_valid;
  logic                           fifo_has_space;

  localparam FIFO_DEPTH = 1024;

  logic h_fifo_has_space;
  logic h_fifo_full;
  // assign fifo_has_space = (fifo_count < FIFO_DEPTH - PACKET_PAYLOAD_BYTES) ? 1 : 0;
  assign fifo_has_space = (fifo_count < FIFO_DEPTH - 'd46) ? 1 : 0;
  assign h_fifo_has_space = ~h_fifo_full;

  // Packet start is only valid when
  // First beat of axi stream and
  // Axis Stream is valid and
  // Axis Stream is ready and
  // Space in FIFO
  // Header valid
  // Space in header FIFO
  // This indicates that this packet has space to go into the fifo
  // Otherwise, it is skipped

  // assign packet_start_valid = s_axis_tvalid && s_axis_tready && s_axis_tfirst && fifo_has_space;
  assign packet_start_valid = s_axis_tvalid && s_axis_tready && s_axis_tfirst && fifo_has_space && h_fifo_has_space && header_valid;

  // create packet_valid flag
  always_ff @(posedge clk) begin
    if (rst) begin
      packet_valid <= 0;

    end else begin
      // If the start of this packet is valid
      if (packet_start_valid) begin
        // The entire packet is valid
        packet_valid <= 1;

      end

      // If this is the end of a valid packet
      if (packet_valid && s_axis_tvalid && s_axis_tready && s_axis_tlast) begin
        // End of valid packet
        packet_valid <= 0;
      end
    end
  end

  logic h_fifo_wr_en, h_fifo_rd_en;
  assign header_rd = h_fifo_wr_en;

  // only write a valid packet
  assign fifo_wr_en = s_axis_tvalid & s_axis_tready & (packet_start_valid || packet_valid);
  assign h_fifo_wr_en = packet_start_valid;

  // ready if fifo has space
  assign s_axis_tready = (fifo_has_space & s_axis_tfirst) | packet_valid;

  // Get header
  // eth_header_gen #(
  //     .SOURCE_MAC(SOURCE_MAC),
  //     .DEST_MAC(DEST_MAC),
  //     .PACKET_PAYLOAD_BYTES(PACKET_PAYLOAD_BYTES)
  // ) eth_header_gen (
  //     .output_header(header)

  // );
  logic [111:0] h_fifo_data;
  //  assign header = h_fifo_data;
  //  assign header.mac_destination = h_fifo_data[111-:48];
  //  assign header.mac_source = h_fifo_data[111-48-:48];
  //  assign header.eth_type_length = h_fifo_data[15:0];

  // data FIFO
  fifo #(
      .DATA_SIZE(8),
      .MAX_DEPTH(FIFO_DEPTH)
  ) data_fifo_i (
      .clk(clk),
      .rst(rst),
      .write_data_in(s_axis_tdata),
      .write_to_fifo(fifo_wr_en),
      .read_from_fifo(fifo_rd_en),
      .read_data_out(fifo_out),
      .full(fifo_full),
      .empty(fifo_empty),
      .fifo_count(fifo_count)
  );

  logic [4:0] header_count;
  logic header_empty;
  fifo #(
      .DATA_SIZE(112)
  ) header_fifo_i (
      .clk(clk),
      .rst(rst),
      .write_to_fifo(h_fifo_wr_en),
      .read_from_fifo(h_fifo_rd_en),
      .write_data_in(header),
      .read_data_out(h_fifo_data),
      .full(h_fifo_full),
      .empty(header_empty),
      .fifo_count(header_count)
  );


  // count the time spent in each state
  logic [31:0] state_counter;

  always @(posedge clk) begin
    if (rst) begin
      state_counter <= '0;

    end else begin
      if (current_state != next_state) begin
        state_counter <= '0;

      end else begin
        // otherwise increment counter and shift buffer
        state_counter <= state_counter + 'd1;
      end
    end
  end

  logic zero_pad, next_zero_pad;
  logic [7:0] pad_length, next_pad_length;
  logic [17:0] packet_length, next_packet_length;
  always_comb begin
    next_zero_pad = zero_pad;
    next_pad_length = pad_length;
    next_packet_length = packet_length;
    if (current_state == SFD && next_state == HEADER) begin
      next_packet_length = {h_fifo_data[15:0], 2'b00};
      if (h_fifo_data[15:0] < 16'd46) begin
        next_zero_pad   = 1;
        next_pad_length = {16'd46 - h_fifo_data, 2'b00};
      end else begin
        next_zero_pad   = 0;
        next_pad_length = '0;
      end
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      zero_pad <= 0;
      pad_length <= '0;
      packet_length <= '0;
    end else begin
      zero_pad <= next_zero_pad;
      pad_length <= next_pad_length;
      packet_length <= next_packet_length;
    end
  end

  // 3 process state machine
  // 1) decide which state to go into next
  always_comb begin
    next_state = current_state;
    case (current_state)
      IDLE: begin
        // If there's enough data in fifo
        // if (fifo_count >= PACKET_PAYLOAD_WORDS) next_state = PREAMBLE;
        //
        // If header FIFO is not empty, and there is at least one data word
        if (~header_empty & ~fifo_empty) next_state = PREAMBLE;
      end

      PREAMBLE: begin
        if (state_counter == PREAMBLE_LENGTH - 1) next_state = SFD;
      end

      SFD: begin
        if (state_counter == SFD_LENGTH - 1) next_state = HEADER;
      end

      HEADER: begin
        if (state_counter == HEADER_LENGTH - 1) next_state = DATA;
      end

      DATA: begin
        if (state_counter == packet_length - 1) begin
          if (zero_pad) next_state = PAD;
          else next_state = FCS;
        end
      end

      PAD: begin
        if (state_counter == pad_length - 1) next_state = FCS;
      end

      FCS: begin
        if (state_counter == FCS_LENGTH - 1) next_state = WAIT;
      end

      WAIT: begin
        if (state_counter == WAIT_LENGTH - 1) next_state = IDLE;
      end

      default: next_state = current_state;
    endcase
  end

  //2) register into that state
  always @(posedge clk) begin
    if (rst) begin
      current_state <= IDLE;
    end else begin
      current_state <= next_state;
    end

  end


  // state dependant variables
  logic [MII_WIDTH-1:0] tx_data;
  logic                 tx_valid;
  logic                 fcs_en;
  logic                 fcs_rst;

  //3) drive output according to state
  always_comb begin
    case (current_state)
      IDLE: begin
        tx_valid = 0;
        tx_data  = 0;
        fcs_en   = 0;
        fcs_rst  = 1;

      end
      PREAMBLE: begin
        tx_valid = 1;
        tx_data  = preamble_buffer[MII_WIDTH-1:0];
        fcs_en   = 0;
        fcs_rst  = 0;

      end
      SFD: begin
        tx_valid = 1;
        tx_data  = sfd_buffer[MII_WIDTH-1:0];
        fcs_en   = 0;
        fcs_rst  = 0;
      end
      HEADER: begin
        tx_valid = 1;
        // tx_data  = header_buffer[111-:MII_WIDTH];
        tx_data  = header_buffer[MII_WIDTH-1:0];
        fcs_en   = 1;
        fcs_rst  = 0;

      end
      DATA: begin
        tx_valid = 1;
        tx_data  = data_buffer[MII_WIDTH-1:0];
        fcs_en   = 1;
        fcs_rst  = 0;

      end
      PAD: begin
        tx_valid = 1;
        tx_data  = 2'b00;
        fcs_en   = 1;
        fcs_rst  = 0;

      end
      FCS: begin
        tx_valid = 1;
        tx_data  = fcs_buffer[MII_WIDTH-1:0];
        fcs_en   = 0;
        fcs_rst  = 0;

      end
      WAIT: begin
        tx_valid = 0;
        tx_data  = 0;
        fcs_en   = 0;
        fcs_rst  = 0;

      end
      default: begin
        tx_valid = 0;
        tx_data  = 0;
        fcs_en   = 0;
        fcs_rst  = 0;

      end
    endcase
  end

  logic [DATA_COUNTER_BITS-1:0] data_ones;
  assign data_ones = '1;

  // populate and shift buffers according to state
  always_ff @(posedge clk) begin
    if (rst == 1) begin
      header_buffer   <= 0;
      preamble_buffer <= 0;
      fifo_rd_en      <= 0;
      // h_fifo_rd_en    <= 0;

    end else begin
      fifo_rd_en <= 0;
      // h_fifo_rd_en <= 0;

      // buffer loading
      if (current_state == IDLE) begin
        header_buffer   <= header_tx_order;
        preamble_buffer <= 56'h55555555555555;
        sfd_buffer      <= 8'hd5;
      end
      // and fcs when it's available
      if (next_state == FCS && current_state != FCS) begin
        fcs_buffer <= fcs;
      end
      // and fcs when it's available
      if (next_state == DATA && current_state != DATA) begin
        data_buffer <= fifo_out;
        fifo_rd_en  <= 1;

      end

      // shift buffers during those states
      if (current_state == HEADER) begin
        header_buffer <= header_buffer >> MII_WIDTH;
      end
      if (current_state == PREAMBLE) begin
        preamble_buffer <= preamble_buffer >> MII_WIDTH;
      end
      if (current_state == SFD) begin
        sfd_buffer <= sfd_buffer >> MII_WIDTH;
      end
      if (current_state == DATA && next_state == DATA) begin
        if (state_counter[DATA_COUNTER_BITS-1:0] == data_ones) begin
          data_buffer <= fifo_out;
          fifo_rd_en  <= 1;

        end else begin
          data_buffer <= data_buffer >> MII_WIDTH;
        end
      end
      if (current_state == FCS) begin
        fcs_buffer <= fcs_buffer >> MII_WIDTH;
        // if (next_state == WAIT) h_fifo_rd_en <= 1'b1;
      end
    end
  end

  assign h_fifo_rd_en = (current_state == FCS && next_state == WAIT);

  // crc generator
  crc_gen crc_gen_i (
      .clk(clk),
      .rst(rst || fcs_rst),

      .data_in(tx_data),
      .crc_en (fcs_en),
      .crc_out(fcs)

  );

  // Register outputs
  //drive tx interfaces

  always @(posedge clk) begin
    if (rst) begin
      tx_en <= 0;

    end else begin
      tx_en <= tx_valid;
      txd   <= tx_data;

    end

  end
  ila_0 debug_i (
      .clk(clk),  // input wire clk


      .probe0(tx_en),  // input wire [0:0]  probe0
      .probe1(header_rd),  // input wire [0:0]  probe1
      .probe2(txd),  // input wire [47:0]  probe2
      .probe3(header),  // input wire [47:0]  probe3
      .probe4(header_tx_order),  // input wire [15:0]  probe4
      .probe5(header_buffer)  // input wire [0:0]  probe5
  );
endmodule
