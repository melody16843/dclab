module I2cInitializer(
    input i_rst_n,
    input i_clk,
    input i_start,
    output o_finished,
    output o_sclk,
    output o_sdat,
    output o_oen
  );

  //state
  parameter S_IDLE = 3'd0;
  parameter S_PREP = 3'd1;
  parameter S_ACK1 = 3'd2;
  parameter S_ACK2 = 3'd3;
  parameter S_ACK_FINISH = 3'd4;

  parameter bit [23:0] INIT_SETTING [9:0] = '{
              24'b0011010_0_000_0000_0_1001_0111, //Left Line In
              24'b0011010_0_000_0001_0_1001_0111, //Right Line In
              24'b0011010_0_000_0010_0_0111_1001, //Left Headphone out
              24'b0011010_0_000_0011_0_0111_1001, //Right Headphone out
              24'b0011010_0_000_0100_0_0001_0101, //Analog Audio Path Control
              24'b0011010_0_000_0101_0_0000_0000, //Digital Audio Path Control
              24'b0011010_0_000_0110_0_0000_0000, //Power Down Control
              24'b0011010_0_000_0111_0_0100_0010, //Digital Audio Interface Format
              24'b0011010_0_000_1000_0_0001_1001, //Sampling Control
              24'b0011010_0_000_1001_0_0000_0001  //Active Control
            };

  logic sda_r, sda_w;
  logic scl_r, scl_w;
  logic finished_r, finished_w;
  logic [2:0] state_r, state_w;
  logic [5:0] counter_r, counter_w; //from 24 to 0
  logic [3:0] count_r, count_w; //from 1 to 10
  logic ack_r, ack_w;
  logic [23:0] data;
  logic sda_change_r, sda_change_w;
  logic ack_finished_r, ack_finished_w;

  assign o_sclk = scl_r;
  assign o_sdat = sda_r;
  assign o_finished = finished_r;
  assign o_oen = ack_r;

  always_comb
  begin
    //default
    sda_w = sda_r;
    scl_w = scl_r;
    finished_w = finished_r;
    state_w = state_r;
    count_w = count_r;
    ack_w = ack_r;
    counter_w = counter_r;
    sda_change_w = sda_change_r;
    ack_finished_w = ack_finished_r;
    if(count_r!=0)
      data = INIT_SETTING[count_r-1];
    else
      data = 24'd0;

    case (state_r)
      S_IDLE:
      begin
        if(count_r == 4'd0)
        begin
          if(i_start)
            state_w = S_PREP;
        end
        else
        begin
          if(scl_r == 1 && sda_r == 1)
          begin
            if (count_r == 4'd10)
            begin
              finished_w = 1;
            end
            else
            begin
              state_w = S_PREP;
            end
          end
          sda_change_w = ~sda_change_r;
          scl_w = 1;
          if(sda_change_r)
            sda_w = 1;

        end
      end

      S_PREP:
      begin
        state_w = S_ACK1;
        counter_w = 6'd24;
        sda_w = 0;
        scl_w = 1;
        count_w = 4'd1;
        if (count_r < 4'd10 && count_r > 4'd0)
        begin
          state_w = S_ACK1;
          counter_w = 6'd24;
          sda_w = 0;
          scl_w = 1;
          sda_change_w = 0;
          count_w = count_r + 1;
        end
      end

      S_ACK1:
      begin
        scl_w = 0;
        sda_change_w = ~sda_change_r;
        if(sda_change_r)
        begin
          if(counter_r == 6'd0)
          begin
            sda_w = 0;
            state_w = S_IDLE;
            ack_w = 1;
          end
          else
          begin
            sda_w = data[counter_r-1];
            state_w = S_ACK2;
            counter_w = counter_r - 1;
            ack_w = 1;
          end
        end
      end

      S_ACK2:
      begin
        scl_w = 1;
        sda_w = sda_r;
        sda_change_w = ~sda_change_r;
        if (counter_r == 6'd16 || counter_r == 6'd8 || counter_r == 6'd0)
        begin
          if(ack_finished_r != 0)
          begin
            if(sda_change_r)
            begin
              ack_finished_w = 0;
              state_w = S_ACK1;
            end
          end
          else
          begin
            if(sda_change_r)
            begin
              state_w = S_ACK_FINISH;
            end
          end
        end
        else
        begin
          if(sda_change_r)
          begin
            state_w = S_ACK1;
            ack_finished_w = 0;
          end
        end
      end

      S_ACK_FINISH:
      begin
        sda_change_w = ~sda_change_r;
        scl_w = 0;

        if(sda_change_r)
        begin
          ack_w = 0;
          sda_w = 1'dz;
          ack_finished_w = 1;
          state_w = S_ACK2;
        end
      end
      /*
      default:
        state_w = S_PREP;
      */
    endcase
  end

  always_ff @( posedge i_clk or negedge i_rst_n)
  begin
    if (!i_rst_n)
    begin
      state_r <= S_IDLE;
      finished_r <= 0;
      sda_r <= 1;
      scl_r <= 1;
      count_r <= 0;
      ack_r <= 1;
      counter_r <= 0;
      sda_change_r <= 0;
      ack_finished_r <= 0;
    end
    else
    begin
      state_r <= state_w;
      finished_r <= finished_w;
      sda_r <= sda_w;
      scl_r <= scl_w;
      count_r <= count_w;
      ack_r <= ack_w;
      counter_r <= counter_w;
      sda_change_r <= sda_change_w;
      ack_finished_r <= ack_finished_w;
    end
  end

endmodule
