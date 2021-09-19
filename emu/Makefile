CC         = g++
LINKER     = g++ -o
RM         = rm -f
MKDIR      = mkdir -p
RMDIR      = rmdir

SRCDIR    = src
OBJDIR    = obj
BINDIR    = bin
DIRS      := $(OBJDIR) $(BINDIR)

CFLAGS    		:=-g -O0 -Wall -Wextra
LFLAGS    		:=


DDR_TEST_OBJ 	:= $(OBJDIR)/ddr.o $(OBJDIR)/log.o $(OBJDIR)/ddr_test.o 

ICACHE_TEST_OBJ	:= $(OBJDIR)/icache.o $(OBJDIR)/fsb.o $(OBJDIR)/log.o 
ICACHE_TEST_OBJ += $(OBJDIR)/ddr.o $(OBJDIR)/icache_test.o

DCACHE_TEST_OBJ	:= $(OBJDIR)/dcache.o $(OBJDIR)/fsb.o $(OBJDIR)/log.o 
DCACHE_TEST_OBJ += $(OBJDIR)/ddr.o $(OBJDIR)/dcache_test.o

FSB_TEST_OBJ 	:= $(OBJDIR)/dcache.o $(OBJDIR)/fsb.o $(OBJDIR)/log.o 
FSB_TEST_OBJ 	+= $(OBJDIR)/icache.o $(OBJDIR)/ddr.o $(OBJDIR)/fsb_test.o


.PHONEY: all
all: directories tests

.PHONEY: directories
directories: $(DIRS)

tests: directories bin/icache_test bin/dcache_test bin/ddr_test bin/fsb_test


$(OBJDIR):
	@$(MKDIR) $(OBJDIR)

$(BINDIR):
	@$(MKDIR) $(BINDIR)

$(OBJDIR)/%.o: $(SRCDIR)/%.cpp
	$(CC) -c -o $@ $< $(CFLAGS)

bin/ddr_test: $(DDR_TEST_OBJ)
	$(LINKER) $@ $^ $(CFLAGS) $(LFLAGS)

bin/icache_test: $(ICACHE_TEST_OBJ)
	$(LINKER) $@ $^ $(CFLAGS) $(LFLAGS)

bin/dcache_test: $(DCACHE_TEST_OBJ)
	$(LINKER) $@ $^ $(CFLAGS) $(LFLAGS)

bin/fsb_test: $(FSB_TEST_OBJ)
	$(LINKER) $@ $^ $(CFLAGS) $(LFLAGS)


.PHONEY: clean
clean:
	@$(RM) $(OBJDIR)/*.o

.PHONEY: realclean
realclean: clean
	@$(RM) $(BINDIR)/*
	@$(RMDIR) $(OBJDIR)
	@$(RMDIR) $(BINDIR)
