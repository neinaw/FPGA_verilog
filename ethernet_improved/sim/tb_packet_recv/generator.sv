import uvm_pkg::*;
import tran_cls::*;
`include "uvm_macros.svh"

module generator(ref uvm_tlm_fifo #(Input_tran) stim_f, input logic clk);

    task direct_tran(
        bit[47:0] dest_mac  = 48'h00_18_3E_04_B3_F2,
        bit[47:0] src_mac   = 48'h54_E1_AD_33_0D_32,
        int length,
        bit bad_frame
    );
        // deterministic transaction
        Input_tran new_tran;
        new_tran = new(dest_mac, src_mac, length, length, bad_frame);
        stim_f.put(new_tran.clone());
        `uvm_info("GEN", $sformatf("%s", new_tran.convert2string()), UVM_HIGH);
    endtask: direct_tran

    task run;
        direct_tran(.length(10), .bad_frame(1'b0));
        direct_tran(.length(64), .bad_frame(1'b0));
        direct_tran(.length(32), .bad_frame(1'b1));
        direct_tran(.length(32), .bad_frame(1'b0));
    endtask: run

endmodule