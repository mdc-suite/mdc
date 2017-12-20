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
module FSM_cg(ck, rst, en, reference_count, sw_ack, status, en_iso, rtn, en_pw_sw, en_cg);

parameter IDLE_ON = 5'd0,
	ISO_ON = 5'd1,
	HOLD_ISO_ON = 5'd2,
	CG_ON = 5'd3,
	HOLD_CG_ON = 5'd4,
	SAVE = 5'd5,
	HOLD_SAVE1 = 5'd6,
	HOLD_SAVE2 = 5'd7,
	POWER_SW_OFF = 5'd8,
	WAIT_OFF_ACK = 5'd9,
	WAIT_OFF_COUNTER = 5'd10,
	IDLE_OFF = 5'd11,
	POWER_SW_ON = 5'd12,
	WAIT_ON_ACK = 5'd13,
	WAIT_ON_COUNTER = 5'd14,
	RESTORE = 5'd15,
	HOLD_RESTORE1 = 5'd16,
	HOLD_RESTORE2 = 5'd17,
	CG_OFF = 5'd18,
	HOLD_CG_OFF = 5'd19,
	ISO_OFF = 5'd20,
	HOLD_ISO_OFF = 5'd21;

	input rst,ck, en, sw_ack;
	input [17:0] reference_count;
	output status, en_iso, rtn, en_pw_sw, en_cg;

	reg status, en_iso, rtn, en_pw_sw, en_cg, en_count;
	reg [3 : 0] state, state_next;
	reg [17:0] count, count_next;


	always @(posedge ck or posedge rst)
 	 if (rst) 	state <= IDLE_ON;
 	 else       state <= state_next;

	always @(posedge ck or posedge rst)
 	 if (rst) 	count <= 18'd0;
 	 else       count <= count_next;


	always@(state or en or sw_ack or reference_count or count)
	  case(state)
	IDLE_ON:  if(en)
			state_next = IDLE_ON;
		    else
			state_next = ISO_ON;
	ISO_ON: 
			state_next = HOLD_ISO_ON;
	HOLD_ISO_ON:  
			state_next = CG_ON;
	CG_ON:
			state_next = HOLD_CG_ON;
	HOLD_CG_ON:
			state_next = SAVE;
	SAVE:  
			state_next = HOLD_SAVE1;
	HOLD_SAVE1:  
			state_next = HOLD_SAVE2;
	HOLD_SAVE2:  
			state_next = POWER_SW_OFF;
	POWER_SW_OFF: 
			state_next = WAIT_OFF_ACK;
	WAIT_OFF_ACK: if(sw_ack) 
			state_next = WAIT_OFF_ACK;
		      else 
			state_next = WAIT_OFF_COUNTER;
	WAIT_OFF_COUNTER: if (count == reference_count)
			state_next = IDLE_OFF;
		      else
			state_next = WAIT_OFF_COUNTER;
	IDLE_OFF: if(en)
			state_next = POWER_SW_ON;
		    else
			state_next = IDLE_OFF;
	POWER_SW_ON: 
			state_next = WAIT_ON_ACK;
	WAIT_ON_ACK: if(sw_ack) 
			state_next = WAIT_ON_COUNTER;
		      else 
			state_next = WAIT_ON_ACK;
	WAIT_ON_COUNTER: if (count == reference_count)
			state_next = RESTORE;
		      else
			state_next = WAIT_ON_COUNTER;
	RESTORE: 	
			state_next = HOLD_RESTORE1;
	HOLD_RESTORE1: 	
			state_next = HOLD_RESTORE2;
	HOLD_RESTORE2:
			state_next = CG_OFF;
	CG_OFF:
			state_next = HOLD_CG_OFF;
	HOLD_CG_OFF:
			state_next = ISO_OFF;
	ISO_OFF:
			state_next = HOLD_ISO_OFF;
	HOLD_ISO_OFF:
			state_next = IDLE_ON;	
	default: state_next = IDLE_ON;
	endcase


	always@(count or en_count)
	   	if(en_count) count_next = count +1;
		else count_next = 0;

	always@(state)
	  case(state)
	  IDLE_ON:	begin
			status = 1; // Domani is on
			en_iso = 0; //isolation is disabled
			rtn = 0;	//state retention is disabled
			en_pw_sw = 1; //switches are on
			en_cg = 1; //clock gating is disabled
			en_count = 0; //counting is disabled (count set to 0)
			end

	  ISO_ON:	begin
			status = 1; // Domani is on
			en_iso = 1; //isolation is enabled
			rtn = 0;	//state retention is disabled
			en_pw_sw = 1; //switches are on
			en_cg = 1; //clock gating is disabled
			en_count = 0; //counting is disabled (count set to 0)
			end

	  HOLD_ISO_ON:	begin
			status = 1; // Domani is on
			en_iso = 1; //isolation is enabled
			rtn = 0;	//state retention is disabled
			en_pw_sw = 1; //switches are on
			en_cg = 1; //clock gating is disabled
			en_count = 0; //counting is disabled (count set to 0)
			end

	  CG_ON:	begin
			status = 1; // Domani is on
			en_iso = 1; //isolation is enabled
			rtn = 0;	//state retention is disabled
			en_pw_sw = 1; //switches are on
			en_cg = 0; //clock gating is enabled
			en_count = 0; //counting is disabled (count set to 0)
			end

	  HOLD_CG_ON:	begin
			status = 1; // Domani is on
			en_iso = 1; //isolation is enabled
			rtn = 0;	//state retention is disabled
			en_pw_sw = 1; //switches are on
			en_cg = 0; //clock gating is enabled
			en_count = 0; //counting is disabled (count set to 0)
			end

	  SAVE:	begin
			status = 1; // Domani is on
			en_iso = 1; //isolation is enabled
			rtn = 1;	//state retention is enabled
			en_pw_sw = 1; //switches are on
			en_cg = 0; //clock gating is enabled
			en_count = 0; //counting is disabled (count set to 0)
			end

	  HOLD_SAVE1:	begin
			status = 1; // Domani is on
			en_iso = 1; //isolation is enabled
			rtn = 1;	//state retention is enabled
			en_pw_sw = 1; //switches are on
			en_cg = 0; //clock gating is enabled
			en_count = 0; //counting is disabled (count set to 0)
			end
	  HOLD_SAVE2:	begin
			status = 1; // Domani is on
			en_iso = 1; //isolation is enabled
			rtn = 1;	//state retention is enabled
			en_pw_sw = 1; //switches are on
			en_cg = 0; //clock gating is enabled
			en_count = 0; //counting is disabled (count set to 0)
			end

	  POWER_SW_OFF:	begin
			status = 1; // Domani is on
			en_iso = 1; //isolation is enabled
			rtn = 1;	//state retention is enabled
			en_pw_sw = 0; //switches are off
			en_cg = 0; //clock gating is enabled
			en_count = 0; //counting is disabled (count set to 0)
			end

	  WAIT_OFF_ACK:	begin
			status = 1; // Domani is on
			en_iso = 1; //isolation is enabled
			rtn = 1;	//state retention is enabled
			en_pw_sw = 0; //switches are off
			en_cg = 0; //clock gating is enabled
			en_count = 0; //counting is disabled (count set to 0) 
			end

	  WAIT_OFF_COUNTER: begin
			status = 1; // Domani is on
			en_iso = 1; //isolation is enabled
			rtn = 1;	//state retention is enabled
			en_pw_sw = 0; //switches are off
			en_cg = 0; //clock gating is enabled
			en_count = 1; //counting is enabled 
			end

	  IDLE_OFF:	begin
			status = 0; // Domani is off
			en_iso = 1; //isolation is enabled
			rtn = 1;	//state retention is enabled
			en_pw_sw = 0; //switches are off
			en_cg = 0; //clock gating is enabled
			en_count = 0; //counting is disabled (count set to 0) 
			end

	  POWER_SW_ON:	begin
			status = 0; // Domani is off
			en_iso = 1; //isolation is enabled
			rtn = 1;	//state retention is enabled
			en_pw_sw = 1; //switches are on
			en_cg = 0; //clock gating is enabled
			en_count = 0; //counting is disabled (count set to 0) 
			end

	  WAIT_ON_ACK:	begin
			status = 0; // Domani is off
			en_iso = 1; //isolation is enabled
			rtn = 1;	//state retention is enabled
			en_pw_sw = 1; //switches are on
			en_cg = 0; //clock gating is enabled
			en_count = 0; //counting is disabled (count set to 0) 
			end

	  WAIT_ON_COUNTER:	begin
			status = 0; // Domani is off
			en_iso = 1; //isolation is enabled
			rtn = 1;	//state retention is enabled
			en_pw_sw = 1; //switches are on
			en_cg = 0; //clock gating is enabled
			en_count = 1; //counting is enabled
			end

	  RESTORE:	begin
			status = 0; // Domani is off
			en_iso = 1; //isolation is enabled
			rtn = 0;	//state retention is disabled
			en_pw_sw = 1; //switches are on
			en_cg = 0; //clock gating is enabled
			en_count = 0; //counting is disabled (count set to 0) 
			end

	  HOLD_RESTORE1:	begin
			status = 0; // Domani is off
			en_iso = 1; //isolation is enabled
			rtn = 0;	//state retention is disabled
			en_pw_sw = 1; //switches are on
			en_cg = 0; //clock gating is enabled
			en_count = 0; //counting is disabled (count set to 0) 
			end

	  HOLD_RESTORE2:	begin
			status = 0; // Domani is off
			en_iso = 1; //isolation is enabled
			rtn = 0;	//state retention is disabled
			en_pw_sw = 1; //switches are on
			en_cg = 0; //clock gating is enabled
			en_count = 0; //counting is disabled (count set to 0) 
			end

	  CG_OFF:	begin
			status = 0; // Domani is off
			en_iso = 1; //isolation is enabled
			rtn = 0;	//state retention is disabled
			en_pw_sw = 1; //switches are on
			en_cg = 1; //clock gating is disabled
			en_count = 0; //counting is disabled (count set to 0) 
			end

	  HOLD_CG_OFF:	begin
			status = 0; // Domani is off
			en_iso = 1; //isolation is enabled
			rtn = 0;	//state retention is disabled
			en_pw_sw = 1; //switches are on
			en_cg = 1; //clock gating is disabled
			en_count = 0; //counting is disabled (count set to 0) 
			end

	  ISO_OFF:	begin
			status = 0; // Domani is off
			en_iso = 0; //isolation is disabled
			rtn = 0;	//state retention is disabled
			en_pw_sw = 1; //switches are on
			en_cg = 1; //clock gating is disabled
			en_count = 0; //counting is disabled (count set to 0) 
			end

	  HOLD_ISO_OFF:	begin
			status = 0; // Domani is off
			en_iso = 0; //isolation is disabled
			rtn = 0;	//state retention is disabled
			en_pw_sw = 1; //switches are on
			en_cg = 1; //clock gating is disabled
			en_count = 0; //counting is disabled (count set to 0) 
			end

	  default: 	begin
			status = 1; // Domani is on
			en_iso = 0; //isolation is disabled
			rtn = 0;	//state retention is disabled
			en_pw_sw = 1; //switches are on
			en_cg = 1; //clock gating is disabled
			en_count = 0; //counting is disabled (count set to 0)
			end
	  endcase
endmodule
