`timescale 1 ns /  100 ps
module circular_buffer_testbench;

    reg clk;
    always #5 clk = (clk === 1'b0);

    reg write_clk = 0;
    reg read_clk = 0;
    
    reg [7:0] write_data;
    wire has_data;
    wire [7:0] read_data;

    circular_buffer c_b (
        .w_clk(write_clk),
        .r_clk(read_clk & has_data),
        .w_data(write_data),
        .r_data(read_data),
        .has_data(has_data));

    task write_ram;
        input [7:0] data;
        begin
            write_data <= data;
            repeat (1<<5) @(posedge clk);
            write_clk <= 1;
            repeat (1<<5) @(posedge clk);
            write_clk <= 0;
            repeat (1<<5) @(posedge clk);
        end
    endtask

    task read_ram;
        begin
            repeat (1<<5) @(posedge clk);
            read_clk <= 1;
            repeat (1<<5) @(posedge clk);
            read_clk <= 0;
            repeat (1<<5) @(posedge clk);
        end
    endtask


    reg [4095:0] vcdfile;

    initial begin
            if ($value$plusargs("vcd=%s", vcdfile)) begin
                    $dumpfile(vcdfile);
                    $dumpvars(0, circular_buffer_testbench);
            end

            write_ram(8'h55);
            write_ram(8'h5A);
            write_ram(8'h00);
            read_ram();
            read_ram();
            read_ram();
            read_ram();

            $finish;
    end
endmodule
