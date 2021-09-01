CC         = g++
LINKER     = g++ -o
RM         = rm -f
MKDIR      = mkdir -p
RMDIR      = rm -r

SRCDIR    = src
OBJDIR    = obj
BINDIR    = bin
DIRS      := $(OBJDIR) $(BINDIR)
OBJDIRS   := $(OBJDIR)/cache $(OBJDIR)/common $(OBJDIR)/fsb $(OBJDIR)/tests


CFLAGS    		:=-O2 -Wall -Wextra
LFLAGS    		:=
CACHE_TEST_OBJ	:= $(OBJDIR)/cache/cache.o $(OBJDIR)/fsb/fsb.o $(OBJDIR)/common/log.o 
CACHE_TEST_OBJ  += $(OBJDIR)/tests/cache_test.o

.PHONEY: all
all: directories cache_test

.PHONEY: directories
directories: $(DIRS)

cache_test: directories tests/cache_test

$(OBJDIR):
	@$(MKDIR) $(OBJDIR)
	@$(MKDIR) $(OBJDIRS)

$(BINDIR):
	@$(MKDIR) $(BINDIR)

$(OBJDIR)/%.o: $(SRCDIR)/%.cpp
	$(CC) -c -o $@ $< $(CFLAGS)

tests/cache_test: $(OBJDIR)/$(CACHE_TEST_OBJ)
	$(LINKER) $@ $^ $(CFLAGS) $(LFLAGS)

.PHONEY: clean
clean:
	$(RMDIR) $(OBJDIR)/*

.PHONEY: realclean
realclean: clean
	@$(RM) $(BINDIR)/*
	@$(RMDIR) $(OBJDIR)
	@$(RMDIR) $(BINDIR)