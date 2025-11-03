`timescale 1ns/1ps
// Dual port single clock BRAM
module bram #(
    /* Global Parameters */
    parameter DATA_W = 8,
    parameter DEPTH  = 8,
    parameter ADDR_W = $clog2(DEPTH)
) (
    /* Global */                  
    input  logic                  clk,
                        
    /* Write Port*/
    input  logic                  i_wren,
    input  logic [ADDR_W - 1 : 0] i_waddr,
    input  logic [DATA_W - 1 : 0] i_wdata,
    
    /* Read Port */
    input  logic                  i_rden,
    input  logic [ADDR_W - 1 : 0] i_raddr,
    output logic [DATA_W - 1 : 0] o_rdata
);


(* ram_style ="block" *)
logic [DATA_W - 1 : 0] data_rg [DEPTH];


always @ (posedge clk) begin
   if (i_wren) begin
      data_rg[i_waddr] <= i_wdata;
   end

   if (i_rden) begin
      o_rdata <= data_rg[i_raddr];
   end
end

endmodule
