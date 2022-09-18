module Top (
    input        i_clk,
    input        i_rst_n,
    input        i_start,
    output [3:0] o_random_out
  );

  // ===== States =====
  parameter S_IDLE = 1'b0;
  parameter S_PROC = 1'b1;

  // ===== Output Buffers =====
  logic [3:0] o_random_out_r, o_random_out_w;

  // ===== Registers & Wires =====
  logic state_r, state_w;
  //logic feedback;
  logic [3:0] seed_r, seed_w;
  logic [26:0] count_r, count_w;

  // ===== Output Assignments =====
  assign o_random_out = o_random_out_r;

  // ===== Combinational Circuits =====
  always_comb
  begin
    // Default Values
    o_random_out_w = o_random_out_r;
    state_w        = state_r;
    count_w = count_r;
    seed_w = seed_r;
    // FSM
    case(state_r)
      S_IDLE:
      begin
        if (i_start)
        begin
          state_w = S_PROC;
          count_w = count_r;
          //o_random_out_w = 4'd15;
          o_random_out_w = seed_r;
          count_w = 27'd1;
        end
        else 
        begin
          state_w        = state_r;
          o_random_out_w = o_random_out_r;
          count_w = count_r;
          seed_w = {(seed_r[3] ^ seed_r[0]), seed_r[3:1]};
        end
      end

      S_PROC:
      begin
        state_w = (count_r[26:23] == 4'd15) ? S_IDLE : state_w;
        seed_w = {(seed_r[3] ^ seed_r[0]), seed_r[3:1]};
        if(count_r[26:23] < 4'd15)
        begin
          //feedback=o_random_out_r[3]^o_random_out_r[0];
          o_random_out_w = o_random_out_r;
          //if (count_r == 27'd4)
          //begin
          //  seed_w = o_random_out_r;
          //end
          if((count_r[26:23] == 4'd1)||(count_r[26:23] == 4'd2)||(count_r[26:23] == 4'd4)||(count_r[26:23] == 4'd7)||(count_r[26:23] == 4'd10)||(count_r[26:23] == 4'd14))
          begin
            if(count_r[22:0] == 23'd0)
            begin
              //o_random_out_w = {feedback,o_random_out_r[3:1]};
              o_random_out_w = {o_random_out_r[3]^o_random_out_r[0],o_random_out_r[3:1]};
            end
            else
            begin
              o_random_out_w = o_random_out_r;
            end
          end
          count_w = count_r + 27'd1;
        end
        else
        begin
          o_random_out_w = o_random_out_r;
          count_w = count_r;
        end
      end

    endcase
  end

  // ===== Sequential Circuits =====
  always_ff @(posedge i_clk or negedge i_rst_n)
  begin
    // reset
    if (!i_rst_n)
    begin
      o_random_out_r <= 4'd0;
      state_r        <= S_IDLE;
      count_r <= 27'd0;
      seed_r <= 4'd15;
    end
    else
    begin
      o_random_out_r <= o_random_out_w;
      state_r        <= state_w;
      count_r <= count_w;
      seed_r <= seed_w;
    end
  end

endmodule
