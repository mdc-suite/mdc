module accumulator (
    input in0_empty,
    input [15:0] in0,
    output reg in0_rd,
    input out0_full,
    output reg [15:0] out0,
    output reg out0_wr,
    input clock,
    input reset
    );

	parameter ACC = 0;
	parameter RES = 1;

	reg state;
    reg n_state;
    reg en_state;
    reg [15:0] p_acc;
    reg [15:0] n_acc;
    reg en_acc;
    reg[2:0] count;
    reg[2:0] n_count;
    reg en_count;

  always@(in0, in0_empty, out0_full, count, p_acc, state)
  begin
    if (count==7 && in0_empty==0 && state==ACC) begin
      in0_rd = 1'b1;
      n_state = RES;
      en_state = 1'b1;
      n_acc = (p_acc) + (in0);
      en_acc = 1'b1;
      out0 <= 16'bx;
      out0_wr = 1'b0;
      n_count = count;
      en_count = 1'b0;
 	end
    else if ( in0_empty==0 && state==ACC ) begin
      in0_rd = 1'b1;
      n_state = ACC;
      en_state = 1'b1;
      n_acc = (p_acc) + (in0);
      en_acc = 1'b1;
      n_count = (count) + 1;
      en_count = 1'b1;
      out0 <= 16'bx;
      out0_wr <= 1'b0;
	end
    else if ( state==RES && out0_full==1'b0 ) begin
      n_state = ACC;
      en_state = 1'b1;
      out0 = p_acc;
      out0_wr = 1'b1;
      n_count = 0;
      en_count = 1'b1;
      n_acc = 0;
      en_acc = 1'b1;
      in0_rd = 1'b0;
	end
    else begin
      in0_rd = 1'b0;
      out0_wr = 1'b0;
      out0 = 16'bx;
      en_state = 1'b0;
      en_acc = 1'b0;
      en_count = 1'b0;
      n_state = state;
      n_acc = p_acc;
      n_count = count;
    end
  end

  always@(posedge clock or negedge reset)
  begin
    if (reset==0) begin
      state <= ACC;
      p_acc <= 16'b0000000000000000;
      count <= 3'b000;
	end
    else begin
      if ( en_state ) begin
        state <= n_state;
	  end
      if ( en_acc ) begin
        p_acc <= n_acc;
	  end
      if ( en_count ) begin
        count <= n_count;
      end
	end
  end

endmodule
