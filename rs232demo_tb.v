module testbench;

	reg clk;
	always #5 clk = (clk === 1'b0);

	reg PDM1_DAT;
	wire LED4;
	wire PDM1_CLK;

	pdm_recv pdm (
		.clk (clk),
		.pdm_clk (PDM1_CLK),
		.pdm_data (PDM1_DAT),
		.pdm (LED4)
	);

	reg [4095:0] vcdfile;

	initial begin
		if ($value$plusargs("vcd=%s", vcdfile)) begin
			$dumpfile(vcdfile);
			$dumpvars(0, testbench);
		end

		repeat (1<<14) @(posedge clk);

		$finish;
	end
endmodule
