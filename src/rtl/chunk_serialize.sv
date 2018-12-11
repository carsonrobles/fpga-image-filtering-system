`include "axi.svh"
`include "pixel_pkg.svh"

module chunk_serialize (
  input wire clk,
  input wire rst,

  axis_if.slave  axis_i,    // pixel chunk in (only concerned with middle pixel)
  axis_if.master axis_o     // single RGB byte out
);

  always_comb axis_i.rdy = axis_o.rdy;

  pixel_pkg::pixel_t pixel = '{default : '0};

  always_ff @ (posedge clk) begin
    if (rst)
      pixel <= '{default : '0};
    else if (axis_i.ok)
      pixel <= axis_i.data[1][1];
  end

  logic vld = 0;

  always_ff @ (posedge clk) begin
    if (rst | (byte_sel == 1 && axis_o.ok))
      vld <= 0;
    else if (axis_i.ok)
      vld <= 1;
  end

  always_comb axis_o.vld = vld;

  logic [2:0] byte_sel = 3'b100;

  always_ff @ (posedge clk) begin
    if (rst)
      byte_sel <= 3'b100;
    else if (axis_o.ok)
      byte_sel <= {byte_sel[0], byte_sel[2:1]};
  end

  always_comb begin
    case (byte_sel)
      3'b100  : axis_o.data = pixel.red;
      3'b010  : axis_o.data = pixel.grn;
      3'b001  : axis_o.data = pixel.blu;
      default : axis_o.data = 'x;
    endcase
  end

endmodule
