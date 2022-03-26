################################## Definitions #################################

RISCV_PREFIX	:= riscv64-elf-
RISCV_GCC 		:= $(RISCV_PREFIX)gcc

CXX				:= $(RISCV_PREFIX)gcc
OBJDUMP 		:= $(RISCV_PREFIX)objdump --disassemble-all --disassemble-zeroes --section=.text --section=.text.startup --section=.text.init --section=.data
OBJCOPY 		:= $(RISCV_PREFIX)objcopy -O binary
OBJSIZE 		:= $(RISCV_PREFIX)size
RM				:= rm -f
MK				:= mkdir -p
RMDIR			:= rmdir

SRCDIR			:= ./src
INCDIR			:= ./inc
BINDIR			:= ./bin
DUMPDIR			:= ./dump
OBJDIR			:= ./obj

FLAGS			:= -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -march=rv32i -mabi=ilp32
CFLAGS			:= -Wall -O0 -march=rv32i -mabi=ilp32 -nostartfiles -lm -lc -lgcc

TESTS = \
simple \
add addi \
and andi \
auipc \
beq bge bgeu blt bltu bne \
jal jalr \
lb lbu lh lhu lw \
lui \
or ori \
sb sh sw \
sll slli \
slt slti sltiu sltu \
sra srai \
srl srli \
sub \
xor xori \
dcache \
float \

OBJ 			:= $(addprefix $(OBJDIR)/, $(addsuffix .o, $(TESTS)))
BIN 			:= $(addprefix $(BINDIR)/, $(addsuffix .hex, $(TESTS)))
DUMP 			:= $(addprefix $(DUMPDIR)/, $(addsuffix .dump, $(TESTS)))

##################################     All     #################################

.PHONEY: all
all:
	@$(MAKE) -s banner
	@$(MAKE) -s msg
	@$(MAKE) -s compile

.PHONEY: fresh
fresh:
	@$(MAKE) -s banner
	@$(MAKE) -s msg
	@$(MAKE) -s realclean
	@$(MAKE) -s compile

.PHONEY: compile
compile:
	@$(MAKE) -s directories
	@$(MAKE) -s obj
	@$(MAKE) -s bin
	@$(MAKE) -s dump

.PHONEY: directories
directories:
	@$(MK) $(OBJDIR)
	@$(MK) $(DUMPDIR)
	@$(MK) $(BINDIR)

##################################  Messages  ##################################

BANNER		:= "\033[38;5;88m ╔═╗ ╦═╗ ╔═╗  ╦ ╔═╗ ╔═╗ ╔╦╗     ╦═╗ ╦ ╔═╗ ╦╔═\n\
\033[38;5;124m╠═╝ ╠╦╝ ║ ║  ║ ║╣  ║    ║  ─── ╠╦╝ ║ ╚═╗ ╠╩╗\n\
\033[38;5;160m╩   ╩╚═ ╚═╝ ╚╝ ╚═╝ ╚═╝  ╩      ╩╚═ ╩ ╚═╝ ╩ ╩\033[m\n"
PLATFORM	:= $(shell uname)
ARCH 		:= $(shell $(CXX) -dumpmachine)
CXX_M		:= $(shell $(CXX) -dumpfullversion)

.PHONY: banner
banner:
	@printf $(BANNER)

.PHONY: msg
msg:
	@printf "\033[32;1mPLATFORM   \033[33;1m?| \033[m$(PLATFORM)\n"
	@printf "\033[36;1mARCH       \033[33;1m?| \033[m$(ARCH)\n"
	@printf "\033[33;1mCXX        \033[33;1m?| \033[m$(CXX)\n"
	@printf "\033[34;1mFLAGS      \033[34;1m:| \033[m$(FLAGS)\n"
	@printf "\n"


##################################   Objects   #################################

obj: $(OBJ)

$(OBJDIR)/%.o: $(SRCDIR)/%.S
	@$(CXX) $(FLAGS) -I$(INCDIR) -T./$(INCDIR)/link.ld -o $@ $<
	@printf "\033[s\033[32;1m-> \033[37;1m$@ "
	@$(OBJDUMP) $@ > $(@:obj/%.o=dump/%.dump)
	@printf "\033[u\033[s\033[16C\033[32;1m-> \033[37;1m$(@:obj/%.o=dump/%.dump) "
	@$(OBJCOPY) $@ $(@:obj/%.o=bin/%.hex)
	@printf "\033[u\033[36C\033[32;1m-> \033[37;1m$(@:obj/%.o=bin/%.hex)\n"

$(OBJDIR)/%.o: $(SRCDIR)/%.c
	@$(CXX) $< $(CFLAGS) -T./$(INCDIR)/clink.ld -o $@
	@$(CXX) -S $< $(CFLAGS) -o $(@:obj/%.o=dump/%.S)
	@printf "\033[s\033[32;1m-> \033[37;1m$@ "
	@$(OBJDUMP) $@ > $(@:obj/%.o=dump/%.dump)
	@printf "\033[u\033[s\033[16C\033[32;1m-> \033[37;1m$(@:obj/%.o=dump/%.dump) "
	@$(OBJCOPY) $@ $(@:obj/%.o=bin/%.hex)
	@printf "\033[u\033[36C\033[32;1m-> \033[37;1m$(@:obj/%.o=bin/%.hex)\n"
	$(OBJSIZE) $@

##################################  Cleaning  ##################################

.PHONY: clean
clean:
	@$(RM) ./$(OBJDIR)/*.o
	@$(RM) ./$(DUMPDIR)/*

.PHONY: realclean
realclean: clean
	@printf "\033[32;1mDeleting objects and directories\033[m...\n\n"
	@$(RM) ./$(BINDIR)/*
	@$(RMDIR) ./$(DUMPDIR)
	@$(RMDIR) ./$(OBJDIR)
	@$(RMDIR) ./$(BINDIR)
