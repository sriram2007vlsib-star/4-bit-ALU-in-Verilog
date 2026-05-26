module spi_master(
  input clk,reset,start,miso,
  input[7:0] data_in,
  output reg[7:0] data_out,
  output reg sclk,cs,mosi,done);
  
  parameter IDLE=2'b00,TRANSFER=2'b01,DONE=2'b10;
  
  reg[1:0] state,next_state;
  reg[2:0] bit_count;
  reg[7:0] shift_reg;
  
  always@(posedge clk) begin
    
    if(reset)
      begin
        state<=IDLE;
        bit_count<=0;
        shift_reg<=0;
      end
    else
      begin
        state<=next_state;
        if(state==TRANSFER)
          sclk<= ~sclk;
        else
          sclk<=0;
        if(sclk==1 && state==TRANSFER)
          begin
            shift_reg<={shift_reg[6:0],miso};
            if(bit_count==7)
              bit_count<=0;
            else
              bit_count<=bit_count+1;
          end
      end
  end
  
          
         
  always@(*) begin
    case(state)
      IDLE:begin
        if(start)
          next_state= TRANSFER;
        else
          next_state= IDLE;
      end
      TRANSFER:begin
        if(sclk==1 && bit_count==7)
          next_state = DONE;
        else
          next_state = TRANSFER;
      end
      DONE:begin
        next_state = IDLE;
      end
      default:next_state =IDLE;
    endcase
  end
  always@(*) begin
    case(state)
      IDLE:begin
        cs=1;
        mosi=0;
        data_out=0;
        done=0;
      end
      TRANSFER:begin
        cs=0;
        mosi=data_in[7-bit_count];
        data_out=0;
        done=0;
      end
      DONE:begin
        cs=1;
        mosi=0;
        data_out=shift_reg;
        done=1;
      end
      default:
        begin
          cs=1;
          mosi=0;
          data_out=0;
          done=0;
        end
    endcase
  end
endmodule

module spi_slave(
  input clk,cs,sclk,mosi,reset,
  input[7:0] data_in,
  output reg miso,
  output reg done,
  output reg[7:0] data_out);
  
  reg[2:0] bit_count;
  reg[7:0] shift_reg;
  
  always@(posedge sclk or posedge reset) begin
    if(reset)
      begin
        shift_reg<=0;
        miso<=0;
        done<=0;
        data_out<=0;
        bit_count<=0;
      end
    else if(!cs) begin
      shift_reg<={shift_reg[6:0],mosi};
      miso<=data_in[7-bit_count];
      
      bit_count<=bit_count+1;
      if(bit_count==7)
        begin
          data_out<={shift_reg[6:0],mosi};
          done<=1;
        end
      else
        done<=0;
    end
  end
endmodule
         
    
   
    
         
          
          
        
      
    
    
