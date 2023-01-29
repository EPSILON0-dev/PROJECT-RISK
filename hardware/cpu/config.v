/****************************************************************************
 * Copyright 2022 Lukasz Forenc
 *
 * File: config.v
 *
 * This file contains all core configuration options.
 ***************************************************************************/
`ifndef CONFIG_V
`define CONFIG_V

  /**************************************************************************
   * CPU hardware settings
   *************************************************************************/
  // Vector that the CPU jumps to on reset
  `define RESET_VECTOR 32'h00010000

  // Try to forward the data instead of stalling the pipelibe
  `define HAZARD_DATA_FORWARDNG

  // Clear the data bus address and output when no memory access is performed
//`define CLEAN_DATA

  // Include the CSR module
  `define INCLUDE_CSR
  // Route out the external CSR bus out of the CPU
//`define CSR_EXTERNAL_BUS

  // Include Compressed extension
  `define C_EXTENSION
  // Always wait for misaligned instructions data to arrive (not only when needed)
//`define C_FETCH_T2

  // Replace the bit shifter with the barrel shifter
  `define BARREL_SHIFTER
  // Include Mutiply/Divide extension
  `define M_EXTENSION

  /**************************************************************************
   * CSR contents settings
   *************************************************************************/
  // misa CSR contents
  // C extension - bit 2
  // M extension - bit 12
  // I base ISA - bit 8
  `define CSR_MISA 32'h40001104

  // mvendorid CSR contents
  // I don't have a vendor ID so this is just some garbage data
  `define CSR_MVENDORID 32'h2D1BC3B7

  // marchid CSR contents
  // This is just a random core so it's also garbage data (BUT MSB MUST BE 0)
  `define CSR_MARCHID 32'h2D1BC3B7

  // mimpid CSR contents
  // Another random piece of data
  `define CSR_MIMPID 32'h2D1BC3B7

  // mhartid CSR contents
  // It's hardware thread ID so for single-core CPU this must be 0
  `define CSR_MHARTID 32'h00000000


  /**************************************************************************
   * Synthesis settings
   *************************************************************************/
  `ifndef SIMULATION
    // Include hardware synthesis tips like (* ram_type = "block" *)
    `define HARDWARE_TIPS
    // Use distributed RAM instead of BRAM as register file
  //`define REGS_DISTRIBUTED
  `endif

  /**************************************************************************
   * Simulation settings
   *************************************************************************/
  `ifdef SIMULATION
    `undef HARDWARE_TIPS
    `undef RESET_VECTOR
    `define RESET_VECTOR 32'h00000000
  `endif

`endif
