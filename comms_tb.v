module comms_testbench;
	localparam integer PERIOD = 12000000 / 9600;
	reg clk;
	always #5 clk = (clk === 1'b0);

	reg RX = 1;
	wire TX;

	task send_byte;
		input [7:0] c;
		integer i;
		begin
			RX <= 0;
			repeat (PERIOD) @(posedge clk);

			for (i = 0; i < 8; i = i+1) begin
				RX <= c[i];
				repeat (PERIOD) @(posedge clk);
			end

			RX <= 1;
			repeat (PERIOD) @(posedge clk);
		end
	endtask

	rs232_loopback #(
		.PERIOD(PERIOD)
	) loopback (
		.clk (clk),
                .rx (RX),
		.tx (TX)
	);

	reg [4095:0] vcdfile;

	initial begin
		if ($value$plusargs("vcd=%s", vcdfile)) begin
			$dumpfile(vcdfile);
			$dumpvars(0, comms_testbench);
		end

		repeat (10 * PERIOD) @(posedge clk);

		send_byte("1");
		send_byte("2");
		send_byte("3");
		send_byte("4");
		send_byte("5");

		repeat (60 * PERIOD) @(posedge clk);

		$finish;
	end
endmodule
