module AudDSP(
    input i_rst_n,
	input i_clk,

	input i_start,
	input i_pause,
	input i_stop,

	input i_fast,
	input i_slow_0, // constant interpolation
	input i_slow_1, // linear interpolation

	input i_daclrck,
	input [15:0] i_sram_data,
	output [15:0] o_dac_data,
	output [19:0] o_sram_addr,

    input i_final_address
);

logic [15:0] dac_t, dac_r;

logic [2:0] addr_count_t, addr_count_r;     //for intepolation 0 repeat time     
logic [19:0] sram_addr_t, sram_addr_r;
logic [2:0] interval_t, interval_r;

logic [4:0] speed_t, speed_r;   //current speed 

logic [2:0] state_t, state_r;

assign o_sram_addr = sram_addr_r;
assign o_dac_data = dac_r;

parameter S_IDLE = 3'd0;
parameter S_FILL = 3'd1;
parameter S_COMP = 3'd2;
parameter S_PAUSE = 3'd3;



always_comb begin
    //default 
    dac_t = dac_r;
    addr_count_t = addr_count_r;
    sram_addr_t = sram_addr_r;
    interval_t = interval_r;
    speed_t = speed_r;
    state_t = state_r;
    //FSM
    //filling part
    case(state_r)
    S_IDLE : if(i_start) state_t = S_FILL;
    S_FILL : begin
        //filling
        if(i_stop)begin
                sram_addr_t = 0;
                speed_t = 5'd7; //normal speed
                state_t = S_IDLE;
                addr_count_t = 0;
        end
        else if(i_pause)begin
                sram_addr_t = sram_addr_r;
                state_t = S_PAUSE;
        end
        else if(i_daclrck) begin

            //deal with pause and nxt addr
            if(i_pause)begin
                sram_addr_t = sram_addr_r;
                state_t = S_PAUSE;
            end
            else if (speed_r > 6) begin
                dac_t = i_sram_data;
                sram_addr_t = sram_addr_r +speed_r - 5'd6;
                interval_t = 0;
                addr_count_t = 0;
                state_t = S_COMP;
            end
            else begin
                interval_t = 5'd7-speed_r; //set interval according to speed
                state_t = S_COMP;
                if(addr_count_r == interval_r || addr_count_r > interval_r)begin
                    sram_addr_t = sram_addr_r +1;
                    addr_count_t = 0;
                end
                else begin
                    sram_addr_t = sram_addr_r;
                    addr_count_t = addr_count_r + 1; 
                end

                //slower 0
                dac_t = i_sram_data;

                //slower 1
                // dac_t = (i_sram_data + dac_r) <<1;

                
            end
            

            //deal with stop
            if(i_stop)begin
                sram_addr_t = 0;
                speed_t = 5'd7; //normal speed
                state_t = S_IDLE;
                addr_count_t = 0;
            end
        end
        else    state_t = state_r;
    end
	S_COMP  : begin
        if(i_stop || sram_addr_t>final_address)begin
                sram_addr_t = 0;
                speed_t = 5'd7; //normal speed
                state_t = S_IDLE;
                addr_count_t = 0;
        end
        else if(i_pause)begin
                sram_addr_t = sram_addr_r;
                state_t = S_PAUSE;
        end
        else if(!i_daclrck)  state_t = S_FILL;
    end
    S_PAUSE :   if(i_start) state_t = S_FILL;
    default :  state_t = S_IDLE;
    endcase


    //speed part
    if(i_fast & speed_r < 5'd14) speed_t = speed_r + 1;
    else if(i_slow_0 & speed_r > 0) speed_t = speed_r - 1;
    else if(i_slow_1 & speed_r > 0) speed_t = speed_r - 1; 
    else speed_t = speed_r;

end

always_ff @(posedge i_clk) begin
    if(!i_rst_n)begin
        dac_r <= 0;
        addr_count_r <= 0;
        sram_addr_r <= 0;
        interval_r <= 0;
        state_r <= S_IDLE;
        speed_r <= 5'd7;

    end
    else begin
        dac_r <= dac_t;
        addr_count_r <= addr_count_t;
        sram_addr_r <= sram_addr_t;
        interval_r <=  interval_t;
        state_r <= state_t;
        speed_r <= speed_t;
    end
end

endmodule