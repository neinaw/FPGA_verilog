`timescale 1ns/1ps
import uvm_pkg::*;
import tran_cls::*;

module tb_top;

    uvm_tlm_fifo #(Input_tran) stim_f;
    uvm_tlm_fifo #(Result_tran) result_f;
    uvm_tlm_fifo #(Input_tran) drv2prd;
    uvm_tlm_fifo #(Result_tran) prd2cmp;

    wire [1:0]  RXD;
    wire        RXDV;
    wire        header_valid;
    wire        header_rd;
    wire [47:0] dest_mac;
    wire [47:0] src_mac;
    wire [15:0] ethertype;

    wire [7:0]  axis_tdata;
    wire        axis_tvalid;
    wire        axis_tready;
    wire        axis_tlast;

    wire clk, rst;

    generator gen(.clk(clk), .stim_f(stim_f));
    driver tran2pins(
        .stim_f(stim_f),
        .pred_f(drv2prd),
        .*
    );

    packet_recv DUT(
        .*,
        .m_axis_tdata(axis_tdata),
        .m_axis_tvalid(axis_tvalid),
        .m_axis_tlast(axis_tlast),
        .m_axis_tready(axis_tready)
    );

    predictor pred(.pred_f(drv2prd), .result_f(prd2cmp));
    comparator comp(.predicted_f(prd2cmp), .actual_f(result_f));

    responder pins2tran(
        .result_f(result_f),
        .*,
        .s_axis_tdata(axis_tdata),
        .s_axis_tvalid(axis_tvalid),
        .s_axis_tlast(axis_tlast),
        .s_axis_tready(axis_tready)
    );

    initial begin
        stim_f = new("stim_f");
        result_f = new("result_f");
        drv2prd = new("drv2prd");
        prd2cmp = new("prd2cmp");
        driver.idle();
        driver.reset();
        fork
            comp.run();
            pred.run();
            gen.run();
            pins2tran.run();
            tran2pins.run();
        join_none
    end

endmodule