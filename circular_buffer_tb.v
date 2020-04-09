`timescale 1 ns /  100 ps
module pdm_recv_testbench;

    reg clk;
    always #5 clk = (clk === 1'b0);

    reg write_clk;
    reg read_clk;
    
    reg [7:0] write_data;
    wire [8:0] capacity;
    wire [7:0] read_data;

    circular_buffer c_b (
        .w_clk(write_clk),
        .r_clk(read_clk),
        .w_data(write_data),
        .r_data(read_data),
        .capacity(capacity));

    task write_ram;
        input [7:0] data;
        begin
            write_data <= data;
            repeat (1<<5) @(negedge clk);
            write_clk <= 1;
            repeat (1<<5) @(negedge clk);
            write_clk <= 0;
            repeat (1<<5) @(negedge clk);
        end
    endtask

    task read_ram;
        begin
            repeat (1<<5) @(negedge clk);
            read_clk <= 1;
            repeat (1<<5) @(negedge clk);
            read_clk <= 0;
            repeat (1<<5) @(negedge clk);
        end
    endtask


    reg [4095:0] vcdfile;

    initial begin
            if ($value$plusargs("vcd=%s", vcdfile)) begin
                    $dumpfile(vcdfile);
                    $dumpvars(0, pdm_recv_testbench);
            end

            write_ram(8'h55);
            write_ram(8'h5A);
            write_ram(8'h00);
            read_ram();
            read_ram();
            read_ram();

            $finish;
    end
endmodule
