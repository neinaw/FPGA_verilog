`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.10.2024 16:00:59
// Design Name: 
// Module Name: stack_tb
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


module stack_tb;
    reg clk, reset;    
    initial begin
        clk = 0;
        reset = 1'b1; #2 reset = 0;
    end
    always #5 clk = ~clk;
    
//    parameter DATA_WIDTH = 8;
    reg push, pop;
    reg [7:0] push_data_in;
    wire [7:0] pop_data_out;
    wire empty, full;
    
    stack #(.DATA_SIZE(8), .ADDR_SPACE_EXP(2))  stack_dut (
        .clk(clk),
        .reset(reset),
        .push(push),
        .pop(pop),
        .push_data_in(push_data_in),
        .pop_data_out(pop_data_out),
        .empty(empty),
        .full(full)
    );
    
    initial begin
    push = 1'b0; pop = 1'b0;
    #3;
        push = 1'b1;
        push_data_in = 8'b0;
        #10 push_data_in = 8'b1111_0000;
        #10 push_data_in = 8'b0000_1111;
        #10 push_data_in = 8'b1010_1010;
        #10 push = 1'b0; pop = 1'b1;
        #30 pop = 1'b0; 
        #10 push_data_in = 8'hBC;
        #10 push = 1'b1; pop = 1'b0;
        #50 $finish;
    end
endmodule
