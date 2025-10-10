/*
 *
 */
 
package it.mdc.tool.core.platformComposer

import java.text.SimpleDateFormat
import java.util.Date
import java.util.List
import net.sf.orcc.df.Network

import it.mdc.tool.core.sboxManagement.SboxLut
import it.mdc.tool.core.ConfigManager
import java.util.ArrayList
import net.sf.orcc.util.OrccLogger

/**
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
		for(Network net:configManager.getNetworkList()){
			networks.add(luts.get(0).getNetworkByName(net.simpleName));
		}
	}
	
	def printBody() {
		    OrccLogger.traceln("DEBUG: Entering printBody method");
		    OrccLogger.traceln("DEBUG: Number of LUTs: " + luts.size);
		    OrccLogger.traceln("DEBUG: Number of networks: " + networks.size);
		    
		'''
		
		reg [«luts.size - 1»:0] sel;
		
		// case ID
		always@(ID)
		case(ID)
		«FOR network : networks»
		
			8'd«configManager.getNetworkId(network.getSimpleName())»:	begin	// «network.getSimpleName()»
			«FOR lut : luts»
							sel[«lut.getCount()»]=«IF lut.getLutValue(network,0)»1'b1«ELSE»1'b0«ENDIF»;
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
    OrccLogger.traceln("DEBUG: ===== Starting printConfig =====");
    OrccLogger.traceln("DEBUG: Input network: " + (network != null ? network.getSimpleName() : "null"));
    OrccLogger.traceln("DEBUG: Number of LUTs received: " + luts.size);
    OrccLogger.traceln("DEBUG: ConfigManager: " + (configManager != null ? "valid" : "null"));
    OrccLogger.traceln("DEBUG: Before computeNets - networks list size: " + networks.size());    				
		computeNets();
	OrccLogger.traceln("DEBUG: After computeNets - networks list size: " + networks.size());
    OrccLogger.traceln("DEBUG: Networks found:");
    for(Network net : networks) {
        OrccLogger.traceln("DEBUG:   - " + net.getSimpleName());
        OrccLogger.traceln("DEBUG:   - " + configManager.getNetworkId(net.getSimpleName()));
        for (SboxLut lut : luts) {
          OrccLogger.traceln("DEBUG:   - lut: " + lut.getCount() + " - " + lut.getLutValue(net, 0));
        }
    }
    
 
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