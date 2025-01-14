`define		tdr_test
`define 	tcr_test
`define   	tsr_test
`define  	null_address
`define 	mixed_address
`define 	countup_forkjoin_pclk2
`define 	countup_forkjoin_pclk4
`define 	countup_forkjoin_pclk8
`define 	countup_forkjoin_pclk16
`define 	countdw_forkjoin_pclk2
`define 	countdw_forkjoin_pclk4
`define 	countdw_forkjoin_pclk8
`define 	countdw_forkjoin_pclk16
`define		countup_pause_countup_pclk2
`define 	countdw_pause_countdw_pclk2
`define		countup_reset_countdw_pclk2
`define 	countdw_reset_countup_pclk2
`define 	countup_reset_load_countdw_pclk2
`define 	countdw_reset_load_countdw_pclk2
`define		fake_overflow
`define 	fake_underflow
module Timer_Testbench(
	input	wire	[7:0] 	address,
	input	wire	[7:0]	data
);
	// Internal reg and wire declarations
    reg         PCLK_reg;
    reg         RST_reg;
    reg         PSEL;
    reg         PENABLE;
    reg         PWRITE;
    reg [7:0]   PADDR;
    reg [7:0]   PWDATA;
    reg [7:0]   read_data;
    wire        PREADY;
    wire        PSLVERR;
    wire[7:0]   PRDATA;
    wire[3:0]   Cks;


	// External clock signal generator
    clock_divider clock_divider_1(
		.clk(PCLK_reg),
		.rst(RST_reg),
		.clk_div2(Cks[0]),
		.clk_div4(Cks[1]),
		.clk_div8(Cks[2]),
		.clk_div16(Cks[3])
	);

	// 8-bit Timer module
    Timer_8bits Timer_8bits_dut(
        .PCLK(PCLK_reg),
        .PRESETn(RST_reg),
        .PSEL(PSEL),
        .PENABLE(PENABLE),
        .PWRITE(PWRITE),
        .PADDR(PADDR),
        .PWDATA(PWDATA),
        .Clk(Cks),
        .PREADY(PREADY),
        .PSLVERR(PSLVERR),
        .PRDATA(PRDATA)
    );

	integer 		COUNT_PAUSE 	= 15;
	integer 		STOP_ENB_TIME 	= 7;	//STOP_ENB_TIME must < COUNT_PAUSE
	reg		[7:0]	Pre_reset_value;

	/* Test case when both PSEL and PENABLE appear */
	task PSEL_PENABLE_appear;
		input [7:0] addr;
		input [7:0] data_in;

		begin
			PADDR	= 0;
			PWDATA	= 0;
			PSEL	= 0;
			PENABLE = 0;
			PWRITE  = 0;
			@(posedge PCLK_reg); // Setup phase
			PWRITE	= 1;
			PSEL	= 1;
			PADDR	= addr;
			PWDATA	= data_in;
			@(posedge PCLK_reg);
			PSEL 	= 0;
			#20;
		end
	endtask

	/* APB Write transaction simulate task */
	task APB_WRITE;
		input [7:0] addr;
		input [7:0] data_in;

		begin
			PADDR	= 0;
			PWDATA	= 0;
			PSEL	= 0;
			PENABLE = 0;
			PWRITE  = 0;
			@(posedge PCLK_reg); // Setup phase
			PWRITE	= 1;
			PSEL	= 1;
			PADDR	= addr;
			PWDATA	= data_in;
			@(posedge PCLK_reg); // Access phase
			PENABLE = 1;
			wait (PREADY);
			@(posedge PCLK_reg);
			PSEL	= 0;
			PENABLE	= 0;
			PWRITE	= 0;
			if (PSLVERR) begin
				$display ("[%0t ns] - [FAILED] Write 8'h%h to address 8'h%h.",$time, data_in, addr);
			end else begin
				$display ("[%0t ns] - [SUCCESS] Write 8'h%h to address 8'h%h.",$time, data_in, addr);
			end
		end
	endtask

	task APB_WRITE_2;
		input [7:0] addr;
		input [7:0] data_in;

		begin
			PADDR	= 0;
			PWDATA	= 0;
			PSEL	= 0;
			PENABLE = 0;
			PWRITE  = 0;
			@(posedge PCLK_reg); // Setup phase
			PWRITE	= 1;
			PSEL	= 1;
			PADDR	= addr;
			PWDATA	= data_in;
			@(posedge PCLK_reg); // Access phase
			PENABLE = 1;
			wait (PREADY);
			PSEL	= 0;
			PENABLE = 0;
			@(posedge PCLK_reg);
			PSEL	= 0;
			PENABLE	= 0;
			PWRITE	= 0;
			if (PSLVERR) begin
				$display ("[%0t ns] - [FAILED] Write 8'h%h to address 8'h%h.",$time, data_in, addr);
			end else begin
				$display ("[%0t ns] - [SUCCESS] Write 8'h%h to address 8'h%h.",$time, data_in, addr);
			end
		end
	endtask

	/* APB Read transaction simulate task */
	task APB_READ;
		input  [7:0] addr;
		output [7:0] data_out;

		begin
			PSEL    = 0;
			PENABLE = 0;
			@(posedge PCLK_reg); // Setup phase
			PWRITE  = 0;
			PSEL    = 1;
			PADDR   = addr;
			@(posedge PCLK_reg); // Access phase
			PENABLE = 1;
			wait (PREADY);
			@(posedge PCLK_reg);
			data_out = PRDATA;
			PSEL = 0;
			PENABLE = 0;
			if (PSLVERR) begin
				$display ("[%0t ns] - [FAILED] Read value 8'h%h from address 8'h%h.",$time, data_out, addr);
			end else begin
				$display ("[%0t ns] - [SUCCESS] Read value 8'h%h from address 8'h%h.",$time, data_out, addr);
			end
		end
	endtask

	/* Register test with selected address */
	task REG_random_value_test;
		input	[7:0]	addr;
		integer			ran_value;
		integer			i;
		begin
			$display("[%0t ns] >> Check default value.", $time);
			APB_READ(addr, read_data);
			for(i = 0; i < 256; i = i + 1) begin
			$display("[Attempt %0d] Random value test to register 8'h%h.", i, addr);
			//ran_value = $random(ran_value);
			APB_WRITE(addr, i);
			APB_READ(addr, read_data);
			$display("[%0t ns] - Attempt ended.\n", $time);
			end
			$display("\n");
		end
	endtask

	/* Testing random address with random value */
	task REG_test_random_value_full_addr;
		integer			ran_value;
		integer			ran_addr;
		integer 		addr;
		integer			i;
		begin
			$display("\n");
			$display("###### Register test with random address and random value ######");	

			for(i = 0; i < 256; i = i + 1) begin
				addr = i;
				$display("[Attempt %0d] Random address and value test on register 8'h%h.", i, addr);
				if((addr == 8'h00) || (addr == 8'h01) || (addr == 8'h02)) begin
					ran_value = $random(ran_value)/16843009;
					APB_WRITE(addr, ran_value);
					APB_READ(addr, read_data);
				end else begin
					ran_value = $random(ran_value)/16843009;
					APB_WRITE(addr, ran_value);
					if(PSLVERR == 1'b1) begin
						$display("[%0t ns] - [FAILED] NULL-ADDRESS.", $time);
					end
				end
				$display("\n");
			end
		end
	endtask

	/* Reset task */
	task Reset_Task;
		begin
			#20;
			RST_reg = 0;
			#20;
			RST_reg = 1;
		end
	endtask

	/* Initialize PCLK clock pulse to start simulation */
	initial begin
			PCLK_reg = 1'b0;
			forever #5 PCLK_reg = ~PCLK_reg;
	end

	initial begin
		RST_reg = 0;
		#20
		RST_reg = 1;
		APB_WRITE_2(8'h00, 8'hFF);
		
		`ifdef tdr_test
			$display("###### (TEST 01: TDR register test) ######");
			REG_random_value_test(8'h00);
		`endif 
		Reset_Task;

		`ifdef tcr_test
			$display("###### (TEST 02: TCR register test) ######");
			REG_random_value_test(8'h01);
		`endif 
		Reset_Task;

		`ifdef tsr_test
			$display("###### (TEST 03: TSR register test) ######");
			REG_random_value_test(8'h02);
		`endif 
		Reset_Task;

		`ifdef null_address
			$display("###### (TEST 04: Null address test) ######");
			REG_test_random_value_full_addr;
		`endif
		Reset_Task;

		`ifdef mixed_address
			$display("###### (TEST 05: Mixed address test) ######");
			REG_test_random_value_full_addr;
		`endif
		Reset_Task;

		`ifdef countup_forkjoin_pclk2
			$display("###### (TEST 06: Countup forkjoin pclk*2) ######");
			$display("[%0t ns] - Load random value to TDR register.", $time);
			APB_WRITE(8'h00, $random);
			APB_WRITE(8'h01, 8'h80);
			fork
				// Thread 1
				begin
					$display("[%0t ns] >> [Thread 1] Start countup.", $time);
					APB_WRITE(8'h01, 8'h10);
					APB_READ(8'h01, read_data);
					#100
					while (Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.counter_2.COUNT_OUT < 255) begin
						//$display("[%0t ns] - ...", $time);
						#20;
					end
					#20 // wait a cycle for the raising edge
					repeat(3) begin
						@(posedge Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.Signal_Counter_wire)
						if(Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.over_flow) begin
							$display("[%0t ns] - [Thread 1][PASS]", $time);
						end else begin
							$display("[%0t ns] - [Thread 1][FAULTY]", $time);
						end
					end
					$display("[%0t ns] - Finish thread 1.\n", $time);
				end
				
				begin
					$display("[%0t ns] >> [Thread 2] Start countup.", $time);
					APB_WRITE(8'h01, 8'h10);
					APB_READ(8'h01, read_data);
					#100
					while (Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.counter_2.COUNT_OUT < 170) begin
						//$display("[%0t ns] - ...", $time);
						#20;
					end
					repeat(3) begin
						@(posedge Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.Signal_Counter_wire)
						if(Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.over_flow) begin
							$display("[%0t ns] - [Thread 2][FAULTY]", $time);
						end else begin
							$display("[%0t ns] - [Thread 2][PASS]", $time);
						end
					end
					$display("[%0t ns] - Finish thread 2.", $time);
				end
			join
		`endif
		
		Reset_Task;

		`ifdef countup_forkjoin_pclk4
			$display("###### (TEST 07: Countup forkjoin pclk*4) ######");
			$display("[%0t ns] - Load random value to TDR register.", $time);
			APB_WRITE(8'h00, $random);
			APB_WRITE(8'h01, 8'h80);
			fork
				// Thread 1
				begin
					$display("[%0t ns] >> [Thread 1] Start countup.", $time);
					APB_WRITE(8'h01, 8'h11);
					APB_READ(8'h01, read_data);
					#100
					while (Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.counter_2.COUNT_OUT < 255) begin
						//$display("[%0t ns] - ...", $time);
						#20;
					end
					#20 // wait a cycle for the raising edge
					repeat(3) begin
						@(posedge Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.Signal_Counter_wire)
						if(Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.over_flow) begin
							$display("[%0t ns] - [Thread 1][PASS]", $time);
						end else begin
							$display("[%0t ns] - [Thread 1][FAULTY]", $time);
						end
					end
					$display("[%0t ns] - Finish thread 1.\n", $time);
				end
				
				begin
					$display("[%0t ns] >> [Thread 2] Start countup.", $time);
					APB_WRITE(8'h01, 8'h11);
					APB_READ(8'h01, read_data);
					#100
					while (Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.counter_2.COUNT_OUT < 170) begin
						//$display("[%0t ns] - ...", $time);
						#20;
					end
					repeat(3) begin
						@(posedge Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.Signal_Counter_wire)
						if(Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.over_flow) begin
							$display("[%0t ns] - [Thread 2][FAULTY]", $time);
						end else begin
							$display("[%0t ns] - [Thread 2][PASS]", $time);
						end
					end
					$display("[%0t ns] - Finish thread 2.", $time);
				end
			join
		`endif

		Reset_Task;

		`ifdef countup_forkjoin_pclk8
			$display("###### (TEST 08: Countup forkjoin pclk*8) ######");
			$display("[%0t ns] - Load random value to TDR register.", $time);
			APB_WRITE(8'h00, $random);
			APB_WRITE(8'h01, 8'h80);
			fork
				// Thread 1
				begin
					$display("[%0t ns] >> [Thread 1] Start countup.", $time);
					APB_WRITE(8'h01, 8'h12);
					APB_READ(8'h01, read_data);
					#100
					while (Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.counter_2.COUNT_OUT < 255) begin
						//$display("[%0t ns] - ...", $time);
						#20;
					end
					#20 // wait a cycle for the raising edge
					repeat(3) begin
						@(posedge Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.Signal_Counter_wire)
						if(Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.over_flow) begin
							$display("[%0t ns] - [Thread 1][PASS]", $time);
						end else begin
							$display("[%0t ns] - [Thread 1][FAULTY]", $time);
						end
					end
					$display("[%0t ns] - Finish thread 1.\n", $time);
				end
				
				begin
					$display("[%0t ns] >> [Thread 2] Start countup.", $time);
					APB_WRITE(8'h01, 8'h12);
					APB_READ(8'h01, read_data);
					#100
					while (Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.counter_2.COUNT_OUT < 170) begin
						//$display("[%0t ns] - ...", $time);
						#20;
					end
					repeat(3) begin
						@(posedge Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.Signal_Counter_wire)
						if(Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.over_flow) begin
							$display("[%0t ns] - [Thread 2][FAULTY]", $time);
						end else begin
							$display("[%0t ns] - [Thread 2][PASS]", $time);
						end
					end
					$display("[%0t ns] - Finish thread 2.", $time);
				end
			join
		`endif

		Reset_Task;

		`ifdef countup_forkjoin_pclk16
			$display("###### (TEST 09: Countup forkjoin pclk*16) ######");
			$display("[%0t ns] - Load random value to TDR register.", $time);
			APB_WRITE(8'h00, $random);
			APB_WRITE(8'h01, 8'h80);
			fork
				// Thread 1
				begin
					$display("[%0t ns] >> [Thread 1] Start countup.", $time);
					APB_WRITE(8'h01, 8'h13);
					APB_READ(8'h01, read_data);
					#100
					while (Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.counter_2.COUNT_OUT < 255) begin
						//$display("[%0t ns] - ...", $time);
						#20;
					end
					#20 // wait a cycle for the raising edge
					repeat(3) begin
						@(posedge Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.Signal_Counter_wire)
						if(Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.over_flow) begin
							$display("[%0t ns] - [Thread 1][PASS]", $time);
						end else begin
							$display("[%0t ns] - [Thread 1][FAULTY]", $time);
						end
					end
					$display("[%0t ns] - Finish thread 1.\n", $time);
				end
				
				begin
					$display("[%0t ns] >> [Thread 2] Start countup.", $time);
					APB_WRITE(8'h01, 8'h13);
					APB_READ(8'h01, read_data);
					#100
					while (Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.counter_2.COUNT_OUT < 170) begin
						//$display("[%0t ns] - ...", $time);
						#20;
					end
					repeat(3) begin
						@(posedge Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.Signal_Counter_wire)
						if(Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.over_flow) begin
							$display("[%0t ns] - [Thread 2][FAULTY]", $time);
						end else begin
							$display("[%0t ns] - [Thread 2][PASS]", $time);
						end
					end
					$display("[%0t ns] - Finish thread 2.", $time);
				end
			join
		`endif

		Reset_Task;

		`ifdef countdw_forkjoin_pclk2
			$display("###### (TEST 10: Countdw forkjoin pclk*2) ######");
			$display("[%0t ns] - Load random value to TDR register.", $time);
			APB_WRITE(8'h00, $random);
			APB_WRITE(8'h01, 8'h80);
			fork
				// Thread 1
				begin
					$display("[%0t ns] >> [Thread 1] Start countup.", $time);
					APB_WRITE(8'h01, 8'h30);
					APB_READ(8'h01, read_data);
					#100
					while (Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.counter_2.COUNT_OUT > 0) begin
						//$display("[%0t ns] - ...", $time);
						#20;
					end
					#20 // wait a cycle for the raising edge
					repeat(3) begin
						@(posedge Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.Signal_Counter_wire)
						if(Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.under_flow) begin
							$display("[%0t ns] - [Thread 1][PASS]", $time);
						end else begin
							$display("[%0t ns] - [Thread 1][FAULTY]", $time);
						end
					end
					$display("[%0t ns] - Finish thread 1.\n", $time);
				end
				
				begin
					$display("[%0t ns] >> [Thread 2] Start countup.", $time);
					APB_WRITE(8'h01, 8'h30);
					APB_READ(8'h01, read_data);
					#100
					while (Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.counter_2.COUNT_OUT >85) begin
						//$display("[%0t ns] - ...", $time);
						#20;
					end
					repeat(3) begin
						@(posedge Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.Signal_Counter_wire)
						if(Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.under_flow) begin
							$display("[%0t ns] - [Thread 2][FAULTY]", $time);
						end else begin
							$display("[%0t ns] - [Thread 2][PASS]", $time);
						end
					end
					$display("[%0t ns] - Finish thread 2.", $time);
				end
			join
		`endif

		Reset_Task;

		`ifdef countdw_forkjoin_pclk4
			$display("###### (TEST 11: Countdw forkjoin pclk*4) ######");
			$display("[%0t ns] - Load random value to TDR register.", $time);
			APB_WRITE(8'h00, $random);
			APB_WRITE(8'h01, 8'h80);
			fork
				// Thread 1
				begin
					$display("[%0t ns] >> [Thread 1] Start countup.", $time);
					APB_WRITE(8'h01, 8'h31);
					APB_READ(8'h01, read_data);
					#100
					while (Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.counter_2.COUNT_OUT > 0) begin
						//$display("[%0t ns] - ...", $time);
						#20;
					end
					#20 // wait a cycle for the raising edge
					repeat(3) begin
						@(posedge Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.Signal_Counter_wire)
						if(Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.under_flow) begin
							$display("[%0t ns] - [Thread 1][PASS]", $time);
						end else begin
							$display("[%0t ns] - [Thread 1][FAULTY]", $time);
						end
					end
					$display("[%0t ns] - Finish thread 1.\n", $time);
				end
				
				begin
					$display("[%0t ns] >> [Thread 2] Start countup.", $time);
					APB_WRITE(8'h01, 8'h31);
					APB_READ(8'h01, read_data);
					#100
					while (Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.counter_2.COUNT_OUT > 85) begin
						//$display("[%0t ns] - ...", $time);
						#20;
					end
					repeat(3) begin
						@(posedge Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.Signal_Counter_wire)
						if(Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.under_flow) begin
							$display("[%0t ns] - [Thread 2][FAULTY]", $time);
						end else begin
							$display("[%0t ns] - [Thread 2][PASS]", $time);
						end
					end
					$display("[%0t ns] - Finish thread 2.", $time);
				end
			join
		`endif

		Reset_Task;

		`ifdef countdw_forkjoin_pclk8
			$display("###### (TEST 12: Countdw forkjoin pclk*8) ######");
			$display("[%0t ns] - Load random value to TDR register.", $time);
			APB_WRITE(8'h00, $random);
			APB_WRITE(8'h01, 8'h80);
			fork
				// Thread 1
				begin
					$display("[%0t ns] >> [Thread 1] Start countup.", $time);
					APB_WRITE(8'h01, 8'h32);
					APB_READ(8'h01, read_data);
					#100
					while (Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.counter_2.COUNT_OUT > 0) begin
						//$display("[%0t ns] - ...", $time);
						#20;
					end
					#20 // wait a cycle for the raising edge
					repeat(3) begin
						@(posedge Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.Signal_Counter_wire)
						if(Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.under_flow) begin
							$display("[%0t ns] - [Thread 1][PASS]", $time);
						end else begin
							$display("[%0t ns] - [Thread 1][FAULTY]", $time);
						end
					end
					$display("[%0t ns] - Finish thread 1.\n", $time);
				end
				
				begin
					$display("[%0t ns] >> [Thread 2] Start countup.", $time);
					APB_WRITE(8'h01, 8'h32);
					APB_READ(8'h01, read_data);
					#100
					while (Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.counter_2.COUNT_OUT > 85) begin
						//$display("[%0t ns] - ...", $time);
						#20;
					end
					repeat(3) begin
						@(posedge Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.Signal_Counter_wire)
						if(Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.under_flow) begin
							$display("[%0t ns] - [Thread 2][FAULTY]", $time);
						end else begin
							$display("[%0t ns] - [Thread 2][PASS]", $time);
						end
					end
					$display("[%0t ns] - Finish thread 2.", $time);
				end
			join
		`endif

		Reset_Task;

		`ifdef countdw_forkjoin_pclk16
			$display("###### (TEST 13: Countdw forkjoin pclk*16) ######");
			$display("[%0t ns] - Load random value to TDR register.", $time);
			APB_WRITE(8'h00, $random);
			APB_WRITE(8'h01, 8'h80);
			fork
				// Thread 1
				begin
					$display("[%0t ns] >> [Thread 1] Start countup.", $time);
					APB_WRITE(8'h01, 8'h33);
					APB_READ(8'h01, read_data);
					#100
					while (Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.counter_2.COUNT_OUT > 0) begin
						//$display("[%0t ns] - ...", $time);
						#20;
					end
					#20 // wait a cycle for the raising edge
					repeat(3) begin
						@(posedge Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.Signal_Counter_wire)
						if(Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.under_flow) begin
							$display("[%0t ns] - [Thread 1][PASS]", $time);
						end else begin
							$display("[%0t ns] - [Thread 1][FAULTY]", $time);
						end
					end
					$display("[%0t ns] - Finish thread 1.\n", $time);
				end
				
				begin
					$display("[%0t ns] >> [Thread 2] Start countup.", $time);
					APB_WRITE(8'h01, 8'h33);
					APB_READ(8'h01, read_data);
					#100
					while (Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.counter_2.COUNT_OUT > 85) begin
						//$display("[%0t ns] - ...", $time);
						#20;
					end
					repeat(3) begin
						@(posedge Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.Signal_Counter_wire)
						if(Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.under_flow) begin
							$display("[%0t ns] - [Thread 2][FAULTY]", $time);
						end else begin
							$display("[%0t ns] - [Thread 2][PASS]", $time);
						end
					end
					$display("[%0t ns] - Finish thread 2.", $time);
				end
			join
		`endif

		APB_WRITE(8'h02, 8'hFF);
		Reset_Task;

		`ifdef countup_pause_countup_pclk2
			$display("###### (TEST 14: Countup pause countup pclk*2) ######");
			$display("[%0t ns] - Write random value to TDR register.", $time);
			APB_WRITE(8'h00, $random);
			APB_WRITE(8'h01, 8'h80);
			$display("[%0t ns] - Setting the condition", $time);
			APB_WRITE(8'h01, 8'h00);
			APB_WRITE(8'h01, 8'h10);
			while(COUNT_PAUSE > 0) begin
				COUNT_PAUSE = COUNT_PAUSE - 1;
				if(COUNT_PAUSE == STOP_ENB_TIME) begin
					$display("[%0t ns] - Disable enable bit during pause section.", $time);
					APB_WRITE(8'h01, 8'h00);
				end
				#20;
			end
			// Check if after the pause overflow signal trigger or not?
			if(Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.over_flow) begin
				$display("[%0t ns] - [FAULTY]", $time);
			end else begin
				$display("[%0t ns] - [PASS]", $time);
			end
			// Enbale the counter
			APB_WRITE(8'h01, 8'h10);
			// Wait for count value equal 255 then reset to 0.
			while (Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.counter_2.COUNT_OUT != 8'h00) begin
				#20;
			end
			if(Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.over_flow) begin
				$display("[%0t ns] - [PASS]", $time);
			end else begin
				$display("[%0t ns] - [FAULTY]", $time);
			end
			$display("\n");
		`endif

		`ifdef countdw_pause_countdw_pclk2
			COUNT_PAUSE = COUNT_PAUSE + 15;
			$display("###### (TEST 15: Countup pause countup pclk*2) ######");
			$display("[%0t ns] - Write random value to TDR register.", $time);
			APB_WRITE(8'h00, $random);
			APB_WRITE(8'h01, 8'h80);
			$display("[%0t ns] - Setting the condition", $time);
			APB_WRITE(8'h01, 8'h20);
			APB_WRITE(8'h01, 8'h30);
			while(COUNT_PAUSE > 0) begin
				COUNT_PAUSE = COUNT_PAUSE - 1;
				if(COUNT_PAUSE == STOP_ENB_TIME) begin
					$display("[%0t ns] - Disable enable bit during pause section.", $time);
					APB_WRITE(8'h01, 8'h00);
				end
				#20;
			end
			// Check if after the pause overflow signal trigger or not?
			if(Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.under_flow) begin
				$display("[%0t ns] - [FAULTY]", $time);
			end else begin
				$display("[%0t ns] - [PASS]", $time);
			end
			// Enbale the counter
			APB_WRITE(8'h01, 8'h30);
			// Wait for count value equal 255 then reset to 0.
			while (Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.counter_2.COUNT_OUT != 8'hFF) begin
				#20;
			end
			if(Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.under_flow) begin
				$display("[%0t ns] - [PASS]", $time);
			end else begin
				$display("[%0t ns] - [FAULTY]", $time);
			end
			$display("\n");
		`endif

		APB_WRITE(8'h02, 8'h03);

		`ifdef countup_reset_countdw_pclk2
			$display("###### (TEST 16: Countup reset countdw pclk*2) ######");
			$display("[%0t ns] - Write random value to TDR register.", $time);
			APB_WRITE(8'h00, $random);
			APB_WRITE(8'h01, 8'h80);
			$display("[%0t ns] - Setting the condition", $time);
			APB_WRITE(8'h01, 8'h00);
			APB_WRITE(8'h01, 8'h10);
			#1000 // wait 1000 ns then reset
			// Save the value before reset.
			Pre_reset_value <= Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.counter_2.COUNT_OUT;
			// Reset
			RST_reg = 0;
			#20
			RST_reg = 1;
			APB_READ(8'h00, read_data);
			APB_READ(8'h01, read_data);
			APB_READ(8'h02, read_data);
			if((Timer_Testbench.Timer_8bits_dut.Read_Write_Control_1.TDR == 8'h00) 
				&& (Timer_Testbench.Timer_8bits_dut.Read_Write_Control_1.TCR == 8'h00) 
				&& (Timer_Testbench.Timer_8bits_dut.Read_Write_Control_1.TSR == 8'h00))
				$display("[%0t ns] - [PASS]", $time);
			else
				$display("[%0t ns] - [FAILED]", $time);
			$display("[%0t ns] - Write Pre-reset value to TDR register.", $time);
			APB_WRITE(8'h00, Pre_reset_value);
			APB_WRITE(8'h01, 8'h80);
			$display("[%0t ns] - Setting the condition", $time);
			APB_WRITE(8'h01, 8'hA0);
			APB_WRITE(8'h01, 8'hB0);
			while (Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.counter_1.COUNT_OUT != 8'hFF) begin
				#20;
			end
			if(Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.under_flow) begin
				$display("[%0t ns] - [PASS]", $time);
			end else begin
				$display("[%0t ns] - [FAULTY]", $time);
			end
			$display("\n");
		`endif

		`ifdef countdw_reset_countup_pclk2
			$display("###### (TEST 17: Countdw reset countdw pclk*2) ######");
			$display("[%0t ns] - Write random value to TDR register.", $time);
			APB_WRITE(8'h00, $random);
			APB_WRITE(8'h01, 8'h80);
			$display("[%0t ns] - Setting the condition", $time);
			APB_WRITE(8'h01, 8'h20);
			APB_WRITE(8'h01, 8'h30);
			#1000 // wait 1000 ns then reset
			// Save the value before reset.
			Pre_reset_value <= Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.counter_2.COUNT_OUT;
			// Reset
			RST_reg = 0;
			#20
			RST_reg = 1;
			APB_READ(8'h00, read_data);
			APB_READ(8'h01, read_data);
			APB_READ(8'h02, read_data);
			if((Timer_Testbench.Timer_8bits_dut.Read_Write_Control_1.TDR == 8'h00) 
				&& (Timer_Testbench.Timer_8bits_dut.Read_Write_Control_1.TCR == 8'h00) 
				&& (Timer_Testbench.Timer_8bits_dut.Read_Write_Control_1.TSR == 8'h00))
				$display("[%0t ns] - [PASS]", $time);
			else
				$display("[%0t ns] - [FAILED]", $time);
			$display("[%0t ns] - Write Pre-reset value to TDR register.", $time);
			APB_WRITE(8'h00, Pre_reset_value);
			APB_WRITE(8'h01, 8'h80);
			$display("[%0t ns] - Setting the condition", $time);
			APB_WRITE(8'h01, 8'h90);
			while (Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.counter_1.COUNT_OUT != 8'h00) begin
				#20;
			end
			if(Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.over_flow) begin
				$display("[%0t ns] - [PASS]", $time);
			end else begin
				$display("[%0t ns] - [FAULTY]", $time);
			end
			#20
			RST_reg = 0;
			#20
			RST_reg = 1;
			$display("\n");
		`endif

		`ifdef countup_reset_load_countdw_pclk2
			$display("###### (TEST 18: Countup reset countdw pclk*2) ######");
			$display("[%0t ns] - Write random value to TDR register.", $time);
			APB_WRITE(8'h00, $random);
			APB_WRITE(8'h01, 8'h80);
			$display("[%0t ns] - Setting the condition", $time);
			APB_WRITE(8'h01, 8'h00);
			APB_WRITE(8'h01, 8'h10);
			#1000 // wait 1000 ns then reset
			// Save the value before reset.
			Pre_reset_value <= Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.counter_2.COUNT_OUT;
			// Reset
			RST_reg = 0;
			#20
			RST_reg = 1;
			APB_READ(8'h00, read_data);
			APB_READ(8'h01, read_data);
			APB_READ(8'h02, read_data);
			if((Timer_Testbench.Timer_8bits_dut.Read_Write_Control_1.TDR == 8'h00) 
				&& (Timer_Testbench.Timer_8bits_dut.Read_Write_Control_1.TCR == 8'h00) 
				&& (Timer_Testbench.Timer_8bits_dut.Read_Write_Control_1.TSR == 8'h00))
				$display("[%0t ns] - [PASS]", $time);
			else
				$display("[%0t ns] - [FAILED]", $time);
			$display("[%0t ns] - Write Pre-reset value to TDR register.", $time);
			APB_WRITE(8'h00, $random);
			APB_WRITE(8'h01, 8'h80);
			$display("[%0t ns] - Setting the condition", $time);
			APB_WRITE(8'h01, 8'hA0);
			APB_WRITE(8'h01, 8'hB0);
			while (Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.counter_1.COUNT_OUT != 8'hFF) begin
				#20;
			end
			if(Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.under_flow) begin
				$display("[%0t ns] - [PASS]", $time);
			end else begin
				$display("[%0t ns] - [FAULTY]", $time);
			end
			$display("\n");
		`endif

		`ifdef countdw_reset_load_countdw_pclk2
			$display("###### (TEST 19: Countdw reset countdw pclk*2) ######");
			$display("[%0t ns] - Write random value to TDR register.", $time);
			APB_WRITE(8'h00, $random);
			APB_WRITE(8'h01, 8'h80);
			$display("[%0t ns] - Setting the condition", $time);
			APB_WRITE(8'h01, 8'h20);
			APB_WRITE(8'h01, 8'h30);
			#1000 // wait 1000 ns then reset
			// Save the value before reset.
			Pre_reset_value <= Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.counter_2.COUNT_OUT;
			// Reset
			RST_reg = 0;
			#20
			RST_reg = 1;
			APB_READ(8'h00, read_data);
			APB_READ(8'h01, read_data);
			APB_READ(8'h02, read_data);
			if((Timer_Testbench.Timer_8bits_dut.Read_Write_Control_1.TDR == 8'h00) 
				&& (Timer_Testbench.Timer_8bits_dut.Read_Write_Control_1.TCR == 8'h00) 
				&& (Timer_Testbench.Timer_8bits_dut.Read_Write_Control_1.TSR == 8'h00))
				$display("[%0t ns] - [PASS]", $time);
			else
				$display("[%0t ns] - [FAILED]", $time);
			$display("[%0t ns] - Write Pre-reset value to TDR register.", $time);
			APB_WRITE(8'h00, $random);
			APB_WRITE(8'h01, 8'h80);
			$display("[%0t ns] - Setting the condition", $time);
			APB_WRITE(8'h01, 8'h90);
			while (Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.counter_1.COUNT_OUT != 8'h00) begin
				#20;
			end
			if(Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.over_flow) begin
				$display("[%0t ns] - [PASS]", $time);
			end else begin
				$display("[%0t ns] - [FAULTY]", $time);
			end
			#20
			RST_reg = 0;
			#20
			RST_reg = 1;
			$display("\n");
		`endif

		`ifdef fake_underflow
			$display("###### (TEST 20: Fake Underflow) ######");
			$display("[%0t ns] - Write 8'hFF to TDR register.", $time);
			APB_WRITE(8'h00, 8'h00);
			APB_WRITE(8'h01, 8'hA0);
			$display("[%0t ns] - Write 8'h00 to TDR register.", $time);
			APB_WRITE(8'h00, 8'hFF);
			APB_WRITE(8'h01, 8'hA0);
			$display("[%0t ns] - Turn off load data function.", $time);
			APB_WRITE(8'h01, 8'h20);
			if(Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.over_flow)
				$display("[%0t ns] - [FAULTY] OVF on.", $time);
			else
				$display("[%0t ns] - [PASS] OVF off.", $time);
			
			if(Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.under_flow)
				$display("[%0t ns] - [FAULTY] UNDF on.", $time);
			else
				$display("[%0t ns] - [PASS] UNDF off.", $time);
			$display("\n");
		`endif

		`ifdef fake_overflow
			$display("###### (TEST 21: Fake Overflow) ######");
			$display("[%0t ns] - Write 8'hFF to TDR register.", $time);
			APB_WRITE(8'h00, 8'hFF);
			APB_WRITE(8'h01, 8'h80);
			$display("[%0t ns] - Write 8'h00 to TDR register.", $time);
			APB_WRITE(8'h00, 8'h00);
			APB_WRITE(8'h01, 8'h80);
			$display("[%0t ns] - Turn off load data function.", $time);
			APB_WRITE(8'h01, 8'h00);
			if(Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.over_flow)
				$display("[%0t ns] - [FAULTY] OVF on.", $time);
			else
				$display("[%0t ns] - [PASS] OVF off.", $time);
			
			if(Timer_Testbench.Timer_8bits_dut.TCNT_sum_1.under_flow)
				$display("[%0t ns] - [FAULTY] UNDF on.", $time);
			else
				$display("[%0t ns] - [PASS] UNDF off.", $time);
			$display("\n");
		`endif
		//APB_WRITE(8'h02, read_data);
		PSEL_PENABLE_appear(8'h00, 8'hEE);

		$stop;
		
	end
endmodule
