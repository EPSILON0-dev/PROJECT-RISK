/****************************************************************************
 * Copyright 2023 Lukasz Forenc
 *
 * File: boot_rom.v
 *
 * This file contains the ROM containing the bootloader, the "INIT"
 * statements are generated were generated bu the python script in
 * "software/bootloader/mem.py". This is a single 18Kb BRAM, it cannot be
 * 9Kb because using 9Kb ROMs lead to undefined behavior.
 *
 * i_clk  - Clock input
 * i_addr - Read address
 *
 * o_data - Read data
 ***************************************************************************/

module boot_rom (
  input         i_clk,
  input   [8:0] i_addr,
  output [31:0] o_data
);

  // Memory block
  // verilator lint_off PINCONNECTEMPTY
  RAMB16BWER #(
    .SIM_DEVICE     ("SPARTAN6"),
    .INIT_A         (36'h000000000),
    .INIT_B         (36'h000000000),
    .INIT_FILE      ("NONE"),
    .RST_PRIORITY_A ("CE"),
    .RST_PRIORITY_B ("CE"),
    .DATA_WIDTH_A   (36),
    .DATA_WIDTH_B   (36),
    .DOA_REG        (0),
    .DOB_REG        (0),
    .EN_RSTRAM_A    ("FALSE"),
    .EN_RSTRAM_B    ("FALSE"),
    .WRITE_MODE_A   ("NO_CHANGE"),
    .WRITE_MODE_B   ("NO_CHANGE"),
    .INIT_00        (256'h00312223043001930031202303600193100194631001F1930101218300008137),
    .INIT_01        (256'hFFF28293FE019EE3FFF18193000801B7004128230012421300F0029300000213),
    .INIT_02        (256'hFFF1819308018663FFF1819306018463FD0181930EC000EF00100493FE0294E3),
    .INIT_03        (256'h0650019308018E63FFF1819300018C63FFF1819306018863FFF1819304018663),
    .INIT_04        (256'hFE41CCE3004181930051A02306F002930000823700000193FC1FF06F00312623),
    .INIT_05        (256'h0FC000EF0040031300038493108000EF00400313F9DFF06F0031262306300193),
    .INIT_06        (256'h0DC000EF00400313F71FF06FFE0498E3FFF48493001383930D4000EF0003C183),
    .INIT_07        (256'h06B00193007400230C4000EF00200313000384130D0000EF0040031300038493),
    .INIT_08        (256'h000001930031262307300193F35FF06FFE0494E3FFF484930014041300312623),
    .INIT_09        (256'hFE019CE30201F1930081218300000067FFC1011300008137000100B700312823),
    .INIT_0A        (256'h0041C463FF918193010002130041CA63FD01819300A002130000806700C12183),
    .INIT_0B        (256'h007181930032D4630301819300F1F193000182130390029300008067FE018193),
    .INIT_0C        (256'h004272130081220300008067007202130042D4630302021300F2721300425213),
    .INIT_0D        (256'h0000039300008293000300670031262300412623FC1FF0EF00008313FE020CE3),
    .INIT_0E        (256'h0000000000028067FE0316E3FFF30313003383B3F81FF0EFF71FF0EF00439393),
    .INIT_0F        (256'h0000000000000000000000000000000000000000000000000000000000000000)
  ) boot_rom_bram (
    .DIA            (32'h00000000),
    .DOA            (o_data),
    .ADDRA          ({i_addr, 5'b00000}),
    .CLKA           (i_clk),
    .ENA            (1'b1),
    .REGCEA         (1'b1),
    .RSTA           (1'b0),
    .WEA            (4'b0000),
    .DIB            (32'h00000000),
    .DOB            (),
    .ADDRB          (14'h0000),
    .CLKB           (1'b0),
    .ENB            (1'b0),
    .REGCEB         (1'b0),
    .RSTB           (1'b0),
    .WEB            (4'b0000)
  );

endmodule
