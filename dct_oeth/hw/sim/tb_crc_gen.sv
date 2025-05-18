`timescale 1ns/1ps
// look at the output at timestep 3280 ns
module tb_crc_gen;
    logic [1:0] data_in;
    logic	crc_en;
    logic [31:0] crc_out;
    logic rst;
    logic clk;

    initial begin
      rst = 1;
      clk = 0;
      crc_en = 0;
      #7 rst = 0;
      crc_en = 1;
      if(frame == '0) crc_en = 0;
    end

    always #5 clk = ~clk;

    logic [81:0][7:0] frame, next_frame;
    logic [3:0][7:0] test, next_test;
    initial begin
	frame[81 -: 6] = 48'h00_18_3e_04_b3_f2;
	frame[75 -: 6] = 48'h54_e1_ad_33_0d_32;
        frame[69 -: 2] = 16'h0040;
	frame[67 -: 64] = 544'h28412036342062797465207061796c6f6164292053656e64696e67202848656c6c6f2c20576f726c64212920746f20465047412066726f6d2074686973205043; 
	frame[3:0] = 32'hB7B64405;

	// a smaller test
	test[3:0] = 32'h075BCD15;
	$display("%h frame top", frame[81]);
	$display("%h frame bottom", frame[0]);
    end

    logic [7:0] current_msb, next_msb;
    logic [1:0] counter;
    always_ff @(posedge clk) begin
      current_msb <= next_msb;
      if (rst) begin
	counter <= '0;
      end

      else begin
	frame <= next_frame;
	test <= next_test;
	counter <= counter + 1'b1;
      end
    end

    always_comb begin
      next_frame = frame;
      next_test = test;
      if(rst == 1 || crc_en == 0) begin
	next_frame = frame;
	next_test = test;
      end
      else begin
	next_frame = frame << 2;
	next_test = test << 2;
      end
    end

    always_comb begin
	if(rst)
	  next_msb = next_frame[81];
	  // next_msb = next_test[3];

	else
	  if(counter == 3) begin
	    next_msb = next_frame[81];
	    // next_msb = next_test[3];
	  end

	  else
	    next_msb = current_msb >> 2;
    end

    assign data_in = current_msb[1:0];

    crc_gen crc_DUT(
      .*
    );

endmodule
