module axis_fifo_new #(
    parameter int DATA_WIDTH = 8,
    parameter int DEPTH      = 1024
)(
    input bit clk, rst,

    // slave side 
    input logic [7:0] s_axis_tdata,
    input logic       s_axis_tvalid,
    input logic       s_axis_tlast,
    input logic       bad_frame, // bad_frame
    output logic      s_axis_tready,

    // master side
    output logic [7:0] m_axis_tdata,
    output logic       m_axis_tvalid,
    output logic       m_axis_tlast,
    input  logic       m_axis_tready
);

    // parameters and defines
    localparam ADDR_WIDTH = $clog2(DEPTH);
    typedef struct packed {
        logic [DATA_WIDTH-1:0] data;
        logic                  last;
    } mem_word_t;

    typedef enum logic [1:0] {EMPTY, NON_EMPTY, FULL} state_t;
    typedef enum logic [1:0] {NA = 2'b00, O_WR = 2'b10, O_RD = 2'b01, O_WR_RD = 2'b11} req_t;

    // memory
    (* ram_style = "block" *) mem_word_t mem[0 : (1<<ADDR_WIDTH) - 1];

    // read and write pointers
    logic [ADDR_WIDTH - 1 :0] wr_ptr, next_wr_ptr, orig_wr_ptr;
    logic [ADDR_WIDTH - 1 :0] rd_ptr, next_rd_ptr;

    // internal signals
    logic full, next_full;
    logic empty, next_empty;
    logic wr_enable, rd_enable;
    logic discard, next_discard;

    logic [$clog2(DEPTH):0] count, next_count;

    state_t state = EMPTY, next_state;

    always_ff @(posedge clk) begin
        if(rst) begin
            wr_ptr          <= '0;
            orig_wr_ptr     <= '0;
            rd_ptr          <= '0;
            full            <= '0;
            empty           <=  1;
            discard         <= '0;
            count           <= '0;
            state           <= EMPTY;
        end

        else begin
            wr_ptr <= next_wr_ptr;
            rd_ptr <= next_rd_ptr;
            full   <= next_full;
            empty  <= next_empty;
            discard <= next_discard;
            state  <= next_state;
            count  <= next_count;
            if(wr_enable & ~discard) begin
                mem[wr_ptr] <= {s_axis_tdata, 1'b0};
                if(commit) begin
                    mem[wr_ptr - 3'd4].last <= 1'b1;
                    orig_wr_ptr <= wr_ptr - 2'd3;;
                    wr_ptr      <= wr_ptr - 2'd3;
                end
            end
        end
    end 

    logic commit;
    logic [1:0] req;
    assign req = {s_axis_tvalid, m_axis_tready};
    always_comb begin
        commit = 0;
        wr_enable = 0;
        next_discard = discard;
        next_full = full;
        next_empty = empty;
        next_state = state;
        next_rd_ptr = rd_ptr;
        next_wr_ptr = wr_ptr;
        next_count = count;
        case(state)

            EMPTY: begin
                s_axis_tready = 1;
                m_axis_tvalid = 0;
                next_empty = 1;
                next_count = 0;
                if(s_axis_tvalid) begin
                    if(!discard) begin
                        next_wr_ptr = wr_ptr + 1;

                        if (s_axis_tlast) begin
                            if(!bad_frame) begin
                            commit = 1;
                            next_state = NON_EMPTY;
                            next_count = count + 1;
                            wr_enable = 1;
                                if(next_wr_ptr == rd_ptr) begin
                                    next_full = 1;
                                    next_state = FULL;
                                end
                            end 

                            else begin
                                next_wr_ptr = orig_wr_ptr;
                                next_state = EMPTY;
                            end
                        end

                        else begin
                            if(next_wr_ptr == rd_ptr) next_discard = 1;
                            else wr_enable = 1;
                        end
                    end
                    else begin
                        if(s_axis_tlast) next_discard = 0;
                    end
                end
            end

            NON_EMPTY: begin
                next_discard = 0;
                next_empty = 0; 
                next_full = 0;
                s_axis_tready = 1;
                m_axis_tvalid = 1;

                case(req)

                    NA: ; // do nothing

                    O_WR: begin // write only
                        if(!discard) begin
                            next_wr_ptr = wr_ptr + 1;

                            if (s_axis_tlast) begin
                                if (!bad_frame) begin
                                    commit = 1;
                                    next_discard = 0;
                                    next_count = count + 1;

                                    if(next_wr_ptr == rd_ptr) begin
                                        next_state = FULL;
                                        next_full = 1;
                                    end

                                    wr_enable = 1;
                                    // next_wr_ptr = wr_ptr - 2'd3;
                                end
                                else begin
                                    next_wr_ptr = orig_wr_ptr;
                                    next_state = EMPTY;
                                end
                            end
                            else begin
                                if(next_wr_ptr == rd_ptr) next_discard = 1;
                                wr_enable = 1;
                            end
                        end
                    end
                    
                    O_RD: begin // ready only
                        next_rd_ptr = rd_ptr + 1;
                        if(mem[rd_ptr].last) begin
                            next_count = count - 1;
                            if(next_count == 0) next_state = EMPTY;
                        end
                    end

                    O_WR_RD: begin // write and read
                        // writing a new frame but reading an old one
                        // handle both atomic write logic and read
                        // if last of read and write coincide,
                        // then count does not change
                        next_wr_ptr = wr_ptr + 1;
                        next_rd_ptr = rd_ptr + 1;
                        if(!discard) begin
                            if (s_axis_tlast) begin
                                if (!bad_frame) begin
                                    commit = 1;

                                    if(!mem[rd_ptr].last)
                                        next_count = count + 1;

                                    wr_enable = 1;
                                    // next_wr_ptr = wr_ptr - 2'd3;
                                end
                                else begin
                                    next_wr_ptr = orig_wr_ptr;
                                    next_state = EMPTY;
                                end
                            end
                            else begin
                                wr_enable = 1;
                            end
                        end
                        if(mem[rd_ptr].last & ~s_axis_tlast) begin
                            next_count = count - 1;
                        end
                    end

                endcase
            end

            FULL: begin
                next_full = 1;
                m_axis_tvalid = 1;
                s_axis_tready = 0;
                case(req)

                    NA: ; // nothing
                    O_WR: ; // only writes not allowed

                    O_RD: begin // ready only
                        next_rd_ptr = rd_ptr + 1;
                        if(mem[rd_ptr].last) begin
                            next_count = count - 1;
                            if(next_count == 0) next_state = EMPTY;
                            else next_state = NON_EMPTY;
                        end
                    end
                    
                    O_WR_RD: begin // write and read
                        // writing a new frame but reading an old one
                        // handle both atomic write logic and read
                        // if last of read and write coincide,
                        // then count does not change
                        next_wr_ptr = wr_ptr + 1;
                        next_rd_ptr = rd_ptr + 1;
                        if(!discard) begin
                            if (s_axis_tlast) begin
                                if (!bad_frame) begin
                                    commit = 1;

                                    if(!mem[rd_ptr].last)
                                        next_count = count + 1;

                                    wr_enable = 1;
                                    // next_wr_ptr = wr_ptr - 2'd3;
                                end
                                else begin
                                    next_wr_ptr = orig_wr_ptr;
                                    // write failed
                                    next_state = NON_EMPTY;
                                end
                            end
                            else begin
                                wr_enable = 1;
                            end
                        end
                        if(mem[rd_ptr].last & ~s_axis_tlast) begin
                            next_count = count - 1;
                        end
                    end

                endcase

            end

        endcase
    end

    // assign s_axis_tready = ~full;
    // assign m_axis_tvalid = ~empty;
    assign m_axis_tdata = mem[rd_ptr].data; 
    assign m_axis_tlast = mem[rd_ptr].last;

endmodule