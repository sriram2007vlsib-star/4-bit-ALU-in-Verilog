module pe(
    input  logic clk,
    input  logic reset,
    input  logic valid,
    input logic tile_rst,

    input  logic [7:0] ain,
    input  logic [7:0] bin,

    output logic [7:0] aout,
    output logic [7:0] bout,
    output logic [31:0] cout
);
  
  
  always_ff @(posedge clk) begin
    if (reset || tile_rst) begin
    aout <= 0;
    bout <= 0;
    cout <= 0;
  end
    
    
    else if (valid) begin
      
      
      aout <= ain;
      bout <= bin;
      
      

      if (reset)
        
        
        cout <= 0;
      
      else
        
        
        cout <=  cout + (ain * bin);
    end
  end
endmodule


module till(
  input  logic clk,
  input  logic reset,
  input  logic start,
  input  logic engine_done,

  output logic done,
  output logic load_en,
  output logic compute_en,
  output logic store_en,
  output logic acc_clear,
  output logic tile_row,
  output logic tile_col,
  output logic tile_k,
  output logic tile_rst
);

  typedef enum logic [2:0] {
    IDLE,
    LOAD,
    COMPUTE,
    WAIT,
    ACCUMULATE,
    STORE,
    DONE
  } state_t;

  state_t state, next_state;

  // -------------------------
 
  // -------------------------
  logic sys_done_r;

  always_ff @(posedge clk) begin
    if (reset)
      sys_done_r <= 1'b0;
    else if (state == COMPUTE)     
      sys_done_r <= 1'b0;
    else if (engine_done)
      sys_done_r <= 1'b1;
  end

  // -------------------------
  // State register
  // -------------------------
  always_ff @(posedge clk) begin
    if (reset)
      state <= IDLE;
    else
      state <= next_state;
  end

  // -------------------------
  // Next-state logic
  // -------------------------
  
  localparam TILE_DIM  = 1;  // max index for row/col (2 tiles → 0 and 1)
  localparam TILE_K_MAX = 1; // max index for k (2 k-tiles → 0 and 1)

  always_comb begin
    next_state = state;
    case (state)

      IDLE: begin
        if (start)
          next_state = LOAD;
      end

      LOAD: begin
        next_state = COMPUTE;
      end

      COMPUTE: begin
        next_state = WAIT;
      end

      WAIT: begin
        if (sys_done_r)
          next_state = ACCUMULATE;
      end

      ACCUMULATE: begin
        
        if (tile_k == TILE_K_MAX)
          next_state = STORE;
        else
          next_state = LOAD;   // loop back for next k
      end

      STORE: begin
        // Advance to next output tile, or finish
        if (tile_row == TILE_DIM && tile_col == TILE_DIM)
          next_state = DONE;
        else
          next_state = LOAD;
      end

      DONE: begin
        next_state = DONE;
      end

    endcase
  end

  // -------------------------
  // Outputs
  // -------------------------
  assign done       = (state == DONE);
  assign load_en    = (state == LOAD);
  assign compute_en = (state == COMPUTE);
  assign store_en   = (state == STORE);

  
  assign acc_clear  = (state == LOAD) && (tile_k == 0);

  // Reset systolic array between tiles
  assign tile_rst   = (state == LOAD);

  // -------------------------
  // Tile counters
  // -------------------------
  always_ff @(posedge clk) begin
    if (reset) begin
      tile_row <= 0;
      tile_col <= 0;
      tile_k   <= 0;
    end
    else begin

      // After each k-compute, increment tile_k (in ACCUMULATE)
      if (state == ACCUMULATE) begin
        if (tile_k == TILE_K_MAX)
          tile_k <= 0;          // reset k for next output tile
        else
          tile_k <= tile_k + 1;
      end

      // After storing an output tile, advance row/col
      if (state == STORE) begin
        if (tile_col == TILE_DIM) begin
          tile_col <= 0;
          if (tile_row == TILE_DIM)
            tile_row <= 0;
          else
            tile_row <= tile_row + 1;
        end
        else begin
          tile_col <= tile_col + 1;
        end
      end

    end
  end

endmodule

module acc#(parameter N=4) (
  input clk,reset,
  input logic[31:0] acc[0:N-1][0:N-1],
  input logic acc_clear,
  input logic valid_en,
  output logic[31:0] result[0:N-1][0:N-1]);
  
  integer i, j;
  
  always_ff@(posedge clk) begin
    if(reset || acc_clear) begin
      for(i=0; i<N; i=i+1)
        for(j=0; j<N; j=j+1)
          result[i][j] <= 0;
    end
    else if(valid_en) begin
      for(i=0; i<N; i=i+1)
        for(j=0; j<N; j=j+1)
          result[i][j] <= result[i][j] + acc[i][j];
    end
  end
endmodule

