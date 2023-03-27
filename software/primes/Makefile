CC = riscv64-elf-gcc
LD = riscv64-elf-ld
OBJCOPY = riscv64-elf-objcopy
OBJDUMP = riscv64-elf-objdump

PROJECT_NAME = primes

CFLAGS = -Wall -Wextra -Werror -O2 -g -march=rv32imc -mabi=ilp32
LDFLAGS = -T include/linker.ld --no-warn-rwx-segments -L/usr/riscv32-elf/lib/rv32imc/ilp32

SRC_DIR = src
INC_DIR = include
BUILD_DIR = build

SRC = $(wildcard $(SRC_DIR)/*.c)
ASRC = $(wildcard $(SRC_DIR)/*.S)
OBJ = $(patsubst $(SRC_DIR)/%.c, $(BUILD_DIR)/%.o, $(SRC)) $(patsubst $(SRC_DIR)/%.S, $(BUILD_DIR)/%.o, $(ASRC))
HEX = $(BUILD_DIR)/$(PROJECT_NAME).hex
OUT = $(BUILD_DIR)/$(PROJECT_NAME).out

.PHONY: all clean

all: $(HEX)

$(OUT): $(OBJ)
	$(LD) $(LDFLAGS) -o $@ $^

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c
	mkdir -p $(@D)
	$(CC) $(CFLAGS) -c -o $@ $<

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.S
	mkdir -p $(@D)
	$(CC) $(CFLAGS) -c -o $@ $<

$(HEX): $(OUT)
	$(OBJCOPY) -O binary $< $@

dump: $(OUT)
	$(OBJDUMP) -S -D $< > $(BUILD_DIR)/$(PROJECT_NAME).sdump
	$(OBJDUMP) -D $< > $(BUILD_DIR)/$(PROJECT_NAME).dump

clean:
	rm -r $(BUILD_DIR)