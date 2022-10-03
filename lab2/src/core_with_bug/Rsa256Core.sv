
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
  parameter S_MONT = 2'd1;
  //parameter S_FINI = 2'd2;

  logic [1:0] state_r, state_w;
  logic [257:0] o_m_r, o_m_w;
  logic [257:0] t_r, t_w;
  logic [15:0] count_r, count_w;  //counter from 0 to 255
  // ModuloProduct output wire
  //logic mod_start_r, mod_start_w;
  // ModuloProduct output wire
  logic [257:0] initial_t;
  logic mod_finish;
  // Mont_m output wire
  logic [257:0] o_Mont_m;
  // Mont_m output wire
  logic [257:0] o_Mont_t;

  assign o_finished = (count_r == 16'd256) ? 1'd1 : 1'd0;
  // assign o_a_pow_d = o_m_r[255:0];
  assign o_a_pow_d = o_m_r;
  /*
  ModuloProduct mod0(
                  .i_clk(i_clk),
                  .i_rst(i_rst),
                  .n(i_n),
                  .i_a(2**256), //2**256, do we need to specify 256 bits?
                  .i_b(i_a),
                  .i_k(256'd256),
                  .o_m(initial_t)
                );
  */
  ModuloProduct mod0(
                  .i_clk(i_clk),
                  .i_rst(i_rst),
                  .i_start(i_start), // might be wrong
                  .i_y(i_a),
                  .i_n(i_n),
                  .mod_output(initial_t),
                  .o_finished(mod_finish)
                );
  MontgemoryAlgorithm Mont_m(
                        .i_clk(i_clk),
                        .i_rst(i_rst),
                        .i_N(i_n),
                        .i_a(o_m_r),
                        .i_b(t_r),
                        .o_m(o_Mont_m)
                      );
  MontgemoryAlgorithm Mont_t(
                        .i_clk(i_clk),
                        .i_rst(i_rst),
                        .i_N(i_n),
                        .i_a(t_r),
                        .i_b(t_r),
                        .o_m(o_Mont_t)
                      );
  // combinational circuits
  always_comb
  begin
    //mod_start_w = 1'd1;

    if (mod_finish == 1'd1)
    begin
      state_w = S_MONT;
    end
    else
    begin
      state_w = state_r;
    end

    if(count_r < 16'd256)
    begin
      if(state_r == S_MONT)
        //if(mod_finish == 1'd1)
      begin
        if (i_d[count_r] == 1'd1)
        begin // count_r-th bit of d is 1
          o_m_w = o_Mont_m;
        end
        else
        begin
          o_m_w = o_m_r;
        end
        t_w = o_Mont_t;
        count_w = count_r + 16'd1;
      end
      else
      begin
        o_m_w = o_m_r;
        t_w = t_r;
        count_w = count_r ;
      end
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
      t_r <= 258'd0;
      state_r <= S_IDLE;
      o_m_r <= 258'd1;
      count_r <= 16'd0;
    end
    else
    begin
      // mod_start_r <= 1'd0;
      if(i_start)
      begin
        // mod_start_r <= 1'd1;
        t_r <= initial_t; // # of bits are different
      end
      else
      begin
        // mod_start_r <= mod_start_w;
        t_r <= t_w;
      end
      state_r <= state_w;
      // t_r <= t_w;
      o_m_r <= o_m_w;
      count_r <= count_w;
    end
  end

endmodule



