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
  // Program counter and branch hazard
  ///////////////////////////////////////////////////////////////////////////
  reg        hz_br;
  reg [31:0] if_pc;

  always @(posedge i_clk) begin
    if (i_rst) begin
      // Clear on reset
      if_pc <= 32'h0;
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

endmodule
