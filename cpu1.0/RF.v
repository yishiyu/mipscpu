`ifndef _RF
`define _RF

`ifndef DEBUG_CPU_REG
`define DEBUG_CPU_REG 1
`endif

// W_data--数据写入端
// R_data--数据输出端(可以输出高阻态)
// Reg-----寄存器地址输入
// OE------输出使能,高电平有效,低电平时输出高阻态
// Wr------写入使能
// 5位地址 32位数据
// 0寄存器永远输出0

module RF(
		input wire			clk,
        input wire	[31:0]	W_data,
        output reg	[31:0]	R_data,
		input wire	[4:0]	Reg,
        input wire OE,
        input wire Wr
        );

	reg [31:0] mem [0:31];  //128个32位存储单元
	
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

    //输出引脚控制
	always @(*) begin
		if (OE == 1'b1)
			R_data = (Reg==5'b0)?0:mem[Reg][31:0];
		else
			R_data = 32'bz;
	end

    //输入引脚控制
	always @(negedge clk) begin
        //如果写入使能有效 同时 输出使能无效
		if (Wr == 1'b1)
			mem[Reg] = W_data;
	end

endmodule

`endif