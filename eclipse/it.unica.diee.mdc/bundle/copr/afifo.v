// ----------------------------------------------------------------------------
//
// Multi-Dataflow Composer tool - Platform Composer
// FIFO module 
// Date: 2014/04/30 12:15:58
//
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// Module Interface
// ----------------------------------------------------------------------------
module a_fifo(
	d_out,
	f_full_flag,
	f_half_full_flag,
	f_empty_flag,
	f_almost_full_flag,
	f_almost_empty_flag,
	d_in,
	r_en,
	w_en,
	r_clk,
	w_clk,
	reset);
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// Module Parameter(s)
// ----------------------------------------------------------------------------
parameter f_width = 8; 			// FIFO width
parameter f_depth = 16; 			// FIFO depth
parameter f_ptr_width = 5; 		// because depth = 16 + OVERFLOW
parameter f_half_full_value = 8;
parameter f_almost_full_value = 14;
parameter f_almost_empty_value = 2;
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// Module Signals
// ----------------------------------------------------------------------------
// Input(s)
input [f_width-1 : 0] 		d_in;
input 				r_en;
input 				w_en;
input				r_clk;
input				w_clk;
input 				reset;
// Ouptut(s)
output [f_width-1 : 0] 		d_out;
output 				f_full_flag;
output				f_half_full_flag;
output				f_almost_full_flag;
output				f_empty_flag;
output				f_almost_empty_flag;
// Wire(s) and Reg(s)
wire [f_ptr_width-1 : 0]	r_ptr;
wire [f_ptr_width-1 : 0] 	w_ptr;
wire 				f_empty_flag_int;
reg [f_width-1 : 0] 		d_out;
reg 				r_next_en;
reg				w_next_en;
reg [f_ptr_width-1 : 0] 	ptr_diff;
// Memory
reg [f_width-1 : 0] 		f_memory[f_depth-1 : 0];
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// Body
// ----------------------------------------------------------------------------
assign f_full_flag=(ptr_diff==(f_depth)); 			// full condition
//assign f_empty_flag=(ptr_diff==0); 				// empty condition
assign f_empty_flag = (r_ptr==w_ptr)? 1:0;			// empty condition
assign f_half_full_flag=(ptr_diff==f_half_full_value); 		// half full condition
assign f_almost_full_flag=(ptr_diff==f_almost_full_value);	// almost full condition
assign f_almost_empty_flag=(ptr_diff==f_almost_empty_value);	// almost empty condition

// Write FIFO
always @(posedge w_clk) begin 					// WEN && !FULL
	if(w_en) begin
		if(!f_full_flag)
			f_memory[w_ptr[f_ptr_width-2:0]]<=d_in; 
	end
end

// Read FIFO
always @(posedge r_clk) begin					//REN && !EMPTY
	if(reset)
		d_out<=0; 
	else if(r_en) begin
		if(!f_empty_flag)
			d_out<=f_memory[r_ptr[f_ptr_width-2:0]]; 
	end
	else d_out<=0;
end

// Pointers Difference Update
always @(*) begin
	if(w_ptr>r_ptr)
		ptr_diff<=w_ptr-r_ptr;
	else if(w_ptr<r_ptr) begin
		ptr_diff<=((f_depth-r_ptr)+w_ptr);
	end
	else 	ptr_diff<=0;
end

// Read Next Update
always @(*) begin  						//after empty flag activated fifo read counter should not increment;
	if(r_en && (!f_empty_flag)) 
		r_next_en=1; 					//REN && !EMPTY ==> READ POINTER INCREMENT ENABLED
	else 	r_next_en=0;
end

// Write Next Update
always @(*) begin 						//after full flag activated fifo write counter should not increment;
	if(w_en && (!f_full_flag))
		w_next_en=1; 					//WEN && !FULL ==> WRITE POINTER INCREMENT ENABLED
	else 	w_next_en=0;
end

// Read Pointer Update (Read Counter)
b_counter #(
	.c_width(f_ptr_width) ) 
r_b_counter(
	.c_out(r_ptr),
	.c_reset(reset),
	.c_clk(r_clk),
	.en(r_next_en)
);

// Write Pointer Update (Write Counter)
b_counter #(
	.c_width(f_ptr_width) ) 
w_b_counter(
	.c_out(w_ptr),
	.c_reset(reset),
	.c_clk(w_clk),
	.en(w_next_en)
);
// ----------------------------------------------------------------------------
		
endmodule		
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
