`timescale 1us/1us

module Top_Test;

parameter cycle = 100.0;

logic   i_rst_n;
logic   i_clk;
logic   i_key_0;
logic   i_key_1;
logic   i_key_2;

logic   [19:0]  o_SRAM_ADDR;
wire    [15:0]  io_SRAM_DQ;
logic           o_SRAM_WE_N;
logic           o_SRAM_CE_N;
logic           o_SRAM_OE_N;
logic           o_SRAM_LB_N;
logic           o_SRAM_UB_N;

logic   i_clk_100k;
logic   o_I2C_SCLK;
wire    io_I2C_SDAT;

wire    i_AUD_ADCDAT;
wire    i_AUD_ADCLRCK;
wire    i_AUD_BCLK;
wire    i_AUD_DACLRCK;
logic   o_AUD_DACDAT;

reg record_input, adclrck, bclk, dacrlck;
assign i_AUD_ADCDAT = record_input;
assign i_AUD_ADCLRCK = adclrck;
assign i_AUD_BCLK = bclk;
assign i_AUD_DACLRCK = dacrlck;

initial i_clk = 0;
initial i_clk_100k = 0;
initial bclk = 0;
initial adclrck = 0;
initial dacrlck = 0;

always #(cycle/2.0) i_clk = ~i_clk;
always #(cycle/5.0) i_clk_100k = ~i_clk_100k;
always #(cycle) bclk = ~bclk;
always #(cycle*50)  adclrck = ~adclrck;
always #(cycle*50)	dacrlck = ~dacrlck;

Top top0(
    .i_rst_n(i_rst_n),
    .i_clk(i_clk),
    .i_key_0(i_key_0),
    .i_key_1(i_key_1),
    .i_key_2(i_key_2),
    .o_SRAM_ADDR(o_SRAM_ADDR),
    .io_SRAM_DQ(io_SRAM_DQ),
    .o_SRAM_WE_N(o_SRAM_WE_N),
    .o_SRAM_CE_N(o_SRAM_CE_N),
    .o_SRAM_OE_N(o_SRAM_OE_N),
    .o_SRAM_LB_N(o_SRAM_LB_N),
    .o_SRAM_UB_N(o_SRAM_UB_N),
    .i_clk_100k(i_clk_100k),
    .o_I2C_SCLK(o_I2C_SCLK),
    .io_I2C_SDAT(io_I2C_SDAT),
    .i_AUD_ADCDAT(i_AUD_ADCDAT),
    .i_AUD_ADCLRCK(i_AUD_ADCLRCK),
    .i_AUD_BCLK(i_AUD_BCLK),
    .i_AUD_DACLRCK(i_AUD_DACLRCK),
    .o_AUD_DACDAT(o_AUD_DACDAT)
);

initial begin
    $fsdbDumpfile("Top.fsdb");
	$fsdbDumpvars(0, Top_Test, "+all");
end

initial begin
    i_clk = 0;
    i_rst_n = 1;
    i_key_0 = 0;
    i_key_1 = 0;
    i_key_2 = 0;
    record_input = 0;


    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk) i_rst_n = 0;
	@(negedge i_clk) i_rst_n = 1; 

    for(int i = 0; i < 345; i++) begin
        @(negedge i_clk);
    end
    
    @(negedge i_clk) i_key_0 = 1;   // start recording
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk) i_key_0 = 0;

    for(int i = 0; i < 74; i++) begin
        @(negedge i_clk);
		record_input = 0;
		@(negedge i_clk);
		record_input = 0;
		@(negedge i_clk);
		record_input = 1;
		@(negedge i_clk);
		record_input = 1;
    end
    
    @(negedge i_clk) i_key_0 = 1;  // stop recording
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk) i_key_0 = 0;
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk) i_key_1 = 1;  // start play
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk) i_key_1 = 0;

    for(int i = 0; i < 100; i++) begin
        @(negedge i_clk);
    end
    
    @(negedge i_clk) i_key_1 = 1;  // playing pause
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk) i_key_1 = 0;
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk) i_key_1 = 1;  // continue playing
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk) i_key_1 = 0;
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);
    @(negedge i_clk);




end

initial #(cycle*10000) $finish;

endmodule
