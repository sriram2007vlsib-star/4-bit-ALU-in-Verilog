module mat_vec#(
  parameter N=3,
  parameter M=3)(
  
  input start,clk,reset,
  input logic[7:0] matrix[N-1:0][M-1:0],
  input logic[7:0] vector[M-1:0],
  output logic[31:0] out_vec[N-1:0],
  output logic done);
  

  logic[$clog2(N)-1:0] row;
  logic[$clog2(N)-1:0] index;
  logic[31:0] acc;
  logic[15:0] product;
  
  assign product = matrix[row][index] * vector[index];
  
  integer i;
  
  always_ff@(posedge clk) begin
    if(reset)
      begin
        for(i=0;i<N;i=i+1)
          out_vec[i]<=0;
        
        acc<=0;
        
        row<=0;
        index<=0;
        done<=0;
      end
    else
      begin
        if(start && !done)
          begin
            acc<=acc+product;
            if(index==M-1)
              begin
                out_vec[row]<=acc+product;
                if(row==N-1)
                  done<=1;
                else
                  begin
                    row<=row+1;
                    index<=0;
                    
                    acc<=0;
                  end
              end
            else
              index<=index+1;
          end
      end
  end
endmodule
  
                    
                  
             
  

              
            
                
                
              
            
            
            
            
    
  
  
  
  
 
