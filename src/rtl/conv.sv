`include "axi.svh"

module conv #(
  parameter int                 DIM               = 3,
  parameter logic signed [31:0] KERNEL [DIM][DIM] = '{default : '0}   // 28.4 fixed point
) (
  input wire     clk,
  input wire     rst,

  input wire     en,

  axis_if.slave  axis_i,   // slave  -- input  chunk data
  axis_if.master axis_o    // master -- output chunk data
);

  localparam int FRAC_BITS = 4;

  logic signed [31:0] data_red [DIM][DIM];
  logic signed [31:0] data_grn [DIM][DIM];
  logic signed [31:0] data_blu [DIM][DIM];

  // convert data in to 28.4 fixed point
  always_comb begin
    int i, j;

    for (i = 0; i < DIM; i += 1)
      for (j = 0; j < DIM; j += 1) begin
        data_red[i][j] = {axis_i.data[i][j].red, {FRAC_BITS{1'b0}}};
        data_grn[i][j] = {axis_i.data[i][j].grn, {FRAC_BITS{1'b0}}};
        data_blu[i][j] = {axis_i.data[i][j].blu, {FRAC_BITS{1'b0}}};
      end
  end

  logic signed [31:0] mul_red [DIM][DIM];
  logic signed [31:0] mul_grn [DIM][DIM];
  logic signed [31:0] mul_blu [DIM][DIM];

  always_ff @ (posedge clk) begin
    int i, j;

    if (axis_i.ok)
      for (i = 0; i < DIM; i += 1)
        for (j = 0; j < DIM; j += 1) begin
          mul_red[i][j] <= (data_red[i][j] * KERNEL[i][j]) >> FRAC_BITS;
          mul_grn[i][j] <= (data_grn[i][j] * KERNEL[i][j]) >> FRAC_BITS;
          mul_blu[i][j] <= (data_blu[i][j] * KERNEL[i][j]) >> FRAC_BITS;
        end
  end

  pixel_pkg::pixel_t chunk_org [DIM][DIM];

  always_ff @ (posedge clk)
    if (axis_i.ok) chunk_org <= axis_i.data;

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

  logic signed [27:0] sum_red_int;
  logic signed [27:0] sum_grn_int;
  logic signed [27:0] sum_blu_int;

  pixel_pkg::pixel_t pixel_add;

  always_comb begin
    // get only integral portion of sum
    sum_red_int = sum_red[31:4];
    sum_grn_int = sum_grn[31:4];
    sum_blu_int = sum_blu[31:4];

    // limit range of final sum value
    pixel_add.red = (sum_red_int > 255) ? 255 : ((sum_red_int < 0) ? 0 : sum_red_int);
    pixel_add.grn = (sum_grn_int > 255) ? 255 : ((sum_grn_int < 0) ? 0 : sum_grn_int);
    pixel_add.blu = (sum_blu_int > 255) ? 255 : ((sum_blu_int < 0) ? 0 : sum_blu_int);
  end

  // register output data and valid
  always_ff @ (posedge clk) begin
    axis_o.data <= chunk_org;
    axis_o.vld  <= vld_tmp;

    if (en) axis_o.data[DIM/2][DIM/2] <= pixel_add;
  end

endmodule
