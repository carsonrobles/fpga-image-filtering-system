`ifndef PIXEL_SVH
`define PIXEL_SVH

package pixel_pkg;

  typedef struct {
    logic [7:0] red;
    logic [7:0] grn;
    logic [7:0] blu;
  } pixel_t;

  typedef pixel_t chunk_t [3][3];

  function pixel_t pix_on_off (
    input pixel_t pixel_i
  );

      pixel_t pixel_o;

      pixel_o.red = (pixel_i.red > 255/2) ? 255 : 0;
      pixel_o.grn = (pixel_i.grn > 255/2) ? 255 : 0;
      pixel_o.blu = (pixel_i.blu > 255/2) ? 255 : 0;

      pix_on_off = pixel_o;

  endfunction

  /*function logic [7:0] median (
    input  logic [7:0] x [9];
  );

    int         i, j;
    logic [7:0] tmp;

    for (i = 0; i < 8; i += 1) begin
      for (j = i + 1; j < n; j += 1) begin
        tmp  = x[i];
        x[i] = x[j];
        x[j] = tmp;
      end
    end

    median = x[4];

  endfunction*/

endpackage

`endif
