`ifndef _alu_cu
`define _alu_cu

//用于将输入的控制符转换为alu控制信号
module alu_cu(
		input wire [5:0] funct,
		input wire [1:0] aluop,
		output reg [2:0] aluctl);

	//暂存运算类型对应的指令
	reg [2:0] _funct;

	//根据aluop输出指定的操作指令
	//根据MIPS汇编指令的二进制码转换为对应的ALU操作指令
	// 参考网址: https://blog.csdn.net/qq_41848006/article/details/82256626
	// 000 AND  100100
    // 001 OR   100101
    // 010 ADD  100000
    // 011 SUB  100010
    // 100 SLT  101010
    // 101 NOT(a)    似乎mips指令集里并没有这条指令
    // 110 NOR       100111
    // 111 XOR(异或) 100110
	always @(*) begin
		case(funct[3:0])
			4'b0100:  _funct = 3'b000;	/* and */
			4'b0101:  _funct = 3'd001;	/* or */
			4'b0000:  _funct = 3'b010;	/* add */
			4'b0010:  _funct = 3'b011;	/* sub */
			4'b1010:  _funct = 3'b100;	/* slt */
			4'b0111:  _funct = 3'b110;	/* nor */
			4'b0110:  _funct = 3'b111;	/* xor */	
			default:  _funct = 3'b000;	/* and */
		endcase
	end

	//执行预定义的其他操作
	always @(*) begin
		case(aluop)
			2'd0: aluctl = 3'b010;	/* add */
			2'd1: aluctl = _funct;
			2'd2: aluctl = 3'b011;	/* sub */
			2'd3: aluctl = 3'b010;	/* add */
			default: aluctl = 0;
		endcase
	end

endmodule

`endif
