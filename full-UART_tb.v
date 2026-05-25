module tb2;
  
  
  reg tx_start,clk,reset;
  wire baud_tick;
  reg[7:0] data;
  
  wire[7:0] rx_data;
  wire rx_done,tx,tx_done;
  
  baud baud_inst(
    .clk(clk),
    .reset(reset),
    .baud_tick(baud_tick));
  
  tx_uart DUT(
    .tx_start(tx_start),
    .clk(clk),
    .reset(reset),
    .baud_tick(baud_tick),
    .data(data),
    .tx(tx),.tx_done(tx_done));
  
  uart_rx rx_inst(
    .clk(clk),
    .reset(reset),
    .rx(tx),
    .baud_tick(baud_tick),
    .data(rx_data),
    .rx_done(rx_done));
  always #5 clk = ~clk;
  
  initial begin
  $dumpfile("uart.vcd");
  $dumpvars(0, tb2);
  $monitor("time=%0t tx=%b tx_done=%b rx_data=%b rx_done=%b",
            $time, tx, tx_done, rx_data, rx_done);
  end
  
  
  initial begin
    clk=0;
    reset=1;#10;
    reset=0;
    tx_start=0;
    data=0;#10;
    data=8'b10110001;
    tx_start=1;#10;
    tx_start=0;
    #2000; $finish;
  end
endmodule
    
    


 
