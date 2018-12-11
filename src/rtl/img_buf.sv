`include "pixel_pkg.svh"

module img_buf (
  input wire     clk,
  input wire     rst,

  input wire     line,
  input wire     done,

  axis_if.slave  axis_i,
  axis_if.master axis_o
);


  enum {
    FILL,
    RDWR
  } fsm = FILL, fsm_d;



  // buffer should always accept valid data
  always_comb axis_i.rdy = 1;



  //////////////////////////////
  // BRAM SELECT
  //
  logic [2:0] ram_sel = 1;    // one hot bram select

  // circular shift with each complete line
  always_ff @ (posedge clk) begin
    if (rst | done) begin
      ram_sel <= 1;
    end else if (line) begin
      ram_sel <= {ram_sel[1:0], ram_sel[2]};//(ram_sel << 1) | ram_sel[2];
    end
  end



  //////////////////////////////
  // WRITE ADDR
  //
  logic [9:0] waddr = '0;

  always_ff @ (posedge clk) begin
    if (rst | line | done) begin
      waddr <= '0;
    end else if (axis_i.ok) begin   // increment write address with new data
      waddr <= waddr + 1;
    end
  end



  //////////////////////////////
  // READ ADDR
  //
  logic [9:0] raddr;

  always_ff @ (posedge clk)
    if (axis_i.ok) raddr <= waddr;



  //////////////////////////////
  // READ FSM
  //
  always_ff @ (posedge clk) fsm <= (rst | done) ? FILL : fsm_d;

  always_comb begin
    unique case (fsm)
      FILL    : fsm_d = (ram_sel == 3'b100) ? RDWR : FILL;
      RDWR    : fsm_d = (done    == 1     ) ? FILL : RDWR;
      default : fsm_d = FILL;
    endcase
  end
  


  logic [2:0] rd_vld_sft = '0;
  wire        rd_vld     = rd_vld_sft[2];

  always_ff @ (posedge clk) rd_vld_sft <= (rd_vld_sft << 1) | (axis_i.ok & fsm == RDWR);



  //////////////////////////////
  // READ DATA REORGANIZATION
  //
  wire [23:0]        rdata [3];
  pixel_pkg::pixel_t pix   [3];

  logic [2:0] ram_sel_sft [3];
  wire  [2:0] ram_sel_rd = ram_sel_sft[2];

  always_ff @ (posedge clk) begin
    int i;

    /*if (rst | done) begin
      ram_sel_sft <= '{default : '0};
    end else begin*/
      ram_sel_sft[0] <= ram_sel;

      for (i = 2; i > 0; i -= 1)
        ram_sel_sft[i] <= ram_sel_sft[i-1];
    //end
  end

  always_comb begin
    case (ram_sel_rd)
      3'b001 : begin
        pix[0].red = rdata[1][23:16];
        pix[0].grn = rdata[1][15: 8];
        pix[0].blu = rdata[1][ 7: 0];

        pix[1].red = rdata[2][23:16];
        pix[1].grn = rdata[2][15: 8];
        pix[1].blu = rdata[2][ 7: 0];

        pix[2].red = rdata[0][23:16];
        pix[2].grn = rdata[0][15: 8];
        pix[2].blu = rdata[0][ 7: 0];
      end

      3'b010 : begin
        pix[0].red = rdata[2][23:16];
        pix[0].grn = rdata[2][15: 8];
        pix[0].blu = rdata[2][ 7: 0];

        pix[1].red = rdata[0][23:16];
        pix[1].grn = rdata[0][15: 8];
        pix[1].blu = rdata[0][ 7: 0];

        pix[2].red = rdata[1][23:16];
        pix[2].grn = rdata[1][15: 8];
        pix[2].blu = rdata[1][ 7: 0];
      end

      3'b100 : begin
        pix[0].red = rdata[0][23:16];
        pix[0].grn = rdata[0][15: 8];
        pix[0].blu = rdata[0][ 7: 0];

        pix[1].red = rdata[1][23:16];
        pix[1].grn = rdata[1][15: 8];
        pix[1].blu = rdata[1][ 7: 0];

        pix[2].red = rdata[2][23:16];
        pix[2].grn = rdata[2][15: 8];
        pix[2].blu = rdata[2][ 7: 0];
      end

      default : begin
        pix[0].red = '1;
        pix[0].grn = '1;
        pix[0].blu = '1;

        pix[1].red = '1;
        pix[1].grn = '1;
        pix[1].blu = '1;

        pix[2].red = '1;
        pix[2].grn = '1;
        pix[2].blu = '1;
      end
    endcase
  end

  logic [1:0] col_cnt = '0;

  always_ff @ (posedge clk) begin
    if (fsm == FILL) col_cnt <= '0;
    else             col_cnt <= (col_cnt == 3) ? 3 : col_cnt + rd_vld;
  end

  pixel_pkg::chunk_t chunk = '{default : '0};

  // shift 3 new pixels into matrix
  always_ff @ (posedge clk) begin
    int i;

    for (i = 0; i < 3; i++) begin
      if (rd_vld) begin
        chunk[i][2] <= pix[i];
        chunk[i][1] <= chunk[i][2];
        chunk[i][0] <= chunk[i][1];
      end
    end
  end



  //////////////////////////////
  // OUTPUT
  //
  axis_if #( .DATA_TYPE (pixel_pkg::chunk_t) ) axis_fifo ();

  logic hold = 0;

  always_ff @ (posedge clk) begin
    if (rst | axis_fifo.ok)
      hold <= 0;
    else if (rd_vld)
      hold <= 1;
  end

  always_comb axis_fifo.data = chunk;
  always_comb axis_fifo.vld <= (col_cnt == 3) && hold;

  sync_fifo #(
    .DATA_TYPE  (pixel_pkg::chunk_t),
    .FIFO_DEPTH (16)
  ) output_fifo (
    .clk    (clk),
    .rst    (rst),
    .full   ( ),
    .empty  ( ),
    .axis_i (axis_fifo),
    .axis_o (axis_o)
  );



  //////////////////////////////
  // BRAM INST
  //
  wire we = axis_i.ok;
  wire [23:0] pdata = {axis_i.data.red, axis_i.data.grn, axis_i.data.blu};
  wire en = 1;

  blk_mem_gen_0 bram0 (
    .clka  (clk),         // PORT A -- WRITE
    .ena   (ram_sel[0]),  // enable port a with ram select
    .wea   (we),          // shared write enable
    .addra (waddr),       // shared write address
    .dina  (pdata),       // incoming pixel data
    .douta ( ),           // no need for read port

    .clkb  (clk),         // PORT B -- READ
    .enb   (en),          // read port enabled with module
    .web   (0),           // never write on this port
    .addrb (raddr),       // shared read address
    .dinb  (0),           // no need for write data
    .doutb (rdata[0])     // read data out
  );

  blk_mem_gen_0 bram1 (
    .clka  (clk),         // PORT A -- WRITE
    .ena   (ram_sel[1]),  // enable port a with ram select
    .wea   (we),          // shared write enable
    .addra (waddr),       // shared write address
    .dina  (pdata),       // incoming pixel data
    .douta ( ),           // no need for read port

    .clkb  (clk),         // PORT B -- READ
    .enb   (en),          // read port enabled with module
    .web   (0),           // never write on this port
    .addrb (raddr),       // shared read address
    .dinb  (0),           // no need for write data
    .doutb (rdata[1])     // read data out
  );

  blk_mem_gen_0 bram2 (
    .clka  (clk),         // PORT A -- WRITE
    .ena   (ram_sel[2]),  // enable port a with ram select
    .wea   (we),          // shared write enable
    .addra (waddr),       // shared write address
    .dina  (pdata),       // incoming pixel data
    .douta ( ),           // no need for read port

    .clkb  (clk),         // PORT B -- READ
    .enb   (en),          // read port enabled with module
    .web   (0),           // never write on this port
    .addrb (raddr),       // shared read address
    .dinb  (0),           // no need for write data
    .doutb (rdata[2])     // read data out
  );

endmodule
