module pll_block(
	input  clock_in,
	output global_clock,
	output locked
);

wire        g_clock_int;


SB_PLL40_CORE #(
`include "pll_param.vh"
) uut (
	.LOCK(locked),
	.RESETB(1'b1),
	.BYPASS(1'b0),
	.REFERENCECLK(clock_in),
	.PLLOUTGLOBAL(g_clock_int)
);

SB_GB sbGlobalBuffer_inst( .USER_SIGNAL_TO_GLOBAL_BUFFER(g_clock_int),
	.GLOBAL_BUFFER_OUTPUT(global_clock) );

endmodule
