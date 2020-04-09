`timescale 1 ns /  100 ps
module pdm_stream_testbench;
    localparam integer PERIOD = 12000000 / 115200;

    reg clk;
    always #5 clk = (clk === 1'b0);

    reg rx;
    wire led1;
    wire led2;
    wire led3;
    wire led4;
    wire led5;
    wire tx;

    top u1 (
            .clk (clk),
            .RX (rx),
            .TX (tx),
            .LED1 (led1),
            .LED2 (led2),
            .LED3 (led3),
            .LED4 (led4),
            .LED5 (led5)
    );

    reg [4095:0] vcdfile;

    initial begin
            if ($value$plusargs("vcd=%s", vcdfile)) begin
                    $dumpfile(vcdfile);
                    $dumpvars(0, pdm_stream_testbench);
            end

            repeat (1<<10) @(posedge clk);
            
            $finish;
    end
endmodule
