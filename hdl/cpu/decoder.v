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
  wire [4:0] rs1_cs    = {2'b01, i_opcode_in[9:7]};
  wire [4:0] rs2_cs    = {2'b01, i_opcode_in[4:2]};
  wire [4:0] rs1_cl    = i_opcode_in[11:7];
  wire [4:0] rs2_cl    = i_opcode_in[6:2];
  wire [2:0] funct3_c  = i_opcode_in[15:13];
  wire [1:0] funct2_ch = i_opcode_in[11:10];
  wire [1:0] funct2_cl = i_opcode_in[6:5];

  wire quad_0 = (i_opcode_in[1:0] == 2'b00);
  wire quad_1 = (i_opcode_in[1:0] == 2'b01);
  wire quad_2 = (i_opcode_in[1:0] == 2'b10);
  wire quad_3 = (i_opcode_in[1:0] == 2'b11);

  wire [7:0] immediate_ciw = {
    i_opcode_in[10:7],
    i_opcode_in[12:11],
    i_opcode_in[5],
    i_opcode_in[6]
  };

  wire [5:0] immediate_ci = {
    i_opcode_in[12],
    i_opcode_in[6:2]
  };

  wire [9:4] immediate_c16sp = {
    i_opcode_in[12],
    i_opcode_in[4:3],
    i_opcode_in[5],
    i_opcode_in[2],
    i_opcode_in[6]
  };

  wire [4:0] immediate_cls = {
    i_opcode_in[5],
    i_opcode_in[12:10],
    i_opcode_in[6]
  };

  wire [5:0] immediate_ca = {
    i_opcode_in[12],
    i_opcode_in[6:2]
  };

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

  wire [8:1] immediate_cb = {
    i_opcode_in[12],
    i_opcode_in[6:5],
    i_opcode_in[2],
    i_opcode_in[11:10],
    i_opcode_in[4:3]
  };

  wire [7:2] immediate_cssp = {
    i_opcode_in[8:7],
    i_opcode_in[12:9]
  };

  wire [7:2] immediate_clsp = {
    i_opcode_in[3:2],
    i_opcode_in[12],
    i_opcode_in[6:4]
  };

  wire c_addi4spn = quad_0 && (funct3_c == 3'b000);

  wire c_lui = quad_1 && (funct3_c == 3'b011) &&
      (rs1_cl != 5'b00000) && (rs1_cl != 5'b00010);

  wire c_addi16sp = quad_1 && (funct3_c == 3'b011) && (rs1_cl == 5'b00010);

  wire c_lw = quad_0 && (funct3_c == 3'b010);

  wire c_sw = quad_0 && (funct3_c == 3'b110);

  wire c_addi = quad_1 && (funct3_c == 3'b000) && (rs1_cl != 5'b00000);

  wire c_li = quad_1 && (funct3_c == 3'b010) && (rs1_cl != 5'b00000);

  wire c_alu = quad_1 && (funct3_c == 3'b100);

  wire c_sri = c_alu && !funct2_ch[1];

  wire c_ar = c_alu && (funct2_ch == 2'b11);
  wire [2:0] c_ar_f3 =
    (funct2_cl == 2'b00) ? 3'b000 :
    (funct2_cl == 2'b01) ? 3'b100 :
    (funct2_cl == 2'b10) ? 3'b110 :
    (funct2_cl == 2'b11) ? 3'b111 : 0;
  wire c_sub = c_ar && (funct2_cl == 2'b00);

  wire c_andi = c_alu && (funct2_ch == 2'b10);

  wire c_slli = quad_2 && (funct3_c == 3'b000);

  wire c_j = quad_1 && (funct3_c[1:0] == 2'b01);

  wire c_b = quad_1 && (funct3_c[2:1] == 2'b11);

  wire c_jr = quad_2 && (funct3_c == 3'b100) &&
    (rs1_cl != 5'b00000) && (rs2_cl == 5'b00000);

  wire c_add = quad_2 && (funct3_c == 3'b100) &&
    (rs1_cl != 5'b00000) && (rs2_cl != 5'b00000);

  wire c_lwsp = quad_2 && (funct3_c == 3'b010);

  wire c_swsp = quad_2 && (funct3_c == 3'b110);

  wire valid_c = c_addi4spn || c_lui || c_addi16sp || c_lw ||
    c_sw || c_li || c_addi || c_sri || c_andi || c_ar ||
    c_slli || c_j || c_b || c_jr || c_add || c_swsp || c_lwsp;

  wire [4:0] c_rd =
    (c_addi4spn) ? rs2_cs :
    (c_lui) ? rs1_cl :
    (c_addi16sp) ? rs1_cl :
    (c_lw) ? rs2_cs :
    (c_sw) ? {immediate_cls[2:0], 2'b00} :
    (c_addi) ? rs1_cl :
    (c_li) ? rs1_cl :
    (c_sri) ? rs1_cs :
    (c_andi) ? rs1_cs :
    (c_ar) ? rs1_cs :
    (c_slli) ? rs1_cl :
    (c_j) ? {4'b0000, !funct3_c[2]} :
    (c_b) ? {immediate_cb[4:1], immediate_cb[8]} :
    (c_jr) ? {4'b0000, i_opcode_in[12]} :
    (c_add) ? rs1_cl :
    (c_lwsp) ? rs1_cl :
    (c_swsp) ? {immediate_cssp[4:2], 2'b00} : 0;

  wire [4:0] c_rs1 =
    (c_addi4spn) ? 5'b00010 :
    (c_lui) ? {{3{immediate_ci[5]}}, immediate_ci[4:3]} :
    (c_addi16sp) ? 5'b00010 :
    (c_lw) ? rs1_cs :
    (c_sw) ? rs1_cs :
    (c_addi) ? rs1_cl :
    (c_li) ? 5'b00000 :
    (c_sri) ? rs1_cs :
    (c_andi) ? rs1_cs :
    (c_ar) ? rs1_cs :
    (c_slli) ? rs1_cl :
    (c_j) ? {5{immediate_cj[11]}} :
    (c_b) ? rs1_cs :
    (c_jr) ? rs1_cl :
    (c_add) ? rs1_cl & {5{i_opcode_in[12]}} :
    (c_lwsp) ? 5'b00010 :
    (c_swsp) ? 5'b00010 : 0;

  wire [4:0] c_rs2 =
    (c_addi4spn) ? {immediate_ciw[2:0], 2'b00} :
    (c_lui) ? {5{immediate_ci[5]}} :
    (c_addi16sp) ? {immediate_c16sp[4], 4'b0000} :
    (c_lw) ? {immediate_cls[2:0], 2'b00} :
    (c_sw) ? rs2_cs :
    (c_addi) ? immediate_ci[4:0] :
    (c_li) ? immediate_ci[4:0] :
    (c_sri) ? immediate_ca[4:0] :
    (c_andi) ? immediate_ca[4:0] :
    (c_ar) ? rs2_cs :
    (c_slli) ? immediate_ca[4:0] :
    (c_j) ? {immediate_cj[4:1], immediate_cj[11]} :
    (c_b) ? 5'b00000 :
    (c_jr) ? 5'b00000 :
    (c_add) ? rs2_cl :
    (c_lwsp) ? {immediate_clsp[4:2], 2'b00} :
    (c_swsp) ? rs2_cl : 0;

  wire [2:0] c_funct3 =
    (c_addi4spn) ? 3'b000 :
    (c_lui) ? immediate_ci[2:0] :
    (c_addi16sp) ? 3'b000 :
    (c_lw) ? 3'b010 :
    (c_sw) ? 3'b010 :
    (c_addi) ? 3'b000 :
    (c_li) ? 3'b000 :
    (c_sri) ? 3'b101 :
    (c_andi) ? 3'b111 :
    (c_ar) ? c_ar_f3 :
    (c_slli) ? 3'b001 :
    (c_j) ? {3{immediate_cj[11]}} :
    (c_b) ? {2'b00, funct3_c[0]} :
    (c_jr) ? 3'b000 :
    (c_add) ? 3'b000 :
    (c_lwsp) ? 3'b010 :
    (c_swsp) ? 3'b010 : 0;

  wire [6:0] c_funct7 =
    (c_addi4spn) ? {2'b00, immediate_ciw[7:3]} :
    (c_lui) ? {7{immediate_ci[5]}} :
    (c_addi16sp) ? {{3{immediate_c16sp[9]}}, immediate_c16sp[8:5]} :
    (c_lw) ? {5'b00000, immediate_cls[4:3]} :
    (c_sw) ? {5'b00000, immediate_cls[4:3]} :
    (c_addi) ? {7{immediate_ci[5]}} :
    (c_li) ? {7{immediate_ci[5]}} :
    (c_sri) ? {1'b0, funct2_ch[0], 5'b00000} :
    (c_andi) ? {7{immediate_ca[5]}} :
    (c_ar) ? {1'b0, c_sub, 5'b00000} :
    (c_slli) ? 7'b0000000 :
    (c_j) ? {immediate_cj[11:5]} :
    (c_b) ? {{4{immediate_cb[8]}}, immediate_cb[7:5]} :
    (c_jr) ? 7'b0000000 :
    (c_add) ? 7'b0000000 :
    (c_lwsp) ? {4'b0000, immediate_clsp[7:5]} :
    (c_swsp) ? {4'b0000, immediate_cssp[7:5]} : 0;

  wire [4:0] c_opcode =
    (c_addi4spn) ? 5'b00100 :
    (c_lui) ? 5'b01101 :
    (c_addi16sp) ? 5'b00100 :
    (c_lw) ? 5'b00000 :
    (c_sw) ? 5'b01000 :
    (c_addi) ? 5'b00100 :
    (c_li) ? 5'b00100 :
    (c_sri) ? 5'b00100 :
    (c_andi) ? 5'b00100 :
    (c_ar) ? 5'b01100 :
    (c_slli) ? 5'b00100 :
    (c_j) ? 5'b11011 :
    (c_b) ? 5'b11000 :
    (c_jr) ? 5'b11001 :
    (c_add) ? 5'b01100 :
    (c_lwsp) ? 5'b00000 :
    (c_swsp) ? 5'b01000 : 0;

  wire [31:0] c_opcode_in =
    {c_funct7, c_rs2, c_rs1, c_funct3, c_rd, c_opcode, {2{valid_c}}};
  wire [31:0] opcode_in = (quad_3)? i_opcode_in : c_opcode_in;
`else
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
