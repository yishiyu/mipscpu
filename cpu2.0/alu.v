`ifndef _alu
`define _alu


//一个普通的alu(没有使用超前进位之类的东西)
module alu(
		input		[2:0]	M,
		input		[31:0]	A, B,
		output reg	[31:0]	OUT,
		output				ZERO,
		output  			OF);

	wire [31:0] sub_ab;
	wire [31:0] add_ab;
	wire 		oflow_add;
	wire 		oflow_sub;
	wire 		OF;
	wire 		slt;

	//零标志位
	assign ZERO = (0 == OUT);
	
	//计算加减结果
	assign sub_ab = A - B;
	assign add_ab = A + B;

	//计算溢出	
	assign oflow_add = (A[31] == B[31] && add_ab[31] != A[31]) ? 1 : 0;
	assign oflow_sub = (A[31] != B[31] && sub_ab[31] != A[31]) ? 1 : 0;
	assign OF = (M == 4'b0010) ? oflow_add : oflow_sub;

	//小于置一
	assign slt = (oflow_sub==0)?sub_ab[31]:~(sub_ab[31]);

	// 000 AND  100100
    // 001 OR   100101
    // 010 ADD  100000
    // 011 SUB  100010
    // 100 SLT  101010
    // 101 NOT(a)    似乎mips指令集里并没有这条指令
    // 110 NOR       100111
    // 111 XOR(异或) 100110
	always @(*) begin
		case (M)
			3'b000: OUT <= A & B;				/* and */
			3'd001: OUT <= A | B;				/* or */
			3'b010: OUT <= add_ab;				/* add */
			3'b011: OUT <= sub_ab;				/* sub */
			3'b100: OUT <= {{31{1'b0}}, slt};	/* slt */
			3'b101:  OUT <= ~ A;				/* not */
            3'b110:  OUT <= ~(A | B);			/* nor */
            3'b111:  OUT <= A ^ B;				/* xor */
			default: OUT <= 0;
		endcase
	end

endmodule

`endif
