module top (
	input  clk,
        input RX,
        input [3:0] PDM_DATA,
        output PDM_CLK,
        output TX,
	output LED1,
	output LED2,
	output LED3,
	output LED4,
	output LED5
);
        parameter integer BAUD_RATE = 4000000;
        parameter integer CLOCK_FREQ_HZ = 120000000;
        localparam integer PERIOD = CLOCK_FREQ_HZ / BAUD_RATE;

	wire pll_clk;
	wire pll_locked;
        reg mode = 0;
        reg sync = 1'b1;
	reg [31:0] counter = 32'b0;


        assign LED5 = pll_locked;
        assign LED2 = counter[24]; // 120MHz / 2^26 = 1.788Hz
        assign LED3 = sync;
        assign LED4 = !RX;
        assign LED1 = led_on;

        wire diag;
        reg led_on = 1'b0;
        always @(posedge diag) begin
            led_on = !led_on;
        end

	always @(posedge pll_clk) begin
            counter <= counter + 1;
            sync <= sync & ! counter[26];
            //mode <= mode | counter[26];
	end

        // PLL output is 120MHz.
	pll_block pll(
            .clock_in (clk),
            .global_clock (pll_clk),
            .locked (pll_locked)
        );

        wire pdm_sample;
        wire pdm_0_align_valid;
        wire pdm_1_align_valid;
        wire pdm_sum_valid;
        wire pdm_diff_valid;
        wire pdm_rnd_valid;
        wire [4:0] ch0;
        wire [4:0] ch1;
        wire [4:0] ch2;
        wire [4:0] ch3;
        wire [4:0] ch4;
        wire [4:0] ch5;
        wire pdm_ch0;
        wire pdm_ch1;
        wire pdm_ch2;
        wire pdm_ch3;
        wire pdm_sum;
        wire pdm_diff;
        wire pdm_rnd;
        wire ch0_sample;
        wire ch1_sample;
        wire ch2_sample;
        wire ch3_sample;
        wire ch4_sample;
        wire ch5_sample;
        pdm_clk_gen pdm_clk_gen(
            .clk(pll_clk),
            .mode (mode),
            .pdm_clk (PDM_CLK),
            .pdm_sample_valid (pdm_sample)
        );

        pdm_rnd rng(
                .clk (pll_clk),
                .pdm_sample (pdm_sample),
                .rnd_data (pdm_rnd),
                .data_valid(pdm_rnd_valid)
        );

        pdm_side_sync pdm_0_synced(
                .clk (pll_clk),
                .pdm_clk (PDM_CLK),
                .pdm_sample_valid (pdm_sample),
                .pdm_data (PDM_DATA[0]),
                .data_valid (pdm_0_align_valid),
                .left(pdm_ch0),
                .right(pdm_ch1)
        );

        accum_recv #(
            .ACCUM_BITS(5)
        ) ch0_accum (
                .clk (pll_clk),
                .sample_valid (pdm_0_align_valid),
                .data(pdm_ch0),
                .sync(sync),
                .accum_data(ch0),
                .accum_clk(ch0_sample)
        );

        accum_recv #(
            .ACCUM_BITS(5)
        ) ch1_accum (
                .clk (pll_clk),
                .sample_valid (pdm_0_align_valid),
                .data(pdm_ch1),
                .sync(sync),
                .accum_data(ch1),
                .accum_clk(ch1_sample)
        );

        pdm_side_sync pdm_1_synced(
                .clk (pll_clk),
                .pdm_clk (PDM_CLK),
                .pdm_sample_valid (pdm_sample),
                .pdm_data (PDM_DATA[1]),
                .data_valid (pdm_1_align_valid),
                .left(pdm_ch2),
                .right(pdm_ch3)
        );

        accum_recv #(
            .ACCUM_BITS(5)
        ) ch2_accum (
                .clk (pll_clk),
                .sample_valid (pdm_rnd_valid),
                .data(pdm_rnd),
                .sync(sync),
                .accum_data(ch2),
                .accum_clk(ch2_sample)
        );

        accum_recv #(
            .ACCUM_BITS(5)
        ) ch3_accum (
                .clk (pll_clk),
                .sample_valid (pdm_1_align_valid),
                .data(pdm_ch3),
                .sync(sync),
                .accum_data(ch3),
                .accum_clk(ch3_sample)
        );

        sum_pdm adder(
            .clk (pll_clk),
            .sample_valid (pdm_0_align_valid),
            .a(pdm_ch1),
            .b(pdm_ch2),
            .out(pdm_sum),
            .data_valid(pdm_sum_valid)
        );

        accum_recv #(
            .ACCUM_BITS(5)
        ) sum_accum (
                .clk (pll_clk),
                .sample_valid (pdm_sum_valid),
                .data(pdm_sum),
                .sync(sync),
                .accum_data(ch4),
                .accum_clk(ch4_sample)
        );

        sum_pdm differ(
            .clk (pll_clk),
            .sample_valid (pdm_0_align_valid),
            .a(pdm_ch1),
            .b(!pdm_ch2),
            .out(pdm_diff),
            .data_valid(pdm_diff_valid)
        );

        accum_recv #(
            .ACCUM_BITS(5)
        ) diff_accum (
                .clk (pll_clk),
                .sample_valid (pdm_diff_valid),
                .data(pdm_diff),
                .sync(sync),
                .accum_data(ch5),
                .accum_clk(ch5_sample)
        );

        // Pack serial data
        reg [3:0] tracker = 4'h0;
        reg has_packet = 1'b0;
        reg [2:0] send_byte = 3'h0;
        reg [7:0] packet_data [4:0];
        reg [7:0] tx_data  = 8'h0;
        reg tx_send = 1'b0;
        always @(posedge pll_clk) begin
            tx_send = 1'b0;
            if (ch0_sample)begin
                tracker[0] <= 1'b1;
                packet_data[0] <= {3'h0, ch0};
            end
            if (ch2_sample)begin
                tracker[1] <= 1'b1;
                packet_data[1] <= {3'h1, ch2};
            end
            if (ch5_sample)begin
                tracker[2] <= 1'b1;
                packet_data[2] <= {3'h2, ch5};
            end
            if (ch4_sample)begin
                tracker[3] <= 1'b1;
                packet_data[3] <= {3'h3, ch4};
            end
            if (tracker == 4'hF) begin
                has_packet <= 1'b1;
                tracker <= 4'h0;
                send_byte <= 4'h3;
            end
            if (has_packet) begin
                tx_data <= packet_data[send_byte];
                tx_send <= 1'b1;
                send_byte <= send_byte - 3'h1;
            end
            if (send_byte == 3'h0 && has_packet) begin
                has_packet <= 1'b0;
            end
        end

        rs232_comms #(
            .PERIOD(PERIOD)
        )comms(
            .clk(pll_clk),
            .rx(RX),
            .rx_hold(1'b1),
            .tx(TX),
            .tx_byte(tx_data),
            .tx_ready(tx_send),
            .rx_ready(diag));

endmodule

