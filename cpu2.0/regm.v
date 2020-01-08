`ifndef _regm
`define _regm

//用于调试的时候显示寄存器中值的参数
`ifndef DEBUG_CPU_REG
`define DEBUG_CPU_REG 1
`endif

//通用寄存器组,有32个32位寄存器
//可以同时读取两个寄存器
//写入的时候可以在同一个周期内读取写入的数据
//持续输出选中的两个寄存器
//通过写入使能信号控制写入
//$0寄存器永远输出0
module regm(
		input wire			clk,
		input wire  [4:0]	R_Reg1, R_Reg2,
		output wire [31:0]	R_data1, R_data2,
		input wire			RegWr,
		input wire	[4:0]	W_Reg,
		input wire	[31:0]	W_data);

	reg [31:0] mem [0:31];
	reg [5:0] index;
	reg [31:0] _data1, _data2;

	initial begin
		for (index = 0 ;index < 32;index = index+1) begin
			mem[index][31:0]=32'h0;
		end
	end

	//如果处于调试模式下则显示寄存器的值
	initial begin
		if (`DEBUG_CPU_REG) begin
			$display("      $0,       $1,       $2,       $3,       $4,       $5,       $6,       $7,       $8,       $9,,       $10");
			$monitor("%x, %x, %x, %x, %x, %x, %x, %x, %x, %x, %x",
					mem[0][31:0],
					mem[1][31:0],
					mem[2][31:0],
					mem[3][31:0],
					mem[4][31:0],
					mem[5][31:0],
					mem[6][31:0],
					mem[7][31:0],
					mem[8][31:0],
					mem[9][31:0],
					mem[10][31:0]
				);
		end
	end

	always @(*) begin
		if (R_Reg1 == 5'd0)
			_data1 = 32'd0;
		else if ((R_Reg1 == W_Reg) && RegWr)
			_data1 = W_data;
		else
			_data1 = mem[R_Reg1][31:0];
	end

	always @(*) begin
		if (R_Reg2 == 5'd0)
			_data2 = 32'd0;
		else if ((R_Reg2 == W_Reg) && RegWr)
			_data2 = W_data;
		else
			_data2 = mem[R_Reg2][31:0];
	end

	assign R_data1 = _data1;
	assign R_data2 = _data2;

	always @(posedge clk) begin
		if (RegWr && W_Reg != 5'd0) begin
			// 写入非$0寄存器
			mem[W_Reg] <= W_data;
		end
	end
endmodule

`endif
