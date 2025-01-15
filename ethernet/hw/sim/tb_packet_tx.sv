`timescale 1ns / 1ps
module tb_packet_tx;
    logic clk, rst;

    // input signals
    logic [7:0] s_axis_tdata;
    logic s_axis_tvalid;
    logic s_axis_tlast;
    logic s_axis_tready;

    // output signals
    logic tx_en;
    logic [1:0] txd;

    initial begin
        clk = 0;
    end

    always #5 clk = ~clk;

    initial begin
        rst = 1;
        #7 rst = 0;
    end

    task automatic initialize();
        s_axis_tvalid <= 0;
        s_axis_tlast <= 0;
        s_axis_tdata <= '0;
    endtask

    task automatic axis_write_packet(input logic [7:0] word='hAA, input int len=64);
        int i;
        if(rst) @(negedge rst);

        @(posedge clk);
        for(i = 0; i < len; i++) begin
            s_axis_tvalid <= 1;
            s_axis_tdata <= (i == len - 1) ? 'hFF : word;
            s_axis_tlast <= (i == len - 1) ? 1 : 0;
            while(~s_axis_tready);
            @(posedge clk);
        end

        s_axis_tvalid <= 0;
        s_axis_tlast <= 0;
        s_axis_tdata <= '0;
    endtask

    packet_tx TX_DUT (.*);
    initial begin
        initialize();
        @(negedge rst);
        #15; axis_write_packet();
    end
endmodule
