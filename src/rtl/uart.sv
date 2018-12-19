`include "axi.svh"

module uart #(
  parameter int CLKS_PER_BIT = 1
) (
  input  wire  clk,
  input  wire  rst,

  input  wire  rxd,       // rx pins
  output logic rts,

  output wire  txd,       // tx pins
  input  wire  cts,

  axis_if.master  axis_rx,   // received uart data
  axis_if.slave   axis_tx    // uart data to transmit
);

  uart_rx #(
    .TICKS_PER_BIT      (CLKS_PER_BIT),
    .TICKS_PER_BIT_SIZE ($bits(CLKS_PER_BIT))
  ) uart_rx_i (
    .i_clk      (clk),
    .i_enable   (1),
    .i_din      (rxd),
    .o_rxdata   (axis_rx.data),
    .o_recvdata (axis_rx.vld),
    .o_busy     (rts)
  );

  wire tx_busy;

  always_comb axis_tx.rdy = ~tx_busy;

  uart_tx #(
    .TICKS_PER_BIT      (CLKS_PER_BIT),
    .TICKS_PER_BIT_SIZE ($bits(CLKS_PER_BIT))
  ) uart_tx_i (
    .i_clk    (clk),
    .i_start  (axis_tx.ok),
    .i_data   (axis_tx.data),
    .o_done   ( ),
    .o_busy   (tx_busy),
    .o_dout   (txd)
  );

endmodule
