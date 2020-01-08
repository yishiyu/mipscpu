`ifndef _regr
`define _regr

module regr (
    input clk,
    input Wr,
    input wire [N-1:0] in,
    output reg [N-1:0] out);

    parameter N = 1;
    initial begin
        out = 32'h00000000;
    end

    always @(negedge clk) begin
        if (Wr)
            out <= in;
        else
            out <= out;
    end
    
endmodule

`endif