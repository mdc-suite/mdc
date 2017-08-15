/*
 *
 */
 
package it.mdc.tool.platformComposer

import java.text.SimpleDateFormat
import java.util.Date

/*
 * A Verilog Network Configurator printer
 * 
 * @author Carlo Sau
 */
class CgCellPrinter {
	
	def headerComments(String type){
				
		var dateFormat = new SimpleDateFormat("yyyy/MM/dd HH:mm:ss");
		var date = new Date();
		'''
		// ----------------------------------------------------------------------------
		//
		// Multi-Dataflow Composer tool - Platform Composer
		// Clock Gating Cell module 
		// Date: «dateFormat.format(date)»
		//
		// ----------------------------------------------------------------------------
		'''	
		
	}

	
	
	def printBody(String type) {
		'''
		// Latch
		always@(*)
			begin
				if(~clk)
					enable = en;
			end
			
		«IF type.equals("FPGA")»
		// BUFG instance
		BUFGCE BUFGCE_inst (
			.O(ck_gated),
			.CE(enable),
			.I(clk)
		);
		«ELSE»
		// And
		assign ck_gated = clk && enable;
		«ENDIF»
		'''
	}
	
	def printSignals() {
		
		'''
		// Input(s)
		input clk;
		input en;
		
		// Ouptut(s)
		output ck_gated;
		
		// Wire(s)
		wire clk;
		wire en;
		wire ck_gated;
		
		// Reg
		reg enable;
		'''
	}
	
	def printInterface() {
		
		'''	
		module clock_gating_cell(
			clk,
			en,
			ck_gated
		);
		'''
	}
	
	def printCgCell(String type){
		
		'''
		«headerComments(type)»
		
		// ----------------------------------------------------------------------------
		// Module Interface
		// ----------------------------------------------------------------------------
		«printInterface()»
		// ----------------------------------------------------------------------------
		
		// ----------------------------------------------------------------------------
		// Module Signals
		// ----------------------------------------------------------------------------
		«printSignals()»
		// ----------------------------------------------------------------------------
		
		// ----------------------------------------------------------------------------
		// Body
		// ----------------------------------------------------------------------------
		«printBody(type)»
		// ----------------------------------------------------------------------------
		
		endmodule
		// ----------------------------------------------------------------------------
		// ----------------------------------------------------------------------------
		// ----------------------------------------------------------------------------
		'''
	}
	
	
	

}