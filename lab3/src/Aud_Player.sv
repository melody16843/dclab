module AudPlayer (
    input i_rst_n,
    input i_bclk,
    input i_daclrck,
    input i_en,
    input [15:0] i_dac_data,
    output o_aud_dacdat
  );

  logic dac_data_w, dac_data_r;
  logic [4:0] count_w, count_r;

  logic [1:0] state_w, state_r;


  logic [15:0] in_dac_data_w, in_dac_data_r;
  logic lrc_negedge_w, lrc_negedge_r;


  parameter S_IDLE = 2'd0;
  parameter S_WAIT = 2'd1;
  parameter S_PLAY = 2'd2;

  assign o_aud_dacdat = dac_data_r;


  always_comb
  begin
    dac_data_w = dac_data_r;
    state_w = state_r;
    count_w = count_r;
    lrc_negedge_w = i_daclrck;
    in_dac_data_w = in_dac_data_r;

    case(state_r)
      S_IDLE:
      begin
        if (i_en)
        begin
          state_w = S_WAIT;
        end
      end

      S_WAIT:
      begin
        in_dac_data_w = i_dac_data;
        if(!i_daclrck && lrc_negedge_r)
        begin
          state_w = S_PLAY;
          count_w = 5'b0;
          dac_data_w = i_dac_data_r[4'd15-count_r];
          //dac_data_w = in_dac_data_r[15];
          //in_dac_data_w = in_dac_data_r << 1;
        end
      end

      S_PLAY:
      begin
        count_w = count_r + 1'b1;
        dac_data_w = i_dac_data_r[4'd15-count_r];
        //dac_data_w = in_dac_data_r[15];
        //in_dac_data_w = in_dac_data_r << 1;
        if (count_r >= 5'd15)
        begin
          state_w = S_WAIT;
          in_dac_data_w = 16'b0;
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
      dac_data_r <= 0;
      count_r <= 5'd15;
      in_dac_data_r <= 0;
      lrc_negedge_r <= 0;
    end
    else
    begin
      state_r <= state_w;
      dac_data_r <= dac_data_w;
      count_r <= count_w;
      in_dac_data_r <= in_dac_data_w;
      lrc_negedge_r <= lrc_negedge_w;
    end


  end
endmodule
