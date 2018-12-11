`include "axi.svh"

module conv_int #(
  parameter int                 DIM               = 3,
  parameter logic signed [31:0] KERNEL [DIM][DIM] = '{default : '0}
) (
  input wire     clk,
  input wire     rst,

  input wire     en,

  axis_if.slave  axis_i,   // slave  -- input  chunk data
  axis_if.master axis_o    // master -- output pixel data
);

  logic signed [31:0] mul_red [DIM][DIM];
  logic signed [31:0] mul_grn [DIM][DIM];
  logic signed [31:0] mul_blu [DIM][DIM];

  //always_comb begin
  always_ff @ (posedge clk) begin
    int i, j;

    if (axis_i.ok) begin
      for (i = 0; i < DIM; i += 1) begin
        for (j = 0; j < DIM; j += 1) begin
          mul_red[i][j] <= axis_i.data[i][j].red * KERNEL[i][j];
          mul_grn[i][j] <= axis_i.data[i][j].grn * KERNEL[i][j];
          mul_blu[i][j] <= axis_i.data[i][j].blu * KERNEL[i][j];
        end
      end
    end
  end

  pixel_pkg::pixel_t chunk_org [DIM][DIM];

  always_ff @ (posedge clk) begin
    if (axis_i.ok) begin
      chunk_org <= axis_i.data;
    end
  end

  logic vld_tmp = 0;

  // propagate signal if data was consumed to act as output valid
  always_ff @ (posedge clk) begin
    vld_tmp <= axis_i.ok;
  end

  // request data only when output module is requesting data
  always_comb axis_i.rdy = axis_o.rdy;


  logic signed [31:0] sum_red;
  logic signed [31:0] sum_grn;
  logic signed [31:0] sum_blu;

  // sum the values
  always_comb begin
    int i, j;

    sum_red = 0;
    sum_grn = 0;
    sum_blu = 0;

    for (i = 0; i < DIM; i = i + 1) begin
      for (j = 0; j < DIM; j = j + 1) begin
        sum_red += mul_red[i][j];
        sum_grn += mul_grn[i][j];
        sum_blu += mul_blu[i][j];
      end
    end
  end

  pixel_pkg::pixel_t pixel_add;

  // cap final sum value
  always_comb begin
    pixel_add.red = (sum_red > 255) ? 255 : ((sum_red < 0) ? 0 : sum_red);
    pixel_add.grn = (sum_grn > 255) ? 255 : ((sum_grn < 0) ? 0 : sum_grn);
    pixel_add.blu = (sum_blu > 255) ? 255 : ((sum_blu < 0) ? 0 : sum_blu);
  end

  // output data and valid
  always_ff @ (posedge clk) begin
    axis_o.data <= chunk_org;
    axis_o.vld  <= vld_tmp;

    if (en)
      axis_o.data[DIM/2][DIM/2] <= pixel_add;
  end

endmodule
