`timescale 1ns / 1ps

module fifo_tb
    #(
	parameter	DATA_SIZE 	   = 8,	// number of bits in a data word
				ADDR_SPACE_EXP = 2	// number of address bits (2^4 = 16 addresses)
	);
	reg clk_100MHz, reset;
	reg write_to_fifo, read_from_fifo;
	reg [DATA_SIZE-1:0] write_data_in;
	wire [DATA_SIZE-1:0] read_data_out;
	wire empty, full;
	
	fifo #(.DATA_SIZE(DATA_SIZE), .ADDR_SPACE_EXP(ADDR_SPACE_EXP)) fifo_dut(
        .clk(clk_100MHz),
        .reset(reset),
        .write_to_fifo(write_to_fifo),
        .read_from_fifo(read_from_fifo),
        .write_data_in(write_data_in),
        .read_data_out(read_data_out),
        .full(full),
        .empty(empty)
        );
    
    initial begin
        clk_100MHz = 0;
        reset = 1; #3 reset = 0;
    end
    
    always #5 clk_100MHz = ~clk_100MHz; //10ns time period
    
    initial begin
        write_to_fifo = 1;
        read_from_fifo = 0;
        #2
        write_data_in = 8'hA1;
        #10
        write_data_in = 8'hFF;
        write_to_fifo = 0;
        read_from_fifo = 1;
        #20
        write_to_fifo = 1;
        read_from_fifo = 0;
        write_data_in = 8'h01;
        #100 $finish;
    end
endmodule