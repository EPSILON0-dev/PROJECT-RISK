TOOLCHAIN	:= riscv64-elf-
GCC     := $(TOOLCHAIN)gcc
OBJDUMP := $(TOOLCHAIN)objdump -d --visualize-jumps=color --disassembler-color=color -h
OBJCOPY := $(TOOLCHAIN)objcopy -O binary
OBJSIZE := $(TOOLCHAIN)size
RM      := rm
MKDIR   := mkdir -p
RMDIR   := rmdir

SFLAGS	:= -march=rv32i -mabi=ilp32
CFLAGS  :=
LFLAGS  := -march=rv32i -mabi=ilp32 -Wall -nostartfiles -nostdlib

OBJ 			:= $(patsubst src/%.c, obj/%.o, $(wildcard src/*.c))
OBJ 			+= $(patsubst src/%.S, obj/%.o, $(wildcard src/*.S))
ELF 			:= bin/out.elf
BIN 			:= bin/out.bin
DUMP 			:= dump/out.dump

all: compile

.PHONEY: fresh
fresh: realclean all

compile: directories link dump hex

directories:
	$(MKDIR) obj
	$(MKDIR) bin
	$(MKDIR) dump

obj/%.o: src/%.S
	$(GCC) -c $(SFLAGS) -o $@ $<

obj/%.o: src/%.c
	$(GCC) -c $(CFLAGS) -o $@ $<

link: $(OBJ)
	$(GCC) $(LFLAGS) -T./src/link.ld -o $(ELF) $^
	$(OBJSIZE) $(ELF)

dump: $(ELF)
	$(OBJDUMP) $^ > $(DUMP)

hex: $(ELF)
	$(OBJCOPY) $< $(BIN)
	python3 mem.py

.PHONY: clean
clean:
	-$(RM) $(DUMP) $(OBJ) $(ELF)

.PHONY: realclean
realclean: clean
	-$(RM) $(BIN) bin/top.mem
	-$(RMDIR) bin obj dump
