// Single Port BRAM with write enable and synchronous read
module bram_sp #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 10,
    parameter DEPTH      = 1 << ADDR_WIDTH
)(
    input logic clk,

    // Write port
    input logic we,
    input logic [ADDR_WIDTH-1:0] wr_addr,
    input logic [DATA_WIDTH-1:0] din,

    // Read port
    input logic [ADDR_WIDTH-1:0] rd_addr,
    output logic [DATA_WIDTH-1:0] dout
);

    (*ram_style = "block"*)
    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    always_ff @(posedge clk) begin
        if(we) begin
            mem[wr_addr] <= din;
        end
        dout <= mem[rd_addr];
    end
endmodule