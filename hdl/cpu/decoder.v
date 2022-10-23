/****************************************************************************
 * Copyright 2022 Lukasz Forenc
 *
 * File: decoder.v
 *
 * This file contains both base I set encoder and compressed C decoder.
 * Firstly the operation quad (2 least significant bits) is decoded, quads
 * 0-2 are compressed instruction quads while 3rd quad is base I set quad,
 * based on the quad and the opcode operation is decoded (op_x signals), from
 * the operation signal operation format (format_x signal) is decoded, based
 * on the format immediate decoded earlier (immediate_x) is selected. Finally
 * from the operation signal internal CPU control signals are generated and
 * (when using C set) the register select and funct signals are multiplexed.
 *
 * i_opcode_in - Instruction from fetch unit
 *
 * o_immediate - Decoded immediate
 * o_funct3    - Decoded funct3 field
 * o_funct7    - Decoded funct7 field
 * o_system    - System operation enable (CSR access, etc.)
 * o_rs1       - RS1 register
 * o_rs2       - RS2 register
 * o_rd        - RD register
 * o_hz_rs1    - Data hazard enable for RS1
 * o_hz_rs2    - Data hazard enable for RS2
 * o_branch    - Branch enable (conditional jump)
 * o_jump      - Jump enable (unconditional branch)
 * o_alu_pc    - Use PC as ALU A input
 * o_alu_imm   - Use immediate as ALU B input
 * o_alu_en    - ALU enable (If disabled ALU performs addition)
 * o_ma_wr     - Memory write enable
 * o_ma_rd     - Memory read enable
 * o_wb_mux    - Write back source selection
 * o_wb_en     - Write back enable
 ***************************************************************************/
