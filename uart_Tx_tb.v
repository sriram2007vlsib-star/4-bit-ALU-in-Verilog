
module tb1;
  reg  tx_start,clk,reset;
  reg [7:0] data;
  wire tx,tx_done;
  wire baud_tick;
  
  baud baud_instant(
    .clk(clk),
    .reset(reset),
    .baud_tick(baud_tick));
  
  
  
  tx_uart DUT(
    .tx_start(tx_start),
    .clk(clk),
    .reset(reset),
    .baud_tick(baud_tick),
    .data(data),
    .tx(tx),
    .tx_done(tx_done));
  
  always #5 clk = ~clk;
  
  
    initial begin
    $dumpfile("uart.vcd");
    $dumpvars(0, tb1);
    $monitor("time=%0t tx=%b tx_done=%b state=%b",
              $time, tx, tx_done, DUT.state);
    end
    
    initial begin
      clk=0;
      reset=1;#10;
      reset=0;
      
      tx_start=0;#10;
      data=8'b11100011;
      
      tx_start=1;#10;
      tx_start=0;
      #2000; $finish;
    end
endmodule
    
      
    
    

      
      
      
      
      

  
  
