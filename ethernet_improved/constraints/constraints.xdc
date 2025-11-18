set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports CLK]
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
## Clock signal

# the following create_clock is not needed when a clock is created from the clocking wizard
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports CLK]
create_generated_clock -name eth_clk -source [get_pins eth_rst_gen_i/gen_50M/inst/mmcm_adv_inst/CLKIN1] [get_pins eth_rst_gen_i/gen_50M/inst/mmcm_adv_inst/CLKOUT0]
create_generated_clock -name fwd_clk -source [get_pins ODDR_inst/C] -divide_by 1 [get_ports ETH_REFCLK]

#set_output_delay -clock eth_clk 2.5 [get_ports ETH_TXEN]
#set_output_delay -clock eth_clk 2.5 [get_ports {ETH_TXD[*]}]


# Output Delay Constraint
set_output_delay -clock fwd_clk -max 4.50 [get_ports {ETH_TXEN {ETH_TXD[0]} {ETH_TXD[1]} ETH_RSTN}]
set_output_delay -clock fwd_clk -min -1.1 [get_ports {ETH_TXEN {ETH_TXD[0]} {ETH_TXD[1]} ETH_RSTN}]

#set_input_delay -clock eth_clk 10.0 [get_ports ETH_CRSDV]
#set_input_delay -clock eth_clk 10.0 [get_ports {ETH_RXD[*]}]

# list of ports should not be comma separated!!!

# Input Delay Constraint
set_input_delay -clock fwd_clk -max 14.5 [get_ports {ETH_CRSDV {ETH_RXD[0]} {ETH_RXD[1]}}]
set_input_delay -clock fwd_clk -min 3.40 [get_ports {ETH_CRSDV {ETH_RXD[0]} {ETH_RXD[1]}}]

set_multicycle_path -from [get_ports ETH_CRSDV] -to [get_pins {receiver/rxdv_z_reg[0]/D}] 2
set_multicycle_path -from [get_ports {ETH_RXD[0]}] -to [get_pins {receiver/rxd_z_reg[0][0]/D}] 2
set_multicycle_path -from [get_ports {ETH_RXD[1]}] -to [get_pins {receiver/rxd_z_reg[0][1]/D}] 2

set_false_path -from [get_ports RST_N]



#set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
#set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
#set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
#connect_debug_port dbg_hub/clk [get_nets eth_clk]

set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets eth_clk]
