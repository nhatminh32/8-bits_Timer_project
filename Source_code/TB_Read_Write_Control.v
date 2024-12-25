module Read_Write_Control_TB;

localparam ADDR_WIDTH = 8;
localparam DATA_WIDTH = 8;

reg	PCLK;
reg	PRESETn;
reg	PSEL;
reg	PENABLE;
reg	PWRITE;
reg	[ADDR_WIDTH-1:0] PADDR;
reg	[DATA_WIDTH-1:0] PWDATA;
reg	[DATA_WIDTH-1:0] read_data;
wire    PREADY;
wire    PSLVERR;
wire	[DATA_WIDTH-1:0] PRDATA;
wire	[DATA_WIDTH-1:0] TDR;
wire	[DATA_WIDTH-1:0] TCR;
wire	[DATA_WIDTH-1:0] TSR;
integer i;

initial begin
	PCLK = 1'b0;
	forever #5 PCLK = ~PCLK;
end

Read_Write_Control_RTL #(
	.ADDR_WIDTH  (ADDR_WIDTH),
	.DATA_WIDTH (DATA_WIDTH)
)DUT (
	.PCLK (PCLK),
	.PRESETn (PRESETn),
	.PSEL (PSEL),
	.PENABLE (PENABLE),
	.PWRITE (PWRITE),
	.PADDR (PADDR),
	.PWDATA (PWDATA),
	.PREADY (PREADY),
	.PSLVERR (PSLVERR),
	.PRDATA (PRDATA),
	.TDR (TDR),
	.TCR (TCR),
	.TSR (TSR)
);

task APB_WRITE;
	input [ADDR_WIDTH-1:0] addr;
	input [DATA_WIDTH-1:0] data_in;

	begin
		PADDR	= 0;
		PWDATA	= 0;
		PSEL	= 0;
		PENABLE = 0;
		PWRITE  = 0;
		@(posedge PCLK); // Setup phase
		PWRITE	= 1;
		PSEL	= 1;
		PADDR	= addr;
		PWDATA	= data_in;
		@(posedge PCLK); // Access phase
		PENABLE = 1;
		wait (PREADY);
		@(posedge PCLK);
		PSEL	= 0;
		PENABLE	= 0;
		PWRITE	= 0;
		if (PSLVERR) begin
			$display ("Write %d to %d unsuccessfully\n", data_in, addr);
		end else begin
			$display ("Write %d to %d successfully\n", data_in, addr);
		end
	end
endtask

task APB_READ;
	input  [ADDR_WIDTH-1:0] addr;
	output [DATA_WIDTH-1:0] data_out;

	begin
		PSEL    = 0;
		PENABLE = 0;
		@(posedge PCLK); // Setup phase
		PWRITE  = 0;
		PSEL    = 1;
		PADDR   = addr;
		@(posedge PCLK); // Access phase
		PENABLE = 1;
		wait (PREADY);
		@(posedge PCLK);
		data_out = PRDATA;
		PSEL = 0;
		PENABLE = 0;
		if (PSLVERR) begin
			$display ("Read value %d from %d unsuccessfully\n", data_out, addr);
		end else begin
			$display ("Read value %d from %d successfully\n", data_out, addr);
		end
	end
endtask

initial begin
	PRESETn = 0; // Reset
	#20;
	@(posedge PCLK);
	PRESETn = 1; 
	
//	for (i = 0; i < 10; i = i+1) begin
//		APB_WRITE (i, 3*i+7);
//		#15;
//	end
//	repeat (100) begin
//		APB_WRITE ($random, read_data);
//		#15;
//	end
//	APB_READ (8'h00, read_data);
//	#15
	APB_WRITE (8'h02, 8'h01);
	APB_WRITE (8'h02, 8'h02);
	#10000;
	$stop;
end
endmodule
