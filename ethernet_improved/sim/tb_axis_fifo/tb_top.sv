import uvm_pkg::*;
import tran_cls::*;

module tb_top;

    uvm_tlm_fifo #(Input_tran) stim_f;
    uvm_tlm_fifo #(Result_tran) result_f;
    uvm_tlm_fifo #(Input_tran) drv2prd;
    uvm_tlm_fifo #(Result_tran) prd2cmp;

    wire [7:0] m_axis_tdata;
    wire m_axis_tready, m_axis_tvalid, m_axis_tlast;
    wire bad_frame;

    wire [7:0] s_axis_tdata;
    wire s_axis_tready, s_axis_tvalid, s_axis_tlast;

    wire clk;
    logic rst;
    
    initial begin
        rst = 1;
        @(negedge clk);
        @(negedge clk);
        rst = 0;
    end

    generator gen (.stim_f(stim_f));
    driver tran2pins(
        .stim_f(stim_f),
        .pred_f(drv2prd),
        .*
    );

    axis_fifo_new DUT(
        .s_axis_tdata(m_axis_tdata),
        .s_axis_tvalid(m_axis_tvalid),
        .s_axis_tlast(m_axis_tlast),
        .s_axis_tready(m_axis_tready),
        .bad_frame(bad_frame),

        .m_axis_tdata(s_axis_tdata),
        .m_axis_tvalid(s_axis_tvalid),
        .m_axis_tlast(s_axis_tlast),
        .m_axis_tready(s_axis_tready),
        .clk(clk),
        .rst(rst)
    );

    predictor pred(.in_f(drv2prd), .res_f(prd2cmp));
    comparator comp(.predicted_f(prd2cmp), .actual_f(result_f));

    responder pins2tran(
        .result_f(result_f),
        .*
    );

    // result_printer print(.result_f(result_f));

    initial begin
        stim_f = new("stim_f");
        result_f = new("result_f");
        drv2prd = new("drv2prd");
        prd2cmp = new("prd2cmp");
        fork
            // print.run();
            comp.run();
            pred.run();
            gen.run();
        join_none
//        #10000 $finish;
    end

endmodule