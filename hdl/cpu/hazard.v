/****************************************************************************
 * Copyright 2022 Lukasz Forenc
 *
 * file: hazard.v
 *
 * This file contains the 3 comparators used for assessing the branch
 * condition, at the end they are connected with a MUX4 and xored with the
 * contition inversion bit.
 *
 * i_hz_rs1    - Hazard on RS1 enable
 * i_hz_rs2    - Hazard on RS2 enable
 * i_rs1       - Current RS1 register
 * i_rs2       - Current RS2 register
 * i_ex_wb_reg - RD register in EX phase
 * i_ma_wb_reg - RD register in MA phase
 * i_wb_wb_reg - RD register in WB phase
 * i_ex_wb_en  - Write back EX in phase
 * i_ma_wb_en  - Write back MA in phase
 * i_wb_wb_en  - Write back WB in phase
 * i_rs1_raw_d - Data from RS1
 * i_rs2_raw_d - Data from RS2
 *
 * i_ex_wb_mux - Write back source in EX phase
 * i_ma_wb_mux - Write back source in MA phase
 * i_ex_ret    - Data in EX return address register
 * i_ma_rd_dat - Load data in MA circuitry
 * i_ma_res    - Data in ALU result in MA phase
 * i_ma_ret    - Data in MA return address register
 * i_wb_wb_d   - Data in WB phase write back register
 *
 * o_rs1_d     - Forwarded data from RS1
 * o_rs2_d     - Forwarded data from RS2
 * o_hz_data   - Unforwardable hazard output (also normal hazard when
 *  forwarding is disabled)
 ***************************************************************************/
`include "config.v"

module hazard (
  input         i_hz_rs1,
  input         i_hz_rs2,

  input   [4:0] i_rs1,
  input   [4:0] i_rs2,

  input   [4:0] i_ex_wb_reg,
  input   [4:0] i_ma_wb_reg,
  input   [4:0] i_wb_wb_reg,

  input         i_ex_wb_en,
  input         i_ma_wb_en,
  input         i_wb_wb_en,

`ifdef HAZARD_DATA_FORWARDNG
  input   [1:0] i_ex_wb_mux,
  input   [1:0] i_ma_wb_mux,

  input  [31:0] i_ex_ret,
  input  [31:0] i_ma_rd_dat,
  input  [31:0] i_ma_res,
  input  [31:0] i_ma_ret,
  input  [31:0] i_wb_wb_d,