`include "config.v"

module decoder (
  input  [31:0] i_opcode_in,

  output [31:0] o_immediate,
  output [ 2:0] o_funct3,
  output [ 6:0] o_funct7,

  output        o_system,

  output [ 4:0] o_rs1,
  output [ 4:0] o_rs2,
  output [ 4:0] o_rd,

  output        o_hz_rs1,
  output        o_hz_rs2,

  output        o_branch,
  output        o_jump,

  output        o_alu_pc,
  output        o_alu_imm,
  output        o_alu_en,

  output        o_ma_wr,
  output        o_ma_rd,

  output [ 1:0] o_wb_mux,
  output        o_wb_en
);


  /**
   * Opcode elements extraction
   */
  wire [ 4:0] opcode  = i_opcode_in[6:2];
  wire [ 4:0] rs1     = i_opcode_in[19:15] & {5{!op_lui}};
  wire [ 4:0] rs2     = i_opcode_in[24:20];
  wire [ 4:0] rd      = i_opcode_in[11:7];
  wire [ 2:0] funct3  = i_opcode_in[14:12];
  wire [ 6:0] funct7  = i_opcode_in[31:25];
`ifdef C_EXTENSION
  wire [ 2:0] copcode = i_opcode_in[15:13];
  wire [ 4:0] rs1cs   = {2'b01, i_opcode_in[9:7]};
  wire [ 4:0] rs2cs   = {2'b01, i_opcode_in[4:2]};
  wire [ 4:0] rs1cl   = i_opcode_in[11:7];
  wire [ 4:0] rs2cl   = i_opcode_in[6:2];
  wire [ 1:0] funct2h = i_opcode_in[11:10];
  wire [ 1:0] funct2l = i_opcode_in[6:5];
`endif

  /**
   * Operation decoding
   */
  wire quad3         = (i_opcode_in[1:0] == 2'b11);
  wire op_load       = quad3 && (opcode == 5'b00000);
  wire op_op_imm     = quad3 && (opcode == 5'b00100);
  wire op_auipc      = quad3 && (opcode == 5'b00101);
  wire op_store      = quad3 && (opcode == 5'b01000);
  wire op_op         = quad3 && (opcode == 5'b01100);
  wire op_lui        = quad3 && (opcode == 5'b01101);
  wire op_branch     = quad3 && (opcode == 5'b11000);
  wire op_jalr       = quad3 && (opcode == 5'b11001);
  wire op_jal        = quad3 && (opcode == 5'b11011);
  wire op_system     = quad3 && (opcode == 5'b11100);
`ifdef C_EXTENSION
  wire quad0         = (i_opcode_in[1:0] == 2'b00);
  wire quad1         = (i_opcode_in[1:0] == 2'b01);
  wire quad2         = (i_opcode_in[1:0] == 2'b10);
  wire op_caddi4spn  = quad0 && (copcode == 3'b000);
  wire op_clw        = quad0 && (copcode == 3'b010);
  wire op_csw        = quad0 && (copcode == 3'b110);
  wire op_caddi      = quad1 && (copcode == 3'b000);
  wire op_cjal       = quad1 && (copcode == 3'b001);
  wire op_cli        = quad1 && (copcode == 3'b010);
  wire op_clui_a16sp = quad1 && (copcode == 3'b011);
  wire op_calu       = quad1 && (copcode == 3'b100);
  wire op_cj         = quad1 && (copcode == 3'b101);
  wire op_cbeqz      = quad1 && (copcode == 3'b110);
  wire op_cbnez      = quad1 && (copcode == 3'b111);
  wire op_cslli      = quad2 && (copcode == 3'b000);
  wire op_clwsp      = quad2 && (copcode == 3'b010);
  wire op_cswsp      = quad2 && (copcode == 3'b110);
  wire op_cjr_mv_add = quad2 && (copcode == 3'b100);
`endif

  /**
   * Operation decoding helper signals
   */
`ifdef C_EXTENSION
  wire op_caddi16sp = op_clui_a16sp && (rs1cl == 5'b00010);
  wire op_clui      = op_clui_a16sp && (rs1cl != 5'b00010) && |rs1cl;
  wire op_csrli     = op_calu && (funct2h == 2'b00);
  wire op_csrai     = op_calu && (funct2h == 2'b01);
  wire op_candi     = op_calu && (funct2h == 2'b10);
  wire op_caryth    = op_calu && (funct2h == 2'b11);
  wire op_csub      = op_caryth && (funct2l == 2'b00);
  wire op_cxor      = op_caryth && (funct2l == 2'b01);
  wire op_cor       = op_caryth && (funct2l == 2'b10);
  wire op_cand      = op_caryth && (funct2l == 2'b11);
  wire op_cmv       = op_cjr_mv_add &&  |rs2cl && !i_opcode_in[12];
  wire op_cadd      = op_cjr_mv_add &&  |rs2cl &&  i_opcode_in[12];
  wire op_cjr       = op_cjr_mv_add && ~|rs2cl && !i_opcode_in[12];
  wire op_cjalr     = op_cjr_mv_add && ~|rs2cl &&  i_opcode_in[12];
`endif

  /**
   * Format decoding
   */
  wire format_u = op_auipc || op_lui;
  wire format_j = op_jal;
  wire format_b = op_branch;
  wire format_s = op_store;
  wire format_r = op_op;
  wire format_i = op_load || op_op_imm || op_jalr || op_system;
`ifdef C_EXTENSION
  wire format_ciw   = op_caddi4spn;
  wire format_ci    = op_caddi || op_cli || op_candi || op_cslli ||
    op_csrai || op_csrli;
  wire format_cu    = op_clui;
  wire format_c16sp = op_caddi16sp;
  wire format_cls   = op_clw || op_csw;
  wire format_cj    = op_cj || op_cjal;
  wire format_cb    = op_cbeqz || op_cbnez;
  wire format_cssp  = op_cswsp;
  wire format_clsp  = op_clwsp;
`endif

  /**
   * Opcode validation
   */
  wire opcode_valid = (
  `ifdef C_EXTENSION
    op_cjr_mv_add ||
    op_calu       ||
    format_ciw    ||
    format_ci     ||
    format_cu     ||
    format_c16sp  ||
    format_cls    ||
    format_cj     ||
    format_cb     ||
    format_cssp   ||
    format_clsp   ||
  `else
    i_opcode_in[1:0] == 2'b11) && (
  `endif
    format_u ||
    format_j ||
    format_b ||
    format_i ||
    format_s ||
    format_r
  );

  /**
   * Immediate decoding
   */

  // Upper immediate
  //  LUI AUIPC
  wire [31:0] immediate_u = {
    i_opcode_in[31:12],
    12'h000
  };

  // Jump immediate
  //  JAL
  wire [31:0] immediate_j = {
    {12{i_opcode_in[31]}},
    i_opcode_in[19:12],
    i_opcode_in[20],
    i_opcode_in[30:21],
    1'b0
  };

  // Branch immediate
  //  BEQ BNE BLT BGE BLTU BGEU
  wire [31:0] immediate_b = {
    {20{i_opcode_in[31]}},
    i_opcode_in[7],
    i_opcode_in[30:25],
    i_opcode_in[11:8],
    1'b0
  };

  // Store immediate
  //  SB SH SW
  wire [31:0] immediate_s = {
    {21{i_opcode_in[31]}},
    i_opcode_in[30:25],
    i_opcode_in[11:7]
  };

  // Normal immediate
  //  LB LH LW LBU LHU ADDI SLTI SLTIU XORI ORI ANDI
  wire [31:0] immediate_i = {
    {21{i_opcode_in[31]}},
    i_opcode_in[30:20]
  };

`ifdef C_EXTENSION
  // Compressed immediate word
  //  C.ADDI4SPN
  wire [31:0] immediate_ciw = {
    22'b00_0000_0000_0000_0000_0000,
    i_opcode_in[10:7],
    i_opcode_in[12:11],
    i_opcode_in[5],
    i_opcode_in[6],
    2'b00
  };

  // Compressed immediate
  //  C.ADDI C.LI C.ANDI C.SLLI
  wire [31:0] immediate_ci = {
    {27{i_opcode_in[12]}},
    i_opcode_in[6:2]
  };

  // Compressed immediate
  //  C.LUI
  wire [31:0] immediate_cu = {
    {15{i_opcode_in[12]}},
    i_opcode_in[6:2],
    12'b0000_0000_0000
  };

  // Compressed 16byte stack offset immediate
  //  C.ADDI16SP
  wire [31:0] immediate_c16sp = {
    {23{i_opcode_in[12]}},
    i_opcode_in[4:3],
    i_opcode_in[5],
    i_opcode_in[2],
    i_opcode_in[6],
    4'b0000
  };

  // Compressed load/store immediate
  //  C.LW C.SW
  wire [31:0] immediate_cls = {
    {26{i_opcode_in[5]}},
    i_opcode_in[12:10],
    i_opcode_in[6],
    2'b00
  };

  // Compressed jump immediate
  //  C.J C.JAL
  wire [31:0] immediate_cj = {
    {21{i_opcode_in[12]}},
    i_opcode_in[8],
    i_opcode_in[10:9],
    i_opcode_in[6],
    i_opcode_in[7],
    i_opcode_in[2],
    i_opcode_in[11],
    i_opcode_in[5:3],
    1'b0
  };

  // Compressed branch immediate
  //  C.BEQZ C.BNEZ
  wire [31:0] immediate_cb = {
    {24{i_opcode_in[12]}},
    i_opcode_in[6:5],
    i_opcode_in[2],
    i_opcode_in[11:10],
    i_opcode_in[4:3],
    1'b0
  };

  // Compressed stack based store
  //  C.SWSP
  wire [31:0] immediate_cssp = {
    24'b0000_0000_0000_0000_0000_0000,
    i_opcode_in[8:7],
    i_opcode_in[12:9],
    2'b00
  };

  // Compressed stack based load
  //  C.LWSP
  wire [31:0] immediate_clsp = {
    24'b0000_0000_0000_0000_0000_0000,
    i_opcode_in[3:2],
    i_opcode_in[12],
    i_opcode_in[6:4],
    2'b00
  };
`endif

  // Immediate multiplexer
  reg [31:0] immediate_mux;
`ifdef HARDWARE_TIPS
  (* parallel_case *)
`endif
  always @* begin
    case (1'b1)
`ifdef C_EXTENSION
      format_ciw:   immediate_mux = immediate_ciw;
      format_ci:    immediate_mux = immediate_ci;
      format_cu:    immediate_mux = immediate_cu;
      format_c16sp: immediate_mux = immediate_c16sp;
      format_cls:   immediate_mux = immediate_cls;
      format_cj:    immediate_mux = immediate_cj;
      format_cb:    immediate_mux = immediate_cb;
      format_cssp:  immediate_mux = immediate_cssp;
      format_clsp:  immediate_mux = immediate_clsp;
`endif
      format_u:     immediate_mux = immediate_u;
      format_j:     immediate_mux = immediate_j;
      format_b:     immediate_mux = immediate_b;
      format_i:     immediate_mux = immediate_i;
      format_s:     immediate_mux = immediate_s;
      default:      immediate_mux = 32'h00000000;
    endcase
  end

  /**
   * Internal CPU signals
   */
`ifdef C_EXTENSION
  // Combined Store Signal (Sx C.SW C.SWSP)
  wire c_op_store = op_store || op_csw || op_cswsp;
  // Combined Load Signal (Lx C.LW C.LWSP)
  wire c_op_load  = op_load || op_clw || op_clwsp;
  // Combined immediate op (All IMM_OPs, C.SLLI and C.ALU excluding arythmetic)
  wire c_op_op_imm = op_op_imm || (op_calu && !op_caryth) || op_cslli;
  // Combined OP (All OPs, C. arythmetic and C.ADD)
  wire c_op_op = op_op || op_caryth || op_cadd || op_cmv;
  // Combined JAL instructions (Normal JAL, C.J and C.JAL)
  wire c_jal = op_jal || op_cj || op_cjal;
  // Combined JALR instructions (Normal JALR, C.JR and C.JALR)
  wire c_jalr = op_jalr || op_cjr || op_cjalr;
  // Combined branches (Normal branches and compressed branches)
  wire c_branch = op_branch || op_cbeqz || op_cbnez;
  // Only JALs, AUIPCs and branches require ALU to compute offset from PC
  wire alu_pc = c_jal || op_auipc || c_branch;
  // All but arytmetic OPs require ALU to use immediate as second operand
  wire alu_imm = !c_op_op;
  // Only ALU operations require it to be enabled, do the ADD when disabled
  wire alu_en = c_op_op || c_op_op_imm;
  // Select the write back input
  wire [1:0] wb_mux = {c_jal || c_jalr, c_op_load};
  // Store changes CPU state, so we make sure opcode is VALID
  wire ma_wr = c_op_store && opcode_valid;
  // Load changes CPU state, so we make sure opcode is VALID
  wire ma_rd = c_op_load && opcode_valid;
  // Stores and branches don't generate a result, everything else discards it
  // When opcode is not valid then just discard the result
  wire wb_en = !(c_op_store || c_branch) && opcode_valid;
  // Only LUI, AUIPC, JALs and C.MV don't use the RS1 input
  wire hz_rs1 = !(op_lui || op_auipc || c_jal || op_cmv);
  // Only arythmetic OPs, branch conditions and stores use RS2 register
  wire hz_rs2 = c_branch || c_op_store || c_op_op;
  // Combined jump output for fetch unit
  wire jump = c_jal || c_jalr;
  // Combined branch output for fetch unit
  wire branch = op_branch || op_cbeqz || op_cbnez;
`else
  // Only JALs, AUIPCs and branches require ALU to compute offset from PC
  wire alu_pc = op_jal || op_auipc || op_branch;
  // All but arytmetic OPs require ALU to use immediate as second operand
  wire alu_imm = !op_op;
  // Only ALU operations require it to be enabled, do the ADD when disabled
  wire alu_en = op_op || op_op_imm;
  // Select the write back input
  wire [1:0] wb_mux = {op_jal || op_jalr, op_load};
  // Store changes CPU state, so we make sure opcode is VALID
  wire ma_wr = op_store && opcode_valid;
  // Load changes CPU state, so we make sure opcode is VALID
  wire ma_rd = op_load && opcode_valid;
  // Stores and branches don't generate a result, everything else discards it
  // When opcode is not valid then just discard the result
  wire wb_en = !(op_store || op_branch) && opcode_valid;
  // Only LUI, AUIPC and JALs don't use the RS1 input
  wire hz_rs1 = !(op_lui || op_auipc || op_jal);
  // Only arythmetic OPs, branch conditions and stores use RS2 register
  wire hz_rs2 = op_branch || op_store || op_op;
  // Combined jump output for fetch unit
  wire jump = op_jal || op_jalr;
  // Combined branch output for fetch unit
  wire branch = op_branch;
`endif


`ifdef C_EXTENSION
  reg [4:0] rs1_mux;
`ifdef HARDWARE_TIPS
  (* parallel_case *)
`endif
  wire rs1_normal = quad3;
  wire rs1_sp = op_caddi4spn || op_clwsp || op_cswsp;
  wire rs1_rs1l = op_caddi16sp || op_caddi || op_cslli || op_cjr || op_cjalr || op_cadd;
  wire rs1_rs1s = op_clw || op_csw || op_csrai || op_csrli || op_candi ||
    op_caryth || op_cbeqz || op_cbnez;
  always @* begin
    case (1'b1)
      rs1_normal: rs1_mux = rs1;
      rs1_rs1l: rs1_mux = rs1cl;
      rs1_rs1s: rs1_mux = rs1cs;
      default: rs1_mux = {3'b000, rs1_sp, 1'b0};
    endcase
  end

  reg [4:0] rs2_mux;
`ifdef HARDWARE_TIPS
  (* parallel_case *)
`endif
  always @* begin
    case (1'b1)
      rs2_normal: rs2_mux = rs2;
      rs2_rs2s: rs2_mux = rs2cs;
      rs2_rs2l: rs2_mux = rs2cl;
      default: rs2_mux = 5'b00000;
    endcase
  end
  wire rs2_normal = quad3;
  wire rs2_rs2s = op_csw || op_caryth || op_cswsp;
  wire rs2_rs2l = op_cadd || op_cmv;

  reg [4:0] rd_mux;
`ifdef HARDWARE_TIPS
  (* parallel_case *)
`endif
  always @* begin
    case (1'b1)
      rd_normal: rd_mux = rd;
      rd_rs1l: rd_mux = rs1cl;
      rd_rs1s: rd_mux = rs1cs;
      rd_rs2s: rd_mux = rs2cs;
      default: rd_mux = {4'b0000, op_cjal || op_cjalr};
    endcase
  end
  wire rd_normal = quad3;
  wire rd_rs2s = op_caddi4spn || op_clw;
  wire rd_rs1l = op_caddi16sp || op_caddi || op_cli || op_clui || op_cslli || op_cadd || op_cmv || op_clwsp;
  wire rd_rs1s = op_csrai || op_csrli || op_candi || op_caryth;

  reg [2:0] funct3_mux;
`ifdef HARDWARE_TIPS
  (* parallel_case *)
`endif
  always @* begin
    case (1'b1)
      funct3_normal: funct3_mux = funct3;
      funct3_001:    funct3_mux = 3'b001;
      funct3_010:    funct3_mux = 3'b010;
      funct3_100:    funct3_mux = 3'b100;
      funct3_101:    funct3_mux = 3'b101;
      funct3_110:    funct3_mux = 3'b110;
      funct3_111:    funct3_mux = 3'b111;
      default:       funct3_mux = 3'b000;
    endcase
  end
  wire funct3_normal = quad3;
  wire funct3_001    = op_cslli || op_cbnez;
  wire funct3_010    = c_op_store || c_op_load;
  wire funct3_100    = op_cxor;
  wire funct3_101    = op_csrai || op_csrli;
  wire funct3_110    = op_cor;
  wire funct3_111    = op_candi || op_cand;

  reg [6:0] funct7_mux;
`ifdef HARDWARE_TIPS
  (* parallel_case *)
`endif
  always @* begin
    case (1'b1)
      funct7_normal: funct7_mux = funct7;
      default: funct7_mux = {1'b0, funct7_5, 5'b00000};
    endcase
  end
  wire funct7_normal = quad3;
  wire funct7_5 = op_csrai || op_csub;

`else
  wire [4:0] rs1_mux    = rs1;
  wire [4:0] rs2_mux    = rs2;
  wire [4:0] rd_mux     = rd;
  wire [2:0] funct3_mux = funct3;
  wire [6:0] funct7_mux = funct7;
`endif

  /**
   * Output assignments
   */
  assign o_immediate  = immediate_mux;
  assign o_funct3     = funct3_mux;
  assign o_funct7     = funct7_mux;

  assign o_system     = op_system;

  assign o_rs1        = rs1_mux;
  assign o_rs2        = rs2_mux;
  assign o_rd         = rd_mux;

  assign o_hz_rs1     = hz_rs1;
  assign o_hz_rs2     = hz_rs2;

  assign o_branch     = branch;
  assign o_jump       = jump;

  assign o_alu_pc     = alu_pc;
  assign o_alu_imm    = alu_imm;
  assign o_alu_en     = alu_en;

  assign o_ma_wr      = ma_wr;
  assign o_ma_rd      = ma_rd;

  assign o_wb_mux     = wb_mux;
  assign o_wb_en      = wb_en;

endmodule
