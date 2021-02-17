module interface_wrapper
(
  input [15:0] a_i_data,
  input a_i_valid,
  output a_i_ready,
  input [3:0] a_i_strb,
  // input a stream
  hwpe_stream_intf_stream.sink   a_i,
  output [15:0] d_o_data,
  output d_o_valid,
  input d_o_ready,
  output [3:0] d_o_strb,
  // output d stream
  hwpe_stream_intf_stream.source d_o
);

  assign a_i.ready = a_i_ready;
  assign a_i_valid = a_i.valid;
  assign a_i_data = a_i.data;
  assign a_i_strb = a_i.strb;

  assign d_o_ready = d_o.ready;
  assign d_o.valid = d_o_valid;
  assign d_o.data = d_o_data;
  assign d_o.strb = d_o_strb;

endmodule

module interface_wrapper_in
(
  input [15:0] in_data,
  input in_valid,
  output in_ready,
  input [3:0] in_strb,
  // input stream intf
  hwpe_stream_intf_stream.sink   in
);

  assign in.ready = in_ready;
  assign in_valid = in.valid;
  assign in_data = in.data;
  assign in_strb = in.strb;

endmodule

module interface_wrapper_out
(
  output [15:0] out_data,
  output out_valid,
  input out_ready,
  output [3:0] out_strb,
  // output stream intf
  hwpe_stream_intf_stream.source out
);

  assign out_ready = out.ready;
  assign out.valid = out_valid;
  assign out.data = out_data;
  //assign out.strb = out_strb;

endmodule
