`timescale 1ns/1ps

module tb;

parameter N = 4;
parameter M = 8;

logic clk;
logic reset;

logic [7:0] data_in;
logic valid_en;

logic [31:0] cout [0:M-1][0:M-1];
logic done;

// DUT
top #(.N(N),.M(M)) dut (
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .valid_en(valid_en),
    .cout(cout),
    .done(done)
);

// ==========================================================
// CLOCK
// ==========================================================
initial clk = 0;
always #5 clk = ~clk;

// ==========================================================
// WAVEFORM
// ==========================================================
initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, tb);
end

// ==========================================================
// SEND BYTE TASK
// ==========================================================
task send_byte(input [7:0] d);
begin
    @(posedge clk);
    data_in  <= d;
    valid_en <= 1;

    @(posedge clk);
    valid_en <= 0;
end
endtask

integer i, j;

// ==========================================================
// MAIN TEST
// ==========================================================
initial begin

    // init
    reset = 1;
    data_in = 0;
    valid_en = 0;

    repeat(5) @(posedge clk);
    reset = 0;

    // ======================================================
    // LOAD SRAM DATA
    // ======================================================
    for (i = 0; i < 2*M*M; i++)
        send_byte(i + 1);

    // ======================================================
    // WAIT LOAD DONE
    // ======================================================
    wait(dut.load_done);
    @(posedge clk);

    $display("\n===== A MATRIX =====");
   for (i = 0; i < M; i++) begin
      for (j = 0; j < M; j++)
            $write("%0d ", dut.a_mat[i][j]);
        $write("\n");
    end

    $display("\n===== B MATRIX =====");
   for (i = 0; i < M; i++) begin
      for (j = 0; j < M; j++)
            $write("%0d ", dut.b_mat[i][j]);
        $write("\n");
    end

    // ======================================================
    // WAIT SYS DONE
    // ======================================================
    wait(dut.sys_done);
    @(posedge clk);

    $display("\n===== SYS_COUT =====");
   for (i = 0; i < M; i++) begin
     
      for (j = 0; j < M; j++)
            $write("%0d ", dut.sys_cout[i][j]);
        $write("\n");
    end

    // ======================================================
    // 
    // ======================================================
    $display("\nWaiting for FINAL done...");

    forever begin
        @(posedge clk);

        if (done) begin
            $display("DONE detected at t=%0t", $time);
            break;
        end
    end

    // allow final write settle
    repeat (5) @(posedge clk);

    // ======================================================
    // FINAL RESULT PRINT
    // ======================================================
    $display("\n===== FINAL RESULT MATRIX =====");

   for (i = 0; i < M; i++) begin
      for (j = 0; j < M; j++)
            $write("%0d ", cout[i][j]);
        $write("\n");
    end

  $display("\nSIMUMATION COMPLETE");
    $finish;
end

endmodule
