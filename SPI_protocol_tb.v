
module tb;
  
  reg clk,reset,start;
  wire sclk,cs;
  wire miso,mosi;
  
  reg[7:0] data_in;
  reg[7:0] data_slave;
  
  wire[7:0] data_out;
  wire[7:0] slave_out;
  
  wire done,slave_done;
  
  
  spi_master DUT(
  .clk(clk),
  .reset(reset),
  .start(start),
  .miso(miso),
  .data_in(data_in),
  .data_out(data_out),
  .sclk(sclk),
  .cs(cs),
  .mosi(mosi),
  .done(done));
  
  spi_slave inst(
    .cs(cs),
    .reset(reset),
    .sclk(sclk),
    .mosi(mosi),
    .data_in(data_slave),
    .miso(miso),
    .data_out(slave_out),
    .done(slave_done));
  
  
  always #5 clk = ~clk;
  
   initial begin
    $dumpfile("spi.vcd");
    $dumpvars(0, tb);
    $monitor("time=%0t cs=%b mosi=%b miso=%b data_out=%b slave_out=%b",
              $time, cs, mosi, miso, data_out, slave_out);
  end
  
  initial begin
    clk=0;
    reset=1;#10;
    reset=0;
    start=0;
    
    data_in=8'b10010100;
    data_slave=8'b10010100;
    start=1;#10;
    start=0;
    #500; $finish;
  end
endmodule
    
    
  
  
  
