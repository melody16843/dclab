module AudRecorder(
    input           i_rst_n,
    input           i_clk,
    input           i_lrc,
    input           i_start,
    input           i_pause,
    input           i_stop,
    input           i_data,
    output  [19:0]  o_address,
    output  [15:0]  o_data,
    output  [19:0]  o_count,  // # of 16-bits data recorded
    output  [3:0]   state_recorder
);

parameter   S_IDLE = 0;
parameter   S_RECD = 1;
parameter   S_READ = 0;
parameter   S_WAIT = 1;



logic           state_r, state_w;
logic           state_recd_r, state_recd_w;
logic   [7:0]   counter_r, counter_w;
logic   [15:0]  o_data_r, o_data_w;
logic   [19:0]  o_count_r, o_count_w;
logic   [19:0]  o_address_r, o_address_w;

assign o_data = o_data_r;
assign o_count = o_count_r;
assign o_address = o_address_r;
assign state_recorder = state_r;


always_comb
begin
    /// default ///
    state_w = state_r;
    state_recd_w = state_recd_r;
    counter_w = counter_r;
    o_data_w = o_data_r;
    o_count_w = o_count_r;
    o_address_w = o_address_r;
    

    case(state_r)
    S_IDLE:
    begin
        state_w = S_IDLE;
    end

    S_RECD:
    begin
        case(state_recd_r)
        S_READ:
        begin
            if (!i_lrc)
            begin
                state_recd_w = S_WAIT;
                counter_w = counter_r;
                o_data_w = o_data_r;
            end
            else
            begin
                state_recd_w = state_recd_r;
                if (counter_r >= 8'd0 && counter_r < 8'd16)
                begin
                    counter_w = counter_r + 8'b1;
                    o_data_w = {o_data_r[14:0], i_data};
                end
                // else if (counter_r == 8'd16)
                // begin
                //     o_count_w = o_count_r + 1;
                    
                // end
                else
                begin
                    o_data_w = o_data_r;
                end
            end
        end

        S_WAIT:
        begin
            if (i_lrc)
            begin
                state_recd_w = S_READ;
                counter_w = 8'd0;
                o_address_w = o_address_r + 1;
                o_count_w = o_count_r + 1;
                if(&o_address_r) state_w = S_IDLE;
            end
            else
            begin
                state_recd_w = state_recd_r;
                counter_w = counter_r;
            end
        end
        default: state_recd_w = S_WAIT;
        endcase
    end

    default: state_w = S_IDLE;
    endcase
end



always_ff @(posedge i_clk or negedge i_rst_n)
begin
    if (!i_rst_n)
    begin
        state_r <= S_IDLE;
        counter_r <= 8'd0;
        o_data_r <= 16'd0;
        o_count_r <= 20'd0;
        o_address_r <= 20'd0;
        o_count_r <=0;
    end
    else if(i_start)
    begin
        state_r <= S_RECD;
        counter_r <= counter_w;
        o_data_r <= o_data_w;
        o_count_r <= o_count_w;
        o_address_r <= o_address_w;
        if (!i_lrc) state_recd_r <= S_WAIT;
        else state_recd_r <= S_READ;
    end
    else if(i_stop)
    begin
        state_r <= S_IDLE;
        counter_r = 8'd0;
        o_data_r <= 16'd0;
        o_count_r <= o_count_w;
        o_address_r <= o_address_w;
        state_recd_r <= state_recd_w;
    end
    else
    begin
        state_r <= state_w;
        counter_r <= counter_w;
        o_data_r <= o_data_w;
        o_count_r <= o_count_w;
        o_address_r <= o_address_w;
        state_recd_r <= state_recd_w;
    end
end

endmodule