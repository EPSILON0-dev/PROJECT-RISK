  .section .text.reset
  .global _start
  .type   _start, @function
_start:
  j init
  nop

  .section .text.init
init:
  la sp, _stack_top

  la t0, _bss_start
  la t1, _bss_size
  li t2, 0
  _bss_clean_loop:
    sw t2, 0(t0)
    addi t0, t0, 4
    bne t1, x0, _bss_clean_loop

  call main
  j .