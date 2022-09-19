module SevenHexDecoder (
	input        [3:0] i_hex,
	input        [3:0] try,
	output logic [6:0] o_seven_ten,
	output logic [6:0] o_seven_one,
	output logic [6:0] o_seven_hundred,
	output logic [6:0] o_seven_thousand
);

/* The layout of seven segment display, 1: dark
 *    00
 *   5  1
 *    66
 *   4  2
 *    33
 */
parameter D0 = 7'b1000000;
parameter D1 = 7'b1111001;
parameter D2 = 7'b0100100;
parameter D3 = 7'b0110000;
parameter D4 = 7'b0011001;
parameter D5 = 7'b0010010;
parameter D6 = 7'b0000010;
parameter D7 = 7'b1011000;
parameter D8 = 7'b0000000;
parameter D9 = 7'b0010000;
always_comb begin
	case(i_hex)
		4'h0: begin o_seven_ten = D0; o_seven_one = D0;  end
		4'h1: begin o_seven_ten = D0; o_seven_one = D1;  end
		4'h2: begin o_seven_ten = D0; o_seven_one = D2;  end
		4'h3: begin o_seven_ten = D0; o_seven_one = D3;  end
		4'h4: begin o_seven_ten = D0; o_seven_one = D4;  end
		4'h5: begin o_seven_ten = D0; o_seven_one = D5;  end
		4'h6: begin o_seven_ten = D0; o_seven_one = D6;  end
		4'h7: begin o_seven_ten = D0; o_seven_one = D7;  end
		4'h8: begin o_seven_ten = D0; o_seven_one = D8;  end
		4'h9: begin o_seven_ten = D0; o_seven_one = D9;  end
		4'ha: begin o_seven_ten = D1; o_seven_one = D0;  end
		4'hb: begin o_seven_ten = D1; o_seven_one = D1;  end
		4'hc: begin o_seven_ten = D1; o_seven_one = D2;  end
		4'hd: begin o_seven_ten = D1; o_seven_one = D3;  end
		4'he: begin o_seven_ten = D1; o_seven_one = D4;  end
		4'hf: begin o_seven_ten = D1; o_seven_one = D5;  end
	endcase
	case(try)
		4'h0: begin o_seven_thousand = D0; o_seven_hundred = D0;  end
		4'h1: begin o_seven_thousand = D0; o_seven_hundred = D1;  end
		4'h2: begin o_seven_thousand = D0; o_seven_hundred = D2;  end
		4'h3: begin o_seven_thousand = D0; o_seven_hundred = D3;  end
		4'h4: begin o_seven_thousand = D0; o_seven_hundred = D4;  end
		4'h5: begin o_seven_thousand = D0; o_seven_hundred = D5;  end
		4'h6: begin o_seven_thousand = D0; o_seven_hundred = D6;  end
		4'h7: begin o_seven_thousand = D0; o_seven_hundred = D7;  end
		4'h8: begin o_seven_thousand = D0; o_seven_hundred = D8;  end
		4'h9: begin o_seven_thousand = D0; o_seven_hundred = D9;  end
		4'ha: begin o_seven_thousand = D1; o_seven_hundred = D0;  end
		4'hb: begin o_seven_thousand = D1; o_seven_hundred = D1;  end
		4'hc: begin o_seven_thousand = D1; o_seven_hundred = D2;  end
		4'hd: begin o_seven_thousand = D1; o_seven_hundred = D3;  end
		4'he: begin o_seven_thousand = D1; o_seven_hundred = D4;  end
		4'hf: begin o_seven_thousand = D1; o_seven_hundred = D5;  end
	endcase
end

endmodule
