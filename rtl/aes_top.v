// AES-128 Top-Level Wrapper
module aes_top (
    input  wire          clk,
    input  wire          rst,
    input  wire          start,
    input  wire          mode, // 1'b0: Encrypt, 1'b1: Decrypt
    input  wire [127:0]  data_in,
    input  wire [127:0]  key,
    output wire [127:0]  data_out,
    output wire          done
);
    // Expand the 128-bit key once combinationally; shared by both cores
    wire [1407:0] round_keys;
    key_expansion ke_inst (
        .key       (key),
        .round_keys(round_keys)
    );

    // Encryption Core
    wire [127:0] encrypt_out;
    wire         encrypt_done;
    aes_encrypt enc_inst (
        .clk       (clk),
        .rst       (rst),
        .start     (start && (mode == 1'b0)),
        .plaintext (data_in),
        .round_keys(round_keys),
        .ciphertext(encrypt_out),
        .done      (encrypt_done)
    );

    // Decryption Core
    wire [127:0] decrypt_out;
    wire         decrypt_done;
    aes_decrypt dec_inst (
        .clk       (clk),
        .rst       (rst),
        .start     (start && (mode == 1'b1)),
        .ciphertext(data_in),
        .round_keys(round_keys),
        .plaintext (decrypt_out),
        .done      (decrypt_done)
    );

    // Route outputs based on mode selection
    assign data_out = (mode == 1'b0) ? encrypt_out  : decrypt_out;
    assign done     = (mode == 1'b0) ? encrypt_done : decrypt_done;
endmodule
