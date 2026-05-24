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

module tx_uart(
  input tx_start,clk,reset,baud_tick,
  input[7:0] data,
  output reg tx,tx_done);
  
  parameter idle=2'b00,start=2'b01,DATA=2'b10,stop=2'b11;
  reg[1:0] state,next_state;
  reg[2:0] bit_count;
  
  always@(posedge clk) begin
    if(reset)
      begin
        state<=idle;
        bit_count<=0;
      end
    else
      begin
        state<=next_state;
        if(baud_tick)
          case(state)
            DATA:begin
              if(bit_count==7)
                begin
                  bit_count<=0;
                  
                end
              else
                bit_count<= bit_count + 1;
            end
            default:bit_count<=0;
          endcase
      end
  end
  
              
  always@(*) begin
    case(state)
      idle:begin
        if(tx_start)
          next_state=start;
        else
          next_state=idle;
      end
      start:begin
        if(baud_tick)
          next_state=DATA;
        else
          next_state=start;
      end
      DATA:begin
        if(baud_tick==1 && bit_count == 7)
          next_state=stop;
        else
          next_state=DATA;
      end
      stop:begin
        if(baud_tick)
          next_state=idle;
        else
          next_state=stop;
      end
      default:next_state = idle;
    endcase
  end
  always@(*) begin
    case(state)
      idle:begin
        tx=1;
        tx_done=0;
      end
      start:begin
        tx=0;
        tx_done=0;
      end
      DATA:begin
        tx=data[bit_count];
        tx_done=0;
      end
      stop:begin
        tx=1;
        tx_done=1;
      end
      default:
        begin
          tx=1;
          tx_done=0;
        end
    endcase
  end
endmodule
        
      
          
          

                  
                
              
  
        
    

  

            
          
            
                
                
                
             
                  
            
      
