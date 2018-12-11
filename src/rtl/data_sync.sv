`include "pixel_pkg.svh"

module data_sync (
  input  wire    clk,
  input  wire    rst,

  output wire    line,
  output wire    done,

  axis_if.slave  axis_i,
  axis_if.master axis_o
);

  enum {
    SYNC,
    WIDTH,
    LENGTH,
    DATA,
    DONE
  } fsm = SYNC, fsm_d;

  logic [7:0] byte_shift [4] = '{default : '0};

  // shift bytes in array
  always_ff @ (posedge clk) begin
    int i;

    if (axis_i.ok)
      for (i = 3; i > 0; i -= 1)
        byte_shift[i] <= byte_shift[i-1];
  end

  // shift in new byte
  always_ff @ (posedge clk)
    if (axis_i.ok) byte_shift[0] <= axis_i.data;

  wire frame_start = (byte_shift[3] == 8'h42) &&
                     (byte_shift[2] == 8'h45) &&
                     (byte_shift[1] == 8'h47) &&
                     (byte_shift[0] == 8'h4e);

  wire frame_end   = (byte_shift[3] == 8'h42) &&
                     (byte_shift[2] == 8'h45) &&
                     (byte_shift[1] == 8'h4e) &&
                     (byte_shift[0] == 8'h44);

  // byte count
  logic [2:0] bcnt = '0;

  always_ff @ (posedge clk) begin
    if      (fsm != fsm_d) bcnt <= '0;
    else if (   axis_i.ok) bcnt <= bcnt + 1;
  end

  // get width
  logic [31:0] width = '0;

  always_ff @ (posedge clk)
    if (rst)
      width <= '0;
    else if (fsm == WIDTH && fsm_d == LENGTH)
      width <= {byte_shift[3], byte_shift[2], byte_shift[1], byte_shift[0]};//logic'(byte_shift);

  // get length
  logic [31:0] length = '0;

  always_ff @ (posedge clk)
    if (rst)
      length <= '0;
    else if (fsm == LENGTH && fsm_d == DATA)
      //length <= logic'(byte_shift);
      length <= {byte_shift[3], byte_shift[2], byte_shift[1], byte_shift[0]};

  // row count
  logic [31:0] rcnt = '0;

  always_ff @ (posedge clk) begin
    if (rst || fsm != DATA)
      rcnt <= '0;
    else
      rcnt <= rcnt + (wcnt == width);
  end

  // pixel shift in data
  logic [7:0] pixel_shift [3] = '{default : '0};
  logic [2:0] pscnt           = 1;

  // track number of shifts
  always_ff @ (posedge clk) begin
    if (rst || fsm != DATA || axis_o.vld)
      pscnt <= 1;
    else if (axis_i.ok)
      pscnt <= {pscnt[1:0], pscnt[2]};
  end

  // column count
  logic [31:0] wcnt = '0;

  always_ff @ (posedge clk) begin
    if (rst || fsm != DATA || wcnt == width) begin
      wcnt <= '0;
    end else if (axis_i.ok) begin
      //wcnt <= wcnt + &pcnt;
      wcnt <= wcnt + (pscnt == 3'b100);
    end
  end


  // shift in pixel data
  always_ff @ (posedge clk) begin
    int i;

    if (rst || fsm != DATA) begin
      pixel_shift <= '{default : '0};
    end else if (axis_i.ok) begin
      /*pixel_shift[0] <= axis_i.data;

      for (i = 2; i > 0; i -= 1)
        pixel_shift[i] <= pixel_shift[i-1];*/
        unique case (pscnt)
          3'b001: pixel_shift[2] <= axis_i.data;
          3'b010: pixel_shift[1] <= axis_i.data;
          3'b100: pixel_shift[0] <= axis_i.data;
        endcase
    end
  end

  // output pixel data
  pixel_pkg::pixel_t pixel = '{default : '0};

  always_comb begin
    pixel.red = pixel_shift[2];
    pixel.grn = pixel_shift[1];
    pixel.blu = pixel_shift[0];
  end

  always_comb axis_o.data = pixel;

  // TODO (carson): valid is not quite right: doesn't hold for ready
  // drive out valid data
  always_ff @ (posedge clk) begin
    axis_o.vld <= (axis_i.ok && fsm == DATA && pscnt == 3'b100);

    /*if (axis_i.ok && fsm == DATA && pscnt == 3'b100)
      axis_o.data <= pixel;*/
  end

  // ready when load module is ready
  always_comb axis_i.rdy = axis_o.rdy;

  // fsm
  always_ff @ (posedge clk) fsm <= (rst) ? SYNC : fsm_d;

  always_comb begin
    case (fsm)
      SYNC    : fsm_d = (   frame_start) ? WIDTH  : SYNC;
      WIDTH   : fsm_d = (bcnt ==      4) ? LENGTH : WIDTH;
      LENGTH  : fsm_d = (bcnt ==      4) ? DATA   : LENGTH;
      DATA    : fsm_d = (rcnt >= length) ? DONE   : DATA;
      DONE    : fsm_d = (     frame_end) ? SYNC   : DONE;
      default : fsm_d = SYNC;
    endcase
  end

  assign line = (wcnt == width  && fsm == DATA);
  assign done = (rcnt == length && fsm == DONE);//(fsm  ==  DONE);

endmodule
