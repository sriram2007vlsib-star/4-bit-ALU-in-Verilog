module pe(
    input  logic clk,
    input  logic reset,
    input  logic valid,

    input  logic [7:0] ain,
    input  logic [7:0] bin,

    output logic [7:0] aout,
    output logic [7:0] bout,
    output logic [31:0] cout
);
  
  
  

  always_ff @(posedge clk) begin
    
    if(reset) begin
      
      
      
      aout <= 0;
      bout <= 0;
      cout <= 0;
    end
    
    
    else begin
      
      
      aout <= ain;
      bout <= bin;
      
      

      if(valid)
        
        
        cout <= cout + (ain * bin);
    end
  end
endmodule
    











module reg_file #(parameter N=2)(
    input  logic clk,
    input  logic reset,

    input  logic [7:0] data_in,
    input  logic valid_en,
    input  logic [$clog2(2*N*N)-1:0] addr,

    output logic [7:0] a_out[0:N-1][0:N-1],
    output logic [7:0] b_out[0:N-1][0:N-1],
    output logic full
);
  

  logic [$clog2(2*N*N+1)-1:0] count;

  logic [7:0] mem_a[0:N-1][0:N-1];
  logic [7:0] mem_b[0:N-1][0:N-1];

  integer r,c;
  
  

  always_ff @(posedge clk) begin
    
    
    if(reset) begin
      
      
      
      
      count <= 0;
      
      

      for(r=0;r<N;r=r+1) begin
        
        
        for(c=0;c<N;c=c+1) begin
          
          
          mem_a[r][c] <= 0;
          mem_b[r][c] <= 0;
        end
      end
    end
    
    
      
      
      
            
    else begin
      
      
        
      
      if(valid_en && !full) begin
        
        
          
          
          
        count <= count + 1;
        
        
          
          
          

        case(addr)
          
          
          
            
            
          0 : mem_a[0][0] <= data_in;
          1 : mem_a[0][1] <= data_in;
          2 : mem_a[1][0] <= data_in;
          3 : mem_a[1][1] <= data_in;
          4 : mem_b[0][0] <= data_in;
          5 : mem_b[0][1] <= data_in;
          6 : mem_b[1][0] <= data_in;
          7 : mem_b[1][1] <= data_in;
            default: ;
        endcase
      end
    end
  end
  
  
         
  
  

  assign a_out = mem_a;
  assign b_out = mem_b;
  assign full  = (count == 2*N*N);

endmodule


module skew #(parameter N=2)(
    input  logic clk,
    input  logic reset,
    input  logic full,

    input  logic [7:0] a_mat[0:N-1][0:N-1],
    input  logic [7:0] b_mat[0:N-1][0:N-1],

    output logic [7:0] a1_out[0:N-1],
    output logic [7:0] b1_out[0:N-1],
    output logic valid_out
);
  
  

  logic [$clog2(2*N):0] c;
  
  

  always_ff @(posedge clk) begin
    
    if(reset)
      
      
      c <= 0;
    else if(full && c < 2*N)
      
      
      c <= c + 1;
  end
  


  assign valid_out = full && (c <= (2*N-1));
  

  integer i,j;
  

  always_comb begin
    
    for(i=0;i<N;i=i+1) begin
      
      
      if((c >= i) && ((c-i) < N))
        
        
        
        a1_out[i] = a_mat[i][c-i];
        else
          
          
          a1_out[i] = 0;
    end
    
    

    for(j=0;j<N;j=j+1) begin
      
      
      if((c >= j) && ((c-j) < N))
        
        
        
        b1_out[j] = b_mat[c-j][j];
        else
          
          
          b1_out[j] = 0;
    end
  end
endmodule
   


module sys #(parameter N=2)(
    input  logic clk,
    input  logic reset,

    input  logic [7:0] ain[0:N-1],
    input  logic [7:0] bin[0:N-1],
    input  logic valid_in,

    output logic [31:0] cout[0:N-1][0:N-1],
    output logic valid_out,
    output logic done
);
  
  

  logic [$clog2(3*N+1)-1:0] count;

  logic [7:0] a_link[0:N-1][0:N];
  logic [7:0] b_link[0:N][0:N-1];

  always_ff @(posedge clk) begin
    
    if(reset) begin
      
      
      count <= 0;
      valid_out <= 0;
      done <= 0;
    end
    
    else begin
      
      
      valid_out <= 0;
      
      

      if(valid_in && !done) begin
        
        
        count <= count + 1;
        
        

        if(count == (3*N-3)) begin
          
          
          valid_out <= 1;
          
          done <= 1;
        end
      end
    end
  end
  
  
  
            

  genvar i,j;

  generate
    
    for(i=0;i<N;i=i+1) begin
      
      
      assign a_link[i][0] = ain[i];
    end
    

    for(j=0;j<N;j=j+1) begin
      
      
      
      assign b_link[0][j] = bin[j];
    end
  endgenerate
  
  
    

  generate
    
    for(i=0;i<N;i=i+1) begin: ROW
      
      
      for(j=0;j<N;j=j+1) begin: COL
        
        
        pe pe_inst(
          
          
          
          .clk(clk),
          .reset(reset),
          .valid(valid_in),
          .ain(a_link[i][j]),
          .bin(b_link[i][j]),
          .aout(a_link[i][j+1]),
          .bout(b_link[i+1][j]),
          .cout(cout[i][j])
                
                
                
            );
      end
    end
  endgenerate
endmodule
                
      


module top #(parameter N=2)(
    input  logic clk,
    input  logic reset,

    input  logic [7:0] data_in,
    input  logic valid_en,
    input  logic [$clog2(2*N*N)-1:0] addr,

    output logic [31:0] cout[0:N-1][0:N-1],
    output logic done
);
  
  
  

  logic full;

  logic [7:0] a_mat[0:N-1][0:N-1];
  logic [7:0] b_mat[0:N-1][0:N-1];

  logic [7:0] skew_a[0:N-1];
  logic [7:0] skew_b[0:N-1];

  logic skew_valid;
  logic sys_valid;
  
  
  

  reg_file #(.N(N)) reg_inst(
    
    
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .valid_en(valid_en),
    .addr(addr),
    .a_out(a_mat),
    .b_out(b_mat),
    .full(full)
);
  
  

  skew #(.N(N)) skew_inst(
    
    .clk(clk),
    .reset(reset),
    .full(full),
    .a_mat(a_mat),
    .b_mat(b_mat),
    .a1_out(skew_a),
    .b1_out(skew_b),
    .valid_out(skew_valid)
);
  
  

  sys #(.N(N)) sys_inst(
    
    .clk(clk),
    .reset(reset),
    .ain(skew_a),
    .bin(skew_b),
    .valid_in(skew_valid),
    .cout(cout),
    .valid_out(sys_valid),
    .done(done)
);

endmodule
