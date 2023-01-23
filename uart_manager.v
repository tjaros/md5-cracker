module uart_manager #(parameter DATA_WIDTH=8,parameter ADDR_WIDTH=8)
(
	input 	wire    									clk,
	input    wire                             rst,
	output 	wire   							  	 	txd,
	input 	wire    									rxd,
	inout    reg 									enable,
	input    wire                       	  mode,
	// addr interval to save to or read from
	input    wire [(ADDR_WIDTH-1):0]   	addr_from,
	input    wire [(ADDR_WIDTH-1):0]   	  addr_to,
	// ram outputs 
	output   reg [(DATA_WIDTH-1):0]  	 ram_data,
	output   reg [(ADDR_WIDTH-1):0]      ram_addr,
	// I assume only one device can write at the same time.
	inout    wire                          ram_we,
	// ram value at address
	input    wire [(DATA_WIDTH-1):0]        ram_q,
	output   wire                            busy,
	output   wire [17:0]                 dbg_ledr,
	output   wire [7:0]                  dbg_ledg
);

parameter RECEIVE  = 1'b0;
parameter TRANSMIT = 1'b1;

parameter STATE_IDLE	 = 2'b00;
parameter STATE_START = 2'b01;
parameter STATE_DATA	 = 2'b10;

reg [1:0] STATE = STATE_IDLE;
reg       MODE;

// UART wires
wire       tx_start;
wire       tx_busy;
wire       rx_ready; 
wire       rx_ready_clr;
wire	    [7:0] rx_data;

// UART regs 
reg       [7:0] tx_data;



reg [(ADDR_WIDTH-1):0] idx;
reg [(ADDR_WIDTH-1):0] from;
reg [(ADDR_WIDTH-1):0] to;


always @(posedge clk)
begin
	if (rst) begin
		STATE <= STATE_IDLE;
	end
	case (STATE)
		STATE_IDLE: begin
			if (enable) begin // We init transmission
				idx   <= 8'b0;
				STATE <= STATE_START;
				MODE  <= mode;
				from  <= addr_from;
				to    <= addr_to+1'b1;
			end
		end // STATE_IDLE
		STATE_START: begin
			case (MODE)
				RECEIVE: begin // INIT Receival, Go to data state
					if ((from + idx) == to) begin
						STATE <= STATE_IDLE;
					end else begin
						STATE <= STATE_DATA;
					end
				end
				TRANSMIT: begin 
					if (!tx_busy) begin
						if ((from + idx) == to) begin
							STATE <= STATE_IDLE;
						end else begin 
							tx_data  <= ram_q;
							ram_addr <= from + idx;
							STATE <= STATE_DATA;
							idx <= idx + 8'b1;
						end
					end
				end
			endcase
		end // STATE_START
		STATE_DATA: begin
			
			case (MODE)
				RECEIVE: begin // Cycle till receival ends, Save to RAM
					if (rx_ready) begin
						ram_data <= rx_data;
						ram_addr <= from + idx;
						idx      <= idx + 8'b1;
						STATE    <= STATE_START;
					end 
				end
				TRANSMIT: begin
					STATE    <= STATE_START;
				end
			endcase
		end // STATE_DATA
		default: begin
			STATE <= STATE_IDLE;
		end
	endcase
end

assign busy   = (STATE != STATE_IDLE) ? 1'b1 : 1'b0;
assign ram_we = ((STATE == STATE_DATA) && (MODE == RECEIVE) && (rx_ready)) ? 1'b1 : 1'bz;
assign rx_ready_clr = ((STATE == STATE_DATA) && (MODE == RECEIVE) && (rx_ready));
assign tx_start = ((STATE == STATE_DATA) && (MODE == TRANSMIT));

// DBG LEDS 
assign dbg_ledg[1:0]   = STATE;
assign dbg_ledg[2]     = tx_busy;
assign dbg_ledg[3]     = rx_ready;
assign dbg_ledg[4]     = enable;
assign dbg_ledg[6]     = STATE == STATE_IDLE;

assign dbg_ledr[17:10] = tx_data;
assign dbg_ledr[7:0]   = ram_addr;

uart u1(
.din(tx_data),
.wr_en(tx_start),
.clk_50m(clk),
.tx(txd),
.tx_busy(tx_busy),
.rx(rxd),
.rdy(rx_ready),
.rdy_clr(rx_ready_clr),
.dout(rx_data));


endmodule