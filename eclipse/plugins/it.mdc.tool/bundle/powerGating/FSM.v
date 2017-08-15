`timescale 1ns / 10ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:18:10 12/12/2014 
// Design Name: 
// Module Name:    Top_count 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module FSM(ck, rst, en, en_iso, en_pw_sw);

parameter IDLE_OFF = 2'd0,
	  POWER_SW_OFF = 2'd1,
	  IDLE_ON =  2'd2,
	  ISO_ON = 2'd3;

	input rst,ck, en;
	output en_iso, en_pw_sw;

	reg en_iso, en_pw_sw;
	reg [1 : 0] state, state_next;


	always @(posedge ck or negedge rst)
 	 if (!rst) 	state <= IDLE_ON;
 	 else       state <= state_next;


	always@(state or en)
	  case(state)
	  IDLE_OFF: if(en)
			state_next = POWER_SW_OFF;
		    else
			state_next = IDLE_OFF;
	  POWER_SW_OFF: 
			state_next = IDLE_ON;
	  IDLE_ON:  if(en)
			state_next = IDLE_ON;
		    else
			state_next = ISO_ON;
	  ISO_ON: 
			state_next = IDLE_OFF;
	  default: state_next = IDLE_ON;
	  endcase

	always@(state)
	  case(state)
	  IDLE_OFF:	begin
			en_iso = 1;
			en_pw_sw = 0; 
			end	
	  POWER_SW_OFF:	begin
			en_iso = 1;
			en_pw_sw = 1; 
			end
	  IDLE_ON:	begin
			en_iso = 0;
			en_pw_sw = 1; 
			end
	  ISO_ON:	begin
			en_iso = 1;
			en_pw_sw = 1; 
			end
	  default: 	begin
			en_iso = 0;
			en_pw_sw = 1; 
			end
	  endcase
endmodule
