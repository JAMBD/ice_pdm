module rs232_loopback #(
	parameter integer PERIOD = 10
) (
    input clk,
    input rx,
    input rx_hold,
    output tx,
    output reg diag
);

        wire rx_stb;
        wire [7:0] rx_data;
        wire tx_stb;
        wire [7:0] tx_data;
        wire rx_has_data;
        wire tx_has_data;
        reg [7:0] sync_tx_data;
        wire [7:0] sync_rx_data;
        reg [7:0] pipe_tracker = 8'b0;

        circular_buffer rx_buffer(
            .w_clk(clk),
            .w_en(rx_stb),
            .r_clk(clk),
            .r_en(rx_has_data & rx_hold),
            .w_data(rx_data),
            .r_data(sync_rx_data),
            .has_data(rx_has_data)
        );

        circular_buffer tx_buffer(
            .w_clk(clk),
            .w_en(pipe_tracker[2]),
            .r_clk(clk),
            .r_en(tx_stb),
            .w_data(sync_tx_data),
            .r_data(tx_data),
            .has_data(tx_has_data)
        );

        rs232_recv #(
            .HALF_PERIOD(PERIOD / 2)
        ) recv (
            .clk (clk),
            .rx (rx),
            .data_byte (rx_data),
            .data_stb (rx_stb)
        );

        rs232_send #(
            .PERIOD(PERIOD)
        ) send (
            .clk (clk),
            .data_byte (tx_data),
            .en(tx_has_data),
            .tx (tx),
            .data_stb(tx_stb)
        );

        always @(posedge clk) begin
            sync_tx_data <= sync_rx_data + 1;
            diag <= diag ^ tx_stb;
        end

        always @(negedge clk) begin
            pipe_tracker <= {pipe_tracker[6:0], rx_has_data & rx_hold};
        end


endmodule
