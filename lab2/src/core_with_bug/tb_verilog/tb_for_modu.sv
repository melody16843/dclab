`timescale 1ns/100ps

module tb;
	localparam CLK = 10;
	localparam HCLK = CLK/2;

	logic clk, start_cal, fin, rst;
	initial clk = 0;
	always #HCLK clk = ~clk;
	logic [255:0] encrypted_data, decrypted_data;
    	logic [255:0] key;

	ModuleProduct test(
		.i_clk(clk),
		.i_rst(rst),
		.i_start(start_cal),
		.i_y(encrypted_data),
		.i_n(key),
		.mod_output(decrypted_data),
		.o_finished(fin)
	);



initial begin
	$fsdbDumpfile("mod_test.fsdb");
	$fsdbDumpvars;	
	clk 	= 0;
	rst = 1;
	start_cal = 1;
	encrypted_data = 256'd2;
	key = 256'd10;
	$display("start");
	@(posedge clk) rst = 0;
	@(posedge fin)begin
	$display("result", decrypted_data);
	start_cal = 0;
	end
end

initial #(CLK*500000) $finish;

endmodule
