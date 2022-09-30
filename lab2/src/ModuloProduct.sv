module ModuleProduct(
    input          i_clk,
	input          i_rst,
	input          i_start,
	input  [255:0] i_y, // cipher text y
	input  [255:0] i_n,
	output [255:0] mod_output, 
	output         o_finished
);

logic [9:0] count_w, count_r;
logic [255:0] t_w, t_r;
logic [1:0] state_r, state_w;
logic [255:0] output_w, output_r;
logic finish_w, finish_r;

assign mod_output = output_r;

parameter S_IDLE = 1'd0;
parameter S_PROC = 1'd1;
parameter S_FINI = 2'd2

always_comb 
begin
    //default value
    count_w = count_r;
    t_w = t_r;
    state_w = seed_r;
    output_w = output_r;
    finish_w = finish_r;

    //FSM
    case(state_r) 
    S_IDLE:begin
        count_w = count_r;
        state_w = seed_r;
        output_w = output_r;
        t_w = t_r
    end

    S_PROC:begin
        if(count_r<10'b100000001)begin 
            if (count_r == 10'b100000000)begin
                state_w = S_FINI;
                if(output_w+t_r>i_n) output_w = output_r+t_r-i_n;
                else output_w = output_r+t_r;
            end
            else begin
                state_w = state_r;
                output_w = output_r;
            end
        end
        else begin
            state_w = state_r;
            output_w = output_r;
        end

        if(t_r+t_r>i_n)begin
            t_w = t_r +t_r - i_n;
        end
        else begin
            t_w = t_r +t_r;
        end
    end

    S_FINI:begin
        finish_w = 1'b1;
        state_w = S_IDLE;
    end
    endcase

    
end


always_ff @(posedge i_clk or negedge i_rst_n)
  begin
    // reset
    if (!i_rst_n)
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