module mac(
  input[7:0] a,
  input[7:0] b,
  input start,clk,reset,
  output logic[32:0] result);
  
  logic[15:0] product;
  
  always_comb begin
    assign product = a*b;
  end
  
  always_ff@(posedge clk) begin
    if(reset)
      result<=0;
    else if(start)
      result<= result+product;
  end
endmodule
      
    
    
  
