module AudPlayer(
    input i_rst_n,
	input i_bclk,
	input i_daclrck,
	input i_en, // enable AudPlayer only when playing audio, work with AudDSP
	input [15:0]i_dac_data, //dac_data
	output o_aud_dacdat
);
logic dac_data_t, dac_data_r;
logic count_t, count_r;

logic [1:0] state_t, state_r;
parameter	S_IDLE = 2'd0;
parameter	S_WAIT = 2'd1;

always_comb begin
	case(state_r)
	S_IDLE: if(en & i_dac_data)	state_t = S_PLAY; 
	S_WAIT:	if(!i_daclrck)begin	//wait one cycle
		count_t = 0;
		state_t = S_PLAY;
	end
	S_PLAY:begin
		if(!en)	state_t = S_IDLE;
		else if(!i_daclrck)begin
			if (count_r<4'd15) begin
			dac_data_t = i_dac_data[count_r];
			count_t = count_r +1;
			end
			else begin
				dac_data_t = i_dac_data[count_r];
				state_t = S_WAIT;
			end
		end
	end
end


always_ff @(posedge i_bclk)begin
	if(!i_rst_n)begin
		dac_data_r <= 0;
		count_r <= 0;
		state_r <= S_IDLE;
	end
	else begin
		dac_data_r <= dac_data_t;
		count_r <= count_t;
		state_r <= state_t;
	end
end
endmodule