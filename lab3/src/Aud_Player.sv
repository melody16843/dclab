module AudPlayer (
    input i_rst_n,
    input i_bclk,
    input i_daclrck,
    input i_en,
    input [15:0] i_dac_data,
    output o_aud_dacdat
  );

  logic data_w, data_r;
  logic [1:0] state_w, state_r;
  logic [4:0] counter_w, counter_r;
  logic [15:0] in_data_w, in_data_r;
  logic lrc_negedge_w, lrc_negedge_r;
  //logic input_taken;

  parameter S_IDLE = 2'b00;
  parameter S_LRC1 = 2'b01;
  parameter S_PLAY = 2'b10;

  assign o_aud_dacdat = data_r;


  always_comb
  begin
    data_w = data_r;
    state_w = state_r;
    counter_w = counter_r;
    lrc_negedge_w = i_daclrck;
    in_data_w = in_data_r;

    case(state_r)
      S_IDLE:
      begin
        if (i_en)
        begin
          state_w = S_LRC1;
        end
      end

      S_LRC1:
      begin
        in_data_w = i_dac_data;
        if(!i_daclrck && lrc_negedge_r)
        begin
          state_w = S_PLAY;
          counter_w = 5'b0;
          data_w = in_data_r[15];
          in_data_w = in_data_r << 1;
        end
      end

      S_PLAY:
      begin
        counter_w = counter_r + 1'b1;
        data_w = in_data_r[15];
        in_data_w = in_data_r << 1;
        if (counter_r >= 5'd15)
        begin
          state_w = S_LRC1;
          in_data_w = 16'b0;
        end
      end
      default:
        state_w = S_IDLE;
    endcase
  end


  always_ff @(posedge i_bclk or negedge i_rst_n)
  begin
    if (!i_rst_n)
    begin
      state_r <= S_IDLE;
      data_r <= 0;
      counter_r <= 5'd15;
      in_data_r <= 0;
      lrc_negedge_r <= 0;
    end
    else
    begin
      state_r <= state_w;
      data_r <= data_w;
      counter_r <= counter_w;
      in_data_r <= in_data_w;
      lrc_negedge_r <= lrc_negedge_w;
    end


  end
endmodule
