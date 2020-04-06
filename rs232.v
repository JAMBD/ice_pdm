module rs232_recv #(
	parameter integer HALF_PERIOD = 5
) (
	input  clk,
	input  rx,
        output reg [7:0] data_byte,
        output data_clk
);
	reg [7:0] buffer;

	reg [$clog2(3*HALF_PERIOD):0] cycle_cnt;
	reg [3:0] bit_cnt = 0;
	reg recv = 0;

        assign data_clk = !recv;
	always @(posedge clk) begin
		if (!recv) begin
			if (!rx) begin
				cycle_cnt <= HALF_PERIOD;
				bit_cnt <= 0;
				recv <= 1;
			end
		end else begin
			if (cycle_cnt == 2*HALF_PERIOD) begin
				cycle_cnt <= 0;
				bit_cnt <= bit_cnt + 1;
				if (bit_cnt == 9) begin
                                        data_byte <= buffer;
					recv <= 0;
				end else begin
					buffer <= {rx, buffer[7:1]};
				end
			end else begin
				cycle_cnt <= cycle_cnt + 1;
			end
		end
	end

endmodule

module rs232_send #(
	parameter integer PERIOD = 10
) (
	input  clk,
	input [7:0] data_byte,
	output tx,
        output reg data_clk
);
	reg [$clog2(PERIOD):0] cycle_cnt = 0;
	reg [4:0] bit_cnt = 0;

	reg data_bit;

	wire [7:0] data_byte;
	always @(posedge clk) begin
		cycle_cnt <= cycle_cnt + 1;
		if (cycle_cnt == PERIOD-1) begin
			cycle_cnt <= 0;
			bit_cnt <= bit_cnt + 1;
                        if (bit_cnt == 9) begin
                            data_clk <= 1;
                        end
                        if (bit_cnt == 0) begin
                            data_clk <= 0;
                        end
			if (bit_cnt == 10) begin
				bit_cnt <= 0;
			end
		end
	end

	always @(posedge clk) begin
		data_bit = 'bx;
		case (bit_cnt)
			0: data_bit <= 0; // start bit
			1: data_bit <= data_byte[0];
			2: data_bit <= data_byte[1];
			3: data_bit <= data_byte[2];
			4: data_bit <= data_byte[3];
			5: data_bit <= data_byte[4];
			6: data_bit <= data_byte[5];
			7: data_bit <= data_byte[6];
			8: data_bit <= data_byte[7];
			9: data_bit <= 1;  // stop bit
			10: data_bit <= 1; // stop bit
		endcase
	end

	assign tx = data_bit;
endmodule
