module MontgemoryAlgorithm(
	input		   i_clk,
	input 		   i_rst,
	input  [255:0] i_N,
	input  [255:0] i_a,
	input  [255:0] i_b,
	output [257:0] o_m	
);

	logic  [257:0] o_m_r, o_m_w;
	logic  [15:0]  count_r, count_w;

	assign o_m = o_m_r;

	always_comb
	begin
		// Default Value //
		o_m_w = o_m_r;
		count_w = count_r;

		if(count_r < 16'd256)
		begin
			//count_w = count_r + 1;
			if(i_a[count_r] == 1'b1)
			begin
				if(o_m_r[0] ^ i_b[0] == 1'b1)
				begin
					o_m_w = (o_m_r + i_b + i_N) >> 1;
				end
				else o_m_w = (o_m_r + i_b) >> 1;
			end

			else
			begin
				if(o_m_r[0] == 1'b1)
				begin
					o_m_w = (o_m_r + i_N) >> 1;
				end
				else o_m_w = o_m_r >> 1;
			end
			count_w = count_r + 1;
		end

		else
		begin
			count_w = count_r;
			if(o_m_r >= i_N)
			begin
				o_m_w = o_m_r - i_N;
			end
			else o_m_w = o_m_r;
		end

	end


	always_ff @(posedge i_clk or negedge i_rst)
	begin
		if(!i_rst)
		begin
			count_r <= 16'd0;
			o_m_r <= 258'd0;
		end

		else
		begin
			count_r <= count_w;
			o_m_r <= o_m_w;
		end
	end


endmodule
