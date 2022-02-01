##################################     All     #################################

.PHONEY: all
all:
	@make -s -C emu -j12
	@printf "\n"
	@make -s -C tests directories obj
	@printf "\n"
	@make -s -C emu test

.PHONEY: fresh
fresh:
	@make -s -C emu -j12 fresh
	@printf "\n"
	@make -s -C tests realclean directories obj
	@printf "\n"
	@make -s -C emu test

.PHONEY: compile
compile:
	@make -s -C emu compile
	@make -s -C tests obj

##################################  Cleaning  ##################################

.PHONY: clean
clean:
	@make -s -C emu clean
	@make -s -C tests clean

.PHONY: realclean
realclean: clean
	@make -s -C emu realclean
	@make -s -C tests realclean
