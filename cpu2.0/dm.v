`ifndef _dm
`define _dm

//数据存储器
//假设为可以在单个时钟周期完成读写的理想数据存储器
//看起来是按字寻址,但是可以通过在CPU中接入地址线的[8:2]位来实现按字节寻址
//(dm本身其实还是按字寻址)
module dm(
		input wire			clk,
		input wire	[6:0]	Addr,
		input wire			Read, Write,
		input wire 	[31:0]	W_data,
		output wire	[31:0]	R_data);

    //128个32位存储单元
	reg [31:0] mem [0:127];
	//用于初始化的参数，数据的个数和数据的存放的文件
	parameter NMEM = 8;
	parameter DM_DATA = "dm_data.txt";
	//初始化数据存储器
	initial begin
		$readmemh(DM_DATA, mem, 0, NMEM-1);
	end

    //在时钟下降沿进行写入
	always @(posedge clk) begin
		if (Write) begin
			mem[Addr] <= W_data;
		end
	end

    //读取可以看作是组合逻辑电路
    //支持在同一个周期内同对同一个单元进行写入和读取
	assign R_data = Write ? W_data : mem[Addr][31:0];

endmodule

`endif
