IVERILOG	:= iverilog
VVP			:= vvp

MODULES		:= cpu
TSTSRC		:= $(patsubst %, %_tb.v, $(MODULES))
TSTOBJ		:= $(patsubst %, %_tb.obj, $(MODULES))
CPUTSTOBJ	:= cpu_tb.obj
TEST			?= NONE

#############################  Test Compilation  ##############################

%.obj: %.v
	@$(IVERILOG) -grelative-include -o $@ $<

###########################  Universal TB Testing  ############################

fresh_tb: clean_tb $(patsubst %.v, %.obj, $(TEST))

clean_tb:
	@-rm $(patsubst %.v, %.obj, $(TEST))

test_tb: $(patsubst %.v, %.obj, $(TEST))
	@vvp $(patsubst %.v, %.obj, $(TEST))

##############################  CPU TB Testing  ###############################

fresh_tst: clean test_cpu

selftest: $(CPUTSTOBJ)
	@python3 ./selftest.py

test_cpu: $(CPUTSTOBJ)
	@python3 ./test.py ../../tests/bin/$(TEST).hex
	@vvp cpu_tb.obj

##################################  Watchers  #################################

watch_tst:
	@while [ true ]; do printf "\033[2J\033[H"; make -s clean; make -s test_cpu; printf "\n"; inotifywait -r -q -e modify ../cpu; done

watch_tb:
	@while [ true ]; do printf "\033[2J\033[H"; make -s fresh_tb TEST=$(TEST); printf "\n"; inotifywait -r -q -e modify ..; done

lint:
	@while [ true ]; do printf "\033[2J\033[H"; verilator --lint-only --relative-includes -Wall ../cpu/cpu.v; printf "\n"; inotifywait -r -q -e modify ../cpu; done

##################################  Cleaning  ##################################

.PHONY: clean
clean:
	@-rm cpu_log.vcd
	@-rm cpu_tb.obj
