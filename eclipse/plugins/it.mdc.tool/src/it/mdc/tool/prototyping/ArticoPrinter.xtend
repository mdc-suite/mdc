/*
 *
 */
 
package it.mdc.tool.prototyping

import java.text.SimpleDateFormat
import java.util.Date
import net.sf.orcc.df.Network
import java.util.Map
import net.sf.orcc.df.Port
import java.util.List
import it.mdc.tool.core.platformComposer.ProtocolManager
import java.util.HashMap
import java.util.ArrayList

/**
 * Printer for ARTICo3 Compliant Kernel
 * 
 * @author Tiziana Fanni
 */
 
class ArticoPrinter extends WrapperPrinter {

	Map <Port,Integer> inputMap;
	Map <Port,Integer> outputMap;
	Map <Port,Integer> portMap;
	List <Integer> signals;
	int portSize;
	int dataSize = 32;
	Map<String,List<Port>> netPorts;

	boolean enableMonitoring;
	
	Map<String,Map<String,String>> netSysSignals;
	Map<String,Map<String,Map<String,String>>> modCommSignals;
	Map<String,Map<String,String>> wrapCommSignals;
	List<String> monList;
	
	override computeNetsPorts(Map<String,Map<String,String>> networkVertexMap) {
		
		netPorts = new HashMap<String,List<Port>>();
		
		for(String net : networkVertexMap.keySet()) {
			for(int id : portMap.values.sort) {
				for(Port port : portMap.keySet) {
					if(portMap.get(port).equals(id)) {
						if(networkVertexMap.get(net).values.contains(port.name)) {
							if(netPorts.containsKey(net)) {
								netPorts.get(net).add(port);
							} else {
								var List<Port> ports = new ArrayList<Port>();
								ports.add(port);
								netPorts.put(net,ports);
							}	
						}
					}
				}
			}	
		}					
	}
	
	override computeSizePointer() {
		if(enableMonitoring)
			return Math.round((((Math.log10(portMap.size + monList.size() )/Math.log10(2))+0.5) as float))
		else
			return Math.round((((Math.log10(portMap.size)/Math.log10(2))+0.5) as float))
	}
	
	override getLongId(int id) {
		if(id<10) {
			return "0"+id.toString();
		} else {
			return id.toString();	
		}
	}
		
	override mapInOut(Network network) {
		
		var index=0;
		var size=0;
		
		inputMap = new HashMap<Port,Integer>();
		outputMap = new HashMap<Port,Integer>();
		portMap = new HashMap<Port,Integer>();
		
		for(Port input : network.getInputs()) {
			inputMap.put(input,index);
			portMap.put(input,index);
			index=index+1;
		}
		
		index=0;
		for(Port output : network.getOutputs()) {
			outputMap.put(output,index);
			portMap.put(output,index+inputMap.size);
			index=index+1;
		}
		
		size = Math.max(inputMap.size,outputMap.size);
		portSize = Math.round((((Math.log10(size)/Math.log10(2))+0.5) as float));
		
	}
		
	override mapSignals() {
		
		var size = Math.max(inputMap.size,outputMap.size);
		var index = 1;
		signals = new ArrayList(size);
		
		while(index<=size) {
			signals.add(index-1,index)
			index = index + 1;
		}
				
	}
	
	override getPortMap(){
		return portMap;
	}
	
	override getInputMap(){
		return inputMap;
	}
		
	override getOutputMap(){
		return outputMap;
	}
	

		
	def initArticoPrinter(Boolean enableMonitoring,
						List<String> monList,
						Map<String,Map<String,String>> netSysSignals, 
						Map<String,Map<String,Map<String,String>>> modCommSignals,
						Map<String,Map<String,String>> wrapCommSignals
	) {
		this.netSysSignals = netSysSignals;
		this.modCommSignals = modCommSignals;
		this.wrapCommSignals = wrapCommSignals;
		this.enableMonitoring = enableMonitoring;
		this.monList = monList;
	}
	
	
	
