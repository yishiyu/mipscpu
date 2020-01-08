echo off
set filename=%1

iverilog -g2012 %filename%.v
vvp a.out
gtkwave %filename%.vcd


del a.out %filename%.vcd