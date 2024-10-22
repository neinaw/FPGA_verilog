`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: neinaw industries
// Engineer: neinaw
// 
// Create Date: 10.10.2024 15:26:20
// Design Name: 
// Module Name: stack
// Project Name: 
// Target Devices: BASYS3
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
module stack 
    #(
        parameter DATA_SIZE = 8, //number of bits in a data word
                  ADDR_SPACE_EXP = 4 //number of addr bits
    )
    (
        input clk,
        input reset,
        input push,
        input pop,
        input [DATA_SIZE-1:0] push_data_in,
        output [DATA_SIZE-1:0] pop_data_out,
        output empty,
        output full
    );
    
    localparam FULL = 2'b11, EMPTY = 2'b00, HLF = 2'b01;
    
    reg [DATA_SIZE-1:0] reg_file [2**ADDR_SPACE_EXP-1:0];
    reg [ADDR_SPACE_EXP-1:0] write_addr, next_write_addr, read_addr, next_read_addr;
    reg [1:0] state, state_next;
    wire push_enable;
    reg empty, full;
    
    always @(posedge clk)
        if(push_enable) 
            reg_file[write_addr] <= push_data_in;
            
    assign pop_data_out = reg_file[read_addr];
    assign push_enable = ~full & push;  
    
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            write_addr <= 0;
            read_addr <= 0;
            state <= EMPTY;
        end
        else begin
            write_addr <= next_write_addr;
            read_addr <= next_read_addr;
            state <= state_next;
        end
    end
    
    always @* begin
    state_next = state;
    next_write_addr = write_addr;
    next_read_addr = read_addr;
        case(state)
            EMPTY: begin
                full = 1'b0;
                empty = 1'b1;
                if(push) begin
                   next_write_addr = write_addr + 1; 
                   next_read_addr = read_addr;
                   state_next = HLF;
                end
            end
            HLF: begin
                full = 1'b0;
                empty = 1'b0;
                if(push) begin
                   if(&write_addr == 1) begin
                       next_write_addr = write_addr; 
                       next_read_addr = read_addr + 1;
                       state_next = FULL;
                   end
                   else begin
                       next_write_addr = write_addr + 1; 
                       next_read_addr = read_addr + 1;
                   end
                end
                else if(pop) begin
                    if(read_addr == {DATA_SIZE{1'b0}}) begin
                       next_write_addr = write_addr - 1; 
                       next_read_addr = read_addr;
                       state_next = EMPTY;
                    end
                    else begin
                       next_write_addr = write_addr - 1; 
                       next_read_addr = read_addr - 1;
                    end
                end
            end
            
            FULL: begin
                full = 1'b1; empty = 1'b0;
                if(pop) begin   
                    next_write_addr = write_addr;
                    next_read_addr = read_addr - 1;
                    state_next = HLF;
                end
            end
        endcase
        
    end
endmodule
