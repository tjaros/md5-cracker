module top #(
	parameter UART_DATA_WIDTH = 8, 
	parameter BAUD_RATE = 115200
)(
	// Keys
	input       [3:0]      KEY,
	
	// 50 MHz Clock
	input 			  	CLOCK_50,
	
	// Debug LEDS
	output		[17:0]    LEDR, 
	output       [7:0]    LEDG,
	
	input  wire rxd,
	output wire txd

);

// Basic wires
wire clk;

// Basic wires assignments
assign clk = CLOCK_50;

// UART wires 
wire       tx_start;
wire       tx_busy;
wire       tx_done;
wire       rx_ready;

wire       [7:0] tx_data;
wire       [7:0] rx_data;


// UART regs
reg [7:0]  tx_data_m = 8'hf1;
reg [7:0]  rx_data_m = 8'h00; 
reg               	rx_rdy_clr;

// Debug LEDS assign
assign LEDG[7] = tx_start;
assign LEDG[6] = tx_busy;
assign LEDG[5] = tx_done;

assign LEDG[0] = rx_rdy_clr;
assign LEDG[1] = rx_ready;

assign LEDR[17:10] = rx_data_m[7:0];
assign LEDR[9:2] = tx_data_m[7:0];


assign tx_start = !KEY[0];
assign tx_data[7:0] = tx_data_m[7:0];

always @(posedge rx_ready)
begin
	rx_data_m <= rx_data;
	rx_rdy_clr <= 1'b1;
end

uart u1(
.din(tx_data),
.wr_en(tx_start),
.clk_50m(CLOCK_50),
.tx(txd),
.tx_busy(tx_busy),
.rx(rxd),
.rdy(rx_ready),
.rdy_clr(rx_rdy_clr),
.dout(rx_data));
endmodule