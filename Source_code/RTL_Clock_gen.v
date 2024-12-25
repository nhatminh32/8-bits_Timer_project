module clock_divider(
	input	wire	clk,
	input	wire	rst,
	output	wire	clk_div2,
	output	wire	clk_div4,
	output	wire	clk_div8,
	output	wire	clk_div16
);
	reg	[3:0]	div_count;

	always @(posedge clk or negedge rst) begin
		if (~rst) begin // start initialize div_count value 4'b0000 when rst signal is low
			div_count <= 4'b0000;
		end else begin
			div_count <= div_count + 1'b1;
		end
	end

	assign clk_div2  = div_count[0];
	assign clk_div4  = div_count[1];
	assign clk_div8  = div_count[2];
	assign clk_div16 = div_count[3];

endmodule

module clock_divider_tb;
	reg		clk;
	reg		rst;
	wire	clk_div2;
	wire	clk_div4;
	wire	clk_div8;
	wire	clk_div16;

	clock_divider dut (
		.clk(clk),
		.rst(rst),
		.clk_div2(clk_div2),
		.clk_div4(clk_div4),
		.clk_div8(clk_div8),
		.clk_div16(clk_div16)
	);
	initial begin
		clk = 0;
		forever #5 clk = ~clk;
	end

	initial begin
		rst = 1;
		#20;

		rst = 0;

		#400;

		rst = 1;
		#20;
		rst = 0;

		#400;

	end
endmodule
