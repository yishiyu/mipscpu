`ifndef _regr
`define _regr

// 级间寄存器，通用寄存器
// 每经过一个时钟周期更新一次
// 支持clear和hold信号
// 时钟下降沿触发
module regr (
	input clk,
	input clear,
	input hold,
	input wire [N-1:0] in,
	output reg [N-1:0] out);

	parameter N = 1;
	initial begin
        out = 32'h00000000;
    end

	always @(posedge clk) begin
		//优先执行hold信号
		//因为BEQ指令在遇到LW指令的阻塞的时候,应该先执行LW指令的阻塞
		//否则BEQ可能得到错误的数据
		//(RF会静默持续输出,如果错误信息刚好触发BEQ的条件,可能发生错误,需要等待LW指令把正确的数据送过来)
		if (hold)
			out <= out;
		else if (clear)
			out <= {N{1'b0}};
		else
			out <= in;
	end
endmodule

`endif
