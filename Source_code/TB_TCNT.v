module test;
	// Declare internal wires and regs use for Sum_dut
	reg			PCLK;
	reg			RST;
	reg	[7:0]	TDR;
	reg	[7:0]	TCR;
	reg	[1:0]	Clk_SEL;
	wire[3:0]	Clk;
	wire		OVF;
	wire		UNDF;
	
	clock_divider clock_divider_dut(
		.clk(PCLK),
		.rst(RST),
		.clk_div2(Clk[0]),
		.clk_div4(Clk[1]),
		.clk_div8(Clk[2]),
		.clk_div16(Clk[3])
	);
	TCNT_sum TCNT_sum_dut(
		.PCLK(PCLK),
		.RST(RST),
		.Clk(Clk),
		.TDR(TDR),
		.TCR(TCR),
		.Clk_SEL(Clk_SEL),
		.over_flow(OVF),
		.under_flow(UNDF)
	);

	initial begin
		PCLK = 1'b0;
		forever #5 PCLK = ~PCLK;
	end
	initial begin
		TCR = 8'h90;
		Clk_SEL = 2'b01;
		TDR = 8'hdf;
		RST = 1;
		#20
		RST = 0;
	end
endmodule

