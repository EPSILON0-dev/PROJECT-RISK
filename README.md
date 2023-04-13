# PROJECT-RISK

## Pipelined rv32imc microcontroller written in Verilog

PROJECT-RISK is an attempt at creating advanced multi-core RISCV processor with modern features like pipelining, branch prediction, floating point unit, debugger.

## Features working so far

- 32 bit intruction set with M (multiplication and division) and C (compressed) extensions.
- UART serial interface
- Bootloader stored in write-protected BRAM

## Features planned

- Debugger probe
- All machine level (and later user level) CSRs
- Multiple hardware interfaces (I2C, SPI, OneWire, USB)
- LPDDR support with caching
- Variable clock speed with PLL
- VGA (or HDMI) graphics system
- A (atomic) instruction set extension
- Floating point unit (F extension)
- 64 bit instruction set
- support for FreeRTOS

### When will it be finished?

Probably never.
