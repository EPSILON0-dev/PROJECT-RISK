module memory (
    input  [31:0] i_data_rd,
    input  [31:0] i_data_wr,
    input  [ 1:0] i_shift,
    input  [ 1:0] i_length,
    input         i_signed_rd,
    output [31:0] o_data_rd,
    output [31:0] o_data_wr,
    output  [3:0] o_we);



    /////////////////////////////////////////////////////////////////////////
    // Length mask
    /////////////////////////////////////////////////////////////////////////
    reg [31:0] length_mask;

    always @* begin
        case (i_length)
            2'b00:   length_mask = 32'h000000ff;
            2'b01:   length_mask = 32'h0000ffff;
            2'b10:   length_mask = 32'hffffffff;
            default: length_mask = 32'h00000000;
        endcase
    end



    /////////////////////////////////////////////////////////////////////////
    // Write data processing
    /////////////////////////////////////////////////////////////////////////
    // Write data is processed in two stages:
    //  Stage 1: Data is length masked
    //  Stage 2: Data is shifted to the given byte offset
    wire [31:0] data_wr_s;
    reg  [31:0] data_wr_shift;

    assign data_wr_s = i_data_wr & length_mask;

    always @* begin
        case (i_shift)
            2'b01:   data_wr_shift = { data_wr_s[23:0], data_wr_s[31:24] };
            2'b10:   data_wr_shift = { data_wr_s[15:0], data_wr_s[31:16] };
            2'b11:   data_wr_shift = { data_wr_s[ 7:0], data_wr_s[31:8 ] };
            default: data_wr_shift = data_wr_s;
        endcase
    end



    /////////////////////////////////////////////////////////////////////////
    // Read data processing
    /////////////////////////////////////////////////////////////////////////
    // Write data is processed in three stages:
    //  Stage 1: Data is shifted to the given byte offset
    //  Stage 2: Data is length masked
    //  Stage 3: Inverted length mask is used to sign extend the value
    reg  [31:0] data_rd_shift;
    wire [31:0] data_rd_short;
    wire [31:0] sign_extension;
    wire [31:0] data_rd_signed;
    wire        sign_bit;

    always @* begin
        case (i_shift)
            2'b01:   data_rd_shift = { i_data_rd[ 7:0], i_data_rd[31:8 ] };
            2'b10:   data_rd_shift = { i_data_rd[15:0], i_data_rd[31:16] };
            2'b11:   data_rd_shift = { i_data_rd[23:0], i_data_rd[31:24] };
            default: data_rd_shift = i_data_rd;
        endcase
    end

    assign data_rd_short = data_rd_shift & length_mask;

    assign sign_bit = (i_length[0])? data_rd_shift[15] : data_rd_shift[7];
    assign sign_extension = (sign_bit && i_signed_rd) ? ~length_mask : 0;
    assign data_rd_signed = data_rd_short | sign_extension;



    /////////////////////////////////////////////////////////////////////////
    // Write enable generation
    /////////////////////////////////////////////////////////////////////////
    // Write data is processed in three stages:
    //  Stage 1: Length is calculated
    //  Stage 2: Length is offset by the address
    reg  [3:0] we_lenght;
    reg  [3:0] we_shifted;

    always @* begin
        case (i_length)
            2'b00:   we_lenght = 4'b0001;
            2'b01:   we_lenght = 4'b0011;
            2'b10:   we_lenght = 4'b1111;
            default: we_lenght = 4'b0000;
        endcase
    end

    always @* begin
        case (i_shift)
            2'b01:   we_shifted = { we_lenght[2:0], 1'b0 };
            2'b10:   we_shifted = { we_lenght[1:0], 2'b00 };
            2'b11:   we_shifted = { we_lenght[  0], 3'b000 };
            default: we_shifted = we_lenght;
        endcase
    end



    /////////////////////////////////////////////////////////////////////////
    // Output assignment
    /////////////////////////////////////////////////////////////////////////
    assign o_data_wr = data_wr_shift;
    assign o_data_rd = data_rd_signed;
    assign o_we      = we_shifted;


endmodule
