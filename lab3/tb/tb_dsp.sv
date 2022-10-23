`timescale 1ns/100ps

module tb;
	localparam CLK = 10;
	localparam HCLK = CLK/2;

	logic clk, start, pause, stop, fast, slow, rst_n, daclrck;
    logic [15:0] data_play;
    logic [15:0] dac_data;
    logic [19:0] addr_play;

	initial clk = 0;
	always #HCLK clk = ~clk;

	AudDSP test(
	.i_rst_n(rst_n),
	.i_clk(clk),
	.i_start(start),
	.i_pause(pause),
	.i_stop(stop),
	.i_fast(fast),
	.i_slow_0(slow), // constant interpolation
	.i_slow_1(0), // linear interpolation
	.i_daclrck(daclrck),
	.i_sram_data(data_play),
	.o_dac_data(dac_data),
	.o_sram_addr(addr_play)
    );



initial begin
	$fsdbDumpfile("dsp_test.fsdb");
	$fsdbDumpvars;	
	rst_n = 0;
	#(2*CLK)
	rst_n = 1;
	daclrck = 1;
	@(posedge clk)
	start = 1;
	data_play = 15'd11;
	
	
end

initial #(CLK*500000) $finish;

endmodule