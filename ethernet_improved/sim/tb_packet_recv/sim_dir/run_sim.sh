#!/bin/bash

xvlog -sv -f ./packet_recv_compile_list.f -L uvm
xelab tb_top -relax -s top -timescale 1ns/1ps -debug all
xsim top --testplusarg "UVM_VERBOSITY=UVM_DEBUG" -gui -tclbatch xsim_run.tcl