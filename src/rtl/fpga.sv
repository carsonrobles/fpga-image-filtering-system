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

  localparam int CLK_FREQ  = 50_000_000;
  localparam int UART_BAUD = 115_200;

  // reset synchronizer
  logic [2:0] rsync = '0;

  always_ff @ (posedge clk) begin
    if (~rst_n)
      rsync <= '0;
    else
      rsync <= (rsync << 1) | rst_n;
  end

  wire rst = ~rsync[2];

  // UART RX data line synchronizer
  logic [2:0] rxd_sft = '1;
  wire        rxd_s   = rxd_sft[2];

  always_ff @ (posedge clk) begin
    if (rst)
      rxd_sft <= '1;
    else
      rxd_sft <= (rxd_sft << 1) | rxd;
  end

  // UART RX and TX AXI streams
  axis_if #( .DATA_TYPE (logic [7:0]) ) axis_rx ();
  axis_if #( .DATA_TYPE (logic [7:0]) ) axis_tx ();

  // instantiate UART core
  uart #(
    .CLKS_PER_BIT (CLK_FREQ / UART_BAUD)
  ) uart_i (
    .clk     (clk),
    .rst     (rst),
    .rxd     (rxd_s),
    .rts     (rts),
    .txd     (txd),
    .cts     (cts),
    .axis_rx (axis_rx),
    .axis_tx (axis_tx)
  );

  // instantiate image filtering data path
  data_path data_path_i (
    .clk        (clk),
    .rst        (rst),
    .filter_sel (sw[3:0]),
    .axis_i     (axis_rx),
    .axis_o     (axis_tx)
  );

endmodule
