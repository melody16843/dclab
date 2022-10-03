module ModuloProduct(
    input          i_clk,
    input          i_rst,
    input          i_start,
    input  [255:0] i_y, // cipher text y
    input  [255:0] i_n,
    output [257:0] mod_output,
    output         o_finished
  );

  logic [9:0] count_w, count_r;
  logic [257:0] t_w, t_r;
  logic [1:0] state_r, state_w;
  logic [257:0] output_w, output_r;
  logic finish_w, finish_r;

  assign mod_output = output_r;
  // assign o_finished = finish_r;
  assign o_finished = (count_r == 10'd257) ? 1'd1 : 1'd0;

  parameter S_IDLE = 1'd0;
  parameter S_PROC = 1'd1;
  parameter S_FINI = 2'd2;

  always_comb
  begin
    //default value
    count_w = count_r;
    t_w = t_r;
    state_w = state_r;
    output_w = output_r;
    finish_w = finish_r;

    //FSM
    case(state_r)
      S_IDLE:
      begin
        if(i_start)
        begin
          count_w = count_r;
          state_w = S_PROC;
          output_w = output_r;
          t_w = i_y;
        end
        else
        begin
          count_w = count_r;
          state_w = state_r;
          output_w = output_r;
          t_w = t_r;
        end
      end

      S_PROC:
      begin
        if(count_r<10'b100000001)
        begin
          if (count_r == 10'b100000000)
          begin
            state_w = S_FINI;
            if(output_w+t_r>i_n)
              output_w = output_r+t_r-i_n;
            else
              output_w = output_r+t_r;
          end
          else
          begin
            state_w = state_r;
            output_w = output_r;
          end
          count_w = count_r +10'b1;
        end
        else
        begin
          count_w = count_r;
          state_w = state_r;
          output_w = output_r;
        end

        if(t_r+t_r>i_n)
        begin
          t_w = t_r +t_r - i_n;
        end
        else
        begin
          t_w = t_r +t_r;
        end
      end

      S_FINI:
      begin
        finish_w = 1'b1;
        state_w = S_IDLE;
      end
    endcase


  end


  always_ff @(posedge i_clk or posedge i_rst)
  begin
    // reset
    if (i_rst || finish_r)
    begin
      t_r <= 257'd0;
      output_r <= 257'd0;
      state_r  <= S_IDLE;
      count_r <= 10'd0;
      finish_r <= 1'b0;
    end
    else
    begin
      t_r <= t_w;
      output_r <= output_w;
      state_r  <= state_w;
      count_r <= count_w;
      finish_r <= finish_w;
    end
  end


endmodule

// my version
/*
module ModuloProduct (
    input i_clk,
    input i_rst,
    input [255:0] n,
    input [255:0] i_a,
    input [255:0] i_b,
    input [255:0] i_k, // k is # of bits of a
    output [257:0] o_m
  );
  logic [257:0] o_m_r, o_m_w;
  logic [257:0] t_r, t_w;
  logic [255:0] count_r, count_w;  //counter from 0 to i_k
 
  assign o_m = o_m_r;
 
  // combinational circuits
  always_comb
  begin
    if(count_r <= i_k)
    begin
      if (i_a[count_r] == 1'd1)
      begin // count_r-th bit of d is 1
        o_m_w = ((o_m_r + t_r)>=n) ? (o_m_r + t_r - n) : (o_m_r + t_r);
      end
      else
      begin
        o_m_w = o_m_r;
      end
      t_w = (t_r*2 > n) ? (2*t_r - n) : (2*t_r);
      count_w = count_r + 256'd1;
    end
    else
    begin
      o_m_w = o_m_r;
      t_w = t_r;
      count_w = count_r ;
    end
  end
 
  // sequential circuits
  always_ff @(posedge i_clk or negedge i_rst)
  begin
    // reset
    if (i_rst)
    begin
      t_r <= {2'd0,i_b}; // # of bits are different
      o_m_r <= 258'd0;
      count_r <= 256'd0;
    end
    else
    begin
      t_r <= t_w;
      o_m_r <= o_m_w;
      count_r <= count_w;
    end
  end
endmodule
*/
