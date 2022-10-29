`timescale 1ns/100ps

module tb;
	localparam CLK = 10;
	localparam HCLK = CLK/2;
    localparam tCLK = CLK*50;

	logic rst_n
    logic key0down, key1down, key2down;
    logic [19:0] SRAM_ADDR;
    logic [15:0] SRAM_DQ;
    logic SRAM_WE_N, SRAM_CE_N, SRAM_OE_N, SRAM_LB_N, SRAM_UB_N;
    logic I2C_SCLK, I2C_SDAT;
    logic AUD_ADCDAT, AUD_ADCLRCK, AUD_BCLK, AUD_DACLRCK, AUD_DACDAT;

    
	initial bclk = 0;
	initial daclrck = 0;
	always #HCLK bclk = ~bclk;
	always #tCLK = daclrck;

    //for clk gen
    logic CLK_12M, CLK_100K, CLK_800K;
    Altpll pll0( // generate with qsys, please follow lab2 tutorials
	.clk_clk(CLK),
	.reset_reset_n(rst_n),
	.altpll_12m_clk(CLK_12M),
	.altpll_100k_clk(CLK_100K),
	.altpll_800k_clk(CLK_800K)
);

	Top test(
	.i_rst_n(rst_n),
	.i_clk(CLK_12M),
	.i_key_0(key0down),
	.i_key_1(key1down),
	.i_key_2(key2down),
	// .i_speed(SW[3:0]), // design how user can decide mode on your own
	
	// AudDSP and SRAM
	.o_SRAM_ADDR(SRAM_ADDR), // [19:0]
	.io_SRAM_DQ(SRAM_DQ), // [15:0]
	.o_SRAM_WE_N(SRAM_WE_N),
	.o_SRAM_CE_N(SRAM_CE_N),
	.o_SRAM_OE_N(SRAM_OE_N),
	.o_SRAM_LB_N(SRAM_LB_N),
	.o_SRAM_UB_N(SRAM_UB_N),
	
	// I2C
	.i_clk_100k(CLK_100K),
	.o_I2C_SCLK(I2C_SCLK),
	.io_I2C_SDAT(I2C_SDAT),
	
	// AudPlayer
	.i_AUD_ADCDAT(AUD_ADCDAT),
	.i_AUD_ADCLRCK(AUD_ADCLRCK),
	.i_AUD_BCLK(AUD_BCLK),
	.i_AUD_DACLRCK(AUD_DACLRCK),
	.o_AUD_DACDAT(AUD_DACDAT)
);



initial begin
	$fsdbDumpfile("top_test.fsdb");
	$fsdbDumpvars;	

	rst_n = 0;
	#(5*CLK)
	rst_n = 1;
	@(posedge bclk)
	@(posedge bclk)
	@(posedge bclk)
	key0down = 1;
    @(posedge bclk)
	@(posedge bclk)
	@(posedge bclk)
    @(posedge bclk)
	@(posedge bclk)
	@(posedge bclk)
    key0down = 0;
    @(posedge bclk)
	@(posedge bclk)
	@(posedge bclk)
    @(posedge bclk)
	@(posedge bclk)
	@(posedge bclk)
    key0down = 1;
    @(posedge bclk)
	@(posedge bclk)
	@(posedge bclk)
    @(posedge bclk)
	@(posedge bclk)
	@(posedge bclk)
    key0down = 0;

	
end

initial #(CLK*500000) $finish;

endmodule