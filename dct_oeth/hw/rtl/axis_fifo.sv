`timescale 1ns / 1ps

/*
    AXI-S -> FIFO -> AXI-S
*/

module axis_fifo #(
    parameter DATA_WIDTH = 8,
              DEPTH      = 1024  // power of two
) (
    input logic clk,
    input logic rst,

    // write side (slave)
    input logic [DATA_WIDTH - 1 : 0] s_axis_tdata,
    input logic s_axis_tvalid,
    input logic s_axis_tlast,
    input logic bad_frame,

    // read side (master)
    output logic [DATA_WIDTH-1 : 0] m_axis_tdata,
    output logic m_axis_tvalid,
    output logic m_axis_tlast,
    input logic m_axis_tready
);

  localparam ADDR_WIDTH = $clog2(DEPTH);
  typedef struct packed {
    logic [DATA_WIDTH - 1 : 0] data;
    logic                      last;
  } mem_word;

  // fifo buffer
  (* ram_style = "block" *) mem_word mem[0 : (1 << ADDR_WIDTH) - 1];
  initial begin
    foreach (mem[i]) mem[i] <= '0;
  end
  logic [ADDR_WIDTH - 1 : 0] wr_ptr, next_wr_ptr, orig_wr_ptr;
  logic [ADDR_WIDTH - 1 : 0] rd_ptr, next_rd_ptr;
  logic wr_enable;

  logic full, next_full;

  // packet count
  logic [$clog2(DEPTH) - 1:0] count, next_count;

  logic commit;

  always_ff @(posedge clk) begin
    if (rst) begin
      wr_ptr <= '0;
      orig_wr_ptr <= '0;
      rd_ptr <= '0;
      full <= 1'b0;
      count <= 0;
    end else begin
      wr_ptr <= next_wr_ptr;
      rd_ptr <= next_rd_ptr;
      full   <= next_full;
      count  <= next_count;
      if (wr_enable) begin
        mem[wr_ptr] <= {s_axis_tdata, s_axis_tlast};
        if (commit) begin
          // trim CRC from mem and mark last of payload
          mem[next_wr_ptr-1].last <= 1'b1;
          orig_wr_ptr <= next_wr_ptr;
        end
      end
    end
  end

  always_comb begin
    next_wr_ptr = wr_ptr;
    next_rd_ptr = rd_ptr;
    wr_enable = 1'b0;
    commit = 1'b0;
    next_full = full;
    next_count = count;
    case ({
      s_axis_tvalid, m_axis_tready
    })
      // 2'b00: nothing
      2'b10: begin
        if (full) begin
          next_wr_ptr = orig_wr_ptr;
        end else begin
          wr_enable   = 1'b1;
          next_wr_ptr = wr_ptr + 1'b1;
          if (s_axis_tlast) begin
            if (bad_frame) begin
              next_wr_ptr = orig_wr_ptr;
            end else begin
              commit = 1'b1;
              // next_empty = 1'b0;
              next_wr_ptr = wr_ptr - 2'd3;
              next_count = count + 1'b1;
            end
          end
          if (next_wr_ptr == rd_ptr) next_full = 1'b1;
        end
      end

      2'b01: begin
        if (m_axis_tvalid) begin
          next_rd_ptr = rd_ptr + 1;
          if (mem[rd_ptr].last) next_count = count - 1'b1;
        end
      end

      2'b11: begin
        next_wr_ptr = wr_ptr;
        if (count == 0) begin
          // master is attempting to write a packet
          // wait for it to be written
          if (full) begin
            // we can reach full when empty, in which case drop
            // frame
            next_wr_ptr = orig_wr_ptr;
          end else begin
            wr_enable   = 1'b1;
            next_wr_ptr = wr_ptr + 1'b1;
            if (s_axis_tlast) begin
              if (bad_frame) begin
                next_wr_ptr = orig_wr_ptr;
              end else begin
                commit = 1'b1;
                next_wr_ptr = wr_ptr - 2'd3;
                next_count = count + 1'b1;
              end
              if (next_wr_ptr == rd_ptr) next_full = 1'b1;
            end
          end
        end else begin
          wr_enable   = 1'b1;
          next_rd_ptr = rd_ptr + 1'b1;
          next_wr_ptr = wr_ptr + 1'b1;
          if (mem[rd_ptr].last) next_count = count - 1'b1;
        end
      end

      default: ;  //do nothing
    endcase
  end
  // read side
  assign m_axis_tdata  = mem[rd_ptr].data;
  assign m_axis_tlast  = mem[rd_ptr].last;
  assign m_axis_tvalid = (count == 0) ? 1'b0 : 1'b1;

endmodule
