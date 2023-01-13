RISCV_PREFIX	:= riscv64-elf-

CXX     := $(RISCV_PREFIX)gcc -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -march=rv32g -mabi=ilp32
OBJDUMP := $(RISCV_PREFIX)objdump --disassemble-all --disassemble-zeroes --section=.text --section=.text.startup --section=.text.init --section=.data
OBJCOPY := $(RISCV_PREFIX)objcopy -O binary
OBJSIZE := $(RISCV_PREFIX)size
RM      := rm -r
MK      := mkdir -p

TESTS := $(patsubst src/%.S, build/%, $(wildcard src/*.S))

.PHONY: all
all: compile

.PHONY: fresh
fresh: clean compile

compile:
	$(MAKE) directories
	$(MAKE) obj

directories:
	$(MK) build

obj: $(TESTS)

build/%: src/%.S
	$(CXX) -T./src/link.ld -o $@ $<
	$(OBJDUMP) $@ > $@.dump
	$(OBJCOPY) $@ $@.hex

.PHONY: clean
clean:
	-$(RM) build