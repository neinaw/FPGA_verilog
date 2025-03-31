module test (
    input  logic clk,
    input  logic rst,
    output logic out1,
    output logic out2
);

  logic next_out1, next_out2;
  logic [1:0] state, next_state;
  always_ff @(posedge clk) begin
    if (rst) begin
      state <= '0;
      out1  <= 0;
      out2  <= 0;
    end else begin
      state <= next_state;
      out1  <= next_out1;
      out2  <= next_out2;
    end
  end

  always_comb begin
    case (state)
      2'b00:   next_state = 2'b01;
      2'b01:   next_state = 2'b10;
      2'b10:   next_state = 2'b11;
      2'b11:   next_state = 2'b00;
      default: next_state = state;
    endcase
  end

  always_comb begin
    next_out1 = 1'b0;
    next_out2 = 1'b0;
    if (state == 2'b00 || state == 2'b01) next_out1 = 1;
    if (state == 2'b10 || state == 2'b11) next_out2 = 1;
  end
endmodule