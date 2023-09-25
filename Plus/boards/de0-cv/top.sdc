create_clock -period "50.0 MHz" [get_ports clk1_50]
#create_clock -period 20 [get_ports clk]

derive_clock_uncertainty

set_false_path -from [get_ports {key[*]}]  -to [all_clocks]
set_false_path -from [get_ports {sw[*]}]   -to [all_clocks]

set_false_path -from * -to [get_ports {led[*]}]

set_false_path -from * -to [get_ports {hex0[*]}]
set_false_path -from * -to [get_ports {hex1[*]}]
set_false_path -from * -to [get_ports {hex2[*]}]
set_false_path -from * -to [get_ports {hex3[*]}]
set_false_path -from * -to [get_ports {hex4[*]}]

set_false_path -from rx -to [all_clocks]
set_false_path -from reset -to [all_clocks]


set_false_path -from * -to vga_hs
set_false_path -from * -to vga_vs
set_false_path -from * -to [get_ports {vga_r[*]}]
set_false_path -from * -to [get_ports {vga_g[*]}]
set_false_path -from * -to [get_ports {vga_b[*]}]

set_false_path -from * -to tx
set_false_path -from * -to dh

set_false_path -from * -to lpt_STROBE
set_false_path -from * -to lpt_data


set_false_path -from * -to sd
set_false_path -from * -to sck
set_false_path -from * -to ws
set_false_path -from * -to lr
