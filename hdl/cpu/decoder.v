`include "config.v"

module decoder (
  input  [31:0] i_opcode_in,

  output [31:0] o_immediate,
  output [ 4:0] o_opcode,
  output [ 2:0] o_funct3,
  output [ 6:0] o_funct7,

  output        o_system,

  output [ 4:0] o_rs1,
  output [ 4:0] o_rs2,
  output [ 4:0] o_rd,

  output        o_hz_rs1,
  output        o_hz_rs2,

  output        o_alu_pc,
  output        o_alu_imm,
  output        o_alu_en,

  output        o_ma_wr,
  output        o_ma_rd,

  output [ 1:0] o_wb_mux,
  output        o_wb_en
);

`ifdef C_EXTENSION
  /**
   * Opcode elements extraction
   */
  wire [4:0] rs1_cs    = {2'b01, i_opcode_in[9:7]};
  wire [4:0] rs2_cs    = {2'b01, i_opcode_in[4:2]};
  wire [4:0] rs1_cl    = i_opcode_in[11:7];
  wire [4:0] rs2_cl    = i_opcode_in[6:2];
  wire [2:0] funct3_c  = i_opcode_in[15:13];
  wire [1:0] funct2_ch = i_opcode_in[11:10];
  wire [1:0] funct2_cl = i_opcode_in[6:5];

  /**
   * Immediate decoding
   */
  // Compressed immediate word
  //  C.ADDI4SPN
  wire [7:0] immediate_ciw = {
    i_opcode_in[10:7],
    i_opcode_in[12:11],
    i_opcode_in[5],
    i_opcode_in[6]
  };

  // Compressed immediate
  //  C.ADDI C.LIC.ANDI C.SLLI
  wire [5:0] immediate_ci = {
    i_opcode_in[12],
    i_opcode_in[6:2]
  };

  // Compressed 16byte stack offset immediate
  //  C.ADDI16SP
  wire [9:4] immediate_c16sp = {
    i_opcode_in[12],
    i_opcode_in[4:3],
    i_opcode_in[5],
    i_opcode_in[2],
    i_opcode_in[6]
  };

  // Compressed load/store immediate
  //  C.LW C.SW
  wire [4:0] immediate_cls = {
    i_opcode_in[5],
    i_opcode_in[12:10],
    i_opcode_in[6]
  };

  // Compressed jump immediate
  //  C.J C.JAL
  wire [11:1] immediate_cj = {
    i_opcode_in[12],
    i_opcode_in[8],
    i_opcode_in[10:9],
    i_opcode_in[6],
    i_opcode_in[7],
    i_opcode_in[2],
    i_opcode_in[11],
    i_opcode_in[5:3]
  };

  // Compressed branch immediate
  //  C.BEQZ C.BNEZ
  wire [8:1] immediate_cb = {
    i_opcode_in[12],
    i_opcode_in[6:5],
    i_opcode_in[2],
    i_opcode_in[11:10],
    i_opcode_in[4:3]
  };

  // Compressed stack based store
  //  C.SWSP
  wire [7:2] immediate_cssp = {
    i_opcode_in[8:7],
    i_opcode_in[12:9]
  };

  // Compressed stack based load
  //  C.LWSP
  wire [7:2] immediate_clsp = {
    i_opcode_in[3:2],
    i_opcode_in[12],
    i_opcode_in[6:4]
  };

  /**
   * Quadrant decoding
   */
  wire q_0 = (i_opcode_in[1:0] == 2'b00);
  wire q_1 = (i_opcode_in[1:0] == 2'b01);
  wire q_2 = (i_opcode_in[1:0] == 2'b10);
  wire q_3 = (i_opcode_in[1:0] == 2'b11);

  /**
   * Compressed funct3 decoding
   */
  wire cf3_000 = (funct3_c == 3'b000);
  wire cf3_010 = (funct3_c == 3'b010);
  wire cf3_011 = (funct3_c == 3'b011);
  wire cf3_100 = (funct3_c == 3'b100);
  wire cf3_110 = (funct3_c == 3'b110);
  wire cf3_x01 = (funct3_c[1:0] == 2'b01);
  wire cf3_11x = (funct3_c[2:1] == 2'b11);

  /**
   * Register conditions
   */
  wire rs1_nz  =  |rs1_cl;
  wire rs1_nsp =  (rs1_cl != 5'b00010);
  wire rs1_sp  =  (rs1_cl == 5'b00010);
  wire rs2_nz  =  |rs2_cl;
  wire rs2_z   = ~|rs2_cl;

  /**
   * Instruction signals
   */
  wire c_addi4spn = q_0 && cf3_000;
  wire c_lui      = q_1 && cf3_011 && rs1_nz && rs1_nsp;
  wire c_addi16sp = q_1 && cf3_011 && rs1_sp;
  wire c_lw       = q_0 && cf3_010;
  wire c_sw       = q_0 && cf3_110;
  wire c_addi     = q_1 && cf3_000 && rs1_nz;
  wire c_li       = q_1 && cf3_010 && rs1_nz;
  wire c_slli     = q_2 && cf3_000;
  wire c_j        = q_1 && cf3_x01;
  wire c_b        = q_1 && cf3_11x;
  wire c_jr       = q_2 && cf3_100 && rs1_nz && rs2_z;
  wire c_add      = q_2 && cf3_100 && rs1_nz && rs2_nz;
  wire c_lwsp     = q_2 && cf3_010;
  wire c_swsp     = q_2 && cf3_110;
  wire c_alu      = q_1 && cf3_100;

  /**
   * ALU instruction signals
   */
  wire c_sri      = c_alu && !funct2_ch[1];
  wire c_ar       = c_alu && (funct2_ch == 2'b11);
  wire c_andi     = c_alu && (funct2_ch == 2'b10);
  wire c_sub      = c_ar  && (funct2_cl == 2'b00);

  wire [2:0] c_ar_f3 =
    (funct2_cl == 2'b00) ? 3'b000 :
    (funct2_cl == 2'b01) ? 3'b100 :
    (funct2_cl == 2'b10) ? 3'b110 :
    (funct2_cl == 2'b11) ? 3'b111 : 0;

  /**
   * Opcode validation
   */
`ifdef C_SIMPLE_VALIDATOR
  wire valid_c = |i_opcode_in[15:0];
`else
  wire valid_c = c_addi4spn || c_lui || c_addi16sp || c_lw ||
    c_sw || c_li || c_addi || c_sri || c_andi || c_ar ||
    c_slli || c_j || c_b || c_jr || c_add || c_swsp || c_lwsp;
`endif

  /**
   * Opcode multiplexers
   */
  // RD field
  wire c_rd_rs2s     = c_addi4spn || c_lw;
  wire c_rd_rs1s     = c_alu;
  wire c_rd_rs1l     = c_lui || c_addi16sp || c_addi || c_li || c_slli ||
    c_add || c_lwsp;
  wire c_rd_imm_cls  = c_sw;
  wire c_rd_imm_cb   = c_b;
  wire c_rd_imm_cssp = c_swsp;
  wire c_rd_j        = c_j;
  wire c_rd_jr       = c_jr;
  wire [4:0] c_rd    =
    (c_rd_rs2s)      ? rs2_cs :
    (c_rd_rs1s)      ? rs1_cs :
    (c_rd_rs1l)      ? rs1_cl :
    (c_rd_imm_cls)   ? {immediate_cls [2:0], 2'b00} :
    (c_rd_imm_cb)    ? {immediate_cb  [4:1], immediate_cb[8]} :
    (c_rd_imm_cssp)  ? {immediate_cssp[4:2], 2'b00} :
    (c_rd_j)         ? {4'b0000, !funct3_c[2]} :
    (c_rd_jr)        ? {4'b0000, i_opcode_in[12]} :
    5'b00000;

  // RS1 field
  wire c_rs1_sp     = c_addi4spn || c_addi16sp || c_swsp || c_lwsp;
  wire c_rs1_rs1s   = c_lw || c_sw || c_sri || c_andi || c_ar || c_b;
  wire c_rs1_rs1l   = c_addi || c_slli || c_jr || (c_add && i_opcode_in[12]);
  wire c_rs1_imm_ci = c_lui;
  wire c_rs1_imm_cj = c_j;
  wire [4:0] c_rs1  =
    (c_rs1_sp)      ? 5'b00010 :
    (c_rs1_rs1s)    ? rs1_cs :
    (c_rs1_rs1l)    ? rs1_cl :
    (c_rs1_imm_ci)  ? {{3{immediate_ci[5]}}, immediate_ci[4:3]} :
    (c_rs1_imm_cj)  ? {5{immediate_cj[11]}} :
    5'b00000;

  // RS2 field
  wire c_rs2_rs2s      = c_sw || c_ar;
  wire c_rs2_rs2l      = c_swsp || c_add;
  wire c_rs2_imm_cil   = c_sri || c_andi || c_slli || c_addi || c_li;
  wire c_rs2_imm_cih   = c_lui;
  wire c_rs2_imm_cls   = c_lw;
  wire c_rs2_imm_ciw   = c_addi4spn;
  wire c_rs2_imm_cj    = c_j;
  wire c_rs2_imm_c16sp = c_addi16sp;
  wire c_rs2_imm_clsp  = c_lwsp;
  wire [4:0] c_rs2     =
    (c_rs2_rs2s)       ? rs2_cs :
    (c_rs2_rs2l)       ? rs2_cl :
    (c_rs2_imm_cil)    ? immediate_ci[4:0] :
    (c_rs2_imm_cih)    ? {5{immediate_ci[5]}} :
    (c_rs2_imm_cls)    ? {immediate_cls[2:0], 2'b00} :
    (c_rs2_imm_ciw)    ? {immediate_ciw[2:0], 2'b00} :
    (c_rs2_imm_cj)     ? {immediate_cj[4:1], immediate_cj[11]} :
    (c_rs2_imm_c16sp)  ? {immediate_c16sp[4], 4'b0000} :
    (c_rs2_imm_clsp)   ? {immediate_clsp[4:2], 2'b00} :
    5'b00000;

  // Funct3 field
  wire c_f3_010       = c_sw || c_lw || c_swsp || c_lwsp;
  wire c_f3_101       = c_sri;
  wire c_f3_001       = c_slli || (c_b && funct3_c[0]);
  wire c_f3_111       = c_andi || (c_j && immediate_cj[11]);
  wire c_f3_ar_f3     = c_ar;
  wire c_f3_imm_ci    = c_lui;
  wire [2:0] c_funct3 =
    (c_f3_imm_ci)     ? immediate_ci[2:0] :
    (c_f3_ar_f3)      ? c_ar_f3 :
    (c_f3_001)        ? 3'b001 :
    (c_f3_010)        ? 3'b010 :
    (c_f3_101)        ? 3'b101 :
    (c_f3_111)        ? 3'b111 :
    3'b000;

  // Funct7 field
  wire c_f7_imm_ci    = c_lui || c_addi || c_li || c_andi;
  wire c_f7_imm_cls   = c_lw || c_sw;
  wire c_f7_imm_cj    = c_j;
  wire c_f7_imm_cb    = c_b;
  wire c_f7_imm_ciw   = c_addi4spn;
  wire c_f7_imm_c16sp = c_addi16sp;
  wire c_f7_imm_clsp  = c_lwsp;
  wire c_f7_imm_cssp  = c_swsp;
  wire c_f7_sub       = c_ar;
  wire c_f7_sr        = c_sri;
  wire [6:0] c_funct7 =
    (c_f7_imm_ci)     ? {7{immediate_ci[5]}} :
    (c_f7_imm_cls)    ? {5'b00000, immediate_cls[4:3]} :
    (c_f7_imm_cj)     ? {immediate_cj[11:5]} :
    (c_f7_imm_cb)     ? {{4{immediate_cb[8]}}, immediate_cb[7:5]} :
    (c_f7_imm_ciw)    ? {2'b00, immediate_ciw[7:3]} :
    (c_f7_imm_c16sp)  ? {{3{immediate_c16sp[9]}}, immediate_c16sp[8:5]} :
    (c_f7_imm_clsp)   ? {4'b0000, immediate_clsp[7:5]} :
    (c_f7_imm_cssp)   ? {4'b0000, immediate_cssp[7:5]} :
    (c_f7_sr)         ? {1'b0, funct2_ch[0], 5'b00000} :
    (c_f7_sub)        ? {1'b0, c_sub, 5'b00000} :
    7'b0000000;

  // Opcode field
  //  Default opcode is 5'b00100 because it's register/immediate operation,
  //  in case of illegal opcode (if simplified validator is used) instead of
  //  executing arbitrary instruction CPU will just execute NOP
  //  (addi zero, zero, 0)
  wire c_op           = c_ar || c_add;
  wire c_load         = c_lw || c_lwsp;
  wire c_store        = c_sw || c_swsp;
  wire c_jal          = c_j;
  wire c_jalr         = c_jr;
  wire c_branch       = c_b;
  wire [4:0] c_opcode =
    (c_op)            ? 5'b01100 :
    (c_load)          ? 5'b00000 :
    (c_store)         ? 5'b01000 :
    (c_jal)           ? 5'b11011 :
    (c_jalr)          ? 5'b11001 :
    (c_lui)           ? 5'b01101 :
    (c_branch)        ? 5'b11000 :
    5'b00100;

  // Opcode assignment
  wire [31:0] c_opcode_in =
    {c_funct7, c_rs2, c_rs1, c_funct3, c_rd, c_opcode, {2{valid_c}}};
  wire [31:0] opcode_in = (q_3)? i_opcode_in : c_opcode_in;

`else

  // Opcode assignment
  wire [31:0] opcode_in = i_opcode_in;
`endif

  /**
   * Opcode elements extraction
   */
  wire [4:0] opcode = opcode_in[6:2];
  wire [4:0] rs1    = opcode_in[19:15] & {5{!op_lui}};
  wire [4:0] rs2    = opcode_in[24:20];
  wire [4:0] rd     = opcode_in[11:7];
  wire [2:0] funct3 = opcode_in[14:12];
  wire [6:0] funct7 = opcode_in[31:25];

  /**
   * Operation decoding
   */
  wire op_load   = (opcode == 5'b00000);
  wire op_op_imm = (opcode == 5'b00100);
  wire op_auipc  = (opcode == 5'b00101);
  wire op_store  = (opcode == 5'b01000);
  wire op_op     = (opcode == 5'b01100);
  wire op_lui    = (opcode == 5'b01101);
  wire op_branch = (opcode == 5'b11000);
  wire op_jalr   = (opcode == 5'b11001);
  wire op_jal    = (opcode == 5'b11011);
  wire op_system = (opcode == 5'b11100);

  /**
   * Format decoding
   */
  wire format_u = op_auipc || op_lui;
  wire format_j = op_jal;
  wire format_b = op_branch;
  wire format_s = op_store;
  wire format_r = op_op;
  wire format_i = op_load || op_op_imm || op_jalr || op_system;

  /**
   * Opcode validation
   */
  wire opcode_valid = (opcode_in[1:0] == 2'b11) && (
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
    opcode_in[31:12],
    12'h000
  };

  // Jump immediate
  //  JAL
  wire [31:0] immediate_j = {
    {12{opcode_in[31]}},
    opcode_in[19:12],
    opcode_in[20],
    opcode_in[30:21],
    1'b0
  };

  // Branch immediate
  //  BEQ BNE BLT BGE BLTU BGEU
  wire [31:0] immediate_b = {
    {20{opcode_in[31]}},
    opcode_in[7],
    opcode_in[30:25],
    opcode_in[11:8],
    1'b0
  };

  // Store immediate
  //  SB SH SW
  wire [31:0] immediate_s = {
    {21{opcode_in[31]}},
    opcode_in[30:25],
    opcode_in[11:7]
  };

  // Normal immediate
  //  LB LH LW LBU LHU ADDI SLTI SLTIU XORI ORI ANDI
  wire [31:0] immediate_i = {
    {21{opcode_in[31]}},
    opcode_in[30:20]
  };

  // Immediate multiplexer
  wire [31:0] immediate_mux =
    (format_u) ? immediate_u :
    (format_j) ? immediate_j :
    (format_b) ? immediate_b :
    (format_i) ? immediate_i :
    (format_s) ? immediate_s :
    32'h00000000;

  /**
   * Internal CPU signals
   */
  // Only branches, JAL and AUIPC use ALU to generate address from pc.
  // JALR uses rs1 as address base so it isn't here.
  wire alu_pc = op_jal || op_auipc || op_branch;
  // Only normal arythmetics don't use immediate values.
  wire alu_imm = !op_op;
  // ALU is enabled on OP and OP_IMM, everything else just relys on ADD.
  // In disabled state ALU only performs ADD operations.
  wire alu_en = op_op || op_op_imm;

  // This will select what is stored in write back register.
  // There are three possible write back sources:
  //  [ 00 ] - ALU
  //  [ 01 ] - Memory (LOAD)
  //  [ 10 ] - Return address (JAL and JALR)
  wire [1:0] wb_mux = {op_jal || op_jalr, op_load};

  // These are pretty selfexplenatory
  wire ma_wr = op_store && opcode_valid;
  wire ma_rd = op_load && opcode_valid;

  // Only stores and branches don't write back any data.
  // This changes future states of the cpu so we need to make sure that
  //  the opcode is valid.
  wire wb_en = !(op_store || op_branch) && opcode_valid;

  // Only LUI, AUIPC and JAL don't use RSA so they don't generate hazard
  wire hz_rs1 = !(op_lui || op_auipc || op_jal);
  // Only branches, stores and normal ops use RSB so they do generate hazard
  wire hz_rs2 = op_branch || op_store || op_op;

  /**
   * Output assignments
   */
  assign o_immediate  = immediate_mux;
  assign o_opcode     = opcode;
  assign o_funct3     = funct3;
  assign o_funct7     = funct7;

  assign o_system     = op_system;

  assign o_rs1        = rs1;
  assign o_rs2        = rs2;
  assign o_rd         = rd;

  assign o_hz_rs1     = hz_rs1;
  assign o_hz_rs2     = hz_rs2;

  assign o_alu_pc     = alu_pc;
  assign o_alu_imm    = alu_imm;
  assign o_alu_en     = alu_en;

  assign o_ma_wr      = ma_wr;
  assign o_ma_rd      = ma_rd;

  assign o_wb_mux     = wb_mux;
  assign o_wb_en      = wb_en;


endmodule
