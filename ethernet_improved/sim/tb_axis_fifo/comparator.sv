import uvm_pkg::*;
import tran_cls::*;
`include "uvm_macros.svh"
module comparator(
    ref uvm_tlm_fifo #(Result_tran) predicted_f,
    ref uvm_tlm_fifo #(Result_tran) actual_f
);

    Result_tran predicted, actual;
    string message;
    
    task run;
        forever begin
            predicted_f.get(predicted);
            actual_f.get(actual);
            $sformat(message, "\n\tGolden result: %s\n\tActual: %s", predicted.convert2string(), actual.convert2string());
            if(predicted.comp(actual)) begin
                `uvm_info("GOOD COMP", $sformatf("%s", message), UVM_HIGH);
            end
            else begin
                `uvm_error("BAD COMP", $sformatf("%s", message));
            end
        end
    endtask
endmodule