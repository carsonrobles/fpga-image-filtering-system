
///////////////////////////////////
//
//  Carson Robles
//  Sep 1, 2016
//
//  7 segment driver
//  displays a 32-bit value on the seven segment display
//
///////////////////////////////////

`define HLF       26'd49999999
`define CNT_WIDTH 16

`ifdef DEBUG
    `define HLF       26'h2
    `define CNT_WIDTH 1
`endif

module sseg_drv (
    input  wire        clk,

    input  wire        en,
    input  wire        mod,

    input  wire [31:0] dat,

    output wire [ 7:0] an,
    output reg  [ 7:0] seg
);

/* blink bit high for half second low for half second */
reg         blnk  = 1'b1;

/* data select to decode and display */
reg  [ 3:0] d_sel;

/* blinking anode */
wire [ 7:0] an_b;

/* final negated anode */
wire [ 7:0] an_n;

/* working anode */
reg  [ 7:0] an_w  = 8'h1;

/* counter to induce a tick signal to switch anode */
reg  [`CNT_WIDTH - 1:0] cnt_a = `CNT_WIDTH'h0;

/* counter used for blinking */
reg  [25:0] cnt_b = 26'h0;

/* tick signal to switch anode */
wire        tck;

/* assign anode to inverted an_n for active low when enabled */
assign an   = (en == 1'b1) ? ~an_n : 8'hff;

/* assign final negated anode */
assign an_n = (mod == 1'b1) ? an_b : an_w;

/* assign blinking anode */
assign an_b = (blnk == 1'b1) ? an_w : 8'h00;

/* assign tck to pulse when cnt is full */
assign tck  = &cnt_a;

/* increment anode counter */
always @ (posedge clk) cnt_a <= cnt_a + `CNT_WIDTH'h1;

/* increment counter */
always @ (posedge clk) begin
    if (cnt_b == `HLF) begin
        cnt_b <= 26'h0;
    end else begin
        cnt_b <= cnt_b + 26'h1;
    end
end

/* toggle blink signal when del reached */
always @ (posedge clk) begin
    if (cnt_b == `HLF) begin
        blnk <= ~blnk;
    end
end

/* decode data select */
always @ (*) begin
    case (d_sel)
        4'h0:    seg = 8'hc0;
        4'h1:    seg = 8'hf9;
        4'h2:    seg = 8'ha4;
        4'h3:    seg = 8'hb0;
        4'h4:    seg = 8'h99;
        4'h5:    seg = 8'h92;
        4'h6:    seg = 8'h82;
        4'h7:    seg = 8'hf8;
        4'h8:    seg = 8'h80;
        4'h9:    seg = 8'h98;
        4'ha:    seg = 8'h88;
        4'hb:    seg = 8'h83;
        4'hc:    seg = 8'hc6;
        4'hd:    seg = 8'ha1;
        4'he:    seg = 8'h86;
        4'hf:    seg = 8'h8e;
        default: seg = 8'hff;
    endcase
end

/* left rotate anode at tck signal */
always @ (posedge clk) begin
    if (tck == 1'b1) begin
        an_w <= (an_w << 1) | an_w[7];
    end
end

/* select data based on current anode */
always @ (*) begin
    case (an_w)
        8'h01:   d_sel = dat[ 3: 0];
        8'h02:   d_sel = dat[ 7: 4];
        8'h04:   d_sel = dat[11: 8];
        8'h08:   d_sel = dat[15:12];
        8'h10:   d_sel = dat[19:16];
        8'h20:   d_sel = dat[23:20];
        8'h40:   d_sel = dat[27:24];
        8'h80:   d_sel = dat[31:28];
        default: d_sel = 4'h0;
    endcase
end

endmodule