module tb_axis_fifo;
    parameter DATA_WIDTH = 8;
    parameter DEPTH      = 16;
    logic clk, rst;

    logic [DATA_WIDTH - 1 : 0] s_axis_tdata;
    logic s_axis_tvalid;
    logic s_axis_tlast;
    logic bad_frame;

    logic [DATA_WIDTH-1 : 0] m_axis_tdata;
    logic m_axis_tvalid;
    logic m_axis_tlast;
    logic m_axis_tready;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst = 1;
        #7 rst = 0;
    end

    task initialize();
        begin
            s_axis_tvalid = 0;
            s_axis_tdata = '0;
            s_axis_tlast = 0;
            bad_frame = 0;
            m_axis_tready = 0;
        end
    endtask

    task axis_write_word(input logic [DATA_WIDTH - 1:0] word, input logic bad_frame = 0, input logic tlast = 0);

        if(rst) @(negedge rst);

        @(posedge clk)
        s_axis_tdata <= word;
        s_axis_tvalid <= 1;
        s_axis_tlast <= tlast;
        bad_frame <= bad_frame;

        @(posedge clk);
        s_axis_tvalid <= 0;
    endtask

    task automatic axis_write_packet(input logic [DATA_WIDTH - 1:0] packet[], input bit bad = 0);
        int size = $size(packet);
        int i;
        // wait for reset deassertion
        if(rst) @(negedge rst);

        @(posedge clk);
        foreach (packet[i]) begin
            s_axis_tdata <= packet[i];
            s_axis_tvalid <= 1;
            s_axis_tlast <= (i == size-1) ? 1'b1 : 1'b0;
            bad_frame <= (i == size-1) ? bad : 0;
            @(posedge clk);
        end

        s_axis_tvalid <= 0;
        s_axis_tlast  <= 0;
        bad_frame  <= '0;
        return;
    endtask
    // #10 is at negedge of clk

    logic [DATA_WIDTH - 1 : 0] packet[0:7] = '{0, 1, 2, 3, 'hF, 'hC, 'hF, 'hC};
    logic [DATA_WIDTH - 1 : 0] packet2[0:7] = '{'hAA, 'hBB, 'hCC, 'hDD, 'hEE, 'hFF, 'hAB, 'hCD};
    initial begin
        initialize();
        // fork
        //     axis_write_packet(packet);
        //     m_axis_tready = 1;
        // join
        axis_write_packet(packet);
        @(negedge clk);
        axis_write_packet(packet2);
        @(negedge clk);
        axis_write_packet(packet, 1);
        @(negedge clk);
        fork
            axis_write_packet(packet2);
            #40 m_axis_tready = 1;
        join
        #100;
        @(negedge clk); $finish;
    end

    axis_fifo #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH)) DUT ( .* );
endmodule

