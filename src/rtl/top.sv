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

  // divided design clock
  wire des_clk;

  clk_wiz_0 clk_div (
    .clk_o  (des_clk),
    .reset  (~rst_n),
    .locked ( ),
    .clk_i  (clk)
  );

  fpga fpga_i (
    .clk   (des_clk),
    .rst_n (rst_n),
    .sw    (sw),
    .led   (led),
    .an    (an),
    .seg   (seg),
    .rxd   (rxd),
    .rts   (rts),
    .txd   (txd),
    .cts   (cts)
  );

endmodule
