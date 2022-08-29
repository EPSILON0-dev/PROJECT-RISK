# Modules

## alu.v

This module is responsible for performing simple math and logic operation as well as integer comparisons. Shifter and muldiv circuitry connections are routed through this module.

## branch.v

Branch conditioner, this module is responsible for checking if the branch condition is met and generationg final branch enable signal.

## config.v

Configuration file, configure the core from this file.

## cpu.v

Main file connecting all modules.

## decoder.v

Instruction decoder, responsible for decoding operations, decoding immediate values and generating internal control signals.

## fetch.v

Instruction fetch, program counter and branch execution circuitry, also responsible for generating and managing branch hazard signal.

## memory.v

Memory iterface, responsible for shifting, adjusting length and sign extending write and read data.

## muldiv.v

Multiplier and divider circuitry.

## regs.v

Register set.

## shifter.v

Shifter circuit.
