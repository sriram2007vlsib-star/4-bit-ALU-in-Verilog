module tb;
  
  parameter N=3;
  parameter M=3;
  
  
  logic start,clk,reset,done;
  logic[7:0] matrix[N-1:0][M-1:0];
  logic[7:0] vector[M-1:0];
  logic[31:0] out_vec[N-1:0];
  
  
  mat_vec DUT(
    .start(start),
    .clk(clk),
    .reset(reset),
    .done(done),
    .matrix(matrix),
    .vector(vector),
    .out_vec(out_vec));
  
  always #5 clk = ~clk;
  
  initial begin
    $dumpfile("mat_vec.vcd");
    $dumpvars(0, tb);
  end
  
  integer i,j;
  
  initial begin
    for(i=0;i<N;i=i+1) begin
      for(j=0;j<M;j=j+1)
        matrix[i][j]=i*M + j + 1;
    end
  end
  
  
  integer k;
  
  
  initial begin
    for(k=0;k<M;k=k+1) begin
      vector[k]=k+1;
    end
  end
  
  initial begin
    clk=0;
    reset=1;#10;
    reset=0;
    
    start=1;
    #200;
    
    start=0;
    
    for(i=0;i<N;i=i+1) begin
      $display("out_vec[%0d]=%0d",i,out_vec[i]);
    end
    #100; $finish;
  end
endmodule
  
    
 
  
 
