
module top(
	input       [1:0]      KEY,
	output		[1:0]     LEDR
);

assign LEDR[0] = KEY[0] & KEY[1];
assign LEDR[1] = KEY[0] | KEY[1];

endmodule