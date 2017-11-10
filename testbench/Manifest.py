action = "simulation"

#target = "altera"
#syn_device = "5agxma3d4f"
#syn_grade = "i3"
#syn_package = "27"

target = "xilinx"
syn_device = "xc6slx45t"
syn_grade = "-3"
syn_package = "fgg484"

sim_tool = "modelsim"
top_module = "main"
vlog_opt = "+incdir+../../../sim"
include_dirs = [ "../../../sim", "./" ]

files = [ "main.sv" ]

modules = { "local" : [ "../../../",
                     "../../../ip_cores/general-cores"
                     ]};
