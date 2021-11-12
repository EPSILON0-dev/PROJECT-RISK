CC		= g++
RM		= rm -rf
MK		= mkdir -p

SRCDIR		= src
BINDIR		= bin
OBJDIR		= obj
OBJSUBDIR	= obj/common obj/cpu obj/memory obj/tests

CFLAGS		:=-g -O2 -Wall -Wextra

TOP_OBJ		:= $(OBJDIR)/common/log.o $(OBJDIR)/memory/dcache.o $(OBJDIR)/memory/ddr.o
TOP_OBJ		+= $(OBJDIR)/memory/fsb.o $(OBJDIR)/memory/icache.o $(OBJDIR)/cpu/alu.o
TOP_OBJ		+= $(OBJDIR)/cpu/regs.o $(OBJDIR)/cpu/decode.o $(OBJDIR)/cpu/branch.o
TOP_OBJ		+= $(OBJDIR)/cpu/cpu.o $(OBJDIR)/top.o

.PHONEY: all
all: directories obj top

.PHONEY: directories
directories:
	@$(MK) $(OBJDIR)
	@$(MK) $(OBJSUBDIR)
	@$(MK) $(BINDIR)

obj: $(TOP_OBJ)

top: bin/top

$(OBJDIR)/%.o: $(SRCDIR)/%.cpp
	$(CC) -c $(CFLAGS) -o $@ $<
	
bin/top: $(TOP_OBJ)
	$(CC) $(CFLAGS) -o $@ $^

.PHONEY: clean
clean:
	@$(RM) $(OBJDIR)/*/*.o

.PHONEY: realclean
realclean: clean
	@$(RM) $(BINDIR)/*
	@$(RM) $(OBJDIR)
	@$(RM) $(BINDIR)
