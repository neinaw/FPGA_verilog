@echo off
echo === Starting Script ===

echo Running xvlog bram...
call xvlog --sv hdl/bram.sv
echo Exit code: %errorlevel%

echo Running xvlog fwft_fifo...
call xvlog --sv hdl/fwft_fifo.sv
echo Exit code: %errorlevel%

echo Running xvlog tb_fifo_bram...
call xvlog --sv sim/tb_fifo_bram.sv
echo Exit code: %errorlevel%

echo Running xelab...
call xelab -debug all tb_fifo_bram -s top_sim
echo Exit code: %errorlevel%

echo Running xsim...
call xsim top_sim -gui -t xsim_run.tcl
echo Exit code: %errorlevel%

echo === Done ===
