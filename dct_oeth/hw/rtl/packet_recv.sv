`timescale 1 ns / 1 ps

/*
* RMII --> AXIS
*/

module packet_recv #(
    parameter [47:0] FPGA_MAC = 48'h00_18_3e_04_b3_f2,
    parameter [47:0] HOST_MAC = 48'h54_e1_ad_33_0d_32,
    parameter DATA_WIDTH = 8,
    parameter DEPTH      = 1024
) (
    input [1:0] RXD,
    input       RXDV,

    input clk,
    input rst,

    output                    m_axis_tvalid,
    output [DATA_WIDTH-1 : 0] m_axis_tdata,
    output                    m_axis_tlast,
    input                     m_axis_tready
);

    // Triple-register received mii data
    // metastability

    /* localparam	   WORD_BYTES = 4; */
    localparam integer MII_WIDTH = 2;
    localparam [47:0] BROADCAST = 48'hFF_FF_FF_FF_FF_FF;

    localparam ADDR_SPACE_EXP = $clog2(DEPTH);

    logic [2:0][MII_WIDTH-1:0] rxd_z;
    logic [2:0]                rxdv_z;

    always @(posedge clk) begin
        if (rst) begin
            rxd_z  <= 0;
            rxdv_z <= 0;
        end else begin
            rxd_z[0] <= RXD;
            rxd_z[2:1] <= rxd_z[1:0];

            rxdv_z[0] <= RXDV;
            rxdv_z[2:1] <= rxdv_z[1:0];
        end
    end

    /*
   +----------------+----------+------------------+------------------+------------+---------------------+---------+
   | Preamble (7B)  | SFD (1B) | Dest MAC (6B)    | Src MAC (6B)     | Type (2B)  | Payload (46-1500B)  | CRC (4B)|
   +----------------+----------+------------------+------------------+------------+---------------------+---------+
			       |<-------------------- Header -------------------->|
   */
    typedef struct packed {
        // Ethernet Frame Header
        // no FCS, added later
        logic [1:0][7:0] eth_type_length;
        logic [5:0][7:0] mac_source;
        logic [5:0][7:0] mac_destination;
    } ethernet_header;

    // write in received data until packet has ended
    // this occurs when rxdv goes low.

    logic packet_done;
    logic packet_start;
    assign packet_start = (rxdv_z[2] == 0 && rxdv_z[1] == 1) ? 1 : 0;
    assign packet_done  = (rxdv_z[2] == 1 && rxdv_z[1] == 0) ? 1 : 0;
    logic crc_en; 
    logic crc_rst, next_crc_rst;
    logic [3:0][7:0] running_crc;
    logic bad_frame, next_bad_frame;

    //dividing by 2 since we Rx/Tx 2 bits at a time
    localparam HEADER_CYCLES = $bits(ethernet_header) / 2;
    localparam PREAMBLE_SFD_CYCLES = 8 * 8 / 2;
    // localparam FCS_CYCLES = 4 * 8 / 2;

    // header and state buffers
    logic [ 7:0] data_buffer;
    logic [63:0] preamble_sfd_buffer;
    logic [63:0] preamble_sfd_buffer_next;
    // logic [31:0] fcs_buffer, next_fcs_buffer;
    logic [31:0] crc_buffer, next_crc_buffer;
    ethernet_header header_buffer;

    // State machine
    typedef enum {
        IDLE,
        PREAMBLE_SFD,
        HEADER,
        DATA
        // ,FCS
    } state_type;

    state_type current_state = IDLE;
    state_type next_state    = IDLE;

    // count the time spent in each state
    logic [31:0]  state_counter;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_counter <= '0;

        end else begin
            if (current_state != next_state) begin
                state_counter <= '0;

            end else begin
                // otherwise increment counter and shift buffer
                state_counter <= state_counter + 1'b1;
            end
        end
    end

    logic [47:0] packet_destination;
    logic [1:0][7:0] ethertype;
    // logic [1:0][7:0] data_cycles;

    //MAGIC! this swaps the endianness of the destination.
    //note we get the destination MSB first, so our buffer
    //has the value like:
    // IF dest mac is		     00 11 22 33 44 55
    // then the buffer gets filled -> 55 44 33 22 11 00
    assign packet_destination = {<<8{header_buffer.mac_destination}};

    //length of data payload in bytes
    // assign ethertype = {<<8{header_buffer.eth_type_length}};
    // assign data_cycles = ethertype * 8 / 2;

    // 3 process state machine
    // 1) decide which state to go into next
    always_comb begin
        next_state = current_state;
        crc_en = 1'b0;
        case (current_state)
            IDLE: begin
                if (packet_start) begin
                    next_state = PREAMBLE_SFD;
                end
            end
            PREAMBLE_SFD: begin
                if (preamble_sfd_buffer_next == 64'hd555555555555555) begin
                    next_state = HEADER;
                end
            end
            HEADER: begin
                crc_en = 1'b1;
                if (state_counter == HEADER_CYCLES - 1) begin
                    next_state = DATA;
                end

                // packet has ended, go back to IDLE
                if (packet_done) next_state = IDLE;
            end
            DATA: begin
                crc_en = 1'b1;
                if (packet_destination != FPGA_MAC) next_state = IDLE;
                      // uncomment below line later
                    // if (packet_destination != BROADCAST) next_state = IDLE;
                // packet has ended, go back to IDLE
                if(packet_done) next_state = IDLE;
            end
            default: next_state = current_state;
        endcase
    end


    //2) register into that state
    always @(posedge clk) begin
        if (rst) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end

    end

    logic data_valid;
    logic data_last;
    
    assign preamble_sfd_buffer_next[63:62] = rst ? 0 : rxd_z[2];
    assign preamble_sfd_buffer_next[61:0]  = rst ? 64'b0 : preamble_sfd_buffer[63:2];

    // populate and shift buffers according to state
    always_ff @(posedge clk) begin
        if (rst == 1) begin
            preamble_sfd_buffer <= 0;
            header_buffer       <= 0;
            data_buffer         <= 0;
            crc_buffer          <= 0;
            data_valid          <= 0;
            data_last           <= 0;
            bad_frame           <= 0;
            crc_rst             <= 0;
        end else begin
            data_valid <= 0;
            data_last  <= 0;
            crc_buffer <= next_crc_buffer;
            bad_frame  <= next_bad_frame;
            crc_rst    <= next_crc_rst;

            case (current_state)
                PREAMBLE_SFD: begin
                    preamble_sfd_buffer <= preamble_sfd_buffer_next;
                end

                HEADER: begin
                    header_buffer[(HEADER_CYCLES*2)-1-:2] <= rxd_z[2];
                    header_buffer[(HEADER_CYCLES*2)-3:0]  <= header_buffer[(HEADER_CYCLES*2)-1:2];
                end

                DATA: begin
                    data_buffer[7:6] <= rxd_z[2];
                    data_buffer[5:0] <= data_buffer[7:2];

                    if (state_counter[1:0] == 3)  /*&& (packet_destination == FPGA_MAC*/ begin
                        data_valid <= 1;

                    end
                    if (packet_done) begin
                        data_last <= 1;
                    end
                end

            endcase
        end
    end

    assign next_crc_rst = (next_state == IDLE && current_state != IDLE) ? 1'b1 : 1'b0;

    crc_gen crc_rx (
        .data_in(rxd_z[2]),
        .crc_en(crc_en),
        .crc_out(running_crc),
        .rst(rst | crc_rst),
        .clk(clk)
    );

    assign next_crc_buffer = crc_en ? running_crc : crc_buffer;

    assign next_bad_frame = (packet_done && running_crc != 32'h2144DF1C) ? 1'b1 : 1'b0;
    
    axis_fifo #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH)) axis_fifo_unit (
        .clk(clk),
        .rst(rst),

        .s_axis_tdata(data_buffer),
        .s_axis_tvalid(data_valid),
        .s_axis_tlast(data_last),
        .bad_frame(bad_frame),

        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tlast(m_axis_tlast),
        .m_axis_tready(m_axis_tready)
    );

endmodule
