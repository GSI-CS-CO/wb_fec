vsim -L secureip -L unisim -t 10fs work.main -voptargs="+acc" +nowarn8684 +nowarn8683
set StdArithNoWarnings 1
set NumericStdNoWarnings 1
do wave_1.do
radix -hexadecimal
run 1000000us
wave zoomfull
