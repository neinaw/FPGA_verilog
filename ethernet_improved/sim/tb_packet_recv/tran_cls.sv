package tran_cls;

typedef struct {
    bit [7:0] pre[7]; // = '{8'h55, 8'h55, 8'h55, 8'h55, 8'h55, 8'55, 8'h55};
    bit [7:0] sfd; // = 8'hd5;
    bit [7:0] dest_mac[6];
    bit [7:0] src_mac[6];
    bit [7:0] ethertype[2];
    bit [7:0] payload[];
    bit [7:0] crc[4];
} ethernet_frame_t;

typedef bit[7:0] data_stream[$];

class Input_tran;
    ethernet_frame_t frame;
    int payload_size;
    data_stream frame_tx_order;
    bit bad_frame;

    function new(
        /* unpacked arrays so that initialization is easy*/
        bit [47:0] i_dest_mac,
        bit [47:0] i_src_mac,
        bit [15:0] i_ethertype,
        int i_payload_size,
        bit i_bad_frame = 1'b0
    );
    
        bit [31:0] ret;
        frame.pre = '{default: 8'h55};
        frame.sfd = 8'hd5;
        frame.dest_mac = {>>{i_dest_mac}};
        frame.src_mac  = {>>{i_src_mac}};
        frame.ethertype = {>>{i_ethertype}};
        frame.payload = new[i_payload_size];
        payload_size = i_payload_size;
        foreach(frame.payload[i]) frame.payload[i] = (i == frame.payload.size() - 1) ? 8'hFF : 8'hAA;

        bad_frame = i_bad_frame;
        if(!bad_frame) begin
            ret = get_crc(frame);
            frame.crc = {<<8{ret}};
        end else begin
            frame.crc = {0, 0, 0, 0};
        end

        frame_tx_order = {>>{
            frame.pre,
            frame.sfd,
            frame.dest_mac,
            frame.src_mac,
            frame.ethertype,
            frame.payload,
            frame.crc
        }};
    endfunction: new

    // cannot return arrays like this
    // local function bit[7:0] crc[4] get_crc();
    function bit[31:0] get_crc(ethernet_frame_t frame);
        bit [31:0] crc;
        bit [7:0] reflected;

        data_stream frame_data;
        frame_data = {>>{
            frame_data, 
            frame.dest_mac,
            frame.src_mac,
            frame.ethertype,
            frame.payload
        }};

        crc = '1;
        for (int i=0; i<frame_data.size(); i++) begin
            crc ^= {24'b0, frame_data[i]};
            for (int j = 0; j < 8; j++) begin
                if (crc[0]) crc = (crc >> 1) ^ 32'hEDB88320;
                else         crc = crc >> 1;
            end
        end
        crc = ~crc;

        return crc;
    endfunction: get_crc

    function string convert2string();
        string s;
        s = $sformatf("Destination MAC:\n");
        foreach (frame.dest_mac[i]) begin
            s = {s, $sformatf("%02x", frame.dest_mac[i])};
            if (i != 5) s = {s, ":"};
        end
        s = {s, "\n"};

        s = {s, $sformatf("Source MAC:\n")};
        foreach (frame.src_mac[i]) begin
            s = {s, $sformatf("%02x", frame.src_mac[i])};
            if (i != 5) s = {s, ":"};
        end
        s = {s, "\n"};

        s = {s, $sformatf("%02x%02x", frame.ethertype[0], frame.ethertype[1]), "\n"};

        s = {s, $sformatf("Payload Size %d", frame.payload.size()), "\n"};
        s = {s, $sformatf("Payload: %p", frame.payload), "\n"};

        s = {s, "CRC: \n"};
        foreach (frame.crc[i]) begin
            s = {s, $sformatf("%02x", frame.crc[i])};
            if (i != 3) s = {s, ":"};
        end
        s = {s, "\n"};

        return s;
    endfunction

    function Input_tran clone();

        Input_tran copy = new(
            {>>{frame.dest_mac}},
            {>>{frame.src_mac}},
            {>>{frame.ethertype}},
            payload_size,
            bad_frame
        );

        // CRC needs to be recalculated
        foreach(copy.frame.payload[i]) copy.frame.payload[i] = frame.payload[i];

        return copy;
    endfunction: clone

    function bit comp(Input_tran t);
        bit res = 1;
        foreach(t.frame.dest_mac[i])    res &= (t.frame.dest_mac[i] == frame.dest_mac[i]);
        foreach(t.frame.src_mac[i])     res &= (t.frame.src_mac[i] == frame.src_mac[i]);
        foreach(t.frame.ethertype[i])   res &= (t.frame.ethertype[i] == frame.ethertype[i]);
        foreach(t.frame.ethertype[i])   res &= (t.frame.ethertype[i] == frame.ethertype[i]);
        foreach(t.frame.payload[i])     res &= (t.frame.payload[i] == frame.payload[i]);
        foreach(t.frame.crc[i])         res &= (t.frame.crc[i] == frame.crc[i]);

        return res;
    endfunction
endclass

class Result_tran;

    // local bit [111:0] header;
    bit [7:0] dest_mac[6];
    bit [7:0] src_mac[6];
    bit [7:0] ethertype[2];
    bit [7:0] payload[$];

    function new(bit [111:0] i_header);

        // left-streaming operator converts packed to unpacked
        // https://www.consulting.amiq.com/2017/05/29/how-to-pack-data-using-systemverilog-streaming-operators/
        bit [7:0] header_unpacked[14] = {>>{i_header}};
        dest_mac   = header_unpacked[0:5];
        src_mac    = header_unpacked[6:11];
        ethertype  = header_unpacked[12:13];
    endfunction: new

    function void add_word(bit [7:0] word);
        payload.push_back(word);
    endfunction: add_word

    function string convert2string();

        string s;
        s = $sformatf("Destination MAC:\n");
        foreach (dest_mac[i]) begin
            s = {s, $sformatf("%02x", dest_mac[i])};
            if (i != 5) s = {s, ":"};
        end

        s = {s, "\n"};

        s = {s, $sformatf("Source MAC:\n")};
        foreach (src_mac[i]) begin
            s = {s, $sformatf("%02x", src_mac[i])};
            if (i != 5) s = {s, ":"};
        end
        s = {s, "\n"};

        s = {s, $sformatf("%02x%02x", ethertype[0], ethertype[1]), "\n"};

        s = {s, $sformatf("Payload Size %d", payload.size()), "\n"};
        s = {s, $sformatf("Payload: %p", payload), "\n"};
        return s;

    endfunction: convert2string

    function Result_tran clone();
        Result_tran copy;

        data_stream stream;
        stream = {>>{
            stream,
            dest_mac,
            src_mac,
            ethertype
        }};
        copy = new( {>>{stream}} );

        foreach (payload[i]) copy.payload[i] = payload[i];

        return copy;

    endfunction: clone

    function bit comp(Result_tran t);
        bit res = 1;
        data_stream stream_this, stream_in;
        stream_this = {>>{
            stream_this,
            dest_mac,
            src_mac,
            ethertype,
            payload
        }};

        stream_in = {>>{
            stream_in,
            t.dest_mac,
            t.src_mac,
            t.ethertype,
            t.payload
        }};

        foreach (stream_this[i]) res &= (stream_this[i] == stream_in[i]);
        return res;
    endfunction: comp

endclass

endpackage