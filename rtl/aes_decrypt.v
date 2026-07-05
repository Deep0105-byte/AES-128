// AES-128 Decryption Core (Iterative)
module aes_decrypt (
    input  wire          clk,
    input  wire          rst,
    input  wire          start,
    input  wire [127:0]  ciphertext,
    input  wire [1407:0] round_keys,
    output reg  [127:0]  plaintext,
    output reg           done
);
    localparam [1:0] STATE_IDLE   = 2'b00;
    localparam [1:0] STATE_ROUNDS = 2'b01;
    localparam [1:0] STATE_FINAL  = 2'b10;
    localparam [1:0] STATE_DONE   = 2'b11;

    reg [1:0]   state_reg;
    reg [127:0] state_data;
    reg [3:0]   round_ctr;

    // Intermediate state signals
    wire [127:0] inv_shift_out;
    wire [127:0] inv_sub_out;
    wire [127:0] inv_mix_out;

    // Instantiate transformation blocks
    inv_shift_rows isr_inst (
        .in (state_data),
        .out(inv_shift_out)
    );

    inv_sub_bytes isb_inst (
        .in (inv_shift_out),
        .out(inv_sub_out)
    );

    // Dynamic round key selection
    wire [127:0] round_key = round_keys[128 * round_ctr +: 128];

    // AddRoundKey is a simple XOR on the output of SubBytes/InvSubBytes
    wire [127:0] add_key_out = inv_sub_out ^ round_key;

    // Inverse MixColumns operates on the AddRoundKey output
    inv_mix_columns imc_inst (
        .in (add_key_out),
        .out(inv_mix_out)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state_reg  <= STATE_IDLE;
            state_data <= 128'h0;
            round_ctr  <= 4'd0;
            plaintext  <= 128'h0;
            done       <= 1'b0;
        end else begin
            case (state_reg)
                STATE_IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        state_data <= ciphertext ^ round_keys[1280 +: 128]; // Round 10 AddRoundKey (last key)
                        round_ctr  <= 4'd9;
                        state_reg  <= STATE_ROUNDS;
                    end
                end

                STATE_ROUNDS: begin
                    state_data <= inv_mix_out;
                    if (round_ctr == 4'd1) begin
                        round_ctr <= 4'd0;
                        state_reg <= STATE_FINAL;
                    end else begin
                        round_ctr <= round_ctr - 4'd1;
                    end
                end

                STATE_FINAL: begin
                    plaintext <= add_key_out; // Final Round 0: no InvMixColumns
                    done      <= 1'b1;
                    state_reg <= STATE_DONE;
                end

                STATE_DONE: begin
                    if (!start) begin
                        done      <= 1'b0;
                        state_reg <= STATE_IDLE;
                    end
                end

                default: state_reg <= STATE_IDLE;
            endcase
        end
    end
endmodule
