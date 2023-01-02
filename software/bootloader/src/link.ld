ENTRY(_start)

MEMORY
{
  rom (rwx) : ORIGIN = 0, LENGTH = 32k
}

SECTIONS
{
  . = 0;
  .text : { *(.text) _etext = .; }
}