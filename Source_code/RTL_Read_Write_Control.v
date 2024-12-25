module TSR_module (
	input	wire	[1:0]	CL_IN,			  // Signal from Control logic to set status bit [1:0]
	input	wire	[7:0]	APB_IN,			  // Signal from APB write transaction
	input	wire			PRESET,			  // Reset signal
	output	reg		[7:0]	TSR,			  // TSR register
	output	reg				OVF_RESET_SIGNAL, // Reset status signal send to register Overflow in TCNT
	output	reg				UNDF_RESET_SIGNAL // Reset status signal send to register Underflow in TCNT
);
	wire			[1:0]	out_signal;
	reg				[1:0]	pre_out_signal;   // pre_out_signal register will save the previous value of out_signal
	assign 	out_signal = (~(APB_IN) & CL_IN) | pre_out_signal;
	
	initial begin
		pre_out_signal = 2'b00;
	end

	always @(*) begin
		/* pre_out_signal value assignment if either Overflow or Underflow flag is on AND there are no APB write transaction  */
		if((APB_IN == 8'h00)&&(CL_IN == 2'b01)) begin
			pre_out_signal <= out_signal;
		end else if ((APB_IN == 8'h00)&&(CL_IN == 2'b10)) begin
			pre_out_signal <= out_signal;
		end else begin
			pre_out_signal = 2'b00;
		end

		/* Set value for TSR register base on the out_signal */
		case (out_signal)
			2'b00:	TSR <= 8'h00;	// Default 
			2'b01:	TSR <= 8'h01;	// Overflow
			2'b10:	TSR <= 8'h02;	// Underflow
			2'b11:	TSR <= 8'h03;	// Overflow and Underflow 
		endcase

		/* Send reset signal to OVF or UNDF register in the Comparison block of TCNT if TSR bit is set to 0 */
		if((APB_IN == 8'h01) || (APB_IN == 8'h02)) begin
			if(out_signal[0] == 1'b0)
				OVF_RESET_SIGNAL 	<= 1'b1;
			else if (out_signal[1] == 1'b0)
				UNDF_RESET_SIGNAL 	<= 1'b1;
		end
		if (APB_IN == 8'h03) begin
			OVF_RESET_SIGNAL 	<= 1'b1;
			UNDF_RESET_SIGNAL 	<= 1'b1;
		end

		/* Reset TSR register value and both register Overflow and Underflow in TCNT if there is a PRESETn signal */
		if(~PRESET) begin
			TSR <= 8'h00;
			OVF_RESET_SIGNAL 	= 1'b1;
			UNDF_RESET_SIGNAL 	= 1'b1;
			#20
			OVF_RESET_SIGNAL 	= 1'b0;
			UNDF_RESET_SIGNAL 	= 1'b0;
		end
	end
endmodule

module Read_Write_Control_RTL # (
	parameter ADDR_WIDTH = 8,
	parameter DATA_WIDTH = 8
)(
	input  	wire		    			PCLK,
	input  	wire		     			PRESETn,
	input  	wire		     			PSEL,
	input  	wire		     			PENABLE,
	input  	wire 		     			PWRITE,
	input  	wire 	[ADDR_WIDTH-1:0] 	PADDR,
	input  	wire 	[DATA_WIDTH-1:0] 	PWDATA,
	input	wire				[1:0]	CL_IN,			
	output 	reg                   		PREADY,
	output 	reg                   		PSLVERR,
	output 	reg  	[DATA_WIDTH-1:0] 	PRDATA,
	output 	reg  	[DATA_WIDTH-1:0] 	TDR,
	output 	reg  	[DATA_WIDTH-1:0] 	TCR,
	output 	wire  	[DATA_WIDTH-1:0] 	TSR,
	output	wire						OVF_RESET_SIGNAL,
	output 	wire						UNDF_RESET_SIGNAL
);
	
	localparam	IDLE   = 2'b00,
				SETUP  = 2'b01,
				ACCESS = 2'b10;
	
	reg 	[1:0] 	cur_state;
	reg 	[1:0] 	next_state;
	reg		[7:0]	APB_IN;
	
	/* Create a TSR_module instatiation */
	TSR_module TSR_module_2(
		.CL_IN(CL_IN),
		.APB_IN(APB_IN),
		.PRESET(PRESETn),
		.TSR(TSR),
		.OVF_RESET_SIGNAL(OVF_RESET_SIGNAL),
		.UNDF_RESET_SIGNAL(UNDF_RESET_SIGNAL)
	);

	/* Operating states of APB transaction */
	always @(*) begin 
		case (cur_state)
			IDLE: begin 
				if (PSEL & ~PENABLE) begin
					next_state = SETUP;
				end else begin
					next_state = IDLE;
				end
			end
			SETUP: begin
				if (PSEL & PENABLE) begin
					next_state = ACCESS;
				end else begin
					next_state = SETUP;
				end
			end
			ACCESS: begin
				next_state = IDLE;
			end
			default: begin
				next_state = IDLE;
			end
		endcase
	end

	/* Initial default state whenever start Read/Write Control*/
	always @(posedge PCLK or negedge PRESETn) begin
		if (~PRESETn) begin
			cur_state <= IDLE;
		end else begin
			cur_state <= next_state;
		end
	end
	
	always @ (posedge PCLK or negedge PRESETn) begin
		/* Initial default value for TDR, TCR and APB_IN register */
		if(~PRESETn) begin
			TDR 	<= 8'h00;
			TCR 	<= 8'h00;
			APB_IN 	<= 8'h00;
		end else begin
			/* WRITE transaction in ACCESS state */
			if ((cur_state == ACCESS) & PWRITE & PSEL & PENABLE) begin
				TDR <= (PADDR == 8'h00) ? PWDATA : TDR;
				TCR <= (PADDR == 8'h01) ? PWDATA : TCR;
				if((PADDR == 8'h02) && (TSR != 8'h00)) begin	// Not allow Write transaction to TSR if TSR = 8'h00 (default valuevalue)
					APB_IN <= PWDATA;
				end else begin
					APB_IN <= APB_IN;
				end
			end
			/* READ transaction in ACCESS state */
			else if ((cur_state == ACCESS) & !PWRITE & PSEL & PENABLE) begin
				case (PADDR)
					8'h00: PRDATA <= TDR;
					8'h01: PRDATA <= TCR;
					8'h02: PRDATA <= TSR;
				endcase
			end 
			/* Keep the previous value in TDR, TCR and APB_IN register if there are no transaction */
			else begin
				TDR 	<= TDR;
				TCR 	<= TCR;
				APB_IN 	<= APB_IN;
			end
		end
	end

	always @(posedge PCLK or negedge PRESETn) begin
		/* Initial default value for PREADY and PSLVERR */
		if (!PRESETn) begin
			PREADY  <= 1'b0;
			PSLVERR <= 1'b0;
		end 
		/* Condition to active PREADY and PSLVERR */
		else begin
			PREADY  <= (cur_state == ACCESS);					// Only active during ACCESS state
			PSLVERR <= (cur_state == ACCESS) & (PADDR > 8'h02); // Active during ACCESS state if the address for transaction is not defined in the code
		end
	end
endmodule
