import uvm_pkg::*;
import tran_cls::*;

/*
    Convert Transactions to signals
    generate clk, rest
*/

module driver(
    ref uvm_tlm_fifo #(Input_tran) stim_f,
    ref uvm_tlm_fifo #(Input_tran) pred_f,
    output logic [7:0] m_axis_tdata,
    output logic       m_axis_tvalid,
    output logic       m_axis_tlast,
    output logic       bad_frame,
    input logic        m_axis_tready,
    output bit clk, 
    input bit rst
);

    Input_tran t;

    always @(negedge clk) begin

        if (!rst) begin
            if(stim_f.try_get(t)) begin
                assert(pred_f.try_put(t)) else
                    `uvm_error("FULL", "Predictor TLM FIFO Full!");
                // pred_f.put(t);
                foreach(t.payload[i]) begin
                        m_axis_tdata <= t.payload[i];
                        m_axis_tvalid <= 1;
                        if(i == t.payload.size() - 1) begin
                            m_axis_tlast <= 1;
                            bad_frame <= t.bad_frame;
                        end
                        else begin
                            m_axis_tlast <= 0;
                            bad_frame <= 0;
                        end

                    do begin
                        @(posedge clk);
                    end while(m_axis_tready != 1);
                end
            end
            else reset();
        end
        
        else begin
            reset();
        end
    end


    always #10 clk = ~clk;

    task reset();
        m_axis_tdata <= 'x;
        m_axis_tvalid <= 0;
        m_axis_tlast <= 0;
    endtask

endmodule