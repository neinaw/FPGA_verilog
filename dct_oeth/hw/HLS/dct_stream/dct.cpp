/*
# Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
# SPDX-License-Identifier: X11
*/

#include "dct.h"

void dct_1d(dct_data_t src[DCT_SIZE], dct_data_t dst[DCT_SIZE])
{
   unsigned int k, n;
   int tmp;
   const dct_data_t dct_coeff_table[DCT_SIZE][DCT_SIZE] = {
#include "dct_coeff_table.txt"
   };

DCT_Outer_Loop:
   for (k = 0; k < DCT_SIZE; k++) {
DCT_Inner_Loop:
      for(n = 0, tmp = 0; n < DCT_SIZE; n++) {
         int coeff = (int)dct_coeff_table[k][n];
         tmp += src[n] * coeff;
      }
      dst[k] = DESCALE(tmp, CONST_BITS);
   }
}

void dct_2d(dct_data_t in_block[DCT_SIZE][DCT_SIZE],
      dct_data_t out_block[DCT_SIZE][DCT_SIZE])
{
   dct_data_t row_outbuf[DCT_SIZE][DCT_SIZE];
   dct_data_t col_outbuf[DCT_SIZE][DCT_SIZE], col_inbuf[DCT_SIZE][DCT_SIZE];
   unsigned i, j;

   // DCT rows
Row_DCT_Loop:
   for(i = 0; i < DCT_SIZE; i++) {
      dct_1d(in_block[i], row_outbuf[i]);
   }
   // Transpose data in order to re-use 1D DCT code
Xpose_Row_Outer_Loop:
   for (j = 0; j < DCT_SIZE; j++)
Xpose_Row_Inner_Loop:
      for(i = 0; i < DCT_SIZE; i++)
         col_inbuf[j][i] = row_outbuf[i][j];
   // DCT columns
Col_DCT_Loop:
   for (i = 0; i < DCT_SIZE; i++) {
      dct_1d(col_inbuf[i], col_outbuf[i]);
   }
   // Transpose data back into natural order
Xpose_Col_Outer_Loop:
   for (j = 0; j < DCT_SIZE; j++)
Xpose_Col_Inner_Loop:
      for(i = 0; i < DCT_SIZE; i++)
         out_block[j][i] = col_outbuf[i][j];
}

void read_data(short input[N], short buf[DCT_SIZE][DCT_SIZE])
{
   int r, c;

RD_Loop_Row:
   for (r = 0; r < DCT_SIZE; r++) {
RD_Loop_Col:
      for (c = 0; c < DCT_SIZE; c++)

buf[r][c] = input[r * DCT_SIZE + c];
   }
}

void write_data(short buf[DCT_SIZE][DCT_SIZE], short output[N])
{
   int r, c;

WR_Loop_Row:
   for (r = 0; r < DCT_SIZE; r++) {
WR_Loop_Col:
      for (c = 0; c < DCT_SIZE; c++)
         output[r * DCT_SIZE + c] = buf[r][c];
   }
}

void dct(short input[N], short output[N]) {


   short buf_2d_in[DCT_SIZE][DCT_SIZE];
   short buf_2d_out[DCT_SIZE][DCT_SIZE];

   // Read input data. Fill the internal buffer.
   read_data(input, buf_2d_in);

   dct_2d(buf_2d_in, buf_2d_out);


   // Write out the results.
   write_data(buf_2d_out, output);
   //write_data(buf_2d_in, output);
}

void dct_stream(hls::stream<trans_pkt>& in_stream, hls::stream<trans_pkt>& out_stream){
    #pragma HLS INTERFACE axis register_mode = both register port = in_stream
    #pragma HLS INTERFACE axis register_mode = both register port = out_stream
    #pragma HLS INTERFACE ap_ctrl_none port=return
    short buffer_in[DCT_SIZE][DCT_SIZE];
    short buffer_out[DCT_SIZE][DCT_SIZE];
    trans_pkt in_val, out_val;
    ap_int<16> in_buf, out_buf;
    int count = 0;
    bool last = false;

READ_LOOP:
    for(int i=0; i<64; i++) {
        // II is 2 for the 2 reads from the stream
        #pragma HLS PIPELINE II = 2

        if(!last) {
            in_val = in_stream.read();
            in_buf = ap_int<16>(in_val.data);
            last = bool(in_val.last);
            if(!in_val.last) {
                in_val = in_stream.read();
                last = bool(in_val.last);
                in_buf = (in_buf << 8) + in_val.data;
            }
            buffer_in[i/DCT_SIZE][i % DCT_SIZE] = in_buf;
        }
        else {
            buffer_in[i/DCT_SIZE][i % DCT_SIZE] = 0;
        }
    }
    last = false;

    dct_2d(buffer_in, buffer_out);

    count = 0;

WRITE_LOOP:
    do {
        // II is 2 for the two writes on the stream
        #pragma HLS PIPELINE II = 2

        out_buf = buffer_out[count/DCT_SIZE][count % DCT_SIZE];

        // write MSB
        out_val.data = ap_uint<8>(out_buf >> 8);
        out_val.last = (count == DCT_SIZE*DCT_SIZE-1);
        out_stream.write(out_val);

        // write LSB
        out_val.data = ap_uint<8>(out_buf & 255);
        out_val.last = (count == DCT_SIZE*DCT_SIZE-1);
        out_stream.write(out_val);
        count++;
    } while(count < DCT_SIZE * DCT_SIZE);
}