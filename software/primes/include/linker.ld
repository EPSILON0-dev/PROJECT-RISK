OUTPUT_FORMAT("elf32-littleriscv")
OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
  RAM (rwx) : ORIGIN = 0x00000000, LENGTH = 32K
}

SECTIONS
{
  .text :
  {
    *(.text.reset)
    *(.text.init)
    *(.text*)
  } > RAM

  . = ALIGN(4);
  .data :
  {
    *(.rodata)
    *(.srodata)
    *(.data)
    *(.sdata)
  } > RAM

  . = ALIGN(4);
  __bss_start = .;
  .bss :
  {
    *(.bss)
    *(.sbss)
  } > RAM
  __bss_end = .;

  PROVIDE(_bss_start = __bss_start);
  PROVIDE(_bss_size = __bss_end - __bss_start);

  PROVIDE(_stack_top = ORIGIN(RAM) + LENGTH(RAM) - 0x4);
}