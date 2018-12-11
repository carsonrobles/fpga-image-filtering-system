`include "pixel_pkg.svh"

module data_path_tb;

  logic clk = 1;
  logic rst = 0;

  wire full;
  wire empty;

  axis_if #( .DATA_TYPE (logic [7:0]) ) axis_i ();
  axis_if #( .DATA_TYPE (logic [7:0]) ) axis_o ();

  data_path dut (
    .clk    (clk),
    .rst    (rst),
    //.line   (line),
    //.done   (done),
    .axis_i (axis_i),
    .axis_o (axis_o),
    .full,
    .empty
  );

  logic tmp = 0;

  always_ff @ (posedge clk) tmp <= ~tmp;

  always_comb axis_o.rdy = tmp;

  always_latch clk <= #5 ~clk;

  logic [7:0] data = '0;

  int clks_to_wait;

  initial begin
    repeat (10) @ (posedge clk);

    // send garbage data (should be ignored)
    repeat (10) begin
      axis_i.data <= $urandom_range(255,0);
      axis_i.vld  <= 1;
      @ (posedge clk);
      axis_i.vld  <= 0;
      clks_to_wait = $urandom_range(100,0);
      $display("clks_to_wait: %d", clks_to_wait);
      repeat (clks_to_wait) @ (posedge clk);
    end

    // send starting data
    axis_i.data <= 8'h42;
    axis_i.vld  <= 1;
    @ (posedge clk);
    axis_i.vld  <= 0;
    clks_to_wait = $urandom_range(100,0);
    repeat (clks_to_wait) @ (posedge clk);

    axis_i.data <= 8'h45;
    axis_i.vld  <= 1;
    @ (posedge clk);
    axis_i.vld  <= 0;
    clks_to_wait = $urandom_range(100,0);
    repeat (clks_to_wait) @ (posedge clk);

    axis_i.data <= 8'h47;
    axis_i.vld  <= 1;
    @ (posedge clk);
    axis_i.vld  <= 0;
    clks_to_wait = $urandom_range(100,0);
    repeat (clks_to_wait) @ (posedge clk);

    axis_i.data <= 8'h4e;
    axis_i.vld  <= 1;
    @ (posedge clk);
    axis_i.vld  <= 0;
    clks_to_wait = $urandom_range(100,0);
    repeat (clks_to_wait) @ (posedge clk);

    // send width and length data
    repeat (2) begin
      repeat (3) begin
        axis_i.data <= 8'h0;
        axis_i.vld  <= 1;
        @ (posedge clk);
        axis_i.vld  <= 0;
        clks_to_wait = $urandom_range(100,0);
        repeat (clks_to_wait) @ (posedge clk);
      end

      axis_i.data <= 8'h5;
      axis_i.vld  <= 1;
      @ (posedge clk);
      axis_i.vld  <= 0;
      clks_to_wait = $urandom_range(100,0);
      repeat (clks_to_wait) @ (posedge clk);
    end

    // send pixel data
    repeat (300) begin
      axis_i.data <= data;
      axis_i.vld  <= 1;
      @ (posedge clk);
      axis_i.vld  <= 0;
      data        <= data + 1;
      clks_to_wait = 100;//$urandom_range(100,0);
      $display("clks_to_wait: %d", clks_to_wait);
      repeat (clks_to_wait) @ (posedge clk);
    end
  end

endmodule
