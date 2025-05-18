import uvm_pkg::*;
import tran_cls::*;
`include "uvm_macros.svh"
/*
    Result Printer Module
*/

module result_printer(ref uvm_tlm_fifo #(Result_tran) result_f);

    Result_tran result;

    task run;
        forever begin
            result_f.get(result);
            `uvm_info("READ", $sformatf("%s", result.convert2string()), UVM_HIGH);
        end
    endtask

endmodule