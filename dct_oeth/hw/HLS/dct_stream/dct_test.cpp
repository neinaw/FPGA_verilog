#include "dct.h"
#include <iostream>

int main(){
    hls::stream<trans_pkt> in_stream, out_stream;
    trans_pkt in_word;
    ap_int<16> out_res = 0;

    for(short i=0; i<64; i++){
        in_word.data = ap_int<8>(i >> 8);
        in_word.last = 0;
        in_stream.write(in_word);

        in_word.data = ap_int<8>(i & 255);
        in_word.last = (i==63);
        in_stream.write(in_word);
    }

    dct_stream(in_stream, out_stream);
    for(int i=0; i<64; i++){
        if (out_stream.empty()) {  // Prevent hanging
            std::cerr << "Error: out_stream ended early at i=" << i << std::endl;
            break;
        }
        in_word = out_stream.read();
        out_res = ap_uint<16>(in_word.data) << 8;
        in_word = out_stream.read();
        // ap_uint<8> tmp = ap_uint<8>(in_word.data);
        out_res = out_res + ap_uint<8>(in_word.data);
        std::cout << i << " Data: " << out_res << " last: " << in_word.last << '\n';
    }
}
