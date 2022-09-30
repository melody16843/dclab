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
		rst = 1;
		#(2*CLK)
		rst = 0;
        for (int j = 0; j < 10; j++) begin
            @(posedge clk);
        end
        $fread(encrypted_data, fp_e);
        $display("=========");
        $display("enc", i, encrypted_data);
        $display("=========");
        start_cal <= 1;
        @(posedge clk)
        encrypted_data <= 256'd10;
        key <= 256'd2;
        start_cal <= 0;
        @(posedge fin)
        $display("=========");
        $display("dec ", i, decrypted_data);
        $display("=========");
		$finish;
	end

	initial begin
		#(500000*CLK)
		$display("Too slow, abort.");
		$finish;
	end

endmodule
