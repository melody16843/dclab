module AudRecorder(
    input           i_rst_n,
    input           i_clk,
    input           i_lrc,
    input           i_start,
    input           i_pause,
    input           i_stop,
    input           i_data,
    output  [19:0]  o_address,
    output  [15:0]  o_data
);

parameter   S_IDLE = 0;
parameter   S_READ = 1;
parameter   S_WAIT = 2;



logic           state_r, state_w;
logic   [7:0]   counter_r, counter_w;
logic   [15:0]  o_data_r, o_data_w;

assign o_data = o_data_r;


always_comb
begin
    /// default ///
    state_w = state_r;
    counter_w = counter_r;
    o_data_w = o_data_r;

    case(state_r)
    S_IDLE:
    begin
        if(i_start)
        begin
            if(!i_lrc) 
            begin
                state_w = S_READ;
                counter_w = 8'd0;
            end
            else 
            begin
                state_w = S_WAIT;
                counter_w = counter_r;
            end
        end
        else 
        begin
            state_w = state_r;
            counter_w = counter_r;
        end
    end

    S_READ:
    begin
        if(i_stop)
        begin
            state_w = S_IDLE;
            counter_w = 8'd0;
            o_data_w = 16'd0;
        end
        else
        begin
            if (i_lrc)
            begin
                state_w = S_IDLE;
                counter_w = counter_r;
                o_data_w = o_data_r;
            end
            else
            begin
                counter_w = counter_r + 8'b1;
                if (counter_r >= 8'd0 && counter_r < 8'd16)
                begin
                    o_data_w = {o_data_r[14:0], i_data};
                end
                else
                begin
                    o_data_w = o_data_r;
                end
            end
        end
    end

    S_WAIT:
    begin
        if(i_stop)
        begin
            state_w = S_IDLE;
            counter_w = 8'd0;
            o_data_w = 16'd0;
        end
        else
        begin
            if (!i_lrc)
            begin
                state_w = S_READ;
                counter_w = 8'd0;
            end
            else
            begin
                state_w = state_r;
                counter_w = counter_r;
            end
        end
    end



    default: state_w = S_IDLE;
    endcase

end

// 1100_1010_1010_0110

always_ff @(posedge i_clk or negedge i_rst_n)
begin
    if (!i_rst_n)
    begin
        state_r <= S_IDLE;
        counter_r <= 8'd0;
        o_data_r <= 16'd0;

    end
    else
    begin
        state_r <= state_w;
        counter_r <= counter_w;
        o_data_r <= o_data_w;
    end
end

endmodule
