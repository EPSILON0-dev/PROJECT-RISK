CC         = g++
LINKER     = g++ -o
RM         = rm -f
MKDIR      = mkdir -p
RMDIR      = rmdir

SRCDIR    = src
OBJDIR    = obj
BINDIR    = bin
DIRS      := $(OBJDIR) $(BINDIR)

CFLAGS    		:=-g -O2 -Wall -Wextra
LFLAGS    		:=
CACHE_TEST_OBJ	:= $(OBJDIR)/icache.o $(OBJDIR)/fsb.o $(OBJDIR)/log.o 
CACHE_TEST_OBJ  += $(OBJDIR)/dcache.o $(OBJDIR)/cache_test.o $(OBJDIR)/ddr.o

.PHONEY: all
all: directories cache_test

.PHONEY: directories
directories: $(DIRS)

cache_test: directories bin/cache_test

$(OBJDIR):
	@$(MKDIR) $(OBJDIR)

$(BINDIR):
	@$(MKDIR) $(BINDIR)

$(OBJDIR)/%.o: $(SRCDIR)/%.cpp
	$(CC) -c -o $@ $< $(CFLAGS)

bin/cache_test: $(CACHE_TEST_OBJ)
	$(LINKER) $@ $^ $(CFLAGS) $(LFLAGS)

.PHONEY: clean
clean:
	@$(RM) $(OBJDIR)/*.o

.PHONEY: realclean
realclean: clean
	@$(RM) $(BINDIR)/*
	@$(RMDIR) $(OBJDIR)
	@$(RMDIR) $(BINDIR)
