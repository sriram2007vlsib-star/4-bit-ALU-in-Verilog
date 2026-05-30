module fifo(
  input clk,reset,
  input[7:0] data_in,
  input write_en,read_en,
  output full,empty,
  output reg[7:0] data_out);
  
  parameter fifo_depth=4;
  
  reg[2:0] count;
  reg[7:0] mem[3:0];
  reg[1:0] write_ptr;
  reg[1:0] read_ptr;
  
  assign full = (count==fifo_depth);
  assign empty = (count==0);
  
  always@(posedge clk or posedge reset) begin
    if(reset)
      begin
        count<=0;
        write_ptr<=0;
        read_ptr<=0;
        data_out<=0;
      end
    else
      begin
        if(write_en && !full)
          begin
            mem[write_ptr]<=data_in;
            if(write_ptr == fifo_depth-1)
              write_ptr<=0;
            else
              write_ptr<=write_ptr+1;
          end
        if(read_en && !empty)
          begin
            data_out<=mem[read_ptr];
            if(read_ptr==fifo_depth-1)
              read_ptr<=0;
            else
              read_ptr<=read_ptr+1;
          end
        case({write_en && !full,read_en && !empty})
          2'b10:count<=count+1;
          2'b01:count<=count-1;
          default:count<=count;
        endcase
      end
  end
endmodule


           
        
            
    
