/****************************************************************************
 * Copyright 2022 Lukasz Forenc
 *
 * File: config.v
 *
 * This file contains all core configuration options.
 ***************************************************************************/
`ifndef CONFIG_V
`define CONFIG_V

  /* CPU hardware settings */
  `define RESET_VECTOR 32'h00010000

  `define HAZARD_DATA_FORWARDNG
//`define CLEAN_DATA

  `define INCLUDE_CSR
  `define CSR_EXTERNAL_BUS

  `define C_EXTENSION
  `define C_FETCH_T2

  `define BARREL_SHIFTER
  `define M_EXTENSION
//`define M_INPUT_REG
//`define M_FAST_MULTIPLIER
//`define M_FAST_MUL_DELAY

  /* Synthesis settings */
  `ifndef SIMULATION
    `define HARDWARE_TIPS
  //`define REGS_DISTRIBUTED
  `endif

  /* Simulation settings */
  `ifdef SIMULATION
    `undef HARDWARE_TIPS
    `undef RESET_VECTOR
    `define RESET_VECTOR 32'h00000000
  `endif

`endif
