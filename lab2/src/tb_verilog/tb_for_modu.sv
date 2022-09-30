`timescale 1ns/100ps

module tb;
	localparam CLK = 10;
	localparam HCLK = CLK/2;

	logic clk, start_cal, fin, rst;
	initial clk = 0;
	always #HCLK clk = ~clk;
	logic [255:0] encrypted_data, decrypted_data;
    logic [255:0] key;
	logic [247:0] golden;
	integer fp_e, fp_d;

	ModuleProduct test(
		.i_clk(clk),
		.i_rst(rst),
		.i_start(start_cal),
		.i_y(encrypted_data),
		.i_n(key),
		.o_a_pow_d(decrypted_data),
		.o_finished(fin)
	);

	

initial begin	
	clk 	= 0;
	rst = 1;
	start_cal = 0;
	encrypted_data = 256'd10;
	key = 256'd2;
	@(posedge fin)
	$display("result", decrypted_data);
	
end

initial #(cycle*500000) $finish;

endmodule
