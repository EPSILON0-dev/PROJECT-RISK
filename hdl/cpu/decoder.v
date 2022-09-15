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


  // Opcode elements extraction
  wire  [4:0] opcode;
  wire  [4:0] rs1;
  wire  [4:0] rs2;
  wire  [4:0] rd;
  wire  [2:0] funct3;
  wire  [6:0] funct7;
`ifdef C_EXTENSION
  wire  [4:0] rs1cs;
  wire  [4:0] rs2cs;
  wire  [4:0] rs1cl;
  wire  [4:0] rs2cl;
  wire  [1:0] funct2h;
  wire  [1:0] funct2l;
  wire  [2:0] copcode;
`endif

  // Opcode decoding
  wire        quad0;
  wire        quad1;
  wire        quad2;
  wire        quad3;
  wire        op_load;
  wire        op_op_imm;
  wire        op_auipc;
  wire        op_store;
  wire        op_op;
  wire        op_lui;
  wire        op_branch;
  wire        op_jalr;
  wire        op_jal;
  wire        op_system;
`ifdef C_EXTENSION
  wire        op_caddi4spn;
  wire        op_clw;
  wire        op_csw;
  wire        op_caddi;
  wire        op_cjal;
  wire        op_cli;
  wire        op_clui_a16sp;
  wire        op_calu;
  wire        op_cj;
  wire        op_cbeqz;
  wire        op_cbnez;
  wire        op_cslli;
  wire        op_clwsp;
  wire        op_cjr_mv_add;
`endif

  wire        op_jump;
`ifdef C_EXTENSION
  wire        op_caddi16sp;
  wire        op_clui;
  wire        op_csrli;
  wire        op_csrai;
  wire        op_candi;
  wire        op_caryth;
  wire        op_csub;
  wire        op_cxor;
  wire        op_cor;
  wire        op_cand;
`endif

  // Format decoding
  wire        opcode_valid;
  wire        format_u;
  wire        format_j;
  wire        format_b;
  wire        format_s;
  wire        format_r;
  wire        format_i;
`ifdef C_EXTENSION
  wire        format_ciw;
  wire        format_ci;
  wire        format_cu;
  wire        format_c16sp;
  wire        format_cls;
  wire        format_cj;
  wire        format_cb;
  wire        format_cssp;
  wire        format_clsp;
`endif

  // Immediate deconding
  wire [31:0] immediate_u;
  wire [31:0] immediate_j;
  wire [31:0] immediate_b;
  wire [31:0] immediate_s;
  wire [31:0] immediate_i;
  reg  [31:0] immediate_mux;
`ifdef C_EXTENSION
  wire [31:0] immediate_ciw;
  wire [31:0] immediate_ci;
  wire [31:0] immediate_cu;
  wire [31:0] immediate_c16sp;
  wire [31:0] immediate_cls;
  wire [31:0] immediate_cj;
  wire [31:0] immediate_cb;
  wire [31:0] immediate_cssp;
  wire [31:0] immediate_clsp;
`endif

  // Internal signals decoding
  wire        alu_pc;
  wire        alu_imm;
  wire        alu_en;
  wire  [1:0] wb_mux;
  wire        ma_wr;
  wire        ma_rd;
  wire        wb_en;
  wire        hz_rs1;
  wire        hz_rs2;
`ifdef C_EXTENSION
  reg   [4:0] rs1_mux;
  reg   [4:0] rs2_mux;
  reg   [4:0] rd_mux;
  reg   [2:0] funct3_mux;
  reg   [6:0] funct7_mux;
`else
  wire  [4:0] rs1_mux;
  wire  [4:0] rs2_mux;
  wire  [4:0] rd_mux;
  wire  [2:0] funct3_mux;
  wire  [6:0] funct7_mux;
