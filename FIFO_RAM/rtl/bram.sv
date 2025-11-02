`timescale 1ns/1ps
module bram   #(
                    /* Global Parameters */
                    parameter DATA_W           = 8                    ,        // Data width
                    parameter DEPTH            = 8                    ,        // Depth

                    /* Dependent Parameters */
                    parameter ADDR_W           = $clog2 (DEPTH)                // Address width 
                 )

                 (
                    /* Global */                  
                    input  logic                  clk                 ,        // Clock                    
                                       
                    /* Write Port*/
                    input  logic                  i_wren              ,        // Write Enable
                    input  logic [ADDR_W - 1 : 0] i_waddr             ,        // Write-address                    
                    input  logic [DATA_W - 1 : 0] i_wdata             ,        // Write-data 
                    
                    /* Read Port */
                    input  logic                  i_rden              ,        // Read Enable
                    input  logic [ADDR_W - 1 : 0] i_raddr             ,        // Read-address                   
                    output logic [DATA_W - 1 : 0] o_rdata                      // Read-data                   
                 );


/*---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
   Internal Registers/Signals
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
(* ram_style ="block" *)
logic [DATA_W - 1 : 0] data_rg [DEPTH] ;        // Data array


/*---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
   Synchronous logic to write to RAM
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
always @ (posedge clk) begin
              
   if (i_wren) begin                          
         
      data_rg [i_waddr] <= i_wdata  ;      
      // o_rdata <= i_wdata;

   end

   if (i_rden) begin
      o_rdata <= data_rg [i_raddr];
   end

end


/*---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
   Synchronous logic to read from RAM
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
// always @ (posedge clk) begin
   
//    o_rdata <= data_rg [i_raddr] ;
      
// end


endmodule