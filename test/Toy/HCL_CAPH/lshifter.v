module lshifter(
    input in0_empty,
    input [15:0] in0,
    output reg in0_rd,
    input out0_full,
    output reg [15:0] out0,
    output reg out0_wr,
    input clock,
    input reset
);
  always@(in0, in0_empty, out0_full)
    if (in0_empty==0 && out0_full==0) begin
      in0_rd = 1'b1;
      out0 <= in0 << 1;
      out0_wr = 1'b1;
	end
    else begin
      in0_rd = 1'b0;
      out0_wr = 1'b0;
      out0 = 16'bx;
	end

endmodule
