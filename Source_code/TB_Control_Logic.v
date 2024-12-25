module Control_Logic_TB;
	reg		OVF_IN;
	reg		UNDF_IN;
	reg	[7:0]	REG_IN_1;
	reg	[7:0]	APB_IN;
	wire	[7:0]	TSR;
	wire	[1:0]	REG_OUT_2;
	wire	[1:0]	CLK_SEL_OUT;
	
	Control_Logic_RTL Control_Logic_dut(
		.OVF_IN(OVF_IN),
		.UNDF_IN(UNDF_IN),
		.REG_IN_1(REG_IN_1),
		.REG_OUT_2(REG_OUT_2),
		.CLK_SEL_OUT(CLK_SEL_OUT)
	);
	TSR_module TSR_module_dut(
		.CL_IN(REG_OUT_2),
		.APB_IN(APB_IN),
		.TSR(TSR)
	);

	initial begin
		APB_IN		=	8'h00;
		OVF_IN		=	8'h00;
		UNDF_IN		=	8'h00;
		REG_IN_1	=	8'h01;
		#100
		OVF_IN		=	8'h01;
		#100
		UNDF_IN		=	8'h01;
		OVF_IN		=	8'h00;	


		#100
		UNDF_IN		=	8'h00;
		APB_IN		=	8'h01;
		#100
		APB_IN		=	8'h02;
	end
endmodule
