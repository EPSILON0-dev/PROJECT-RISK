CC = riscv64-elf-gcc
LD = riscv64-elf-ld
OBJCOPY = riscv64-elf-objcopy
OBJDUMP = riscv64-elf-objdump

PROJECT_NAME = csr_test

CFLAGS = -Wall -Wextra -O2 -g -march=rv32imzicsr -mabi=ilp32
LDFLAGS = --print-memory-usage -T include/linker.ld --no-warn-rwx-segments
LDFLAGS += -L/usr/riscv64-elf/lib/rv32im/ilp32 -lm -lg_nano -lnosys
LDFLAGS += -L/usr/lib/gcc/riscv64-elf/12.2.0/rv32im/ilp32 -lgcc

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
	$(LD) -o $@ $^ $(LDFLAGS)

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
	-rm -r $(BUILD_DIR)