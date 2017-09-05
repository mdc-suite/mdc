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
module fsmIN_RDmem(
	clk,			// system clock
	rst,			// system reset
	start,			// start loading
	exists,
	OUT_rdy, 		// generic ready port
	endburst,		// end loading burst
	endsend, 		// end loading port
	read,		// enable memory (reading)
	send,		// genberic send data
	count			// enable counters

);
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// Module Parameter(s)
// ----------------------------------------------------------------------------
parameter IDLE=0;
parameter WAITDATA=1; 
parameter SENDDATA=2;
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// Module Signals
// ----------------------------------------------------------------------------
// Input(s)
input wire clk;
input wire rst;
input wire start;
input wire exists;
input wire OUT_rdy;
input wire endburst;
input wire endsend;
// Output(s)
output reg read;
output reg send;
output reg count;

// State
reg [1:0] state;
reg [1:0] state_nxt;
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// Body
// ----------------------------------------------------------------------------
// State Register
always @ (posedge clk or posedge rst)
	if (rst) 
		state<=IDLE;
	else 
		state<=state_nxt;

// State Update
always @ (state or start or OUT_rdy or endburst or endsend or exists)
	case(state)
		IDLE: 	if (!endsend && start && OUT_rdy) 
				state_nxt=WAITDATA;
      			else 
				state_nxt=IDLE;
		WAITDATA: if (!exists && OUT_rdy) 
                   state_nxt=WAITDATA; else
                if (exists && OUT_rdy)
                   state_nxt=SENDDATA;	else					 
                if (!(OUT_rdy)) 
                   state_nxt=IDLE;
		SENDDATA: if (exists && OUT_rdy && !endburst)
                   state_nxt=SENDDATA; else
                if (!exists && OUT_rdy && !endburst)
                   state_nxt=WAITDATA; else
                if (!(OUT_rdy && !endburst))
                   state_nxt=IDLE;						 
		default: 	state_nxt=IDLE;
	endcase

// Mealy Outputs
always @ (state or endburst or exists or OUT_rdy)
	case(state)
		IDLE:	 begin
        		 count=0; 
				 send=0; 
				 read=0;
				 end
		WAITDATA: begin
         	 count=0;
				 send=0;
				 read=exists;
				 end
		SENDDATA:	 begin
       		 count=1;
				 send=1;
				 read=exists && !endburst && OUT_rdy; 
				 end
		default: begin
		         count=0;
				 send=0;
				 read=0;
		         end

	endcase
// ----------------------------------------------------------------------------
				
endmodule		
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

