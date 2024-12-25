# Project overview
The 8-bit TIMER includes the following features:
-	Selection of four clock sources.
-	Read/Write control using APB protocol. PSLVERR will activate high when the transmission fails.
-	Two counting operations, including normal operation and load data from TDR register operation.
-	Setting the Timer counter (TCNT) through the TCR register.
-	Showing Overflow and Underflow status on the TSR register, and the register status can be reset using APB WRITE transaction.

# Folder structure
1. Source_code
   - Include the RTL design and testbench for each module.
   - `RTL_Timer.v` and `TB_Timer.v` are this project’s top-level design and testbench.
2. Specification
   - Contains the `.pdf` and `.docx` versions of the 8-bit TIMER design document.
3. Coverage_report
   - Contains the coverage test report run on Questasim.
4. Testplan
   - Contains the `Timer_test_plan.xlsx` file describing test cases needed to be performed on the design.
   - All the code related to these tests is written in  `/Source_code/TB_Timer.v`.
