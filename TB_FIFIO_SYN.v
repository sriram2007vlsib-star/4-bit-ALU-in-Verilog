module tb;
  reg clk,reset;
  reg[7:0] data_in;
  reg write_en,read_en;
  wire full,empty;
  wire[7:0] data_out;
  
  fifo DUT(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .write_en(write_en),
    .read_en(read_en),
    .full(full),
    .empty(empty),
    .data_out(data_out));
  
  always #5 clk = ~clk;
  
    initial begin
    $dumpfile("fifo.vcd");
    $dumpvars(0, tb);
    $monitor("time=%0t wr=%b rd=%b data_in=%b data_out=%b full=%b empty=%b count=%0d",
              $time, write_en, read_en, data_in, data_out, full, empty, DUT.count);
    end
  
  initial begin
    clk=0;
    reset=1;#10;
    reset=0;
    write_en=0;#10;
    read_en=0;#10;
    data_in=0;#10;
    
    
    
    data_in=8'b10000111; write_en=1;#10;
    
    
    data_in=8'b10101010;#10;
   
    
    data_in=8'b11110000;#10;
    
    
    data_in=8'b11001100;#10;
    
    write_en=0;
    
    read_en=1; #10;
               #10;
               #10;
               #10;
    read_en=0; #10;
    
    
    
    
    
    
    #50; $finish;
  end
endmodule
    
    
    
