`include "axi.svh"

module sync_fifo #(
  parameter type DATA_TYPE  = logic [7:0],
  parameter int  FIFO_DEPTH = 8
) (
  input  wire    clk,
  input  wire    rst,

  output logic   full,
  output logic   empty,

  axis_if.slave  axis_i,
  axis_if.master axis_o
);

  //****************************************
  // LOCAL PARAMETERS
  //
  localparam int ADDR_WIDTH = $clog2(FIFO_DEPTH);


  //****************************************
  // CURRENT DATA COUNT
  //
  logic [ADDR_WIDTH:0] cnt = '0;

  always_ff @ (posedge clk) begin
    if (rst)
      cnt <= '0;
    else if (axis_i.ok & ~axis_o.ok)
      cnt <= cnt + 1;
    else if (axis_o.ok & ~axis_i.ok)
      cnt <= cnt - 1;
  end


  //****************************************
  // FULL, EMPTY, READY, AND VALID FLAGS
  //
  assign      full       = (cnt == FIFO_DEPTH);
  assign      empty      = (cnt == 0);

  always_comb axis_i.rdy = ~full;   // fifo will take data as long as not full
  always_comb axis_o.vld = ~empty;  // fifo has valid data as long as not empty


  //****************************************
  // RAM ADDRESS LOGIC
  //
  logic [ADDR_WIDTH-1:0] waddr = '0;

  always_ff @ (posedge clk) begin
    if (rst)
      waddr <= '0;
    else if (axis_i.ok)
      waddr <= waddr + 1;
  end

  logic [ADDR_WIDTH-1:0] raddr = '0;

  always_ff @ (posedge clk) begin
    if (rst)
      raddr <= '0;
    else if (axis_o.ok)
      raddr <= raddr + 1;
  end


  //****************************************
  // WRITE AND READ RAM
  //
  DATA_TYPE mem [FIFO_DEPTH] = '{default : '0};

  // write data
  always_ff @ (posedge clk) begin
    if (rst)
      mem <= '{default : '0};
    else if (axis_i.ok)
      mem[waddr] <= axis_i.data;
  end

  // read data
  always_comb axis_o.data = mem[raddr];

endmodule
