`timescale 1 ns /  100 ps
module pdm_recv_testbench;

    reg clk;
    always #5 clk = (clk === 1'b0);

    wire pdm_r_clk;
    wire pdm_l_clk;
    wire pdm_r_dat;
    wire pdm_l_dat;
    wire pdm_clk;
    reg pdm_data;
    reg pdm_mode;

    pdm_dual_recv pdm (
            .clk (clk),
            .mode (pdm_mode),
            .pdm_data (pdm_data),
            .pdm_clk (pdm_clk),
            .pdm_r_stream (pdm_r_dat),
            .pdm_r_clk (pdm_r_clk),
            .pdm_l_stream (pdm_l_dat),
            .pdm_l_clk (pdm_l_clk)
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
            
            send_pdm(16'hAAAA, 16'h3333);

            $finish;
    end
endmodule
