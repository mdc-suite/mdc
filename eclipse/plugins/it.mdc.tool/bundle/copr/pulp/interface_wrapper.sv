module interface_wrapper
(
  input [31:0] a_i_data,
  input a_i_valid,
  output a_i_ready,
  // input a stream
  hwpe_stream_intf_stream.sink   a_i,
  output [31:0] d_o_data,
  output d_o_valid,
  input d_o_ready,
  // output d stream
  hwpe_stream_intf_stream.source d_o
);

  assign a_i.ready = a_i_ready;
  assign a_i_valid = a_i.valid;
  assign a_i_data = a_i.data;

  assign d_o_ready = d_o.ready;
  assign d_o.valid = d_o_valid;
  assign d_o.data = d_o_data;

endmodule

module interface_wrapper_in
(
  output [31:0] in_data,
  output in_valid,
  input in_ready,
  // input stream intf
  hwpe_stream_intf_stream.sink   in
);

  assign in.ready = in_ready;
  assign in_valid = in.valid;
  assign in_data = in.data;

endmodule

module interface_wrapper_out
(
  input [31:0] out_data,
  input out_valid,
  output out_ready,
  // output stream intf
  hwpe_stream_intf_stream.source out
);

  assign out_ready = out.ready;
  assign out.valid = out_valid;
  assign out.data = out_data;

endmodule
