/*
 *
 */
 
package it.unica.diee.mdc.platformComposer

import java.text.SimpleDateFormat
import java.util.Date
import java.util.List
import net.sf.orcc.df.Network

import it.unica.diee.mdc.sboxManagement.SboxLut
import it.unica.diee.mdc.ConfigManager
import java.util.ArrayList

/*
 * A Verilog Network Configurator printer
 * 
 * @author Carlo Sau
 */
class ConfigPrinter {
	
	var List<SboxLut> luts;
	
	var List<Network> networks;
	
	var ConfigManager configManager;
	
	def headerComments(){
				
		var dateFormat = new SimpleDateFormat("yyyy/MM/dd HH:mm:ss");
		var date = new Date();
		'''
		// ----------------------------------------------------------------------------
		//
		// Multi-Dataflow Composer tool - Platform Composer
		// Configurator module 
		// Date: «dateFormat.format(date)»
		//
		// ----------------------------------------------------------------------------
		'''	
		
	}
	
	def computeNets() {
		networks.addAll(luts.get(0).getNetworks());
	}
	
	def printBody() {
		'''
		
		reg [«luts.size - 1»:0] sel;
		
		// case ID
		always@(ID)
		case(ID)
		«FOR network : networks»
			8'd«configManager.getNetworkId(network.getSimpleName())»:	begin	// «network.getSimpleName()»
			«FOR lut : luts»
							sel[«lut.getCount()»]=«IF lut.getLutValue(network,0)»1«ELSE»0«ENDIF»;
			«ENDFOR»
						end
			«ENDFOR»
			default:	sel=«luts.size»'bx;
		endcase
		
		'''
	}
	
	def printSignals() {
		
		'''
		
		// Input
		input [7:0] ID;
		
		// Ouptut(s)
		output [«luts.size - 1»:0] sel;
		
		'''
	}
	
	def printInterface(Network network) {
		
		'''
		
		module configurator(
			ID,
			sel
		);
		
		'''
	}
	
	def printConfig(Network network, List<SboxLut> luts, ConfigManager configManager){
		// Initialize members
		this.luts = luts; 
		this.configManager = configManager;
		networks = new ArrayList<Network>();
				
		computeNets();

		'''
		«headerComments()»
		
		// ----------------------------------------------------------------------------
		// Module Interface
		// ----------------------------------------------------------------------------
		«printInterface(network)»
		
		// ----------------------------------------------------------------------------
		// Module Signals
		// ----------------------------------------------------------------------------
		«printSignals()»
		
		// ----------------------------------------------------------------------------
		// Body
		// ----------------------------------------------------------------------------
		«printBody()»
		
		endmodule
		// ----------------------------------------------------------------------------
		// ----------------------------------------------------------------------------
		// ----------------------------------------------------------------------------
		'''
	}
	
	

}