`timescale 1ns / 1ps

// AES-128 Testbench
module tb_aes;
    reg          clk;
    reg          rst;
    reg          start;
    reg          mode;
    reg  [127:0] data_in;
    reg  [127:0] key;
    wire [127:0] data_out;
    wire         done;

    // Instantiate Top-Level Wrapper
    aes_top uut (
        .clk     (clk),
        .rst     (rst),
        .start   (start),
        .mode    (mode),
        .data_in (data_in),
        .key     (key),
        .data_out(data_out),
        .done    (done)
    );

    // Clock Generation (100MHz)
    always #5 clk = ~clk;

    // Expected values
    reg [127:0] expected_ciphertext = 128'h69c4e0d86a7b0430d8cdb78070b4c55a;
    reg [127:0] expected_plaintext  = 128'h00112233445566778899aabbccddeeff;
    reg [127:0] key_vector          = 128'h000102030405060708090a0b0c0d0e0f;
    reg [127:0] temp_ciphertext;
    
    integer enc_passed = 0;
    integer dec_passed = 0;

    // Hierarchical logging of round states for easy debugging
    always @(posedge clk) begin
        // If Encryption is active (STATE_ROUNDS = 2'b01, STATE_FINAL = 2'b10)
        if (uut.enc_inst.state_reg == 2'b01 || uut.enc_inst.state_reg == 2'b10) begin
            $display("[SIM-ENC] Round %0d Current State: %h  (Key: %h)", 
                     uut.enc_inst.round_ctr, uut.enc_inst.state_data, uut.enc_inst.round_key);
        end
        // If Decryption is active (STATE_ROUNDS = 2'b01, STATE_FINAL = 2'b10)
        if (uut.dec_inst.state_reg == 2'b01 || uut.dec_inst.state_reg == 2'b10) begin
            $display("[SIM-DEC] Round %0d Current State: %h  (Key: %h)", 
                     uut.dec_inst.round_ctr, uut.dec_inst.state_data, uut.dec_inst.round_key);
        end
    end

    initial begin
        // Initialize Inputs
        clk     = 0;
        rst     = 1;
        start   = 0;
        mode    = 0;
        data_in = 0;
        key     = 0;

        $display("==================================================");
        $display("   Starting AES-128 Engine Functional Verification ");
        $display("==================================================");

        // Reset the system
        #20;
        rst = 0;
        #10;

        // --- TEST 1: ENCRYPTION ---
        $display("\n--- [TEST 1] ENCRYPTION START ---");
        $display("Plaintext:  %h", expected_plaintext);
        $display("Cipher Key: %h", key_vector);

        mode    = 1'b0; // Mode 0 = Encrypt
        key     = key_vector;
        data_in = expected_plaintext;
        
        #10;
        start = 1;
        #10;
        start = 0;

        // Wait for Encryption Core Done
        while (!done) begin
            #10;
        end

        temp_ciphertext = data_out;
        $display("Ciphertext: %h", temp_ciphertext);
        $display("Expected:   %h", expected_ciphertext);

        if (temp_ciphertext == expected_ciphertext) begin
            $display(">>> ENCRYPTION TEST PASSED!");
            enc_passed = 1;
        end else begin
            $display(">>> ENCRYPTION TEST FAILED! (Mismatch)");
            enc_passed = 0;
        end

        // Wait a few cycles
        #30;

        // --- TEST 2: DECRYPTION ---
        $display("\n--- [TEST 2] DECRYPTION START ---");
        $display("Ciphertext: %h", temp_ciphertext);
        $display("Cipher Key: %h", key_vector);

        mode    = 1'b1; // Mode 1 = Decrypt
        key     = key_vector;
        data_in = temp_ciphertext;

        #10;
        start = 1;
        #10;
        start = 0;

        // Wait for Decryption Core Done
        while (!done) begin
            #10;
        end

        $display("Plaintext:  %h", data_out);
        $display("Expected:   %h", expected_plaintext);

        if (data_out == expected_plaintext) begin
            $display(">>> DECRYPTION TEST PASSED!");
            dec_passed = 1;
        end else begin
            $display(">>> DECRYPTION TEST FAILED! (Mismatch)");
            dec_passed = 0;
        end

        #20;
        $display("\n==================================================");
        if (enc_passed && dec_passed) begin
            $display("       ALL AES-128 VERIFICATION TESTS PASSED!");
        end else begin
            $display("       AES-128 VERIFICATION TESTS FAILED!");
        end
        $display("==================================================");

        $finish;
    end
endmodule
