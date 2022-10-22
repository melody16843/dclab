`timescale 1ns/100ps

module tb;
	localparam CLK = 10;
	localparam HCLK = CLK/2;

	logic bclk, rst_n, start, pause, stop, adclrck;
    logic [15:0] adc_data;
    logic [15:0] data_record;
    logic [19:0] addr_record;
    
	initial bclk = 0;
	always #HCLK bclk = ~bclk;

	AudRecorder test(
	.i_rst_n(rst_n), 
	.i_clk(bclk),
	.i_lrc(adclrck),
	.i_start(start),
	.i_pause(pause),
	.i_stop(stop),
	.i_data(adc_data),
	.o_address(addr_record),
	.o_data(data_record),
);



initial begin
	$fsdbDumpfile("recorder_test.fsdb");
	$fsdbDumpvars;	
	
end

initial #(CLK*500000) $finish;

endmodule