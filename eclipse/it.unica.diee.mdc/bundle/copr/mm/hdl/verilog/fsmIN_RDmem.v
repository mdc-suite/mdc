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
	OUT_rdy, 		// generic ready port
	selected,		// loading port selected
	endburst,		// end loading burst
	endsend, 		// end loading port
	IN_send,		// genberic send data
	go,			// enable counters
	portEn,			// enable port selector
	free,			// reset port selector
	load,         // uscita aggiunta caricamento valore contatore
	clear        // reset registri contatore

);
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// Module Parameter(s)
// ----------------------------------------------------------------------------
parameter IDLE=0;
parameter ENMEM=1; 
parameter SEND=2;
parameter FREE=3;
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// Module Signals
// ----------------------------------------------------------------------------
// Input(s)
input clk;
input rst;
input start;
input OUT_rdy;
input selected;
input endburst;
input endsend;
// Output(s)
output IN_send;
output go;
output free;
output portEn;
output load;
output clear;
// Wire(s) and Reg(s)
wire clk;
wire rst;
wire start;
wire OUT_rdy;
wire selected;
wire endburst;
wire endsend;
reg IN_send;
reg go;
reg free;
reg portEn;
reg load;
reg clear;
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
always @ (state or start or selected or OUT_rdy or endburst or endsend)
	case(state)
		IDLE: 	if (!endsend && start && selected && OUT_rdy) 
				state_nxt=ENMEM;
      			else 
				state_nxt=IDLE;		
		ENMEM: 	if (OUT_rdy && !endburst)
				state_nxt=SEND;
			else
			   state_nxt=FREE;			
		SEND: 	if (OUT_rdy && !endburst) 
				state_nxt=SEND;
       			else
			   state_nxt=FREE;	
		FREE: 		state_nxt=IDLE;
		default: 	state_nxt=IDLE;
	endcase


// Moore Outputs
always @ (state)
	case(state)
		IDLE:	begin
  				go=0;
 				IN_send=0;
 				free=0;
 			end
		ENMEM: 	begin
 				go=1;
 			   IN_send=0;
 				free=0;
 			end
		SEND:	begin
 				go=1;
 			   IN_send=1;
 				free=0;
 			end			
		FREE:	begin
 				go=0;
 			   IN_send=1;
 				free=1;
 			end
		default: begin
 				go=0;
 			   IN_send=0;
 				free=0;
 			 end	
	endcase

// Mealy Outputs
always @ (state or selected or endsend or start or OUT_rdy)
	case(state)
		IDLE:		begin 
		         portEn=!selected;
					load=!endsend && start && selected && OUT_rdy;
					clear=!start;
					end
		ENMEM:	begin 
		         portEn=0;
					load=0;
					clear=0;
					end
		SEND:		begin 
		         portEn=0;
					load=0;
					clear=0;
					end
		FREE:		begin 
		         portEn=0;
					load=0;
					clear=0;
					end
		default: begin 
		         portEn=0;
					load=0;
					clear=0;
					end
   endcase

				
endmodule		
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

