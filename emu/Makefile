CC         = g++
LINKER     = g++ -o
RM         = rm -f
MKDIR      = mkdir -p
RMDIR      = rm -rf

SRCDIR    = src
BINDIR    = bin
OBJDIR    = obj
OBJSUBDIR = obj/common obj/memory obj/tests

CFLAGS    		:=-g -O0 -Wall -Wextra
LFLAGS    		:=

ALL_OBJ			:= $(OBJDIR)/common/log.o $(OBJDIR)/memory/dcache.o $(OBJDIR)/memory/ddr.o
ALL_OBJ		 	+= $(OBJDIR)/memory/fsb.o $(OBJDIR)/memory/icache.o

DDR_TEST_OBJ 	:= $(OBJDIR)/common/log.o $(OBJDIR)/memory/ddr.o $(OBJDIR)/tests/ddr_test.o 

ICACHE_TEST_OBJ	:= $(OBJDIR)/common/log.o $(OBJDIR)/memory/ddr.o $(OBJDIR)/memory/fsb.o 
ICACHE_TEST_OBJ += $(OBJDIR)/memory/icache.o $(OBJDIR)/tests/icache_test.o

DCACHE_TEST_OBJ	:= $(OBJDIR)/common/log.o $(OBJDIR)/memory/dcache.o $(OBJDIR)/memory/ddr.o 
DCACHE_TEST_OBJ += $(OBJDIR)/memory/fsb.o $(OBJDIR)/tests/dcache_test.o

FSB_TEST_OBJ 	:= $(OBJDIR)/common/log.o $(OBJDIR)/memory/dcache.o $(OBJDIR)/memory/ddr.o
FSB_TEST_OBJ 	+= $(OBJDIR)/memory/fsb.o $(OBJDIR)/memory/icache.o  $(OBJDIR)/tests/fsb_test.o


.PHONEY: all
all: directories obj tests

.PHONEY: directories
directories:
	@$(MKDIR) $(OBJDIR)
	@$(MKDIR) $(OBJSUBDIR)
	@$(MKDIR) $(BINDIR)

obj: $(ALL_OBJ)

tests: directories bin/test-ddr bin/test-icache bin/test-dcache bin/test-fsb

$(OBJDIR)/%.o: $(SRCDIR)/%.cpp
	$(CC) -c -o $@ $< $(CFLAGS)

bin/test-ddr: $(DDR_TEST_OBJ)
	$(LINKER) $@ $^ $(CFLAGS) $(LFLAGS)

bin/test-icache: $(ICACHE_TEST_OBJ)
	$(LINKER) $@ $^ $(CFLAGS) $(LFLAGS)

bin/test-dcache: $(DCACHE_TEST_OBJ)
	$(LINKER) $@ $^ $(CFLAGS) $(LFLAGS)

bin/test-fsb: $(FSB_TEST_OBJ)
	$(LINKER) $@ $^ $(CFLAGS) $(LFLAGS)


.PHONEY: clean
clean:
	@$(RM) $(OBJDIR)/*/*.o

.PHONEY: realclean
realclean: clean
	@$(RM) $(BINDIR)/*
	@$(RMDIR) $(OBJDIR)
	@$(RMDIR) $(BINDIR)
