`include "alu.v"
`include "dm.v"
`include "harzard_unit.v"
`include "im.v"
`include "regm.v"
`include "regr.v"
`include "mcu.v"


`ifndef DEBUG_CPU_STAGES
`define DEBUG_CPU_STAGES 1
`endif
module cpu(
    input wire clk
);

    // |  RegWrite  |               当前指令需要写入寄存器               |
    // |  MemtoReg  |     当前指令需要从存储器中获取数据并存入寄存器     |
    // |  MemWrite  |               当前指令需要写入存储器               |
    // |   ALUCtrl  |                 指定 ALU 运算类型                  |
    // |   ALUSrc   |        ALU 中 B 数据来源选择(寄存器/立即数)        |
    // |   RegDst   |   寄存器写入目的指定,指定需要写入的寄存器(Rt/Rd)   |
    // | BranchBEQ  | 当前指令为 BEQ 指令,需要在指令译码阶段判断是否跳转 |
    // |  BranchJ   |    当前指令为 J 指令,在指令译码阶段完成 J 跳转     |


    //=========================取指令阶段-----F=========================
    //PC寄存器
    //在参考的数据通路的基础上改原多路选择器为四选一型,以支持J指令
    reg [31:0] pc_in_F;           //最终输入PC寄存器的地址
    wire [31:0] pc_out_F;          //PC寄存器输出的地址
    wire [31:0] pc_plus4_F;        //PC寄存器原值加4(默认的下一条指令的位置)
    wire [31:0] pc_plus4_D;        //pc_plus_F传递到D阶段
    reg  [31:0] pc_BEQ_addr_D;     //BEQ指令对应的地址
    wire [31:0] pc_J_addr_D;       //J指令对应的地址
    wire pc_src_BEQ_D;             //BEQ指令产生的控制信号,跳转时为1,不跳转时为0
    wire pc_src_J_D;               //J指令产生的控制信号,跳转时为1,不跳转时为0

    //PC数据源多路选择器
    always @(*) begin
        case({pc_src_J_D,pc_src_BEQ_D})
            2'b00:pc_in_F <= pc_plus4_F;
            2'b01:pc_in_F <= pc_BEQ_addr_D;
            2'b10:pc_in_F <= pc_J_addr_D;
            2'b11:pc_in_F <= pc_J_addr_D;
            default:pc_in_F <= pc_plus4_F;
        endcase
    end

    wire stall_F;               //F阶段阻塞信号
    wire stall_D;               //D阶段阻塞信号
    wire flush_D;               //D阶段插入气泡信号

    //发生任何一种转移都需要在当前D阶段插入气泡
    //其实可以通过更复杂的设计使得J指令可以不用插入气泡直接取跳转后的指令
    //但是好麻烦呀...懒得弄了
    assign flush_D = pc_src_BEQ_D||pc_src_J_D;
    // input clk,
	// input clear,
	// input hold,
	// input wire [N-1:0] in,
	// output reg [N-1:0] out
    regr #(.N(32)) PC_bibibi(
        .clk(clk),
        .clear(1'b0),
        .hold(stall_F),
        .in(pc_in_F),
        .out(pc_out_F)
    );

    //获取默认的下一条指令的地址
    assign pc_plus4_F = pc_out_F+32'h4;

    wire [31:0] instr_F;          //F阶段32位指令
    wire [31:0] instr_D;          //D阶段32位指令
    //指令存储器
	// input wire 	[31:0] 	addr,
	// output wire [31:0] 	data
    im IM_bibibi(
        .addr(pc_out_F),
        .data(instr_F)
    );

    //取指令-指令译码 级间寄存器
    //32-指令 32-PCPlus4
    regr #(.N(64)) FD_bibibi(
        .clk(clk),
        .clear(flush_D),
        .hold(stall_D),
        .in({instr_F,pc_plus4_F}),
        .out({instr_D,pc_plus4_D})
    );

    //=========================指令译码阶段-----D=========================

    // |  RegWrite  |               当前指令需要写入寄存器               |
    // |  MemtoReg  |     当前指令需要从存储器中获取数据并存入寄存器     |
    // |  MemWrite  |               当前指令需要写入存储器               |
    // |   ALUCtrl  |                 指定 ALU 运算类型                  |
    // |   ALUSrc   |        ALU 中 B 数据来源选择(寄存器/立即数)        |
    // |   RegDst   |   寄存器写入目的指定,指定需要写入的寄存器(Rt/Rd)   |
    // | BranchBEQ  | 当前指令为 BEQ 指令,需要在指令译码阶段判断是否跳转 |
    // |  BranchJ   |    当前指令为 J 指令,在指令译码阶段完成 J 跳转     |
    wire regwrite_D;
    wire memtoreg_D;
    wire memwrite_D;
    wire [2:0] aluctrl_D;
    wire alusrc_D;
    wire regdst_D;
    wire branch_beq_D;
    wire equal_D;
    // wire [31:0] pc_BEQ_addr_D;     //BEQ指令对应的地址
    // wire [31:0] pc_J_addr_D;       //J指令对应的地址
    // wire pc_src_BEQ_D;             //BEQ指令产生的控制信号,跳转时为1,不跳转时为0
    // wire pc_src_J_D;               //J指令产生的控制信号,跳转时为1,不跳转时为0
    
    //使用额外的加法器计算BEQ指令跳转的目的地址和逻辑使能信号F
    //其中扩展时需要注意负数的情况,因为BEQ指令跳转的是相对地址
    // assign pc_BEQ_addr_D = pc_plus4_D + {14'b0,instr_D[15:0],2'b00};
    //本来想直接在这一步将偏移地址乘4，但是发现通过扩展直接将补码负数乘4很难...放弃了放弃了...
    //所以偏移地址的单位是字节,而不是字
    always @(*) begin
        if(instr_D[15]==1'b1)
            pc_BEQ_addr_D = pc_plus4_D + {16'hFF,instr_D[15:0]};
        else
            pc_BEQ_addr_D = pc_plus4_D + {16'h00,instr_D[15:0]};
    end
    assign pc_src_BEQ_D = branch_beq_D && equal_D;
    assign equal_D = (rs_data_D==rt_data_D);

    //计算J指令的跳转目的地址
    //其中扩展的时候不需要注意负数的情况,因为J指令跳转的是绝对地址,使用的时无符号数
    assign pc_J_addr_D = {6'b0,instr_D[25:0]};

    //主控制器
    // input wire [5:0] OPCode,
    // input wire [5:0] Func,
    // output reg RegWrite,
    // output reg MemtoReg,
    // output reg MemWrite,
    // output reg [2:0] ALUCtrl,
    // output reg ALUSrc,
    // output reg RegDst,
    // output reg BranchBEQ,
    // output reg BranchJ
    mcu MCU_bibibi(
        .OPCode(instr_D[31:26]),
        .Func(instr_D[5:0]),
        .RegWrite(regwrite_D),
        .MemtoReg(memtoreg_D),
        .MemWrite(memwrite_D),
        .ALUCtrl(aluctrl_D),
        .ALUSrc(alusrc_D),
        .RegDst(regdst_D),
        .BranchBEQ(branch_beq_D),
        .BranchJ(pc_src_J_D)
    );


    wire [31:0] rs_temp_D;             //寄存器组直接输出的rs数据
    wire [31:0] rt_temp_D;             //寄存器组直接输出的rt数据
    wire [31:0] rs_data_D;             //最终得到的rs寄存器值
    wire [31:0] rt_data_D;             //最终得到的rt寄存器值
    wire regwrite_W;                 //回送阶段的使能信号
    wire [4:0]  reg_in_addr_W;         //回送阶段的地址
    wire [31:0] reg_in_data_W;         //回送阶段的数据

    //解决RAW数据冒险
    wire [31:0] alu_out_M;             //存储器访问阶段的alu输出结果
    wire forwardA_D;                   //A寄存器回送使能
    wire forwardB_D;                   //B寄存器回送使能
    assign rs_data_D = (forwardA_D==1'b1)?alu_out_M:rs_temp_D;
    assign rt_data_D = (forwardB_D==1'b1)?alu_out_M:rt_temp_D;

    //寄存器组
	// input wire			clk,
	// input wire  [4:0]	R_Reg1, R_Reg2,
	// output wire [31:0]	R_data1, R_data2,
	// input wire			RegWr,
	// input wire	[4:0]	W_Reg,
	// input wire	[31:0]	W_data
    regm RF_bibibi(
        .clk(clk),
        .R_Reg1(instr_D[25:21]),
        .R_Reg2(instr_D[20:16]),
        .R_data1(rs_temp_D),
        .R_data2(rt_temp_D),
        .RegWr(regwrite_W),
        .W_Reg(reg_in_addr_W),
        .W_data(reg_in_data_W)
    );

    //将指令中的立即数扩展为32位数,扩展时需要考虑符号
    wire [31:0] imm32_D;
    assign imm32_D = (instr_D[15]==1'b0)?{16'b0,instr_D[15:0]}:{16'hFFFF,instr_D[15:0]};


    wire flush_E;               //E阶段插入气泡信号
    wire regwrite_E;            //传递到下一阶段的信号
    wire memtoreg_E;
    wire memwrite_E;
    wire [2:0] aluctrl_E;
    wire alusrc_E;
    wire regdst_E;
    wire [31:0] rs_data_E;
    wire [31:0] rt_data_E;
    wire [4:0] rs_addr_E;
    wire [4:0] rt_addr_E;
    wire [4:0] rd_addr_E;
    wire [31:0] imm32_E;

    //指令译码-指令执行 级间寄存器
    //1,1,1,3,1,1,32,32,5,5,5,32
    //总位数:119
    regr #(.N(119)) DE_bibibi(
        .clk(clk),
        .clear(flush_E),
        .hold(1'b0),
        .in({regwrite_D,memtoreg_D,memwrite_D,aluctrl_D,alusrc_D,regdst_D,
            rs_data_D,rt_data_D,instr_D[25:21],instr_D[20:16],instr_D[15:11],
            imm32_D}),
        .out({regwrite_E,memtoreg_E,memwrite_E,aluctrl_E,alusrc_E,regdst_E,
            rs_data_E,rt_data_E,rs_addr_E,rt_addr_E,rd_addr_E,imm32_E})
    );


    //=========================指令执行阶段-----E=========================

    //A寄存器多路选择
    reg [31:0] A_data_E;            //ALU A引脚数据
    wire [1:0] forwardA_E;          //ALU 选择信号
    always @(*) begin
        case (forwardA_E)
            2'b00: A_data_E <= rs_data_E;
            2'b01: A_data_E <= reg_in_data_W;
            2'b10: A_data_E <= alu_out_M;
            default: A_data_E <= rs_data_E;
        endcase
    end

    //B寄存器多路选择
    reg [31:0] B_data_E;            //ALU B引脚数据
    wire [1:0] forwardB_E;          //ALU 选择信号
    always @(*) begin
        case (forwardB_E)
            2'b00: B_data_E <= rt_data_E;
            2'b01: B_data_E <= reg_in_data_W;
            2'b10: B_data_E <= alu_out_M;
            default: B_data_E <= rt_data_E;
        endcase
    end

    //B引脚输入选择(B寄存器/立即数)
    wire [31:0] B_temp_E;
    assign B_temp_E = (alusrc_E==1'b1)?imm32_E:B_data_E;

    //寄存器写入地址与数据
    wire [4:0] writereg_E;
    wire [31:0] writedata_E;
    assign writereg_E = (regdst_E==1'b1)?rd_addr_E:rt_addr_E;
    assign writedata_E = B_data_E;

    //算术逻辑运算ALU
    wire [31:0] alu_out_E;
    wire zero_E;
    wire of_E;
    // input		[2:0]	M,
	// input		[31:0]	A, B,
	// output reg	[31:0]	OUT,
	// output				ZERO,
	// output  			    OF
    alu ALU_bibibi(
        .M(aluctrl_E),
        .A(A_data_E),
        .B(B_temp_E),
        .OUT(alu_out_E),
        .ZERO(zero_E),
        .OF(of_E)
    );

    wire regwrite_M;
    wire memtoreg_M;
    wire memwrite_M;
    // wire [31:0] alu_out_M;
    wire [31:0] writedata_M;
    wire [4:0] writereg_M;

    //指令执行-访问存储器 级间寄存器
    //1,1,1,32,32,5
    //总位数:72
    regr #(.N(72)) EM_bibibi(
        .clk(clk),
        .clear(1'b0),
        .hold(1'b0),
        .in({regwrite_E,memtoreg_E,memwrite_E,alu_out_E,
            writedata_E,writereg_E}),
        .out({regwrite_M,memtoreg_M,memwrite_M,alu_out_M,
            writedata_M,writereg_M})
    );


    //=========================访问存储器阶段---M=========================

    wire [31:0] mem_out_M;              //存储器输出的数据

    //数据存储器
    // input wire			clk,
	// input wire	[6:0]	Addr,
	// input wire			Read, Write,
	// input wire 	[31:0]	W_data,
	// output wire	[31:0]	R_data
    dm DM_bibibi(
        .clk(clk),
        .Addr(alu_out_M[6:0]),
        .W_data(writedata_M),
        .R_data(mem_out_M),
        .Read(1'b1),
        .Write(memwrite_M)
    );


    //wire regwrite_W;
    wire memtoreg_W;
    wire [31:0] mem_out_W;
    wire [31:0] alu_out_W;

    //访问存储器-寄存器回送 级间寄存器
    //1,1,32,32,5
    //总位数:71
    regr #(.N(71)) MW_bibibi(
        .clk(clk),
        .clear(1'b0),
        .hold(1'b0),
        .in({regwrite_M,memtoreg_M,mem_out_M,
            alu_out_M,writereg_M}),
        .out({regwrite_W,memtoreg_W,mem_out_W,
            alu_out_W,reg_in_addr_W})
    );

    //=========================寄存器回写阶段---W=========================

    assign reg_in_data_W = (memtoreg_W==1'b1)?mem_out_W:alu_out_W;

    //=========================  冒险处理机构  =========================

    // input      [4:0] WriteRegE,     //E阶段可能要写的寄存器地址
    // input      [4:0] WriteRegW,     //W阶段可能要写的寄存器地址
    // input      [4:0] WriteRegM,     //M阶段可能要写的寄存器地址
    // input      RegWriteE,           //E阶段写寄存器的使能信号
    // input      RegWriteW,           //W阶段写寄存器的使能信号
    // input      RegWriteM,           //M阶段写寄存器的使能信号
    // input      [4:0] RsE,           //E阶段要用的Rs寄存器的地址
    // input      [4:0] RtE,           //E阶段要用的Rt寄存器的地址
    // output reg [1:0] ForwardAE,     //E阶段A寄存器(Rs)数据旁路使能信号
    // output reg [1:0] ForwardBE,     //E阶段B寄存器(Rt)数据旁路使能信号
    // input      [4:0] RsD,           //D阶段要用的Rs寄存器的地址
    // input      [4:0] RtD,           //D阶段要用的Rt寄存器的地址
    // input      MemtoRegE,           //E阶段存储器向寄存器写入的使能信号
    // input      MemtoRegM,           //M阶段存储器向寄存器写入的使能信号
    // output     StallF,              //F阶段阻塞信号
    // output     StallD,              //D阶段阻塞信号
    // output     FlushE,              //E阶段清空信号(插入气泡)
    // output reg ForwardAD,           //D阶段A寄存器(Rs)数据旁路使能信号
    // output reg ForwardBD,           //D阶段B寄存器(Rt)数据旁路使能信号
    // input      BranchD              //D阶段发出的BEQ分支控制信号
    harzard_unit HARZARD_UNIT_bibibi(
        .WriteRegE(writereg_E),
        .WriteRegW(reg_in_addr_W),
        .WriteRegM(writereg_M),
        .RegWriteE(regwrite_E),
        .RegWriteW(regwrite_W),
        .RegWriteM(regwrite_M),
        .RsE(rs_addr_E),
        .RtE(rt_addr_E),
        .ForwardAE(forwardA_E),
        .ForwardBE(forwardB_E),
        .RsD(instr_D[25:21]),
        .RtD(instr_D[20:16]),
        .MemtoRegE(memtoreg_E),
        .MemtoRegM(memtoreg_M),
        .StallF(stall_F),
        .StallD(stall_D),
        .FlushE(flush_E),
        .ForwardAD(forwardA_D),
        .ForwardBD(forwardB_D),
        .BranchD(branch_beq_D)
    );

endmodule
