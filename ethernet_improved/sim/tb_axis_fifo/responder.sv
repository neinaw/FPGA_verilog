import uvm_pkg::*;
import tran_cls::*;

module responder(
    input uvm_tlm_fifo #(Result_tran) result_f,
    input bit clk, 
    input bit rst,
    input [7:0] s_axis_tdata,
    input       s_axis_tvalid,
    output   logic   s_axis_tready,
    input       s_axis_tlast
);

    Result_tran t = new();

    always @(posedge clk) begin
//        s_axis_tready <= 1;
//        @(posedge clk);
        if(s_axis_tvalid & s_axis_tready) begin
            t.add_word(s_axis_tdata);
            if(s_axis_tlast) begin
                assert(result_f.try_put(t.clone())) else
                    `uvm_fatal("NC", "Responder Not Connected!");
                t = new();
            end
        end
    end

    assign s_axis_tready = 1;

endmodule