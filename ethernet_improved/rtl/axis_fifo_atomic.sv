module axis_fifo_atomic #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 10,
    parameter DEPTH      = 1 << ADDR_WIDTH
) (
    input  logic                  clk,
    input  logic                  rst,

    // AXI-S (input)
    input  logic [DATA_WIDTH-1:0] s_axis_tdata,
    input  logic                  s_axis_tvalid,
    input  logic                  s_axis_tlast,
    input  logic                  s_axis_tuser,
    output logic                  s_axis_tready,

    // AXI-M (output)
    output logic [DATA_WIDTH-1:0] m_axis_tdata,
    output logic                  m_axis_tvalid,
    output logic                  m_axis_tlast,
    input  logic                  m_axis_tready
);
    /* tuser is the bad_frame indicator */
    localparam BRAM_DATA_WIDTH = DATA_WIDTH + 1;

    // BRAM interface signals
    logic bram_we;
    logic [ADDR_WIDTH-1:0] bram_wr_addr;
    logic [BRAM_DATA_WIDTH-1:0] bram_din;
    logic [ADDR_WIDTH-1:0] bram_rd_addr;
    logic [BRAM_DATA_WIDTH-1:0] bram_dout;

    // State machine & Write side pointers
    typedef enum logic[1:0] {IDLE, WRITE, DROP} state_t;
    state_t state;
    logic [ADDR_WIDTH-1:0] wr_ptr, commit_ptr, frame_start_ptr;

    // Read side pointers
    logic [ADDR_WIDTH-1:0] rd_ptr;
    logic [DATA_WIDTH-1:0] data_out_buf;
    logic tlast_out_buf;
    logic valid_out_buf;

    // frame count//occupancy indicators
    // width is +1 for extra full/empty state
    logic [ADDR_WIDTH:0] spec_occupancy;
    logic [ADDR_WIDTH:0] commit_occupancy;
    logic fifo_full_spec;
    logic fifo_empty;

    wire [ADDR_WIDTH:0] wr_ptr_ext = {1'b0, wr_ptr};
    wire [ADDR_WIDTH:0] rd_ptr_ext = {1'b0, rd_ptr};
    wire [ADDR_WIDTH:0] commit_ptr_ext = {1'b0, commit_ptr};

    assign spec_occupancy = wr_ptr_ext - rd_ptr_ext;
    assign commit_occupancy = commit_ptr_ext - rd_ptr_ext;

    assign fifo_full_spec = (spec_occupancy == DEPTH);
    assign fifo_empty = (commit_occupancy == 0);

    // bram_sp #(.DATA_WIDTH(BRAM_DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) ram (
    //     .clk(clk),
    //     .we(bram_we),
    //     .wr_addr(bram_wr_addr),
    //     .din(bram_din),
    //     .rd_addr(bram_rd_addr),
    //     .dout(bram_dout)
    // );
    wire fetch_data;
    bram #(.DATA_W(BRAM_DATA_WIDTH), .DEPTH(1<<ADDR_WIDTH)) ram (
        .clk(clk),
        .i_wren(bram_we),
        .i_waddr(bram_wr_addr),
        .i_wdata(bram_din),
        .i_rden(fetch_data),
        .i_raddr(rd_ptr),
        .o_rdata(bram_dout)
    );

    // Write Side Atomic Write Logic

    // Ready unless IDLE and Full
    assign s_axis_tready = (state == IDLE) ? !fifo_full_spec : 1'b1;

    assign bram_we = (state != DROP) && (s_axis_tvalid && s_axis_tready);
    assign bram_wr_addr = wr_ptr;
    assign bram_din = {s_axis_tlast, s_axis_tdata};

    // FSM & wr_ptr logic
    always_ff @(posedge clk) begin
        if(rst) begin
            state <= IDLE;
            wr_ptr <= '0;
            frame_start_ptr <= '0;
            commit_ptr <= '0;
        end else begin
            case(state)
                IDLE: begin
                    if(s_axis_tvalid && s_axis_tready) begin
                        frame_start_ptr <= wr_ptr;
                        wr_ptr <= wr_ptr + 1;
                        if(s_axis_tlast) begin
                            // single beat frame
                            if(!s_axis_tuser) commit_ptr <= wr_ptr + 1;
                        end else begin
                            state <= WRITE;
                        end
                    end
                end
                WRITE: begin
                    if(s_axis_tvalid) begin // ready is 1
                        if(fifo_full_spec) begin
                            state <= DROP;
                        end else begin
                            wr_ptr <= wr_ptr + 1;
                            if(s_axis_tlast) begin
                                if(!s_axis_tuser) commit_ptr <= wr_ptr + 1;
                                // else DROP handled below
                                state <= IDLE;
                            end
                        end
                    end
                end
                DROP: begin
                    // ready is one
                    // consume data but don't write anywhere
                    // break on last
                    if(s_axis_tvalid & s_axis_tlast) state <= IDLE;
                end
            endcase
            if(s_axis_tvalid & s_axis_tready & s_axis_tlast) begin
                if(s_axis_tuser || (state == DROP)) wr_ptr <= frame_start_ptr;
            end
        end
    end

    // Read Logic with 1 cycle latency

    assign bram_rd_addr = rd_ptr;

    assign m_axis_tvalid = valid_out_buf;
    assign {m_axis_tlast, m_axis_tdata} = bram_dout;

    // read pointer and output register logic
    wire rd_en = valid_out_buf & m_axis_tready;
    assign fetch_data = (rd_en || (!valid_out_buf)) && !fifo_empty;

    always_ff @(posedge clk) begin
        if(rst) begin
            rd_ptr <= 0;
            valid_out_buf <= 0;
            tlast_out_buf <= 0;
            data_out_buf <= 8'h00;
        end else begin
            // pre-fetch the BRAM to register its output

            if(fetch_data) begin
                valid_out_buf <= 1;
                rd_ptr <= rd_ptr + 1;
            end else begin
                if(rd_en) begin
                    valid_out_buf <= 0;
                    tlast_out_buf <= 0;
                end
            end
        end
    end
endmodule