module tile_ext#(parameter N=4,parameter M=8)(
  input logic[7:0] a_mat[0:M-1][0:M-1],
  input logic[7:0] b_mat[0:M-1][0:M-1],
  input logic tile_row,
  input logic tile_col,
  input logic tile_k,
  output logic[7:0] a_tile[0:N-1][0:N-1],
  output logic[7:0] b_tile[0:N-1][0:N-1]);
  
  integer i,j;
  
  always_comb begin
    for(i=0;i<N;i=i+1) begin
      for(j=0;j<N;j=j+1) begin
        a_tile[i][j] = a_mat[tile_row*N+i][tile_k*N+j];
        b_tile[i][j] = b_mat[tile_k*N+i][tile_col*N+j];
      end
    end
  end
endmodule


module buffer#(parameter N=4) (
  
  
  input clk,reset,
  input logic[7:0] a_tile[0:N-1][0:N-1],
  input logic[7:0] b_tile[0:N-1][0:N-1],
  input logic load_en,
  input logic store_en,
  output logic [7:0] a_mat[0:N-1][0:N-1],
  output logic [7:0] b_mat[0:N-1][0:N-1]);
  


  logic sel;
  logic first_load_done;
  logic[7:0] a_buf[0:1][0:N-1][0:N-1];
  logic[7:0] b_buf[0:1][0:N-1][0:N-1];
  
  integer i,j,k;
  

  always_ff @(posedge clk) begin
    if (reset) begin
        sel <= 0;
        first_load_done <= 0;
        for (i = 0; i < 2; i++)
            for (j = 0; j < N; j++)
                for (k = 0; k < N; k++) begin
                    a_buf[i][j][k] <= 0;
                    b_buf[i][j][k] <= 0;
                end
    end
    else if (load_en) begin
        if (!first_load_done) begin
            // cold start — write into active buffer
            a_buf[sel] <= a_tile;
            b_buf[sel] <= b_tile;
            first_load_done <= 1;
        end
        else begin
            
            sel <= ~sel;
            a_buf[~sel] <= a_tile;
            b_buf[~sel] <= b_tile;
        end
    end
  end
  
      
  
  
  


  always_comb begin
    
    
    a_mat=a_buf[sel];
    b_mat=b_buf[sel];
  end
endmodule








  
        
        
      
    
    
    


      
  
        
        
            
          
          
        
    


    











module sram#(parameter N=4)(
  input clk,reset,
  input logic[$clog2(2*N*N)-1:0]addr,
  input logic[7:0] data_in,
  input write_en,
  output logic[7:0] data_out,
  output logic full);
  
  logic[7:0] mem[2*N*N-1:0];
  logic full_reg;
  
  always_ff@(posedge clk) begin
    if(reset)
      full_reg<=0;
    else if(write_en) begin
      mem[addr]<=data_in;
      if(addr==2*N*N-1)
        full_reg<=1;
    end
  end
  
      
      
      
      
  assign full = full_reg;
  assign data_out = mem[addr];
endmodule

module mem_loader#(parameter N=4)(
  input clk,reset,
  input logic [7:0] data_out,
  input logic full,
  output logic [7:0] a1_out[0:N-1][0:N-1],
  output logic [7:0] b1_out[0:N-1][0:N-1],
  output logic[$clog2(2*N*N)-1:0] addr,
  output logic load_done);
  
  

  always_ff@(posedge clk) begin
    
    
    if(reset) begin
      
      addr<=0;
      load_done<=0;
    end
    
    else if(full) begin
      if(addr< 2*N*N)
        addr<=addr+1;
      if(addr == 2*N*N-1)
        load_done<=1;
      if(addr<N*N)
        a1_out[addr/N][addr%N]<=data_out;
      else
        b1_out[(addr-N*N)/N][(addr-N*N)%N]<=data_out;
      
    end
  end
endmodule
  
  

    



module skew #(parameter N=4)(
    input  logic clk,
    input  logic reset,
    input  logic full,
    
    input logic tile_rst,

    input  logic [7:0] a_mat[0:N-1][0:N-1],
    input  logic [7:0] b_mat[0:N-1][0:N-1],

    output logic [7:0] a1_out[0:N-1],
    output logic [7:0] b1_out[0:N-1],
    output logic valid_out
);
  
  

  logic [$clog2(2*N):0] c;
  
  

  always_ff @(posedge clk) begin
    
    if(reset || tile_rst)
      
      
      c <= 0;
    else if(full && c < (3*N-2))
      
      
      c <= c + 1;
  end
  


  assign valid_out = full && (c <= (4*N-1));
  

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
    input logic tile_rst,

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
    
    if(reset || tile_rst) begin
      
      
      count <= 0;
      valid_out <= 0;
      done <= 0;
    end
    
    else begin
      
      
      valid_out <= 0;
      done<=0;
      
      

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
          .tile_rst(tile_rst),
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
                
      


