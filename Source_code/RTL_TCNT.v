module TCNT_sum(
	input	wire			PCLK,
	input	wire			RST,
	input	wire	[3:0]	Clk,
	input	wire	[7:0]	TDR,
	input	wire	[7:0]	TCR,
	input	wire			OVF_rst,
	input	wire			UNDF_rst,
	input	wire	[1:0]	Clk_SEL,		// Clock select signal sent from the Control logic module.
	output	wire			over_flow,		// ouput wire because the dut of Comparison block already reg type, so the next connection should be wire
	output	wire			under_flow		// the same with underflow
);

	wire			Signal_Counter_wire; 	// wire connect after selected
	wire	[7:0]	Start_count_1;		 	// Wire connect value from flipflop to counter block in load data TDR counter chain
	wire	[7:0]	Start_count_2;		 	// Wire connect value from flipflop to counter block in Default mode counter chain 
	wire	[7:0]	Count_OUT_default;   	// Wire connect counter block of the Default mode to Comparison block
	wire	[7:0]	Count_OUT_TDR;   	 	// Wire connect counter block of the Load data TDR reg mode to the Comparison block
	reg		[7:0]	Def_Val;			 	// Register store the default value
	reg		[7:0]	SEL_OUT_value; 			// middle-man reg use for store value for the input of the Comparison block, base on which mode default or load data from TDR reg.

	/* Select_clock module instatiation */
	Select_clock Select_clock_dut(
		.PCLK(PCLK),
		.Clk0(Clk[0]),
		.Clk1(Clk[1]),
		.Clk2(Clk[2]),
		.Clk3(Clk[3]),
		.Clk_SEL(Clk_SEL),
		.Signal_Counter(Signal_Counter_wire)
	);
	/* Counter chain instantiation for TDR reg load data mode */
	D_flipflop flipflop_1(
		.D_IN(TDR),
		.PCLK(PCLK),
		.Q_OUT(Start_count_1)
	);
	Counter_block counter_1(
		.COUNT_IN(Start_count_1),
		.TCR(TCR),
		.CLK(Signal_Counter_wire),
		.RST(RST),
		.COUNT_OUT(Count_OUT_TDR)
	);
	/* Counter chain instantiation for default value mode */
	D_flipflop flipflop_2(
		.D_IN(Def_Val),
		.PCLK(PCLK),
		.Q_OUT(Start_count_2)
	);
	Counter_block counter_2(
		.COUNT_IN(Start_count_2),
		.TCR(TCR),
		.CLK(Signal_Counter_wire),
		.RST(RST),
		.COUNT_OUT(Count_OUT_default)
	);
	/* Overflow/Underflow comparison module instantiation */
	OVF_UNDF_Comparison_RTL Comparison_dut(
		.CLK(Signal_Counter_wire),
		.TCR(TCR),
		.CNT_IN(SEL_OUT_value),
		.OVF_RST_SIG_IN(OVF_rst),
		.UNDF_RST_SIG_IN(UNDF_rst),
		.over_flow(over_flow),
		.under_flow(under_flow)
	);

	always @(*) begin
	
		if(TCR[7] == 0) begin
			/* Initialize start value for Default counter mode (TCR[7] = 0) base on TCR[5] (Counting Up/Down bit) */
			if(TCR[5] == 0)
				Def_Val <= 8'h00;
			else 
				Def_Val <= 8'hFF;
		end
		/*
			If TCR[7] = 0 (Default mode): load value from counter_2 to the comparision block
			If TCR[7] = 1 (Load data mode): load value from counter_1 to the comparision blockblock
		*/
		case (TCR[7]) 
			1'b0: 	SEL_OUT_value <= Count_OUT_default;
			1'b1:	SEL_OUT_value <= Count_OUT_TDR;
		endcase
	end
endmodule

module Select_clock(
	input	wire			PCLK,
	input	wire			Clk0,
	input	wire			Clk1,
	input	wire			Clk2,
	input	wire			Clk3,
	input	wire	[1:0]	Clk_SEL,			// Select clock signal output from Control_Logic
	output	wire			Signal_Counter		// Output clock pulse after the selection 
);

	wire	[7:0]	Clock_Out_1;
	wire	[7:0]	Clock_Out_2;

	D_flipflop flipflop_1(
		.D_IN(Clock_Out_1),
		.PCLK(PCLK),
		.Q_OUT(Clock_Out_2)
	);

	Two_bit_MUX Mux(
		.Cks_IN0(Clk0),
		.Cks_IN1(Clk1),
		.Cks_IN2(Clk2),
		.Cks_IN3(Clk3),
		.SEL(Clk_SEL),
		.Cks_OUT(Clock_Out_1)
	);

	assign Signal_Counter = Clock_Out_2; 
