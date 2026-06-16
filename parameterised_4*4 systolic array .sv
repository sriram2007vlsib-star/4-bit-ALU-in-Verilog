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
    











module reg_file #(parameter N=4)(
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
        
        
          
          
          

        if (addr < N*N)
          
          
          mem_a[addr/N][addr%N] <= data_in;
        else
          
          
          

          mem_b[(addr-N*N)/N][(addr-N*N)%N] <= data_in;
      end
    end
  end
  
  
  
         
  
  

  assign a_out = mem_a;
  assign b_out = mem_b;
  assign full  = (count == 2*N*N);

endmodule


module skew #(parameter N=4)(
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
    else if(full && c < (3*N-2))
      
      
      c <= c + 1;
  end
  


  assign valid_out = full && (c <= (3*N-3));
  

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
   


module sys #(parameter N=4)(
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
                
      


module top #(parameter N=4)(
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


module baud(
  input clk,reset,
  output reg baud_tick);
  
  reg[3:0] count;
  
  always@(posedge clk) begin
    if(reset)
      begin
        count<=0;
        baud_tick<=0;
      end
    else
      begin
        if(count==15)
          begin
            count<=0;
            baud_tick<=1;
          end
        else
          begin
            count<= count+1;
            baud_tick<=0;
          end
      end
  end
endmodule 





  

module uart_rx(
    input  logic       clk,
    input  logic       reset,
    input  logic       rx,
    input  logic       baud_tick,

    output logic [7:0] data,
    output logic       rx_done
);

    parameter IDLE  = 2'b00,
              START = 2'b01,
              DATA  = 2'b10,
              STOP  = 2'b11;

    logic [1:0] state, next_state;
    logic [2:0] bit_count;
    logic [7:0] shift_reg;

    //========================================================
    // Sequential logic
    //========================================================
    always_ff @(posedge clk) begin
        if (reset) begin
            state     <= IDLE;
            bit_count <= 3'd0;
            shift_reg <= 8'd0;
            data      <= 8'd0;
            rx_done   <= 1'b0;
        end
        else begin
            state   <= next_state;
            rx_done <= 1'b0;        // default: pulse for one cycle only

            if (baud_tick) begin
                case (state)

                    IDLE: begin
                        bit_count <= 3'd0;
                    end

                    START: begin
                        bit_count <= 3'd0;
                    end

                    DATA: begin
                        shift_reg <= {rx, shift_reg[7:1]};

                        if (bit_count == 3'd7)
                            bit_count <= 3'd0;
                        else
                            bit_count <= bit_count + 1'b1;
                    end

                    STOP: begin
                        data    <= shift_reg;
                        rx_done <= 1'b1;
                    end

                endcase
            end
        end
    end

    //========================================================
    // Next-state logic
    //========================================================
    always_comb begin
        next_state = state;

        case (state)

            IDLE: begin
                if (rx == 1'b0)
                    next_state = START;
            end

            START: begin
                if (baud_tick)
                    next_state = DATA;
            end

            DATA: begin
                if (baud_tick && (bit_count == 3'd7))
                    next_state = STOP;
            end

            STOP: begin
                if (baud_tick)
                    next_state = IDLE;
            end

            default: next_state = IDLE;

        endcase
    end

endmodule


module uart_top #(parameter N=4)(
    input  logic clk,
    input  logic reset,
    input  logic rx,

    output logic [31:0] cout[0:N-1][0:N-1],
    output logic done
);

    logic baud_tick;
    logic [7:0] rx_data;
    logic rx_done;
    logic [$clog2(2*N*N)-1:0] addr;

    // Baud generator
    baud baud_inst (
        .clk(clk),
        .reset(reset),
        .baud_tick(baud_tick)
    );

    // UART Receiver
    uart_rx uart_rx_inst (
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .baud_tick(baud_tick),
        .data(rx_data),
        .rx_done(rx_done)
    );

    // Address generator
    always_ff @(posedge clk) begin
        if (reset)
            addr <= 0;
        else if (rx_done)
            addr <= addr + 1;
    end

    // Matrix accelerator top
    top #(.N(N)) top_inst (
        .clk(clk),
        .reset(reset),
        .data_in(rx_data),
        .valid_en(rx_done),
        .addr(addr),
        .cout(cout),
        .done(done)
    );

endmodule
  
    
    
  
  
             
               
        
        
  
  
  














        
      
 
