`ifndef _alu
`define _alu

// 000 AND
// 001 OR
// 010 ADD
// 011 SUB
// 100 小于置一
// 101 NOT(a)
// 110 NOR
// 111 XOR(异或)

module alu(
		input		[2:0]	ALUCtrl,
		input		[31:0]	a, b,
		output reg	[31:0]	out,
		output				Zero,
        output				OF);

	wire [31:0] sub_ab;
	wire [31:0] add_ab;
	wire 		oflow_add;
	wire 		oflow_sub;
	wire 		slt;

    //计算零标志位
	assign Zero = (0 == out);
	//assign Zero = 1'b1;

    //计算加减结果
	assign sub_ab = a - b;
	assign add_ab = a + b;

	// 计算时候溢出
	assign oflow_add = (a[31] == b[31] && add_ab[31] != a[31]) ? 1 : 0;
	assign oflow_sub = (a[31] != b[31] && sub_ab[31] != a[31]) ? 1 : 0;
	assign OF = (ALUCtrl == 3'b010) ? oflow_add : oflow_sub;

	// 计算小于置一运算结果
	assign slt = (oflow_sub==0)?sub_ab[31]:~(sub_ab[31]);

    //使用多路选择器输出计算结果
    // 000 AND
    // 001 OR
    // 010 ADD
    // 011 SUB
    // 100 小于置一
    // 101 NOT(a)
    // 110 NOR
    // 111 XOR(异或)
	always @(*) begin
		case (ALUCtrl)
        	3'b000:  out <= a & b;				/* and */
            3'd001:  out <= a | b;				/* or */
			3'b010:  out <= add_ab;				/* add */
            3'b011:  out <= sub_ab;				/* sub */
            3'b100:  out <= {{31{1'b0}}, slt};	/* slt */
            3'b101:  out <= ~ a;				/* not */
            3'b110:  out <= ~(a | b);     		/* nor */
            3'b111:  out <= a ^ b;				/* xor */
			default: out <= 0;
		endcase
	end

endmodule

`endif
