################################## Definitions #################################

CXX			= g++
RM			= rm -f
MK			= mkdir -p
RMDIR		= rmdir

SRCDIR		= ./src
BINDIR		= ./bin
OBJDIR		= ./obj
OBJSUBDIR	= ./obj/main ./obj/common ./obj/cpu ./obj/memory

OPTFLAGS	:= -O0 -g
WARNFLAGS	:= -Wall -Wextra

OBJ			:= $(OBJDIR)/common/log.o 	$(OBJDIR)/memory/dcache.o 	$(OBJDIR)/memory/ddr.o
OBJ			+= $(OBJDIR)/memory/fsb.o 	$(OBJDIR)/memory/icache.o 	$(OBJDIR)/cpu/alu.o
OBJ			+= $(OBJDIR)/cpu/regs.o 	$(OBJDIR)/cpu/decode.o 		$(OBJDIR)/cpu/branch.o
OBJ			+= $(OBJDIR)/cpu/cpu.o 		$(OBJDIR)/cpu/mem.o 		$(OBJDIR)/main/system.o
OBJ			+= $(OBJDIR)/main/arg.o		$(OBJDIR)/main/help.o		$(OBJDIR)/main/main.o

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
	@$(MAKE) -s main

.PHONEY: fresh_tests
fresh_tests:
	@$(MAKE) -C ../tests -s fresh

.PHONEY: compile_tests
compile_tests:
	@$(MAKE) -C ../tests -s

.PHONY: test
test: compile
	@python3 ./test/selftest.py

.PHONEY: directories
directories:
	@$(MK) $(OBJDIR)
	@$(MK) $(OBJSUBDIR)
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
	@printf "\033[31;1mWARNFLAGS  \033[34;1m:| \033[m$(WARNFLAGS)\n"
	@printf "\033[34;1mOPTFLAGS   \033[34;1m:| \033[m$(OPTFLAGS)\n"
	@printf "\n"


##################################   Objects   #################################

obj: $(OBJ)

$(OBJDIR)/%.o: $(SRCDIR)/%.cpp
	@$(CXX) -c $(OPTFLAGS) $(WARNFLAGS) -o $@ $<
	@printf "\033[32;1m-> \033[37;1m$@\n"

##################################  Binaries  ##################################

main: bin/main
bin/main: $(OBJ)
	@printf "\n\033[32;1mLinking and optimizing binary\033[m...\n"
	@$(CXX) $(OPTFLAGS) $(WARNFLAGS) -o $@ $^
	@printf "\033[32;1m-> \033[37;1mbin/main\033[m\n\n"


##################################  Cleaning  ##################################

.PHONY: clean
clean:
	@$(RM) ./$(OBJDIR)/*/*.o

.PHONY: realclean
realclean: clean
	@printf "\033[32;1mDeleting objects and directories\033[m...\n\n"
	@$(RM) ./$(BINDIR)/*
	@$(RMDIR) ./$(OBJSUBDIR)
	@$(RMDIR) ./$(OBJDIR)
	@$(RMDIR) ./$(BINDIR)
