##################################     All     #################################

.PHONEY: all
all:
	@make -s -C tests directories obj

.PHONEY: fresh
fresh:
	@make -s -C tests realclean directories obj

.PHONEY: compile
compile:
	@make -s -C tests obj

##################################  Cleaning  ##################################

.PHONY: clean
clean:
	@make -s -C tests clean

.PHONY: realclean
realclean: clean
	@make -s -C tests realclean
