`ifndef _tsg
`define _tsg

module tsg(
    input wire Ctrl,
    input wire [N-1:0] in,
    output wire [N-1:0] out);

    parameter N = 1;
    assign out = (Ctrl==1'b1)? in : 32'hz;

endmodule

`endif