	override printTop(Network network) {
		
		mapInOut(network);
		mapSignals();
		var dateFormat = new SimpleDateFormat("yyyy/MM/dd HH:mm:ss");
		var date = new Date();
		
		'''	
	// ----------------------------------------------------------------------------
	//
	// This file has been automatically generated by:
	// Multi-Dataflow Composer tool - Platform Composer
	// on «dateFormat.format(date)»
	// More info available at http://sites.unica.it/rpct/
	// 
	// This is an ARTICo³ Compliant Kernel
	// ARTICo³ documentation is available at https://des-cei.github.io/tools/artico3
	//
	// ----------------------------------------------------------------------------

	module cgr_accelerator# (
		parameter integer C_DATA_WIDTH = 32, // Data bus width (for ARTICo³ in Zynq, use 32 bits)
		parameter integer C_ADDR_WIDTH = 16 // Address bus width (for ARTICo³ in Zynq, use 16 bits)
	)		
	(	
	// ----------------------------------------------------------------------------
	// Module Signals
	// ----------------------------------------------------------------------------
		// Global signals
		input clk,
		input reset,
		
		// Control Signals
		input wire start,
		output reg ready,
		
		// Configuration registers					
		output wire [C_DATA_WIDTH-1 : 0] reg_0_o,
		output wire reg_0_o_vld,
		input [C_DATA_WIDTH-1 : 0] reg_0_i,
				
		«FOR port : portMap.keySet»
		// «port.getName()»
		output wire [C_DATA_WIDTH-1 : 0] reg_«portMap.get(port)+1»_o,
		output wire reg_«portMap.get(port)+1»_o_vld,
		input [C_DATA_WIDTH-1 : 0] reg_«portMap.get(port)+1»_i,
		«ENDFOR»
		
		«IF enableMonitoring»
		// Monitors registers
		«FOR String monitor: monList»
		// «monitor»
		output wire [C_DATA_WIDTH-1 : 0] reg_«portMap.keySet.size + 1 + monList.indexOf(monitor)»_o,
		output wire reg_«portMap.keySet.size + 1 + monList.indexOf(monitor)»_o_vld,
		input [C_DATA_WIDTH-1 : 0] reg_«portMap.keySet.size + 1 + monList.indexOf(monitor)»_i,
		«ENDFOR»
		«ENDIF»
		
		// Data memories
		«FOR port : portMap.keySet»
		// bram_«portMap.get(port)» («port.name»)
		output bram_«portMap.get(port)»_clk,
		output bram_«portMap.get(port)»_rst,
		output wire bram_«portMap.get(port)»_en,
		output wire bram_«portMap.get(port)»_we,
		output wire [C_ADDR_WIDTH-1 : 0] bram_«portMap.get(port)»_addr,
		output wire [C_DATA_WIDTH-1 : 0] bram_«portMap.get(port)»_din,
		input wire [C_DATA_WIDTH-1 : 0] bram_«portMap.get(port)»_dout,
		
		«ENDFOR»
		// Data Counter 
		input [31 : 0] values);
		
	// ----------------------------------------------------------------------------
	// ----------------------------------------------------------------------------
		// Wire(s) and Reg(s)
		wire [C_DATA_WIDTH-1:0] slv_reg0;
		«FOR port : portMap.keySet»
		wire [C_DATA_WIDTH-1:0] slv_reg«portMap.get(port)+1»;
		«ENDFOR»
		«IF enableMonitoring»
		// Monitors registers
		«FOR String monitor: monList»
		wire [C_DATA_WIDTH-1:0] slv_reg«portMap.keySet.size + 1 + monList.indexOf(monitor)»; // «monitor»
		«ENDFOR»
		«ENDIF»
		
		wire done;
		wire done_input;
		«FOR input : inputMap.keySet()»
		«FOR commSigId : getInFirstModCommSignals().keySet»
		wire «getSizePrefix(getPortCommSigSize(input,commSigId,getFirstModCommSignals()))»«input.getName()»_«getMatchingWrapMapping(getFirstModCommSignals().get(commSigId).get(ProtocolManager.CH))»;
		«ENDFOR»
		
		«ENDFOR»
		«FOR input : inputMap.keySet()»
		wire en_«input.name»;
		wire done_«input.name»;
		wire last_«input.name»;
		wire [C_ADDR_WIDTH-1:0] count_«input.name»;
		wire wren_mem_«portMap.get(input)+1»;
		wire rden_mem_«portMap.get(input)+1»;
		wire [C_ADDR_WIDTH-1:0] address_mem_«portMap.get(input)+1»;
		wire [C_DATA_WIDTH-1:0] data_in_mem_«portMap.get(input)+1»;
		wire [C_DATA_WIDTH-1:0] data_out_mem_«portMap.get(input)+1»;
		
		«ENDFOR»
		«FOR output : outputMap.keySet()»
		«FOR commSigId : getOutLastModCommSignals().keySet»
		wire «getSizePrefix(getPortCommSigSize(output,commSigId,getLastModCommSignals()))»«output.getName()»_«getMatchingWrapMapping(getLastModCommSignals().get(commSigId).get(ProtocolManager.CH))»;
		«ENDFOR»
		
		«ENDFOR»
		wire done_output;
		«FOR output : outputMap.keySet()»
		wire en_«output.name»;
		wire done_«output.name»;
		wire last_«output.name»;
		wire [C_ADDR_WIDTH-1:0] count_«output.name»;
		wire rden_mem_«portMap.get(output)+1»;
		wire wren_mem_«portMap.get(output)+1»;
		wire [C_ADDR_WIDTH-1:0] address_mem_«portMap.get(output)+1»;
		wire [C_DATA_WIDTH-1:0] data_in_mem_«portMap.get(output)+1»;
		wire [C_DATA_WIDTH-1:0] data_out_mem_«portMap.get(output)+1»;
		
		«ENDFOR»
		
		«IF enableMonitoring»
		//monitoring
		wire valid;		
		«FOR String monitor: monList»
		// Monitor «monList.indexOf(monitor)»: «monitor»
		wire clear_monitor_«monList.indexOf(monitor)»;
		reg [C_DATA_WIDTH-1:0]  «monitor»;
		
		«ENDFOR»
		«IF monList.contains("count_clock_cycles")»
		reg en_clock_count;
		reg state, next_state;  
		«ENDIF»
		«ENDIF»
		
	// Logic to manage ready signal
	// ----------------------------------------------------------------------------
		always@(posedge clk or negedge reset)
		 if(!reset)
		  ready <= 1;
		 else
		   if(start) ready <= 0;
		 else if(done) ready <= 1;
			
		«IF enableMonitoring»
	// ----------------------------------------------------------------------------
	// Monitoring Logic
	// ----------------------------------------------------------------------------
	
	assign valid = 1'b1;
	
		«FOR String monitor: monList»
		«IF monitor.contains("count_full_")»
		// TO FIX
		// monitoring total full of  FIFO  «monitor.replace("count_full_", "")»_full
			always@(posedge clk or negedge reset)
			    if(!reset)
			        begin
			        «monitor» <= 0;
			        end 
			    else
			        begin
			        if(clear_monitor_«monList.indexOf(monitor)»)
			            «monitor» <= 0;
			        else if(«monitor.replace("count_full_", "")»_full)
			            «monitor» <= «monitor» + 1;
			        else 
			            «monitor» <= «monitor»;
			        end
			        
		«ENDIF»
		«IF monitor.equals("count_clock_cycles")»
		// monitoring clock cycles
			always@(posedge clk or negedge reset)
			    if(!reset)
			        begin
			        state <= 0;
			        «monitor» <= 0;
			        end 
			    else
			        begin
			        state <= next_state;
			        if(clear_monitor_«monList.indexOf(monitor)»)
			            «monitor» <= 0;
			        else if(en_clock_count)
			            «monitor» <= «monitor» + 1;
			        else 
			            «monitor» <= «monitor»;
			        end
			        
		 // state transitions (to enable monitoring only from start to done signals)
		    always@(state or start or done)
		        case(state)
		        //wait 
		        1'b0: if(start) 
		            next_state = 1'b1;
		        else
		            next_state = 1'b0;
		        // count
		        1'b1: if(done)
		            next_state = 1'b0;
		        else
		            next_state = 1'b1;
		        default: next_state = 1'b0;
		        endcase 
			        
		 // enabling monitoring
		    always@(state)
		        case(state)
		        //wait (clock count disabled)
		        1'b0: en_clock_count = 0;
		        1'b1: en_clock_count = 1;
		        default: en_clock_count = 0;
		        endcase 
			        
		«ENDIF»
		«IF monitor.contains("count_in_tokens_")»
		// monitoring input tokens (of port «monitor.replace("count_in_tokens_", "")»)		
		always@(posedge clk or negedge reset)
		    if(!reset)
		        begin
		        «monitor» <= 0;
		        end 
		    else
		        begin
		        if(clear_monitor_«monList.indexOf(monitor)»)
		            «monitor» <= 0;
		        else if(rden_mem_«getPortIdFromName(monitor.replace("count_in_tokens_", ""))+1»)
		            «monitor» <= «monitor» + 1;
		        else 
		            «monitor» <= «monitor»;
		        end
		        
		«ENDIF»
		«IF monitor.contains("count_out_tokens_")»
		// monitoring output tokens (of port «monitor.replace("count_out_tokens_", "")»)		
		always@(posedge clk or negedge reset)
		    if(!reset)
		        begin
		        «monitor» <= 0;
		        end 
		    else
		        begin
		        if(clear_monitor_«monList.indexOf(monitor)»)
		            «monitor» <= 0;
		        else if(wren_mem_«getPortIdFromName(monitor.replace("count_out_tokens_", ""))+1»)
		            «monitor» <= «monitor» + 1;
		        else 
		            «monitor» <= «monitor»;
		        end
		        
		«ENDIF»
		«ENDFOR»
		«ENDIF»
			
	// Coprocessor Front-End(s)
	// ----------------------------------------------------------------------------
		«FOR input : inputMap.keySet()»
		front_end i_front_end_«input.name»(
			.aclk(clk),
			.aresetn(reset),
			.start(start),
			.zero(slv_reg«portMap.get(input)+1»[C_ADDR_WIDTH-1:0]=={C_ADDR_WIDTH{1'b1}})
			.last(last_«input.name»),
			.full(«IF isNegMatchingWrapMapping(getFullChannelWrapCommSignalID())»!«ENDIF»«input.name»_full),
			.en(en_«input.name»),
			.rden(rden_mem_«portMap.get(input)+1»),
			.wr(«input.name»_push),
			.done(done_«input.name»)	
		);
		
		counter #(			
			.SIZE(C_ADDR_WIDTH) ) 
		i_counter_«input.name» (
			.aclk(clk),
			.aresetn(reset),
			.clr(ready),
			.en(en_«input.name»),
			.max(slv_reg«portMap.get(input)+1»[C_ADDR_WIDTH-1:0]),
			.count(count_«input.name»),
			.last(last_«input.name»)
		);
		
		assign address_mem_«portMap.get(input)+1» = count_«input.name»;
		assign wren_mem_«portMap.get(input)+1» = 1'b0;
		assign data_in_mem_«portMap.get(input)+1» = 32'b0;
		
		«ENDFOR»
					
		assign done_input = «FOR input : inputMap.keySet() SEPARATOR " && "»done_«input.name»«ENDFOR»;
		
	// ----------------------------------------------------------------------------
	
	// Multi-Dataflow Reconfigurable Datapath
	// ----------------------------------------------------------------------------
			
		multi_dataflow reconf_dpath (
			// Multi-Dataflow Input(s)
			«FOR input : inputMap.keySet()»
			«FOR commSigId : getInFirstModCommSignals().keySet»
			.«input.getName()»«getSuffix(getInFirstModCommSignals(),commSigId)»(«input.getName()»_«getMatchingWrapMapping(getFirstModCommSignals().get(commSigId).get(ProtocolManager.CH))»),
			«ENDFOR»
			«ENDFOR»
			// Multi-Dataflow Output(s)
			«FOR output : outputMap.keySet()»
			«FOR commSigId : getOutLastModCommSignals().keySet»
			.«output.getName()»«getSuffix(getOutLastModCommSignals(),commSigId)»(«IF isNegMatchingWrapMapping(getLastModCommSignals().get(commSigId).get(ProtocolManager.CH))»!«ENDIF»«output.getName()»_«getMatchingWrapMapping(getLastModCommSignals().get(commSigId).get(ProtocolManager.CH))»),
			«ENDFOR»
			«ENDFOR»
			«FOR clockSignal : getClockSysSignals()»
			.«clockSignal»(clk),
			«ENDFOR»
			«FOR resetSignal : getResetSysSignals().keySet»
			.«resetSignal»(reset),
			«ENDFOR»
			// Multi-Dataflow Kernel ID
			.ID(slv_reg0[31:24])
		);
					

		«FOR input :inputMap.keySet»
		assign «input.name»_data = data_out_mem_«portMap.get(input)+1»;
		«ENDFOR»
		«FOR output :outputMap.keySet»
		assign data_in_mem_«portMap.get(output)+1» = «output.name»_data;
		«ENDFOR»
			

	// Coprocessor Back-End(s)
	// ----------------------------------------------------------------------------
		«FOR output : outputMap.keySet()»
		back_end i_back_end_«output.name»(
			.aclk(clk),
			.aresetn(reset),
			.start(start),
			.zero(slv_reg«portMap.get(output)+1»[C_ADDR_WIDTH-1:0]=={C_ADDR_WIDTH{1'b1}}),
			.last(last_«output.name»),
			.wr(«output.name»_push),
			.wren(wren_mem_«portMap.get(output)+1»),
			.en(en_«output.name»),
			.full(«output.name»_full),
			.done(done_«output.name»)
		);
		
		counter #(			
			.SIZE(C_ADDR_WIDTH) )
		i_counter_«output.name» (
			.aclk(clk),
			.aresetn(reset),
			.clr(ready),
			.en(en_«output.name»),
			.max(slv_reg«portMap.get(output)+1»[C_ADDR_WIDTH-1:0]),
			.count(count_«output.name»),
			.last(last_«output.name»)
		);
			
		assign address_mem_«portMap.get(output)+1» = count_«output.name»;
		assign rden_mem_«portMap.get(output)+1» = 1'b0;
		
		«ENDFOR»
		assign done_output = «FOR output : outputMap.keySet() SEPARATOR " && "»done_«output.name»«ENDFOR»;
		assign done = done_input && done_output;
		

		«FOR port : portMap.keySet»
		// bram_«portMap.get(port)» («port.name»)
		assign bram_«portMap.get(port)»_rst = !reset;
		«IF inputMap.containsKey(port)»
		assign bram_«portMap.get(port)»_en = rden_mem_«portMap.get(port)+1»;
		«ELSE»
		assign bram_«portMap.get(port)»_en = wren_mem_«portMap.get(port)+1»;
		«ENDIF»
		assign bram_«portMap.get(port)»_we = wren_mem_«portMap.get(port)+1»;
		assign bram_«portMap.get(port)»_addr = address_mem_«portMap.get(port)+1»;
		assign bram_«portMap.get(port)»_din = data_in_mem_«portMap.get(port)+1»;
		assign data_out_mem_«portMap.get(port)+1» = bram_«portMap.get(port)»_dout;
		«ENDFOR»
		
		assign slv_reg0 = reg_0_i;
		assign reg_0_o_vld = 1'b0;
		assign reg_0_o = {C_DATA_WIDTH{1'b0}};
		
		«FOR port : portMap.keySet»
		assign slv_reg«portMap.get(port)+1» = reg_«portMap.get(port)+1»_i;
		assign reg_«portMap.get(port)+1»_o_vld = 1'b0;
		assign reg_«portMap.get(port)+1»_o = {C_DATA_WIDTH{1'b0}};
		
		«ENDFOR»
		«IF enableMonitoring»
		// Monitors registers
		«FOR String monitor: monList»
		assign slv_reg«portMap.keySet.size + 1 + monList.indexOf(monitor)» = reg_«portMap.keySet.size + 1 + monList.indexOf(monitor)»_i;
		assign reg_«portMap.keySet.size + 1 + monList.indexOf(monitor)»_o_vld = valid;
		assign reg_«portMap.keySet.size + 1 + monList.indexOf(monitor)»_o = «monitor»;
		assign clear_monitor_«monList.indexOf(monitor)» = reg_«portMap.keySet.size + 1 + monList.indexOf(monitor)»_i[31];
		
		«ENDFOR»
		«ENDIF»
	endmodule
	// ----------------------------------------------------------------------------
	// ----------------------------------------------------------------------------
	// ----------------------------------------------------------------------------
		'''
		
	}
	
