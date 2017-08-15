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
module FSM_cg(ck, rst, en, en_iso, rstr, save, en_pw_sw, en_cg);

parameter IDLE_OFF = 4'd0,
	  POWER_SW_OFF = 4'd1,
	  RESTORE =  4'd2,
	  HOLD_ISO_ON = 4'd3,
	  IDLE_ON =  4'd4,
	  ISO_ON = 4'd5,
	  SAVE =  4'd6,
	  HOLD_POWER_SW_OFF = 4'd7,
	  CG_OFF = 4'd8,
	  CG_ON = 4'd9;
	  

	input rst,ck, en;
	output en_iso, rstr, save, en_pw_sw, en_cg;

	reg en_iso, rstr, save, en_pw_sw, en_cg;
	reg [3 : 0] state, state_next;


	always @(posedge ck or posedge rst)
 	 if (rst) 	state <= IDLE_ON;
 	 else       state <= state_next;


	always@(state or en)
	  case(state)
	  IDLE_OFF: if(en)
			state_next = POWER_SW_OFF;
		    else
			state_next = IDLE_OFF;
	  POWER_SW_OFF: 
			state_next = RESTORE;
	  RESTORE: 	
			state_next = HOLD_ISO_ON;
	  HOLD_ISO_ON:  
			state_next = CG_ON;
	  CG_ON:
			state_next = IDLE_ON;
	  IDLE_ON:  if(en)
			state_next = IDLE_ON;
		    else
			state_next = ISO_ON;
	  ISO_ON: 
			state_next = CG_OFF;
	  CG_OFF:
			state_next = SAVE;
	  SAVE:  
			state_next = HOLD_POWER_SW_OFF;
	  HOLD_POWER_SW_OFF:  
			state_next = IDLE_OFF;
	  default: state_next = IDLE_ON;
	  endcase

	always@(state)
	  case(state)
	  IDLE_OFF:	begin
			en_iso = 1;
			rstr = 1;
			save = 0;
			en_pw_sw = 0; 
			en_cg = 0; 
			end	
	  POWER_SW_OFF:	begin
			en_iso = 1;
			rstr = 1;
			save = 0;
			en_pw_sw = 1; 
			en_cg = 0;
			end
	  RESTORE:	begin
			en_iso = 1;
			rstr = 0;
			save = 0;
			en_pw_sw = 1; 
			en_cg = 0; 
			end
	  CG_ON:	begin
			en_iso = 1;
			rstr = 1;
			save = 0;
			en_pw_sw = 1; 
			en_cg = 1; 
			end
	  HOLD_ISO_ON:	begin
			en_iso = 1;
			rstr = 1;
			save = 0;
			en_pw_sw = 1; 
			en_cg = 1; 
			end
	  IDLE_ON:	begin
			en_iso = 0;
			rstr = 1;
			save = 0;
			en_pw_sw = 1; 
			en_cg = 1;
			end
	  ISO_ON:	begin
			en_iso = 1;
			rstr = 1;
			save = 0;
			en_pw_sw = 1; 
			en_cg = 1; 
			end
	  CG_OFF:	begin
			en_iso = 1;
			rstr = 1;
			save = 0;
			en_pw_sw = 1; 
			en_cg = 0; 
			end
	  SAVE:		begin
			en_iso = 1;
			rstr = 1;
			save = 1;
			en_pw_sw = 1;  
			en_cg = 0;
			end
	  HOLD_POWER_SW_OFF:begin
			    en_iso = 1;
			    rstr = 1;
			    save = 0;
			    en_pw_sw = 1; 
			    en_cg = 0; 
			    end
	  default: 	begin
			en_iso = 0;
			rstr = 1;
			save = 0;
			en_pw_sw = 1; 
			en_cg = 1; 
			end
	  endcase
endmodule
