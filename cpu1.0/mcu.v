`ifndef _cu
`define _cu

//CPU 控制器模块
//第一版MCU 使用硬布线逻辑，毕竟支支持少数几个指令，不需要更复杂的控制方式
module mcu(
		input  wire clk,
        input  wire	[5:0] opcode,
        input  wire [31:0] ALU_out,
        input  wire Zero,OF,
        output reg PCOeh,PCOel,
        output reg PCWr,IRWr,
        output reg ImmOeh,ImmOel,
        output reg [1:0] ExtSel,
        output reg [1:0] ALUOp,
        output reg AWr,BWr,
        output reg ALUOe,
        output reg RegOe,RegWr,
        output reg [1:0] RegSel,
        output reg MemRd,MemWr,MemOe,
        output reg MARWr,
        output reg MDRSrc,MDROe,MDRWr
        );

    //用于存放当前指令周期
    //指令最多有9个周期,其中前5个周期是相同的,后面的指令随指令互异
    reg [3:0] state=0;
    reg temp_zero;

    always @(negedge clk) begin
        #1
        temp_zero=Zero;
    end

    parameter lw = 6'b100011;
    parameter sw = 6'b101011;
    parameter R  = 6'b000000;   //算术逻辑运算指令
    parameter BEQ= 6'b000100;
    parameter J  = 6'b000010;   //跳转指令

	always @(posedge clk) begin
		/* default */
		PCOeh = 1'b0;
        PCOel = 1'b0;
        PCWr = 1'b0;
        IRWr = 1'b0;
        ImmOeh = 1'b0;
        ImmOel = 1'b0;
        ExtSel = 2'b00;
        ALUOp = 2'b00;
        AWr = 1'b0;
        BWr = 1'b0;
        ALUOe = 1'b0;
        RegOe = 1'b0;
        RegWr = 1'b0;
        RegSel = 2'b00;
        MemRd = 1'b0;
        MemWr = 1'b0;
        MemOe = 1'b0;
        MARWr = 1'b0;
        MDRSrc = 1'b0;
        MDROe = 1'b0;
        MDRWr = 1'b0;

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

        //根据mips指令的格式设置控制输出
        //参考资料： https://blog.csdn.net/qq_41848006/article/details/82256626
		case(state)
            4'h0:begin          /* 第1个时钟周期 */
                PCOeh = 1'b1;
                PCOel = 1'b1;
                AWr = 1'b1;
                MARWr = 1'b1;
                state = 4'h1;
            end
            4'h1:begin          /* 第2个时钟周期 */
                IRWr = 1'b1;
                MemRd = 1'b1;
                MemOe = 1'b1;
                state = 4'h2;
            end
            4'h2:begin          /* 第3个时钟周期 */
                ImmOeh = 1'b1;
                ImmOel = 1'b1;
                ExtSel = 2'b10;
                BWr = 1'b1;
                state = 4'h3;                
            end
            4'h3:begin          /* 第4个时钟周期 */
                PCWr = 1'b1;
                ALUOe = 1'b1;
                state = 4'h4;                
            end
            4'h4:begin          /* 第5个时钟周期 */
                AWr = 1'b1;
                RegOe = 1'b1;
                state = 4'h5;                
            end

            // parameter lw = 100011;
            // parameter sw = 101011;
            // parameter R  = 000000;算术逻辑运算指令
            // parameter BEQ= 000100;
            // parameter J  = 000010;跳转指令

            4'h5:begin          /* 第6个时钟周期 */
               case(opcode)
                    lw:begin
                        ImmOeh = 1'b1;
                        ImmOel = 1'b1;
                        BWr = 1'b1;
                        state = 4'h6;
                    end
                    sw:begin
                        ImmOeh = 1'b1;
                        ImmOel = 1'b1;
                        BWr = 1'b1;
                        state = 4'h6;
                    end
                    R:begin
                        RegSel = 2'b01;
                        RegOe = 1'b1;
                        BWr = 1'b1;
                        state = 4'h6;
                    end
                    BEQ:begin
                        RegSel = 2'b01;
                        RegOe = 1'b1;
                        BWr = 1'b1;
                        ALUOp = 2'b10;
                        //调用 sub 运算，根据 Zero 判定下一步信号
                        state = 4'h6;
                    end
                    J:begin
                        //将原本高位不变的奇怪规则改为由立即数指定
                        // PCOeh = 1'b1;
                        // ExtSel = 2'b11;
                        // ImmOel = 1'b1;
                        // PCWr = 1'b1;
                        // state = 4'h6;
                        ExtSel = 2'b11;
                        ImmOeh = 1'b1;
                        ImmOel = 1'b1;
                        PCWr = 1'b1;
                        state = 4'h6;
                    end
                    default:begin
                        state = 4'h0;
                    end
               endcase
            end
            4'h6:begin          /* 第7个时钟周期 */
               case(opcode)
                    lw:begin
                        ALUOe = 1'b1;
                        MARWr = 1'b1;
                        state = 4'h7;
                    end
                    sw:begin
                        ALUOe = 1'b1;
                        MARWr = 1'b1;
                        state = 4'h7;
                    end
                    R:begin
                        ALUOp = 2'b01;
                        ALUOe = 1'b1;
                        RegSel = 2'b10;
                        RegWr = 1'b1;
                        state = 4'h0;
                    end
                    BEQ:begin
                        //需要在这一步决定走向
                        //如果走向结束，这一步起到0状态的作用
                        PCOeh = 1'b1;
                        PCOel = 1'b1;
                        AWr = 1'b1;
                        MARWr = (temp_zero==1'b0)?1'b1:1'b0;
                        state = (temp_zero==1'b0)?4'h1:4'h7;
                        //state = 4'h7;
                    end
                    default:begin
                        state = 4'h0;
                    end
               endcase
            end
            4'h7:begin          /* 第8个时钟周期 */
               case(opcode)
                    lw:begin
                        MemRd = 1'b1;
                        MDRSrc = 1'b1;
                        MDRWr = 1'b1;
                        state = 4'h8;
                    end
                    sw:begin
                        RegSel = 2'b01;
                        RegOe = 1'b1;
                        MDRWr = 1'b1;
                        state = 4'h8;
                    end
                    BEQ:begin
                        ExtSel = 2'b01;
                        ImmOeh = 1'b1;
                        ImmOel = 1'b1;
                        BWr = 1'b1;
                        state = 4'h8;
                    end
                    default:begin
                        state = 4'h0;
                    end
               endcase
            end
            4'h8:begin          /* 第9个时钟周期 */
               case(opcode)
                    lw:begin
                        MDROe = 1'b1;
                        RegSel = 2'b01;
                        RegWr = 1'b1;
                        state = 4'h0;
                    end
                    sw:begin
                        MemWr = 1'b1;
                        state = 4'h0;
                    end
                    BEQ:begin
                        ALUOe = 1'b1;
                        PCWr = 1'b1;
                        state = 4'h0;
                    end
                    default:begin
                        state = 4'h0;
                    end
               endcase
            end
            default:begin
                state = 4'h0;
            end
        endcase
	end

endmodule

`endif