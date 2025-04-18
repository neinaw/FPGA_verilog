`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Target Devices: Nexys A7 100T
// Description: A parameterized FIFO unit
//////////////////////////////////////////////////////////////////////////////////

module fifo #(
    parameter         DATA_SIZE = 8,  // number of bits in a data word
    parameter integer MAX_DEPTH = 16
) (
    input clk,
    input rst,
    input write_to_fifo,
    input read_from_fifo,
    input [DATA_SIZE-1:0] write_data_in,
    output [DATA_SIZE-1:0] read_data_out,
    output logic [$clog2(MAX_DEPTH) : 0] fifo_count,
    output empty,
    output full
);

  localparam ADDR_SPACE_EXP = $clog2(MAX_DEPTH);
  // signal declaration
  logic [2**ADDR_SPACE_EXP-1:0][DATA_SIZE-1:0] memory;  // memory array register
  logic [ADDR_SPACE_EXP-1:0] current_write_addr, current_write_addr_buff, next_write_addr;
  logic [ADDR_SPACE_EXP-1:0] current_read_addr, current_read_addr_buff, next_read_addr;
  logic fifo_full, fifo_empty, full_buff, empty_buff;
  logic write_enabled;
  logic [$clog2(MAX_DEPTH):0] next_fifo_count;

  // body
  // register file (memory) write operation
  always_ff @(posedge clk) if (write_enabled) memory[current_write_addr] <= write_data_in;

  // logicister file (memory)  read operation
  assign read_data_out = memory[current_read_addr];

  // only allow write operation when FIFO is NOT full
  assign write_enabled = write_to_fifo & ~fifo_full;

  // FIFO control logic
  // logicister logic
  always_ff @(posedge clk or posedge rst)
    if (rst) begin
      current_write_addr <= 0;
      current_read_addr  <= 0;
      fifo_count         <= '0;
      fifo_full          <= 1'b0;
      fifo_empty         <= 1'b1;  // FIFO is empty after rst
    end else begin
      current_write_addr <= current_write_addr_buff;
      current_read_addr  <= current_read_addr_buff;
      fifo_count         <= next_fifo_count;
      fifo_full          <= full_buff;
      fifo_empty         <= empty_buff;
    end

  // next state logic for read and write address pointers
  always_comb begin
    // successive pointer values
    next_write_addr = current_write_addr + 1;
    next_read_addr = current_read_addr + 1;

    // default: keep old values
    current_write_addr_buff = current_write_addr;
    current_read_addr_buff = current_read_addr;
    full_buff = fifo_full;
    empty_buff = fifo_empty;
    next_fifo_count = fifo_count;

    // Button press logic
    case ({
      write_to_fifo, read_from_fifo
    })  // check both buttons
        // 2'b00: neither buttons pressed, do nothing

      2'b01:  // read button pressed?
      if (~fifo_empty) begin  // FIFO not empty
        current_read_addr_buff = next_read_addr;
        full_buff = 1'b0;  // after read, FIFO not full anymore
        next_fifo_count = fifo_count - 1;
        if (next_read_addr == current_write_addr) empty_buff = 1'b1;
      end

      2'b10:  // write button pressed?
      if (~fifo_full) begin  // FIFO not full
        current_write_addr_buff = next_write_addr;
        empty_buff = 1'b0;  // after write, FIFO not empty anymore
        next_fifo_count = fifo_count + 1;
        if (next_write_addr == current_read_addr) full_buff = 1'b1;
      end

      2'b11: begin  // write and read
        //count does not change
        // next_fifo_count = fifo_count + 1 - 1;
        current_write_addr_buff = next_write_addr;
        current_read_addr_buff  = next_read_addr;
      end
      default: ;  // do nothing, all defaults are set
    endcase
  end

  // output
  assign full  = fifo_full;
  assign empty = fifo_empty;

endmodule
