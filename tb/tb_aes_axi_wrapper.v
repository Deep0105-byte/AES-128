`timescale 1ns / 1ps

// Testbench for the AES AXI4-Lite Wrapper
module tb_aes_axi_wrapper;

    parameter integer C_S_AXI_DATA_WIDTH = 32;
    parameter integer C_S_AXI_ADDR_WIDTH = 6;

    // Clock and Reset
    reg                                S_AXI_ACLK;
    reg                                S_AXI_ARESETN;

    // AXI Write Address Channel
    reg  [C_S_AXI_ADDR_WIDTH-1 : 0]     S_AXI_AWADDR;
    reg                                S_AXI_AWVALID;
    wire                               S_AXI_AWREADY;

    // AXI Write Data Channel
    reg  [C_S_AXI_DATA_WIDTH-1 : 0]     S_AXI_WDATA;
    reg  [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB;
    reg                                S_AXI_WVALID;
    wire                               S_AXI_WREADY;

    // AXI Write Response Channel
    wire [1:0]                         S_AXI_BRESP;
    wire                               S_AXI_BVALID;
    reg                                S_AXI_BREADY;

    // AXI Read Address Channel
    reg  [C_S_AXI_ADDR_WIDTH-1 : 0]     S_AXI_ARADDR;
    reg                                S_AXI_ARVALID;
    wire                               S_AXI_ARREADY;

    // AXI Read Data Channel
    wire [C_S_AXI_DATA_WIDTH-1 : 0]     S_AXI_RDATA;
    wire [1:0]                         S_AXI_RRESP;
    wire                               S_AXI_RVALID;
    reg                                S_AXI_RREADY;

    // Instantiate AXI Wrapper
    aes_axi_wrapper #(
        .C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
    ) uut (
        .S_AXI_ACLK   (S_AXI_ACLK),
        .S_AXI_ARESETN(S_AXI_ARESETN),
        .S_AXI_AWADDR (S_AXI_AWADDR),
        .S_AXI_AWVALID(S_AXI_AWVALID),
        .S_AXI_AWREADY(S_AXI_AWREADY),
        .S_AXI_WDATA  (S_AXI_WDATA),
        .S_AXI_WSTRB  (S_AXI_WSTRB),
        .S_AXI_WVALID (S_AXI_WVALID),
        .S_AXI_WREADY (S_AXI_WREADY),
        .S_AXI_BRESP  (S_AXI_BRESP),
        .S_AXI_BVALID (S_AXI_BVALID),
        .S_AXI_BREADY (S_AXI_BREADY),
        .S_AXI_ARADDR (S_AXI_ARADDR),
        .S_AXI_ARVALID(S_AXI_ARVALID),
        .S_AXI_ARREADY(S_AXI_ARREADY),
        .S_AXI_RDATA  (S_AXI_RDATA),
        .S_AXI_RRESP  (S_AXI_RRESP),
        .S_AXI_RVALID (S_AXI_RVALID),
        .S_AXI_RREADY (S_AXI_RREADY)
    );

    // Clock generation (100MHz)
    always #5 S_AXI_ACLK = ~S_AXI_ACLK;

    // Register Offset Constants
    localparam [5:0] ADDR_PLAINTEXT_0  = 6'h00;
    localparam [5:0] ADDR_PLAINTEXT_1  = 6'h04;
    localparam [5:0] ADDR_PLAINTEXT_2  = 6'h08;
    localparam [5:0] ADDR_PLAINTEXT_3  = 6'h0C;
    localparam [5:0] ADDR_KEY_0        = 6'h10;
    localparam [5:0] ADDR_KEY_1        = 6'h14;
    localparam [5:0] ADDR_KEY_2        = 6'h18;
    localparam [5:0] ADDR_KEY_3        = 6'h1C;
    localparam [5:0] ADDR_CONTROL      = 6'h20;
    localparam [5:0] ADDR_STATUS       = 6'h24;
    localparam [5:0] ADDR_CIPHERTEXT_0 = 6'h28;
    localparam [5:0] ADDR_CIPHERTEXT_1 = 6'h2C;
    localparam [5:0] ADDR_CIPHERTEXT_2 = 6'h30;
    localparam [5:0] ADDR_CIPHERTEXT_3 = 6'h34;

    // AXI Write Task
    task axi_write(
        input [C_S_AXI_ADDR_WIDTH-1:0] addr,
        input [C_S_AXI_DATA_WIDTH-1:0] data
    );
        begin
            @(posedge S_AXI_ACLK);
            S_AXI_AWADDR  = addr;
            S_AXI_AWVALID = 1'b1;
            S_AXI_WDATA   = data;
            S_AXI_WVALID  = 1'b1;
            S_AXI_WSTRB   = 4'hF;
            S_AXI_BREADY  = 1'b1;

            // Wait for both ready handshakes
            fork
                begin
                    while (!S_AXI_AWREADY) @(posedge S_AXI_ACLK);
                end
                begin
                    while (!S_AXI_WREADY) @(posedge S_AXI_ACLK);
                end
            join

            @(posedge S_AXI_ACLK);
            S_AXI_AWVALID = 1'b0;
            S_AXI_WVALID  = 1'b0;

            // Wait for response validity
            while (!S_AXI_BVALID) @(posedge S_AXI_ACLK);
            
            @(posedge S_AXI_ACLK);
            S_AXI_BREADY = 1'b0;
            #15;
        end
    endtask

    // AXI Read Task
    task axi_read(
        input  [C_S_AXI_ADDR_WIDTH-1:0] addr,
        output [C_S_AXI_DATA_WIDTH-1:0] data
    );
        begin
            @(posedge S_AXI_ACLK);
            S_AXI_ARADDR  = addr;
            S_AXI_ARVALID = 1'b1;
            S_AXI_RREADY  = 1'b1;

            while (!S_AXI_ARREADY) @(posedge S_AXI_ACLK);

            @(posedge S_AXI_ACLK);
            S_AXI_ARVALID = 1'b0;

            while (!S_AXI_RVALID) @(posedge S_AXI_ACLK);
            data = S_AXI_RDATA;

            @(posedge S_AXI_ACLK);
            S_AXI_RREADY = 1'b0;
            #15;
        end
    endtask

    // Verification variables
    reg [31:0] read_val;
    reg [127:0] expected_ciphertext = 128'h69c4e0d86a7b0430d8cdb78070b4c55a;
    reg [127:0] expected_plaintext  = 128'h00112233445566778899aabbccddeeff;
    reg [127:0] key_vector          = 128'h000102030405060708090a0b0c0d0e0f;
    reg [127:0] result_ciphertext;
    reg [127:0] result_plaintext;

    initial begin
        if ($test$plusargs("fsdb")) begin
            $fsdbDumpfile("tb_aes_axi_wrapper.fsdb");
            $fsdbDumpvars(0, tb_aes_axi_wrapper);
        end
        // Initialize Ports
        S_AXI_ACLK    = 0;
        S_AXI_ARESETN = 0;
        S_AXI_AWADDR  = 0;
        S_AXI_AWVALID = 0;
        S_AXI_WDATA   = 0;
        S_AXI_WVALID  = 0;
        S_AXI_WSTRB   = 0;
        S_AXI_BREADY  = 0;
        S_AXI_ARADDR  = 0;
        S_AXI_ARVALID = 0;
        S_AXI_RREADY  = 0;

        $display("==================================================");
        $display("  Starting AXI4-Lite AES Wrapper Verification tb  ");
        $display("==================================================");

        // Reset system
        #40;
        S_AXI_ARESETN = 1;
        #20;

        // --- TEST 1: MMIO ENCRYPTION WRITE & RUN ---
        $display("\n--- [TEST 1] WRITING PLAINTEXT AND KEY OVER AXI ---");
        
        // Write Plaintext: 00112233_44556677_8899aabb_ccddeeff
        axi_write(ADDR_PLAINTEXT_0, key_vector[127:96]); // Wait, write test plaintext
        axi_write(ADDR_PLAINTEXT_0, expected_plaintext[127:96]);
        axi_write(ADDR_PLAINTEXT_1, expected_plaintext[95:64]);
        axi_write(ADDR_PLAINTEXT_2, expected_plaintext[63:32]);
        axi_write(ADDR_PLAINTEXT_3, expected_plaintext[31:0]);

        // Write Key: 00010203_04050607_08090a0b_0c0d0e0f
        axi_write(ADDR_KEY_0, key_vector[127:96]);
        axi_write(ADDR_KEY_1, key_vector[95:64]);
        axi_write(ADDR_KEY_2, key_vector[63:32]);
        axi_write(ADDR_KEY_3, key_vector[31:0]);

        $display("--- TRIGGERING ENCRYPTION (mode = 0, start = 1) ---");
        axi_write(ADDR_CONTROL, 32'h00000001); // start=1, mode=0

        // Poll status register
        $display("--- POLLING STATUS REGISTER ---");
        read_val = 32'h0;
        while (read_val[0] == 1'b0) begin
            axi_read(ADDR_STATUS, read_val);
            #10;
        end
        $display("Encryption complete! STATUS read: %h", read_val);

        // Read results from Ciphertext registers
        axi_read(ADDR_CIPHERTEXT_0, result_ciphertext[127:96]);
        axi_read(ADDR_CIPHERTEXT_1, result_ciphertext[95:64]);
        axi_read(ADDR_CIPHERTEXT_2, result_ciphertext[63:32]);
        axi_read(ADDR_CIPHERTEXT_3, result_ciphertext[31:0]);

        $display("Read Ciphertext:     %h", result_ciphertext);
        $display("Expected Ciphertext: %h", expected_ciphertext);

        if (result_ciphertext == expected_ciphertext) begin
            $display(">>> AXI ENCRYPTION MATCH SUCCESSFUL!");
        end else begin
            $display(">>> AXI ENCRYPTION MATCH FAILED! (Mismatch)");
            $finish;
        end

        // --- TEST 2: MMIO DECRYPTION WRITE & RUN ---
        $display("\n--- [TEST 2] WRITING CIPHERTEXT BACK FOR DECRYPTION ---");
        // Load Ciphertext into Plaintext registers for Decrypting
        axi_write(ADDR_PLAINTEXT_0, result_ciphertext[127:96]);
        axi_write(ADDR_PLAINTEXT_1, result_ciphertext[95:64]);
        axi_write(ADDR_PLAINTEXT_2, result_ciphertext[63:32]);
        axi_write(ADDR_PLAINTEXT_3, result_ciphertext[31:0]);

        $display("--- TRIGGERING DECRYPTION (mode = 1, start = 1) ---");
        axi_write(ADDR_CONTROL, 32'h00000003); // start=1, mode=1

        // Poll status register
        $display("--- POLLING STATUS REGISTER ---");
        read_val = 32'h0;
        while (read_val[0] == 1'b0) begin
            axi_read(ADDR_STATUS, read_val);
            #10;
        end
        $display("Decryption complete! STATUS read: %h", read_val);

        // Read results back
        axi_read(ADDR_CIPHERTEXT_0, result_plaintext[127:96]);
        axi_read(ADDR_CIPHERTEXT_1, result_plaintext[95:64]);
        axi_read(ADDR_CIPHERTEXT_2, result_plaintext[63:32]);
        axi_read(ADDR_CIPHERTEXT_3, result_plaintext[31:0]);

        $display("Read Plaintext:     %h", result_plaintext);
        $display("Expected Plaintext: %h", expected_plaintext);

        if (result_plaintext == expected_plaintext) begin
            $display(">>> AXI DECRYPTION MATCH SUCCESSFUL!");
        end else begin
            $display(">>> AXI DECRYPTION MATCH FAILED! (Mismatch)");
        end

        $display("\n==================================================");
        if ((result_ciphertext == expected_ciphertext) && (result_plaintext == expected_plaintext)) begin
            $display("   AXI WRAPPER SYSTEM VERIFICATION PASSED!");
        end else begin
            $display("   AXI WRAPPER SYSTEM VERIFICATION FAILED!");
        end
        $display("==================================================");

        $finish;
    end
endmodule
