// AES Inverse SubBytes Module
module inv_sub_bytes (
    input  wire [127:0] in,
    output wire [127:0] out
);
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : inv_sbox_gen
            inv_sbox sb_inv (
                .in (in [128 - 8*i - 1 : 128 - 8*i - 8]),
                .out(out[128 - 8*i - 1 : 128 - 8*i - 8])
            );
        end
    endgenerate
endmodule
