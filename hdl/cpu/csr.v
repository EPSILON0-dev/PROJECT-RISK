module csr (
  input         i_clk,

  // verilator lint_off unused
  input         i_rd,
  // verilator lint_on unused
  input         i_wr,
  input         i_set,
  input         i_clr,

`ifdef CSR_EXTERNAL_BUS
  output [11:0] o_ext_addr,
  input  [31:0] i_ext_rd_data,
  output [31:0] o_ext_wr_data,
  output        o_ext_wr,
  output        o_ext_rd,
`endif

  input  [11:0] i_addr,
  input  [31:0] i_wr_data,
  output [31:0] o_rd_data
);


  /**
   * Temporary registers for testing
   */
  reg [31:0] reg_200;
  reg [31:0] reg_800;
  reg [31:0] reg_F00;

  initial begin
    reg_200 = 0;
    reg_800 = 0;
    reg_F00 = 0;
  end


  /**
   * Read from currently selected CSR
   */
  reg  [31:0] read_data;

  always @* begin
    case (i_addr)
      12'h200: read_data = reg_200;
      12'h800: read_data = reg_800;
      12'hF00: read_data = reg_F00;
`ifdef CSR_EXTERNAL_BUS
      default: read_data = i_ext_rd_data;
`else
      default: read_data = 0;
`endif
    endcase
  end


  /**
   * Generate the write data
   */
  wire write_enable = i_wr | i_set | i_clr;

  wire [31:0] set_data = read_data |  i_wr_data;
  wire [31:0] clr_data = read_data & ~i_wr_data;

  wire [31:0] write_data = (i_wr) ? i_wr_data :
    (i_set) ? set_data :
    (i_clr) ? clr_data : 0;


  /**
   * Write to the selected register
   */
  always @(posedge i_clk) begin
    if (write_enable) begin
      case (i_addr)
        12'h200: reg_200 <= write_data;
        12'h800: reg_800 <= write_data;
        12'hF00: reg_F00 <= write_data;
        default: begin end  // Empty expression
      endcase
    end
  end


  /**
   * Output assignment
   */
  assign o_rd_data = read_data;

`ifdef CSR_EXTERNAL_BUS
  assign o_ext_addr    = i_addr;
  assign o_ext_wr_data = write_data;
  assign o_ext_wr      = i_wr;
  assign o_ext_rd      = i_rd;
`endif


endmodule
