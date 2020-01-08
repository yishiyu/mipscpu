`ifndef _im
`define _im

//指令寄存器（instruction memory）
//为纯组合逻辑电路
//最大存放128条32位指令
//和dm一样,通过忽略接入线的低2位数据来实现伪字节寻址
module im(
	input wire 	[31:0] 	addr,
	output wire [31:0] 	data);

	//用于初始化的参数，指令的个数和指令的存放的文件
	parameter NMEM = 128;
	parameter IM_DATA = "im_data.txt";
	//初始化指令存储器
	initial begin
		$readmemh(IM_DATA, mem, 0, NMEM-1);
	end

	reg [31:0] mem [0:127];

	assign data = mem[addr[8:2]][31:0];

endmodule

`endif
