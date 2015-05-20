`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: UCLA CS M152A
// Engineer: Aman Agarwal and Lowell Bander
// 
// Create Date:    13:31:25 04/30/2015 
// Design Name: 
// Module Name:    stopw 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module stopw(
    input Pause,
    input Reset,
    input Adjust,
    input Clock,
    input Select,
    output [3:0] Minute0,
    output [3:0] Minute1,
    output [3:0] Second0,
    output [3:0] Second1,
    output [7:0] seg,
    output [3:0] an
    );

    wire [5:0] Instruction;

	wire SecondsClock;
	wire MinutesClock;
	wire ResetForTimer;
	wire SecondsCount;
	wire MinutesCount;
	wire overflowSeconds;

	wire slowClock;
	wire fastClock;
	wire fasterClock;
	wire blinkyClock;
    
    wire [3:0] minute0;
    wire [3:0] minute1;
    wire [3:0] second0;
    wire [3:0] second1;
    
    clockConverter clockC (
		.Clock(Clock), 
        .Reset(Reset),
		.slowClock(slowClock), 
		.fastClock(fastClock), 
		.fasterClock(fasterClock), 
		.blinkyClock(blinkyClock)
	);

	state s (
		.Pause(Pause), 
		.ResetIn(Reset), 
		.Adjust(Adjust), 
		.Clock(Clock), 
		.Select(Select),
		.Instruction(Instruction)
	);

	instructionDecoder instDec (
		.Instruction(Instruction), 
		.SlowClock(slowClock), 
		.FastClock(fastClock), 
		.SecondsClock(SecondsClock), 
		.MinutesClock(MinutesClock), 
		.Reset(ResetForTimer), 
		.SecondsCount(SecondsCount), 
		.MinutesCount(MinutesCount), 
		.overflowSeconds(overflowSeconds)
	);

	timer timerMain (
		.SecondsClock(SecondsClock),
		.MinutesClock(MinutesClock),
		.Reset(Reset),
		.SecondsCount(SecondsCount),
		.MinutesCount(MinutesCount),
        .overflowSeconds(overflowSeconds),
		.Minute0(minute0),
		.Minute1(minute1),
		.Second0(second0),
		.Second1(second1)
	);
    
    timeToDisplay ttd (
        .Clock(fasterClock),
        .Reset(Reset),
        .Minute0(minute0),
        .Minute1(minute1),
        .Second0(second0),
        .Second1(second1),
        .seg(seg),
        .an(an)
    );
    
    assign Minute0 = minute0;
    assign Minute1 = minute1;
    assign Second0 = second0;
    assign Second1 = second1;


endmodule


module timeToDisplay (
    input Clock,
    input Reset,
    input [3:0] Minute0,
    input [3:0] Minute1,
    input [3:0] Second0,
    input [3:0] Second1,
//    output [7:0] Minute0Display,
//    output [7:0] Minute1Display,
//    output [7:0] Second0Display,
//    output [7:0] Second1Display
    output [7:0] seg,
    output [3:0] an
    );
    
    reg [7:0] seg;
    reg [3:0] an;
    
    localparam STATE0 = 2'b00,
               STATE1 = 2'b01,
               STATE2 = 2'b10,
               STATE3 = 2'b11;



    wire [7:0] Minute0Display;
    wire [7:0] Minute1Display;
    wire [7:0] Second0Display;
    wire [7:0] Second1Display;



    reg [1:0] nextState;
    reg [1:0] state;
    
    digitToDisplay min0 (
        .Clock(Clock),
        .Digit(Minute0),
        .Display(Minute0Display)
    );

    digitToDisplay min1 (
        .Clock(Clock),
        .Digit(Minute1),
        .Display(Minute1Display)
    );

    digitToDisplay sec0 (
        .Clock(Clock),
        .Digit(Second0),
        .Display(Second0Display)
    );

    digitToDisplay sec1 (
        .Clock(Clock),
        .Digit(Second1),
        .Display(Second1Display)
    );

    always @ (*) begin
        an = 4'b1111;
        seg = 8'b0000_0000;
        case(state)
            STATE0: an = 4'b1110;
            STATE1: an = 4'b1101;
            STATE2: an = 4'b1011;
            STATE3: an = 4'b0111;
        endcase
        case(state)
            STATE0: seg = Second0Display;
            STATE1: seg = Second1Display;
            STATE2: seg = Minute0Display;
            STATE3: seg = Minute1Display;
        endcase
    end

    always @ (posedge Clock or posedge Reset) begin
//        tempWire <= 2'b10;
        if (Reset) begin
            //tempWire <= 2'b11;
            state <= STATE0;
        end else begin
//            tempWire <= 2'b00;
            state <= nextState;
        end
    end

    
    always @ (*) begin
        nextState = state;
        case(state)
            STATE0: nextState = STATE1;
            STATE1: nextState = STATE2;
            STATE2: nextState = STATE3;
            STATE3: nextState = STATE0;
        endcase
    end
    

    
/*    always @ (posedge Clock or posedge Reset) begin
        if (Reset == 1'b1) begin
            state <= 0;
        end else begin
            state <= nextState;
        end
    end*/
    
    
endmodule

module digitToDisplay (
    input Clock,
    input [3:0] Digit,
    output [7:0] Display
    );
    
    reg [7:0] Display;
    
    always @ (posedge Clock) begin
        Display = 0;
        case (Digit)
            4'h0: Display = 8'b00111111;
            4'h1: Display = 8'b00000110;
            4'h2: Display = 8'b01011011;
            4'h3: Display = 8'b01001111;
            4'h4: Display = 8'b01100110;
            4'h5: Display = 8'b01101101;
            4'h6: Display = 8'b01111101;
            4'h7: Display = 8'b00000111;
            4'h8: Display = 8'b01111111;
            4'h9: Display = 8'b01101111;
            default: Display = 8'b00000000;
        endcase
        Display = ~Display;
    end
    
//    assign Display = temp;
    
endmodule
    



module clockConverter (
    input Reset,
    input Clock, // 100Mhz master clock
    output slowClock, // 1Hz
    output fastClock, // 2Hz
    output fasterClock, // 50-700 Hz // 50 Hz
    output blinkyClock // > 1Hz // 5Hz
);

    wire slowCarry;
    wire fastCarry;
    wire fasterCarry;
    wire blinkyCarry;

//    wire [26:0] CountValue;
//    wire [26:0] evenFasterValue;
//    wire [26:0] fastValue;
//    wire [26:0] blinkyValue;

    counterN #(
        .N('d100_000_000)
//        .N('d100)
    ) slowClockCounter (
		.Clock(Clock), 
		.Reset(Reset), 
		.Data(0), 
		.Load(0), 
		.Count(1),
//		.Output(CountValue), 
		.Carry(slowCarry)
    );

    counterN #(
        .N('d50_000_000)
//        .N('d50)
    ) fastClockCounter (
		.Clock(Clock), 
		.Reset(Reset), 
		.Data(0), 
		.Load(0), 
		.Count(1),
//		.Output(fastValue), 
		.Carry(fastCarry)
    );
    

    counterN #(
        .N('d500_000)
//        .N('d2)
    ) fasterClockCounter (
		.Clock(Clock), 
		.Reset(Reset), 
		.Data(0), 
		.Load(0), 
		.Count(1),
//		.Output(evenFasterValue), 
		.Carry(fasterCarry)
    );

    counterN #(
        .N('d20_000_000)
//        .N('d20)
    ) blinkyCounter (
		.Clock(Clock), 
		.Reset(Reset), 
		.Data(0), 
		.Load(0), 
		.Count(1),
//		.Output(blinkyValue), 
		.Carry(blinkyCarry)
    );
    
//    always @ (posedge Clock or posedge Reset) begin
//    end

    assign slowClock = slowCarry;
    assign fastClock = fastCarry;
    assign fasterClock = fasterCarry;
    assign blinkyClock = blinkyCarry;

endmodule

module state (
    input Pause,
    input ResetIn,
    input Adjust,
    input Clock,
    input Select,
    output [5:0] Instruction
//    output SecondsClock,
//    output MinutesClock,
//    output Reset,
//    output SecondsCount,
//    output MinutesCount,
//    output overflowSeconds,
    );

    reg [5:0] Instruction;

    parameter SLOW = 1'b0;
    parameter FAST = 1'b1;

    parameter NORMAL = 2'b00;
    parameter [5:0] normalOutput = 6'b000101;
    
    parameter PAUSED = 2'b01;
    parameter [5:0] pausedOutput = 6'b000000;
    
    parameter UPDATESECOND = 2'b11;
    parameter [5:0] updateSecondOutput = 6'b100100;

    parameter UPDATEMINUTE = 2'b10;
    parameter [5:0] updateMinuteOutput = 6'b010010;
    
    parameter [5:0] resetOutput = 6'b001000;
    
    reg [1:0] state = NORMAL;
    
    reg previousPauseValue;

    always @(posedge Clock) begin 
        if (ResetIn) begin
            Instruction = resetOutput;
        end else begin
            case (state)
                NORMAL: begin
                    if (Pause & ~previousPauseValue) begin
                        state = PAUSED;
                        Instruction = pausedOutput;
                    end else if (Adjust) begin
                        if (Select) begin
                            state = UPDATESECOND;
                            Instruction = updateSecondOutput;
                        end else begin
                            state = UPDATEMINUTE;
                            Instruction = updateMinuteOutput;
                        end
                    end else begin
                        Instruction = normalOutput;
                    end
                end
                PAUSED: begin
                    if (Pause & ~previousPauseValue) begin
                        if (Adjust) begin
                            if (Select) begin
                                state = UPDATESECOND;
                                Instruction = updateSecondOutput;
                            end else begin
                                state = UPDATEMINUTE;
                                Instruction = updateMinuteOutput;
                            end
                        end else begin
                            state = NORMAL;
                            Instruction = normalOutput;
                        end
                    end else begin
                        Instruction = pausedOutput;
                    end
                end
                UPDATESECOND: begin
                    if (Pause & ~previousPauseValue) begin
                        state = PAUSED;
                        Instruction = pausedOutput;
                    end else if (!Adjust) begin
                        state = NORMAL;
                        Instruction = normalOutput;
                    end else if (!Select) begin
                        state = UPDATEMINUTE;
                        Instruction = updateMinuteOutput;
                    end else begin
                        Instruction = updateSecondOutput;
                    end
                end
                UPDATEMINUTE: begin
                    if (Pause & ~previousPauseValue) begin
                        state = PAUSED;
                        Instruction = pausedOutput;
                    end else if (!Adjust) begin
                        state = NORMAL;
                        Instruction = normalOutput;
                    end else if (Select) begin
                        state = UPDATESECOND;
                        Instruction = updateSecondOutput;
                    end else begin
                        Instruction = updateMinuteOutput;
                    end
                end
            endcase
        end
        
        previousPauseValue <= Pause;
        
    end
    
endmodule

module instructionDecoder(
    input [5:0] Instruction,
//    input SecondsClock,
//    input MinutesClock,
//    input Reset,
//    input SecondsCount,
//    input MinutesCount,
//    input overflowSeconds,
    input SlowClock,
    input FastClock,
    output SecondsClock,
    output MinutesClock,
    output Reset,
    output SecondsCount,
    output MinutesCount,
    output overflowSeconds
    );

    assign SecondsClock = Instruction[5] ? FastClock : SlowClock;
    assign MinutesClock = Instruction[4] ? FastClock : SlowClock;
    assign Reset = Instruction[3];
    assign SecondsCount = Instruction[2];
    assign MinutesCount = Instruction[1];
    assign overflowSeconds = Instruction[0];

endmodule




module timer(
    input SecondsClock,
    input MinutesClock,
    input Reset,
    input SecondsCount,
    input MinutesCount,
    input overflowSeconds,
    output [3:0] Minute0,
    output [3:0] Minute1,
    output [3:0] Second0,
    output [3:0] Second1
    );
    

    wire secondsCarry;
    wire minutesCarry;
    
    wire minutesCount;
    
    counter60 Seconds (
        .Clock(SecondsClock),
        .Reset(Reset),
        .Count(SecondsCount),
        .lowerDigit(Second0),
        .upperDigit(Second1),
        .Carry(secondsCarry)
    );
    
    assign minutesCount = (SecondsCount & secondsCarry & overflowSeconds) | MinutesCount;

    counter60 Minutes (
        .Clock(MinutesClock),
        .Reset(Reset),
        .Count(minutesCount),
        .lowerDigit(Minute0),
        .upperDigit(Minute1),
        .Carry(minutesCarry)
    );


endmodule
    

module counter60(
    input Clock,
    input Reset,
    input Count,
    output [3:0] lowerDigit,
    output [3:0] upperDigit,
    output Carry
    );

    wire lowerCarry;
    wire upperCarry;
    
    counterN #(
        .N('d10)
    ) lowerCounter (
		.Clock(Clock), 
		.Reset(Reset), 
		.Data(0), 
		.Load(0), 
		.Count(Count), 
		.Output(lowerDigit), 
		.Carry(lowerCarry)
    );
    
    wire upperCount;
    assign upperCount = lowerCarry & Count;

    counterN #(
        .N('d6)
    ) upperCounter (
		.Clock(Clock), 
		.Reset(Reset), 
		.Data(0),
		.Load(0), 
		.Count(upperCount), 
		.Output(upperDigit), 
		.Carry(upperCarry)
    );
    
    assign Carry = upperCarry & lowerCarry;

endmodule


module counterN #(parameter [26:0] N = 'd16)(
    input Clock,
    input Reset,
    input [26:0] Data,
    input Load,
    input Count,
    output [26:0] Output,
    output Carry
    );
    
    reg [26:0] state;

    always  @(posedge Clock or posedge Reset) begin
        if (Reset) begin
            state <= 0;
        end else if (Load) begin
            state <= Data;
        end else if (Count) begin
            if (state == N - 1) begin
                state <= 0;
            end else begin
                state <= state + 1;
            end
        end
    end
    
    assign Output = state;
    assign Carry = (state == N - 1) ? 1 : 0;

endmodule


