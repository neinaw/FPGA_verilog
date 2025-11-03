## Clock signal
set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports CLK]

# the following create_clock is not needed when a clock is created from the clocking wizard
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports CLK]
create_generated_clock -name eth_clk [get_pins {eth_rst_gen_i/gen_50M/inst/mmcm_adv_inst/CLKOUT0}]

#set_output_delay -clock eth_clk 2.5 [get_ports ETH_TXEN]
#set_output_delay -clock eth_clk 2.5 [get_ports {ETH_TXD[*]}]

set destination_clock eth_clk;     # Name of destination clock
set tsu               4.000;            # Destination device setup time requirement
set thd               1.500;            # Destination device hold time requirement
set trce_dly_max      1.000;            # Maximum board trace delay
set trce_dly_min      0.000;            # Minimum board trace delay
set output_ports      {ETH_TXEN ETH_TXD[0] ETH_TXD[1] ETH_RSTN};   # List of output ports

# Output Delay Constraint
set_output_delay -clock $destination_clock -max [expr $trce_dly_max + $tsu] [get_ports $output_ports];
set_output_delay -clock $destination_clock -min [expr $trce_dly_min - $thd] [get_ports $output_ports];

#set_input_delay -clock eth_clk 10.0 [get_ports ETH_CRSDV]
#set_input_delay -clock eth_clk 10.0 [get_ports {ETH_RXD[*]}]

set input_clock     eth_clk;   # Name of input clock
set tco_max         14.000;          # Maximum clock to out delay (external device)
set tco_min         3.000;          # Minimum clock to out delay (external device)
set trce_dly_max    1.000;          # Maximum board trace delay
set trce_dly_min    0.000;          # Minimum board trace delay
# list of ports should not be comma separated!!!
set input_ports     {ETH_CRSDV ETH_RXD[0] ETH_RXD[1]};  # List of input ports

# Input Delay Constraint
set_input_delay -clock $input_clock -max [expr $tco_max + $trce_dly_max] [get_ports $input_ports];
set_input_delay -clock $input_clock -min [expr $tco_min + $trce_dly_min] [get_ports $input_ports];

set_false_path -from [get_ports RST_N]

set_property -dict {PACKAGE_PIN C12 IOSTANDARD LVCMOS33} [get_ports RST_N]

set_property -dict {PACKAGE_PIN C9 IOSTANDARD LVCMOS33} [get_ports ETH_MDC]
set_property -dict {PACKAGE_PIN A9 IOSTANDARD LVCMOS33} [get_ports ETH_MDIO]
set_property -dict {PACKAGE_PIN B3 IOSTANDARD LVCMOS33} [get_ports ETH_RSTN]
set_property -dict {PACKAGE_PIN D9 IOSTANDARD LVCMOS33} [get_ports ETH_CRSDV]
set_property -dict {PACKAGE_PIN C10 IOSTANDARD LVCMOS33} [get_ports ETH_RXERR]
set_property -dict {PACKAGE_PIN C11 IOSTANDARD LVCMOS33} [get_ports {ETH_RXD[0]}]
set_property -dict {PACKAGE_PIN D10 IOSTANDARD LVCMOS33} [get_ports {ETH_RXD[1]}]
set_property -dict {PACKAGE_PIN B9 IOSTANDARD LVCMOS33} [get_ports ETH_TXEN]
set_property -dict {PACKAGE_PIN A10 IOSTANDARD LVCMOS33} [get_ports {ETH_TXD[0]}]
set_property -dict {PACKAGE_PIN A8 IOSTANDARD LVCMOS33} [get_ports {ETH_TXD[1]}]
set_property -dict {PACKAGE_PIN D5 IOSTANDARD LVCMOS33} [get_ports ETH_REFCLK]
set_property -dict {PACKAGE_PIN B8 IOSTANDARD LVCMOS33} [get_ports ETH_INTN]

#set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
#set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
#set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
#connect_debug_port dbg_hub/clk [get_nets eth_clk]
