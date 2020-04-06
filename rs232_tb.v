`timescale 1 ns /  100 ps
module rs232_testbench;
	localparam integer PERIOD = 12000000 / 9600;

	reg clk;
	always #5 clk = (clk === 1'b0);

	reg RX = 1;
        reg [7:0] tx_data = 8'h00;
	wire TX;
        wire [7:0] rx_data;
        wire tx_data_clk;
        wire rx_data_clk;

	rs232_recv #(
		.HALF_PERIOD(PERIOD / 2)
	) recv (
		.clk  (clk ),
		.rx   (RX  ),
                .data_byte (rx_data),
                .data_clk (rx_data_clk)
	);

	rs232_send #(
		.PERIOD(PERIOD)
	) send (
		.clk  (clk ),
                .data_byte (tx_data),
		.tx   (TX  ),
                .data_clk (tx_data_clk)
	);

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

	reg [4095:0] vcdfile;

	initial begin
		if ($value$plusargs("vcd=%s", vcdfile)) begin
			$dumpfile(vcdfile);
			$dumpvars(0, rs232_testbench);
		end

		repeat (10 * PERIOD) @(posedge clk);
                @(posedge tx_data_clk);
                tx_data = 8'hFF;
                @(posedge tx_data_clk);
                tx_data = 8'hAA;
                @(posedge tx_data_clk);
                tx_data = 8'hA5;

		send_byte("1");
		send_byte("2");
		send_byte("3");
		send_byte("4");
		send_byte("5");

		repeat (10 * PERIOD) @(posedge clk);

		$finish;
	end
endmodule
