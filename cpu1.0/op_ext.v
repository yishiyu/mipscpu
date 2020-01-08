`ifndef _op_ext
`define _op_ext

module op_ext(
    input wire [1:0] signal,
    input wire [31:0] in,
    output reg [3:0] sig_ext_h,
    output reg [27:0] sig_ext_l
);

    always @(*) begin
        case (signal)
            2'b00: begin
                //扩展低16位为32位
                sig_ext_h=4'h0;
                sig_ext_l={12'h0,in[15:0]};
            end
            2'b01: begin
                sig_ext_h=4'h0;
                sig_ext_l={16'h0,in[15:0]};
            end
            2'b10: begin
                sig_ext_h=4'h0;
                sig_ext_l=28'h1;
            end
            2'b11: begin
                //书上的内存为按字节存储,故跳转的时候需要将立即数乘以4
                //bibibi的内存按字存储,跳转时立即数不用变
                //为此也顺便将跳转时 原本高位不变奇怪规则也改为由立即数指定
                //修改部分再mcu中(修改控制信号)
                sig_ext_h=4'h0;
                sig_ext_l=in[27:0];
            end
            default: begin
                sig_ext_h=4'h0;
                sig_ext_l=28'h0;
            end
        endcase
    end

endmodule

`endif