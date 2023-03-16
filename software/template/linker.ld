/*****************************************************************************
 * Copyright 2023 Lukasz Forenc
 *
 * File: linker.ld
 *
 * This is the linker script for fitting the program into CPU's memory.
 ****************************************************************************/
ENTRY(_start)

HEAP_SIZE  = DEFINED(__heap_size__)  ? __heap_size__  : 0x0400;
STACK_SIZE = DEFINED(__stack_size__) ? __stack_size__ : 0x0800;

MEMORY
{
  m_text       (RX) : ORIGIN = 0x00000000, LENGTH = 0x00004000
  m_data       (RW) : ORIGIN = 0x00004000, LENGTH = 0x00004000
}

SECTIONS
{
  /* Text */
  .text :
  {
    . = ALIGN(4);
    *(.isr_vectors)
    *(.text*)
    *(.rodata*)
    . = ALIGN(4);
  } > m_text

  text_end = ORIGIN(m_text) + LENGTH(m_text);

  __etext = .;
  __DATA_ROM = .;
  text_end = ORIGIN(m_text) + LENGTH(m_text);
  ASSERT(__DATA_END <= text_end, "region m_text overflowed")

  /* Data section */
  .data :
  {
    . = ALIGN(4);
    __DATA_RAM = .;
    __data_start__ = .;
    *(.data*)
    *(.sdata*)
    __data_end__ = .;
  } > m_data

  __DATA_END = __DATA_ROM + (__data_end__ - __data_start__);

  /* Uninitialized data section */
  .bss :
  {
    . = ALIGN(4);
    __START_BSS = .;
    __bss_start__ = .;
    *(.bss*)
    *(.sbss*)
    *(COMMON)
    . = ALIGN(4);
    __bss_end__ = .;
    __END_BSS = .;
  } > m_data

  .heap :
  {
    . = ALIGN(8);
    __end__ = .;
    PROVIDE(end = .);
    __HeapBase = .;
    . += HEAP_SIZE;
    __HeapLimit = .;
    __heap_limit = .;
  } > m_data

  .stack :
  {
    . = ALIGN(8);
    . += STACK_SIZE;
  } > m_data

  __StackTop = ORIGIN(m_data) + LENGTH(m_data);
  __StackLimit = __StackTop - STACK_SIZE;
  PROVIDE(__stack = __StackTop);

  ASSERT(__StackLimit >= __HeapLimit, "region m_data overflowed")
}

