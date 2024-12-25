This directory contains 2 types of Verilog code:
- RTL code: Describe the operation of each IP in the 8-bit TIMER. "RTL" will be placed at the beginning of each file.
  Ex: RTL_Read_Write_Control.v

- Test bench: Contains test bench script for each IP. "TB" will be placed at the beginning of each file.
  Ex: TB_Read_Write_Control.v

RTL source code files include:
+ < Clock_gen.v >                contains RTL and testbench for the external clock generator.
+ < Control_Logic_RTL.v >        contains Verilog code for the Control logic block, TCR, TDR, and TSR register module.
+ < Read_Write_Control_RTL.v >   contains Verilog code for the Read/Write Control module using APB protocol.
+ < TCNT_RTL.v >                 contains Verilog code for D-flipflop, 2bits Mux, Synchronous Up/Down counter, Overflow/Underflow comparison block, and the TCNT module.
+ < Timer_RTL.v >                contains the final module of 8-bit TIMER.