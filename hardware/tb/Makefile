TEST			?= NONE

%.obj: %.v
	iverilog -grelative-include -DSIMULATION -o $@ $<

.PHONY: cpu_clean
cpu_clean:
	-rm cpu_tb.obj

.PHONY: cpu_selftest
cpu_selftest: cpu_clean cpu_tb.obj
	@python3 ./selftest.py

.PHONY: cpu_test
cpu_test: cpu_clean cpu_tb.obj
	python3 ./test.py ../../software/selftests/build/$(TEST).hex
	vvp cpu_tb.obj

.PHONY: uart_clean
uart_clean:
	-rm ../peripheral/uart/uart_tb.obj

.PHONY: uart_test
uart_test: uart_clean ../peripheral/uart/uart_tb.obj
	vvp ../peripheral/uart/uart_tb.obj

.PHONY: clean
clean: cpu_clean uart_clean
	-rm cpu.mem
	-rm cpu_log.vcd
	-rm uart_log.vcd
