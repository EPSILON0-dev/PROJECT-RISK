module fetch (
  input         i_clk,
  input         i_clk_ce,
  input         i_rst,
  input  [31:0] i_data_in,

  input         i_hz_data,
  input         i_br_en,
  input  [31:0] i_br_addr,


  output [31:0] o_if_pc,
  output [31:0] o_id_pc,
  output [31:0] o_id_ret,
  output [31:0] o_id_ir,

  output        o_hz_br
);

  ///////////////////////////////////////////////////////////////////////////
  // C extension fetch unit
  //  This version supports both 16bit and 32bit opcodes, 32bit opcodes
  //  don't have to be aligned to 4-byte boundries.
  ///////////////////////////////////////////////////////////////////////////
`ifdef C_EXTENSION
  /**
   * Program counter and branch hazard
   */
  reg [31:0] if_pc;
  always @(posedge i_clk) begin
    if (i_rst) begin
      // Clear on reset
      if_pc <= 0;
    end else begin
      // Update if pc should be updated
      if (i_clk_ce && (!i_hz_data || i_br_en)) begin
        if_pc <= pc_mux;
      end
    end
  end

  // If branching pc input should be branch address
  wire [31:0] pc_mux = (i_br_en)? i_br_addr : pc_next;

  // This timing signals makes next expressions a bit clearer
  wire [31:0] pc_t0 = if_pc;
  wire [31:0] data_t0 = i_data_in;

  // These signals determine if instructions from memory are compressed
  wire data_t0_cl = (data_t0[1:0] != 2'b11);
  wire data_t0_ch = (data_t0[17:16] != 2'b11);

  // This signal tells if pc should advance by half or full instruction
  wire pc_next_c = (data_t0_cl && !pc_t0[1]) || (pc_t0[1] && data_t0_ch);
  wire [31:0] pc_next = pc_t0 + ((pc_next_c) ? 32'h2 : 32'h4);

  /**
   * Data registers
   *  These registers can work in two modes: t1 mode and t2 mode.
   *  After branch or reset fetch unit enters t1 mode in which opcode passes
   *  through only one register before going to ir output, in this mode it's
   *  impossible to read unaligned 32bit opcodes. To read 32bit opcodes fetch
   *  unit enters t2 mode (it's automatically detected with unaligned_32
   *  signal), in this mode fetch unit has access to the current word and the
   *  next one so that unaligned opcodes can be read. To save a few cycles
   *  fetch unit doesn't enter t1 mode until branch or reset occurs.
   */
  reg [31:0] data_t1;
  reg [31:0] data_t2;
  reg [31:0] pc_t1;
  reg [31:0] pc_t2;
  reg [31:0] ret_t1;
  reg [31:0] ret_t2;
  reg valid_t1;
  reg valid_t2;
  reg t2_mode;
  always @(posedge i_clk) begin
    if (i_rst) begin
      data_t1  <= 0;
      data_t2  <= 0;
      valid_t1 <= 0;
      valid_t2 <= 0;
      pc_t1    <= 0;
      pc_t2    <= 0;
      ret_t1   <= 0;
      ret_t2   <= 0;
      t2_mode  <= 0;
    end else begin
      if (i_clk_ce && (!i_hz_data || i_br_en)) begin
        data_t1  <= data_t0;
        data_t2  <= data_t1;
        valid_t1 <= 1'b1;
        valid_t2 <= valid_t1;
        pc_t1    <= pc_t0;
        pc_t2    <= pc_t1;
        ret_t1   <= pc_next;
        ret_t2   <= ret_t1;
        t2_mode  <= t2_en || t2_mode;
      end
    end
    if (i_clk_ce && i_br_en) begin
      data_t1  <= 0;
      data_t2  <= 0;
      valid_t1 <= 0;
      valid_t2 <= 0;
    end
  end

  // This signal tells the fetch unit to switch to t2 mode
  //  If C_FETCH_T2 is defined fetch unit will automatically enter t2 mode
  //  no matter what opcode it receives.
`ifdef C_FETCH_T2
  wire t2_en = 1;
`else
  wire t2_en = pc_t1[1] && !c_data_t1_1;

  // This signal determines if unaligned instructions in t1 is compressed
  wire c_data_t1_1 = (data_t1[17:16] != 2'b11);
`endif

  // These signals are the multiplexers that align the unaligned opcodes
  wire [31:0] data_o_t1 = (pc_t1[1])? { 16'h0000, data_t1[31:16] } : data_t1;
  wire [31:0] data_o_t2 = (pc_t2[1])? { data_t1[15:0], data_t2[31:16] } : data_t2;

  // This signals tell if opcodes are already valid or if the cpu should wait
  wire valid_o_t1 = valid_t1 && !t2_en;
  wire valid_o_t2 = valid_t2;

  // These are output multiplexers that switch between t2 and t1 registers
  wire [31:0] data_out = (t2_mode)? data_o_t2 : data_o_t1;
  wire [31:0] pc_out = (t2_mode)? pc_t2 : pc_t1;
  wire [31:0] ret_out = (t2_mode)? ret_t2 : ret_t1;
  wire valid_out = (t2_mode)? valid_o_t2 : valid_o_t1;

  /**
   * Output assignments
   */
  assign o_if_pc  = if_pc;
  assign o_id_pc  = pc_out;
  assign o_id_ir  = data_out;
  assign o_id_ret = ret_out;

  assign o_hz_br = !valid_out;

  ///////////////////////////////////////////////////////////////////////////
  // Base I fetch unit
  //  This version only supports both 32bit opcodes which have to be aligned
  //  to 4-byte boundries.
  ///////////////////////////////////////////////////////////////////////////
`else
  /**
   * Program counter and branch hazard
   */
  reg        hz_br;
  reg [31:0] if_pc;

  always @(posedge i_clk) begin
    if (i_rst) begin
      // Clear on reset
      if_pc <= 0;
      hz_br <= 0;
    end else begin
      // Clear branch hazard if set
      if (i_clk_ce && hz_br) begin
        hz_br <= 0;
      end
      // Update the pc
      if (i_clk_ce && (!i_hz_data || i_br_en)) begin
        if_pc <= pc_mux;
        // Set hazard if branch taken
        if (i_br_en) begin
          hz_br <= 1'b1;
        end
      end
    end
  end

  wire [31:0] pc_next = if_pc + 32'h4;
  wire [31:0] pc_mux = (i_br_en) ? i_br_addr : pc_next;


  /**
   * Instruction Decode Registers
   *  These registers are as simple as it gets, they just take the current
   *  address, return address and the instruction from memory and keep them
   *  in register for the cpu to read
   */
  reg [31:0] id_ret;
  reg [31:0] id_pc;
  reg [31:0] id_ir;

  always @(posedge i_clk) begin
    if (i_rst) begin
      id_ret <= 0;
      id_pc  <= 0;
      id_ir  <= 0;
    end else if (i_clk_ce && !i_hz_data) begin
      id_ret <= pc_next;
      id_pc  <= if_pc;
      id_ir  <= i_data_in;
    end
    if (i_clk_ce && i_br_en) begin
      id_ir <= 0;
    end
  end


  /**
   * Output assignments
   */
  assign o_if_pc  = if_pc;
  assign o_id_pc  = id_pc;
  assign o_id_ir  = id_ir;
  assign o_id_ret = id_ret;

  assign o_hz_br = hz_br;
`endif

endmodule