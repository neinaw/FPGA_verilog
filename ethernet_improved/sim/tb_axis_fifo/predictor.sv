import uvm_pkg::*;
import tran_cls::*;
`include "uvm_macros.svh"
module predictor(
    ref uvm_tlm_fifo #(Input_tran) in_f,
    ref uvm_tlm_fifo #(Result_tran) res_f
);

    Input_tran frame;
    Result_tran res;
    int payload_size;

    task run;
        forever begin
            in_f.get(frame);
            `uvm_info("PREDICT IN", $sformatf("%s", frame.convert2string()), UVM_DEBUG);
            payload_size = frame.payload.size();
            if(!frame.bad_frame && payload_size <= 1024) begin
                res = new();
                // res.payload = frame.payload;
                for(int i=0; i<payload_size; i++) begin
                    res.add_word(frame.payload[i]);
                end

                res_f.put(res);
            end
        end
    endtask

endmodule