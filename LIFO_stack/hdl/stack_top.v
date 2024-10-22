`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.10.2024 19:03:09
// Design Name: 
// Module Name: stack_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module stack_top(
        input clk,
        input reset,
        input push,
        input pop,
        input [2:0] push_data_in,
        output [2:0] pop_data_out,
        output empty,
        output full
    );
    
    wire db_push, db_pop;
    
    debounce_explicit debounce_unit1(
        .clk_100MHz(clk),
        .reset(reset),
        .btn(push),
        .db_level(),        // unconnected
        .db_tick(db_push)
    );
   
    debounce_explicit debounce_unit2(
        .clk_100MHz(clk),
        .reset(reset),
        .btn(pop),
        .db_level(),        // unconnected
        .db_tick(db_pop)
    ); 
    stack #(.DATA_SIZE(3), .ADDR_SPACE_EXP(2)) stack_unit(
        .clk(clk),
        .reset(reset),
        .push(db_push),
        .pop(db_pop),
        .push_data_in(push_data_in),
        .pop_data_out(pop_data_out),
        .empty(empty),
        .full(full)
     );
endmodule
