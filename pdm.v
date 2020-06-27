module pdm_clk_gen(
    input clk,
    input mode,
    output pdm_clk, 
    output pdm_sample_valid);
    
    reg [6:0] counter = 7'h0;
    assign pdm_clk = mode ? counter[5] : counter[6];
    assign pdm_sample_valid = mode ? counter[4] : counter[5];

    always @(posedge clk) begin
        counter <= counter + 7'h1;
    end
endmodule
    
module pdm_side_sync(
        input clk,
        input pdm_clk,
        input pdm_sample_valid,
        input pdm_data,
        output reg left,
        output reg right,
        output reg data_valid);
    reg left_sample = 1'b0;
    reg prev_pdm_sample_valid = 1'b1;
    always @(posedge clk) begin
        data_valid <= 1'b0;
        prev_pdm_sample_valid <= pdm_sample_valid;
        if (pdm_sample_valid && (! prev_pdm_sample_valid)) begin
            if (pdm_clk) begin
                left_sample <= pdm_data;
            end else begin
                right <=  pdm_data;
                left <= left_sample;
                data_valid <= 1'b1;
            end
        end
    end
endmodule

module sum_pdm(
        input clk,
        input sample_valid,
        input a,
        input b,
        output reg out,
        output reg data_valid);
    reg [15:0] error_accum = 16'h8000;
    reg prev_sample_valid = 1'b1;
    always @(posedge clk) begin
        data_valid <= 1'b0;
        prev_sample_valid <= sample_valid;
        if (sample_valid && (! prev_sample_valid)) begin
            if (a && b) begin
                out <= 1'b1;
                error_accum <= error_accum + 16'h0001;
            end else if (a ^ b) begin
                if (error_accum[15]) begin
                    out <= 1'b1;
                    error_accum <= error_accum - 16'h0001;
                end else begin
                    out <= 1'b0;
                    error_accum <= error_accum + 16'h0001;
                end
            end else if (!a & !b) begin
                out <= 1'b0;
                error_accum <= error_accum - 16'h0001;
            end     
            data_valid <= 1'b1;
        end
    end
endmodule

module accum_recv #(
    parameter integer ACCUM_BITS = 4
)(
        input clk,
        input sample_valid,
        input data,
        input sync,
        output reg [ACCUM_BITS - 1:0] accum_data,
        output reg accum_clk);

    reg prev_sample_valid = 1'b1;

    reg [ACCUM_BITS - 1:0] accum = {1'h1, {ACCUM_BITS - 1{1'h0}}};
    reg [ACCUM_BITS - 2:0] smp_counter = {ACCUM_BITS - 1{1'h0}};

    always @(posedge clk) begin
        if (sync) begin
            smp_counter <= {ACCUM_BITS - 1{1'h0}};
        end
        accum_clk <= 1'b0;
        prev_sample_valid <= sample_valid;
        if (sample_valid && (! prev_sample_valid)) begin
            smp_counter <= smp_counter +  {{ACCUM_BITS - 2{1'h0}}, 1'h1};
            if (&smp_counter) begin
                smp_counter <= {{ACCUM_BITS - 2{1'h0}}, 1'h1};
                accum_clk <= 1'b1;
                accum_data <= accum;
                if (data) begin
                    accum = {1'h1, {ACCUM_BITS - 1{1'h0}}} + {{ACCUM_BITS - 1{1'h0}}, 1'h1};
                end else begin
                    accum = {1'h1, {ACCUM_BITS - 1{1'h0}}} - {{ACCUM_BITS - 1{1'h0}}, 1'h1};
                end
            end else begin
                if (data) begin
                    accum = accum + {{ACCUM_BITS - 1{1'h0}}, 1'h1};
                end else begin
                    accum = accum - {{ACCUM_BITS - 1{1'h0}}, 1'h1};
                end
            end
        end
    end
endmodule
