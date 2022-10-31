module AudPlayer(
    input i_rst_n,
	input i_bclk,
	input i_daclrck,
	input i_en, // enable AudPlayer only when playing audio, work with AudDSP
	input [15:0]i_dac_data, //dac_data
	output o_aud_dacdat,
	
	output [4:0] state_play
);
logic dac_data_t, dac_data_r;
logic [4:0] count_t, count_r;
assign o_aud_dacdat = dac_data_r;

logic [1:0] state_t, state_r;
assign state_play = state_r;

logic wait_cycle_t, wait_cycle_r;
logic [15:0] in_dac_data_t, in_dac_data_r;

parameter	S_IDLE = 2'd0;
parameter	S_WAIT = 2'd1;
parameter   S_PLAY = 2'd2;

always_comb begin
	//default
	count_t = count_r;
	dac_data_t = dac_data_r;
	state_t = state_r;
	wait_cycle_t = i_daclrck;
	in_dac_data_t = in_dac_data_r;

	//FSM
	case(state_r)
	S_IDLE: begin
		if(i_en ) begin
			state_t = S_WAIT; 

		end
	end
	S_WAIT:	begin	//wait one cycle
		in_dac_data_t = i_dac_data;
		if(!i_daclrck && wait_cycle_r) begin
			count_t = 0;
			state_t = S_PLAY;
			dac_data_t = i_dac_data[5'd15-count_r];
		end
	end
	S_PLAY:begin
		// if(!i_en)	state_t = S_IDLE;
		dac_data_t = i_dac_data[5'd15-count_r];
		count_t = count_r +1;
		if (count_r >= 5'd15) begin
			in_dac_data_t = 0;
			state_t = S_WAIT;
		end
		
		
	end
	endcase
end


always_ff @(posedge i_bclk or negedge i_rst_n)begin
	if(!i_rst_n)begin
		dac_data_r <= 0;
		count_r <= 5'd0;
		state_r <= S_IDLE;
		wait_cycle_r <= 0;
		in_dac_data_r <=0;
	end
	else begin
		dac_data_r <= dac_data_t;
		count_r <= count_t;
		state_r <= state_t;
		wait_cycle_r <= wait_cycle_t;
		in_dac_data_r <= in_dac_data_t;
	end
end
endmodule
