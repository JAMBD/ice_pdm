module rs232_loopback #(
	parameter integer PERIOD = 10
) (
    input clk,
    input rx,
    output tx
);

        wire rx_clk;
        wire [7:0] rx_data;
        wire tx_clk;
        wire [7:0] tx_data;
        wire [8:0] rx_capacity;
        wire [8:0] tx_capacity;
        reg [7:0] sync_tx_data;
        wire [7:0] sync_rx_data;
        reg has_input_data = 1'b0;
        reg know_there_is_input_data = 1'b0;
        reg has_processed_data = 1'b0;

        always @(*) begin
            has_input_data = (|rx_capacity) & know_there_is_input_data;
        end

        circular_buffer rx_buffer(
            .w_clk(rx_clk),
            .r_clk(clk & has_input_data),
            .w_data(rx_data),
            .r_data(sync_rx_data),
            .capacity(rx_capacity)
        );

        circular_buffer tx_buffer(
            .w_clk(!clk & has_processed_data),
            .r_clk(tx_clk),
            .w_data(sync_tx_data),
            .r_data(tx_data),
            .capacity(tx_capacity)
        );

        rs232_recv #(
            .HALF_PERIOD(PERIOD / 2)
        ) recv (
            .clk (clk),
            .rx (rx),
            .data_byte (rx_data),
            .data_clk (rx_clk)
        );

        rs232_send #(
            .PERIOD(PERIOD)
        ) send (
            .clk (clk),
            .data_byte (tx_data),
            .en(|tx_capacity),
            .tx (tx),
            .data_clk(tx_clk)
        );

        always @(posedge clk) begin
            know_there_is_input_data <= |rx_capacity;
            if (know_there_is_input_data) begin
                sync_tx_data <= sync_rx_data + 1;
                has_processed_data <= 1'b1;
            end else begin
                has_processed_data <= 1'b0;
            end
        end

endmodule
