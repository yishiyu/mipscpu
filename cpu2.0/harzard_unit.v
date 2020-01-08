`ifndef _hazard_unit
`define _hazard_unit

//冲突处理单元
//不负责具体的数据传送,仅接受和发送控制信号
//信号末尾的字母代表该型号在流水线中的阶段
//F:取指令阶段
//D:指令译码阶段
//E:指令执行阶段
//M:访问存储器阶段
//W:寄存器回送阶段

module harzard_unit(
    input      [4:0] WriteRegE,     //E阶段可能要写的寄存器地址
    input      [4:0] WriteRegW,     //W阶段可能要写的寄存器地址
    input      [4:0] WriteRegM,     //M阶段可能要写的寄存器地址
    input      RegWriteE,           //E阶段写寄存器的使能信号
    input      RegWriteW,           //W阶段写寄存器的使能信号
    input      RegWriteM,           //M阶段写寄存器的使能信号
    input      [4:0] RsE,           //E阶段要用的Rs寄存器的地址
    input      [4:0] RtE,           //E阶段要用的Rt寄存器的地址
    output reg [1:0] ForwardAE,     //E阶段A寄存器(Rs)数据旁路使能信号
    output reg [1:0] ForwardBE,     //E阶段B寄存器(Rt)数据旁路使能信号
    input      [4:0] RsD,           //D阶段要用的Rs寄存器的地址
    input      [4:0] RtD,           //D阶段要用的Rt寄存器的地址
    input      MemtoRegE,           //E阶段存储器向寄存器写入的使能信号
    input      MemtoRegM,           //M阶段存储器向寄存器写入的使能信号
    output     StallF,              //F阶段阻塞信号
    output     StallD,              //D阶段阻塞信号
    output     FlushE,              //E阶段清空信号(插入气泡)
    output     ForwardAD,           //D阶段A寄存器(Rs)数据旁路使能信号
    output     ForwardBD,           //D阶段B寄存器(Rt)数据旁路使能信号
    input      BranchD              //D阶段发出的BEQ分支控制信号
);
    //使用旁路数据通路解决RAW数据冲突
    always @(*) begin
        //优先解决M阶段要回送的数据,因为这个数据更新
        //其实回送阶段的数据冲突也可以通过使用使得寄存器组支持同时读写一个寄存器来解决
        //A寄存器数据冲突
        if((RsE!=5'h0)&&(RsE==WriteRegM)&&(RegWriteM==1'b1))
            ForwardAE=2'b10;
        else if((RsE!=5'h0)&&(RsE==WriteRegW)&&(RegWriteW==1'b1))
            ForwardAE=2'b01;
        else
            ForwardAE=2'b00;
        //B寄存器数据冲突
        if((RtE!=5'h0)&&(RtE==WriteRegM)&&(RegWriteM==1'b1))
            ForwardBE=2'b10;
        else if((RtE!=5'h0)&&(RtE==WriteRegW)&&(RegWriteW==1'b1))
            ForwardBE=2'b01;
        else
            ForwardBE=2'b00;
    end

    //使用插入气泡解决RAW数据冲突
    wire LWStall;
    assign LWStall = (((RsD==RtE)||(RtD==RtE))&&MemtoRegE);


    //BEQ在D阶段就可能使用数据(而不是E阶段),这样会造成新的数据冲突
    //使用数据旁路解决新的数据冲突
    assign ForwardAD = ((RsD!=5'b0)&&(RsD==WriteRegM)&&(RegWriteM==1'b1));
    assign ForwardBD = ((RtD!=5'b0)&&(RtD==WriteRegM)&&(RegWriteM==1'b1));
    //使用插入气泡解决新的数据冲突
    wire BranchStall;
    assign BranchStall = (BranchD && RegWriteM && ((RegWriteE == RsD) || (RegWriteE == RtD)))
                       ||(BranchD && MemtoRegM && ((WriteRegM == RsD) || (WriteRegM == RtD)));

    //综合所有阻塞信号
    assign StallD = LWStall||BranchStall;
    assign StallF = LWStall||BranchStall;
    assign FlushE = LWStall||BranchStall;
    
endmodule
`endif