module pdm_dual_recv (
        input clk,
        input mode,
        input pdm_data,
        output pdm_clk,
        output reg pdm_r_stream,
        output pdm_r_clk,
        output reg pdm_l_stream,
        output pdm_l_clk);

    // For pdm_*_clk, data is sampled on negedge and
    // processing starts at posedge and have until
    // the next negedge to be completed.
    wire pdm_smp_clk;
    reg [7:0] clk_div = 8'b0;
    reg pdm_side_clk;
    
    assign pdm_clk = mode ? clk_div[7] : clk_div[6];
    assign pdm_smp_clk = mode ? clk_div[6] : clk_div[5];
    assign pdm_l_clk = ~pdm_side_clk;
    assign pdm_r_clk = pdm_side_clk;

    always @(posedge clk) begin
        clk_div <= clk_div + 1;
        pdm_side_clk <= pdm_clk ^ pdm_smp_clk;
    end

    always @(negedge pdm_l_clk) begin
        pdm_l_stream <= pdm_data;
    end

    always @(negedge pdm_r_clk) begin
        pdm_r_stream <= pdm_data;
    end
endmodule
