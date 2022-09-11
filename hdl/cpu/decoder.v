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

  // Format decoding
  wire        format_u;
  wire        format_j;
  wire        format_b;
  wire        format_s;
  wire        format_r;
  wire        format_i;
  wire        opcode_valid;

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
  wire [31:0] immediate_c16sp;
  wire [31:0] immediate_cls;
  wire [31:0] immediate_cj;
  wire [31:0] immediate_cb;
  wire [31:0] immediate_cssp;
  wire [31:0] immediate_clsp;
`endif

  // Internal signals decoding
  wire        branch;
  wire        jump;
  wire        alu_pc;
  wire        alu_imm;
  wire        alu_en;
  wire  [1:0] wb_mux;
  wire        ma_wr;
  wire        ma_rd;
  wire        wb_en;
  wire        hz_rs1;
  wire        hz_rs2;


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
`endif

  /**
   * Operation decoding
   */
  assign op_load   = quad3  && (opcode == 5'b00000);
  assign op_op_imm = quad3  && (opcode == 5'b00100);
  assign op_auipc  = quad3  && (opcode == 5'b00101);
  assign op_store  = quad3  && (opcode == 5'b01000);
  assign op_op     = quad3  && (opcode == 5'b01100);
  assign op_lui    = quad3  && (opcode == 5'b01101);
  assign op_branch = quad3  && (opcode == 5'b11000);
  assign op_jalr   = quad3  && (opcode == 5'b11001);
  assign op_jal    = quad3  && (opcode == 5'b11011);
  assign op_system = quad3  && (opcode == 5'b11100);
`ifdef C_EXTENSION
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
   * Format decoding
   */
  assign format_u = op_auipc || op_lui;
  assign format_j = op_jal;
  assign format_b = op_branch;
  assign format_s = op_store;
  assign format_r = op_op;
  assign format_i = op_load || op_op_imm || op_jalr || op_system;

  /**
   * Opcode validation
   */
  assign opcode_valid = (i_opcode_in[1:0] == 2'b11) && (
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
    24'b0000_0000_0000_0000_0000_0000,
    i_opcode_in[10:7],
    i_opcode_in[12:11],
    i_opcode_in[5],
    i_opcode_in[6]
  };

  // Compressed immediate
  //  C.ADDI C.LI C.ANDI C.SLLI
  assign immediate_ci = {
    {27{i_opcode_in[12]}},
    i_opcode_in[6:2]
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
    {28{i_opcode_in[5]}},
    i_opcode_in[12:10],
    i_opcode_in[6]
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
      format_u: immediate_mux = immediate_u;
      format_j: immediate_mux = immediate_j;
      format_b: immediate_mux = immediate_b;
      format_i: immediate_mux = immediate_i;
      format_s: immediate_mux = immediate_s;
      default:  immediate_mux = 32'h00000000;
    endcase
  end


  /**
   * Internal CPU signals
   */

  // Branch and jump signals
  assign branch = op_branch;
  assign jump   = op_jal || op_jalr;

  // Only branches, JAL and AUIPC use ALU to generate address from pc.
  // JALR uses rs1 as address base so it isn't here.
  assign alu_pc = op_jal || op_auipc || op_branch;
  // Only normal arythmetics don't use immediate values.
  assign alu_imm = !op_op;
  // ALU is enabled on OP and OP_IMM, everything else just relys on ADD.
  // In disabled state ALU only performs ADD operations.
  assign alu_en = op_op || op_op_imm;

  // This will select what is stored in write back register.
  // There are three possible write back sources:
  //  [ 00 ] - ALU
  //  [ 01 ] - Memory (LOAD)
  //  [ 10 ] - Return address (JAL and JALR)
  assign wb_mux = {op_jal || op_jalr, op_load};

  // These are pretty selfexplenatory
  assign ma_wr = op_store && opcode_valid;
  assign ma_rd = op_load && opcode_valid;

  // Only stores and branches don't write back any data.
  // This changes future states of the cpu so we need to make sure that
  //  the opcode is valid.
  assign wb_en = !(op_store || op_branch) && opcode_valid;

  // Only LUI, AUIPC and JAL don't use RSA so they don't generate hazard
  assign hz_rs1 = !(op_lui || op_auipc || op_jal);
  // Only branches, stores and normal ops use RSB so they do generate hazard
  assign hz_rs2 = op_branch || op_store || op_op;

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
