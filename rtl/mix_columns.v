// AES MixColumns Module
module mix_columns (
    input  wire [127:0] in,
    output wire [127:0] out
);
    mix_column col0 (.in(in[127:96]), .out(out[127:96]));
    mix_column col1 (.in(in[95:64]),  .out(out[95:64]));
    mix_column col2 (.in(in[63:32]),  .out(out[63:32]));
    mix_column col3 (.in(in[31:0]),   .out(out[31:0]));
endmodule

module mix_column (
    input  wire [31:0] in,
    output wire [31:0] out
);
    wire [7:0] s0 = in[31:24];
    wire [7:0] s1 = in[23:16];
    wire [7:0] s2 = in[15:8];
    wire [7:0] s3 = in[7:0];

    // xtime(s) = (s[7] == 1) ? ((s << 1) ^ 8'h1b) : (s << 1)
    wire [7:0] x0 = (s0[7]) ? ((s0 << 1) ^ 8'h1b) : (s0 << 1);
    wire [7:0] x1 = (s1[7]) ? ((s1 << 1) ^ 8'h1b) : (s1 << 1);
    wire [7:0] x2 = (s2[7]) ? ((s2 << 1) ^ 8'h1b) : (s2 << 1);
    wire [7:0] x3 = (s3[7]) ? ((s3 << 1) ^ 8'h1b) : (s3 << 1);

    // Multiplication by 3: 3*s = xtime(s) ^ s
    wire [7:0] m0 = x0 ^ s0;
    wire [7:0] m1 = x1 ^ s1;
    wire [7:0] m2 = x2 ^ s2;
    wire [7:0] m3 = x3 ^ s3;

    assign out[31:24] = x0 ^ m1 ^ s2 ^ s3;
    assign out[23:16] = s0 ^ x1 ^ m2 ^ s3;
    assign out[15:8]  = s0 ^ s1 ^ x2 ^ m3;
    assign out[7:0]   = m0 ^ s1 ^ s2 ^ x3;
endmodule
