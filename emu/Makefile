################################## Definitions #################################

CXX			= g++
RM			= rm -rf
MK			= mkdir -p

SRCDIR		= src
BINDIR		= bin
OBJDIR		= obj
OBJSUBDIR	= obj/main obj/common obj/cpu obj/memory obj/tests

OPTFLAGS	:= -g -O0 
WARNFLAGS	:= -Wall -Wextra

OBJ			:= $(OBJDIR)/common/log.o 	$(OBJDIR)/memory/dcache.o 	$(OBJDIR)/memory/ddr.o
OBJ			+= $(OBJDIR)/memory/fsb.o 	$(OBJDIR)/memory/icache.o 	$(OBJDIR)/cpu/alu.o
OBJ			+= $(OBJDIR)/cpu/regs.o 	$(OBJDIR)/cpu/decode.o 		$(OBJDIR)/cpu/branch.o
OBJ			+= $(OBJDIR)/cpu/cpu.o 		$(OBJDIR)/main/system.o 	$(OBJDIR)/main/main.o

##################################     All     #################################

.PHONEY: all
all: 
	@$(MAKE) -s msg
	@$(MAKE) -s compile

.PHONEY: fresh
fresh:
	@$(MAKE) -s msg
	@$(MAKE) -s realclean
	@$(MAKE) -s compile

.PHONEY: compile
compile:
	@$(MAKE) -s directories
	@$(MAKE) -s obj
	@$(MAKE) -s main

.PHONEY: directories
directories:
	@$(MK) $(OBJDIR)
	@$(MK) $(OBJSUBDIR)
	@$(MK) $(BINDIR)

##################################  Messages  ##################################

BANNER		:= "\033[38;1m\033[38;5;88m ╔═╗ ╦═╗ ╔═╗  ╦ ╔═╗ ╔═╗ ╔╦╗     ╦═╗ ╦ ╔═╗ ╦╔═\n\
\033[38;5;124m╠═╝ ╠╦╝ ║ ║  ║ ║╣  ║    ║  ─── ╠╦╝ ║ ╚═╗ ╠╩╗\n\
\033[38;5;160m╩   ╩╚═ ╚═╝ ╚╝ ╚═╝ ╚═╝  ╩      ╩╚═ ╩ ╚═╝ ╩ ╩\033[m\n"
PLATFORM	:= $(shell uname)
ARCH 		:= $(shell $(CXX) -dumpmachine)
CXX_M		:= $(shell $(CXX) -dumpfullversion)

.PHONEY: msg
msg:
	@printf $(BANNER)
	@printf "\033[32;1mPLATFORM   \033[33;1m?| \033[m$(PLATFORM)\n"
	@printf "\033[36;1mARCH       \033[33;1m?| \033[m$(ARCH)\n"
	@printf "\033[33;1mCXX        \033[33;1m?| \033[m$(CXX)\n"
	@printf "\033[31;1mWARNFLAGS  \033[34;1m:| \033[m$(WARNFLAGS)\n"
	@printf "\033[34;1mOPTFLAGS   \033[34;1m:| \033[m$(OPTFLAGS)\n"
	@printf "\n"


##################################   Objects   #################################

obj: obj_msg $(OBJ)

obj_msg:
	@printf "\033[32;1mCompiling Objects\033[m...\n"
	
$(OBJDIR)/%.o: $(SRCDIR)/%.cpp
	@$(CXX) -c $(OPTFLAGS) $(WARNFLAGS) -o $@ $<
	@printf "\033[32;1m-> \033[37;1m$@\n"

##################################  Binaries  ##################################

main: bin/main
bin/main: $(OBJ)
	@printf "\n\033[32;1mLinking and optimizing binary\033[m...\n"
	@$(CXX) $(OPTFLAGS) $(WARNFLAGS) -o $@ $^
	@printf "\033[32;1m-> \033[37;1mbin/main\033[m\n"


##################################  Cleaning  ##################################

.PHONEY: clean
clean:
	@$(RM) $(OBJDIR)/*/*.o

.PHONEY: realclean
realclean: clean
	@printf "\033[32;1mDeleting objects and directories\033[m...\n\n"
	@$(RM) $(BINDIR)/*
	@$(RM) $(OBJDIR)
	@$(RM) $(BINDIR)
