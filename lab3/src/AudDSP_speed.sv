module AudDSP(
    input i_rst_n,
    input i_clk,
    input i_start,
    input i_pause,
    input i_stop,
    input [3:0] i_speed,
    input i_fast,
    input i_slow_0, // constant interpolation
    input i_slow_1, // linear interpolation
    input i_daclrck,
    input [15:0] i_sram_data,
    output [15:0] o_dac_data,
    output [19:0] o_sram_addr
  );

  localparam max_addr = 20'b11111111111111111111;
  //state
  localparam S_IDLE = 3'd0;
  localparam S_FAST = 3'd1;
  localparam S_SLOW0 = 3'd2;
  localparam S_SLOW1 = 3'd3;
  localparam S_PAUSE = 3'd4;
  localparam S_PREP = 3'd5;

  logic signed [15:0] dac_r, dac_w;
  logic signed [15:0] pre_r, pre_w;
  logic [2:0] count_r, count_w;
  logic [19:0] sram_addr_r, sram_addr_w;
  logic [2:0]  state_r, state_w;

  logic pre_daclrck;

  assign o_sram_addr = sram_addr_w;
  assign o_dac_data = dac_r;

  always_comb
  begin
    //default
    state_w = state_r;
    dac_w = dac_r;
    pre_w = pre_r;
    sram_addr_w = sram_addr_r;
    count_w = count_r;

    if(i_start)
    begin
      if(i_fast)
        state_w = S_FAST;
      else if(i_slow_0)
        state_w = S_SLOW0;
      else if(i_slow_1)
        state_w = S_SLOW1;
      else
        state_w = S_FAST;
    end
    else if(i_pause)
    begin
      state_w = S_PAUSE;
    end

    //state
    case(state_r)
      S_IDLE:
      begin
        if(i_start)
        begin
          sram_addr_w = 0;
          count_w = 0;
          pre_w = 0;
        end
      end

      S_FAST :
      begin
        dac_w = signed'(i_sram_data);
        sram_addr_w = sram_addr_w + i_speed + 1;
        state_w = S_PREP;
        if(sram_addr_w >= max_addr - i_speed - 1)
        begin
          sram_addr_w = max_addr;
        end
        if(sram_addr_w >= max_addr)
        begin
          state_w = S_IDLE;
        end
      end

      S_SLOW0 :
      begin
        state_w = S_PREP;
        dac_w = signed'(i_sram_data);
        if(count_w == i_speed)
        begin
          count_w = 0;
          sram_addr_w = sram_addr_w + 1;
        end
        else
        begin
          count_w = count_w + 1;
        end

        if(sram_addr_w >= max_addr)
        begin
          state_w = S_IDLE;
        end
      end

      S_SLOW1 :
      begin
        state_w = S_PREP;
        dac_w = (signed'(count_w)*signed'(i_sram_data) + (signed'(i_speed)-signed'(count_w)+1)*pre_w) / signed'(i_speed+1);
        if(count_w == i_speed)
        begin
          pre_w = signed'(i_sram_data);
          sram_addr_w = sram_addr_w + 1;
          count_w = 0;
        end
        else
        begin
          count_w = count_w + 1;
        end

        if(sram_addr_w >= max_addr)
        begin
          state_w = S_IDLE;
        end
      end

      S_PAUSE :
      begin

      end

      S_PREP :
      begin
        if((!pre_daclrck) && i_daclrck)
        begin
          if(i_fast)
            state_w = S_FAST;
          else if(i_slow_0)
            state_w = S_SLOW0;
          else if(i_slow_1)
            state_w = S_SLOW1;
          else
            state_w = S_FAST;
        end
      end
    endcase

  end

  always_ff @(posedge i_clk or negedge i_rst_n or posedge i_stop)
  begin
    if((!i_rst_n) || i_stop)
    begin
      state_r <= S_IDLE ;
      dac_r <= 0 ;
      pre_r <= 0 ;
      sram_addr_r <= 0 ;
      count_r <= 0 ;
      pre_daclrck <= i_daclrck ;
    end
    else
    begin
      state_r <= state_w ;
      dac_r <= dac_w ;
      pre_r <= pre_w ;
      sram_addr_r <= sram_addr_w ;
      count_r <= count_w ;
      pre_daclrck <= i_daclrck ;
    end
  end
endmodule
