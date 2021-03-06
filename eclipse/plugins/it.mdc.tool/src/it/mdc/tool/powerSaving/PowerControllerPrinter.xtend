/*
 *
 */
 
package it.mdc.tool.powerSaving

import java.text.SimpleDateFormat
import java.util.Date
import java.util.List
import net.sf.orcc.df.Network

import it.mdc.tool.core.sboxManagement.SboxLut
import it.mdc.tool.core.ConfigManager
import java.util.ArrayList
import java.util.Map
import java.util.Set

/*
 * A Controller enables for Power saving logic
 * 
 * @author Tiziana Fanni
 */
class PowerController {	
	
	/**Config Manager description*/
	var ConfigManager configManager;
	
	/**Look Up Table */
	var List<SboxLut> luts;
	
	/**List of input networks*/
	var List<Network> networks;
	
	/** Map of instances for each LR*/
	var Map<String,Set<String>> logicRegions;
	
	/** Map of LRs for each network */
	var Map<String,Set<String>> netRegions;
	
	/** Map with one ID for each LR */
	var Map<String, Integer> logicRegionID;
	
	/**Set of switchable LRs */
	var Set<String> powerSets;
	
	/** For each Logic Regions in this map, the key value is true if the LR is sequential, and false if LR is purely combinatorial*/
	var Map<String,Boolean> logicRegionsSeqMap;
	
	def headerComments(){
				
		var dateFormat = new SimpleDateFormat("yyyy/MM/dd HH:mm:ss");
		var date = new Date();
		'''
		// ----------------------------------------------------------------------------
		// Multi-Dataflow Composer tool - Power Saving
		// Power Controller generator
		// Date: «dateFormat.format(date)»
		// ----------------------------------------------------------------------------
		'''	
	}
	
	def computeNets() {
		networks.addAll(luts.get(0).getNetworks());
	}
	
	
	def printInterface() {		
		'''		
		module PowerController(
			ID,
			reference_count,
			
			«FOR lr: powerSets»
			sw_ack«logicRegionID.get(lr)»,
			status«logicRegionID.get(lr)»,
			iso_en«logicRegionID.get(lr)»,
			«IF logicRegionsSeqMap.get(lr)»
			rtn_en«logicRegionID.get(lr)»,
			en_cg«logicRegionID.get(lr)»,
			«ENDIF»
			pw_switch_en«logicRegionID.get(lr)»,
			
			«ENDFOR»	
			rst,
			clk
		);		
		'''
	}
	
	
	def printSignals() {		
		'''		
		// Input
		input clk, rst;
		input [7 : 0] ID;
		input [17:0] reference_count;
		
		«FOR lr: powerSets»
		input	sw_ack«logicRegionID.get(lr)»;
		«ENDFOR»
		
		// Output(s)
		«FOR lr: powerSets»
		output  status«logicRegionID.get(lr)»;
		output	iso_en«logicRegionID.get(lr)»;
		«IF logicRegionsSeqMap.get(lr)»
		output	rtn_en«logicRegionID.get(lr)»;
		output	en_cg«logicRegionID.get(lr)»;
		«ENDIF»
		output	pw_switch_en«logicRegionID.get(lr)»;
		
		«ENDFOR»
		'''
	}
	
			
	def printBody() {		
		'''		
		«FOR lr: powerSets»
		reg en_fsm_«logicRegionID.get(lr)»;
		«ENDFOR»
			
		always@(posedge clk or posedge rst)
		if(rst) begin
			//FSMs enabled
			«FOR lr: powerSets»
			en_fsm_«logicRegionID.get(lr)» = 1;
			«ENDFOR»
			end
		else
			case(ID)
			«FOR network : networks» 
				8'd«configManager.getNetworkId(network.getSimpleName())»:	begin 
					// «network.getSimpleName()»
					«FOR lr: powerSets»
						en_fsm_«logicRegionID.get(lr)» = «IF netRegions.get(network.getSimpleName()).contains(lr)»1'b1«ELSE»1'b0«ENDIF»;										
					«ENDFOR»
					end
			«ENDFOR»
			default:	
				begin
				«FOR lr: powerSets»
				en_fsm_«logicRegionID.get(lr)» = 1;
				«ENDFOR»
				end
			endcase
			
			//An FSM for each Power Domain is instantiated
			
			«FOR lr: powerSets»			
			«IF logicRegionsSeqMap.get(lr)»
			FSM_cg fsm_«logicRegionID.get(lr)» (			
			// Input Signal(s)
			.en(en_fsm_«logicRegionID.get(lr)»),
			.reference_count(reference_count),
			.sw_ack(sw_ack«logicRegionID.get(lr)»),
			// Output Signal(s)
			.status(status«logicRegionID.get(lr)»),
			.en_iso(iso_en«logicRegionID.get(lr)»),
			.rtn(rtn_en«logicRegionID.get(lr)»),		
			.en_cg(en_cg«logicRegionID.get(lr)»),
			.en_pw_sw(pw_switch_en«logicRegionID.get(lr)»),
			// External Signal(s)
			.rst(rst),
			// Clock Signal
			.ck(clk)
			);
			
			«ELSE»
			FSM fsm_«logicRegionID.get(lr)» (			
			// Input Signal(s)
			.en(en_fsm_«logicRegionID.get(lr)»),
			// Output Signal(s)
			.en_iso(iso_en«logicRegionID.get(lr)»),
			.en_pw_sw(pw_switch_en«logicRegionID.get(lr)»),
			// External Signal(s)
			.rst(rst),
			// Clock Signal
			.ck(clk)
			);
			
			«ENDIF»
			«ENDFOR»
		'''
	}
	

	
	def printPowerController(Network network, List<SboxLut> luts, 
		Map<String,Set<String>> logicRegions,
		Map<String,Set<String>> netRegions,
		Map<String, Integer> logicRegionID, 
		ConfigManager configManager, 
		Set<String> powerSets,
		 Map<String,Boolean> logicRegionsSeqMap){
		// Initialize members
		this.logicRegions = logicRegions;
		this.netRegions = netRegions;
		this.logicRegionID = logicRegionID;
		this.luts = luts; 
		this.configManager = configManager;
		this.powerSets = powerSets;
		this.logicRegionsSeqMap = logicRegionsSeqMap;
		
		networks = new ArrayList<Network>();
		
		computeNets();
		//findSharedRegion();
				
		'''
		«headerComments()»
		
		// ----------------------------------------------------------------------------
		// Module Interface
		// ----------------------------------------------------------------------------
		
		«printInterface()»
		
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