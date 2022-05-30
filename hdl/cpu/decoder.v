module decoder (
    input  [31:0] i_opcode_in,
    output [31:0] o_immediate,
    output [ 4:0] o_opcode,
    output [ 2:0] o_funct3,
    output [ 6:0] o_funct7,
    output [ 4:0] o_rsa,
    output [ 4:0] o_rsb,
    output [ 4:0] o_rd,
    output        o_hz_rsa,
    output        o_hz_rsb,
    output        o_alu_pc,
    output        o_alu_imm,
    output        o_alu_en,
    output        o_ma_wr,
    output        o_ma_rd,
    output [ 1:0] o_wb_mux,
    output        o_wb_en);


    /////////////////////////////////////////////////////////////////////////
    // Opcode bit extraction
    /////////////////////////////////////////////////////////////////////////
    wire [4:0] opcode;
    wire [4:0] rsa;
    wire [4:0] rsb;
    wire [4:0] rd;
    wire [2:0] funct3;
    wire [6:0] funct7;

    assign opcode = i_opcode_in[6:2];
    assign rsa = i_opcode_in[19:15] & {5{!op_lui}};
    assign rsb = i_opcode_in[24:20];
    assign rd = i_opcode_in[11:7];
    assign funct3 = i_opcode_in[14:12];
    assign funct7 = i_opcode_in[31:25];


    /////////////////////////////////////////////////////////////////////////
    // Operation decoding
    /////////////////////////////////////////////////////////////////////////
    wire op_load;
    wire op_op_imm;
    wire op_auipc;
    wire op_store;
    wire op_op;
    wire op_lui;
    wire op_branch;
    wire op_jalr;
    wire op_jal;

    assign op_load   = (opcode == 5'b00000);
    assign op_op_imm = (opcode == 5'b00100);
    assign op_auipc  = (opcode == 5'b00101);
    assign op_store  = (opcode == 5'b01000);
    assign op_op     = (opcode == 5'b01100);
    assign op_lui    = (opcode == 5'b01101);
    assign op_branch = (opcode == 5'b11000);
    assign op_jalr   = (opcode == 5'b11001);
    assign op_jal    = (opcode == 5'b11011);


    /////////////////////////////////////////////////////////////////////////
    // Format decoding
    /////////////////////////////////////////////////////////////////////////
    wire format_u;
    wire format_j;
    wire format_b;
    wire format_i;
    wire format_s;
    wire format_r;

    assign format_u = op_auipc || op_lui;
    assign format_j = op_jal;
    assign format_b = op_branch;
    assign format_i = op_load || op_op_imm || op_jalr;
    assign format_s = op_store;
    assign format_r = op_op;


    /////////////////////////////////////////////////////////////////////////
    // Opcode validation
    /////////////////////////////////////////////////////////////////////////
    wire opcode_valid;

    assign opcode_valid = (i_opcode_in[1:0] == 2'b11) && (
        format_u ||
        format_j ||
        format_b ||
        format_i ||
        format_s ||
        format_r
    );


    /////////////////////////////////////////////////////////////////////////
    // Immediate decoding
    /////////////////////////////////////////////////////////////////////////
    wire [31:0] immediate_mux;
    wire [31:0] immediate_u;
    wire [31:0] immediate_j;
    wire [31:0] immediate_b;
    wire [31:0] immediate_i;
    wire [31:0] immediate_s;

    // Upper immediate
    assign immediate_u = {
        i_opcode_in[31:12],
        12'h000
    };

    // Jump immediate
    assign immediate_j = {
        {12{i_opcode_in[31]}},
        i_opcode_in[19:12],
        i_opcode_in[20],
        i_opcode_in[30:21],
        1'b0
    };

    // Branch immediate
    assign immediate_b = {
        {20{i_opcode_in[31]}},
        i_opcode_in[7],
        i_opcode_in[30:25],
        i_opcode_in[11:8],
        1'b0
    };

    // Store immediate
    assign immediate_s = {
        {21{i_opcode_in[31]}},
        i_opcode_in[30:25],
        i_opcode_in[11:7]
    };

    // Normal immediate
    assign immediate_i = {
        {21{i_opcode_in[31]}},
        i_opcode_in[30:20]
    };

    // Immediate multiplexer
    assign immediate_mux =
        (format_u)? immediate_u :
        (format_j)? immediate_j :
        (format_b)? immediate_b :
        (format_i)? immediate_i :
        (format_s)? immediate_s :
        32'h00000000;


    /////////////////////////////////////////////////////////////////////////
    // Internal CPU signals
    /////////////////////////////////////////////////////////////////////////
    wire       alu_pc;
    wire       alu_imm;
    wire       alu_en;
    wire       ma_wr;
    wire       ma_rd;
    wire [1:0] wb_mux;
    wire       wb_en;
    wire       hz_rsa;
    wire       hz_rsb;

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
    assign wb_mux[1] = op_jal || op_jalr;
    assign wb_mux[0] = op_load;

    // These are pretty selfexplenatory
    assign ma_wr = op_store && opcode_valid;
    assign ma_rd = op_load && opcode_valid;

    // Only stores and branches don't write back any data.
    // This changes future states of the cpu so we need to make sure that
    //  the opcode is valid.
    assign wb_en = !(op_store || op_branch) && opcode_valid;

    // Only LUI, AUIPC and JAL don't use RSA so they don't generate hazard
    assign hz_rsa = !(op_lui || op_auipc || op_jal);
    // Only branches, stores and normal ops use RSB so they generate hazard
    assign hz_rsb = op_branch || op_store || op_op;


    /////////////////////////////////////////////////////////////////////////
    // Output assignments
    /////////////////////////////////////////////////////////////////////////
    assign o_immediate    = immediate_mux;
    assign o_opcode       = opcode;
    assign o_funct3       = funct3;
    assign o_funct7       = funct7;
    assign o_rsa          = rsa;
    assign o_rsb          = rsb;
    assign o_rd           = rd;
    assign o_hz_rsa       = hz_rsa;
    assign o_hz_rsb       = hz_rsb;
    assign o_alu_pc       = alu_pc;
    assign o_alu_imm      = alu_imm;
    assign o_alu_en       = alu_en;
    assign o_ma_wr        = ma_wr;
    assign o_ma_rd        = ma_rd;
    assign o_wb_mux       = wb_mux;
    assign o_wb_en        = wb_en;


endmodule
