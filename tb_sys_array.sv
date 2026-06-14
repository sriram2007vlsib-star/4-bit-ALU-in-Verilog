module tb_top;
  parameter N=2;
  logic clk,reset;
  logic[7:0] data_in;
  logic valid_en;
  logic[$clog2(2*N*N)-1:0] addr;
  logic[31:0] cout[0:N-1][0:N-1];
  logic done;
  
  top#(.N(N)) DUT(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .valid_en(valid_en),
    .addr(addr),
    .cout(cout),
    .done(done));
  
  always #5 clk = ~clk;
  
  initial begin
    $dumpfile("tb_top.vcd");
    $dumpvars(0,tb_top);
  
  

    clk=0;
    reset=1; #10;
    data_in=0;
    addr=0;
    valid_en=0;
    @(posedge clk);
    @(posedge clk);
    reset=0;
    
    valid_en=1;addr=0;data_in=1;@(posedge clk);
    valid_en=1;addr=1;data_in=2;@(posedge clk);
    valid_en=1;addr=2;data_in=3;@(posedge clk);
    valid_en=1;addr=3;data_in=4;@(posedge clk);
    
    valid_en=1;addr=4;data_in=5;@(posedge clk);
    valid_en=1;addr=5;data_in=6;@(posedge clk);
    valid_en=1;addr=6;data_in=7;@(posedge clk);
    valid_en=1;addr=7;data_in=8;@(posedge clk);
    
    valid_en=0;
    
  
 
    
  
    
    
    
    
    
    
    
    
    
    
    repeat(6) @(posedge clk);
    
    $display("cout[0][0]=%0d",cout[0][0]);@(posedge clk);
    $display("cout[0][1]=%0d",cout[0][1]);@(posedge clk);
    $display("cout[1][0]=%0d",cout[1][0]);@(posedge clk);
    $display("cout[1][1]=%0d",cout[1][1]);@(posedge clk);
    
    $finish;
  end
endmodule