endmodule

module Two_bit_MUX(
	input	wire			Cks_IN0,
	input	wire			Cks_IN1,
	input	wire			Cks_IN2,
	input	wire			Cks_IN3,
	input	wire	[1:0]	SEL,
	output	reg		[7:0]	Cks_OUT
);
	always @(*) begin
		case (SEL)
			2'b00:	Cks_OUT <= Cks_IN0;
			2'b01:	Cks_OUT <= Cks_IN1;
			2'b10:	Cks_OUT <= Cks_IN2;
			2'b11:	Cks_OUT <= Cks_IN3;
		endcase
	end
endmodule

module D_flipflop(
	input	wire	[7:0]	D_IN,
	input	wire			PCLK,
	output	reg		[7:0]	Q_OUT
);
	always @(posedge PCLK) begin
		Q_OUT <= D_IN;
	end
endmodule

module Counter_block(

	input	wire	[7:0]	COUNT_IN, 	// Start value for Counter_block
	input	wire			CLK, 		// Clock pulse output from the Select_clock
	input	wire	[7:0]	TCR,		// Input TCR register valuevalue
	input	wire			RST,		// Reset signal
	output	reg		[7:0]	COUNT_OUT	// Output of the Counter_block after execute increment (+) or decrement (-)
);
	/* 
		count_back use to backup the count value if a STOP or DELAY event happens 
		count_back value will be assign the same as COUNT_OUT value
	*/
	reg	[7:0]	count_backup;			
	initial begin
		count_backup = 8'h00;
	end

	always @(posedge CLK) begin
		/* Enable bit TCR[4] = 1, then counter start */
		if(TCR[4] == 1'b1) begin
			/* Count up mode*/
			if(TCR[5] == 1'b0) begin
				COUNT_OUT	 <= COUNT_OUT + 8'h01;
				count_backup <= COUNT_OUT + 8'h01;
			end
			/* Count down mode*/
			else begin
				COUNT_OUT	 <= COUNT_OUT - 8'h01;
				count_backup <= COUNT_OUT - 8'h01;
			end
		end

		COUNT_OUT = COUNT_IN | count_backup;
	end

	always@(*) begin
		if(~RST) begin
			COUNT_OUT <= 8'h00;
			count_backup <= 8'h00;
		end
	end
endmodule

module OVF_UNDF_Comparison_RTL #(
	parameter MAX_COUNT = 8'hFF, 				// Maximum count value (255 decimal)
	parameter MIN_COUNT = 8'h00 				// Minimum count value (0 decimal)
)(
	input	wire			CLK,				// Clock pulse from output of Select_clockclock
	input	wire	[7:0]	TCR,				// TCR register valuevalue
	input 	wire	[7:0]	CNT_IN,				// Output value from the Counter_block
	input	wire			OVF_RST_SIG_IN,		// Reset signal for Overflow register from Read/Write Control
	input	wire			UNDF_RST_SIG_IN,	// Reset signal for Underflow register from Read/Write Control
	output	reg				over_flow,			// Status register, represent Overflow
	output	reg	        	under_flow			// Status register, represent Underflow
);
	reg	[7:0]	pre_count;		// pre_count use to store the previous input value from CNT_IN

	/* Initial default value for over_flow and under_flow registers */
	initial begin
		over_flow 	= 1'b0;
		under_flow 	= 1'b0;
	end

	always @(posedge CLK) begin
		/*	Count up: Overflow when pre_count = 8'hFF */
		if(TCR[5] == 1'b0) begin
			/* (MAX_COUNT - 8'h01) ensure the over_flow signal raise at the end when pre_count = 8'hFE, which means the beginning of 8'hFF */
			if(pre_count == (MAX_COUNT - 8'h01)) 
				over_flow 	<= 1'b1;
		end
		/*	Count down: Overflow when pre_count = 8'h00 */
		else begin
			/* (MIN_COUNT + 8'h01) ensure the under_flow signal raise at the end when pre_count = 8'h01, which means the beginning of 8'h00 */
			if(pre_count == (MIN_COUNT + 8'h01)) 
				under_flow	<= 1'b1;
		end
		pre_count <= CNT_IN;
	end

	/* Reset over_flow and under_flow register value if there is a PRESETn signal sent to */
	always @(*) begin
		if(OVF_RST_SIG_IN 	== 1'b1)
			over_flow 	<= 1'b0;
		if(UNDF_RST_SIG_IN 	== 1'b1)
			under_flow 	<= 1'b0;
	end
endmodule

