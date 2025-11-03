import uvm_pkg::*;
import tran_cls::*;
`include "uvm_macros.svh"
/*
    Stimulus Generator Module
*/


module generator(ref uvm_tlm_fifo #(Input_tran) stim_f);

    localparam int NUM_ITER = 40;
    Input_tran random_transaction;

    task direct_tran(int len, bit bad_frame);
        Input_tran new_tran;
        new_tran = new(len, bad_frame);
        stim_f.put(new_tran.clone());
        `uvm_info("WRITE", $sformatf("%s", new_tran.convert2string()), UVM_DEBUG);
    endtask: direct_tran


    task run;
        direct_tran(10, 0);
        direct_tran(20, 1);
        direct_tran(32, 0);
        direct_tran(64, 0);

        // random_transaction = new();
        // repeat(NUM_ITER) begin
        //     assert(random_transaction.randomize());
        //     `uvm_info("WRITE", $sformatf("%s", random_transaction.convert2string()), UVM_DEBUG);
        //     stim_f.put(random_transaction.clone());
        // end
        // #500 $finish;
    endtask: run

endmodule