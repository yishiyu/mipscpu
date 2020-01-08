`include "alu.v"
`include "ram.v"
`include "regr.v"
`include "RF.v"
`include "tsg.v"
`include "mcu.v"
`include "op_ext.v"
`include "alu_cu.v"


`ifndef _cpu
`define _cpu

module cpu(
    input wire clk
    );

    // | 输出引脚 |          作用          | 输出引脚 |         作用         |
    // | :------: | :--------------------: | :------: | :------------------: |
    // |   CLK    |        时钟信号        |  ALUOe   |     ALU 输出使能     |
    // |  PCOeh   |   PC 高 4 位输出总线   |  RegOe   |  通用寄存器输出使能  |
    // |  PCOel   |  PC 低 28 位输出总线   |  RegWr   |  通用寄存器写入使能  |
    // |   PCWr   |      PC 写入使能       |  RegSel  | 通用寄存器写入源选择 |
    // |   IRWr   |      IR 写入使能       |  MARWr   |     MAR 写入使能     |
    // |  ImmOeh  | 立即数高 4 位输出总线  |  MemRd   |     存储器读使能     |
    // |  ImmOel  | 立即数低 28 位输出总线 |  MemWr   |     存储器写使能     |
    // |  ExtSel  |    符号扩展方式选择    |  MDRSrc  |    MDR 写入源选择    |
    // |  ALUOp   |        ALU 操作        |  MDROe   |     MDR 输出使能     |
    // | ALUCtrl  |      ALU 操作控制      |  MDRWr   |     MDR 写入使能     |
    // |   AWr    |    A 暂存器写入使能    |  MemOe   |    存储器输出使能    |
    // |   BWr    |    B 暂存器写入使能    |

    wire [31:0] bus;        //32位总线
    wire [5:0] opcode;
    wire [31:0] ALU_out;
    wire Zero,OF;
    reg PCOeh,PCOel;
    reg PCWr,IRWr;
    reg ImmOeh,ImmOel;
    reg [1:0] ExtSel;
    reg [1:0] ALUOp;
    reg AWr,BWr;
    reg ALUOe;
    reg RegOe,RegWr;
    reg [1:0] RegSel;
    reg MemRd,MemWr,MemOe;
    reg MARWr;
    reg MDRSrc,MDROe,MDRWr;

    //主控制单元
    mcu mcu_bibibi(
        .clk(clk),
        .opcode(opcode),
        .ALU_out(ALU_out),
        .Zero(Zero),
        .OF(OF),
        .PCOeh(PCOeh),
        .PCOel(PCOel),
        .PCWr(PCWr),
        .IRWr(IRWr),
        .ImmOeh(ImmOeh),
        .ImmOel(ImmOel),
        .ExtSel(ExtSel),
        .ALUOp(ALUOp),
        .AWr(AWr),
        .BWr(BWr),
        .ALUOe(ALUOe),
        .RegOe(RegOe),
        .RegWr(RegWr),
        .RegSel(RegSel),
        .MemRd(MemRd),
        .MemWr(MemWr),
        .MemOe(MemOe),
        .MARWr(MARWr),
        .MDRSrc(MDRSrc),
        .MDROe(MDROe),
        .MDRWr(MDRWr)
    );

    //PC寄存器
    // input clk,
    // input Wr,
    // input wire [N-1:0] in,
    // output reg [N-1:0] out
    wire [3:0] PC_out_h;
    wire [27:0] PC_out_l;
    regr #(.N(32)) PC(
        .clk(clk),
        .Wr(PCWr),
        .in(bus),
        .out({PC_out_h,PC_out_l})
    );
    // input Ctrl,
    // input wire [N-1:0] in,
    // output reg [N-1:0] out
    tsg #(.N(4)) PC_h(
        .Ctrl(PCOeh),
        .in(PC_out_h),
        .out(bus[31:28])
    );
    tsg #(.N(28)) PC_l(
        .Ctrl(PCOel),
        .in(PC_out_l),
        .out(bus[27:0])
    );

    //IR寄存器
    wire [31:0] IR_out;
    assign opcode = IR_out[31:26];
    regr #(.N(32)) IR(
        .clk(clk),
        .Wr(IRWr),
        .in(bus),
        .out(IR_out)
    );
    // input wire [1:0] signal,
    // input wire [31:0] in,
    // output reg [3:0] sig_ext_h,
    // output reg [27:0] sig_ext_l
    wire [3:0] sig_ext_h;
    wire [27:0] sig_ext_l;
    op_ext Sig_Ext(
        .signal(ExtSel),
        .in(IR_out),
        .sig_ext_h(sig_ext_h),
        .sig_ext_l(sig_ext_l)
    );
    tsg #(.N(4)) Sig_Ext_h(
        .Ctrl(ImmOeh),
        .in(sig_ext_h),
        .out(bus[31:28])
    );
    tsg #(.N(28)) Sig_Ext_l(
        .Ctrl(ImmOel),
        .in(sig_ext_l),
        .out(bus[27:0])
    );

    //ALUCU
    // input wire [5:0] funct,
	// input wire [1:0] aluop,
	// output reg [2:0] aluctl
    wire [2:0] aluctrl;
    alu_cu alucu(
        .funct(IR_out[5:0]),
        .aluop(ALUOp),
        .aluctl(aluctrl)
    );
    
    //ALU辅助寄存器AB
    // input clk,
    // input Wr,
    // input wire [N-1:0] in,
    // output reg [N-1:0] out
    wire [31:0] A_out;
    wire [31:0] B_out;
    regr #(.N(32)) A(
        .clk(clk),
        .Wr(AWr),
        .in(bus),
        .out(A_out)
    );
    regr #(.N(32)) B(
        .clk(clk),
        .Wr(BWr),
        .in(bus),
        .out(B_out)
    );

    //数字逻辑计算器ALU
    // input        [2:0]	ALUCtrl,
    // input	    [31:0]	a, b,
    // output reg	[31:0]	out,
    // output				Zero,
    // output				OF
    alu alu_bibibi(
        .ALUCtrl(aluctrl),
        .a(A_out),
        .b(B_out),
        .out(ALU_out),
        .Zero(Zero),
        .OF(OF)
    );
    tsg #(.N(32)) ALU_OUT(
        .Ctrl(ALUOe),
        .in(ALU_out),
        .out(bus)
    );

    //通用寄存器组RF
    reg [4:0] Reg_addr;
    always @(*) begin
        case(RegSel)
            2'b00: Reg_addr = IR_out[25:21];
            2'b01: Reg_addr = IR_out[20:16];
            2'b10: Reg_addr = IR_out[15:11];
            default:Reg_addr = 5'b00000;
        endcase
    end
	// input wire			clk,
    // input wire	[31:0]	W_data,
    // output reg	[31:0]	R_data,
	// input wire	[4:0]	Reg,
    // input wire OE,
    // input wire Wr
    RF RF_bibibi(
        .clk(clk),
        .W_data(bus),
        .R_data(bus),
        .Reg(Reg_addr),
        .OE(RegOe),
        .Wr(RegWr)
    );

    //存储器
    // input clk,
    // input Wr,
    // input wire [N-1:0] in,
    // output reg [N-1:0] out
    wire [6:0] mem_addr;
    wire [31:0] mem_out;
    wire [31:0] mem_in;
    wire [31:0] mdr_in;
    assign mdr_in = (MDRSrc==1)?mem_out:bus;
    regr #(.N(7)) MAR(
        .clk(clk),
        .Wr(MARWr),
        .in(bus[6:0]),
        .out(mem_addr)
    );
    regr #(.N(32)) MDR(
        .clk(clk),
        .Wr(MDRWr),
        .in(mdr_in),
        .out(mem_in)
    );
    tsg #(.N(32)) mem_r(
        .Ctrl(MemOe),
        .in(mem_out),
        .out(bus)
    );
    tsg #(.N(32)) mem_w(
        .Ctrl(MDROe),
        .in(mem_in),
        .out(bus)
    );
    // input wire	[6:0]	Addr,
	// input wire			W, R,
	// input wire 	[31:0]	W_data,
	// output wire	[31:0]	R_data
    ram ram_bibibi(
        .Addr(mem_addr),
        .R_data(mem_out),
        .W_data(mem_in),
        .R(MemRd),
        .W(MemWr)
    );

endmodule

`endif