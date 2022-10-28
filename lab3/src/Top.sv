module Top (
	input i_rst_n,
	input i_clk,
	input i_key_0,
	input i_key_1,
	input i_key_2,
	// input [3:0] i_speed, // design how user can decide mode on your own
	
	// AudDSP and SRAM
	output [19:0] o_SRAM_ADDR,
	inout  [15:0] io_SRAM_DQ,
	output        o_SRAM_WE_N,
	output        o_SRAM_CE_N,
	output        o_SRAM_OE_N,
	output        o_SRAM_LB_N,
	output        o_SRAM_UB_N,
	
	// I2C
	input  i_clk_100k,
	output o_I2C_SCLK,
	inout  io_I2C_SDAT,
	
	// AudPlayer
	input  i_AUD_ADCDAT,
	inout  i_AUD_ADCLRCK,
	inout  i_AUD_BCLK,
	inout  i_AUD_DACLRCK,
	output o_AUD_DACDAT

	// SEVENDECODER (optional display)
	// output [5:0] o_record_time,
	// output [5:0] o_play_time,

	// LCD (optional display)
	// input        i_clk_800k,
	// inout  [7:0] o_LCD_DATA,
	// output       o_LCD_EN,
	// output       o_LCD_RS,
	// output       o_LCD_RW,
	// output       o_LCD_ON,
	// output       o_LCD_BLON,

	// LED
	// output  [8:0] o_ledg,
	// output [17:0] o_ledr
);

// design the FSM and states as you like
parameter S_IDLE       = 0;
parameter S_I2C        = 1;
parameter S_RECD       = 2;
parameter S_RECD_PAUSE = 3;
parameter S_PLAY       = 4;
parameter S_PLAY_PAUSE = 5;

logic i2c_oen, i2c_sdat;
logic [19:0] addr_record, addr_play;
logic [15:0] data_record, data_play, dac_data;

assign io_I2C_SDAT = (i2c_oen) ? i2c_sdat : 1'bz;

assign o_SRAM_ADDR = (state_r == S_RECD) ? addr_record : addr_play[19:0];
assign io_SRAM_DQ  = (state_r == S_RECD) ? data_record : 16'dz; // sram_dq as output
assign data_play   = (state_r != S_RECD) ? io_SRAM_DQ : 16'd0; // sram_dq as input

assign o_SRAM_WE_N = (state_r == S_RECD) ? 1'b0 : 1'b1;
assign o_SRAM_CE_N = 1'b0;
assign o_SRAM_OE_N = 1'b0;
assign o_SRAM_LB_N = 1'b0;
assign o_SRAM_UB_N = 1'b0;

// below is a simple example for module division
// you can design these as you like

//control var
logic [2:0] state_t, state_r;

//init var
logic init_finished;

//recorder var
logic recorder_start;
logic recorder_pause;

//player var
logic player_start;
logic player_pause;
logic player_stop;



parameter S_INIT = 3'd0;
parameter S_READY = 3'd2;


// === I2cInitializer ===
// sequentially sent out settings to initialize WM8731 with I2C protocal
I2cInitializer init0(
	.i_rst_n(i_rst_n),
	.i_clk(i_clk_100K),
	.i_start(!i_rst_n),
	.o_finished(init_finished),
	.o_sclk(o_I2C_SCLK),
	.o_sdat(i2c_sdat),
	.o_oen(i2c_oen) // you are outputing (you are not outputing only when you are "ack"ing.)
);

// === AudDSP ===
// responsible for DSP operations including fast play and slow play at different speed
// in other words, determine which data addr to be fetch for player 
AudDSP dsp0(
	.i_rst_n(i_rst_n),
	.i_clk(i_AUD_BCLK),
	.i_start(player_start),
	.i_pause(player_pause),
	.i_stop(player_stop),
	.i_fast(),
	.i_slow_0(), // constant interpolation
	.i_slow_1(), // linear interpolation
	.i_daclrck(i_AUD_DACLRCK),
	.i_sram_data(data_play),
	.o_dac_data(dac_data),
	.o_sram_addr(addr_play)
);

// === AudPlayer ===
// receive data address from DSP and fetch data to sent to WM8731 with I2S protocal
AudPlayer player0(
	.i_rst_n(i_rst_n),
	.i_bclk(i_AUD_BCLK),
	.i_daclrck(i_AUD_DACLRCK),
	.i_en(player_start), // enable AudPlayer only when playing audio, work with AudDSP
	.i_dac_data(dac_data), //dac_data
	.o_aud_dacdat(o_AUD_DACDAT)
);

// === AudRecorder ===
// receive data from WM8731 with I2S protocal and save to SRAM
AudRecorder recorder0(
	.i_rst_n(i_rst_n), 
	.i_clk(i_AUD_BCLK),
	.i_lrc(i_AUD_ADCLRCK),
	.i_start(recorder_start),
	.i_pause(recorder_pause),
	.i_stop(recorder_stop),
	.i_data(i_AUD_ADCDAT),
	.o_address(addr_record),
	.o_data(data_record),
);

always_comb begin
	// design your control here
	//default
	state_t = state_r

	//FSM
	case(state_r)
	S_INIT:if (init_finished) state_t = S_READY;
	S_READY:begin 
		recorder_stop = 0;
		player_stop = 0;
		if (i_key_0) begin //recorder start
			state_t = S_RECORD;
			recorder_start = 1;
		end
		if (i_key_1) begin
			state_t = S_PLAY;
			player_start = 1;
		end
	end
	S_RECORD:begin
		if (i_key_0) begin //recorder pause
			state_t = S_READY;
			recorder_start = 0;
			recorder_pause = 1;
		end
		
	end
	S_PLAY: begin
		if (i_key_1) begin //player pause
			state_t = S_PLAY_PAUSE;
			player_start = 0;
			player_pause = 1;
			player_stop = 0;
		end
		else if (i_key_2) begin //player stop
			state_t = S_READY;
			player_start = 0;
			player_pause = 0;
			player_stop = 1;
		end
	end
	S_PLAY_PAUSE:begin
		if (i_key_1) begin //player start again
			state_t = S_PLAY;
			player_start = 1;
			player_pause = 0;
			player_stop = 0;
		end
		if else (i_key_2) begin //player stop
			state_t = S_READY;
			player_start = 0;
			recorder_pause = 0;
			player_stop = 1;
		end
	end
end

always_ff @(posedge i_AUD_BCLK or posedge i_rst_n) begin
	if (!i_rst_n) begin
		
	end
	else begin
		
	end
end

endmodule