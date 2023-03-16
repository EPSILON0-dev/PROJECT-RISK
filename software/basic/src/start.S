/*****************************************************************************
 * Copyright 2023 Lukasz Forenc
 *
 * File: startup.S
 *
 * This is the startup code for the RISC-V core executed at boot, it clears
 * the registers and the BSS.
 ****************************************************************************/

/* Reset/interrupt vectors */
  .section .isr_vectors
  .align 2
  .globl __isr_vectors
__isr_vectors:
  j _start
  .size __isr_vectors, . - __isr_vectors

/* Reset/startup handler */
  .section .text
  .globl _start
  .weak _start
  .type _start, %function
_start:

/* Clear the BSS section */
  la x1, __bss_start__
  la x2, __bss_end__
  sub x2, x2, x1
  ble x2, zero, _start2

_start1:
  sw zero, 0(x1)
  addi x1, x1, 4
  addi x2, x2, -4
  bnez x2, _start1
_start2:

/* Initialize the DATA section */
  la x1, __data_start__
  la x2, __data_end__
  la x3, __etext
  sub x2, x2, x1
  ble x2, zero, _start4

_start3:
  lw x4, 0(x3)
  sw x4, 0(x1)
  addi x1, x1, 4
  addi x3, x3, 4
  addi x2, x2, -4
  bnez x2, _start3
_start4:

/* Clear the registers */
  li x1, 0
  li x3, 0
  li x4, 0
  li x5, 0
  li x6, 0
  li x7, 0
  li x8, 0
  li x9, 0
  li x10, 0
  li x11, 0
  li x12, 0
  li x13, 0
  li x14, 0
  li x15, 0
  li x16, 0
  li x17, 0
  li x18, 0
  li x19, 0
  li x20, 0
  li x21, 0
  li x22, 0
  li x23, 0
  li x24, 0
  li x25, 0
  li x26, 0
  li x27, 0
  li x28, 0
  li x29, 0
  li x30, 0
  li x31, 0

/* Set the stack top */
  la sp, __StackTop
  j main
  .size _start, . - _start
