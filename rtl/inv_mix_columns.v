// AES Inverse MixColumns Module
module inv_mix_columns (
    input  wire [127:0] in,
    output wire [127:0] out
);
    inv_mix_column col0 (.in(in[127:96]), .out(out[127:96]));
    inv_mix_column col1 (.in(in[95:64]),  .out(out[95:64]));
    inv_mix_column col2 (.in(in[63:32]),  .out(out[63:32]));
    inv_mix_column col3 (.in(in[31:0]),   .out(out[31:0]));
endmodule

module inv_mix_column (
    input  wire [31:0] in,
    output wire [31:0] out
);
    wire [7:0] s0 = in[31:24];
    wire [7:0] s1 = in[23:16];
    wire [7:0] s2 = in[15:8];
    wire [7:0] s3 = in[7:0];

    // Helper outputs for s0
    wire [7:0] s0_1 = (s0[7])   ? ((s0 << 1)   ^ 8'h1b) : (s0 << 1);
    wire [7:0] s0_2 = (s0_1[7])  ? ((s0_1 << 1)  ^ 8'h1b) : (s0_1 << 1);
    wire [7:0] s0_3 = (s0_2[7])  ? ((s0_2 << 1)  ^ 8'h1b) : (s0_2 << 1);
    wire [7:0] mul9_s0  = s0_3 ^ s0;
    wire [7:0] mul11_s0 = s0_3 ^ s0_1 ^ s0;
    wire [7:0] mul13_s0 = s0_3 ^ s0_2 ^ s0;
    wire [7:0] mul14_s0 = s0_3 ^ s0_2 ^ s0_1;

    // Helper outputs for s1
    wire [7:0] s1_1 = (s1[7])   ? ((s1 << 1)   ^ 8'h1b) : (s1 << 1);
    wire [7:0] s1_2 = (s1_1[7])  ? ((s1_1 << 1)  ^ 8'h1b) : (s1_1 << 1);
    wire [7:0] s1_3 = (s1_2[7])  ? ((s1_2 << 1)  ^ 8'h1b) : (s1_2 << 1);
    wire [7:0] mul9_s1  = s1_3 ^ s1;
    wire [7:0] mul11_s1 = s1_3 ^ s1_1 ^ s1;
    wire [7:0] mul13_s1 = s1_3 ^ s1_2 ^ s1;
    wire [7:0] mul14_s1 = s1_3 ^ s1_2 ^ s1_1;

    // Helper outputs for s2
    wire [7:0] s2_1 = (s2[7])   ? ((s2 << 1)   ^ 8'h1b) : (s2 << 1);
    wire [7:0] s2_2 = (s2_1[7])  ? ((s2_1 << 1)  ^ 8'h1b) : (s2_1 << 1);
    wire [7:0] s2_3 = (s2_2[7])  ? ((s2_2 << 1)  ^ 8'h1b) : (s2_2 << 1);
    wire [7:0] mul9_s2  = s2_3 ^ s2;
    wire [7:0] mul11_s2 = s2_3 ^ s2_1 ^ s2;
    wire [7:0] mul13_s2 = s2_3 ^ s2_2 ^ s2;
    wire [7:0] mul14_s2 = s2_3 ^ s2_2 ^ s2_1;

    // Helper outputs for s3
    wire [7:0] s3_1 = (s3[7])   ? ((s3 << 1)   ^ 8'h1b) : (s3 << 1);
    wire [7:0] s3_2 = (s3_1[7])  ? ((s3_1 << 1)  ^ 8'h1b) : (s3_1 << 1);
    wire [7:0] s3_3 = (s3_2[7])  ? ((s3_2 << 1)  ^ 8'h1b) : (s3_2 << 1);
    wire [7:0] mul9_s3  = s3_3 ^ s3;
    wire [7:0] mul11_s3 = s3_3 ^ s3_1 ^ s3;
    wire [7:0] mul13_s3 = s3_3 ^ s3_2 ^ s3;
    wire [7:0] mul14_s3 = s3_3 ^ s3_2 ^ s3_1;

    assign out[31:24] = mul14_s0 ^ mul11_s1 ^ mul13_s2 ^ mul9_s3;
    assign out[23:16] = mul9_s0  ^ mul14_s1 ^ mul11_s2 ^ mul13_s3;
    assign out[15:8]  = mul13_s0 ^ mul9_s1  ^ mul14_s2 ^ mul11_s3;
    assign out[7:0]   = mul11_s0 ^ mul13_s1 ^ mul9_s2  ^ mul14_s3;
endmodule
