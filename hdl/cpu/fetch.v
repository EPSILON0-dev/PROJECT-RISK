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

`ifdef C_EXTENSION
  ///////////////////////////////////////////////////////////////////////////
  // Program counter and branch hazard
  ///////////////////////////////////////////////////////////////////////////
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

  ///////////////////////////////////////////////////////////////////////////
  // Data registers
  ///////////////////////////////////////////////////////////////////////////
  reg [31:0] data_t1;
  reg [31:0] data_t2;
  reg [31:0] pc_t1;
  reg [31:0] pc_t2;
  reg [31:0] ret_t1;
  reg [31:0] ret_t2;
  reg valid_t1;
  reg valid_t2;
  reg t2_en;
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
      t2_en    <= 0;
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
        t2_en    <= unaligned_n || t2_en;
      end
    end
    if (i_clk_ce && i_br_en) begin
      data_t1  <= 0;
      data_t2  <= 0;
      valid_t1 <= 0;
      valid_t2 <= 0;
    end
  end
  wire unaligned_n = pc_t1[1] && !c_data_t1_1;

  wire c_data_t1_1 = (data_t1[17:16] != 2'b11);

  wire [31:0] data_o_t1 = (pc_t1[1])? { 16'h0000, data_t1[31:16] } : data_t1;
  wire valid_o_t1 = valid_t1 && !unaligned_n;

  wire [31:0] data_o_t2 = (pc_t2[1])? { data_t1[15:0], data_t2[31:16] } : data_t2;
  wire valid_o_t2 = valid_t2;

  wire [31:0] data_out = (t2_en)? data_o_t2 : data_o_t1;
  wire [31:0] pc_out = (t2_en)? pc_t2 : pc_t1;
  wire [31:0] ret_out = (t2_en)? ret_t2 : ret_t1;
  wire valid_out = (t2_en)? valid_o_t2 : valid_o_t1;

  ///////////////////////////////////////////////////////////////////////////
  // Output assignments
  ///////////////////////////////////////////////////////////////////////////
  assign o_if_pc  = if_pc;
  assign o_id_pc  = pc_out;
  assign o_id_ir  = data_out;
  assign o_id_ret = ret_out;

  assign o_hz_br = !valid_out;

`else
  ///////////////////////////////////////////////////////////////////////////
  // Program counter and branch hazard
  ///////////////////////////////////////////////////////////////////////////
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


  ///////////////////////////////////////////////////////////////////////////
  // Instruction Decode Registers
  ///////////////////////////////////////////////////////////////////////////
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


  ///////////////////////////////////////////////////////////////////////////
  // Output assignments
  ///////////////////////////////////////////////////////////////////////////
  assign o_if_pc  = if_pc;
  assign o_id_pc  = id_pc;
  assign o_id_ir  = id_ir;
  assign o_id_ret = id_ret;

  assign o_hz_br = hz_br;
`endif

endmodule
