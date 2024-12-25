module OVF_UNDF_Comparison_TB;
	reg	[7:0]	count;
	wire		over_flow;
	wire		under_flow;
	reg	[7:0]	TCR;
	reg	[7:0]	TDR;
	reg	[7:0]	def_reg;
	reg		PCLK;
	wire		Q;
	reg	[7:0]	COUNT_IN;
	reg		CLK;
	wire	[7:0]	COUNT_OUT;

	initial begin
		PCLK = 1'b0;
		forever #5 PCLK = ~PCLK;
		CLK = 1'b0;
		forever #5 CLK = ~CLK;
	end

	//Modules instantiation
	D_flipflop flipflop_1 (
		.PCLK(PCLK),
		.D(def_reg),
		.Q(Q)
	);

	Counter_block Counter_block_1 (
		.COUNT_IN(COUNT_IN),
		.TCR(TCR),
		.COUNT_OUT(COUNT_OUT),
		.CLK(CLK)
	);

	D_flipflop flipflop_2 (
	
	);

	Counter_block Counter_block_2 (

	);

	OVF_UNDF_Comparison_RTL dut(
		.TCR(TCR),
		.count(count),
		.over_flow(over_flow),
		.under_flow(under_flow)
	);
	


	// Tasks list 
	task Default_Count;
	begin
		TDR = 8'h00;
		TCR = 8'h00;
		def_reg  = TDR;
		COUNT_IN = Q;

	end
	endtask

	task Count_Up;
	begin
		TCR = 8'h00;
		count = 8'hFE;
		#100;
		count = 8'hFF;
		#100;
		count = 8'h00;
		#100;	
	end
	endtask

	task Count_Down;
	begin
		TCR = 8'h20;
		count = 8'h00;
		#100;
		count = 8'hFF;
		#100;
		count = 8'hFE;
		#100;	
	end
	endtask

	initial begin
		Default_Count;
	end
endmodule

