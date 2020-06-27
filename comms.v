
module rs232_loopback #(
	parameter integer PERIOD = 10
) (
    input clk,
    input rx,
    input rx_hold,
    output tx,
    output diag
);
    wire rx_ready;
    reg [7:0] sync_tx_data;
    wire [7:0] sync_rx_data;
    reg [7:0] pipe_tracker = 8'b0;

    rs232_comms #(
        .PERIOD(PERIOD)
    )comms(
        .clk(clk),
        .rx(rx),
        .rx_hold(rx_hold),
        .tx(tx),
        .diag(diag),

        .tx_byte(sync_tx_data),
        .tx_ready(pipe_tracker[1]),
        .rx_byte(sync_rx_data),
        .rx_ready(rx_ready));


    always @(posedge clk) begin
        sync_tx_data <= sync_rx_data;
        pipe_tracker <= {pipe_tracker[6:0], rx_ready};
    end

endmodule

module rs232_comms #(
	parameter integer PERIOD = 10
) (
    input clk,
    input rx,
    input rx_hold,
    output tx,
    output reg diag = 1'b0,

    input [7:0] tx_byte,
    input tx_ready,
    output [7:0] rx_byte,
    output rx_ready
);

        wire rx_stb;
        wire [7:0] rx_data;
        wire tx_stb;
        wire [7:0] tx_data;
        wire rx_has_data;
        wire tx_has_data;
        
        assign rx_ready = rx_has_data & rx_hold;

        circular_buffer rx_buffer(
            .w_clk(clk),
            .w_en(rx_stb),
            .r_clk(clk),
            .r_en(rx_ready),
            .w_data(rx_data),
            .r_data(rx_byte),
            .has_data(rx_has_data)
        );

        circular_buffer tx_buffer(
            .w_clk(clk),
            .w_en(tx_ready),
            .r_clk(clk),
            .r_en(tx_stb),
            .w_data(tx_byte),
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

endmodule
