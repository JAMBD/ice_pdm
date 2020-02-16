module top (
	input  clk,
	input  PDM_DATA_1,
	input  RX,
	output TX,
	output LED1,
	output LED2,
	output LED3,
	output LED4,
	output LED5,
	output PDM_CLK,
);
	parameter integer BAUD_RATE = 4000000;
	parameter integer CLOCK_FREQ_HZ = 120000000;
	localparam integer PERIOD = CLOCK_FREQ_HZ / BAUD_RATE;
	wire pll_clk;
	wire pll_locked;
	wire [23:0] byte;
	wire dummy;	
	wire dummy2;
	wire dummy3;
	//wire mode;
	reg mode = 1'b0;
	assign LED1 = PDM_CLK;
	assign LED2 = mode;
	reg [32:0] counter = 32'b0;
	//assign mode = counter[25];
	always @(posedge clk) begin
		counter <= counter + 1;
	end
	pdm_recv pdm (
		.clk (pll_clk),
		.mode (mode),
		.pdm_clk (PDM_CLK),
		.pdm_data (PDM_DATA_1),
		.pdm_byte (byte));

	pll_block pll(
		.clock_in (clk),
		.global_clock (pll_clk),
		.locked (pll_locked))
	;
	rs232_recv #(
		.HALF_PERIOD(PERIOD / 2)
	) recv (
		.clk  (pll_clk ),
		.RX   (RX  ),
		.LED1 (dummy2),
		.LED2 (dummy3),
		.LED3 (LED3),
		.LED4 (dummy),
		.LED5 (LED5)
	);

	rs232_send #(
		.PERIOD(PERIOD)
	) send (
		.clk  (pll_clk ),
		.TX   (TX  ),
		.byte (byte)
	);
endmodule

module pdm_recv (
	input clk,
	input mode,
	output pdm_clk,
	input pdm_data,
	output [24:0] pdm_byte);
	
	wire clk_2;
	reg [23:0] clk_div = 23'b0;
	reg [23:0] counter = 24'h800000;
	assign pdm_byte = counter;
	always @(posedge clk) begin
		clk_div <= clk_div + 1;
	end

	assign pdm_clk = mode ? clk_div[7] : clk_div[6];
	assign clk_2 = mode ? clk_div[6] : clk_div[5];

	always @(negedge clk_2) begin
		counter <= pdm_data ? counter + 24'h1 : counter - 24'h1;
	end
endmodule

module rs232_recv #(
	parameter integer HALF_PERIOD = 5
) (
	input  clk,
	input  RX,
	output reg LED1,
	output reg LED2,
	output reg LED3,
	output reg LED4,
	output reg LED5
);
	reg [7:0] buffer;
	reg buffer_valid;

	reg [$clog2(3*HALF_PERIOD):0] cycle_cnt;
	reg [3:0] bit_cnt = 0;
	reg recv = 0;

	initial begin
		LED1 = 1;
		LED2 = 0;
		LED3 = 0;
		LED4 = 0;
		LED5 = 0;
	end

	always @(posedge clk) begin
		buffer_valid <= 0;
		if (!recv) begin
			if (!RX) begin
				cycle_cnt <= HALF_PERIOD;
				bit_cnt <= 0;
				recv <= 1;
			end
		end else begin
			if (cycle_cnt == 2*HALF_PERIOD) begin
				cycle_cnt <= 0;
				bit_cnt <= bit_cnt + 1;
				if (bit_cnt == 9) begin
					buffer_valid <= 1;
					recv <= 0;
				end else begin
					buffer <= {RX, buffer[7:1]};
				end
			end else begin
				cycle_cnt <= cycle_cnt + 1;
			end
		end
	end

	always @(posedge clk) begin
		if (buffer_valid) begin
			if (buffer == "1") LED1 <= !LED1;
			if (buffer == "2") LED2 <= !LED2;
			if (buffer == "3") LED3 <= !LED3;
			if (buffer == "4") LED4 <= !LED4;
			if (buffer == "5") LED5 <= !LED5;
		end
	end
endmodule

module rs232_send #(
	parameter integer PERIOD = 10
) (
	input  clk,
	output TX,
	input [23:0] byte
);
	reg [$clog2(PERIOD):0] cycle_cnt = 0;
	reg [4:0] bit_cnt = 0;

	reg [23:0] sample;
	reg [1:0] byte_count;
	reg data_bit;

	wire [7:0] data_byte;
	assign data_byte[7:2] = byte_count[1] ? (byte_count[0] ? byte[23:18] : byte[17:12]) : (byte_count[0] ? byte[11:6] : byte[5:0]);
	assign data_byte[1:0] = byte_count;
	always @(posedge clk) begin
		cycle_cnt <= cycle_cnt + 1;
		if (cycle_cnt == PERIOD-1) begin
			cycle_cnt <= 0;
			bit_cnt <= bit_cnt + 1;
			if (bit_cnt == 10) begin
				bit_cnt <= 0;
				byte_count <= byte_count + 2'h1;
				if (byte_count == 2'h0) begin
					sample <= byte;
				end
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

	assign TX = data_bit;
endmodule
