module tb;
  logic clk,reset,start;
  logic[7:0] a;
  logic[7:0] b;
  logic[32:0] result;
  
  
  mac DUT(.clk(clk),
          .reset(reset),
          .start(start),
          .a(a),.b(b),
          .result(result));
  
  initial begin
    $dumpfile("mac.vcd");
    $dumpvars(0, tb);
  end
  
  always #5 clk = ~clk;
  
  initial begin
    clk=0;
    start=0;
    reset=1;#10;
    reset=0;
    
    a=8'b00001111;
    b=8'b00001111;
    start=1;#50;
    start=0;
    #100; $finish;
  end
endmodule
    
  
  
