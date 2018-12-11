module top (
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

  wire slow_clk;

  clk_wiz_0 clk_div (
    .clk_o (slow_clk),
    .reset (~rst_n),
    .locked ( ),
    .clk_i (clk)
  );

  fpga fpga_i (
    .clk (slow_clk),
    .rst_n,
    .sw,
    .led,
    .an,
    .seg,
    .rxd,
    .rts,
    .txd,
    .cts
  );

endmodule
