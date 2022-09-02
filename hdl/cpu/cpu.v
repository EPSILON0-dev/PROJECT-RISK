`include "config.v"
`include "alu.v"
`include "branch.v"
`include "decoder.v"
`include "fetch.v"
`include "hazard.v"
`include "memory.v"
`include "regs.v"

`ifdef INCLUDE_CSR
`include "csr.v"
`endif

module cpu (
  input         i_clk,
  input         i_rst,
  input         i_valid_i,
  input         i_valid_d,
  input  [31:0] i_data_in_i,
  input  [31:0] i_data_in_d,
  output [31:0] o_addr_i,
  output [31:0] o_addr_d,
  output  [3:0] o_we_d,
  output        o_rd_d,
  output [31:0] o_data_out_d
);


  /**
   * Hazard Detector
   */
  wire hz_data;

  hazard hazard_i (
    .i_hz_rs1    (hz_rs1),
    .i_hz_rs2    (hz_rs2),
    .i_rs1       (rs1),
    .i_rs2       (rs2),
    .i_ex_wb_reg (ex_wb_reg),
    .i_ma_wb_reg (ma_wb_reg),
    .i_wb_wb_reg (wb_wb_reg),
    .o_hz_data   (hz_data)
  );

  /**
   * Clock Signals
   */
  wire clk_ce = i_valid_i && i_valid_d && !alu_busy;
  wire clk_n = !i_clk;

  ///////////////////////////////////////////////////////////////////////////
  // FETCH STAGE
  ///////////////////////////////////////////////////////////////////////////

  /**
   * Instruction fetch circuitry
   */
  wire [31:0] if_pc;
  wire [31:0] id_pc;
  wire [31:0] id_ir;
  wire [31:0] id_ret;
  wire hz_br;

  fetch fetch_i (
    .i_clk      (i_clk),
    .i_clk_ce   (clk_ce),
    .i_rst      (i_rst),
    .i_data_in  (i_data_in_i),
    .i_hz_data  (hz_data),
    .i_br_en    (br_en),
    .i_br_addr  (alu_out),
    .o_if_pc    (if_pc),
    .o_id_pc    (id_pc),
    .o_id_ret   (id_ret),
    .o_id_ir    (id_ir),
    .o_hz_br    (hz_br)
  );

  ///////////////////////////////////////////////////////////////////////////
  // DECODE STAGE
  ///////////////////////////////////////////////////////////////////////////

  /**
   * Instruction Decoder
   */
  wire [31:0] immediate;
  wire [ 4:0] opcode;
  wire [ 2:0] funct3;
  wire [ 6:0] funct7;
  wire [ 4:0] rs1;
  wire [ 4:0] rs2;
  wire [ 4:0] rd;
  wire        hz_rs1;
  wire        hz_rs2;
  wire        alu_pc;
  wire        alu_imm;
  wire        alu_en;
  wire        d_wr;
  wire        d_rd;
  wire [ 1:0] wb_mux;
  wire        wb_en;
  wire        system;

  decoder decoder_i (
    .i_opcode_in (id_ir),
    .o_immediate (immediate),
    .o_opcode    (opcode),
    .o_funct3    (funct3),
    .o_funct7    (funct7),
    .o_rs1       (rs1),
    .o_rs2       (rs2),
    .o_rd        (rd),
    .o_system    (system),
    .o_hz_rs1    (hz_rs1),
    .o_hz_rs2    (hz_rs2),
    .o_alu_pc    (alu_pc),
    .o_alu_imm   (alu_imm),
    .o_alu_en    (alu_en),
    .o_ma_wr     (d_wr),
    .o_ma_rd     (d_rd),
    .o_wb_mux    (wb_mux),
    .o_wb_en     (wb_en)
  );

  /**
   * Register set
   */
  wire [31:0] rs1_d;
  wire [31:0] rs2_d;

  regs regs_i (
    .i_clk       (clk_n),
    .i_ce        (clk_ce),
    .i_we        (wb_wb_en),
    .i_addr_rd_a (rs1),
    .i_addr_rd_b (rs2),
    .i_addr_wr   (wb_wb_reg),
    .i_dat_wr    (wb_wb_d),
    .o_dat_rd_a  (rs1_d),
    .o_dat_rd_b  (rs2_d)
  );

  ///////////////////////////////////////////////////////////////////////////
  // EXECUTE STAGE
  ///////////////////////////////////////////////////////////////////////////

  /**
   * Execute Registers
   */
  reg  [31:0] ex_rs1_d;
  reg  [31:0] ex_rs2_d;
  reg  [31:0] ex_imm;
  reg  [31:0] ex_pc;
  reg  [31:0] ex_ret;
  reg  [ 4:0] ex_opcode;
  reg  [ 2:0] ex_funct3;
  reg  [ 6:0] ex_funct7;
  reg  [ 4:0] ex_rs1;
  reg         ex_alu_pc;
  reg         ex_alu_imm;
  reg         ex_alu_en;
  reg         ex_ma_wr;
  reg         ex_ma_rd;
  reg  [ 1:0] ex_wb_mux;
  reg  [ 4:0] ex_wb_reg;
  reg         ex_wb_en;
  reg         ex_system;

  always @(posedge i_clk) begin
    if (i_rst || (clk_ce && (hz_br || hz_data || br_en))) begin
      ex_rs1_d    <= 0;
      ex_rs2_d    <= 0;
      ex_imm      <= 0;
      ex_pc       <= 0;
      ex_ret      <= 0;
      ex_opcode   <= 0;
      ex_funct3   <= 0;
      ex_funct7   <= 0;
      ex_rs1      <= 0;
      ex_alu_pc   <= 0;
      ex_alu_imm  <= 0;
      ex_alu_en   <= 0;
      ex_ma_wr    <= 0;
      ex_ma_rd    <= 0;
      ex_wb_reg   <= 0;
      ex_wb_mux   <= 0;
      ex_wb_en    <= 0;
      ex_system   <= 0;
    end else if (clk_ce) begin
      ex_rs1_d    <= rs1_d;
      ex_rs2_d    <= rs2_d;
      ex_imm      <= immediate;
      ex_pc       <= id_pc;
      ex_ret      <= id_ret;
      ex_opcode   <= opcode;
      ex_funct3   <= funct3;
      ex_funct7   <= funct7;
      ex_rs1      <= rs1;
      ex_alu_pc   <= alu_pc;
      ex_alu_imm  <= alu_imm;
      ex_alu_en   <= alu_en;
      ex_ma_wr    <= d_wr;
      ex_ma_rd    <= d_rd;
      ex_wb_reg   <= rd;
      ex_wb_mux   <= wb_mux;
      ex_wb_en    <= wb_en;
      ex_system   <= system;
    end
  end

  /**
   * Branch Conditioner
   */
  wire br_en;

  branch branch_i (
    .i_dat_a  (ex_rs1_d),
    .i_dat_b  (ex_rs2_d),
    .i_funct3 (ex_funct3),
    .i_opcode (ex_opcode),
    .o_br_en  (br_en)
  );

  /**
   * Arythmetic and Logic Unit
   */
  wire [31:0] alu_out;
  wire        alu_busy;

  alu alu_i (
    .i_clk_n   (clk_n),
    .i_rst     (i_rst),
    .i_in_a    (alu_a_mux),
    .i_in_b    (alu_b_mux),
    .i_funct3  (ex_funct3),
    .i_funct7  (ex_funct7),
    .i_alu_en  (ex_alu_en),
    .i_alu_imm (ex_alu_imm),
    .o_busy    (alu_busy),
    .o_alu_out (alu_out)
  );

  wire [31:0] alu_a_mux = (ex_alu_pc)  ? ex_pc  : ex_rs1_d;
  wire [31:0] alu_b_mux = (ex_alu_imm) ? ex_imm : ex_rs2_d;

  /**
   * Control and Status Registers
   */
`ifdef INCLUDE_CSR
  wire [31:0] csr_rd_data;

  csr csr_i (
    .i_clk     (i_clk),
    .i_rd      (csr_rd),
    .i_wr      (csr_wr),
    .i_set     (csr_set),
    .i_clr     (csr_clr),
    .i_adr     (ex_imm[11:0]),
    .i_wr_data (csr_wr_data),
    .o_rd_data (csr_rd_data)
  );

  wire [31:0] csr_wr_data = ex_funct3[2] ? {27'h0, ex_rs1} : ex_rs1_d;

  wire csr_wr_en = ex_system && (ex_rs1 != 5'b00000);
  wire csr_rd    = ex_system && (ex_wb_reg != 5'b00000);
  wire csr_wr    = csr_wr_en && (ex_funct3[1:0] == 2'b01);
  wire csr_set   = csr_wr_en && (ex_funct3[1:0] == 2'b10);
  wire csr_clr   = csr_wr_en && (ex_funct3[1:0] == 2'b11);
`endif

  ///////////////////////////////////////////////////////////////////////////
  // MEMORY ACCESS STAGE
  ///////////////////////////////////////////////////////////////////////////

  /**
   * Memory Access Registers
   */
  reg  [31:0] ma_rs2_d;
  reg  [31:0] ma_res;
  reg  [31:0] ma_ret;
  reg  [ 2:0] ma_funct3;
  reg         ma_wr;
  reg         ma_rd;
  reg  [ 4:0] ma_wb_reg;
  reg  [ 1:0] ma_wb_mux;
  reg         ma_wb_en;

  always @(posedge i_clk) begin
    if (i_rst) begin
      ma_rs2_d  <= 0;
      ma_res    <= 0;
      ma_ret    <= 0;
      ma_funct3 <= 0;
      ma_wr     <= 0;
      ma_rd     <= 0;
      ma_wb_reg <= 0;
      ma_wb_mux <= 0;
      ma_wb_en  <= 0;
    end else if (clk_ce) begin
      ma_rs2_d  <= ex_rs2_d;
      ma_res    <= ma_res_dat;
      ma_ret    <= ex_ret;
      ma_funct3 <= ex_funct3;
      ma_wr     <= ex_ma_wr;
      ma_rd     <= ex_ma_rd;
      ma_wb_reg <= ex_wb_reg;
      ma_wb_mux <= ex_wb_mux;
      ma_wb_en  <= ex_wb_en;
    end
  end

`ifdef INCLUDE_CSR
  wire [31:0] ma_res_dat = ex_system ? csr_rd_data : alu_out;
`else
  wire [31:0] ma_res_dat = alu_out;
`endif

  /**
   * Data Memory
   */
  wire [31:0] ma_rd_dat;
  wire [31:0] ma_wr_dat;
  wire [ 3:0] ma_we;

  memory memory_i (
    .i_data_rd   (i_data_in_d),
    .i_data_wr   (ma_rs2_d),
    .i_shift     (ma_res[1:0]),
    .i_length    (ma_funct3[1:0]),
    .i_signed_rd (!ma_funct3[2]),
    .o_data_rd   (ma_rd_dat),
    .o_data_wr   (ma_wr_dat),
    .o_we        (ma_we)
  );

  wire [3:0] ma_wr_en = ma_we & {4{ma_wr}};
  wire       ma_rd_en = ma_rd;

  ///////////////////////////////////////////////////////////////////////////
  // WRITE BACK STAGE
  ///////////////////////////////////////////////////////////////////////////

  /**
   * Write Back Registers
   */
  reg  [31:0] wb_wb_d;
  reg  [ 4:0] wb_wb_reg;
  reg         wb_wb_en;

  always @(posedge i_clk) begin
    if (i_rst) begin
      wb_wb_d   <= 0;
      wb_wb_reg <= 0;
      wb_wb_en  <= 0;
    end else if (clk_ce) begin
      wb_wb_d   <= wb_dat_mux;
      wb_wb_reg <= ma_wb_reg;
      wb_wb_en  <= ma_wb_en;
    end
  end

  wire [31:0] wb_dat_mux = (ma_wb_mux == 2'b10) ? ma_ret :
    (ma_wb_mux == 2'b01) ? ma_rd_dat : ma_res;

  /**
   * Output assignment
   */
  assign o_addr_i = if_pc;
  assign o_rd_d   = ma_rd_en;
  assign o_we_d   = ma_wr_en;

`ifdef CLEAN_DATA
  assign o_addr_d     = (ma_rd_en || |ma_wr_en) ? ma_res    : 0;
  assign o_data_out_d = (ma_rd_en || |ma_wr_en) ? ma_wr_dat : 0;
`else
  assign o_addr_d     = ma_res;
  assign o_data_out_d = ma_wr_dat;
`endif

endmodule
