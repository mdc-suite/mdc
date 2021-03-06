`timescale 1ns / 1ps

module tb_design_1_wrapper;


    reg reset_rtl;
    reg sys_clock;

    design_1_wrapper dut(
        .reset_rtl(reset_rtl),
        .sys_clock(sys_clock)
    );
    
    always #5 sys_clock = ~sys_clock;
    
    initial
        begin
            sys_clock = 0;
            reset_rtl = 1;
            
            #3
            reset_rtl = 0;
            
            #40
            reset_rtl = 1;
            
            #10000
            $stop;
        end

endmodule

