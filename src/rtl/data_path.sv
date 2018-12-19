`include "axi.svh"
`include "pixel_pkg.svh"

module data_path (
  input wire           clk,
  input wire           rst,

  input wire     [3:0] filter_sel,

  axis_if.slave        axis_i,
  axis_if.master       axis_o
);

  // TODO: put filters in parallel
  axis_if #( .DATA_TYPE (pixel_pkg::pixel_t) ) axis_pix     ();
  axis_if #( .DATA_TYPE (pixel_pkg::chunk_t) ) axis_buf     ();
  axis_if #( .DATA_TYPE (pixel_pkg::chunk_t) ) axis_blur    ();
  axis_if #( .DATA_TYPE (pixel_pkg::chunk_t) ) axis_edge    ();
  axis_if #( .DATA_TYPE (pixel_pkg::chunk_t) ) axis_sharpen ();

  wire line;
  wire done;

  data_sync data_sync_i (
    .clk    (clk),
    .rst    (rst),
    .line   (line),
    .done   (done),
    .axis_i (axis_i),
    .axis_o (axis_pix)
  );

  img_buf img_buf_i (
    .clk    (clk),
    .rst    (rst),
    .line   (line),
    .done   (done),
    .axis_i (axis_pix),
    .axis_o (axis_buf)
  );

  conv #(
    .DIM    (3),
    .KERNEL ('{
      {'b0010, 'b0010, 'b0010},
      {'b0010, 'b0010, 'b0010},
      {'b0010, 'b0010, 'b0010}
    })
  ) conv_blur (
    .clk    (clk),
    .rst    (rst),
    .en     (filter_sel[0]),
    .axis_i (axis_buf),
    .axis_o (axis_blur)
  );

  conv_int #(
    .DIM    (3),
    .KERNEL ('{
      {-1, -1, -1},
      {-1,  8, -1},
      {-1, -1, -1}
    })
  ) conv_edge_detect (
    .clk    (clk),
    .rst    (rst),
    .en     (filter_sel[1]),
    .axis_i (axis_blur),
    .axis_o (axis_edge)
  );

  chunk_serialize chunk_serialize_i (
    .clk    (clk),
    .rst    (rst),
    .axis_i (axis_edge),
    .axis_o (axis_o)
  );

endmodule