	override printXML(){
		
	'''
	<?xml version="1.0" encoding="UTF-8"?>
	<mdcInfo>
	  <baseAddress>0x43C00000</baseAddress>
	  <nbEvents>«monList.size»</nbEvents>
	  «FOR String monitor: monList»
	  <event> 
	    <index>«portMap.size+1+monList.indexOf(monitor)»</index>
	    «IF monitor.contains("count_full_")»
	    <name>MDC_«monitor.replace("count_", "").toUpperCase()»</name>
	    <desc>Total number of FIFO full of input «monitor.replace("count_full_", "")» during the execution of the accelerator</desc>
	    «ENDIF»
	    «IF monitor.contains("count_clock_cycles")»
	    <name>MDC_«monitor.replace("count_", "").toUpperCase()»</name>
	    <desc>Number of clock cycles from start to done signals.</desc>
	    «ENDIF»
	    «IF monitor.contains("count_in_tokens_")»
	    <name>MDC_«monitor.replace("count_in_", "").toUpperCase()»</name>
	    <desc>Number of input tokens to the accelerator at port «monitor.replace("count_in_tokens_", "")»</desc>
	    «ENDIF»
	    «IF monitor.contains("count_out_tokens_")»
	    <name>MDC_«monitor.replace("count_out_", "").toUpperCase()»</name>
	    <desc>Number of output tokens from the accelerator at port «monitor.replace("count_out_tokens_", "")»</desc>
	    «ENDIF»
	  </event>
	  «ENDFOR»
	</mdcInfo>
	'''
	}
	
