`timescale 1ns/100ps

module tb;
	localparam CLK = 10;
	localparam HCLK = CLK/2;

	logic bclk, en, rst_n, daclrck;
    logic [15:0] dac_data;
    logic [15:0] aud_dacdat;
    
	initial bclk = 0;
	initial daclrck = 0;
	always #HCLK bclk = ~bclk;
	always #CLK = daclrck;

	AudPlayer test(
	.i_rst_n(rst_n),
	.i_bclk(bclk),
	.i_daclrck(daclrck),
	.i_en(en), // enable AudPlayer only when playing audio, work with AudDSP
	.i_dac_data(dac_data), //dac_data
	.o_aud_dacdat(aud_dacdat)
);



initial begin
	$fsdbDumpfile("player_test.fsdb");
	$fsdbDumpvars;	
	rst_n = 0;
	#(2*CLK)
	rst_n = 1;
	@(posedge bclk)
	en = 1;
	@(posedge bclk)
	@(posedge bclk)
	dac_data = 16'd100;

	
end

initial #(CLK*500000) $finish;

endmodule