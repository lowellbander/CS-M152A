module fpcvt(D, S, E, F
    );
	input [11:0] D;
	output S;
	output [2:0] E;
	output [3:0] F;
    
    
    wire [10:0] mag;
    wire [3:0] zeroCount;
    wire [3:0] exponent;
    
    wire round;
    wire overflow;
    
    wire [2:0] tempE;

    wire [3:0] tempF;
    wire [3:0] rv;


    twosComplementToSignMagnitude ttsm(.I(D), .S(S), .M(mag));
    
    leadingZeroesCount lzc(.I(mag), .O(zeroCount));
    
    assign exponent = (zeroCount > 7) ? 0 : 4'hb - zeroCount - 4'h4;
    
    assign tempE = exponent[2:0];
    
    extractSignicifandAndRoundBit esr(.I(mag), .exponent(tempE), .significand(tempF), .round(round), .zeros(zeroCount));

    roundValueIfRound rvir(.I(tempF), .roundedVal(rv), .Round(round), .overflow(overflow));

    handleOverflow ho(.I(D), .roundedVal(rv), .significand(F), .oldE(tempE), .exponent(E), .overflow(overflow));


endmodule

module twosComplementToSignMagnitude(I, S, M);
    input [11:0] I;
    output [0:0] S;
    output [10:0] M;
    
    reg [11:0] temp;

    always @(*)
    begin
        if (I[11]) begin
            temp = ~I + 1;
        end
    end
    
    assign M = (I[11]) ? temp[10:0] : I[10:0];

    assign S = I[11];
    
endmodule


module leadingZeroesCount(I, O);
    input [10:0] I;
    output [3:0] O;
    
    reg [3:0] temp;
    
    always @(*)
    begin
        if (I[10]) begin
            temp = 0;
        end else if(I[9]) begin
            temp = 1;
        end else if(I[8]) begin
            temp = 2;
        end else if(I[7]) begin
            temp = 3;
        end else if(I[6]) begin
            temp = 4;
        end else if(I[5]) begin
            temp = 5;
        end else if(I[4]) begin
            temp = 6;
        end else if(I[3]) begin
            temp = 7;
        end else if(I[2]) begin
            temp = 8;
        end else if(I[1]) begin
            temp = 9;
        end else if(I[0]) begin
            temp = 10;
        end else begin
            temp = 11;
        end
    end
    
    assign O = temp;

endmodule

module extractSignicifandAndRoundBit(I, exponent, significand, round, zeros);
    input [10:0] I;
    input [2:0] exponent;
    output [3:0] significand;
    output round;
    input [3:0] zeros;
    
    reg [10:0] shiftedInput;
    reg [2:0] shiftAmount;
   
    always @(*)
    begin
        /*shiftAmount = exponent - 1;
        if (exponent > 7) begin
            shiftAmount = 0;
        end*/

        shiftedInput = I;

        if (zeros >= 7) begin
            shiftAmount = 0;
            shiftedInput = shiftedInput << 1;
        end
        
        case (shiftAmount)
            1:shiftedInput = {1'b0, shiftedInput[10:1]};
            2:shiftedInput = {2'b00, shiftedInput[10:2]};
            3:shiftedInput = {3'b000, shiftedInput[10:3]};
            4:shiftedInput = {4'b0000, shiftedInput[10:4]};
            5:shiftedInput = {5'b0_0000, shiftedInput[10:5]};
        endcase

    end
    
    assign round = shiftedInput[0];
    assign significand = shiftedInput[4:1];
    
endmodule

module roundValueIfRound(I, roundedVal, Round, overflow);
    input [3:0] I;
    output [3:0] roundedVal;
    input Round;
    output overflow;

    reg [4:0] sum;
    
    always @(*)
    begin
        if (Round) begin
            sum = {0, I} + 1;
        end
    end

    assign overflow = Round ? sum[4] : 0;
    assign roundedVal = Round? sum[3:0] : I;

endmodule

module handleOverflow(I, roundedVal, significand, oldE, exponent, overflow);
    input [11:0] I;
    input [3:0] roundedVal;
    output [3:0] significand;
    output [2:0] exponent;
    input [2:0] oldE;
    input overflow;
   
    assign significand = (I == 12'h7FF || I == 12'h800) ? 4'hF : (overflow ? 4'h8 : roundedVal);
    assign exponent = (I == 12'h800) ? 3'h7 : (overflow ? oldE + 1 : oldE);

endmodule
