module rgb2hsv(
    input [7:0] i_R,
    input [7:0] i_G,
    input [7:0] i_B,
    output [7:0] o_H,
    output [7:0] o_S,
    output [7:0] o_V
);

reg [7:0] max, min;


wire [16:0] diff_shift;
assign diff_shift = (max - min)<<8;
wire [16:0] divide;
assign divide = (max == 0) ? 0:(diff_shift/max);
assign o_S = divide[7:0];

always @(*) begin
    if (i_R>i_G &&i_R>i_B)begin
        max = i_R;
    end
    else if (i_G>i_R &&i_G>i_B)begin
        max = i_G;
    end
    else if (i_G == i_R && i_G>i_B)begin
        max = i_G;
    end
    else begin
        max = i_B;
    end

    if (i_R<i_G && i_R<i_B)begin
        min = i_R;
    end
    else if (i_G<i_R && i_G<i_B)begin
        min = i_G;
    end
    else if (i_G == i_R && i_G<i_B)begin
        min = i_G;
    end
    else begin
        min = i_B;
    end
end
endmodule