`endif

  /**
   * Opcode elements extraction
   */
  assign opcode  = i_opcode_in[6:2];
  assign rs1     = i_opcode_in[19:15] & {5{!op_lui}};
  assign rs2     = i_opcode_in[24:20];
  assign rd      = i_opcode_in[11:7];
  assign funct3  = i_opcode_in[14:12];
  assign funct7  = i_opcode_in[31:25];
`ifdef C_EXTENSION
  assign copcode = i_opcode_in[15:13];
  assign rs1cs   = {2'b01, i_opcode_in[9:7]};
  assign rs2cs   = {2'b01, i_opcode_in[4:2]};
  assign rs1cl   = i_opcode_in[11:7];
  assign rs2cl   = i_opcode_in[6:2];
  assign funct2h = i_opcode_in[11:10];
  assign funct2l = i_opcode_in[6:5];
`endif

  /**
   * Operation decoding
   */
  assign quad3         = (i_opcode_in[1:0] == 2'b11);
  assign op_load       = quad3 && (opcode == 5'b00000);
  assign op_op_imm     = quad3 && (opcode == 5'b00100);
  assign op_auipc      = quad3 && (opcode == 5'b00101);
  assign op_store      = quad3 && (opcode == 5'b01000);
  assign op_op         = quad3 && (opcode == 5'b01100);
  assign op_lui        = quad3 && (opcode == 5'b01101);
  assign op_branch     = quad3 && (opcode == 5'b11000);
  assign op_jalr       = quad3 && (opcode == 5'b11001);
  assign op_jal        = quad3 && (opcode == 5'b11011);
  assign op_system     = quad3 && (opcode == 5'b11100);
`ifdef C_EXTENSION
  assign quad0         = (i_opcode_in[1:0] == 2'b00);
  assign quad1         = (i_opcode_in[1:0] == 2'b01);
  assign quad2         = (i_opcode_in[1:0] == 2'b10);
  assign op_caddi4spn  = quad0 && (copcode == 3'b000);
  assign op_clw        = quad0 && (copcode == 3'b010);
  assign op_csw        = quad0 && (copcode == 3'b110);
  assign op_caddi      = quad1 && (copcode == 3'b000);
  assign op_cjal       = quad1 && (copcode == 3'b001);
  assign op_cli        = quad1 && (copcode == 3'b010);
  assign op_clui_a16sp = quad1 && (copcode == 3'b011);
  assign op_calu       = quad1 && (copcode == 3'b100);
  assign op_cj         = quad1 && (copcode == 3'b101);
  assign op_cbeqz      = quad1 && (copcode == 3'b110);
  assign op_cbnez      = quad1 && (copcode == 3'b111);
  assign op_cslli      = quad2 && (copcode == 3'b000);
  assign op_clwsp      = quad2 && (copcode == 3'b010);
  assign op_cjr_mv_add = quad2 && (copcode == 3'b100);
  assign op_cswsp      = quad2 && (copcode == 3'b110);
`endif

  /**
   * Operation decoding helper signals
   */
  assign op_jump      = op_jal || op_jalr;
`ifdef C_EXTENSION
  assign op_caddi16sp = op_clui_a16sp && (rs1cl == 5'b00010);
  assign op_clui      = op_clui_a16sp && (rs1cl != 5'b00010) && |rs1cl;
  assign op_csrli     = op_calu && (funct2h == 2'b00);
  assign op_csrai     = op_calu && (funct2h == 2'b01);
  assign op_candi     = op_calu && (funct2h == 2'b10);
  assign op_caryth    = op_calu && (funct2h == 2'b11);
  assign op_csub      = op_caryth && (funct2l == 2'b00);
  assign op_cxor      = op_caryth && (funct2l == 2'b01);
  assign op_cor       = op_caryth && (funct2l == 2'b10);
  assign op_cand      = op_caryth && (funct2l == 2'b11);
`endif

  /**
   * Format decoding
   */
  assign format_u = op_auipc || op_lui;
  assign format_j = op_jal;
  assign format_b = op_branch;
  assign format_s = op_store;
  assign format_r = op_op;
  assign format_i = op_load || op_op_imm || op_jalr || op_system;
`ifdef C_EXTENSION
  assign format_ciw   = op_caddi4spn;
  assign format_ci    = op_caddi || op_cli || op_candi || op_cslli ||
    op_csrai || op_csrli;
  assign format_cu    = op_clui;
  assign format_c16sp = op_caddi16sp;
  assign format_cls   = op_clw || op_csw;
  assign format_cj    = op_cj || op_cjal;
  assign format_cb    = op_cbeqz || op_cbnez;
  assign format_cssp  = op_cswsp;
  assign format_clsp  = op_clwsp;
`endif

  /**
   * Opcode validation
   */
  assign opcode_valid = (
  `ifdef C_EXTENSION
    op_calu      ||
    format_ciw   ||
    format_ci    ||
    format_cu    ||
    format_c16sp ||
    format_cls   ||
    format_cj    ||
    format_cb    ||
    format_cssp  ||
    format_clsp  ||
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
  assign immediate_u = {
    i_opcode_in[31:12],
    12'h000
  };

  // Jump immediate
  //  JAL
  assign immediate_j = {
    {12{i_opcode_in[31]}},
    i_opcode_in[19:12],
    i_opcode_in[20],
    i_opcode_in[30:21],
    1'b0
  };

  // Branch immediate
  //  BEQ BNE BLT BGE BLTU BGEU
  assign immediate_b = {
    {20{i_opcode_in[31]}},
    i_opcode_in[7],
    i_opcode_in[30:25],
    i_opcode_in[11:8],
    1'b0
  };

  // Store immediate
  //  SB SH SW
  assign immediate_s = {
    {21{i_opcode_in[31]}},
    i_opcode_in[30:25],
    i_opcode_in[11:7]
  };

  // Normal immediate
  //  LB LH LW LBU LHU ADDI SLTI SLTIU XORI ORI ANDI
  assign immediate_i = {
    {21{i_opcode_in[31]}},
    i_opcode_in[30:20]
  };

`ifdef C_EXTENSION
  // Compressed immediate word
  //  C.ADDI4SPN
  assign immediate_ciw = {
    22'b00_0000_0000_0000_0000_0000,
    i_opcode_in[10:7],
    i_opcode_in[12:11],
    i_opcode_in[5],
    i_opcode_in[6],
    2'b00
  };

  // Compressed immediate
  //  C.ADDI C.LI C.ANDI C.SLLI
  assign immediate_ci = {
    {27{i_opcode_in[12]}},
    i_opcode_in[6:2]
  };

  // Compressed immediate
  //  C.LUI
  assign immediate_cu = {
    {15{i_opcode_in[12]}},
    i_opcode_in[6:2],
    12'b0000_0000_0000
  };

  // Compressed 16byte stack offset immediate
  //  C.ADDI16SP
  assign immediate_c16sp = {
    {23{i_opcode_in[12]}},
    i_opcode_in[4:3],
    i_opcode_in[5],
    i_opcode_in[2],
    i_opcode_in[6],
    4'b0000
  };

  // Compressed load/store immediate
  //  C.LW C.SW
  assign immediate_cls = {
    {26{i_opcode_in[5]}},
    i_opcode_in[12:10],
    i_opcode_in[6],
    2'b00
  };

  // Compressed jump immediate
  //  C.J C.JAL
  assign immediate_cj = {
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
  assign immediate_cb = {
    {24{i_opcode_in[12]}},
    i_opcode_in[6:5],
    i_opcode_in[2],
    i_opcode_in[11:10],
    i_opcode_in[4:3],
    1'b0
  };

  // Compressed stack based store
  //  C.SWSP
  assign immediate_cssp = {
    24'b0000_0000_0000_0000_0000_0000,
    i_opcode_in[8:7],
    i_opcode_in[12:9],
    2'b00
  };

  // Compressed stack based load
  //  C.LWSP
  assign immediate_clsp = {
    24'b0000_0000_0000_0000_0000_0000,
    i_opcode_in[3:2],
    i_opcode_in[12],
    i_opcode_in[6:4],
    2'b00
  };
`endif

  // Immediate multiplexer
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
  wire c_op_store = op_store || op_csw;
  wire c_op_load  = op_load  || op_clw;
  wire c_op_op_imm = op_op_imm || (op_calu && !op_caryth) || op_cslli;
  wire c_op_op = op_op || op_caryth;
  wire c_jal = op_jal || op_cj || op_cjal;
  assign alu_pc = op_jal || op_auipc || op_branch;
  assign alu_imm = !c_op_op;
  assign alu_en = c_op_op || c_op_op_imm;
  assign wb_mux = {c_jal || op_jalr, c_op_load};
  assign ma_wr = c_op_store && opcode_valid;
  assign ma_rd = c_op_load && opcode_valid;
  assign wb_en = !(c_op_store || op_branch) && opcode_valid;
  assign hz_rs1 = !(op_lui || op_auipc || op_jal);
  assign hz_rs2 = op_branch || c_op_store || c_op_op;
`else
  assign alu_pc = op_jal || op_auipc || op_branch;
  assign alu_imm = !op_op;
  assign alu_en = op_op || op_op_imm;
  assign wb_mux = {op_jal || op_jalr, op_load};
  assign ma_wr = op_store && opcode_valid;
  assign ma_rd = op_load && opcode_valid;
  assign wb_en = !(op_store || op_branch) && opcode_valid;
  assign hz_rs1 = !(op_lui || op_auipc || op_jal);
  assign hz_rs2 = op_branch || op_store || op_op;
`endif

`ifdef C_EXTENSION

`ifdef HARDWARE_TIPS
  (* parallel_case *)
`endif
  always @* begin
    case (1'b1)
      rs1_normal: rs1_mux = rs1;
      rs1_rs1l: rs1_mux = rs1cl;
      rs1_rs1s: rs1_mux = rs1cs;
      default: rs1_mux = {3'b000, rs1_sp, 1'b0};
    endcase
  end
  wire rs1_normal = quad3;
  wire rs1_sp = op_caddi4spn;
  wire rs1_rs1l = op_caddi16sp || op_caddi || op_cslli;
  wire rs1_rs1s = op_clw || op_csw || op_csrai || op_csrli || op_candi ||
    op_caryth;

`ifdef HARDWARE_TIPS
  (* parallel_case *)
`endif
  always @* begin
    case (1'b1)
      rs2_normal: rs2_mux = rs2;
      rs2_rs2s: rs2_mux = rs2cs;
      default: rs2_mux = 5'b00000;
    endcase
  end
  wire rs2_normal = quad3;
  wire rs2_rs2s = op_csw || op_caryth;

`ifdef HARDWARE_TIPS
  (* parallel_case *)
`endif
  always @* begin
    case (1'b1)
      rd_normal: rd_mux = rd;
      rd_rs1l: rd_mux = rs1cl;
      rd_rs1s: rd_mux = rs1cs;
      rd_rs2s: rd_mux = rs2cs;
      default: rd_mux = {4'b0000, op_cjal};
    endcase
  end
  wire rd_normal = quad3;
  wire rd_rs2s = op_caddi4spn || op_clw;
  wire rd_rs1l = op_caddi16sp || op_caddi || op_cli || op_clui || op_cslli;
  wire rd_rs1s = op_csrai || op_csrli || op_candi || op_caryth;

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
  wire funct3_010    = op_clw || op_csw;
  wire funct3_100    = op_cxor;
  wire funct3_101    = op_csrai || op_csrli;
  wire funct3_110    = op_cor;
  wire funct3_111    = op_candi || op_cand;

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
  assign rs1_mux    = rs1;
  assign rs2_mux    = rs2;
  assign rd_mux     = rd;
  assign funct3_mux = funct3;
  assign funct7_mux = funct7;
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

  assign o_branch     = op_branch;
  assign o_jump       = op_jump;

  assign o_alu_pc     = alu_pc;
  assign o_alu_imm    = alu_imm;
  assign o_alu_en     = alu_en;

  assign o_ma_wr      = ma_wr;
  assign o_ma_rd      = ma_rd;

  assign o_wb_mux     = wb_mux;
  assign o_wb_en      = wb_en;


endmodule
