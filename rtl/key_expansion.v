// AES-128 Key Expansion Module
module key_expansion (
    input  wire [127:0] key,
    output wire [1407:0] round_keys
);
    wire [31:0] w[0:43];

    // Initial 4 words are the input key itself
    assign w[0] = key[127:96];
    assign w[1] = key[95:64];
    assign w[2] = key[63:32];
    assign w[3] = key[31:0];

    genvar j;
    generate
        for (j = 1; j <= 10; j = j + 1) begin : round_key_gen
            // S-box lookups for RotWord(w[4*j-1])
            // RotWord(w[4*j-1]) is:
            //   byte 0: w[4*j-1][23:16]
            //   byte 1: w[4*j-1][15:8]
            //   byte 2: w[4*j-1][7:0]
            //   byte 3: w[4*j-1][31:24]
            wire [7:0] sb_out0;
            wire [7:0] sb_out1;
            wire [7:0] sb_out2;
            wire [7:0] sb_out3;

            sbox sb0 (.in(w[4*j-1][23:16]), .out(sb_out0));
            sbox sb1 (.in(w[4*j-1][15:8]),  .out(sb_out1));
            sbox sb2 (.in(w[4*j-1][7:0]),   .out(sb_out2));
            sbox sb3 (.in(w[4*j-1][31:24]), .out(sb_out3));

            // Rcon value for round j
            wire [7:0] rc = (j == 1)  ? 8'h01 :
                            (j == 2)  ? 8'h02 :
                            (j == 3)  ? 8'h04 :
                            (j == 4)  ? 8'h08 :
                            (j == 5)  ? 8'h10 :
                            (j == 6)  ? 8'h20 :
                            (j == 7)  ? 8'h40 :
                            (j == 8)  ? 8'h80 :
                            (j == 9)  ? 8'h1b :
                            (j == 10) ? 8'h36 : 8'h00;

            wire [31:0] temp = {sb_out0 ^ rc, sb_out1, sb_out2, sb_out3};

            assign w[4*j]   = w[4*j-4] ^ temp;
            assign w[4*j+1] = w[4*j-3] ^ w[4*j];
            assign w[4*j+2] = w[4*j-2] ^ w[4*j+1];
            assign w[4*j+3] = w[4*j-1] ^ w[4*j+2];
        end
    endgenerate

    // Pack the 44 words into the output 1408-bit bus
    genvar r;
    generate
        for (r = 0; r <= 10; r = r + 1) begin : key_slice_assign
            assign round_keys[128*r + 127 : 128*r] = {w[4*r], w[4*r+1], w[4*r+2], w[4*r+3]};
        end
    endgenerate
endmodule
