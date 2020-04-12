module circular_buffer(
    input w_clk,
    input w_en,
    input r_clk,
    input r_en,
    input [7:0] w_data,
    output [7:0] r_data,
    output has_data);

    wire [7:0] extra_read;

    reg [8:0] tail = 9'h000;
    reg [8:0] head = 9'h000;
    assign has_data = tail != head;

    SB_RAM40_4K #(
        .WRITE_MODE(1),
        .READ_MODE(1)
    ) ram_block (
        .RDATA({extra_read[7], r_data[7],
                extra_read[6], r_data[6],
                extra_read[5], r_data[5],
                extra_read[4], r_data[4],
                extra_read[3], r_data[3],
                extra_read[2], r_data[2],
                extra_read[1], r_data[1],
                extra_read[0], r_data[0]}),
        .RADDR({2'b0, tail}),
        .RCLK(r_clk),
        .RCLKE(r_en),
        .RE(1'b1),
        .WADDR({2'b0, head}),
        .WCLK(w_clk),
        .WCLKE(w_en),
        .WDATA({1'b0, w_data[7],
                1'b0, w_data[6],
                1'b0, w_data[5],
                1'b0, w_data[4],
                1'b0, w_data[3],
                1'b0, w_data[2],
                1'b0, w_data[1],
                1'b0, w_data[0]}),
        .WE(1'b1)
    );
    defparam ram_block.INIT_0 = 256'h0;
    defparam ram_block.INIT_1 = 256'h0;
    defparam ram_block.INIT_2 = 256'h0;
    defparam ram_block.INIT_3 = 256'h0;
    defparam ram_block.INIT_4 = 256'h0;
    defparam ram_block.INIT_5 = 256'h0;
    defparam ram_block.INIT_6 = 256'h0;
    defparam ram_block.INIT_7 = 256'h0;
    defparam ram_block.INIT_8 = 256'h0;
    defparam ram_block.INIT_9 = 256'h0;
    defparam ram_block.INIT_A = 256'h0;
    defparam ram_block.INIT_B = 256'h0;
    defparam ram_block.INIT_C = 256'h0;
    defparam ram_block.INIT_D = 256'h0;
    defparam ram_block.INIT_E = 256'h0;
    defparam ram_block.INIT_F = 256'h0;


    always @(posedge r_clk) begin
        if (r_en) begin
            tail <= tail + 9'h001;
        end
    end

    always @(posedge w_clk) begin
        if (w_en) begin
            head <= head + 9'h001;
        end
    end
endmodule
