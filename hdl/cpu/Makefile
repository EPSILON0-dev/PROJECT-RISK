IVERILOG	:= iverilog
VVP			:= vvp

MODULES		:= cpu
TSTSRC		:= $(patsubst %, tb/%_tb.v, $(MODULES))
TSTOBJ		:= $(patsubst %, obj/%_tb.obj, $(MODULES))
CPUTSTOBJ	:= obj/cpu_tb.obj
TEST		?= NONE

default: compile_tst

#############################  Test Compilation  ##############################

fresh_tst: clean compile_tst

compile_tst: $(TSTOBJ)

obj/%.obj: tb/%.v
	@$(IVERILOG) -grelative-include -o $@ $<

##############################  CPU TB Testing  ###############################

fresh_test_cpu: clean test_cpu

test_cpu: $(CPUTSTOBJ)
	@python3 tb/test.py $(TEST)
	@vvp obj/cpu_tb.obj

watch_tst:
	@printf "Starting watching\n"
	@while [ true ]; do make -s fresh_test_cpu; printf "\n"; inotifywait -r -q -e modify .; done

##################################  Cleaning  ##################################

.PHONY: clean
clean:
	@rm -f ./obj/*
