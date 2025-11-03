`timescale 1ns/1ps
import uvm_pkg::*;
import tran_cls::*;
`include "uvm_macros.svh"

module driver #(parameter int CYCLE_TIME = 10, WAIT_CYCLES = 96) (
    ref    uvm_tlm_fifo #(Input_tran) stim_f,
    ref    uvm_tlm_fifo #(Input_tran) pred_f,
    output logic[1:0]   RXD,
    output logic        RXDV,
    output bit          clk,
    output bit          rst
);

    typedef enum logic [1:0] {
        IDLE,
        DRIVE,
        WAIT
    } state_t;

    Input_tran t;
    bit [7:0] curr_byte;
    bit [1:0] two_bits;
    logic[31:0] byte_index;
    logic[1:0] slice_index;
    state_t state;

    task run();
    forever begin
        if(rst) @(negedge rst);
        stim_f.get(t);
        assert(pred_f.try_put(t)) else
            `uvm_error("PFULL", "Predictor TLM FIFO FULL!");

        @(negedge clk);
        foreach(t.frame_tx_order[i]) begin
            RXDV <= 1;
            curr_byte = t.frame_tx_order[i];
            for (int j=0; j<4; j++) begin
                two_bits = (curr_byte >> (j*2)) & 2'b11;
                RXD <= two_bits;
                @(posedge clk);
            end
        end
        idle();
        stall();
    end
    endtask

    always #(CYCLE_TIME/2) clk = ~clk;

    task idle();
        RXDV <= 0;
        RXD  <= 'x;
    endtask

    task stall();
        repeat(25) @(posedge clk);
    endtask

    task reset();
        rst <= 1;
        @(negedge clk);
        @(negedge clk);
        rst <= 0;
    endtask

endmodule