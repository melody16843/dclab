module Rsa256Core (
    input          i_clk,
    input          i_rst,
    input          i_start,
    input  [255:0] i_a, // cipher text y
    input  [255:0] i_d, // private key
    input  [255:0] i_n,
    output [255:0] o_a_pow_d, // plain text x
    output         o_finished
  );

  // operations for RSA256 decryption
  // namely, the Montgomery algorithm
  parameter S_IDLE = 2'd0;
  parameter S_PREP = 2'd1;
  parameter S_MONT = 2'd2;
  parameter S_CALC = 2'd3;

  logic [1:0] state_r, state_w;
  logic [255:0] o_m_r, o_m_w;
  logic [255:0] t_r, t_w;
  logic [15:0] count_r, count_w;

  // ModuloProduct output wire
  logic [255:0] initial_t;
  logic mod_finish;
  // Mont_m, Mont_t input wire
  logic start_mont_w, start_mont_r;
  logic [255:0] Mont_m_a_r, Mont_m_a_w;
  logic [255:0] Mont_t_a_r, Mont_t_a_w;
  // Mont_m, Mont_t output wire
  logic [255:0]   o_Mont_m, o_Mont_t;
  logic           o_Mont_m_finish, o_Mont_t_finish;

  assign o_finished = (state_r == S_CALC && count_r == 16'd256) ? 1'b1 : 1'b0;
  assign o_a_pow_d = o_m_r;

  ModuloProduct mod0(
                  .i_clk(i_clk),
                  .i_rst(i_rst),
                  .i_start(i_start),
                  .i_y(i_a),
                  .i_n(i_n),
                  .mod_output(initial_t),
                  .o_finished(mod_finish));

  MontgemoryAlgorithm  Mont_m(
                         .i_clk(i_clk),
                         .i_start(start_mont_r),
                         .i_rst(i_rst),
                         .i_N(i_n),
                         .i_a(Mont_m_a_w),
                         .i_b(t_w),
                         .o_m(o_Mont_m),
                         .o_finished(o_Mont_m_finish));

  MontgemoryAlgorithm  Mont_t(
                         .i_clk(i_clk),
                         .i_start(start_mont_r),
                         .i_rst(i_rst),
                         .i_N(i_n),
                         .i_a(Mont_t_a_w),
                         .i_b(t_w),
                         .o_m(o_Mont_t),
                         .o_finished(o_Mont_t_finish));

  //combinational circuits
  always_comb
  begin
    state_w = state_r;
    count_w = count_r;
    start_mont_w = start_mont_r;
    o_m_w = o_m_r;
    t_w = t_r;
    Mont_m_a_w = Mont_m_a_r;
    Mont_t_a_w = Mont_t_a_r;

    case (state_r)
      S_IDLE:
      begin
        if(i_start)
        begin
          state_w = S_PREP;
          count_w = 0 ;
        end
      end
      S_PREP:
      begin
        if(mod_finish)
        begin
          t_w = initial_t ;
          o_m_w = 1 ;
          state_w = S_MONT;
          Mont_m_a_w = t_w;
          if(i_d[0])
            Mont_t_a_w = o_m_w;
          start_mont_w = 1 ;
        end
        else
        begin
          state_w = state_r;
        end
      end
      S_MONT:
      begin
        start_mont_w = 0;
        if(o_Mont_m_finish)
        begin
          state_w = S_CALC;
          count_w = count_r + 1 ;
          if (i_d[count_r])
            o_m_w = o_Mont_t ;
          t_w = o_Mont_m ;
        end
        else
          state_w = state_r ;

      end
      S_CALC:
      begin
        if(count_r < 16'd256)
        begin
          state_w= S_MONT ;
          start_mont_w = 1 ;
          if(i_d[count_r] == 1'b1)
            Mont_t_a_w=o_m_r;
          Mont_m_a_w=t_r;
        end
        else
        begin
          state_w = S_IDLE;
        end
      end

      default
      begin
        state_w = 0;
        count_w = 0;
        start_mont_w = 0;
        o_m_w = 1;
        t_w = 0;
        Mont_m_a_w = 1;
        Mont_t_a_w = 0;
      end
    endcase
  end
  //sequential circuits
  always_ff @( posedge i_clk or posedge i_rst )
  begin
    if (i_rst)
    begin
      state_r <=0;
      start_mont_r<=0;
      t_r<=0;
      o_m_r<=0;
      count_r<=0;
      Mont_m_a_r<=0;
      Mont_t_a_r<=0;
    end
    else
    begin
      state_r <=state_w;
      start_mont_r<=start_mont_w;
      t_r<=t_w;
      o_m_r<=o_m_w;
      count_r<=count_w;
      Mont_m_a_r<=Mont_m_a_w;
      Mont_t_a_r<=Mont_t_a_w;
    end
  end

endmodule

module ModuloProduct (
    input   i_clk,
    input   i_rst,
    input   i_start,
    input   [255:0] i_y,
    input   [255:0] i_n,
    output  [255:0] mod_output,
    output  o_finished
  );

  parameter S_IDLE = 1'd0;
  parameter S_PROC = 1'd1;
  logic state_r, state_w;
  logic finish_w, finish_r;
  logic [257:0] output_w, output_r;
  logic [257:0] t_w, t_r;
  logic [9:0] count_w, count_r;

  assign o_finished = finish_r ;
  assign mod_output = output_r[255:0];

  always_comb
  begin
    state_w = state_r ;
    output_w = output_r ;
    t_w = t_r ;
    count_w = count_r ;
    finish_w = finish_r ;

    case(state_r)
      S_IDLE :
      begin
        if(i_start)
        begin
          state_w = 1 ;
          output_w = 0 ;
          t_w = {2'b0, i_y} ;
          count_w = 0 ;
          finish_w = 0 ;
        end
      end

      S_PROC:
      begin
        if(t_r+t_r > i_n)
          t_w = t_r + t_r - i_n ;
        else
          t_w = t_r + t_r ;
        if(count_r == 10'd256)
        begin
          if(output_r+t_r >= i_n)
          begin
            output_w = output_r + t_r - i_n ;
          end
          else
          begin
            output_w = output_r + t_r ;
          end
          state_w  = 0 ;
          finish_w = 1 ;
        end
        count_w = count_r + 1 ;

      end
    endcase
  end

  // sequential circuits
  always_ff @(posedge i_clk or negedge i_rst)
  begin
    if(i_rst)
    begin
      state_r <= 0;
      output_r <= 0;
      t_r <= 0;
      count_r <= 0;
      finish_r <= 0;
    end
    else
    begin
      state_r <= state_w;
      output_r <= output_w;
      t_r <= t_w;
      count_r <= count_w;
      finish_r <= finish_w;
    end
  end
endmodule


module MontgemoryAlgorithm (
    input   i_clk,
    input   i_start,
    input   i_rst,
    input   [255:0] i_N,
    input   [255:0] i_a,
    input   [255:0] i_b,
    output  [255:0] o_m,
    output  o_finished
  );

  parameter S_IDLE = 1'd0;
  parameter S_PROC = 1'd1;
  logic state_w, state_r;
  logic finish_w, finish_r;
  logic [257:0] o_m_w, o_m_r;
  logic [15:0] count_r, count_w;
  logic [257:0] tmp1;
  logic [256:0] tmp2;

  assign o_finished = finish_r;
  assign o_m = o_m_r[255:0] ;

  always_comb
  begin
    // Default Value //
    state_w = state_r ;
    o_m_w = o_m_r ;
    count_w = count_r ;
    finish_w = 0 ;
    tmp1 = o_m_r ;
    tmp2 = o_m_r ;

    case(state_r)
      S_IDLE :
      begin
        o_m_w = 0 ;
        count_w = 0 ;
        finish_w = 0 ;
        tmp1 = 0 ;
        tmp2 = 0 ;
        if(i_start)
        begin
          state_w = 1 ;
        end
      end

      S_PROC:
      begin
        if(i_a[count_r] == 1'b1)
        begin
          tmp1 = o_m_r + i_b + ((o_m_r[0]^i_b[0])? i_N:0);
          o_m_w = (o_m_r + i_b + ((o_m_r[0]^i_b[0])? i_N:0)) >> 1 ;
        end
        else
        begin
          tmp1 = o_m_r + ((o_m_r[0])? i_N:0);
          o_m_w =(o_m_r + ((o_m_r[0])? i_N:0))>>1 ;
        end
        tmp2 = tmp1 >> 1 ;

        if(count_r == 16'd255)
        begin
          o_m_w = tmp2 - (tmp2 >= i_N? i_N : 0) ;
          /*
          if(o_m_r >= i_N)
          begin
            o_m_w = o_m_r - i_N;
          end
          else
            o_m_w = o_m_r;
          */
          state_w  = 0 ;
          finish_w = 1 ;
        end
        else
          count_w = count_r + 1 ;
      end
    endcase
  end

  // sequential circuits
  always_ff @(posedge i_clk or negedge i_rst)
  begin
    if(i_rst)
    begin
      state_r <= 0;
      o_m_r <= 0;
      count_r <= 0;
      finish_r <= 0;
    end
    else
    begin
      state_r <= state_w;
      o_m_r <= o_m_w;
      count_r <= count_w;
      finish_r <= finish_w;
    end
  end
endmodule