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
	output [19:0] o_sram_addr
);

logic [15:0] dac_t, dac_r;

logic [2:0] addr_count_t, addr_count_r;     
logic [19:0] sram_addr_t, sram_addr_r;
logic [2:0] interval_t, interval_r;

logic start_fill_t, start_fill_r;   //filling or not

logic [4:0] speed_t, speed_r;   //current speed 

assign o_sram_addr = sram_addr_r;
assign o_dac_data = dac_r;




always_comb begin
    //default 

    //FSM
    //filling part
	if(i_daclrck & start_fill_r) begin     //dsp try to fill dac data at daclrck==1
        //filling
        dac_t = i_sram_data;


        //deal with pause and nxt addr
        if(i_pause)begin
            sram_addr_t = sram_addr_r;
        end
        else if (speed_r > 6) begin
            sram_addr_t = sram_addr_r +speed_r - 6;
            interval_t = 0;
            addr_count_t = 0;
        end
        else if begin
            interval_t = 7-speed_r; //set interval according to speed
            if(addr_count_r == interval_r || addr_count_r > interval_r)begin
                sram_addr_t = sram_addr_r +1;
                addr_count_t = 0;
            end
            else begin
                sram_addr_t = sram_addr_r;
                addr_count_t = addr_count_r + 1; 
            end

            
        end
        

        //deal with stop
        if(i_stop)begin
            sram_addr_t = 0;
            speed_t = 5'd6;
        end

    end
    else if(i_daclrck & !start_fill_r & i_start) begin
        dac_t = dac_r;
        start_fill_t = 1;   //wait 1 cycle
    end
    else begin  //dac filling completed
        dac_t = dac_r;
        start_fill_t = 0;   
    end

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
        start_fill_r <= 0;
        speed_r <= 5'd6;

    end
    else begin
        dac_r <= dac_t;
        addr_count_r <= addr_count_t;
        sram_addr_r <= sram_addr_t;
        interval_r <=  interval_t;
        start_fill_r <= start_fill_t;
        speed_r <= speed_t;
    end
end

endmodule