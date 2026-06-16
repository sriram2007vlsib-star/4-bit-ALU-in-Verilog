module tb_uart_top;

  parameter N = 4;

  logic clk;
  logic reset;
  logic rx;

  logic [31:0] cout[0:N-1][0:N-1];
  logic done;

  integer i, j;

  //----------------------------------------------------------
  // DUT
  //----------------------------------------------------------
  uart_top #(.N(N)) DUT (
      .clk(clk),
      .reset(reset),
      .rx(rx),
      .cout(cout),
      .done(done)
  );

  //----------------------------------------------------------
  // Clock generation
  //----------------------------------------------------------
  initial clk = 0;
  always #5 clk = ~clk;

  //----------------------------------------------------------
  // UART receive debug
  //----------------------------------------------------------
  always @(posedge clk) begin
    if (DUT.rx_done)
      $display("RX_DONE : time=%0t  addr=%0d  rx_data=%0d",
               $time, DUT.addr, DUT.rx_data);
  end

  //----------------------------------------------------------
  // UART transmit task
  //----------------------------------------------------------
  task send_byte(input [7:0] byte_data);
    integer k;
    begin
      // Start bit
      rx = 1'b0;
      repeat(16) @(posedge clk);

      // 8 data bits (LSB first)
      for (k = 0; k < 8; k = k + 1) begin
        rx = byte_data[k];
        repeat(16) @(posedge clk);
      end

      // Stop bit
      rx = 1'b1;
      repeat(16) @(posedge clk);
    end
  endtask

  //----------------------------------------------------------
  // Stimulus
  //----------------------------------------------------------
  initial begin

    clk   = 0;
    reset = 1;
    rx    = 1;

    @(posedge clk);
    @(posedge clk);
    reset = 0;

    // Give UART a little idle time after reset
    repeat (20) @(posedge clk);

    //--------------------------------------------------------
    // Matrix A
    //
    //  1   2   3   4
    //  5   6   7   8
    //  9  10  11  12
    // 13  14  15  16
    //--------------------------------------------------------

    send_byte(8'd1);
    send_byte(8'd2);
    send_byte(8'd3);
    send_byte(8'd4);

    send_byte(8'd5);
    send_byte(8'd6);
    send_byte(8'd7);
    send_byte(8'd8);

    send_byte(8'd9);
    send_byte(8'd10);
    send_byte(8'd11);
    send_byte(8'd12);

    send_byte(8'd13);
    send_byte(8'd14);
    send_byte(8'd15);
    send_byte(8'd16);

    //--------------------------------------------------------
    // Matrix B = Identity
    //--------------------------------------------------------

    send_byte(8'd1);
    send_byte(8'd0);
    send_byte(8'd0);
    send_byte(8'd0);

    send_byte(8'd0);
    send_byte(8'd1);
    send_byte(8'd0);
    send_byte(8'd0);

    send_byte(8'd0);
    send_byte(8'd0);
    send_byte(8'd1);
    send_byte(8'd0);

    send_byte(8'd0);
    send_byte(8'd0);
    send_byte(8'd0);
    send_byte(8'd1);

    //--------------------------------------------------------
    // Wait for computation
    //--------------------------------------------------------
    wait(done);
    @(posedge clk);

    //--------------------------------------------------------
    // Display result
    //--------------------------------------------------------
    $display("");
    $display("========================================");
    $display("         FINAL OUTPUT MATRIX");
    $display("========================================");

    for (i = 0; i < N; i = i + 1) begin
      for (j = 0; j < N; j = j + 1)
        $write("%4d ", cout[i][j]);
      $write("\n");
    end

    $display("========================================");

    $finish;
  end

endmodule
