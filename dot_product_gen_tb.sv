module tb;
  logic start,clk,reset,done;
  logic[7:0] a[3:0];
  logic[7:0] b[3:0];
  
  logic[31:0] result;
  
  dot_prod_gen DUT(
    .a(a),.b(b),
    .start(start),
    .clk(clk),.reset(reset),
    .done(done),.result(result));
  always #5 clk = ~clk;
  
  initial begin
    $dumpfile("dot_product.vcd");
    $dumpvars(0, tb);
  end
  
  initial begin
    a[0]=1;
    a[1]=2;
    a[2]=3;
    a[3]=4;

    b[0]=1;
    b[1]=2;
    b[2]=3;
    b[3]=4;
  end
  
  initial begin
    clk=0;
    start=0;
    reset=1;#10;
    reset=0;
    start=1;
    #50;
    start=0;
    #100; $finish;
  end
endmodule
    
