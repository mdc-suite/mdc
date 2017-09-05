// ----------------------------------------------------------------------------
//
// Multi-Dataflow Composer tool - Platform Composer
// Output Finite State Machine module 
// Date: 2014/04/30 12:15:58
//
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// Module Interface
// ----------------------------------------------------------------------------
module fsmOUT_WRmem(
	clk,			// system clock
	rst,			// system reset
	empty, 			// FIFO empty
	selected,		// selected output port
	endwrite,
	enablemem,		// enable memory
	rd_en,			// FIFO read
	go,			// enable size counter
	portEn,			// compute next output port
	free,			// release output port
	clear,      // clear counter register
	load        // load counter 
);
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// Module Parameter(s)
// ----------------------------------------------------------------------------
parameter IDLE  = 0;
parameter RD_FF = 1;
parameter W_MEM = 2;
parameter FREE  = 3;
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// Module Signals
// ----------------------------------------------------------------------------
// Input(s)
input 		clk;
input		rst;
input 		empty;
input		selected;
input    endwrite;
// Output(s)
output 		enablemem;
output		rd_en;
output		go;
output		free;
output		portEn;
output      clear;
output      load;
// Wire(s) and Reg(s)
wire 		clk;
wire		rst;
wire 		empty;
wire		selected;
wire     endwrite;
reg 		enablemem;
reg		rd_en;
reg		go;
reg		free;
reg		portEn;
reg      clear;
reg      load;
// State
reg [1 : 0] 	state;
reg [1 : 0] 	state_nxt;
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// Body
// ----------------------------------------------------------------------------
// State Register
always @ (posedge clk or posedge rst)
	if (rst)
		state <= IDLE;
	else 
		state <= state_nxt;

// State Update
always @ (state,selected,empty)
	case(state)
		IDLE: 	if (selected && !empty) 
				state_nxt = RD_FF;
			else 
				state_nxt = IDLE;
	
		RD_FF: 		state_nxt = W_MEM;
		
		W_MEM: 	if (!empty) 
				state_nxt = W_MEM;
			else 
				state_nxt = FREE;

		FREE: 		state_nxt = IDLE;

		default: 	state_nxt = IDLE;
endcase

// Moore Outputs
always @ (state or empty)
	case(state)
		IDLE: 	begin
				enablemem<=0;
				free<=0;
				go<=0;
				portEn<=1;
			end

		RD_FF: 	begin
				enablemem<=0;
				free<=0;
				go<=0;
				portEn<=0;
			end

		W_MEM: 	begin
				enablemem<=1;
				free<=0;
				go<=1;
				portEn<=0;
			end

		FREE: 	begin
				enablemem<=0;
				free<=1;
				go<=0;
				portEn<=0;
			end

		default: begin
				enablemem<=0;
				free<=0;
				go<=0;
				portEn<=0;
			 end
	endcase

// Mealy Outputs
always @ (state or empty or selected or endwrite)
	case(state)
		IDLE: 		begin
		            rd_en<=0;
						clear<=0; //endwrite
						load<=(selected && !empty);
						end
		RD_FF: 		begin
		            rd_en<=1;
						clear<=0;
						load<=0;
						end
		W_MEM: 		begin
		            rd_en<=!empty;
						clear<=0;
						load<=0;
						end
		FREE: 		begin
		            rd_en<=0;
						clear<=endwrite; //0
						load<=0;
						end
		default: 	begin
		            rd_en<=0;
						clear<=0;
						load<=0;
						end
	endcase
// ----------------------------------------------------------------------------
		
endmodule		
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

