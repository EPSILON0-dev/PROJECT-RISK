IVERILOG	:= iverilog
VVP			:= vvp

MODULES		:= cpu
TSTSRC		:= $(patsubst %, %_tb.v, $(MODULES))
TSTOBJ		:= $(patsubst %, %_tb.obj, $(MODULES))
CPUTSTOBJ	:= cpu_tb.obj
TEST		?= NONE

all: compile_tst

#############################  Test Compilation  ##############################

fresh_tst: clean compile_tst

compile_tst: $(TSTOBJ)

%.obj: %.v
	@$(IVERILOG) -grelative-include -o $@ $<

##############################  CPU TB Testing  ###############################

fresh_test_cpu: clean test_cpu

selftest: fresh_tst
	@python3 ./selftest.py

test_cpu: $(CPUTSTOBJ)
	@python3 ./test.py ../../tests/bin/$(TEST).hex
	@vvp cpu_tb.obj

##################################  Watchers  #################################

watch_tst:
	@while [ true ]; do printf "\033[2J\033[H"; make -s fresh_tst; make -s test_cpu; printf "\n"; inotifywait -r -q -e modify ../cpu; done

lint:
	@while [ true ]; do printf "\033[2J\033[H"; verilator --lint-only --relative-includes -Wall ../cpu/cpu.v; printf "\n"; inotifywait -r -q -e modify ../cpu; done

##################################  Cleaning  ##################################

.PHONY: clean
clean:
	@-rm cpu_log.vcd
	@-rm cpu_tb.obj
