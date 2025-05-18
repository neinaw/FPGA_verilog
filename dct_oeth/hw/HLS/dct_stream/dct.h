/*
# Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
# SPDX-License-Identifier: X11
*/

#ifndef __DCT_H__
#define __DCT_H__

#include <fstream>
#include <iostream>
#include <iomanip>
#include <cstdlib>
#include "hls_stream.h"
#include "ap_axi_sdata.h"

#define DW 16
// #define N 1024/DW
#define N 64
#define NUM_TRANS 16
#define AXIS_ENABLE_LAST 0b00010000

typedef short dct_data_t;

typedef ap_axiu<8, 0, 0, 0, AXIS_ENABLE_LAST> trans_pkt;
struct data {
    ap_int<8> data_field;
    ap_int<1> last;
};

#define DCT_SIZE 8    /* defines the input matrix as 8x8 */
#define CONST_BITS  13
#define DESCALE(x,n)  (((x) + (1 << ((n)-1))) >> n)

extern "C" {
  void dct(short input[N], short output[N]);
  void dct_stream(hls::stream<trans_pkt>& in_stream, hls::stream<trans_pkt>& out_stream);
}
#endif // __DCT_H__ not defined
