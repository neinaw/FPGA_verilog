`timescale 1ns/1ps
module tb_fifo_bram;

bit clk, rst;
localparam DATA_W = 8;
localparam DEPTH = 16;

logic i_wren;
logic [DATA_W - 1 : 0] i_wrdata;
logic o_full;

logic i_rden;
logic [DATA_W - 1 : 0] o_rddata;
logic o_empty;

logic [DATA_W - 1: 0] out_word;
logic [$clog2(DEPTH) : 0] count;

// fifo_bram #(DATA_W, DEPTH) DUT (.*);
fwft_fifo #(.DEPTH(DEPTH), .DATA_WIDTH(DATA_W))
    DUT (
        .clk(clk),
        .rst(rst),
        .wr_en(i_wren),
        .din(i_wrdata),
        .rd_en(i_rden),
        .dout(o_rddata),
        .full(o_full),
        .empty(o_empty),
        .count(count)
    );

always #5 clk = ~clk;

initial begin
    clk = 0;
    reset();
    write_word(1);
    repeat(3) @(posedge clk);
    write_word(2);
    $finish;
    // for(int i=0; i<DEPTH; i++) begin
    //     if(i == DEPTH-3) begin
    //         fork
    //             read_word(out_word);
    //             write_word(i);
    //         join
    //     end
    //     else
    //         write_word(i);
    // end
end

task write_word(input bit [DATA_W - 1 : 0] in_word);
    if(rst) @(negedge rst);

    if(o_full) @(negedge o_full);
    @(negedge clk);
    i_wren <= 1;
    i_wrdata <= in_word;
    @(posedge clk);
    i_wren <= 0;
    i_wrdata <= '0;
endtask

task read_word(output bit[DATA_W - 1 : 0] out_word);
    if(rst) @(negedge rst);

    // if(o_empty) @(negedge o_empty);
    @(negedge clk);
    i_rden <= 1;
    @(posedge clk);
    out_word <= o_rddata;
    // @(negedge clk);
    i_rden <= 0;
endtask

task reset();
    i_rden <= 0;
    i_wren <= 0;
    i_wrdata <= '0;
    rst <= 1;
    @(negedge clk);
    @(negedge clk);
    rst <= 0;
endtask

endmodule