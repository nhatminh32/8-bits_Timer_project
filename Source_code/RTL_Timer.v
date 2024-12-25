module Timer_8bits(
    input   wire            PCLK,
    input   wire            PRESETn,
    input   wire            PSEL,
    input   wire            PENABLE,
    input   wire            PWRITE,
    input   wire    [7:0]   PADDR,
    input   wire    [7:0]   PWDATA,
    input   wire    [3:0]   Clk,
    output  wire            PREADY,
    output  wire            PSLVERR,
    output  wire    [7:0]   PRDATA
);
	localparam  ADDR_WIDTH = 8;
	localparam  DATA_WIDTH = 8;

	wire    [7:0]   TSR_APB; 				// wire connection between the output of Read_Write_Control_1 and TSR register
	wire    [1:0]   TSR_CL;  				// wire connection between the output of Control_Logic_1 and TSR_module
	wire            OVF;     				// wire connection between the output Overflow register of TCNT and the Contro_Logic_1
	wire            UNDF;    				// wire connection between the output Underflow register of TCNT and the Contro_Logic_1
	wire    [1:0]   Clk_SEL; 				// wire connection sent Clock selection signal from Control_Logic_1 to TCNT.
	wire    [7:0]   TCR_OUT; 				// wire connection for ouput value from TCR register, connect to Control_Logic_1 and TCNT
	wire    [7:0]   TDR_OUT; 				// wire connection for ouput value from TDR register, connect to TCNT.
	wire			TSR_ovf_rst_signal;		// wire connection transfer reset signal from TSR module to Comparison block in TCNT.
	wire			TSR_undf_rst_signal;		

	Read_Write_Control_RTL #(
		.ADDR_WIDTH (ADDR_WIDTH),
		.DATA_WIDTH (DATA_WIDTH)
	) Read_Write_Control_1(
		.PCLK (PCLK),
		.PRESETn (PRESETn),
		.PSEL (PSEL),
		.PENABLE (PENABLE),
		.PWRITE (PWRITE),
		.PADDR (PADDR),
		.PWDATA (PWDATA),
		.CL_IN(TSR_CL),
		.PREADY (PREADY),
		.PSLVERR (PSLVERR),
		.PRDATA (PRDATA),
		.TDR (TDR_OUT),
		.TCR (TCR_OUT),
		.TSR (TSR_APB),
		.OVF_RESET_SIGNAL(TSR_ovf_rst_signal),
		.UNDF_RESET_SIGNAL(TSR_undf_rst_signal)
	);

	TCNT_sum TCNT_sum_1(
		.PCLK(PCLK),
		.RST(PRESETn),
		.Clk(Clk),
		.TDR(TDR_OUT),
		.TCR(TCR_OUT),
		.OVF_rst(TSR_ovf_rst_signal),
		.UNDF_rst(TSR_undf_rst_signal),
		.Clk_SEL(Clk_SEL),
		.over_flow(OVF),
		.under_flow(UNDF)
	);

	Control_Logic_RTL Control_Logic_1(
		.OVF_IN(OVF),
		.UNDF_IN(UNDF),
		.REG_IN_1(TCR_OUT),
		.REG_OUT_2(TSR_CL),
		.CLK_SEL_OUT(Clk_SEL)
	);
endmodule