`timescale 1 ns /  100 ps
module pdm_recv_testbench;

    reg clk;
    always #5 clk = (clk === 1'b0);

    wire pdm_clk;
    wire pdm_smp_clk;
    reg pdm_data;
    reg pdm_mode;

    wire [3:0] left_data;
    wire [3:0] right_data;
    wire data_sample;

    wire right_align;
    wire left_align;
    wire p0_clk;

    wire [3:0] left_accum;
    wire left_accum_clk;
    wire [3:0] right_accum;
    wire right_accum_clk;
    wire sync = 1'b0;

    wire sum_out;
    wire p1_clk;
    wire [3:0] sum_accum;

    wire data_clock;

    pdm_clk_gen pdm_clk_gen(
        .clk(clk),
        .mode (pdm_mode),
        .pdm_clk (pdm_clk),
        .pdm_sample_valid (pdm_smp_clk)
    );

    pdm_side_sync pdm_synced(
            .clk (clk),
            .pdm_data (pdm_data),
            .pdm_clk (pdm_clk),
            .pdm_sample_valid (pdm_smp_clk),
            .left(left_align),
            .right(right_align),
            .data_valid(p0_clk)
    );

    sum_pdm adder(
        .clk (clk),
        .sample_valid (p0_clk),
        .a(left_align),
        .b(right_align),
        .out(sum_out),
        .data_valid(p1_clk)
    );


    accum_recv #(
        .ACCUM_BITS(4)
    ) left_accum_recv (
            .clk (clk),
            .sample_valid (p0_clk),
            .data(left_align),
            .sync(sync),
            .accum_data(left_accum),
            .accum_clk(left_accum_clk)
    );

    accum_recv #(
        .ACCUM_BITS(4)
    ) right_accum_recv (
            .clk (clk),
            .sample_valid (p0_clk),
            .data(right_align),
            .sync(sync),
            .accum_data(right_accum),
            .accum_clk(right_accum_clk)
    );

    accum_recv #(
        .ACCUM_BITS(4)
    ) sum_accum_recv (
            .clk (clk),
            .sample_valid (p1_clk),
            .data(sum_out),
            .sync(sync),
            .accum_data(sum_accum),
            .accum_clk(sum_accum_clk)
    );

    task send_pdm;
        input [15:0] left_data;
        input [15:0] right_data;
        integer i;
        begin
            for (i=0; i<16; i=i+1) begin
                @(posedge pdm_clk)
                pdm_data <= left_data[i];
                @(negedge pdm_clk)
                pdm_data <= right_data[i];
            end
        end
    endtask


    reg [4095:0] vcdfile;

    initial begin
            if ($value$plusargs("vcd=%s", vcdfile)) begin
                    $dumpfile(vcdfile);
                    $dumpvars(0, pdm_recv_testbench);
            end

            pdm_mode <= 1'b1;
            pdm_data <= 1'b0;

            repeat (1<<10) @(posedge clk);
            
            send_pdm(16'h1234, 16'h5432);

            $finish;
    end
endmodule
