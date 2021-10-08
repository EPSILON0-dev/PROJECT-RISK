CC         = g++
RM         = rm -rf
MK	       = mkdir -p

SRCDIR    = src
BINDIR    = bin
OBJDIR    = obj
OBJSUBDIR = obj/common obj/cpu obj/memory obj/tests

CFLAGS    		:=-g -O2 -Wall -Wextra

ALL_OBJ			:= $(OBJDIR)/common/log.o $(OBJDIR)/memory/dcache.o $(OBJDIR)/memory/ddr.o
ALL_OBJ		 	+= $(OBJDIR)/memory/fsb.o $(OBJDIR)/memory/icache.o $(OBJDIR)/cpu/alu.o
ALL_OBJ			+= $(OBJDIR)/cpu/pc.o $(OBJDIR)/cpu/regs.o $(OBJDIR)/cpu/pipeline.o
ALL_OBJ			+= $(OBJDIR)/cpu/branch.o $(OBJDIR)/cpu/cpu.o $(OBJDIR)/top.o

ALL_TEST_OBJ	:= $(OBJDIR)/tests/ddr_test.o $(OBJDIR)/tests/icache_test.o $(OBJDIR)/tests/dcache_test.o
ALL_TEST_OBJ	+= $(OBJDIR)/tests/fsb_test.o $(OBJDIR)/tests/alu_test.o $(OBJDIR)/tests/pc_test.o
ALL_TEST_OBJ	+= $(OBJDIR)/tests/regs_test.o $(OBJDIR)/tests/pipeline_test.o $(OBJDIR)/tests/branch_test.o

DDR_TEST_OBJ 	:= $(OBJDIR)/common/log.o $(OBJDIR)/memory/ddr.o $(OBJDIR)/tests/ddr_test.o 

ICACHE_TEST_OBJ	:= $(OBJDIR)/common/log.o $(OBJDIR)/memory/ddr.o $(OBJDIR)/memory/fsb.o 
ICACHE_TEST_OBJ += $(OBJDIR)/memory/icache.o $(OBJDIR)/tests/icache_test.o

DCACHE_TEST_OBJ	:= $(OBJDIR)/common/log.o $(OBJDIR)/memory/dcache.o $(OBJDIR)/memory/ddr.o 
DCACHE_TEST_OBJ += $(OBJDIR)/memory/fsb.o $(OBJDIR)/tests/dcache_test.o

FSB_TEST_OBJ 	:= $(OBJDIR)/common/log.o $(OBJDIR)/memory/dcache.o $(OBJDIR)/memory/ddr.o
FSB_TEST_OBJ 	+= $(OBJDIR)/memory/fsb.o $(OBJDIR)/memory/icache.o  $(OBJDIR)/tests/fsb_test.o

ALU_TEST_OBJ	:= $(OBJDIR)/common/log.o $(OBJDIR)/cpu/alu.o $(OBJDIR)/tests/alu_test.o

PC_TEST_OBJ		:= $(OBJDIR)/common/log.o $(OBJDIR)/cpu/pc.o $(OBJDIR)/tests/pc_test.o

REGS_TEST_OBJ	:= $(OBJDIR)/common/log.o $(OBJDIR)/cpu/regs.o $(OBJDIR)/tests/regs_test.o

PIPE_TEST_OBJ	:= $(OBJDIR)/common/log.o $(OBJDIR)/cpu/pipeline.o $(OBJDIR)/tests/pipeline_test.o

BR_TEST_OBJ		:= $(OBJDIR)/common/log.o $(OBJDIR)/cpu/branch.o $(OBJDIR)/tests/branch_test.o

TOP_OBJ			:= $(OBJDIR)/common/log.o $(OBJDIR)/memory/dcache.o $(OBJDIR)/memory/ddr.o
TOP_OBJ		 	+= $(OBJDIR)/memory/fsb.o $(OBJDIR)/memory/icache.o $(OBJDIR)/cpu/alu.o
TOP_OBJ			+= $(OBJDIR)/cpu/pc.o $(OBJDIR)/cpu/regs.o $(OBJDIR)/cpu/pipeline.o
TOP_OBJ			+= $(OBJDIR)/cpu/branch.o $(OBJDIR)/cpu/cpu.o $(OBJDIR)/top.o

.PHONEY: all
all: directories obj test_obj tests top

.PHONEY: directories
directories:
	@$(MK) $(OBJDIR)
	@$(MK) $(OBJSUBDIR)
	@$(MK) $(BINDIR)

obj: $(ALL_OBJ)
test_obj: $(ALL_TEST_OBJ)

tests: directories memory_tests cpu_tests
memory_tests: bin/test-ddr bin/test-icache bin/test-dcache bin/test-fsb
cpu_tests: bin/test-alu bin/test-pc bin/test-regs bin/test-pipeline bin/test-branch
top: bin/top

$(OBJDIR)/%.o: $(SRCDIR)/%.cpp
	$(CC) -c $(CFLAGS) -o $@ $< 

bin/test-ddr: $(DDR_TEST_OBJ)
	$(CC) $(CFLAGS) -o $@ $^

bin/test-icache: $(ICACHE_TEST_OBJ)
	$(CC) $(CFLAGS) -o $@ $^

bin/test-dcache: $(DCACHE_TEST_OBJ)
	$(CC) $(CFLAGS) -o $@ $^

bin/test-fsb: $(FSB_TEST_OBJ)
	$(CC) $(CFLAGS) -o $@ $^

bin/test-alu: $(ALU_TEST_OBJ)
	$(CC) $(CFLAGS) -o $@ $^

bin/test-pc: $(PC_TEST_OBJ)
	$(CC) $(CFLAGS) -o $@ $^

bin/test-regs: $(REGS_TEST_OBJ)
	$(CC) $(CFLAGS) -o $@ $^

bin/test-pipeline: $(PIPE_TEST_OBJ)
	$(CC) $(CFLAGS) -o $@ $^

bin/test-branch: $(BR_TEST_OBJ)
	$(CC) $(CFLAGS) -o $@ $^

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
