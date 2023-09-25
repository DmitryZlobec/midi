`timescale 1 ns / 1 ns
module tb;

    //------------------------------------------------------------------------

    logic       clk;
    logic       rst;
    logic [15:0] out_time;

    //------------------------------------------------------------------------

    timer
    i_timer
    (
        .clk ( clk ),
        .rst ( rst ),
        .out_time ( out_time )
    );

    //------------------------------------------------------------------------

    initial
    begin
        clk = 1'b0;
        forever
            # 10 clk = ~ clk;
    end

    //------------------------------------------------------------------------

    initial
    begin
        rst <= 1'bx;
        repeat (2) @ (posedge clk);
        rst <= 1'b1;
        repeat (2) @ (posedge clk);
        rst <= 1'b0;
    end

    initial
    begin
        `ifdef __ICARUS__
            $dumpvars;
        `endif
        
        repeat (1000000)
        begin
            @ (posedge clk);
        end
        $finish;
    end

endmodule
