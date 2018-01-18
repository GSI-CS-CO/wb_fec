target = "xilinx"
action = "simulation"
sim_tool = "modelsim"
top_module = "main"
syn_device = "XC6VLX130T"

#files = [ "golay_tb.vhd" ]

#include_dirs = [ "../../sim", "../../sim/wr-hdl" ]

modules = { "local" : ["../"]}
#modules = { "local" : ["../../top/bare_top",
#                       "../../ip_cores/general-cores",
#                       "../../ip_cores/wr-cores"] }
					
files = [ "main.sv" ]
include_dirs = [ "../sim" ]
