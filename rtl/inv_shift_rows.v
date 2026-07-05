// AES Inverse ShiftRows Module
module inv_shift_rows (
    input  wire [127:0] in,
    output wire [127:0] out
);
    // Row 0: bytes 0, 4, 8, 12 remain at 0, 4, 8, 12
    assign out[127:120] = in[127:120]; // Byte 0
    assign out[95:88]   = in[95:88];   // Byte 4
    assign out[63:56]   = in[63:56];   // Byte 8
    assign out[31:24]   = in[31:24];   // Byte 12

    // Row 1: shifted right by 1 byte: 13->1, 1->5, 5->9, 9->13
    assign out[119:112] = in[23:16];   // Byte 1 <= Byte 13
    assign out[87:80]   = in[119:112]; // Byte 5 <= Byte 1
    assign out[55:48]   = in[87:80];   // Byte 9 <= Byte 5
    assign out[23:16]   = in[55:48];   // Byte 13 <= Byte 9

    // Row 2: shifted right by 2 bytes: 10->2, 14->6, 2->10, 6->14
    assign out[111:104] = in[47:40];   // Byte 2 <= Byte 10
    assign out[79:72]   = in[15:8];    // Byte 6 <= Byte 14
    assign out[47:40]   = in[111:104]; // Byte 10 <= Byte 2
    assign out[15:8]    = in[79:72];   // Byte 14 <= Byte 6

    // Row 3: shifted right by 3 bytes: 7->3, 11->7, 15->11, 3->15
    assign out[103:96]  = in[71:64];   // Byte 3 <= Byte 7
    assign out[71:64]   = in[39:32];   // Byte 7 <= Byte 11
    assign out[39:32]   = in[7:0];     // Byte 11 <= Byte 15
    assign out[7:0]     = in[103:96];  // Byte 15 <= Byte 3
endmodule
