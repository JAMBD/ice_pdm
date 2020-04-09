PROJ = pdm_stream

PIN_DEF = icestick.pcf
DEVICE = hx1k

PROJECT_FILES = circular_buffer.v comms.v pll.v pdm.v rs232.v

all: $(PROJ).rpt $(PROJ).bin

%.json: %.v $(PROJECT_FILES)
	yosys -p 'synth_ice40 -top top -json $@' $^

%.asc: %.json
	nextpnr-ice40 --hx$(subst hx,,$(subst lp,,$(DEVICE))) --asc $@ --pcf $(PIN_DEF) --json $^

%.bin: %.asc
	icepack $< $@

%.rpt: %.asc
	icetime -d $(DEVICE) -mtr $@ $<

%_tb: %_tb.v %.v $(PROJECT_FILES)
	iverilog -o $@ $^ `yosys-config --datdir/ice40/cells_sim.v`

%_tb.vcd: %_tb
	vvp -N $< +vcd=$@

%_syn.v: %.blif
	yosys -p 'read_blif -wideports $^; write_verilog $@'

%_syntb: %_tb.v %_syn.v
	iverilog -o $@ $^ `yosys-config --datdir/ice40/cells_sim.v`

%_syntb.vcd: %_syntb
	vvp -N $< +vcd=$@

sim: $(PROJ)_tb.vcd

pdm_sim: pdm_tb.vcd

postsim: $(PROJ)_syntb.vcd

time: $(PROJ).asc
	icetime -d $(DEVICE) $<
prog: $(PROJ).bin
	iceprog $<

sudo-prog: $(PROJ).bin
	@echo 'Executing prog as root!!!'
	sudo iceprog $<

clean:
	rm -f $(PROJ).json $(PROJ).asc $(PROJ).rpt $(PROJ).bin *.vcd *_tb

.SECONDARY:
.PHONY: all prog clean
