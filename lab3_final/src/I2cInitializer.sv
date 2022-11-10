module I2cInitializer (
    input i_rst_n,
    input i_clk,
    input i_start,
    output o_finished,
    output o_sclk,
    output o_sdat,
    output o_oen // you are outputing (you are not outputing only when you are "ack"ing.)
  );

  //state
  localparam S_IDLE = 0;
  localparam S_PREP = 1;
  localparam S_FINISH = 2;

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

  logic [23:0] data_r, data_w;
  logic [3:0] count_r, count_w;
  logic finished_r, finished_w;
  logic [1:0] state_r, state_w;

  //Acknowledge input
  logic ack_start_r, ack_start_w;
  logic ack_finished;
  //Acknowledge output
  logic scl;
  logic sda;
  logic oen;

  Acknowledge acknowledge0 (
                .i_rst_n(i_rst_n),
                .i_clk(i_clk),
                .i_start(ack_start_r),
                .i_data(data_r),
                .o_finished(ack_finished),
                .o_sclk(scl),
                .o_sdat(sda),
                .o_oen(oen)
              );
  //outputs
  assign o_finished = finished_r;
  assign o_sclk = scl;
  assign o_sdat = sda;
  assign o_oen = oen;

  always_comb
  begin
    //default
    state_w = state_r;
    count_w = count_r;
    data_w = data_r;
    ack_start_w = ack_start_r;
    finished_w = finished_r;

    case (state_r)
      S_IDLE:
      begin
        if (i_start)
        begin
          state_w = S_PREP;
          count_w = count_r + 1;
          data_w = INIT_SETTING[count_r];
          ack_start_w = 1;
          finished_w = 0;
        end
      end

      S_PREP:
      begin
        if (count_r < 10)
        begin
          if (ack_finished)
          begin
            count_w = count_r + 1;
            data_w = INIT_SETTING[count_r];
          end
        end
        if (count_r == 10) //finish all init_setting
        begin
          state_w = S_FINISH;
          count_w = 0;
        end
      end

      S_FINISH:
      begin
        state_w = S_IDLE;
        ack_start_w = 0;
        finished_w = 1;
      end
    endcase
  end


  always_ff @(posedge i_clk or negedge i_rst_n)
  begin
    if(!i_rst_n)
    begin
      state_r <= S_IDLE;
      count_r <= 0;
      data_r <= 0;
      ack_start_r <= 0;
      finished_r <= 0;
    end
    else
    begin
      state_r <= state_w;
      count_r <= count_w;
      data_r <= data_w;
      ack_start_r <= ack_start_w;
      finished_r <= finished_w;

    end
  end
endmodule

module Acknowledge (
    input i_rst_n,
    input i_clk,
    input i_start,
    input [23:0] i_data,
    output o_finished,
    output o_sclk,
    output o_sdat,
    output o_oen // you are outputing (you are not outputing only when you are "ack"ing.)
  );

  //state
  localparam S_IDLE = 0;
  localparam S_PREP = 1;
  localparam S_ACK = 2;
  localparam S_FINISH = 3;

  logic [1:0] state_r, state_w;
  logic  [23:0] i_data_r, i_data_w;
  logic         scl_r, scl_w;
  logic         sda_r, sda_w;
  logic         ack_r, ack_w;
  logic         o_finished_r, o_finished_w;
  //counter
  logic [1:0] count_byte_r, count_byte_w;
  logic [3:0] count_bit_r, count_bit_w;

  //output
  assign o_finished = o_finished_r;
  assign o_sclk = scl_r;
  assign o_sdat = ack_r ? sda_r : 1'bz;
  assign o_oen = ack_r; //might be !ack_r


  always_comb
  begin
    //default
    state_w      = state_r;
    i_data_w     = i_data_r;
    scl_w        = scl_r;
    sda_w      = sda_r;
    ack_w       = ack_r;
    o_finished_w = o_finished_r;
    count_byte_w   = count_byte_r;
    count_bit_w    = count_bit_r;

    case (state_r)
      S_IDLE:
      begin
        if (i_start)
        begin
          state_w = S_PREP;
          i_data_w = i_data;
          sda_w = 0;
          count_bit_w = 0;
          count_byte_w = 0;
          o_finished_w = 0;

        end
      end
      S_PREP:
      begin
        scl_w = 0;
        if (!scl_r)
        begin
          state_w = S_ACK;
          sda_w = i_data_r[23];
          i_data_w = i_data_r << 1;
        end
      end
      S_ACK:
      begin
        if (scl_r == 0)
        begin //BLUE
          scl_w = 1;
        end
        else if (scl_r == 1)
        begin //GREEN
          count_bit_w = count_bit_r + 1;
          scl_w = 0;
          if (count_bit_r < 7)
          begin
            sda_w = i_data_r[23];
            i_data_w = i_data_r << 1;
          end
          else if (count_bit_r == 7)
          begin
            ack_w = 0;
          end
          else if (count_bit_r == 8 && count_byte_r != 2)
          begin
            count_byte_w = count_byte_r + 1;
            ack_w = 1;
            sda_w = i_data_r[23];
            count_bit_w = 0;
            i_data_w = i_data_r << 1;
          end
          else if (count_bit_r == 8 && count_byte_r == 2)
          begin
            ack_w = 1;
            sda_w = 0;
            state_w = S_FINISH;
          end
        end
      end
      S_FINISH:
      begin
        scl_w = 1;
        if (scl_r)
        begin
          state_w = S_IDLE;
          sda_w = 1;
          o_finished_w = 1;
        end
      end
    endcase
  end

  always_ff @(posedge i_clk or negedge i_rst_n)
  begin
    if(!i_rst_n)
    begin
      state_r <= S_IDLE;
      i_data_r <= 24'b0011_0100_000_1111_0_0000_0000; // reset;
      scl_r <= 1;
      sda_r <= 1;
      ack_r <= 1;
      count_byte_r <= 0;
      count_bit_r  <= 0;
      o_finished_r <= 0;
    end
    else
    begin
      state_r <= state_w;
      i_data_r <= i_data_w;
      scl_r <= scl_w;
      sda_r <= sda_w;
      ack_r <= ack_w;
      count_byte_r <= count_byte_w;
      count_bit_r <= count_bit_w;
      o_finished_r <= o_finished_w;
    end
  end
endmodule