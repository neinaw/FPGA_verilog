`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11.09.2024 17:05:07
// Design Name: 
// Module Name: square
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


module square(
    input clk, 
    input en, // enable/pause the circulation -  1 for pause, 0 for continue
    input cw, // dir of circulation - 1 for cw, 0 for anti-cw
    output reg [7:0] led,
    output reg [3:0] an
    );
    
    reg [26:0] count = 26'b0; // ~400 ms counter
    
    parameter [7:0] top_sq = 8'b0011_1001, 
                    bottom_sq = 8'b1100_0101;
    
    reg [2:0] state_reg = 3'b000;
    wire [2:0] state_next;
    
    always @(posedge clk) begin
        if(~en)
            state_reg <= state_next;
        count <= count + 1;
    end
    
    //output logic
    always @* begin
        case(state_reg)
            3'b000: begin
                led = top_sq;
                an = 4'b0111;
            end
            3'b001: begin
                led = top_sq;
                an = 4'b1011;
            end
            3'b010: begin
                led = top_sq;
                an = 4'b1101;
            end
            3'b011: begin
                led = top_sq;
                an = 4'b1110;
            end
            3'b100: begin
                led = bottom_sq;
                an = 4'b1110;
            end
            3'b101: begin
                led = bottom_sq;
                an = 4'b1101;
            end
            3'b110: begin
                led = bottom_sq;
                an = 4'b1011;
            end
            3'b111: begin
                led = bottom_sq;
                an = 4'b0111;
            end
        endcase
    end
    
    //next-state logic
    assign state_next = (&count == 1) ? ((cw == 1) ? state_reg + 1 : state_reg - 1) : state_reg;
endmodule
