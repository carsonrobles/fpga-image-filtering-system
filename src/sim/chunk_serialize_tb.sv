`include "axi.svh"
`include "pixel_pkg.svh"

module chunk_serialize_tb;

  logic clk = 1;
  logic rst = 0;

  axis_if #( .DATA_TYPE (pixel_pkg::chunk_t) ) axis_i ();
  axis_if #( .DATA_TYPE (logic [7:0]       ) ) axis_o ();

  chunk_serialize dut (
    .clk    (clk),
    .rst    (rst),
    .axis_i (axis_i),
    .axis_o (axis_o)
  );

  always_latch clk <= #5 ~clk;

  always_comb axis_o.rdy = 1;

endmodule
