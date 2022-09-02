IVERILOG	:= iverilog
VVP			:= vvp

MODULES		:= cpu
TSTSRC		:= $(patsubst %, tb/%_tb.v, $(MODULES))
TSTOBJ		:= $(patsubst %, obj/%_tb.obj, $(MODULES))
CPUTSTOBJ	:= obj/cpu_tb.obj
TEST		?= NONE

all: compile_tst

#############################  Test Compilation  ##############################

fresh_tst: clean compile_tst

compile_tst: $(TSTOBJ)

obj/%.obj: tb/%.v
	@$(IVERILOG) -grelative-include -o $@ $<

##############################  CPU TB Testing  ###############################

fresh_test_cpu: clean test_cpu

selftest: fresh_tst
	@python3 tb/selftest.py

test_cpu: $(CPUTSTOBJ)
	@python3 tb/test.py ../tests/bin/$(TEST).hex
	@vvp obj/cpu_tb.obj

##################################  Watchers  #################################

watch_tst:
	@while [ true ]; do printf "\033[2J\033[H"; make -s fresh_tst; make -s test_cpu; printf "\n"; inotifywait -r -q -e modify .; done

lint:
	@while [ true ]; do printf "\033[2J\033[H"; verilator --lint-only --relative-includes -Wall cpu/cpu.v; printf "\n"; inotifywait -r -q -e modify .; done

##################################  Cleaning  ##################################

.PHONY: clean
clean:
	@rm -f ./obj/*
