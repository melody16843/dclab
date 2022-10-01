
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

endmodule

module Mont(
    input		   i_clk,
    input 		   i_rst,
    input  [255:0] i_a, // cipher text y
    input  [255:0] i_d, // private key
    input  [255:0] i_n,
    output [257:0] o_m
  );
  logic [257:0] o_m_r, o_m_w;
  logic [257:0] t_r, t_w;
  logic [15:0] count_r, count_w;  //counter from 0 to 255
  // ModuloProduct output wire
  logic [257:0] initial_t;
  // Mont_m output wire
  logic [257:0] o_Mont_m;
  // Mont_m output wire
  logic [257:0] o_Mont_t;

  assign o_m = o_m_r;

  ModuloProduct mod0(
                  .i_clk(i_clk),
                  .i_rst(i_rst),
                  .n(i_n),
                  .i_a(2**256), //2**256, do we need to specify 256 bits?
                  .i_b(i_a),
                  .i_k(256'd256),
                  .o_m(initial_t)
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
    if(count_r < 16'd256)
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
  // sequential circuits
  always_ff @(posedge i_clk or negedge i_rst)
  begin
    // reset
    if (!i_rst_n)
    begin
      t_r <= initial_t; // # of bits are different
      o_m_r <= 258'd1;
      count_r <= 16'd0;
    end
    else
    begin
      t_r <= t_w;
      o_m_r <= o_m_w;
      count_r <= count_w;
    end
  end
endmodule

module ExponentiationSquaring(
    input i_clk,
    input i_rst,
    input [255:0] y,
    input [255:0] d, // private key
    input [255:0] n,
    output [257:0] o_m
  );
  logic [257:0] o_m_r, o_m_w;
  logic [257:0] t_r, t_w;
  logic [15:0] count_r, count_w;  //counter from 0 to 255

  assign o_m = o_m_r;

  // combinational circuits
  always_comb
  begin
    if(count_r < 16'd256)
    begin
      if (d[count_r] == 1'd1)
      begin // count_r-th bit of d is 1
        o_m_w = o_m_r * t_r % n ;//m = m*t(mod n)
      end
      else
      begin
        o_m_w = o_m_r;
      end
      t_w = (t_r**2) % n;
      count_w = count_r + 16'd1;
    end
    else
    begin
      o_m_w = o_m_r;
      t_w = t_r;
      count_w = count_r;
    end
  end

  // sequential circuits
  always_ff @(posedge i_clk or negedge i_rst)
  begin
    // reset
    if (!i_rst)
    begin
      t_r <= {2'b0, y}; // # of bits are different
      o_m_r <= 258'd1;
      count_r <= 16'd0;
    end
    else
    begin
      t_r <= t_w;
      o_m_r <= o_m_w;
      count_r <= count_w;
    end
  end

endmodule

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
    if (!i_rst)
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

module MontgemoryAlgorithm(
    input		   i_clk,
    input 		   i_rst,
    input  [255:0] i_N,
    input  [255:0] i_a,
    input  [255:0] i_b,
    output [257:0] o_m
  );

  logic  [257:0] o_m_r, o_m_w;
  logic  [15:0]  count_r, count_w;

  assign o_m = o_m_r;

  always_comb
  begin
    // Default Value //
    o_m_w = o_m_r;
    count_w = count_r;

    if(count_r < 16'd256)
    begin
      //count_w = count_r + 1;
      if(i_a[count_r] == 1'b1)
      begin
        if(o_m_r[0] ^ i_b[0] == 1'b1) // m is odd
        begin
          o_m_w = (o_m_r + i_b + i_N) >> 1;
        end
        else
          o_m_w = (o_m_r + i_b) >> 1;
      end

      else
      begin
        if(o_m_r[0] == 1'b1)
        begin
          o_m_w = (o_m_r + i_N) >> 1;
        end
        else
          o_m_w = o_m_r >> 1;
      end
      count_w = count_r + 1;
    end

    else
    begin
      count_w = count_r;
      if(o_m_r >= i_N)
      begin
        o_m_w = o_m_r - i_N;
      end
      else
        o_m_w = o_m_r;
    end

  end


  always_ff @(posedge i_clk or negedge i_rst)
  begin
    if(!i_rst)
    begin
      count_r <= 16'd0;
      o_m_r <= 257'd0;
    end

    else
    begin
      count_r <= count_w;
      o_m_r <= o_m_w;
    end
  end


endmodule

