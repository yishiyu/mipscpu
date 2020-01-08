`include "cpu.v"
module testbench;

    reg test_clk;

    cpu bibibi_cpu(
        .clk(test_clk)
    );

    initial begin
        $dumpfile("testbench.vcd");
        $dumpvars(0,testbench);

        test_clk=0;
        forever #5 test_clk=~test_clk;
    end

    initial begin
        #1000 $finish;
    end

endmodule // testbench