`include "axi.svh"

module fpga (
  input  wire         clk,
  input  wire         rst_n,

  input  wire  [15:0] sw,
  output logic [15:0] led,
  output logic [ 7:0] an,
  output logic [ 7:0] seg,

  input  wire         rxd,    // uart
  output wire         rts,
  output wire         txd,
  input  wire         cts
);

  localparam int CLK_FREQ     = 50_000_000;
  localparam int UART_BAUD    = 115_200;

  logic [2:0] rsync = '0;

  always_ff @ (posedge clk or negedge rst_n) begin
    if (~rst_n)
      rsync <= '0;
    else
      rsync <= (rsync << 1) | rst_n;
  end

  wire rst = ~rsync[2];

  axis_if #( .DATA_TYPE (logic [7:0]) ) axis_rxtx ();
  axis_if #( .DATA_TYPE (logic [7:0]) ) axis_rx ();
  axis_if #( .DATA_TYPE (logic [7:0]) ) axis_tx ();

  logic [2:0] state_dbg;

  logic [2:0] rxd_sft = '1;
  wire        rxd_s   = rxd_sft[2];

  always_ff @ (posedge clk) begin
    if (rst)
      rxd_sft <= '1;
    else
      rxd_sft <= (rxd_sft << 1) | rxd;
  end

  uart #(
    .CLKS_PER_BIT (CLK_FREQ / UART_BAUD)
  ) uart_i (
    .clk     (clk),
    .rst     (rst),
    .rxd     (rxd_s),
    .rts     (rts),
    .txd     (txd),
    .cts     (cts),
    .state_dbg,
    .axis_rx (axis_rx),
    .axis_tx (axis_tx)
  );

  wire full, empty;

  data_path data_path_i (
    .clk        (clk),
    .rst        (rst),
    .filter_sel (sw[3:0]),
    .axis_i     (axis_rx),
    .axis_o     (axis_tx),
    .full,
    .empty
  );

/*

















  logic [1:0] rx_edge = '0;

  always_ff @ (posedge clk) begin
    if (rst)
      rx_edge <= '0;
    else
      rx_edge <= (rx_edge << 1) | axis_rx.ok;
  end

  logic [15:0] rx_cnt = '0;

  always_ff @ (posedge clk) begin
    if (rst)
      rx_cnt <= '0;
    else if (~rx_edge[1] & rx_edge[0])
      rx_cnt <= rx_cnt + 1;
  end

  logic [1:0] tx_edge = '0;

  always_ff @ (posedge clk) begin
    if (rst)
      tx_edge <= '0;
    else
      tx_edge <= (tx_edge << 1) | axis_tx.ok;
  end

  logic [15:0] tx_cnt = '0;

  always_ff @ (posedge clk) begin
    if (rst)
      tx_cnt <= '0;
    else if (~tx_edge[1] & tx_edge[0])
      tx_cnt <= tx_cnt + 1;
  end

  sseg_drv (
    .clk (clk),
    .en  (1),
    .mod (0),
    .dat ({rx_cnt, tx_cnt}),
    .an  (an),
    .seg (seg)
  );

  logic [23:0] cnt = 0;

  always_ff @ (posedge clk)
    if (rst)
      cnt <= '0;
    else
      cnt <= cnt + 1;

  always_ff @ (posedge clk) begin
    led[13] <= rst;
    led[12] <= cts;
    led[11] <= rts;
    led[10] <= full;
    led[ 9] <= empty;
    led[ 8] <= '0;
    led[6]   <= axis_tx.vld;
    led[5]   <= axis_tx.rdy;
    led[4]   <= axis_rx.vld;
    led[3]   <= axis_rx.rdy;
    led[2:0] <= state_dbg;

    if (        &cnt) led[ 15] <= ~led[15];
    if (axis_rxtx.ok) led[ 14] <= ~led[14];
    //if (axis_rxtx.ok) led[7:0] <= axis_rxtx.data;
  end*/

endmodule