	override getPortIdFromName(String name){
		for(Port port : portMap.keySet) {
			if(port.getName.equals(name)) {
				return portMap.get(port);
			}
		}
		
	}
	
	override getSuffix(Map<String,String> idNameMap, String id) {
		if(idNameMap.containsKey(id)) {
			if(idNameMap.get(id).equals("")) {
				return ""
			} else {
				return "_" + idNameMap.get(id)
			}
		}
		return null
	}
	
	override getMatchingWrapMapping(String channel){
		for(commSigId : wrapCommSignals.keySet) {
			if(wrapCommSignals.get(commSigId).containsKey(ProtocolManager.CH)) {
				if(channel.equals(wrapCommSignals.get(commSigId).get(ProtocolManager.CH))) {
					return wrapCommSignals.get(commSigId).get(ProtocolManager.MAP)
				}
			}
		}
		return null
	}
		
	override getOutLastModCommSignals(){
		var Map<String,String> result = new HashMap<String,String>();
		for(commSigId : getLastModCommSignals().keySet) {
			if( (getLastModCommSignals().get(commSigId).get(ProtocolManager.KIND).equals("output") 
					&& getLastModCommSignals().get(commSigId).get(ProtocolManager.DIR).equals("direct") )
					|| (getLastModCommSignals().get(commSigId).get(ProtocolManager.KIND).equals("input")
					&& getLastModCommSignals().get(commSigId).get(ProtocolManager.DIR).equals("reverse") ) ) {
				result.put(commSigId,getLastModCommSignals().get(commSigId).get(ProtocolManager.CH));	
			}
		}
		return result
	}
	
