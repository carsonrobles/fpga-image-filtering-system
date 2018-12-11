module uart_rx_tb;

  logic clk = 1;
  logic rst = 0;

  logic rxd = 1;

  wire  rts;
  wire  idle_dbg;

  always_latch clk <= #5 ~clk;

  axis_if #( .DATA_TYPE (logic [7:0]) ) axis_rx ();

  always_comb axis_rx.rdy = 1;

  uart_rx #(
    .CLKS_PER_BIT (2)
  ) uart_rx_i (
    .clk     (clk),
    .rst     (rst),
    .rxd     (rxd),
    .rts     (rts),
    .axis_rx (axis_rx),
    .idle_dbg
  );

  initial begin
    repeat (10) begin
    rxd <= 1;
    repeat (20) @ (posedge clk);
    rxd <= 0;
    repeat ( 3) @ (posedge clk);
    rxd <= 1;
    repeat (20) @ (posedge clk);
    end
  end

endmodule
