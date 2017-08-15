/*
 *
 */
 
package it.mdc.tool.core.platformComposer

import java.text.SimpleDateFormat
import java.util.Date
import java.util.List
import net.sf.orcc.df.Network

import it.mdc.tool.core.ConfigManager
import java.util.ArrayList
import java.util.Set
import java.util.Map
import java.util.HashMap

/*
 * A Verilog Logic Regions Enable Generator printer
 * 
 * @author Carlo Sau
 */
class EnGenPrinter {
	
	var Map<String,Set<String>> logicRegions;
	
	var Map<String,Integer> logicRegionID;
		
	var List<String> networks;
	
	var ConfigManager configManager;
	
	var Map<String,Set<String>> networksInstances;
	
	var Set<String> powerSets;
	
	var Map<String,Integer> powerSetsIndex;
	
	var Map<String,Set<String>> netRegions;
	
	var Map<String,Boolean> logicRegionsSeqMap;
	
	def headerComments(){
				
		var dateFormat = new SimpleDateFormat("yyyy/MM/dd HH:mm:ss");
		var date = new Date();
		'''
		// ----------------------------------------------------------------------------
		//
		// Multi-Dataflow Composer tool - Platform Composer
		// Enable Generator module 
		// Date: «dateFormat.format(date)»		
		//
		// ----------------------------------------------------------------------------
		'''	
		
	}
	
//	def printBody() {		
//		'''
//		
//		reg [«logicRegions.size» : 0] clocks_en;
//		
//		// case ID
//		always@(posedge clock_in)
//		case(ID)
//		«FOR network : networks»
//			8'd«configManager.getNetworkId(network)»:	begin   // «network»
//			«FOR id : logicRegionID.keySet()»				clocks_en[«logicRegionID.get(id)»]=«IF !id.equals("DEFAULT")»«IF networksInstances.get(network).contains(id)»1 // network «network» enables LR«logicRegionID.get(id)»«ELSE»0«ENDIF»«ELSE»1 //Main Clock«ENDIF»;
//			«ENDFOR»
//					end
//		«ENDFOR»
//		default:		clocks_en=«logicRegions.size + 1»'d«(2<<(logicRegions.size))-1»;
//		endcase
//		
//		'''
//	}
	
		def printBody() {		
			
			//«FOR lr: powerList»
		//lr «lr», index in list is «powerList.indexOf(lr)»;
		//«ENDFOR»
		'''
		
		reg [«powerSetsIndex.size - 1» : 0] clocks_en;
		
		// case ID
		always@(posedge clock_in)
		case(ID)
		«FOR network : networks»
			8'd«configManager.getNetworkId(network)»:	begin   // «network»
			«FOR lr: powerSets» «IF logicRegionsSeqMap.get(lr)»
			clocks_en[«powerSetsIndex.get(lr)»] = «IF netRegions.get(network).contains(lr)»1«ELSE»0«ENDIF»;
			«ENDIF» «ENDFOR»
					end
		«ENDFOR»
		default:	clocks_en=«powerSetsIndex.size»'d«(1<<(powerSetsIndex.size))-1»;
		endcase
		
		'''
	}
//	
//	def printSignals() {
//		
//		'''
//		
//		// Input
//		input clock_in;
//		input [7 : 0] ID;
//		
//		// Ouptut(s)
//		output [«logicRegions.size» : 0] clocks_en;
//		
//		'''
//	}

	def printSignals() {
		
		'''
		
		// Input
		input clock_in;
		input [7 : 0] ID;
		
		// Ouptut(s)
		output [«powerSetsIndex.size - 1» : 0] clocks_en;
		
		'''
	}
	
	def printInterface(Network network) {
		
		'''
		
		module enable_generator(
			clocks_en,
			clock_in,
			ID
		);
		
		'''
	}
	
	def printEnGen(Network network, ConfigManager configManager, 
		Map<String,Set<String>> clockSets, 
		Map<String,Set<String>> networksInstances,
			Map<String,Integer> clockDomainsIndex,
			Set<String> powerSets,
			Map<String,Set<String>> netRegions,
			Map<String,Integer> powerSetsIndex,
		 Map<String,Boolean> logicRegionsSeqMap){
		// Initialize members
		this.configManager = configManager;
		networks = new ArrayList<String>();
		networks.addAll(networksInstances.keySet);
		this.logicRegions = clockSets;
		this.logicRegionID = clockDomainsIndex;
		this.networksInstances = networksInstances;
		this.powerSets = powerSets;
		this.netRegions = netRegions;
		this.powerSetsIndex = powerSetsIndex;
		this.logicRegionsSeqMap = logicRegionsSeqMap;
		
		//sortClockSetIDs();
		
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
	
	def sortClockSetIDs() {
		
		var Map<String,String> setsMap = new HashMap<String,String>();
		
		for(int index : 0 .. logicRegions.size-1) {
			if(!logicRegions.containsKey(index)) {
				for(String otherIndex : logicRegions.keySet()){
					if(!(Integer.parseInt(otherIndex)<logicRegions.size)) {
						setsMap.put(String.valueOf(index),otherIndex);
						for(String net : networksInstances.keySet())
							if(networksInstances.get(net).contains(otherIndex)) {
								networksInstances.get(net).remove(otherIndex);
								networksInstances.get(net).add(String.valueOf(index));
						}
					}
				}
			}
		}
		
		for(String index : setsMap.keySet()) {
			logicRegions.put(index,logicRegions.get(setsMap.get(index)));
			logicRegions.remove(setsMap.get(index))
		}
		
	}
	
	

}