	override getLastModCommSignals(){
		if(modCommSignals.containsKey(ProtocolManager.SUCC)) {
			return modCommSignals.get(ProtocolManager.SUCC)
		} else {
			return modCommSignals.get(ProtocolManager.ACTOR)
		}
	}
	
	override getInFirstModCommSignals(){
		var Map<String,String> result = new HashMap<String,String>();
		for(commSigId : getFirstModCommSignals().keySet) {
			if( (getFirstModCommSignals().get(commSigId).get(ProtocolManager.KIND).equals("input") 
					&& getFirstModCommSignals().get(commSigId).get(ProtocolManager.DIR).equals("direct") )
					|| (getFirstModCommSignals().get(commSigId).get(ProtocolManager.KIND).equals("output")
					&& getFirstModCommSignals().get(commSigId).get(ProtocolManager.DIR).equals("reverse") ) ) {
				result.put(commSigId,getFirstModCommSignals().get(commSigId).get(ProtocolManager.CH));		
			}
		}
		return result
	}
	
	override getFirstModCommSignals(){
		if(modCommSignals.containsKey(ProtocolManager.PRED)) {
			return modCommSignals.get(ProtocolManager.PRED)
		} else {
			return modCommSignals.get(ProtocolManager.ACTOR)
		}
	}
	
	override getClockSysSignals(){
		var List<String> result = new ArrayList<String>();
		for(String sysSigId : netSysSignals.keySet) {
			if(netSysSignals.get(sysSigId).containsKey(ProtocolManager.CLOCK)) {
				result.add(netSysSignals.get(sysSigId).get(ProtocolManager.NETP))
			}
		}
		return result
	}
	
	override getResetSysSignals(){
		var Map<String,String> result = new HashMap<String,String>();
		for(String sysSigId : netSysSignals.keySet) {
			if(netSysSignals.get(sysSigId).containsKey(ProtocolManager.RST)) {
				result.put(netSysSignals.get(sysSigId).get(ProtocolManager.NETP),"HIGH")
			} else if(netSysSignals.get(sysSigId).containsKey(ProtocolManager.RSTN)) {
				result.put(netSysSignals.get(sysSigId).get(ProtocolManager.NETP),"LOW")
			}
		}
		return result
	}
	

}