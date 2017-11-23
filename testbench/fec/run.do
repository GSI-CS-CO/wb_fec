vlog -sv main.sv +incdir+"." +incdir+../../../sim
vsim -L unisim -t 10fs work.main -voptargs="+acc"
set StdArithNoWarnings 1
set NumericStdNoWarnings 1
do wave.do
radix -hexadecimal
run 20ms
wave zoomfull
