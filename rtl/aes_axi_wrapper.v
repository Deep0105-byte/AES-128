`timescale 1ns / 1ps

// AXI4-Lite Wrapper for AES-128 Core
module aes_axi_wrapper # (
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 6
)(
    // AXI4-Lite Slave Ports
    input  wire                                S_AXI_ACLK,
    input  wire                                S_AXI_ARESETN, // active-low

    // Write Address Channel
    input  wire [C_S_AXI_ADDR_WIDTH-1 : 0]     S_AXI_AWADDR,
    input  wire                                S_AXI_AWVALID,
    output wire                                S_AXI_AWREADY,

    // Write Data Channel
    input  wire [C_S_AXI_DATA_WIDTH-1 : 0]     S_AXI_WDATA,
    input  wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
    input  wire                                S_AXI_WVALID,
    output wire                                S_AXI_WREADY,

    // Write Response Channel
    output wire [1:0]                          S_AXI_BRESP,
    output wire                                S_AXI_BVALID,
    input  wire                                S_AXI_BREADY,

    // Read Address Channel
    input  wire [C_S_AXI_ADDR_WIDTH-1 : 0]     S_AXI_ARADDR,
    input  wire                                S_AXI_ARVALID,
    output wire                                S_AXI_ARREADY,

    // Read Data Channel
    output wire [C_S_AXI_DATA_WIDTH-1 : 0]     S_AXI_RDATA,
    output wire [1:0]                          S_AXI_RRESP,
    output wire                                S_AXI_RVALID,
    input  wire                                S_AXI_RREADY
);

    // Internal Register Bank (14 registers of 32-bit width)
    reg [31:0] reg_plaintext0;  // 0x00
    reg [31:0] reg_plaintext1;  // 0x04
    reg [31:0] reg_plaintext2;  // 0x08
    reg [31:0] reg_plaintext3;  // 0x0C
    reg [31:0] reg_key0;        // 0x10
    reg [31:0] reg_key1;        // 0x14
    reg [31:0] reg_key2;        // 0x18
    reg [31:0] reg_key3;        // 0x1C
    reg [31:0] reg_control;     // 0x20
    reg [31:0] reg_status;      // 0x24
    reg [31:0] reg_ciphertext0; // 0x28
    reg [31:0] reg_ciphertext1; // 0x2C
    reg [31:0] reg_ciphertext2; // 0x30
    reg [31:0] reg_ciphertext3; // 0x34

    // AXI4-Lite Internal Signals
    reg [C_S_AXI_ADDR_WIDTH-1 : 0] axi_awaddr;
    reg                            axi_awready;
    reg                            axi_wready;
    reg [1:0]                      axi_bresp;
    reg                            axi_bvalid;
    reg [C_S_AXI_ADDR_WIDTH-1 : 0] axi_araddr;
    reg                            axi_arready;
    reg [C_S_AXI_DATA_WIDTH-1 : 0] axi_rdata;
    reg [1:0]                      axi_rresp;
    reg                            axi_rvalid;

    // Pulse signal for starting the AES Core
    reg                            aes_start_pulse;

    // Interface assignments
    assign S_AXI_AWREADY = axi_awready;
    assign S_AXI_WREADY  = axi_wready;
    assign S_AXI_BRESP   = axi_bresp;
    assign S_AXI_BVALID  = axi_bvalid;
    assign S_AXI_ARREADY = axi_arready;
    assign S_AXI_RDATA   = axi_rdata;
    assign S_AXI_RRESP   = axi_rresp;
    assign S_AXI_RVALID  = axi_rvalid;

    // ----------------------------------------------------
    // Write Channel Handshake & Latch Address
    // ----------------------------------------------------
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_awready <= 1'b0;
            axi_wready  <= 1'b0;
            axi_awaddr  <= {C_S_AXI_ADDR_WIDTH{1'b0}};
        end else begin
            // Ready when both address and data are valid
            if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID) begin
                axi_awready <= 1'b1;
                axi_awaddr  <= S_AXI_AWADDR;
            end else begin
                axi_awready <= 1'b0;
            end

            if (~axi_wready && S_AXI_AWVALID && S_AXI_WVALID) begin
                axi_wready <= 1'b1;
            end else begin
                axi_wready <= 1'b0;
            end
        end
    end

    // slv_reg_wren is high when write handshakes are active
    wire slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

    // ----------------------------------------------------
    // Write Data Latching & Start Pulse Generation
    // ----------------------------------------------------
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            reg_plaintext0  <= 32'h0;
            reg_plaintext1  <= 32'h0;
            reg_plaintext2  <= 32'h0;
            reg_plaintext3  <= 32'h0;
            reg_key0        <= 32'h0;
            reg_key1        <= 32'h0;
            reg_key2        <= 32'h0;
            reg_key3        <= 32'h0;
            reg_control     <= 32'h0;
            aes_start_pulse <= 1'b0;
        end else begin
            // Default self-clearing behavior for pulse controls
            aes_start_pulse <= 1'b0;
            reg_control[0]  <= 1'b0; // start bit self-clears automatically in next cycle

            if (slv_reg_wren) begin
                case (axi_awaddr[5:2])
                    4'd0: reg_plaintext0 <= S_AXI_WDATA;
                    4'd1: reg_plaintext1 <= S_AXI_WDATA;
                    4'd2: reg_plaintext2 <= S_AXI_WDATA;
                    4'd3: reg_plaintext3 <= S_AXI_WDATA;
                    4'd4: reg_key0       <= S_AXI_WDATA;
                    4'd5: reg_key1       <= S_AXI_WDATA;
                    4'd6: reg_key2       <= S_AXI_WDATA;
                    4'd7: reg_key3       <= S_AXI_WDATA;
                    4'd8: begin
                        reg_control <= S_AXI_WDATA;
                        if (S_AXI_WDATA[0]) begin
                            aes_start_pulse <= 1'b1;
                        end
                    end
                    // Other registers are Read-Only (writes ignored)
                    default: ;
                endcase
            end
        end
    end

    // ----------------------------------------------------
    // Write Response Channel Control
    // ----------------------------------------------------
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_bvalid <= 1'b0;
            axi_bresp  <= 2'b00;
        end else begin
            if (axi_awready && S_AXI_AWVALID && axi_wready && S_AXI_WVALID && ~axi_bvalid) begin
                axi_bvalid <= 1'b1;
                axi_bresp  <= 2'b00; // OKAY
            end else if (S_AXI_BREADY && axi_bvalid) begin
                axi_bvalid <= 1'b0;
            end
        end
    end

    // ----------------------------------------------------
    // Read Address Channel Handshake
    // ----------------------------------------------------
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_arready <= 1'b0;
            axi_araddr  <= {C_S_AXI_ADDR_WIDTH{1'b0}};
        end else begin
            if (~axi_arready && S_AXI_ARVALID) begin
                axi_arready <= 1'b1;
                axi_araddr  <= S_AXI_ARADDR;
            end else begin
                axi_arready <= 1'b0;
            end
        end
    end

    // ----------------------------------------------------
    // Read Data & Valid Handshake
    // ----------------------------------------------------
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_rvalid <= 1'b0;
            axi_rresp  <= 2'b00;
        end else begin
            if (axi_arready && S_AXI_ARVALID && ~axi_rvalid) begin
                axi_rvalid <= 1'b1;
                axi_rresp  <= 2'b00; // OKAY
            end else if (axi_rvalid && S_AXI_RREADY) begin
                axi_rvalid <= 1'b0;
            end
        end
    end

    // slv_reg_rden is high when a read is initiated
    wire slv_reg_rden = axi_arready && S_AXI_ARVALID && ~axi_rvalid;
    reg [C_S_AXI_DATA_WIDTH-1 : 0] reg_data_out;

    // Read address multiplexing
    always @(*) begin
        case (axi_araddr[5:2])
            4'd0:  reg_data_out = reg_plaintext0;
            4'd1:  reg_data_out = reg_plaintext1;
            4'd2:  reg_data_out = reg_plaintext2;
            4'd3:  reg_data_out = reg_plaintext3;
            4'd4:  reg_data_out = reg_key0;
            4'd5:  reg_data_out = reg_key1;
            4'd6:  reg_data_out = reg_key2;
            4'd7:  reg_data_out = reg_key3;
            4'd8:  reg_data_out = reg_control;
            4'd9:  reg_data_out = reg_status;
            4'd10: reg_data_out = reg_ciphertext0;
            4'd11: reg_data_out = reg_ciphertext1;
            4'd12: reg_data_out = reg_ciphertext2;
            4'd13: reg_data_out = reg_ciphertext3;
            default: reg_data_out = 32'h0;
        endcase
    end

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_rdata <= 32'h0;
        end else begin
            if (slv_reg_rden) begin
                axi_rdata <= reg_data_out;
            end
        end
    end

    // ----------------------------------------------------
    // AES Core Output Latching & Done Status sticky bit
    // ----------------------------------------------------
    wire [127:0] aes_data_out;
    wire         aes_done;

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            reg_ciphertext0 <= 32'h0;
            reg_ciphertext1 <= 32'h0;
            reg_ciphertext2 <= 32'h0;
            reg_ciphertext3 <= 32'h0;
            reg_status      <= 32'h0;
        end else begin
            if (aes_done) begin
                // Latch 128-bit ciphertext
                reg_ciphertext0 <= aes_data_out[127:96];
                reg_ciphertext1 <= aes_data_out[95:64];
                reg_ciphertext2 <= aes_data_out[63:32];
                reg_ciphertext3 <= aes_data_out[31:0];
                reg_status[0]   <= 1'b1; // done bit set to 1
            end else if (aes_start_pulse) begin
                reg_status[0]   <= 1'b0; // clear done bit on next start
            end
        end
    end

    // ----------------------------------------------------
    // Instantiation of the AES Top core (u_aes_top)
    // ----------------------------------------------------
    aes_top u_aes_top (
        .clk     (S_AXI_ACLK),
        .rst     (~S_AXI_ARESETN), // active-high reset for core
        .mode    (reg_control[1]), // drive mode directly (level signal)
        .start   (aes_start_pulse), // drive start pulse
        .data_in ({reg_plaintext0, reg_plaintext1, reg_plaintext2, reg_plaintext3}),
        .key     ({reg_key0, reg_key1, reg_key2, reg_key3}),
        .data_out(aes_data_out),
        .done    (aes_done)
    );

endmodule
