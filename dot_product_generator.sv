module dot_prod_gen(
  input clk,reset,start,
  input logic[7:0] a[3:0],
  input logic[7:0] b[3:0],
  output logic done,
  output logic[31:0] result);
  
  parameter N=4;
  parameter data_width=8;
  
  
  logic[3:0] index; 
  
  always_ff@(posedge clk) begin
    if(reset)
      begin
        done<=0;
        index<=0;
        result<=0;
      end
    else if(start && !done)
      begin
        result<=result + (a[index]*b[index]);
        if(index==N-1)
          done<=1;
        else
          index<=index+1;
      end
  end
endmodule
  
          
  
    
  
