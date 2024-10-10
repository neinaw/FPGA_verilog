`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.09.2024 15:10:40
// Design Name: 
// Module Name: square_top
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


module square_top(
    input clk, 
    input en, // enable/pause the circulation -  1 for pause, 0 for continue
    input cw, // dir of circulation - 1 for cw, 0 for anti-cw
    output [3:0] an,
    output [7:0] sseg
    );
    
//    wire debounced_en, debounced_cw;
//    debounce_explicit debounce_en(
//        .clk_100MHz(clk),
//        .reset(1'b0),
//        .btn(en),
//        .db_level(),
//        .db_tick(debounced_en)
//    );
    
//    debounce_explicit debounce_cw(
//        .clk_100MHz(clk),
//        .reset(1'b0),
//        .btn(en),
//        .db_level(),
//        .db_tick(debounced_cw)
//    );
    
    wire [7:0] led0, led1, led2, led3;
    square square_unit(
        .clk(clk),
        .en(en),
        .cw(cw),
        .an(an),
        .led(sseg)
    );
endmodule
