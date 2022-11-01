module Top_speed (
    input i_rst_n,
    input i_clk,
    input i_key_0,
    input i_key_1,
    input i_key_2,
    input [3:0] i_speed, // design how user can decide mode on your own
    input i_fast,
    input i_slow_0,
    input i_slow_1,

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
    output o_AUD_DACDAT,

    //output [3:0] state

    // SEVENDECODER (optional display)
    output [5:0] o_record_time,
    output [5:0] o_play_time

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
  // parameter S_IDLE       = 0;
  // parameter S_I2C        = 1;
  // parameter S_RECD       = 2;
  // parameter S_RECD_PAUSE = 3;
  // parameter S_PLAY       = 4;
  // parameter S_PLAY_PAUSE = 5;

  logic i2c_oen, i2c_sdat;
  logic [19:0] addr_record, addr_play;
  logic [15:0] data_record, data_play, dac_data;
  logic [19:0] o_count;
  logic [19:0] final_address;


  parameter S_INIT = 4'd0;
  parameter S_READY = 4'd1;
  parameter S_RECORD = 4'd2;
  parameter S_PLAY = 4'd3;
  parameter S_PLAY_PAUSE = 4'd4;
  parameter S_PLAY_FAST = 4'd5;
  parameter S_PLAY_SLOW = 4'd6;

  //control var
  logic [3:0] state_t, state_r;

  //test section
  logic [3:0] state_dsp;
  // assign state = address_end;
  logic [3:0] state_play;
  // assign state = player_en;
  // assign state = state_i2c;
  assign o_record_time = (state_r == S_RECORD) ? addr_record[19:14] : 6'd0;
  assign o_play_time = (state_r == S_PLAY) ? addr_play[19:14] : 6'd0;
  
  assign io_I2C_SDAT = (i2c_oen) ? i2c_sdat : 1'bz;

  assign o_SRAM_ADDR = (state_r == S_RECORD) ? addr_record : addr_play[19:0];
  assign io_SRAM_DQ  = (state_r == S_RECORD) ? data_record : 16'dz; // sram_dq as output
  assign data_play   = (state_r != S_RECORD) ? io_SRAM_DQ : 16'd0; // sram_dq as input

  assign o_SRAM_WE_N = (state_r == S_RECORD) ? 1'b0 : 1'b1;
  assign o_SRAM_CE_N = 1'b0;
  assign o_SRAM_OE_N = 1'b0;
  assign o_SRAM_LB_N = 1'b0;
  assign o_SRAM_UB_N = 1'b0;

  assign final_address = o_count;

  // below is a simple example for module division
  // you can design these as you like


  //init var
  logic init_finished;
  // assign init_finished = init_finished_r;

  //recorder var
  logic recorder_start, recorder_start_r, recorder_start_t;
  logic recorder_pause, recorder_pause_r, recorder_pause_t;
  logic recorder_stop, recorder_stop_r, recorder_stop_t;
  assign recorder_start = recorder_start_r;
  assign recorder_pause = recorder_pause_r;
  assign recorder_stop = recorder_stop_r;

  //player var
  logic player_start, player_start_r, player_start_t;
  logic player_pause, player_pause_r, player_pause_t;
  logic player_stop, player_stop_r, player_stop_t;
  logic player_fast, player_fast_r, player_fast_t;
  logic player_slow, player_slow_r, player_slow_t;
  logic player_slow1, player_slow1_r, player_slow1_t;
  logic player_en, player_en_r, player_en_t;
  assign player_start = player_start_r;
  assign player_pause = player_pause_r;
  assign player_stop = player_stop_r;
  assign player_fast = player_fast_r;
  assign player_slow = player_slow_r;
  assign player_slow1 = player_slow1_r;
  assign player_en = player_en_r;

  logic address_end_r, address_end_t, address_end;
  // assign address_end_r = address_end;

  //key up
  logic key_0_up_r, key_0_up_t;
  logic key_1_up_r, key_1_up_t;
  logic key_2_up_r, key_2_up_t;



  // === I2cInitializer ===
  // sequentially sent out settings to initialize WM8731 with I2C protocal
  I2cInitializer init0(
                   .i_rst_n(i_rst_n),
                   .i_clk(i_clk_100k),
                   //.i_start(!i_rst_n),
                   .i_start(1'd1),
                   .o_finished(init_finished),
                   .o_sclk(o_I2C_SCLK),
                   .o_sdat(i2c_sdat),
                   .o_oen(i2c_oen)// you are outputing (you are not outputing only when you are "ack"ing.)
                  //  .state_i2c(state_i2c)
                 );

  // === AudDSP ===
  // responsible for DSP operations including fast play and slow play at different speed
  // in other words, determine which data addr to be fetch for player
  AudDSP_0 dsp0(
           .i_rst_n(i_rst_n),
           .i_clk(i_AUD_BCLK),
           .i_start(player_start),
           .i_pause(player_pause),
           .i_stop(player_stop),
           .i_speed(i_speed),
           .i_fast(i_fast),
           .i_slow_0(i_slow_0), // constant interpolation
           .i_slow_1(i_slow_1), // linear interpolation
           .i_daclrck(i_AUD_DACLRCK),
           .i_sram_data(data_play),
           .o_dac_data(dac_data),
           .o_sram_addr(addr_play),
           .i_final_address(final_address),
           .o_final(address_end)
           // .state_dsp(state_dsp)
         );

  // === AudPlayer ===
  // receive data address from DSP and fetch data to sent to WM8731 with I2S protocal
  AudPlayer player0(
              .i_rst_n(i_rst_n),
              .i_bclk(i_AUD_BCLK),
              .i_daclrck(i_AUD_DACLRCK),
              .i_en(player_en), // enable AudPlayer only when playing audio, work with AudDSP
              .i_dac_data(dac_data), //dac_data
              .o_aud_dacdat(o_AUD_DACDAT),
              .state_play(state_play)
            );

  // === AudRecorder ===
  // receive data from WM8731 with I2S protocal and save to SRAM
  AudRecorder recorder0(
                .i_rst_n(i_rst_n),
                .i_clk(i_AUD_BCLK),
                .i_lrc(i_AUD_ADCLRCK),
                .i_start(recorder_start),
                .i_pause(recorder_stop),
                .i_stop(recorder_stop),
                .i_data(i_AUD_ADCDAT),
                .o_address(addr_record),
                .o_data(data_record),
                .o_count(o_count),
                .state_recorder(state_recorder)
              );

  always_comb
  begin
    // design your control here
    //default
    state_t = state_r;
    // init_finished_t = init_finished_r;
    recorder_start_t = recorder_start_r;
    recorder_pause_t = recorder_pause_r;
    recorder_stop_t = recorder_stop_r;
    player_start_t = player_start_r;
    player_pause_t = player_pause_r;
    player_stop_t = player_stop_r;
    player_fast_t = player_fast_r;
    player_slow_t = player_slow_r;
    player_slow1_t = player_slow1_r;
    player_en_t = player_en_r;
    key_0_up_t = key_0_up_r;
    key_1_up_t = key_1_up_r;
    key_2_up_t = key_2_up_r;
    // address_end_t = address_end_r;


    //FSM
    case(state_r)
      S_INIT:
        if (init_finished)
          state_t = S_READY;
      S_READY:
      begin
        recorder_stop_t = 0;
        player_stop_t = 0;
        if(!i_key_0)
          key_0_up_t = 1;
        if(!i_key_1)
          key_1_up_t = 1;
        if (i_key_0 && key_0_up_r)
        begin //recorder start
          state_t = S_RECORD;
          recorder_start_t = 1;
          key_0_up_t = 0;
        end
        else if (i_key_1 && key_1_up_r)
        begin
          state_t = S_PLAY;
          player_start_t = 1;
          key_1_up_t = 0;
          player_en_t = 1;
        end
      end
      S_RECORD:
      begin
        if (!i_key_0)
        begin
          key_0_up_t = 1;
          recorder_start_t = 0;
        end
        if (i_key_0 && key_0_up_r)
        begin //recorder pause
          state_t = S_READY;
          recorder_start_t = 0;
          recorder_stop_t = 1;
          key_0_up_t = 0;
        end

      end
      S_PLAY:
      begin
        if(!i_key_1)
        begin
          key_1_up_t = 1;
          player_start_t = 0;
        end
        if(!i_key_0)
        begin
          player_fast_t = 0;
          state_t = S_PLAY;
          key_0_up_t = 1;
        end
        if (!i_key_2)
        begin
          player_slow_t = 0;
          state_t = S_PLAY;
          key_2_up_t = 1;
        end
        if (i_key_1 && key_1_up_r)
        begin //player pause
          state_t = S_PLAY_PAUSE;
          player_start_t = 0;
          player_pause_t = 1;
          key_1_up_t = 0;
          player_en_t = 0;
        end
        // else if (i_key_0 && key_0_up_r)
        // begin //player faster
        //   state_t = S_PLAY;
        //   player_fast_t = 1;
        //   key_0_up_t = 0;

        // end
        // else if (i_key_2 && key_2_up_r)
        // begin //player slower
        //   state_t = S_PLAY;
        //   player_slow_t = 1;
        //   key_2_up_t = 0;
        // end

        if (address_end)
        begin
          player_en_t = 0;
          state_t = S_READY;
        end

      end
      S_PLAY_FAST:
      begin
        if(!i_key_0)
        begin
          player_fast_t = 0;
          state_t = S_PLAY;
          key_0_up_t = 1;
        end
      end
      S_PLAY_SLOW:
      begin
        if (!i_key_2)
        begin
          player_slow_t = 0;
          state_t = S_PLAY;
          key_2_up_t = 1;
        end
      end
      S_PLAY_PAUSE:
      begin
        if(!i_key_1)
        begin
          key_1_up_t = 1;
          player_pause_t = 0;
          player_en_t = 0;
        end
        if(!i_key_2)
          key_2_up_t = 1;

        if (i_key_1 && key_1_up_r)
        begin //player start again
          state_t = S_PLAY;
          player_start_t = 1;
          player_pause_t = 0;
          player_stop_t = 0;
          key_1_up_t = 0;
          player_en_t = 1;
        end
        else if (i_key_2 && key_2_up_r)
        begin //player stop
          state_t = S_READY;
          player_start_t = 0;
          recorder_pause_t = 0;
          player_stop_t = 1;
        end
      end
    endcase
  end

  always_ff @(posedge i_AUD_BCLK or negedge i_rst_n)
  begin
    if (!i_rst_n)
    begin
      state_r <= S_INIT;
      // init_finished <= 0;
      recorder_start_r <= 0;
      recorder_pause_r <= 0;
      recorder_stop_r <= 0;
      player_start_r <= 0;
      player_pause_r <= 0;
      player_stop_r <= 0;
      player_fast_r <= 0;
      player_slow_r <= 0;
      player_slow1_r <= 0;
      player_en_r <= 0;
      key_0_up_r <= 1;
      key_1_up_r <= 1;
      key_2_up_r <= 1;
      // address_end_r <=0;
    end
    else
    begin
      state_r <= state_t;
      recorder_start_r <= recorder_start_t;
      recorder_pause_r <= recorder_pause_t;
      recorder_stop_r <= recorder_stop_t;
      player_start_r <= player_start_t;
      player_pause_r <= player_pause_t;
      player_stop_r <= player_stop_t;
      player_fast_r <= player_fast_t;
      player_slow_r <= player_slow_t;
      player_slow1_r <= player_slow1_t;
      player_en_r <= player_en_t;
      key_0_up_r <= key_0_up_t;
      key_1_up_r <= key_1_up_t;
      key_2_up_r <= key_2_up_t;
      // address_end_r <= address_end_t;

    end
  end

endmodule