`endif

  input  [31:0] i_rs1_raw_d,
  input  [31:0] i_rs2_raw_d,

  output [31:0] o_rs1_d,
  output [31:0] o_rs2_d,

  output        o_hz_data
);

`ifdef HAZARD_DATA_FORWARDNG
  /*
   * If hazard data forwarding is enabled hazard unit tries to forward the
   *  data from the pipeline, if it cannot be done data hazard is generated,
   *  using MUX6 to do the switching isn't ideal but it's the least bad
   *  option that I have
   */

  // Hazard enables for read registers
  wire        rs1_hz_en;
  wire        rs2_hz_en;

  // Hazards at write back phase
  wire        hz_wb1;
  wire        hz_wb2;

  // Hazards at memory access phase
  wire        hz_ma1;
  wire        hz_ma2;
  wire        hz_ma_res1;
  wire        hz_ma_ret1;
  wire        hz_ma_rd1;
  wire        hz_ma_res2;
  wire        hz_ma_ret2;
  wire        hz_ma_rd2;

  // Hazards at execute phase
  wire        hz_ex1;
  wire        hz_ex2;
  wire        hz_ex_res1;
  wire        hz_ex_ret1;
  wire        hz_ex_rd1;
  wire        hz_ex_res2;
  wire        hz_ex_ret2;
  wire        hz_ex_rd2;

  // Forwarding to read registers
  reg  [31:0] rs1_d;
  reg  [31:0] rs2_d;

  // Unrecoverable hazard
  wire        hz_data;


  // Hazard enables for read registers
  assign rs1_hz_en = i_hz_rs1 && |i_rs1;
  assign rs2_hz_en = i_hz_rs2 && |i_rs2;

  // Hazards at write back phase
  assign hz_wb1 = rs1_hz_en && (i_rs1 == i_wb_wb_reg) && i_wb_wb_en;
  assign hz_wb2 = rs2_hz_en && (i_rs2 == i_wb_wb_reg) && i_wb_wb_en;

  // Hazards at memory access phase
  assign hz_ma1     = rs1_hz_en && (i_rs1 == i_ma_wb_reg) && i_ma_wb_en;
  assign hz_ma2     = rs2_hz_en && (i_rs2 == i_ma_wb_reg) && i_ma_wb_en;
  assign hz_ma_res1 = hz_ma1 && (i_ma_wb_mux == 2'b00);
  assign hz_ma_ret1 = hz_ma1 && (i_ma_wb_mux == 2'b10);
  assign hz_ma_rd1  = hz_ma1 && (i_ma_wb_mux == 2'b01);
  assign hz_ma_res2 = hz_ma2 && (i_ma_wb_mux == 2'b00);
  assign hz_ma_ret2 = hz_ma2 && (i_ma_wb_mux == 2'b10);
  assign hz_ma_rd2  = hz_ma2 && (i_ma_wb_mux == 2'b01);

  // Hazards at execute phase
  assign hz_ex1     = rs1_hz_en && (i_rs1 == i_ex_wb_reg) && i_ex_wb_en;
  assign hz_ex2     = rs2_hz_en && (i_rs2 == i_ex_wb_reg) && i_ex_wb_en;
  assign hz_ex_res1 = hz_ex1 && (i_ex_wb_mux == 2'b00);
  assign hz_ex_ret1 = hz_ex1 && (i_ex_wb_mux == 2'b10);
  assign hz_ex_rd1  = hz_ex1 && (i_ex_wb_mux == 2'b01);
  assign hz_ex_res2 = hz_ex2 && (i_ex_wb_mux == 2'b00);
  assign hz_ex_ret2 = hz_ex2 && (i_ex_wb_mux == 2'b10);
  assign hz_ex_rd2  = hz_ex2 && (i_ex_wb_mux == 2'b01);

  // Forwarding to rs1
`ifdef HARDWARE_TIPS
  (* parallel_case *)
`endif
  always @* begin
    case (1'b1)
      hz_wb1:     rs1_d = i_wb_wb_d;
      hz_ma_res1: rs1_d = i_ma_res;
      hz_ma_ret1: rs1_d = i_ma_ret;
      hz_ma_rd1:  rs1_d = i_ma_rd_dat;
      hz_ex_ret1: rs1_d = i_ex_ret;
      default:    rs1_d = i_rs1_raw_d;
    endcase
  end

  // Forwarding to rs2
`ifdef HARDWARE_TIPS
  (* parallel_case *)
`endif
  always @* begin
    case (1'b1)
      hz_wb2:     rs2_d = i_wb_wb_d;
      hz_ma_res2: rs2_d = i_ma_res;
      hz_ma_ret2: rs2_d = i_ma_ret;
      hz_ma_rd2:  rs2_d = i_ma_rd_dat;
      hz_ex_ret2: rs2_d = i_ex_ret;
      default:    rs2_d = i_rs2_raw_d;
    endcase
  end

  // Critical unrecoverable hazards
  assign hz_data = hz_ex_rd1 || hz_ex_rd2 || hz_ex_res1 || hz_ex_res2;

`else
  /*
   * This version of hazard unit is like a crying baby that cannot do
   *  anything on it's own and cries "data hazard" every time something
   *  goes at least slightly wrong
   */
  wire        hz_dat_rs1;
  wire        hz_dat_rs2;
  wire        hz_data;
  wire [31:0] rs1_d;
  wire [31:0] rs2_d;

  assign hz_dat_rs1 = i_hz_rs1 && (|i_rs1) && (
    ((i_rs1 == i_ex_wb_reg) && i_ex_wb_en) ||
    ((i_rs1 == i_ma_wb_reg) && i_ma_wb_en) ||
    ((i_rs1 == i_wb_wb_reg) && i_wb_wb_en));
  assign hz_dat_rs2 = i_hz_rs2 && (|i_rs2) && (
    ((i_rs2 == i_ex_wb_reg) && i_ex_wb_en) ||
    ((i_rs2 == i_ma_wb_reg) && i_ma_wb_en) ||
    ((i_rs2 == i_wb_wb_reg) && i_wb_wb_en));
  assign hz_data = hz_dat_rs1 || hz_dat_rs2;

  // Pass through for registers direcly, they won't be used on hazard anyway
  assign rs1_d = i_rs1_raw_d;
  assign rs2_d = i_rs2_raw_d;
`endif

  assign o_rs1_d = rs1_d;
  assign o_rs2_d = rs2_d;
  assign o_hz_data = hz_data;

endmodule

