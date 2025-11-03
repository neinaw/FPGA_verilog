`timescale 1ns/1ps
import uvm_pkg::*;
import tran_cls::*;
`include "uvm_macros.svh"

module predictor(
    ref uvm_tlm_fifo #(Input_tran)  pred_f,
    ref uvm_tlm_fifo #(Result_tran) result_f
);

    Input_tran eth_pkt;
    Result_tran res;

    task run;
        forever begin
            pred_f.get(eth_pkt);
            res = new(
                {>>{
                    eth_pkt.frame.dest_mac,
                    eth_pkt.frame.src_mac,
                    eth_pkt.frame.ethertype
                }}
            );

            foreach(eth_pkt.frame.payload[i])
                res.add_word(eth_pkt.frame.payload[i]);

            result_f.put(res);
        end
    endtask

endmodule