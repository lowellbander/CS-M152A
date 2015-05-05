`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   12:08:22 04/28/2015
// Design Name:   fpcvt
// Module Name:   C:/Users/152/lowellaman/fpcvt/tb.v
// Project Name:  fpcvt
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: fpcvt
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb;

	// Inputs
	reg [11:0] D;
    
    reg clk;

	// Outputs
	wire S;
	wire [2:0] E;
	wire [3:0] F;
    
    reg [11:0] inst_mem [1024:0];

    integer index;
    integer testCases;
    integer testCaseInput;
    integer testCaseOutput;


	// Instantiate the Unit Under Test (UUT)
	fpcvt uut (
		.D(D), 
		.S(S), 
		.E(E), 
		.F(F)
	);

	initial begin
    
        clk = 0;
        
        
        for(index = 0; index < 1024; index = index + 1)
            inst_mem[index] = 0;
        
        $readmemb("test.txt", inst_mem);
        
        testCases = inst_mem[0];
        
        $display("File has %0d test cases", testCases);

        for(index = 0; index < testCases; index = index + 1) begin
            testCaseInput = index * 2 + 1;
            testCaseOutput = index * 2 + 2;
            D = inst_mem[testCaseInput];
            #100000;
            if (inst_mem[testCaseOutput] != {S, E, F}) begin
                $display("Failed test case %0d", index + 1);
                $display("D: %b, S: %0b, E: %b, F: %b", D, S, E, F);
            end else begin
                $display("Passed test case %0d", index + 1);
            end
        end

        $finish;

//		// Initialize Inputs
////		D = 0;
//
//		// Wait 100 ns for global reset to finish
//		#100;
//        
//		// Add stimulus here
//        D = 12'b000001111101;
//        
//        #100000;
//        
//        D = 12'b111001111101;
//
//        #10000;
//
//        D = 12'b0111_1111_1111;
//
//        #10000;
//
	end
      
    always #5 clk = ~clk;

      
      
endmodule

