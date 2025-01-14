module Control_Logic_RTL (
	input	wire			OVF_IN,				// Input Overflow signal from TCNT
	input	wire			UNDF_IN,			// Input Underflow signal from TCNT
	input	wire	[7:0]	REG_IN_1,			// Input TCR register from Read/Write Control
	output	reg		[1:0]	REG_OUT_2,			// Output signal to set Overflow or Underflow status bit on TSR register
	output	reg		[1:0]	CLK_SEL_OUT			// Output signal to select appropriate clock pulse base on TCR register
);

	always @(*) begin

		/* Select clock pulse base on TCR[1:0] */
		case (REG_IN_1[1:0])
			2'b00:	CLK_SEL_OUT = 2'b00;
			2'b01:	CLK_SEL_OUT = 2'b01;
			2'b10:	CLK_SEL_OUT = 2'b10;
			2'b11:	CLK_SEL_OUT = 2'b11;
		endcase

		/* Set status bit on TSR register*/
		if(OVF_IN == 1'b1) begin
			REG_OUT_2 = 2'b01;
		end else if (UNDF_IN == 1'b1) begin
			REG_OUT_2 = 2'b10;
		end else
			REG_OUT_2 = 2'b00;
	end
endmodule

