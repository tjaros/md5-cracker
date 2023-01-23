module top(
	// Keys
	input       [3:0]     KEY,
	
	// 50 MHz Clock
	input 			  CLOCK_50,
	
	// Debug LEDS
	output		[17:0]    LEDR, 
	output       [7:0]    LEDG,

	input  wire rxd,
	output wire txd

);

// Basic wires
wire clk;
wire rst;
wire send;

// Basic wires assignments
assign clk = CLOCK_50;

// RAM parameters
parameter RAM_DATA_WIDTH = 8;
parameter RAM_ADDR_WIDTH = 8;

// RAM wires
wire [(RAM_DATA_WIDTH-1):0] ram_data;
wire [(RAM_ADDR_WIDTH-1):0] ram_addr;
wire [(RAM_DATA_WIDTH-1):0] ram_q;
wire ram_we;

// RAM is used for saving the received data, possibly 
ram #(.DATA_WIDTH(RAM_DATA_WIDTH), .ADDR_WIDTH(RAM_ADDR_WIDTH)) ram1 (
	.data(ram_data),
	.addr(ram_addr),
	.we(ram_we), 
	.clk(clk),
	.q(ram_q)
);

// Message is assumed to be 512 bits long block containing
// 448 bit possibly padded message || 64-bit length of the message before the padding bits were added
// See rfc1321 

parameter ADDR_BLOCK0  = 8'h00;
parameter ADDR_BLOCK64 = 8'h3f;

parameter ADDR_DIGEST0   = 8'h40;
parameter ADDR_DIGEST16  = 8'h4f;

wire uart_busy;
wire uart_enable;

// 0 - receive
// 1 - send
reg uart_mode = 1'b0;
reg [(RAM_ADDR_WIDTH-1):0] addr_from;
reg [(RAM_ADDR_WIDTH-1):0] addr_to;

// When we reset, we expect 512 bit message from UART and Invalidate anything previously
// computed or saved in memory, because it will be overwritten

assign rst  = !KEY[0];
assign send = !KEY[1];

always @(posedge clk) 
begin
		if (rst) begin
			uart_mode <= 1'b0;
			addr_from <= ADDR_BLOCK0;
			addr_to   <= ADDR_BLOCK64;
		end else	if (send) begin
			uart_mode <= 1'b1;
			addr_from <= ADDR_BLOCK0;
			addr_to   <= ADDR_BLOCK64;
		end
end

assign uart_enable = (rst) || (send);


uart_manager #(.ADDR_WIDTH(RAM_ADDR_WIDTH)) uart_mng1
(
	.clk(clk),
	.rst(rst),
	.txd(txd),
	.rxd(rxd),
	.enable(uart_enable),
	.mode(uart_mode),
	.addr_from(addr_from),
	.addr_to(addr_to),
	// Ram runs on the same clock
	.ram_data(ram_data),
	.ram_addr(ram_addr),
	.ram_we(ram_we), 
	.ram_q(ram_q),
	.busy(uart_busy),
	.dbg_ledr(LEDR),
	.dbg_ledg(LEDG)
);

endmodule

