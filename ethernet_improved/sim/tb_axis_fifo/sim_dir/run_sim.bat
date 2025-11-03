@echo off

call xvlog -sv -f ./packet_recv_compile_list.f -L uvm || exit \b
call xelab tb_top -relax -s top -timescale 1ns/1ps -debug all || exit \b
call xsim top --testplusarg "UVM_VERBOSITY=UVM_HIGH" -gui -tclbatch xsim_run.tcl || exit \b
pause