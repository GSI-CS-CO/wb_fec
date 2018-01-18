# project name
PROJECT = hamming_weight
# vhdl files
FILES = ../full_adder.vhd ../golay_pkg.vhd ../three_bit_adder.vhd ../two_bit_adder.vhd ../golay_hamming_distance.vhd
# testbench
SIMTOP = hamming_weight_tb
SIMFILES = hamming_weight_tb.vhd
# Simu break condition
GHDL_SIM_OPT    = --assert-level=error
GHDL_SIM_OPT    = --stop-time=500ns

SIMDIR = simu
SYNTHFILES = 

GHDL_CMD        = ghdl
GHDL_FLAGS      = --ieee=synopsys --warn-no-vital-generic

VIEW_CMD        = gtkwave

compile :
	mkdir -p simu
	$(GHDL_CMD) -i $(GHDL_FLAGS) --workdir=simu --work=work $(SIMFILES) $(FILES)
	$(GHDL_CMD) -m $(GHDL_FLAGS) --workdir=simu --work=work $(SIMTOP)
	@mv $(SIMTOP) simu/$(SIMTOP)

run :
	@$(SIMDIR)/$(SIMTOP) $(GHDL_SIM_OPT) --vcdgz=$(SIMDIR)/$(SIMTOP).vcdgz

view:
	gunzip --stdout $(SIMDIR)/$(SIMTOP).vcdgz | $(VIEW_CMD) --vcd

clean :
	$(GHDL_CMD) --clean --workdir=simu
