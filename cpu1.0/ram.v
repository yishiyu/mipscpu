`ifndef _ram
`define _ram

module ram(
		input wire	[6:0]	Addr,
		input wire			W, R,	//R参数实际上时没有用的
		input wire 	[31:0]	W_data,
		output wire	[31:0]	R_data);

	reg [31:0] mem [0:127];  //128个32位存储单元

	//初始化内存中的部分内容
	parameter NMEM = 12;
	parameter DATA = "data.txt";
	initial begin
		$readmemh(DATA, mem, 0);
	end

    //写入数据
	always @(*) begin
		if (W) begin
			mem[Addr] = W_data;
		end
	end

    //读取数据,支持同时写入和读取
	assign R_data = W ? W_data : mem[Addr][31:0];

	

endmodule

`endif
