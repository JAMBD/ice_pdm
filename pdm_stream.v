module top (
	input  clk,
	output LED1,
	output LED2,
	output LED3,
	output LED4,
	output LED5,
);
	wire pll_clk;
	wire pll_locked;
        reg mode = 0;
	reg [31:0] counter = 32'b0;

        assign LED5 = pll_locked;
        assign LED2 = counter[24]; // 120MHz / 2^26 = 1.788Hz
        assign LED3 = mode;

	always @(posedge clk) begin
		counter <= counter + 1;
                mode <= mode | counter[25];
	end

        // PLL output is 120MHz.
	pll_block pll(
		.clock_in (clk),
		.global_clock (pll_clk),
		.locked (pll_locked))
	;
endmodule