module top #(parameter N=4, parameter M=8)(
    input  logic clk,
    input  logic reset,

    input  logic [7:0] data_in,
    input  logic valid_en,

    output logic [31:0] cout[0:M-1][0:M-1],   // CHANGED: N→M
    output logic done
);

    logic load_done;
    logic full;
    logic [7:0] sram_out;
    logic [$clog2(2*M*M)-1:0] wr_addr;
    logic [$clog2(2*M*M)-1:0] rd_addr;
    logic [$clog2(2*M*M)-1:0] sram_addr;

    logic [7:0] a_mat[0:M-1][0:M-1];
    logic [7:0] b_mat[0:M-1][0:M-1];
    logic tile_row, tile_col, tile_k;
    logic [7:0] a_tile[0:N-1][0:N-1];
    logic [7:0] b_tile[0:N-1][0:N-1];

    logic [7:0] skew_a[0:N-1];
    logic [7:0] skew_b[0:N-1];

    logic skew_valid;
    logic sys_valid;
    logic load_en;
    logic compute_en;
    logic store_en;
    logic acc_clear;
    logic till_done;
    logic sys_done;
    logic tile_rst;
    logic [31:0] sys_cout[0:N-1][0:N-1];
    logic [31:0] acc_result[0:N-1][0:N-1];
    logic[7:0] buff_a_out[0:N-1][0:N-1];
    logic[7:0] buff_b_out[0:N-1][0:N-1];

  
    // wr_addr counter
    always_ff @(posedge clk) begin
        if (reset)
            wr_addr <= 0;
        else if (valid_en && !full)
            wr_addr <= wr_addr + 1;
    end
    assign sram_addr = full ? rd_addr : wr_addr;

    assign done = till_done;

    // ----------------------------------------------------------
    // ADDED: write each tile result into correct quadrant of cout
    // ----------------------------------------------------------
    integer ii, jj;
    always_ff @(posedge clk) begin
        if (reset) begin
            for (ii = 0; ii < M; ii++)
                for (jj = 0; jj < M; jj++)
                    cout[ii][jj] <= 0;
        end
        else if (store_en) begin
            for (ii = 0; ii < N; ii++)
                for (jj = 0; jj < N; jj++)
                    cout[tile_row*N + ii][tile_col*N + jj] <= acc_result[ii][jj];
        end
    end

    // ----------------------------------------------------------
    // Submodule instantiations
    // ----------------------------------------------------------
    till till_inst(
        .clk(clk),
        .reset(reset),
        .start(load_done),
        .engine_done(sys_done),
        .done(till_done),
        .load_en(load_en),
        .compute_en(compute_en),
        .store_en(store_en),
        .acc_clear(acc_clear),
        .tile_row(tile_row),
        .tile_col(tile_col),
        .tile_k(tile_k),
        .tile_rst(tile_rst)
    );

    // CHANGED: result now goes to acc_result, not cout
    acc #(.N(N)) acc_inst(
        .clk(clk),
        .reset(reset),
        .acc(sys_cout),
        .acc_clear(acc_clear),
        .valid_en(sys_done),
        .result(acc_result)
    );

    tile_ext #(.N(N),.M(M)) tile_ext_inst(
        .a_mat(a_mat),
        .b_mat(b_mat),
        .tile_row(tile_row),
        .tile_col(tile_col),
        .tile_k(tile_k),
        .a_tile(a_tile),
        .b_tile(b_tile)
    );

    buffer#(.N(N)) buff_inst(
        .clk(clk),
        .reset(reset),
        .a_tile(a_tile),
        .b_tile(b_tile),
        .load_en(load_en),
        .store_en(store_en),
        .a_mat(buff_a_out),
        .b_mat(buff_b_out));
  
  
  
  
    sram #(.N(M)) sram_inst(
        .clk(clk),
        .reset(reset),
        .addr(sram_addr),
        .data_in(data_in),
        .write_en(valid_en),
        .data_out(sram_out),
        .full(full)
    );

    mem_loader #(.N(M)) mem_inst(
        .clk(clk),
        .reset(reset),
        .data_out(sram_out),
        .load_done(load_done),
        .full(full),
        .a1_out(a_mat),
        .b1_out(b_mat),
        .addr(rd_addr)
    );

    skew #(.N(N)) skew_inst(
        .clk(clk),
        .reset(reset),
        .full(load_done),
        .a_mat(buff_a_out),
        .b_mat(buff_b_out),
        .tile_rst(tile_rst),
        .a1_out(skew_a),
        .b1_out(skew_b),
        .valid_out(skew_valid)
    );

    sys #(.N(N)) sys_inst(
        .clk(clk),
        .reset(reset),
        .ain(skew_a),
        .bin(skew_b),
        .tile_rst(tile_rst),
        .valid_in(skew_valid),
        .cout(sys_cout),
        .valid_out(sys_valid),
        .done(sys_done)
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


module uart_top #(parameter N=4, parameter M=8)(
    input  logic clk,
    input  logic reset,
    input  logic rx,

  output logic [31:0] cout[0:M-1][0:M-1],
    output logic done
);

    logic baud_tick;
    logic [7:0] rx_data;
    logic rx_done;
    

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

    

    // Matrix accelerator top
  top #(.N(N),.M(M)) top_inst (
        .clk(clk),
        .reset(reset),
        .data_in(rx_data),
        .valid_en(rx_done),
        
        .cout(cout),
        .done(done)
    );

endmodule
  
    
    
  
  
             
               
        
        
  
  
  














        
      
 




















































































   
  
  
        




    
  
  
