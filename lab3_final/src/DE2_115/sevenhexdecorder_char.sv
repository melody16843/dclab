module SevenHexDecoder_char (
	input        [3:0] i_hex,
	output logic [6:0] o_seven_thu,
	output logic [6:0] o_seven_hud,
    output logic [6:0] o_seven_ten,
	output logic [6:0] o_seven_one
);

/* The layout of seven segment display, 1: dark
 *    00
 *   5  1
 *    66
 *   4  2
 *    33
 */
parameter P = 7'b0001100;
parameter L = 7'b1000111;
parameter A = 7'b0001000;
parameter y = 7'b0010001;
parameter r = 7'b0101111;
parameter E = 7'b0000110;
parameter d = 7'b0100001;
parameter C = 7'b0100111;
// parameter a = 7'b0000010;
parameter I = 7'b1111001;
parameter n = 7'b0101011;
parameter t = 7'b0000111;
parameter U = 7'b1000001;
parameter S = 7'b0010010;
parameter F = 7'b0001110;
parameter O = 7'b1000000;
parameter dark = 7'b1111111;
always_comb begin
	case(i_hex)
		4'h0: begin o_seven_thu = I; o_seven_hud = n; o_seven_ten = I; o_seven_one = t; end
		4'h1: begin o_seven_thu = r; o_seven_hud = E; o_seven_ten = d; o_seven_one = y; end
		4'h2: begin o_seven_thu = r; o_seven_hud = E; o_seven_ten = C; o_seven_one = d; end
		4'h3: begin o_seven_thu = P; o_seven_hud = L; o_seven_ten = A; o_seven_one = y; end
		4'h4: begin o_seven_thu = P; o_seven_hud = A; o_seven_ten = U; o_seven_one = S; end
		4'h5: begin o_seven_thu = F; o_seven_hud = A; o_seven_ten = S; o_seven_one = t; end
		4'h6: begin o_seven_thu = S; o_seven_hud = L; o_seven_ten = O; o_seven_one = dark; end
		// 5'h7: begin o_seven_ten = D0; o_seven_one = D7; end
		// 5'h8: begin o_seven_ten = D0; o_seven_one = D8; end
		// 5'h9: begin o_seven_ten = D0; o_seven_one = D9; end
		// 5'ha: begin o_seven_ten = D1; o_seven_one = D0; end
		// 5'hb: begin o_seven_ten = D1; o_seven_one = D1; end
		// 5'hc: begin o_seven_ten = D1; o_seven_one = D2; end
		// 5'hd: begin o_seven_ten = D1; o_seven_one = D3; end
		// 5'he: begin o_seven_ten = D1; o_seven_one = D4; end
		// 5'hf: begin o_seven_ten = D1; o_seven_one = D5; end
		// 5'd16: begin o_seven_ten = D1; o_seven_one = D6; end
		// 5'd17: begin o_seven_ten = D1; o_seven_one = D7; end
		// 5'd18: begin o_seven_ten = D1; o_seven_one = D8; end
		// 5'd19: begin o_seven_ten = D1; o_seven_one = D9; end
		// 5'd20: begin o_seven_ten = D2; o_seven_one = D0; end
		// 5'd21: begin o_seven_ten = D2; o_seven_one = D1; end
		// 5'd22: begin o_seven_ten = D2; o_seven_one = D2; end
		// 5'd23: begin o_seven_ten = D2; o_seven_one = D3; end
		// 5'd24: begin o_seven_ten = D2; o_seven_one = D4; end
		// 5'd25: begin o_seven_ten = D2; o_seven_one = D5; end
		// 5'd26: begin o_seven_ten = D2; o_seven_one = D6; end
		// 5'd27: begin o_seven_ten = D2; o_seven_one = D7; end
		// 5'd28: begin o_seven_ten = D2; o_seven_one = D8; end
		// 5'd29: begin o_seven_ten = D2; o_seven_one = D9; end
		// 5'd30: begin o_seven_ten = D3; o_seven_one = D0; end
		// 5'd31: begin o_seven_ten = D3; o_seven_one = D1; end
		//6'd32: begin o_seven_ten = D1; o_seven_one = D5; end
		
		default: begin o_seven_thu = I; o_seven_hud = n; o_seven_ten = I; o_seven_one = t; end
	endcase
end

endmodule
