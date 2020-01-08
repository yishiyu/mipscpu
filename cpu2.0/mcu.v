`ifndef _mcu
`define _mcu


//同时集成了书中cu和alu_cu的功能
//为纯组合逻辑电路
//输入引脚为高6位操作吗和低6位R型指令类型码
module mcu(
    input wire [5:0] OPCode,
    input wire [5:0] Func,
    output reg RegWrite,
    output reg MemtoReg,
    output reg MemWrite,
    output reg [2:0] ALUCtrl,
    output reg ALUSrc,
    output reg RegDst,
    output reg BranchBEQ,
    output reg BranchJ
);
    // |  输出引脚  |                        作用                        |
    // | :--------: | :------------------------------------------------: |
    // |  RegWrite  |               当前指令需要写入寄存器               |
    // |  MemtoReg  |     当前指令需要从存储器中获取数据并存入寄存器     |
    // |  MemWrite  |               当前指令需要写入存储器               |
    // |   ALUCtrl  |                 指定 ALU 运算类型                  |
    // |   ALUSrc   |        ALU 中 B 数据来源选择(寄存器/立即数)        |
    // |   RegDst   |   寄存器写入目的指定,指定需要写入的寄存器(Rt/Rd)   |
    // | BranchBEQ  | 当前指令为 BEQ 指令,需要在指令译码阶段判断是否跳转 |
    // |  BranchJ   |    当前指令为 J 指令,在指令译码阶段完成 J 跳转     |


    // | ALU 操作码 | 运算 | Func 码 |
    // | :--------: | :--: | :-----: |
    // |    000     | AND  | 100100  |
    // |    001     |  OR  | 100101  |
    // |    010     | ADD  | 100000  |
    // |    011     | SUB  | 100010  |
    // |    100     | SLT  | 101010  |
    // |    110     | NOR  | 100111  |
    // |    111     | XOR  | 100110  |

    parameter LW   = 6'b100011;
    parameter SW   = 6'b101011;
    parameter R    = 6'b000000;
    parameter BEQ  = 6'b000100;
    parameter J    = 6'b000010;
    parameter ADDI =6'b001000;

    //mcu向alucu发出的信号
    reg [1:0] ALUOp;

    //mcu部分
    always @(*) begin
        //defaults
        RegWrite <= 1'b0;
        MemtoReg <= 1'b0;
        MemWrite <= 1'b0;
        ALUOp    <= 2'b00;
        ALUSrc   <= 1'b0;
        RegDst   <= 1'b0;
        BranchBEQ<= 1'b0;
        BranchJ  <= 1'b0;

        // |  输出引脚  |                        作用                        |
        // | :--------: | :------------------------------------------------: |
        // |  RegWrite  |               当前指令需要写入寄存器               |
        // |  MemtoReg  |     当前指令需要从存储器中获取数据并存入寄存器     |
        // |  MemWrite  |               当前指令需要写入存储器               |
        // |   ALUCtrl  |                 指定 ALU 运算类型                  |
        // |   ALUSrc   |        ALU 中 B 数据来源选择(寄存器/立即数)        |
        // |   RegDst   |   寄存器写入目的指定,指定需要写入的寄存器(Rt/Rd)   |
        // | BranchBEQ  | 当前指令为 BEQ 指令,需要在指令译码阶段判断是否跳转 |
        // |  BranchJ   |    当前指令为 J 指令,在指令译码阶段完成 J 跳转     |
        case (OPCode)
            LW  :begin
                RegWrite <= 1'b1;
                MemtoReg <= 1'b1;
                ALUSrc   <= 1'b1;
            end
            SW  :begin
                ALUSrc   <= 1'b1;
                MemWrite <= 1'b1;
            end
            R   :begin
                RegWrite <= 1'b1;
                RegDst   <= 1'b1;
                ALUOp    <= 2'b10;
            end
            BEQ :begin
                BranchBEQ<= 1'b1;
                // 在流水线中使用额外的加法器实现BEQ指令,故无需使用ALU
                // ALUOp    <= 2'b10;
            end
            J   :begin
                BranchJ  <= 1'b1;
            end
            ADDI:begin
                //预留一个加立即数的操作
                RegWrite <= 1'b1;
                ALUSrc   <= 1'b1;
            end
        endcase
    end

    //ALUCU部分
	always @(*) begin
		case(ALUOp)
			2'd0: ALUCtrl = 3'b010;	/* add */
			2'd1: ALUCtrl = 3'b101;	/* not */
			2'd2: ALUCtrl = _funct;
			2'd3: ALUCtrl = 3'b010;	/* add */
			default: ALUCtrl = 0;
		endcase
	end
    reg [2:0] _funct;
    always @(*) begin
		case(Func[3:0])
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



endmodule
`endif