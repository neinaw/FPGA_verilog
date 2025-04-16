package tran_cls;

import uvm_pkg::*;
`include "uvm_macros.svh"

class Input_tran;

    // logic [7:0] payload[];
    // bit bad_frame;
    rand bit [7:0] payload[];
    rand bit bad_frame;

    constraint payload_size_range {
        payload.size() inside {[5:200]};
    }
    constraint payload_badness {
        // bad 1/10th of the time (Considering actual BER of ethernet, this constraint is very tight)
        bad_frame dist {0:= 9, 1:= 1};
    }

    // the following is was done before randomization
    // after randomization, we do not need it, but still might need to force a certain payload
    function new(int len = 64, bit i_bad_frame = 0);
        bad_frame = i_bad_frame;
        payload = new[len];

        for (int i=0; i<len; i++) begin
            payload[i] = (i == len-1) ? 8'hFF : 8'hAA;
        end
    endfunction: new

    // function void init(int len, bit i_bad_frame = 0);
    //     bad_frame = i_bad_frame;
    //     payload = new[len];

    //     for (int i=0; i<len; i++) begin
    //         payload[i] = (i == len-1) ? 8'hFF : 8'hAA;
    //     end
    // endfunction: init

    function string convert2string();
        string result;
        result = $sformatf("Payload Length: %d,  Bad Frame: %b\n", payload.size(), bad_frame);
        result = {result, "Payload: \n"};

        foreach(payload[i]) begin
            if (i !=0) result = {result, " "};
            result = {result, $sformatf("%02x", payload[i])};

            if ((i+1) % 16 == 0 && (i+1) != payload.size()) begin
                result = {result, "\n"};
            end
        end

        return result;
    endfunction: convert2string

    function Input_tran clone();
        Input_tran copy = new(payload.size());
        foreach(copy.payload[i]) begin
            copy.payload[i] = this.payload[i];
        end
        copy.bad_frame = this.bad_frame;
        return copy;
    endfunction: clone

    function bit comp(Input_tran t);
        bit res = 1;
        if(t.payload.size() == payload.size()) begin
            foreach(t.payload[i]) begin
                res = res & (t.payload[i] == payload[i]);
            end
            return res;
        end
        else begin
            return 0;
        end
    endfunction
endclass

class Result_tran;

    bit [7:0] payload [$];

    function void add_word(bit [7:0] word);
        payload.push_back(word);
    endfunction: add_word

    function string convert2string();
        string result;
        result = $sformatf("Payload Length: %d\n", payload.size());
        result = {result, "Payload: \n"};

        foreach(payload[i]) begin
            if (i !=0) result = {result, " "};
            result = {result, $sformatf("%02x", payload[i])};

            if ((i+1) % 16 == 0 && (i+1) != payload.size()) begin
                result = {result, "\n"};
            end
        end

        return result;
    endfunction: convert2string

    function Result_tran clone();
        Result_tran copy = new();
        foreach(payload[i]) begin
            copy.add_word(payload[i]);
        end
        return copy;
    endfunction: clone

    function bit comp(Result_tran t);
        return(t.payload.size() == payload.size() && t.payload == payload);
    endfunction: comp

endclass
endpackage