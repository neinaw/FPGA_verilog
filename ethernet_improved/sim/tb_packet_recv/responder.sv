`timescale 1ns/1ps
import uvm_pkg::*;
import tran_cls::*;

module responder(
    ref    uvm_tlm_fifo #(Result_tran) result_f,
    input  bit                         clk,
    input  bit                         rst,

    input  logic [47:0]                dest_mac,
    input  logic [47:0]                src_mac,
    input  logic [15:0]                ethertype,
    input  logic                       header_valid,
    output logic                       header_rd,

    input  logic [7:0]                 s_axis_tdata,
    input  logic                       s_axis_tvalid,
    output logic                       s_axis_tready,
    input  logic                       s_axis_tlast
);

    task run();
        Result_tran t;
        // @(posedge clk);
        s_axis_tready = 0;
        header_rd = 0;

        forever begin
        wait(header_valid);
        @(posedge clk);
        header_rd = 1;
        t = new({dest_mac, src_mac, ethertype});
        @(posedge clk);
        header_rd = 0;
        forever begin
            @(negedge clk);
            // s_axis_tready = 1;     // ready to accept data
            s_axis_tready = ($random % 5) == 0 ? 0 : 1;
            if(!s_axis_tready) continue;

            if (s_axis_tvalid && s_axis_tready) begin
                t.add_word(s_axis_tdata);

                if (s_axis_tlast) begin
                    // finished frame
                    assert(result_f.try_put(t.clone()))
                        else `uvm_fatal("NC", "Responder Not Connected!");

                    @(posedge clk);
                    break;
                end
                @(posedge clk);
            end
        end

        // final cleanup
        s_axis_tready = 0;
        header_rd = 0;
        end
    endtask
endmodule
