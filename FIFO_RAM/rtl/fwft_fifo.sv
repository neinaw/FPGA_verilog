`timescale 1ns/1ps
module fwft_fifo #(parameter int DEPTH = 64, DATA_WIDTH = 8) (
    input  logic clk,
    input  logic rst,

    // write port
    input  logic wr_en,
    input  logic [DATA_WIDTH - 1 : 0] din,

    // read port
    input  logic rd_en,
    output logic [DATA_WIDTH - 1 : 0] dout,
    output logic [$clog2(DEPTH) : 0] count,

    output logic full,
    output logic empty
);

    localparam LOG2_DEPTH = $clog2(DEPTH);

    logic [LOG2_DEPTH : 0]         next_words_in_ram; // Combinatorial
    logic [LOG2_DEPTH : 0]         words_in_ram;
    logic [LOG2_DEPTH - 1 : 0]     rd_addr;
    logic [LOG2_DEPTH - 1 : 0]     wr_addr;
    logic                          has_more_words;
    logic                          fetch_data, commit_data;

    assign fetch_data = (rd_en || empty) && has_more_words;
    assign commit_data = wr_en && !full;

    always_comb begin
        if (commit_data && !fetch_data) begin
            next_words_in_ram = words_in_ram + 1;
        end
        else if (!commit_data && fetch_data) begin
            next_words_in_ram = words_in_ram - 1;
        end
        else begin
            next_words_in_ram = words_in_ram;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            empty <= 1;
            full <= 0;
            words_in_ram <= 0;
            has_more_words <= 0;
            rd_addr <= 0;
            wr_addr <= 0;
        end
        else begin
            words_in_ram <= next_words_in_ram;
            full <= (next_words_in_ram == DEPTH);
            has_more_words <= (next_words_in_ram != 0);

            if (fetch_data)
                rd_addr <= rd_addr + 1;

            if (commit_data)
                wr_addr <= wr_addr + 1;

            if (fetch_data)
                empty <= 0;
            else if (rd_en)
                empty <= 1;
        end

    end

    bram #(.DEPTH(DEPTH), .ADDR_W(LOG2_DEPTH), .DATA_W(DATA_WIDTH)) ram_i (
        .clk(clk),
        .i_waddr(wr_addr),
        .i_raddr(rd_addr),
        .i_wren(commit_data),
        .i_rden(fetch_data),
        .i_wdata(din),
        .o_rdata(dout)
    );

    assign count = empty ? 0 : words_in_ram + 1;
endmodule