// AES-128 Encryption Core (Iterative)
module aes_encrypt (
    input  wire          clk,
    input  wire          rst,
    input  wire          start,
    input  wire [127:0]  plaintext,
    input  wire [1407:0] round_keys,
    output reg  [127:0]  ciphertext,
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
    wire [127:0] sub_out;
    wire [127:0] shift_out;
    wire [127:0] mix_out;

    // Instantiate transformation blocks
    sub_bytes sb_inst (
        .in (state_data),
        .out(sub_out)
    );

    shift_rows sr_inst (
        .in (sub_out),
        .out(shift_out)
    );

    mix_columns mc_inst (
        .in (shift_out),
        .out(mix_out)
    );

    // Dynamic round key selection
    wire [127:0] round_key = round_keys[128 * round_ctr +: 128];

    // Compute next states combinationally
    wire [127:0] round_state_next = mix_out ^ round_key;
    wire [127:0] final_state_next = shift_out ^ round_key;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state_reg  <= STATE_IDLE;
            state_data <= 128'h0;
            round_ctr  <= 4'd0;
            ciphertext <= 128'h0;
            done       <= 1'b0;
        end else begin
            case (state_reg)
                STATE_IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        state_data <= plaintext ^ round_keys[127:0]; // Round 0 AddRoundKey
                        round_ctr  <= 4'd1;
                        state_reg  <= STATE_ROUNDS;
                    end
                end

                STATE_ROUNDS: begin
                    state_data <= round_state_next;
                    if (round_ctr == 4'd9) begin
                        round_ctr <= 4'd10;
                        state_reg <= STATE_FINAL;
                    end else begin
                        round_ctr <= round_ctr + 4'd1;
                    end
                end

                STATE_FINAL: begin
                    ciphertext <= final_state_next;
                    done       <= 1'b1;
                    state_reg  <= STATE_DONE;
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
