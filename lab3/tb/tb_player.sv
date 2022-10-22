`timescale 1ns/100ps

module tb;
	localparam CLK = 10;
	localparam HCLK = CLK/2;

	logic clk, start, finished, rst_n, ic2_sclk, i2c_sdat, i2c_oen;
    
	initial clk = 0;
	always #HCLK clk = ~clk;

	I2cInitializer test(
	.i_rst_n(rst_n),
	.i_clk(clk),
	.i_start(start),
	.o_finished(finished),
	.o_sclk(ic2_sclk),
	.o_sdat(i2c_sdat),
	.o_oen(i2c_oen) // you are outputing (you are not outputing only when you are "ack"ing.)
);



initial begin
	$fsdbDumpfile("ic2_test.fsdb");
	$fsdbDumpvars;	
	
end

initial #(CLK*500000) $finish;

endmodule