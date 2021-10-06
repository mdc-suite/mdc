/*
 *
 */
 
package it.mdc.tool.prototyping

import java.text.SimpleDateFormat
import java.util.Date
import net.sf.orcc.df.Network
import java.util.ArrayList
import java.util.Map
import java.util.HashMap
import net.sf.orcc.df.Port
import java.util.List
import it.mdc.tool.core.platformComposer.ProtocolManager
import it.mdc.tool.core.sboxManagement.SboxLut
import java.io.File
import java.util.LinkedHashMap

/**
 * Pulp HWPE Wrapper Printer 
 * 
 * @author Tiziana Fanni
 * @author Carlo Sau
 */
class PulpPrinter {

	Map <Port,Integer> inputMap;
	Map <Port,Integer> outputMap;
	Map <Port,Integer> portMap;
	List <Integer> signals;
	List <SboxLut> luts;
	int portSize;
	Map<String,List<Port>> netPorts;
	
	String coupling = ""
	boolean enableMonitoring;
	
	Map<String,Map<String,String>> netSysSignals;
	Map<String,Map<String,Map<String,String>>> modCommSignals;
	Map<String,Map<String,String>> wrapCommSignals;
	List<String> monList;
	
	Network network;
	
	def computeNetsPorts(Map<String,Map<String,String>> networkVertexMap) {
		
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
	
	def computeSizePointer() {
		if(coupling.equals("mm")) {
			if(enableMonitoring)
				return Math.round((((Math.log10(portMap.size + monList.size() )/Math.log10(2))+0.5) as float))
			else
				return Math.round((((Math.log10(portMap.size)/Math.log10(2))+0.5) as float))
		} else {
			return Math.round((((Math.log10(outputMap.size)/Math.log10(2))+0.5) as float))
		}
	}
	
	def getLongId(int id) {
		if(id<10) {
			return "0"+id.toString();
		} else {
			return id.toString();	
		}
	}
		
	def mapInOut(Network network) {
		
		var index=0;
		var size=0;
		
		inputMap = new LinkedHashMap<Port,Integer>();
		outputMap = new LinkedHashMap<Port,Integer>();
		portMap = new LinkedHashMap<Port,Integer>();
		
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
		
	def mapSignals() {
		
		var size = Math.max(inputMap.size,outputMap.size);
		var index = 1;
		signals = new ArrayList(size);
		
		while(index<=size) {
			signals.add(index-1,index)
			index = index + 1;
		}
				
	}
	
	def getPortMap(){
		return portMap;
	}
	
	def getInputMap(){
		return inputMap;
	}
		
	def getOutputMap(){
		return outputMap;
	}
		
	def initPulpPrinter(
						List<SboxLut> luts,
						Map<String,Map<String,String>> netSysSignals, 
						Map<String,Map<String,Map<String,String>>> modCommSignals,
						Map<String,Map<String,String>> wrapCommSignals,
						Network network
	) {
		this.coupling = coupling;
		this.enableMonitoring = enableMonitoring;
		this.monList = monList;
		this.luts = luts;
		this.netSysSignals = netSysSignals;
		this.modCommSignals = modCommSignals;
		this.wrapCommSignals = wrapCommSignals;
		this.network = network;
	}
	
	def hasParameter(String portValue) {
		var boolean result = false;
		
		if(portValue.split("_").size > 3) {
			result = true;
		}
		
		return result;
	}
	
	def getDefaultValue(String portValue) {
		var int defaultValue;
				
		if(hasParameter(portValue)) {
			defaultValue = Integer.parseInt(portValue.split("_").get(portValue.split("_").size-1));
		} else {
			defaultValue = Integer.parseInt(portValue.split("_").get(2));
		}
		
		return defaultValue;
	}
	
	def getParameter(String portValue) {
		var String parameter = ""; 
		var int i = 2;
		
		if(portValue.split("_").size==4) {
			parameter = portValue.split("_").get(2);
		} else {
			while(i<portValue.split("_").size-1) {
				if(parameter.equals("")) {
					parameter = parameter + portValue.split("_").get(i);
				} else {
					parameter = parameter + "_" + portValue.split("_").get(i);
				}
				i=i+1;	
			}
		}
		
		return parameter;
	}
	
	def getDirection(String portValue) {
		var String direction = portValue;
		if(portValue.contains("_")) {
			direction = portValue.split("_").get(0);
		}
		return direction;
	}
	
	def getReverseDirection(String portValue) {
		var String direction = getDirection(portValue);
		if(direction.equals("in")) {
			direction = "out";
		} else {
			direction = "in";
		}
		return direction;
	}
	
	def printHWPELicense(Boolean printHWPEName, String modulePrinted){
		'''		
		
		/*
		«IF printHWPEName»
		 * HWPE: Francesco Conti <fconti@iis.ee.ethz.ch>
		«ENDIF»
		 *
		 * Copyright (C) 2018 ETH Zurich, University of Bologna
		 * Copyright and related rights are licensed under the Solderpad Hardware
		 * License, Version 0.51 (the "License"); you may not use this file except in
		 * compliance with the License.  You may obtain a copy of the License at
		 * http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
		 * or agreed to in writing, software, hardware and materials distributed under
		 * this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
		 * CONDITIONS OF ANY KIND, either express or implied. See the License for the
		 * specific language governing permissions and limitations under the License.
		 *
		 * Authors:     Francesco Conti <fconti@iis.ee.ethz.ch>
		 * Contribute:  Gianluca Bellocchi <gianluca.bellocchi@unimore.it>
		 *
		 * Module: multi_dataflow_«modulePrinted».sv
		 *
		 */
		'''
		
	}
	
	def printTop(Network network) {
		
		mapInOut(network);
		mapSignals();
		
		'''	
		«printTopHeaderComments()»
		import multi_dataflow_package::*;
		import hwpe_ctrl_package::*;
		
		// ----------------------------------------------------------------------------
		// Module Interface
		// ----------------------------------------------------------------------------
		«printTopInterface()»
		
		// ----------------------------------------------------------------------------
		// Module Signals
		// ----------------------------------------------------------------------------
		«printTopSignals()»
		
		«IF enableMonitoring»
		//monitoring
		
		«FOR String monitor: monList»
			// Monitor «monList.indexOf(monitor)»: «monitor»
			wire clear_monitor_«monList.indexOf(monitor)»;
			reg [31 : 0]  «monitor»;
		«ENDFOR»
		
		«IF monList.contains("count_clock_cycles")»
			reg en_clock_count;
			reg state, next_state;  
		«ENDIF»
		«ENDIF»		
		
		// ----------------------------------------------------------------------------
		// Body
		// ----------------------------------------------------------------------------
		«printTopBody()»
		
		endmodule
		// ----------------------------------------------------------------------------
		// ----------------------------------------------------------------------------
		// ----------------------------------------------------------------------------
		'''
		
	}
	
	def printTopHeaderComments(){
				
		var dateFormat = new SimpleDateFormat("yyyy/MM/dd HH:mm:ss");
		var date = new Date();
		'''
		// ----------------------------------------------------------------------------
		//
		// This file has been automatically generated by:
		// Multi-Dataflow Composer tool - Platform Composer
		// Template Interface Layer module - Memory-Mapped type
		// on «dateFormat.format(date)»
		// More info available at http://sites.unica.it/rpct/
		//
		// ----------------------------------------------------------------------------
		'''	
		
	}
	
	def getSizePrefix(String size) {
		if(size.equals("1")) {
			return ""
		} else {
			return "[" + (Integer.parseInt(size) - 1) + " : 0] "
		}
	}
	
	def getPortCommSigSize(Port port, String commSigId, Map<String,Map<String,String>> commSigIdMap) {
			if(commSigIdMap.containsKey(commSigId)){
			if(commSigIdMap.get(commSigId).get(ProtocolManager.SIZE).equals("variable")) {
				return port.type.sizeInBits.toString
			} else {
				return commSigIdMap.get(commSigId).get(ProtocolManager.SIZE)	
			}
		}
		return null
	}

	def printTopSignals() {
		
		'''		
		// Communication signals
		«FOR input : inputMap.keySet()»
		«FOR commSigId : getInFirstModCommSignals().keySet»
		wire «getSizePrefix(getPortCommSigSize(input,commSigId,getFirstModCommSignals()))»«input.getName()»_«getMatchingWrapMapping(getFirstModCommSignals().get(commSigId).get(ProtocolManager.CH))»;
		«ENDFOR»
		wire [31:0] stream_if_«input.name»_data;
		wire stream_if_«input.name»_valid;
		wire stream_if_«input.name»_ready;
		«ENDFOR»
		«FOR output : outputMap.keySet()»
		«FOR commSigId : getOutLastModCommSignals().keySet»
		wire «getSizePrefix(getPortCommSigSize(output,commSigId,getLastModCommSignals()))»«output.getName()»_«getMatchingWrapMapping(getLastModCommSignals().get(commSigId).get(ProtocolManager.CH))»;
		«ENDFOR»
		wire [31:0] stream_if_«output.name»_data;
		wire stream_if_«output.name»_valid;
		wire stream_if_«output.name»_ready;
		«ENDFOR»
		'''
		
	}
	
	def printTopInterface() {

		'''
			module multi_dataflow_reconf_datapath_top 
			(
				// Sink ports
				«FOR port : inputMap.keySet»  
				  hwpe_stream_intf_stream.sink    «port.name»,
				«ENDFOR»  
				// Source ports
				«FOR port : outputMap.keySet»  
				  hwpe_stream_intf_stream.source  «port.name»,
				«ENDFOR»  	
				// Algorithm parameters
				«FOR param : network.parameters» 
				  logic unsigned [(32-1):0] 		«param.name»,
				«ENDFOR»  
				«IF !(this.luts.empty)»// Multi-Dataflow Kernel ID
				  input logic [7:0]					ID,
				«ENDIF»
				// Global signals
				input  logic                      clk_i,
				input  logic                      rst_ni
			);
			
		'''
	}
			
	def printTopBody() {
		//TODO check zero and last for size=0 with stream accelerator
		
		'''		
		// hwpe strem interface wrappers
		«FOR input : inputMap.keySet»// hwpe stream intf in «input.name»
		interface_wrapper_in i_interface_wrapper_in_«input.name»(
			.in_data(stream_if_«input.name»_data),
			.in_valid(stream_if_«input.name»_valid),
			.in_ready(stream_if_«input.name»_ready),
			.in(«input.name»)
		);
		«ENDFOR»
		«FOR output : outputMap.keySet»// hwpe stream intf out «output.name»
		interface_wrapper_out i_interface_wrapper_out_«output.name»(
			.out_data(stream_if_«output.name»_data),
			.out_valid(stream_if_«output.name»_valid),
			.out_ready(stream_if_«output.name»_ready),
			.out(«output.name»)
		);
		«ENDFOR»
		
		// Multi-Dataflow Reconfigurable Datapath
		// ----------------------------------------------------------------------------
		«printTopDatapath()»
		«FOR input :inputMap.keySet»
		assign stream_if_«input.name»_ready = «IF !isNegMatchingWrapMapping(getFullChannelWrapCommSignalID())»«ENDIF»~«input.getName()»_full;
		assign «input.getName()»_data = stream_if_«input.name»_data«IF getDataSize(input)<32» [«getDataSize(input)-1» : 0]«ENDIF»;
		assign «input.getName()»_push = stream_if_«input.name»_valid;
		«ENDFOR»
		«FOR output : outputMap.keySet()»
		assign stream_if_«output.name»_valid = «output.getName()»_push;
		assign stream_if_«output.name»_data = «IF getDataSize(output)<32»{{«32-getDataSize(output)»{1'b0}},«ENDIF»«output.getName()»_data«IF getDataSize(output)<32»}«ENDIF»;
		assign «output.getName()»_full = ~«IF !isNegMatchingWrapMapping(getFullChannelWrapCommSignalID())»«ENDIF»stream_if_«output.name»_ready;
		«ENDFOR»
		'''
	}
	
	def getFullChannelWrapCommSignalID() {
		for(commSigId : wrapCommSignals.keySet) {
			if(wrapCommSignals.get(commSigId).get(ProtocolManager.MAP).equals("full")) {
				return wrapCommSignals.get(commSigId).get(ProtocolManager.CH);
			}		
		}
	}
	
	def getPortIdFromName(String name){
		for(Port port : portMap.keySet) {
			if(port.getName.equals(name)) {
				return portMap.get(port);
			}
		}
		
	}
	
	def getDataSize(Port port) {
		for(commSigId : wrapCommSignals.keySet) {
			if(wrapCommSignals.get(commSigId).get(ProtocolManager.MAP).equals("data")) {
				if(wrapCommSignals.get(commSigId).get(ProtocolManager.SIZE).equals("variable")) {
					return port.type.sizeInBits
				} else {
					return Integer.parseInt(wrapCommSignals.get(commSigId).get(ProtocolManager.SIZE))
				}
			}
		}
		return 1
	}
	
	def printTopDatapath() {
		'''
			// to adapt profiling
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
				// Algorithm parameters
				   «FOR param : network.parameters» 
				   	.«param.name»        (  «param.name»      ),
				   «ENDFOR»  
				«FOR clockSignal : getClockSysSignals()»
					.«clockSignal»(clk_i)«IF !(getResetSysSignals().empty && this.luts.empty)»,«ENDIF»
				«ENDFOR»
				«FOR resetSignal : getResetSysSignals().keySet»
					.«resetSignal»(«IF getResetSysSignals().get(resetSignal).equals("HIGH")»!«ENDIF»rst_ni)«IF !(this.luts.empty)»,«ENDIF»
				«ENDFOR»
			«IF !(this.luts.empty)»// Multi-Dataflow Kernel ID
				.ID(ID)«ENDIF»
			);
		'''
	}
	
	def getSuffix(Map<String,String> idNameMap, String id) {
		if(idNameMap.containsKey(id)) {
			if(idNameMap.get(id).equals("")) {
				return ""
			} else {
				return "_" + idNameMap.get(id)
			}
		}
		return null
	}
	
	def getMatchingWrapMapping(String channel){
		for(commSigId : wrapCommSignals.keySet) {
			if(wrapCommSignals.get(commSigId).containsKey(ProtocolManager.CH)) {
				if(channel.equals(wrapCommSignals.get(commSigId).get(ProtocolManager.CH))) {
					return wrapCommSignals.get(commSigId).get(ProtocolManager.MAP)
				}
			}
		}
		return null
	}
	
	def isNegMatchingWrapMapping(String channel){
		for(commSigId : wrapCommSignals.keySet) {
			if(wrapCommSignals.get(commSigId).containsKey(ProtocolManager.CH)) {
				if(channel.equals(wrapCommSignals.get(commSigId).get(ProtocolManager.CH))) {
					return wrapCommSignals.get(commSigId).containsKey(ProtocolManager.INV)
				}
			}
		}
		return null
	}
		
	def getOutLastModCommSignals(){
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
	
	def getLastModCommSignals(){
		if(modCommSignals.containsKey(ProtocolManager.SUCC)) {
			return modCommSignals.get(ProtocolManager.SUCC)
		} else {
			return modCommSignals.get(ProtocolManager.ACTOR)
		}
	}
	
	def getInFirstModCommSignals(){
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
	
	def getFirstModCommSignals(){
		if(modCommSignals.containsKey(ProtocolManager.PRED)) {
			return modCommSignals.get(ProtocolManager.PRED)
		} else {
			return modCommSignals.get(ProtocolManager.ACTOR)
		}
	}
	
	def getClockSysSignals(){
		var List<String> result = new ArrayList<String>();
		for(String sysSigId : netSysSignals.keySet) {
			if(netSysSignals.get(sysSigId).containsKey(ProtocolManager.CLOCK)) {
				result.add(netSysSignals.get(sysSigId).get(ProtocolManager.NETP))
			}
		}
		return result
	}
	
	def getResetSysSignals(){
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
	
	def printCtrl() {

		'''
			«printHWPELicense(true, "ctrl")»
			 
			import multi_dataflow_package::*;
			import hwpe_ctrl_package::*;
			module multi_dataflow_ctrl
			#(
			  parameter int unsigned N_CORES         = 2,
			  parameter int unsigned N_CONTEXT       = 2,
			  parameter int unsigned N_IO_REGS       = 16,
			  parameter int unsigned ID              = 10,
			  parameter int unsigned UCODE_HARDWIRED = 0
			)
			(  // Global signals
			  input  logic                                  clk_i,
			  input  logic                                  rst_ni,
			  input  logic                                  test_mode_i,
			  output logic                                  clear_o,
			  // events
			  output logic [N_CORES-1:0][REGFILE_N_EVT-1:0] evt_o,
			  // ctrl & flags
			  output ctrl_streamer_t                        ctrl_streamer_o,
			  input  flags_streamer_t                       flags_streamer_i,
			  output ctrl_engine_t                          ctrl_engine_o,
			  input  flags_engine_t                         flags_engine_i,
			  // periph slave port
			  hwpe_ctrl_intf_periph.slave                   periph
			);
			  /* Ctrl/flag signals */
			  // Slave
			  ctrl_slave_t   slave_ctrl;
			  flags_slave_t  slave_flags;
			  // Register file
			  ctrl_regfile_t reg_file;
			  // Uloop
			  logic [223:0]  ucode_flat;
			  uloop_code_t   ucode;
			  ctrl_uloop_t   ucode_ctrl;
			  flags_uloop_t  ucode_flags;
			  logic [11:0][31:0] ucode_registers_read;
			  /* Standard registers */
			  // Uloop
			  logic unsigned [31:0] static_reg_nb_iter;
			  logic unsigned [31:0] static_reg_vectstride;
			  logic unsigned [31:0] static_reg_onestride;
			  logic unsigned [15:0] static_reg_shift;
			  // FSM
			  logic unsigned [31:0] static_reg_cnt_limit;
			  // Address generator
			  «FOR input : inputMap.keySet»
			  	// Controls - «input.name»
			  	logic unsigned [31:0] static_reg_«input.name»_trans_size;
			  	logic unsigned [31:0] static_reg_«input.name»_line_stride;
			  	logic unsigned [31:0] static_reg_«input.name»_line_length;
			  	logic unsigned [31:0] static_reg_«input.name»_feat_stride;
			  	logic unsigned [31:0] static_reg_«input.name»_feat_length;
			  	logic unsigned [31:0] static_reg_«input.name»_feat_roll;
			  	logic unsigned [31:0] static_reg_«input.name»_loop_outer;
			  	logic unsigned [31:0] static_reg_«input.name»_realign_type;
			  «ENDFOR»
			  «FOR output : outputMap.keySet»
			  	// Controls - «output.name»
			  	logic unsigned [31:0] static_reg_«output.name»_trans_size;
			  	logic unsigned [31:0] static_reg_«output.name»_line_stride;
			  	logic unsigned [31:0] static_reg_«output.name»_line_length;
			  	logic unsigned [31:0] static_reg_«output.name»_feat_stride;
			  	logic unsigned [31:0] static_reg_«output.name»_feat_length;
			  	logic unsigned [31:0] static_reg_«output.name»_feat_roll;
			  	logic unsigned [31:0] static_reg_«output.name»_loop_outer;
			  	logic unsigned [31:0] static_reg_«output.name»_realign_type;
			  «ENDFOR»
			  // Custom register files
				«FOR netParm : this.network.parameters»
					logic unsigned [(32-1):0] static_reg_«netParm.name»;
				«ENDFOR»
			«IF !luts.empty»
				logic unsigned [(32-1):0] static_reg_config;
			«ENDIF»
			  /* FSM input signals */
			  ctrl_fsm_t fsm_ctrl;
			  /* Peripheral slave & register file */
			  hwpe_ctrl_slave #(
			  .N_CORES        ( N_CORES               ),
			  .N_CONTEXT      ( N_CONTEXT             ),
			  .N_IO_REGS      ( N_IO_REGS             ),
			  .N_GENERIC_REGS ( (1-UCODE_HARDWIRED)*8 ),
			  .ID_WIDTH       ( ID                    )
			  ) i_slave (
			    .clk_i    ( clk_i       ),
			    .rst_ni   ( rst_ni      ),
			    .clear_o  ( clear_o     ),
			    .cfg      ( periph      ),
			    .ctrl_i   ( slave_ctrl  ),
			    .flags_o  ( slave_flags ),
			    .reg_file ( reg_file    )
			  );
			  /* Events */
			  assign evt_o = slave_flags.evt;
			  /* Direct register file mappings */
			  // Uloop registers
			  assign static_reg_nb_iter    = reg_file.hwpe_params[REG_NB_ITER]  + 1;
			  assign static_reg_linestride = reg_file.hwpe_params[REG_SHIFT_LINESTRIDE];
			  assign static_reg_tilestride = reg_file.hwpe_params[REG_SHIFT_TILESTRIDE];
			  assign static_reg_onestride  = 4;
			  // Custom registers
			  	«FOR netParm : this.network.parameters»
			  	assign static_reg_«netParm.name» = reg_file.hwpe_params[REG_«netParm.name.toUpperCase»];
			  	«ENDFOR»
				«IF !luts.empty»
					assign static_reg_config = reg_file.hwpe_params[CONFIG];
				«ENDIF»
			  // FSM signals
			  assign static_reg_cnt_limit = reg_file.hwpe_params[MMUL_OPT_MDC_REG_CNT_LIMIT] + 1;
			  // Address generator
			  «FOR input : inputMap.keySet»
			    // Mapping - «input.name»
			    assign static_«input.name»_trans_size          = reg_file.hwpe_params[REG_«input.name»_TRANS_SIZE];
			    assign static_«input.name»_line_stride         = reg_file.hwpe_params[REG_«input.name»_LINE_STRIDE];
			    assign static_«input.name»_line_length         = reg_file.hwpe_params[REG_«input.name»_LINE_LENGTH];
			    assign static_«input.name»_feat_stride         = reg_file.hwpe_params[REG_«input.name»_FEAT_STRIDE];
			    assign static_«input.name»_feat_length         = reg_file.hwpe_params[REG_«input.name»_FEAT_LENGTH];
			    assign static_«input.name»_feat_roll           = reg_file.hwpe_params[REG_«input.name»_FEAT_ROLL];
			    assign static_«input.name»_loop_outer          = reg_file.hwpe_params[REG_«input.name»_LOOP_OUTER];
			    assign static_«input.name»_realign_type        = reg_file.hwpe_params[REG_«input.name»_REALIGN_TYPE];
			  «ENDFOR»
			  «FOR output : outputMap.keySet»
			  	// Mapping - «output.name»
			  	assign static_«output.name»_trans_size         = reg_file.hwpe_params[REG_«output.name»_TRANS_SIZE];
			  	assign static_«output.name»_line_stride        = reg_file.hwpe_params[REG_«output.name»_LINE_STRIDE];
			  	assign static_«output.name»_line_length        = reg_file.hwpe_params[REG_«output.name»_LINE_LENGTH];
			  	assign static_«output.name»_feat_stride        = reg_file.hwpe_params[REG_«output.name»_FEAT_STRIDE];
			  	assign static_«output.name»_feat_length        = reg_file.hwpe_params[REG_«output.name»_FEAT_LENGTH];
			  	assign static_«output.name»_feat_roll          = reg_file.hwpe_params[REG_«output.name»_FEAT_ROLL];
			  	assign static_«output.name»_loop_outer         = reg_file.hwpe_params[REG_«output.name»_LOOP_OUTER];
			  	assign static_«output.name»_realign_type       = reg_file.hwpe_params[REG_«output.name»_REALIGN_TYPE];
			  «ENDFOR»
			  /* Microcode processor */
			  generate
			    if(UCODE_HARDWIRED != 0) begin
			      // equivalent to the microcode in ucode/code.yml
			      assign ucode_flat = 224'h0000000000040000000000000000000000000000000008cd11a12c05;
			    end
			    else begin
			      // the microcode is stored in registers independent of context (job)
			      assign ucode_flat = reg_file.generic_params[6:0];
			    end
			  endgenerate
			  assign ucode = {
			    // loops & bytecode
			    ucode_flat,
			    // ranges
			    12'b0,
			    12'b0,
			    12'b0,
			    12'b0,
			    12'b0,
			    static_reg_nb_iter[11:0]
			  };
			  assign ucode_registers_read[UCODE_MNEM_NBITER]     = static_reg_nb_iter;
			  assign ucode_registers_read[UCODE_MNEM_ITERSTRIDE] = static_reg_linestride;
			  assign ucode_registers_read[UCODE_MNEM_ONESTRIDE]  = static_reg_onestride;
			  assign ucode_registers_read[UCODE_MNEM_TILESTRIDE] = static_reg_tilestride;
			  assign ucode_registers_read[11:4] = '0;
			  hwpe_ctrl_uloop #(
			    .NB_LOOPS       ( 1  ), // Default: 1
			    .NB_REG         ( 4  ),
			    .NB_RO_REG      ( 12 ),
			    .DEBUG_DISPLAY  ( 0  )  // Default: 0
			  ) i_uloop (
			    .clk_i            ( clk_i                ),
			    .rst_ni           ( rst_ni               ),
			    .test_mode_i      ( test_mode_i          ),
			    .clear_i          ( clear_o              ),
			    .ctrl_i           ( ucode_ctrl           ),
			    .flags_o          ( ucode_flags          ),
			    .uloop_code_i     ( ucode                ),
			    .registers_read_i ( ucode_registers_read )
			  );
			  /* Main FSM */
			  multi_dataflow_fsm i_fsm (
			    .clk_i            ( clk_i              ),
			    .rst_ni           ( rst_ni             ),
			    .test_mode_i      ( test_mode_i        ),
			    .clear_i          ( clear_o            ),
			    .ctrl_streamer_o  ( ctrl_streamer_o    ),
			    .flags_streamer_i ( flags_streamer_i   ),
			    .ctrl_engine_o    ( ctrl_engine_o      ),
			    .flags_engine_i   ( flags_engine_i     ),
			    .ctrl_ucode_o     ( ucode_ctrl         ),
			    .flags_ucode_i    ( ucode_flags        ),
			    .ctrl_slave_o     ( slave_ctrl         ),
			    .flags_slave_i    ( slave_flags        ),
			    .reg_file_i       ( reg_file           ),
			    .ctrl_i           ( fsm_ctrl           )
			  );
			  always_comb
			  begin
			    /* Custom register file mappings to FSM */
			    fsm_ctrl.cnt_limit        = static_reg_cnt_limit;
			    // Custom register file mappings to fsm
			    «FOR netParm : this.network.parameters»
			      fsm_ctrl.«netParm.name»	= static_reg_«netParm.name»;
			    «ENDFOR»
			    «IF !luts.empty»
			      fsm_ctrl.configuration    = static_reg_config;
			    «ENDIF»
			    // Address generator
			    «FOR input : inputMap.keySet»
			      // Mapping - «input.name»
			      fsm_ctrl.«input.name»_trans_size     = static_«input.name»_trans_size;
			      fsm_ctrl.«input.name»_line_stride    = static_«input.name»_line_stride;
			      fsm_ctrl.«input.name»_line_length    = static_«input.name»_line_length;
			      fsm_ctrl.«input.name»_feat_stride    = static_«input.name»_feat_stride;
			      fsm_ctrl.«input.name»_feat_length    = static_«input.name»_feat_length;			      fsm_ctrl.«input.name»_feat_roll      = static_«input.name»_feat_roll;
			      fsm_ctrl.«input.name»_loop_outer     = static_«input.name»_loop_outer;
			      fsm_ctrl.«input.name»_realign_type   = static_«input.name»_realign_type;
			    «ENDFOR»
			    «FOR output : outputMap.keySet»
			      // Mapping - «output.name»
			      fsm_ctrl.«output.name»_trans_size     = static_«output.name»_trans_size;
			      fsm_ctrl.«output.name»_line_stride    = static_«output.name»_line_stride;
			      fsm_ctrl.«output.name»_line_length    = static_«output.name»_line_length;
			      fsm_ctrl.«output.name»_feat_stride    = static_«output.name»_feat_stride;
			      fsm_ctrl.«output.name»_feat_length    = static_«output.name»_feat_length;
			      fsm_ctrl.«output.name»_feat_roll      = static_«output.name»_feat_roll;
			      fsm_ctrl.«output.name»_loop_outer     = static_«output.name»_loop_outer;
			      fsm_ctrl.«output.name»_realign_type   = static_«output.name»_realign_type;
			    «ENDFOR»
			  end
			endmodule
			'''
	}
	
	def printFSM() {

		'''
			«printHWPELicense(true, "fsm")»
			import multi_dataflow_package::*;
			import hwpe_ctrl_package::*;
			module multi_dataflow_fsm (
			  // Global signals
			  input  logic                                  clk_i,
			  input  logic                                  rst_ni,
			  input  logic                                  test_mode_i,
			  output logic                                  clear_i,
			  // ctrl & flags
			  output ctrl_streamer_t                        ctrl_streamer_o,
			  input  flags_streamer_t                       flags_streamer_i,
			  output ctrl_engine_t                          ctrl_engine_o,
			  input  flags_engine_t                         flags_engine_i,
			  output ctrl_uloop_t                           ctrl_ucode_o,
			  input  flags_uloop_t                          flags_ucode_i,
			  output ctrl_slave_t                           ctrl_slave_o,
			  input  flags_slave_t                          flags_slave_i,
			  input  ctrl_regfile_t                         reg_file_i,
			  input  ctrl_fsm_t                             ctrl_i
			);
			  // State signals
			  state_fsm_t curr_state, next_state;
			  // State computation
			  always_ff @(posedge clk_i or negedge rst_ni)
			  begin : main_fsm_seq
			    if(~rst_ni) begin
			      curr_state <= FSM_IDLE;
			    end
			    else if(clear_i) begin
			      curr_state <= FSM_IDLE;
			    end
			    else begin
			      curr_state <= next_state;
			    end
			  end
			  // State declaration
			  always_comb
			  begin : main_fsm_comb
			    /* Initialize */
			    // Address generator
			    «FOR input : inputMap.keySet»
			    	// Input stream - «input.name» (programmable)
			    	ctrl_streamer_o.«input.name»_source_ctrl.addressgen_ctrl.trans_size   = ctrl_i.«input.name»_trans_size;
			    	ctrl_streamer_o.«input.name»_source_ctrl.addressgen_ctrl.line_stride  = ctrl_i.«input.name»_line_stride;
			    	ctrl_streamer_o.«input.name»_source_ctrl.addressgen_ctrl.line_length  = ctrl_i.«input.name»_line_length;
			    	ctrl_streamer_o.«input.name»_source_ctrl.addressgen_ctrl.feat_stride  = ctrl_i.«input.name»_feat_stride;
			    	ctrl_streamer_o.«input.name»_source_ctrl.addressgen_ctrl.feat_length  = ctrl_i.«input.name»_feat_length;
			    	ctrl_streamer_o.«input.name»_source_ctrl.addressgen_ctrl.base_addr    = reg_file_i.hwpe_params[REG_«input.name»_ADDR] + (flags_ucode_i.offs[UCODE_«input.name»_OFFS]);
			    	ctrl_streamer_o.«input.name»_source_ctrl.addressgen_ctrl.feat_roll    = ctrl_i.«input.name»_feat_roll;
			    	ctrl_streamer_o.«input.name»_source_ctrl.addressgen_ctrl.loop_outer   = ctrl_i.«input.name»_loop_outer;
			    	ctrl_streamer_o.«input.name»_source_ctrl.addressgen_ctrl.realign_type = ctrl_i.«input.name»_realign_type;
			    «ENDFOR»
			    «FOR output : outputMap.keySet»
			    	// Output stream - «output.name» (programmable)
			    	ctrl_streamer_o.«output.name»_sink_ctrl.addressgen_ctrl.trans_size   = ctrl_i.«output.name»_trans_size;
			    	ctrl_streamer_o.«output.name»_sink_ctrl.addressgen_ctrl.line_stride  = ctrl_i.«output.name»_line_stride;
			    	ctrl_streamer_o.«output.name»_sink_ctrl.addressgen_ctrl.line_length  = ctrl_i.«output.name»_line_length;
			    	ctrl_streamer_o.«output.name»_sink_ctrl.addressgen_ctrl.feat_stride  = ctrl_i.«output.name»_feat_stride;
			    	ctrl_streamer_o.«output.name»_sink_ctrl.addressgen_ctrl.feat_length  = ctrl_i.«output.name»_feat_length;
			    	ctrl_streamer_o.«output.name»_sink_ctrl.addressgen_ctrl.base_addr    = reg_file_i.hwpe_params[REG_«output.name»_ADDR] + (flags_ucode_i.offs[UCODE_«output.name»_OFFS]);
			    	ctrl_streamer_o.«output.name»_sink_ctrl.addressgen_ctrl.feat_roll    = ctrl_i.«output.name»_feat_roll;
			    	ctrl_streamer_o.«output.name»_sink_ctrl.addressgen_ctrl.loop_outer   = ctrl_i.«output.name»_loop_outer;
			    	ctrl_streamer_o.«output.name»_sink_ctrl.addressgen_ctrl.realign_type = ctrl_i.«output.name»_realign_type;
			    «ENDFOR»
			    // Streamer
			    «FOR input : inputMap.keySet»
			    	ctrl_streamer_o.«input.name»_source_ctrl.req_start    = '0;
			    «ENDFOR»
			    «FOR output : outputMap.keySet»
			    	ctrl_streamer_o.«output.name»_sink_ctrl.req_start    = '0;
			    «ENDFOR»			        
			    // Engine
			    ctrl_engine_o.clear      = '1;                    // Clear counters
			    ctrl_engine_o.start      = '0;                    // Trigger execution
			    ctrl_engine_o.cnt_limit  = ctrl_i.cnt_limit;      // Length of line -> take a look at innermost loop of the address generator
			    «FOR netParm : this.network.parameters»
			    	ctrl_engine_o.«netParm.name»    = ctrl_i.«netParm.name»;
			    «ENDFOR»
			    «IF !luts.empty»
			    	ctrl_engine_o.configuration    = ctrl_i.configuration;		
			    «ENDIF»
			    // Slave
			    ctrl_slave_o.done = '0;
			    ctrl_slave_o.evt  = '0;
			    // Real finite-state machine
			    next_state   = curr_state;
			    ctrl_ucode_o.enable                        = '0;
			    ctrl_ucode_o.clear                         = '0;
			    /* States */
				case(curr_state)
				  FSM_IDLE: begin
				    // Wait for a start signal
				    ctrl_ucode_o.clear = '1;
				    if(flags_slave_i.start) begin
				      next_state = FSM_START;
				    end
				  end
				  FSM_START: begin
				    // Update the indeces, then load the first feature
				    if(
				      	«FOR input : inputMap.keySet»
				      		flags_streamer_i.«input.name»_source_flags.ready_start &
				      	«ENDFOR»
				      	«FOR output : outputMap.keySet SEPARATOR " & "»
				      		flags_streamer_i.«output.name»_sink_flags.ready_start
				    «ENDFOR»)  begin
				     next_state  = FSM_COMPUTE;
				     ctrl_engine_o.start  = 1'b1;
				     ctrl_engine_o.clear  = 1'b0;
				     // Request data streaming from/to TCDM
				     «FOR input : inputMap.keySet»
				     	ctrl_streamer_o.«input.name»_source_ctrl.req_start = 1'b1;
				     «ENDFOR»
				     «FOR output : outputMap.keySet»
				     	ctrl_streamer_o.«output.name»_sink_ctrl.req_start = 1'b1;
				     «ENDFOR»
				    end
				    else begin
				      next_state = FSM_WAIT;
				    end
				  end
				  FSM_COMPUTE: begin
				    ctrl_engine_o.clear  = 1'b0;
				    if (flags_engine_i.cnt == ctrl_i.cnt_limit)
				      next_state = FSM_TERMINATE;
				    if(flags_engine_i.ready) begin
				      ctrl_engine_o.start  = 1'b1;
				      ctrl_engine_o.clear  = 1'b0;
				    end
				  end
				  FSM_UPDATEIDX: begin
				    // update the indeces, then go back to load or idle
				    if(flags_ucode_i.valid == 1'b0) begin
				      ctrl_ucode_o.enable = 1'b1;
				    end
				    else if(flags_ucode_i.done) begin
				      next_state = FSM_TERMINATE;
				    end
				    else if(
				      «FOR input : inputMap.keySet»
				          		flags_streamer_i.«input.name»_source_flags.ready_start &
				      «ENDFOR»
				      «FOR output : outputMap.keySet SEPARATOR " & "»
				          		flags_streamer_i.«output.name»_sink_flags.ready_start
				      «ENDFOR»)  begin
				    next_state = FSM_COMPUTE;
				    ctrl_engine_o.start  = 1'b1;
				    ctrl_engine_o.clear  = 1'b0;
				    // Request data streaming from/to TCDM
				    «FOR input : inputMap.keySet»
				    	ctrl_streamer_o.«input.name»_source_ctrl.req_start = 1'b1;
				«ENDFOR»
				«FOR output : outputMap.keySet»
					ctrl_streamer_o.«output.name»_sink_ctrl.req_start = 1'b1;
				«ENDFOR»
				end
				else begin
				  next_state = FSM_WAIT;
				       end
				     end
				     FSM_WAIT: begin
				       // wait for the flags to be ok then go back to load
				       ctrl_engine_o.clear  = 1'b0;
				       ctrl_ucode_o.enable  = 1'b0;
				       if(
				       	«FOR input : inputMap.keySet»
				       		flags_streamer_i.«input.name»_source_flags.ready_start &
				       	«ENDFOR»
				       	«FOR output : outputMap.keySet SEPARATOR " & "»
				       		flags_streamer_i.«output.name»_sink_flags.ready_start
				       	«ENDFOR»)  begin
				       	 next_state = FSM_COMPUTE;
				       	 ctrl_engine_o.start = 1'b1;
				       	 // Request data streaming from/to TCDM
				       	   «FOR input : inputMap.keySet»
				       	   	ctrl_streamer_o.«input.name»_source_ctrl.req_start = 1'b1;
				     «ENDFOR»
				     «FOR output : outputMap.keySet»
				     	ctrl_streamer_o.«output.name»_sink_ctrl.req_start = 1'b1;
				     «ENDFOR»
				     end
				     end
				     FSM_TERMINATE: begin
				       // wait for the flags to be ok then go back to idle
				       ctrl_engine_o.clear  = 1'b0;
				       ctrl_engine_o.enable = 1'b0;
				       if(
				       	«FOR input : inputMap.keySet»
				       		flags_streamer_i.«input.name»_source_flags.ready_start &
				       	«ENDFOR»
				       	«FOR output : outputMap.keySet SEPARATOR " & "»
				       		flags_streamer_i.«output.name»_sink_flags.ready_start
				       	«ENDFOR»)  begin
				       	 next_state = FSM_IDLE;
				       	 ctrl_slave_o.done = 1'b1;
				       end
				     end
				   endcase // curr_state
				 end
			endmodule // multi_dataflow_fsm
		'''
	}
	
	def printBender(String hclPath) {
		'''
			package:
			  name: hwpe-multidataflow-wrapper
			sources:
			  - include_dirs:
			      - rtl/hwpe-stream
			    files:
			      - rtl/hwpe-stream/hwpe_stream_package.sv
			      - rtl/hwpe-stream/hwpe_stream_interfaces.sv
			      - rtl/hwpe-stream/basic/hwpe_stream_assign.sv
			      - rtl/hwpe-stream/basic/hwpe_stream_mux_static.sv
			      - rtl/hwpe-stream/basic/hwpe_stream_demux_static.sv
			      - rtl/hwpe-stream/basic/hwpe_stream_buffer.sv
			      - rtl/hwpe-stream/basic/hwpe_stream_merge.sv
			      - rtl/hwpe-stream/basic/hwpe_stream_fence.sv
			      - rtl/hwpe-stream/basic/hwpe_stream_split.sv
			      - rtl/hwpe-stream/fifo/hwpe_stream_fifo_earlystall_sidech.sv
			      - rtl/hwpe-stream/fifo/hwpe_stream_fifo_earlystall.sv
			      - rtl/hwpe-stream/fifo/hwpe_stream_fifo_scm.sv
			      - rtl/hwpe-stream/fifo/hwpe_stream_fifo_scm_test_wrap.sv
			      - rtl/hwpe-stream/fifo/hwpe_stream_fifo_sidech.sv
			      - rtl/hwpe-stream/fifo/hwpe_stream_fifo.sv
			      - rtl/hwpe-stream/fifo/hwpe_stream_fifo_ctrl.sv
			      - rtl/hwpe-stream/streamer/hwpe_stream_addressgen.sv
			      - rtl/hwpe-stream/streamer/hwpe_stream_addressgen_v2.sv
			      - rtl/hwpe-stream/streamer/hwpe_stream_strbgen.sv
			      - rtl/hwpe-stream/streamer/hwpe_stream_sink.sv
			      - rtl/hwpe-stream/streamer/hwpe_stream_sink_realign.sv
			      - rtl/hwpe-stream/streamer/hwpe_stream_source.sv
			      - rtl/hwpe-stream/streamer/hwpe_stream_source_realign.sv
			      - rtl/hwpe-stream/streamer/hwpe_stream_streamer_queue.sv
			      - rtl/hwpe-stream/tcdm/hwpe_stream_tcdm_fifo_load.sv
			      - rtl/hwpe-stream/tcdm/hwpe_stream_tcdm_fifo_load_sidech.sv
			      - rtl/hwpe-stream/tcdm/hwpe_stream_tcdm_fifo_store.sv
			      - rtl/hwpe-stream/tcdm/hwpe_stream_tcdm_fifo.sv
			      - rtl/hwpe-stream/tcdm/hwpe_stream_tcdm_assign.sv
			      - rtl/hwpe-stream/tcdm/hwpe_stream_tcdm_mux.sv
			      - rtl/hwpe-stream/tcdm/hwpe_stream_tcdm_mux_static.sv
			      - rtl/hwpe-stream/tcdm/hwpe_stream_tcdm_reorder.sv
			      - rtl/hwpe-stream/tcdm/hwpe_stream_tcdm_reorder_static.sv
			  - include_dirs:
			      - rtl/hwpe-ctrl
			    files:
			      - rtl/hwpe-ctrl/hwpe_ctrl_package.sv
			      - rtl/hwpe-ctrl/hwpe_ctrl_interfaces.sv
			      - rtl/hwpe-ctrl/hwpe_ctrl_regfile.sv
			      - rtl/hwpe-ctrl/hwpe_ctrl_regfile_fpga.sv
			      - rtl/hwpe-ctrl/hwpe_ctrl_regfile_fpga_wrap.sv
			      - rtl/hwpe-ctrl/hwpe_ctrl_slave.sv
			      - rtl/hwpe-ctrl/hwpe_ctrl_uloop.sv
			  - include_dirs:
			      - rtl/hwpe-engine
			    files:
			      «FOR file : new File(hclPath).listFiles»
			      - rtl/hwpe-engine/engine_dev/«file.name»
			      «ENDFOR»
			      - rtl/hwpe-engine/engine_dev/multi_dataflow.v
			      - rtl/hwpe-engine/engine_dev/interface_wrapper.sv
			      «IF !luts.empty»
			      - rtl/hwpe-engine/engine_dev/configurator.v
			      - rtl/hwpe-engine/engine_dev/sbox1x2.v
			      - rtl/hwpe-engine/engine_dev/sbox2x1.v
			      «ENDIF»
			      - rtl/hwpe-engine/multi_dataflow_package.sv
			      - rtl/hwpe-engine/multi_dataflow_fsm.sv
			      - rtl/hwpe-engine/multi_dataflow_ctrl.sv
			      - rtl/hwpe-engine/multi_dataflow_streamer.sv
			      - rtl/hwpe-engine/multi_dataflow_reconf_datapath_top.sv
			      - rtl/hwpe-engine/multi_dataflow_kernel_adapter.sv
			      - rtl/hwpe-engine/multi_dataflow_engine.sv
			      - rtl/hwpe-engine/multi_dataflow_top.sv
			  - include_dirs:
			      - rtl/wrap
			    files:
			      - rtl/wrap/multi_dataflow_top_wrapper.sv
		'''
	}
	
	def printPackage() {
		var counterReg = 0;
		'''		
			«printHWPELicense(true, "package")»
			import hwpe_stream_package::*;
			
			package multi_dataflow_package;
			  parameter int unsigned CNT_LEN = 1024; // maximum length of the vectors for a scalar product
			  /* Registers */
			  // Standard registers
			  parameter int unsigned REG_NB_ITER              = «counterReg++»;
			  parameter int unsigned REG_SHIFT_LINESTRIDE     = «counterReg++»;
			  parameter int unsigned REG_SHIFT_TILESTRIDE     = «counterReg++»;
			  parameter int unsigned REG_CNT_LIMIT            = «counterReg++»;
			  // Custom register files
			  «FOR netParm : this.network.parameters»
			  	parameter int unsigned REG_«netParm.name.toUpperCase»             = «counterReg++»;
			  «ENDFOR»
			  «IF !luts.empty»		  
			  	parameter int unsigned CONFIG             = «counterReg++»;
			  «ENDIF»
			  «FOR input : inputMap.keySet»
			  	// Input stream - «input.name» (programmable)
			  	parameter int unsigned REG_«input.name»_TRANS_SIZE       = «counterReg++»;
			  	parameter int unsigned REG_«input.name»_LINE_STRIDE      = «counterReg++»;
			  	parameter int unsigned REG_«input.name»_LINE_LENGTH      = «counterReg++»;
			  	parameter int unsigned REG_«input.name»_FEAT_STRIDE      = «counterReg++»;
			  	parameter int unsigned REG_«input.name»_FEAT_LENGTH      = «counterReg++»;
			  	parameter int unsigned REG_«input.name»_FEAT_ROLL        = «counterReg++»;
			  	parameter int unsigned REG_«input.name»_LOOP_OUTER       = «counterReg++»;
			  	parameter int unsigned REG_«input.name»_REALIGN_TYPE     = «counterReg++»;
			  «ENDFOR»
			  «FOR output : outputMap.keySet»
			  	// Output stream - «output.name» (programmable)
			  	parameter int unsigned REG_«output.name»_TRANS_SIZE       = «counterReg++»;
			  	parameter int unsigned REG_«output.name»_LINE_STRIDE      = «counterReg++»;
			  	parameter int unsigned REG_«output.name»_LINE_LENGTH      = «counterReg++»;
			  	parameter int unsigned REG_«output.name»_FEAT_STRIDE      = «counterReg++»;
			  	parameter int unsigned REG_«output.name»_FEAT_LENGTH      = «counterReg++»;
			  	parameter int unsigned REG_«output.name»_FEAT_ROLL        = «counterReg++»;
			  	parameter int unsigned REG_«output.name»_LOOP_OUTER       = «counterReg++»;
			  	parameter int unsigned REG_«output.name»_REALIGN_TYPE     = «counterReg++»;
			  «ENDFOR»
			  // TCDM addresses
			  // Input ports
			  «FOR input : inputMap.keySet»
			    parameter int unsigned REG_«input.name»_ADDR              = «counterReg++»;
			  «ENDFOR»
			  // Output ports
			  «FOR output : outputMap.keySet»
			  	parameter int unsigned REG_«output.name»_ADDR              = «counterReg++»;
			  «ENDFOR»
			  /* Microcode processor */
			  // offset indeces -- this should be aligned to the microcode compiler of course!
			  «FOR port : portMap.keySet»
			  	parameter int unsigned UCODE_«port.name»_OFFS              = «portMap.get(port)»;
			  «ENDFOR»
			  // mnemonics -- this should be aligned to the microcode compiler of course!
			  parameter int unsigned UCODE_MNEM_NBITER     = 0;
			  parameter int unsigned UCODE_MNEM_ITERSTRIDE = 1;
			  parameter int unsigned UCODE_MNEM_ONESTRIDE  = 2;
			  parameter int unsigned UCODE_MNEM_TILESTRIDE = 3;
			  /* Typedefs */
			  typedef struct packed {
			    logic clear;
			    logic enable;
			    logic start;
			    logic unsigned [$clog2(CNT_LEN):0] cnt_limit;
			    // Custom register files
			  «FOR netParm : this.network.parameters»
			  	logic unsigned [(32-1):0] «netParm.name»;
			  «ENDFOR»
			  «IF !luts.empty»	
			  	logic unsigned [(32-1):0] configuration;
			  «ENDIF»
			  } ctrl_engine_t;
			  typedef struct packed {
			    logic unsigned [$clog2(CNT_LEN):0] cnt; // 1 bit more as cnt starts from 1, not 0
			    logic done;
			    logic idle;
			    logic ready;
			  } flags_engine_t;
			  typedef struct packed {
			  «FOR input : inputMap.keySet»
			    hwpe_stream_package::ctrl_sourcesink_t «input.name»_source_ctrl;
			  «ENDFOR»
			  «FOR output : outputMap.keySet»
			    hwpe_stream_package::ctrl_sourcesink_t «output.name»_sink_ctrl;
			  «ENDFOR»
			  } ctrl_streamer_t;
			  typedef struct packed {
			  «FOR input : inputMap.keySet»
			    hwpe_stream_package::flags_sourcesink_t «input.name»_source_flags;
			  «ENDFOR»
			  «FOR output : outputMap.keySet»
			    hwpe_stream_package::flags_sourcesink_t «output.name»_sink_flags;
			  «ENDFOR»
			  } flags_streamer_t;
			  typedef struct packed {
			    «FOR input : inputMap.keySet»
			      // Input stream - «input.name» (programmable)
			      logic unsigned [31:0] «input.name»_trans_size;
			      logic unsigned [31:0] «input.name»_line_stride;
			      logic unsigned [31:0] «input.name»_line_length;
			      logic unsigned [31:0] «input.name»_feat_stride;
			      logic unsigned [31:0] «input.name»_feat_length;
			      logic unsigned [31:0] «input.name»_feat_roll;
			      logic unsigned [31:0] «input.name»_loop_outer;
			      logic unsigned [31:0] «input.name»_realign_type;
			    «ENDFOR»
			    «FOR output : outputMap.keySet»
			      // Output stream - «output.name» (programmable)
			      logic unsigned [31:0] «output.name»_trans_size;
			      logic unsigned [31:0] «output.name»_line_stride;
			      logic unsigned [31:0] «output.name»_line_length;
			      logic unsigned [31:0] «output.name»_feat_stride;
			      logic unsigned [31:0] «output.name»_feat_length;
			      logic unsigned [31:0] «output.name»_feat_roll;
			      logic unsigned [31:0] «output.name»_loop_outer;
			      logic unsigned [31:0] «output.name»_realign_type;
			    «ENDFOR»
			    // Computation
			    logic unsigned [$clog2(CNT_LEN):0] cnt_limit;
			    // Custom register files
			    «FOR netParm : this.network.parameters»
			      logic unsigned [(32-1):0] «netParm.name»;
			    «ENDFOR»
			    «IF !luts.empty»
			      logic unsigned [(32-1):0] configuration;
			    «ENDIF»
			  } ctrl_fsm_t;
			  typedef enum {
			    FSM_IDLE,
			    FSM_START,
			    FSM_COMPUTE,
			    FSM_WAIT,
			    FSM_UPDATEIDX,
			    FSM_TERMINATE
			  } state_fsm_t;
			endpackage
				'''
	}
	
	def printStreamer() {
		'''
			«printHWPELicense(false ,"streamer")»
			import multi_dataflow_package::*;
			import hwpe_stream_package::*;
			module multi_dataflow_streamer
			#(
			  parameter int unsigned MP = «portMap.size», // number of master ports
			  parameter int unsigned FD = 2  // FIFO depth
			)
			(
			  // Global signals
			  input  logic          clk_i,
			  input  logic          rst_ni,
			  input  logic          test_mode_i,
			  // Local enable & clear
			  input  logic          enable_i,
			  input  logic          clear_i,
			  // TCDM interface
			  hwpe_stream_intf_tcdm.master tcdm [MP-1:0],
			  // Streaming interfaces
			  «FOR input : inputMap.keySet»
			   	hwpe_stream_intf_stream.source «input.name»,
			  «ENDFOR»
			  «FOR output : outputMap.keySet»
			   	hwpe_stream_intf_stream.sink «output.name»,
			  «ENDFOR»
			  // control channel
			  input  ctrl_streamer_t  ctrl_i,
			  output flags_streamer_t flags_o
			);
			  // Source modules (TCDM -> HWPE)
			  «FOR input : inputMap.keySet»
			  	hwpe_stream_source #(
			  	  .DATA_WIDTH ( 32 ),
			  	  .DECOUPLED  ( 1  )
			  	) i_«input.name»_source (
			  	  .clk_i              ( clk_i                  ),
			  	  .rst_ni             ( rst_ni                 ),
			  	  .test_mode_i        ( test_mode_i            ),
			  	  .clear_i            ( clear_i                ),
			  	  .tcdm               ( tcdm_fifo_«portMap.get(input)»	),
			  	  .stream             ( «input.name»_prefifo.source),
			  	  .ctrl_i             ( ctrl_i.«input.name»_source_ctrl   ),
			  	  .flags_o            ( flags_o.«input.name»_source_flags ),
			  	  .tcdm_fifo_ready_o  ( «input.name»_tcdm_fifo_ready      )
			  	);
			  «ENDFOR»
			  //
			  // Sink modules (TCDM <- HWPE)
			  «FOR output : outputMap.keySet»
			  	hwpe_stream_sink #(
			  	  .DATA_WIDTH ( 32 )
			  	  // .NB_TCDM_PORTS (    )
			  	) i_«output.name»_sink (
			  	  .clk_i       ( clk_i                ),
			  	  .rst_ni      ( rst_ni               ),
			  	  .test_mode_i ( test_mode_i          ),
			  	  .clear_i     ( clear_i              ),
			  	  .tcdm        ( tcdm_fifo_«portMap.get(output)»	),
			  	  .stream      ( «output.name»_postfifo.sink      ),
			  	  .ctrl_i      ( ctrl_i.«output.name»_sink_ctrl   ),
			  	  .flags_o     ( flags_o.«output.name»_sink_flags )
			  	);
			  «ENDFOR»
			  // FIFO interfaces
			  hwpe_stream_intf_tcdm tcdm_fifo [MP-1:0] ( .clk ( clk_i ) );
			  «FOR port : portMap.keySet»
			   hwpe_stream_intf_tcdm tcdm_fifo_«port.name» [«(port.dataSize - 1)»:0] ( .clk (clk_i) );
			  «ENDFOR»	
			  // Pre-FIFO streamer interfaces (TCDM-side)
			  «FOR input : inputMap.keySet»
			   hwpe_stream_intf_stream #( .DATA_WIDTH(32) ) «input.name»_prefifo ( .clk (clk_i) );
			  «ENDFOR»
			  // TCDM-side FIFOs (TCDM -> HWPE)
			  «FOR input : inputMap.keySet»
			  	hwpe_stream_tcdm_fifo_load #(
			  	  .FIFO_DEPTH ( 4 )
			  	) i_«input.name»_tcdm_fifo_load (
			  	  .clk_i       ( clk_i             ),
			  	  .rst_ni      ( rst_ni            ),
			  	  .clear_i     ( clear_i           ),
			  	  .flags_o     (                   ),
			  	  .ready_i     ( «input.name»_tcdm_fifo_ready ),
			  	  .tcdm_slave  ( tcdm_fifo_«portMap.get(input)»    ),
			  	  .tcdm_master ( tcdm      [«portMap.get(input)»]     )
			  	);
			  «ENDFOR»
			  // TCDM-side FIFOs (TCDM <- HWPE)
			  «FOR output : outputMap.keySet»
			  	hwpe_stream_tcdm_fifo_store #(
			  	  .FIFO_DEPTH ( 4 )
			  	) i_«output.name»_tcdm_fifo_store (
			  	  .clk_i       ( clk_i          ),
			  	  .rst_ni      ( rst_ni         ),
			  	  .clear_i     ( clear_i        ),
			  	  .flags_o     (                ),
			  	  .tcdm_slave  ( tcdm_fifo_«portMap.get(output)» ),
			  	  .tcdm_master ( tcdm       [«portMap.get(output)»] )
			  	);
			  «ENDFOR»
			  // Post-FIFO streamer interfaces (TCDM-side)
			  «FOR output : outputMap.keySet»
			   hwpe_stream_intf_stream #( .DATA_WIDTH (32) ) «output.name»_postfifo ( .clk (clk_i) );
			  «ENDFOR»
			  // Engine-side FIFOs (TCDM -> HWPE)
			  «FOR input : inputMap.keySet»
			  	hwpe_stream_fifo #(
			  	  .DATA_WIDTH( 32 ),
			  	  .FIFO_DEPTH( 2  ),
			  	  .LATCH_FIFO( 0  )
			  	) i_«input.name»_fifo (
			  	  .clk_i   ( clk_i          ),
			  	  .rst_ni  ( rst_ni         ),
			  	  .clear_i ( clear_i        ),
			  	  .push_i  ( «input.name»_prefifo.sink ),
			  	  .pop_o   ( «input.name»_o            ),
			  	  .flags_o (                )
			  	);
			  «ENDFOR»
			  // Datapath-side FIFOs (TCDM <- HWPE)
			  «FOR output : outputMap.keySet»
			  	hwpe_stream_fifo #(
			  	  .DATA_WIDTH( 32 ),
			  	  .FIFO_DEPTH( 2  ),
			  	  .LATCH_FIFO( 0  )
			  	) i_«output.name»_fifo (
			  	  .clk_i   ( clk_i             ),
			  	  .rst_ni  ( rst_ni            ),
			  	  .clear_i ( clear_i           ),
			  	  .push_i  ( «output.name»_i               ),
			  	  .pop_o   ( «output.name»_postfifo.source ),
			  	  .flags_o (                   )
			  	);
			  	
			  «ENDFOR»
			  endmodule // multi_dataflow_streamer
		  	'''
	}
	
	def printMk(String hclPath) {
		'''
		IP=hwpe_multi_dataflow
		IP_PATH=$(IPS_PATH)/hwpe-multi-dataflow
		LIB_NAME=$(IP)_lib
		
		include vcompile/build.mk
		
		.PHONY: vcompile-$(IP) vcompile-subip-hw-multi-dataflow 
		
		vcompile-$(IP): $(LIB_PATH)/_vmake
		
		$(LIB_PATH)/_vmake : $(LIB_PATH)/hw-multi-dataflow.vmake 
			@touch $(LIB_PATH)/_vmake
		
		
		# hw-multi-dataflow component
		INCDIR_HW-MULTI-DATAFLOW=+incdir+$(IP_PATH)/rtl
		SRC_SVLOG_HW-MULTI-DATAFLOW=\
			$(IP_PATH)/rtl/multi_dataflow_package.sv\
			$(IP_PATH)/rtl/multi_dataflow_fsm.sv\
			$(IP_PATH)/rtl/multi_dataflow_ctrl.sv\
			$(IP_PATH)/rtl/multi_dataflow_streamer.sv\
			«FOR file : new File(hclPath).listFiles»
			$(IP_PATH)/rtl/«file.name»\
			«ENDFOR»
			«IF !luts.empty»
			$(IP_PATH)/rtl/configurator.v\
			$(IP_PATH)/rtl/sbox1x2.v\
			$(IP_PATH)/rtl/sbox2x1.v\
			«ENDIF»
			$(IP_PATH)/rtl/multi_dataflow.v\
			$(IP_PATH)/rtl/interface_wrapper.sv\
			$(IP_PATH)/rtl/multi_dataflow_top.sv\
			$(IP_PATH)/wrap/multi_dataflow_top_wrap.sv
		SRC_VHDL_HW-MULTI-DATAFLOW=
		
		vcompile-subip-hw-multi-dataflow: $(LIB_PATH)/hw-multi-dataflow.vmake
		
		$(LIB_PATH)/hw-multi-dataflow.vmake: $(SRC_SVLOG_HW-MULTI-DATAFLOW) $(SRC_VHDL_HW-MULTI-DATAFLOW)
			$(call subip_echo,hw-multi-dataflow)
			$(SVLOG_CC) -work $(LIB_PATH) +define+HWPE_ASSERT_SEVERITY="\$$fatal" -L hwpe_ctrl_lib -L hwpe_stream_lib -suppress 2583 -suppress 13314 $(INCDIR_HW-MULTI-DATAFLOW) $(SRC_SVLOG_HW-MULTI-DATAFLOW)
			
			@touch $(LIB_PATH)/hw-multi-dataflow.vmake
		
		'''
	}
	
	def printWrap() {
		'''
		«printHWPELicense(true ,"wrapper")»
		import multi_dataflow_package::*;
		import hwpe_ctrl_package::*;
		
		module multi_dataflow_top_wrap
		#(
		  parameter int unsigned N_CORES = 2,
		  parameter int unsigned MP  = «portMap.size»,
		  parameter int unsigned ID  = 10
		)
		(
		  // Global signals
		  input  logic          clk_i,
		  input  logic          rst_ni,
		  input  logic          test_mode_i,
		  // Events
		  output logic [N_CORES-1:0][REGFILE_N_EVT-1:0] evt_o,
		  // TCDM master ports
		  output logic [MP-1:0]                         tcdm_req,
		  input  logic [MP-1:0]                         tcdm_gnt,
		  output logic [MP-1:0][31:0]                   tcdm_add,
		  output logic [MP-1:0]                         tcdm_wen,
		  output logic [MP-1:0][3:0]                    tcdm_be,
		  output logic [MP-1:0][31:0]                   tcdm_data,
		  input  logic [MP-1:0][31:0]                   tcdm_r_data,
		  input  logic [MP-1:0]                         tcdm_r_valid,
		  // Peripheral slave port
		  input  logic                                  periph_req,
		  output logic                                  periph_gnt,
		  input  logic         [31:0]                   periph_add,
		  input  logic                                  periph_wen,
		  input  logic         [3:0]                    periph_be,
		  input  logic         [31:0]                   periph_data,
		  input  logic       [ID-1:0]                   periph_id,
		  output logic         [31:0]                   periph_r_data,
		  output logic                                  periph_r_valid,
		  output logic       [ID-1:0]                   periph_r_id
		);
		  hwpe_stream_intf_tcdm tcdm[MP-1:0] (
		    .clk ( clk_i )
		  );
		  hwpe_ctrl_intf_periph #(
		    .ID_WIDTH ( ID )
		  ) periph (
		    .clk ( clk_i )
		  );
		  // bindings
		  generate
		    for(genvar ii=0; ii<MP; ii++) begin: tcdm_binding
		      assign tcdm_req  [ii] = tcdm[ii].req;
		      assign tcdm_add  [ii] = tcdm[ii].add;
		      assign tcdm_wen  [ii] = tcdm[ii].wen;
		      assign tcdm_be   [ii] = tcdm[ii].be;
		      assign tcdm_data [ii] = tcdm[ii].data;
		      assign tcdm[ii].gnt     = tcdm_gnt     [ii];
		      assign tcdm[ii].r_data  = tcdm_r_data  [ii];
		      assign tcdm[ii].r_valid = tcdm_r_valid [ii];
		    end
		  endgenerate
		  always_comb
		  begin
		    periph.req  = periph_req;
		    periph.add  = periph_add;
		    periph.wen  = periph_wen;
		    periph.be   = periph_be;
		    periph.data = periph_data;
		    periph.id   = periph_id;
		    periph_gnt     = periph.gnt;
		    periph_r_data  = periph.r_data;
		    periph_r_valid = periph.r_valid;
		    periph_r_id    = periph.r_id;
		  end
		  multi_dataflow_top #(
		    .N_CORES ( N_CORES ),
		    .MP      ( MP      ),
		    .ID      ( ID      )
		  ) i_multi_dataflow_top (
		    .clk_i       ( clk_i       ),
		    .rst_ni      ( rst_ni      ),
		    .test_mode_i ( test_mode_i ),
		    .evt_o       ( evt_o       ),
		    .tcdm        ( tcdm        ),
		    .periph      ( periph      )
		  );
		endmodule // multi_dataflow_top_wrap
		'''
	}
	
	def printPulpHwpeWrap() {
		'''

		/*
		 *
		 * Copyright (C) 2018 ETH Zurich, University of Bologna
		 * Copyright and related rights are licensed under the Solderpad Hardware
		 * License, Version 0.51 (the "License"); you may not use this file except in
		 * compliance with the License.  You may obtain a copy of the License at
		 * http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
		 * or agreed to in writing, software, hardware and materials distributed under
		 * this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
		 * CONDITIONS OF ANY KIND, either express or implied. See the License for the
		 * specific language governing permissions and limitations under the License.
		 *
		 * Authors:     Francesco Conti <fconti@iis.ee.ethz.ch>
		 * Contribute:  Gianluca Bellocchi <gianluca.bellocchi@unimore.it>
		 *
		 * Module: pulp_hwpe_wrap.sv
		 *
		 */
		module pulp_hwpe_wrap
		#(
		  parameter N_CORES = 2,
		  parameter N_HWPE = 2,
		  parameter N_DMA = 4,
		  parameter N_EXT = 4,
		  parameter N_MEM = 16,
		  parameter N_MASTER_PORT = 4,
		  parameter ID_WIDTH = 8,
		  parameter DEFAULT_DW = 32,
		  parameter DEFAULT_AW = 32,
		  parameter DEFAULT_BW = 8,
		  parameter DEFAULT_WW = 10,
		  parameter AWH = DEFAULT_AW
		)
		(
		  input  logic                        clk,
		  input  logic                        rst_n,
		  input  logic                        test_mode,
		  XBAR_TCDM_BUS.Master                hwacc_xbar_master[N_MASTER_PORT-1:0],
		  XBAR_PERIPH_BUS.Slave               hwacc_cfg_slave,
		  output logic [N_CORES-1:0][1:0]     evt_o,
		  output logic                        busy_o
		);
		  logic [N_MASTER_PORT-1:0]           tcdm_req;
		  logic [N_MASTER_PORT-1:0]           tcdm_gnt;
		  logic [N_MASTER_PORT-1:0] [32-1:0]  tcdm_add;
		  logic [N_MASTER_PORT-1:0]           tcdm_type;
		  logic [N_MASTER_PORT-1:0] [4 -1:0]  tcdm_be;
		  logic [N_MASTER_PORT-1:0] [32-1:0]  tcdm_wdata;
		  logic [N_MASTER_PORT-1:0] [32-1:0]  tcdm_r_rdata;
		  logic [N_MASTER_PORT-1:0]           tcdm_r_valid;
		  multi_dataflow_top_wrap #(
		    .N_CORES          ( N_CORES ),
		    .MP               ( N_MASTER_PORT ),
		    .ID               ( ID_WIDTH )
		  ) i_hwpe_top_wrap (
		    .clk_i          ( clk                       ),
		    .rst_ni         ( rst_n                     ),
		    .test_mode_i    ( test_mode                 ),
		    .tcdm_add       ( tcdm_add                  ), // address
		    .tcdm_be        ( tcdm_be                   ), // byte enable
		    .tcdm_data      ( tcdm_wdata                ), // write data
		    .tcdm_gnt       ( tcdm_gnt                  ), // grant
		    .tcdm_wen       ( tcdm_type                 ), // write enable
		    .tcdm_req       ( tcdm_req                  ), // request
		    .tcdm_r_data    ( tcdm_r_rdata              ), // read data
		    .tcdm_r_valid   ( tcdm_r_valid              ), // read valid
		    .periph_add     ( hwacc_cfg_slave.add       ),  // address
		    .periph_be      ( hwacc_cfg_slave.be        ),  // byte enable
		    .periph_data    ( hwacc_cfg_slave.wdata     ),  // write data
		    .periph_gnt     ( hwacc_cfg_slave.gnt       ),  // grant
		    .periph_wen     ( hwacc_cfg_slave.wen       ),  // write enable
		    .periph_req     ( hwacc_cfg_slave.req       ),  // request
		    .periph_id      ( hwacc_cfg_slave.id        ),  // write id
		    .periph_r_data  ( hwacc_cfg_slave.r_rdata   ),  // read data
		    .periph_r_valid ( hwacc_cfg_slave.r_valid   ),  // read valid
		    .periph_r_id    ( hwacc_cfg_slave.r_id      ),  // read id
		    .evt_o          ( evt_o                     )   // event
		  );
		  assign busy_o = 1'b1;
		  genvar i;
		  generate
		    for (i=0;i<N_MASTER_PORT;i++) begin : hwacc_binding
		      assign hwacc_xbar_master[i].req   = tcdm_req   [i];
		      assign hwacc_xbar_master[i].add   = tcdm_add   [i];
		      assign hwacc_xbar_master[i].wen   = tcdm_type  [i];
		      assign hwacc_xbar_master[i].wdata = tcdm_wdata [i];
		      assign hwacc_xbar_master[i].be    = tcdm_be    [i];
		      // response channel
		      assign tcdm_gnt     [i] = hwacc_xbar_master[i].gnt;
		      assign tcdm_r_rdata [i] = hwacc_xbar_master[i].r_rdata;
		      assign tcdm_r_valid [i] = hwacc_xbar_master[i].r_valid;
		    end
		  endgenerate
		endmodule // pulp_hwpe_wrap
		'''
	}	
	
	def printPulpClusterHwpePkg() {
		'''	
		
		/*
		 *
		 * pulp_cluster_hwpe_pkg.sv
		 *
		 * Author: Gianluca Bellocchi <gianluca.bellocchi@unimore.it>
		 *
		 * Configuration package for HWPE module
		 * This package has to be included in the 'pulp_cluster_cfg_pkg' configuration package
		 * for PULP cluster OOC stub. Here are collected the HWPE design features that need to be
		 * shared with the higher-level (with respect to the HWPE module) hardware modules
		 * of the PULP system.
		 *
		 */
		package automatic pulp_cluster_hwpe_pkg;
		  localparam bit          HWPE_PRESENT = 1'b1;
		  localparam int unsigned N_HWPE_PORTS = «portMap.keySet.size»;
		endpackage
		'''
	}	
	
	def printPulpTop() {
		'''	
			«printHWPELicense(true ,"top")»
			import multi_dataflow_package::*;
			import hwpe_ctrl_package::*;
			module multi_dataflow_top
			#(
			  parameter int unsigned N_CORES = 2,
			  parameter int unsigned MP  = «portMap.keySet.size»,
			  parameter int unsigned ID  = 10
			)
			(
			  // Global signals
			  input  logic          clk_i,
			  input  logic          rst_ni,
			  input  logic          test_mode_i,
			  // Events
			  output logic [N_CORES-1:0][REGFILE_N_EVT-1:0] evt_o,
			  // TCDM master ports
			  hwpe_stream_intf_tcdm.master                  tcdm[MP-1:0],
			  // Peripheral slave port
			  hwpe_ctrl_intf_periph.slave                   periph
			);
			  // Signals
			  logic enable, clear;
			  logic [N_CORES-1:0][REGFILE_N_EVT-1:0] evt;
			  ctrl_streamer_t  streamer_ctrl;
			  flags_streamer_t streamer_flags;
			  ctrl_engine_t    engine_ctrl;
			  flags_engine_t   engine_flags;
			  // Streamer interfaces
			  «FOR port : portMap.keySet»  
			  hwpe_stream_intf_stream #( .DATA_WIDTH(32) ) «port.name» ( .clk (clk_i) );
			  «ENDFOR»  
			  // HWPE engine wrapper
			  multi_dataflow_engine i_engine (
			    .clk_i            ( clk_i          ),
			    .rst_ni           ( rst_ni         ),
			    .test_mode_i      ( test_mode_i    ),
			    «FOR port : inputMap.keySet»  
			    .«port.name»_i              ( «port.name».i       ),
			    «ENDFOR»  
			    «FOR port : outputMap.keySet»  
			    .«port.name»_o              ( «port.name».o       ),
			    «ENDFOR»  
			    .ctrl_i           ( engine_ctrl    ),
			    .flags_o          ( engine_flags   )
			  );
			  // HWPE streamer wrapper
			  multi_dataflow_streamer #(
			    .MP ( MP )
			  ) i_streamer (
			    .clk_i            ( clk_i          ),
			    .rst_ni           ( rst_ni         ),
			    .test_mode_i      ( test_mode_i    ),
			    .enable_i         ( enable         ),
			    .clear_i          ( clear          ),
			    «FOR port : inputMap.keySet»  
			    	.«port.name»              ( «port.name».o       ),
			    «ENDFOR»  
			    «FOR port : outputMap.keySet»  
			    	.«port.name»              ( «port.name».i       ),
			    «ENDFOR»  		  
			    .tcdm             ( tcdm           ),
			    .ctrl_i           ( streamer_ctrl  ),
			    .flags_o          ( streamer_flags )
			  );
			  // HWPE ctrl wrapper
			  multi_dataflow_ctrl #(
			    .N_CORES   ( 2  ),
			    .N_CONTEXT ( 2  ),
			    .N_IO_REGS ( 16 ),
			    .ID ( ID )
			  ) i_ctrl (
			    .clk_i            ( clk_i          ),
			    .rst_ni           ( rst_ni         ),
			    .test_mode_i      ( test_mode_i    ),
			    .clear_o          ( clear          ),
			    .evt_o            ( evt_o          ),
			    .ctrl_streamer_o  ( streamer_ctrl  ),
			    .flags_streamer_i ( streamer_flags ),
			    .ctrl_engine_o    ( engine_ctrl    ),
			    .flags_engine_i   ( engine_flags   ),
			    .periph           ( periph         )
			  );
			  assign enable = 1'b1;
			endmodule
			    
		'''
	}	
	
	def printEngine() {
		'''	
			«printHWPELicense(true ,"engine")»
			import multi_dataflow_package::*;
			module multi_dataflow_engine (
			  // Global signals
			  input  logic          clk_i,
			  input  logic          rst_ni,
			  input  logic          test_mode_i,
			  // Sink ports
			  «FOR port : inputMap.keySet»  
			  	hwpe_stream_intf_stream.sink    «port.name»,
			  «ENDFOR»  
			  // Source ports
			  «FOR port : outputMap.keySet»  
			  	hwpe_stream_intf_stream.source  «port.name»,
			  «ENDFOR»  		  
			  // Control channel
			  input  ctrl_engine_t            ctrl_i,
			  output flags_engine_t           flags_o
			);
			  // multi_dataflow control
			  logic clear;
			  logic done, idle, ready;
			  assign clear = ctrl_i.clear;
			  assign flags_o.done = done;
			  assign flags_o.idle = idle;
			  always_ff @(posedge clk_i or negedge rst_ni)
			  begin: fsm_ready
			    if(~rst_ni)
			      flags_o.ready = 1'b0;
			    else if(~(ready | idle))
			      flags_o.ready = 1'b0;
			    else
			      flags_o.ready = 1'b1;
			  end
			  /* Count outputs */
			  «FOR port : outputMap.keySet»  
			    logic unsigned [($clog2(MDC_CNT_LEN)+1):0] cnt_«port.name»;
			    always_ff @(posedge clk_i or negedge rst_ni)
			    begin: cnt_«port.name»_counter
			      if((~rst_ni) | clear)
			    	cnt_«port.name» = 32'b0;
			      else if( («port.name».valid) & («port.name».ready) & (done) )			    	cnt_«port.name» = cnt_«port.name» + 1;
			        cnt_«port.name» = cnt_«port.name» + 1;
			      else
			    	cnt_«port.name» = cnt_«port.name»;
			    end
			    assign flags_o.cnt = cnt_«port.name»;
			  «ENDFOR» 
			  /* Kernel adapter */
			  multi_dataflow_kernel_adapter i_multi_dataflow_adapter (
			    // Global signals
			    .clk_i           ( clk_i            ),
			    .rst_ni          ( rst_ni           ),
			    .test_mode_i     ( test_mode_i      ),
			    // Data streams
			    «FOR port : inputMap.keySet»  
			        .i_«port.name»              ( «port.name»	),
			    «ENDFOR»  
			    «FOR port : outputMap.keySet»  
			        .o_«port.name»              ( «port.name»	),
			    «ENDFOR»  	  
			    // Algorithm parameters
			    «FOR param : network.parameters» 
			        .«param.name»        ( ctrl_i.«param.name»      ),
			    «ENDFOR»  
			    «IF !(this.luts.empty)»// Multi-Dataflow Kernel ID
			      .ID(ctrl_i.configuration),
			     «ENDIF»
			    // Control signals
			    .start           ( ctrl_i.start     ),
			    // Flag signals
			    .done            ( engine_done      ),
			    .idle            ( engine_idle      ),
			    .ready           ( engine_ready     )
			  );
			endmodule
		'''
	}		
	
	def printKernelAdapter() {
		'''	
			«printHWPELicense(true ,"kernel_wrapper")»
			import multi_dataflow_package::*;
			module multi_dataflow_kernel_adapter (
			  // Global signals
			  input  logic          clk_i,
			  input  logic          rst_ni,
			  input  logic          test_mode_i,
			  // Sink ports
			  «FOR port : inputMap.keySet»  
			  	hwpe_stream_intf_stream.sink    i_«port.name»,
			  «ENDFOR»  
			  // Source ports
			  «FOR port : outputMap.keySet»  
			  	hwpe_stream_intf_stream.source    o_«port.name»,
			  «ENDFOR»  
			  // Algorithm parameters
			  «FOR param : network.parameters» 
			  	input logic [31:0] «param.name»,
			  «ENDFOR»  
			  «IF !(this.luts.empty)»// Multi-Dataflow Kernel ID
			    input logic [31:0] 		ID,
			  «ENDIF»
			  // Control signals
			  input  logic          start,
			  // Flag signals
			  output logic          done,
			  output logic          idle,
			  output logic          ready
			  );
			  /* ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ */
			  /* multi_dataflow control signals. */
			  logic kernel_start;
			  // START is not always high. For each READY (~(engine_ready | engine_idle)) that is
			  // delivered to the FSM, a new START signal is set high and iaaued to the kernel.
			  assign kernel_start = start;
			  /* multi_dataflow flag signals. */
			  «FOR port : inputMap.keySet»  
			  	logic local_ready_«port.name»;
			  	logic kernel_done_«port.name»;  //FIXEME: to be removed
			  «ENDFOR»
			  «FOR port : outputMap.keySet»  
			  	logic kernel_done_«port.name»;
			  «ENDFOR»
			  logic kernel_done_out_r;
			  logic kernel_idle, kernel_ready;
			  /* Done. */
			  // A done is generated for each output. These are counted and
			  // delivered to the FSM that decides when to update the address
			  // on the basis of the state of the line processing (see HWPE-docs).
			  // FIXME: This temporarily works synch-outputs.
			  // EX: What if Out_0 is provided at each input and Out_1 once per 10 inputs?
			  assign done = «FOR output : outputMap.keySet SEPARATOR " & "» (kernel_done_«output.name») «ENDFOR»;
			  «FOR output : outputMap.keySet»
			    always_ff @(posedge clk_i or negedge rst_ni)
			      begin: fsm_done_«output.name»
			    	if(~rst_ni)
			    	  kernel_done_«output.name» = 1'b0;
			    	else if((o_«output.name».valid)&(o_«output.name».ready))
			    	  kernel_done_«output.name» = 1'b1;
			    	else
			    	  kernel_done_«output.name» = 1'b0;
			      end
			  «ENDFOR»
			  /* ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ */
			  /* Ready. */
			  /* This is used in the hwpe-engine to set flags_o.ready.
			     The latter triggers the START of accelerator. (see FSM_COMPUTE). */
			  /* Driven using input counters. */
			  assign ready = «FOR input : inputMap.keySet SEPARATOR " & "» (kernel_done_«input.name») «ENDFOR»;
			  /* ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ */
			  /* Idle. */
			  /* This is used in the hwpe-engine to set flags_o.ready.
			     The latter triggers the START of accelerator. (see FSM_COMPUTE). */
			  /* For more infos refer to UG902. */
			  assign idle = kernel_idle;
			  /* The Idle signal indicates when the design is idle and not operating. */
			  always_ff @(posedge clk_i or negedge rst_ni)
			  begin: fsm_idle
					if(~rst_ni) begin
			      kernel_idle = 1'b0;
			    end
			    else if(kernel_start) begin
			      /* Idle goes Low immediately after Start to indicate the design is no longer idle. */
			      /* If the Start signal is High when Ready is High, the design continues to operate,
			          and the Idle signal remains Low. */
						kernel_idle = 1'b0;
			    end
			    else if((!kernel_start) & (ready)) begin
			      if(«FOR output : outputMap.keySet SEPARATOR " & "» (kernel_done_«output.name») «ENDFOR») begin
			        /* If the Start signal is Low when Ready is High, the design stops operation, and
			            the ap_idle signal goes High one cycle after ap_done.*/
			        kernel_idle = 1'b1;
			      end
			    end
			    else begin
						kernel_idle = kernel_idle;
			    end
			  end
			  /* ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ */
			  /* multi_dataflow input counters. Ready. */
			  «FOR port : inputMap.keySet»  
			    logic unsigned [($clog2(CNT_LEN)+1):0] local_cnt_«port.name»;
			    always_ff @(posedge clk_i or negedge rst_ni)
			      begin: engine_cnt_«port.name»
			      if((~rst_ni)) begin
			        local_cnt_«port.name» = 32'b0;
			      end
			      else if(kernel_start) begin
			        local_cnt_«port.name» = 32'b0;
			      end
			      else if ((i_«port.name».valid) & (i_«port.name».ready)) begin
			    	local_cnt_«port.name» = local_cnt_«port.name» + 1;
			      end
			      else begin
			        local_cnt_«port.name» = local_cnt_«port.name»;
			      end
			    end
			    // FIXME: Now local_done_in goes High every time an input enters the acc.
			    // This should be generalized. Even though the wrapper looper is designed to
			    // on counting the ouputs, the number of inputs needed to generate an ouput
			    // are usually > 1.
			    // SOL: Add to ctrl_i also the information about max_input.
			    assign kernel_done_«port.name» = (local_cnt_«port.name»==1) ? 1 : 0;
			  «ENDFOR» 
			  /* ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ */
			  /* ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ */
			  /* multi_dataflow output counters. */
			  «FOR port : outputMap.keySet»  
			    logic unsigned [($clog2(CNT_LEN)+1):0] local_cnt_«port.name»;
			  «ENDFOR»
			  // Suggested design:
			  //      ap_done = done_out0 & ... & done_outM;
			  //      done_outM = cnt_out,i == ctrl_i.max_out,i; (for i=1,..,N)
			  // However, loop ctrl is already implemented in micro-code looper that sits
			  // in the hwpe-ctrl. Thus, the done information provided by this stage should
			  // concern a single output element, not a tile (block,..).
			  // FIXME: At this point, cnt_out is not essential here and could be removed.
			  «FOR output : outputMap.keySet»
			    always_ff @(posedge clk_i or negedge rst_ni)
			    begin: engine_cnt_«output.name»
			      if((~rst_ni))
			        local_cnt_«output.name» = 32'b0;
			      else if(!kernel_idle) begin
			        if((o_«output.name».valid)&(o_«output.name».ready))
			          local_cnt_«output.name» = local_cnt_«output.name» + 1;
			        else
			          local_cnt_«output.name» = local_cnt_«output.name»;
			      end
			    end
			    assign cnt_«output.name» = local_cnt_«output.name»;
			  «ENDFOR» 
			  /* ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ */
			  /* ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ */
			  /* multi_dataflow streaming interface control. */  
			  multi_dataflow_reconf_datapath_top i_multi_dataflow_reconf_datapath_top (
			    // Input data (to-hwpe)
			    «FOR port : inputMap.keySet»  
			      .«port.name»	( i_«port.name»	),
			    «ENDFOR»  
			    // Output data (from-hwpe)
			    «FOR port : outputMap.keySet»  
			      .«port.name»	( o_«port.name»	),
			    «ENDFOR»  
			    // Algorithm parameters
			    «FOR param : network.parameters» 
			      .«param.name»	( «param.name» ),
			    «ENDFOR» 
			    «IF !(this.luts.empty)»// Multi-Dataflow Kernel ID
			      .ID(ID_datapath_top),
			    «ENDIF»
			      // Global signals.
			      .clk_i             ( clk_i            ),
			      .rst_ni           ( rst_ni           )
			    );
			  // At the moment output strobe is always '1
			  // All bytes of output streams are written
			  // to TCDM
			  always_comb
			  begin
			    «FOR output : outputMap.keySet»
			    o_«output.name».strb = '1;
			    «ENDFOR»
			  end
			  /* ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ */
			endmodule
		'''
	}	
	
	def printPulpTbWave() {
		var counterXbarMaster = 0;
		'''	
		onerror {resume}
		quietly virtual signal -install {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/decoder_i} { /pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/decoder_i/instr_rdata_i[24:20]} rs2
		quietly virtual signal -install {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/decoder_i} { /pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/decoder_i/instr_rdata_i[19:15]} rs1
		quietly virtual signal -install {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i} { /pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/instr_rdata_i[6:0]} opcode
		quietly virtual signal -install {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i} { /pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/instr_rdata_i[11:7]} rd
		quietly virtual signal -install {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i} { /pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/instr_rdata_i[14:12]} funct3
		quietly virtual signal -install {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i} { /pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/instr_rdata_i[19:15]} rs1
		quietly virtual signal -install {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i} { /pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/instr_rdata_i[24:20]} rs2
		quietly WaveActivateNextPane {} 0
		add wave -noupdate -group {HWPE_wrapper[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/clk}
		add wave -noupdate -group {HWPE_wrapper[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/rst_n}
		add wave -noupdate -group {HWPE_wrapper[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/test_mode}
		«FOR port: portMap.keySet»
		add wave -noupdate -group {HWPE_wrapper[0]} -group {hwpe_xbar_master[«counterXbarMaster»]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/hwacc_xbar_master[«counterXbarMaster»]/req}
		add wave -noupdate -group {HWPE_wrapper[0]} -group {hwpe_xbar_master[«counterXbarMaster»]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/hwacc_xbar_master[«counterXbarMaster»]/add}
		add wave -noupdate -group {HWPE_wrapper[0]} -group {hwpe_xbar_master[«counterXbarMaster»]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/hwacc_xbar_master[«counterXbarMaster»]/wen}
		add wave -noupdate -group {HWPE_wrapper[0]} -group {hwpe_xbar_master[«counterXbarMaster»]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/hwacc_xbar_master[«counterXbarMaster»]/wdata}
		add wave -noupdate -group {HWPE_wrapper[0]} -group {hwpe_xbar_master[«counterXbarMaster»]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/hwacc_xbar_master[«counterXbarMaster»]/be}
		add wave -noupdate -group {HWPE_wrapper[0]} -group {hwpe_xbar_master[«counterXbarMaster»]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/hwacc_xbar_master[«counterXbarMaster»]/gnt}
		add wave -noupdate -group {HWPE_wrapper[0]} -group {hwpe_xbar_master[«counterXbarMaster»]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/hwacc_xbar_master[«counterXbarMaster»]/r_opc}
		add wave -noupdate -group {HWPE_wrapper[0]} -group {hwpe_xbar_master[«counterXbarMaster»]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/hwacc_xbar_master[«counterXbarMaster»]/r_rdata}
		add wave -noupdate -group {HWPE_wrapper[0]} -group {hwpe_xbar_master[«counterXbarMaster»]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/hwacc_xbar_master[«counterXbarMaster++»]/r_valid}
		«ENDFOR»
		add wave -noupdate -group {HWPE_wrapper[0]} -group {hwacc_cfg_slave} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/hwacc_cfg_slave/req}
		add wave -noupdate -group {HWPE_wrapper[0]} -group {hwacc_cfg_slave} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/hwacc_cfg_slave/add}
		add wave -noupdate -group {HWPE_wrapper[0]} -group {hwacc_cfg_slave} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/hwacc_cfg_slave/wen}
		add wave -noupdate -group {HWPE_wrapper[0]} -group {hwacc_cfg_slave} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/hwacc_cfg_slave/wdata}
		add wave -noupdate -group {HWPE_wrapper[0]} -group {hwacc_cfg_slave} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/hwacc_cfg_slave/be}
		add wave -noupdate -group {HWPE_wrapper[0]} -group {hwacc_cfg_slave} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/hwacc_cfg_slave/gnt}
		add wave -noupdate -group {HWPE_wrapper[0]} -group {hwacc_cfg_slave} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/hwacc_cfg_slave/id}
		add wave -noupdate -group {HWPE_wrapper[0]} -group {hwacc_cfg_slave} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/hwacc_cfg_slave/r_valid}
		add wave -noupdate -group {HWPE_wrapper[0]} -group {hwacc_cfg_slave} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/hwacc_cfg_slave/r_opc}
		add wave -noupdate -group {HWPE_wrapper[0]} -group {hwacc_cfg_slave} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/hwacc_cfg_slave/r_id}
		add wave -noupdate -group {HWPE_wrapper[0]} -group {hwacc_cfg_slave} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/hwacc_cfg_slave/r_rdata}
		add wave -noupdate -group {HWPE_wrapper[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/evt_o}
		add wave -noupdate -group {HWPE_wrapper[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/busy_o}
		add wave -noupdate -group {HWPE_top[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/clk_i}
		add wave -noupdate -group {HWPE_top[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/rst_ni}
		add wave -noupdate -group {HWPE_top[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/test_mode_i}
		add wave -noupdate -group {HWPE_top[0]} -group {tcdm} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/tcdm_add}
		add wave -noupdate -group {HWPE_top[0]} -group {tcdm} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/tcdm_be}
		add wave -noupdate -group {HWPE_top[0]} -group {tcdm} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/tcdm_data}
		add wave -noupdate -group {HWPE_top[0]} -group {tcdm} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/tcdm_gnt}
		add wave -noupdate -group {HWPE_top[0]} -group {tcdm} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/tcdm_wen}
		add wave -noupdate -group {HWPE_top[0]} -group {tcdm} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/tcdm_req}
		add wave -noupdate -group {HWPE_top[0]} -group {tcdm} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/tcdm_r_data}
		add wave -noupdate -group {HWPE_top[0]} -group {tcdm} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/tcdm_r_valid}
		add wave -noupdate -group {HWPE_top[0]} -group {periph} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/periph_add}
		add wave -noupdate -group {HWPE_top[0]} -group {periph} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/periph_be}
		add wave -noupdate -group {HWPE_top[0]} -group {periph} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/periph_data}
		add wave -noupdate -group {HWPE_top[0]} -group {periph} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/periph_gnt}
		add wave -noupdate -group {HWPE_top[0]} -group {periph} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/periph_wen}
		add wave -noupdate -group {HWPE_top[0]} -group {periph} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/periph_req}
		add wave -noupdate -group {HWPE_top[0]} -group {periph} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/periph_id}
		add wave -noupdate -group {HWPE_top[0]} -group {periph} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/periph_r_data}
		add wave -noupdate -group {HWPE_top[0]} -group {periph} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/periph_r_valid}
		add wave -noupdate -group {HWPE_top[0]} -group {periph} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/periph_r_id}
		add wave -noupdate -group {HWPE_top[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/evt_o}
		add wave -noupdate -group {HWPE_multi_dataflow_engine[0]} -group {global} -label {clk_i} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_engine/clk_i}
		add wave -noupdate -group {HWPE_multi_dataflow_engine[0]} -group {global} -label {rst_ni} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_engine/rst_ni}
		add wave -noupdate -group {HWPE_multi_dataflow_engine[0]} -group {global} -label {test_mode_i} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_engine/test_mode_i}
		«FOR port: inputMap.keySet»
		add wave -noupdate -group {HWPE_multi_dataflow_engine[0]} -group {Input data} -label {«port.name»} -label{Valid} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_engine/«port.name»_i/valid}
		add wave -noupdate -group {HWPE_multi_dataflow_engine[0]} -group {Input data} -label {«port.name»} -label{Data} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_engine/«port.name»_i/data}
		add wave -noupdate -group {HWPE_multi_dataflow_engine[0]} -group {Input data} -label {«port.name»} -label{Ready} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_engine/«port.name»_i/ready}
		«ENDFOR»
		«FOR port: outputMap.keySet»
		add wave -noupdate -group {HWPE_multi_dataflow_engine[0]} -group {Output data} -label {«port.name» valid} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_engine/«port.name»_o/valid}
		add wave -noupdate -group {HWPE_multi_dataflow_engine[0]} -group {Output data} -label {«port.name» data} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_engine/«port.name»_o/data}
		add wave -noupdate -group {HWPE_multi_dataflow_engine[0]} -group {Output data} -label {«port.name» ready} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_engine/«port.name»_o/ready}
		«ENDFOR»
		add wave -noupdate -group {HWPE_multi_dataflow_engine[0]} -group {control} -label {ctrl_i} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_engine/ctrl_i}
		add wave -noupdate -group {HWPE_multi_dataflow_engine[0]} -group {flags} -label {flags_o} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_engine/flags_o}
		add wave -noupdate -group {HWPE_multi_dataflow_kernel_wrapper[0]} -group {Global} -label {clk_i} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_engine/i_multi_dataflow_adater/clk_i}
		add wave -noupdate -group {HWPE_multi_dataflow_kernel_wrapper[0]} -group {Global} -label {rst_ni} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_engine/i_multi_dataflow_adater/rst_ni}
		add wave -noupdate -group {HWPE_multi_dataflow_kernel_wrapper[0]} -group {Global} -label {test_mode_i} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_engine/i_multi_dataflow_adater/test_mode_i}
		«FOR port: inputMap.keySet»
		add wave -noupdate -group {HWPE_multi_dataflow_kernel_wrapper[0]} -group {Input data} -group {«port.name»} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_engine/i_multi_dataflow_adater/«port.name»/valid}
		add wave -noupdate -group {HWPE_multi_dataflow_kernel_wrapper[0]} -group {Input data} -group {«port.name»} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_engine/i_multi_dataflow_adater/«port.name»/data}
		add wave -noupdate -group {HWPE_multi_dataflow_kernel_wrapper[0]} -group {Input data} -group {«port.name»} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_engine/i_multi_dataflow_adater/«port.name»/ready}
		«ENDFOR»
		«FOR port: outputMap.keySet»
		add wave -noupdate -group {HWPE_multi_dataflow_kernel_wrapper[0]} -group {Output data} -group {«port.name»} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_engine/i_multi_dataflow_adater/«port.name»/valid}
		add wave -noupdate -group {HWPE_multi_dataflow_kernel_wrapper[0]} -group {Output data} -group {«port.name»} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_engine/i_multi_dataflow_adater/«port.name»/data}
		add wave -noupdate -group {HWPE_multi_dataflow_kernel_wrapper[0]} -group {Output data} -group {«port.name»} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_engine/i_multi_dataflow_adater/«port.name»/ready}
		«ENDFOR»
		«FOR param : network.parameters» 
		add wave -noupdate -group {HWPE_multi_dataflow_kernel_wrapper[0]} -group {Custom registers} -label {«param.name»} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_engine/i_multi_dataflow_adater/«param.name»}
		«ENDFOR» 
		add wave -noupdate -group {HWPE_multi_dataflow_kernel_wrapper[0]} -group {Control} -label {Start} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_engine/i_multi_dataflow_adater/start}
		add wave -noupdate -group {HWPE_multi_dataflow_kernel_wrapper[0]} -group {Control} -label {Clear} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_engine/i_multi_dataflow_adater/clear}
		add wave -noupdate -group {HWPE_multi_dataflow_kernel_wrapper[0]} -group {Flags} -label {Done} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_engine/i_multi_dataflow_adater/done}
		add wave -noupdate -group {HWPE_multi_dataflow_kernel_wrapper[0]} -group {Flags} -label {Idle} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_engine/i_multi_dataflow_adater/idle}
		add wave -noupdate -group {HWPE_multi_dataflow_kernel_wrapper[0]} -group {Flags} -label {Ready} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_engine/i_multi_dataflow_adater/ready}
		«FOR port: outputMap.keySet»
		add wave -noupdate -group {HWPE_multi_dataflow_kernel_wrapper[0]} -group {Output counters} -label {cnt_out} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_engine/i_multi_dataflow_adater/cnt_«port.name»}
		«ENDFOR»
		add wave -noupdate -group {HWPE_multi_dataflow_kernel_wrapper[0]} -group {Local} -group {Control} -label {Start} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_engine/i_multi_dataflow_adater/local_start}
		«FOR port: inputMap.keySet»
		add wave -noupdate -group {HWPE_multi_dataflow_kernel_wrapper[0]} -group {Local} -group {Flags} -label {Ready_«port.name»} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_engine/i_multi_dataflow_adater/local_ready_«port.name»}
		add wave -noupdate -group {HWPE_multi_dataflow_kernel_wrapper[0]} -group {Local} -group {Flags} -label {Done_«port.name»} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_engine/i_multi_dataflow_adater/local_done_«port.name»}
		«ENDFOR»
		«FOR port: outputMap.keySet»
		add wave -noupdate -group {HWPE_multi_dataflow_kernel_wrapper[0]} -group {Local} -group {Flags} -label {Done«port.name»} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_engine/i_multi_dataflow_adater/local_done_«port.name»}
		«ENDFOR»
		add wave -noupdate -group {HWPE_multi_dataflow_kernel_wrapper[0]} -group {Local} -group {Flags} -label {Idle} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_engine/i_multi_dataflow_adater/local_idle}
		«FOR port: inputMap.keySet»
		add wave -noupdate -group {HWPE_multi_dataflow_kernel_wrapper[0]} -group {Local} -group {Counter-in} -label {Count_«port.name»} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_engine/i_multi_dataflow_adater/local_cnt_«port.name»}
		«ENDFOR»
		«FOR port: outputMap.keySet»
		add wave -noupdate -group {HWPE_multi_dataflow_kernel_wrapper[0]} -group {Local} -group {Counter-out} -label {Count_«port.name»} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_engine/i_multi_dataflow_adater/local_cnt_«port.name»}
		«ENDFOR»
		add wave -noupdate -group {HWPE_streamer[0]} -group {global} -label {clk_i} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_streamer/clk_i}
		add wave -noupdate -group {HWPE_streamer[0]} -group {global} -label {rst_ni} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_streamer/rst_ni}
		add wave -noupdate -group {HWPE_streamer[0]} -group {global} -label {test_mode_i} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_streamer/test_mode_i}
		add wave -noupdate -group {HWPE_streamer[0]} -group {global} -label {enable_i} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_streamer/enable_i}
		add wave -noupdate -group {HWPE_streamer[0]} -group {global} -label {clear_i} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_streamer/clear_i}
		«FOR port: inputMap.keySet»
		add wave -noupdate -group {HWPE_streamer[0]} -group {«port.name»_sink («port.name»)} -group {intf_tcdm} -label {req} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_streamer/i_«port.name»_source/tcdm[0]/req}
		add wave -noupdate -group {HWPE_streamer[0]} -group {«port.name»_sink («port.name»)} -group {intf_tcdm} -label {gnt} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_streamer/i_«port.name»_source/tcdm[0]/gnt}
		add wave -noupdate -group {HWPE_streamer[0]} -group {«port.name»_sink («port.name»)} -group {intf_tcdm} -label {add} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_streamer/i_«port.name»_source/tcdm[0]/add}
		add wave -noupdate -group {HWPE_streamer[0]} -group {«port.name»_sink («port.name»)} -group {intf_tcdm} -label {wen} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_streamer/i_«port.name»_source/tcdm[0]/wen}
		add wave -noupdate -group {HWPE_streamer[0]} -group {«port.name»_sink («port.name»)} -group {intf_tcdm} -label {be} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_streamer/i_«port.name»_source/tcdm[0]/be}
		add wave -noupdate -group {HWPE_streamer[0]} -group {«port.name»_sink («port.name»)} -group {intf_tcdm} -label {data} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_streamer/i_«port.name»_source/tcdm[0]/data}
		add wave -noupdate -group {HWPE_streamer[0]} -group {«port.name»_sink («port.name»)} -group {intf_tcdm} -label {r_data} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_streamer/i_«port.name»_source/tcdm[0]/r_data}
		add wave -noupdate -group {HWPE_streamer[0]} -group {«port.name»_sink («port.name»)} -group {intf_tcdm} -label {r_valid} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_streamer/i_«port.name»_source/tcdm[0]/r_valid}
		add wave -noupdate -group {HWPE_streamer[0]} -group {«port.name»_sink («port.name»)} -group {intf_stream} -label {valid} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_streamer/i_«port.name»_source/stream/valid}
		add wave -noupdate -group {HWPE_streamer[0]} -group {«port.name»_sink («port.name»)} -group {intf_stream} -label {ready} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_streamer/i_«port.name»_source/stream/ready}
		add wave -noupdate -group {HWPE_streamer[0]} -group {«port.name»_sink («port.name»)} -group {intf_stream} -label {data} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_streamer/i_«port.name»_source/stream/data}
		add wave -noupdate -group {HWPE_streamer[0]} -group {«port.name»_sink («port.name»)} -group {intf_stream} -label {strb} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_streamer/i_«port.name»_source/stream/strb}
		add wave -noupdate -group {HWPE_streamer[0]} -group {«port.name»_sink («port.name»)} -group {ctrl_plane} -label {current_state} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_streamer/i_«port.name»_source/cs}
		add wave -noupdate -group {HWPE_streamer[0]} -group {«port.name»_sink («port.name»)} -group {ctrl_plane} -label {next_state} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_streamer/i_«port.name»_source/ns}
		add wave -noupdate -group {HWPE_streamer[0]} -group {«port.name»_sink («port.name»)} -group {ctrl_plane} -label {ctrl_i} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_streamer/i_«port.name»_source/ctrl_i}
		add wave -noupdate -group {HWPE_streamer[0]} -group {«port.name»_sink («port.name»)} -group {ctrl_plane} -label {flags_o} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_streamer/i_«port.name»_source/flags_o}
		«ENDFOR»
		«FOR port: outputMap.keySet»
		add wave -noupdate -group {HWPE_streamer[0]} -group {«port.name»_sink («port.name»)} -group {intf_tcdm} -label {req} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_streamer/i_«port.name»_sink/tcdm[0]/req}
		add wave -noupdate -group {HWPE_streamer[0]} -group {«port.name»_sink («port.name»)} -group {intf_tcdm} -label {gnt} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_streamer/i_«port.name»_sink/tcdm[0]/gnt}
		add wave -noupdate -group {HWPE_streamer[0]} -group {«port.name»_sink («port.name»)} -group {intf_tcdm} -label {add} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_streamer/i_«port.name»_sink/tcdm[0]/add}
		add wave -noupdate -group {HWPE_streamer[0]} -group {«port.name»_sink («port.name»)} -group {intf_tcdm} -label {wen} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_streamer/i_«port.name»_sink/tcdm[0]/wen}
		add wave -noupdate -group {HWPE_streamer[0]} -group {«port.name»_sink («port.name»)} -group {intf_tcdm} -label {be} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_streamer/i_«port.name»_sink/tcdm[0]/be}
		add wave -noupdate -group {HWPE_streamer[0]} -group {«port.name»_sink («port.name»)} -group {intf_tcdm} -label {data} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_streamer/i_«port.name»_sink/tcdm[0]/data}
		add wave -noupdate -group {HWPE_streamer[0]} -group {«port.name»_sink («port.name»)} -group {intf_tcdm} -label {r_data} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_streamer/i_«port.name»_sink/tcdm[0]/r_data}
		add wave -noupdate -group {HWPE_streamer[0]} -group {«port.name»_sink («port.name»)} -group {intf_tcdm} -label {r_valid} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_streamer/i_«port.name»_sink/tcdm[0]/r_valid}
		add wave -noupdate -group {HWPE_streamer[0]} -group {«port.name»_sink («port.name»)} -group {intf_stream} -label {valid} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_streamer/i_«port.name»_sink/stream/valid}
		add wave -noupdate -group {HWPE_streamer[0]} -group {«port.name»_sink («port.name»)} -group {intf_stream} -label {ready} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_streamer/i_«port.name»_sink/stream/ready}
		add wave -noupdate -group {HWPE_streamer[0]} -group {«port.name»_sink («port.name»)} -group {intf_stream} -label {data} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_streamer/i_«port.name»_sink/stream/data}
		add wave -noupdate -group {HWPE_streamer[0]} -group {«port.name»_sink («port.name»)} -group {intf_stream} -label {strb} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_streamer/i_«port.name»_sink/stream/strb}
		add wave -noupdate -group {HWPE_streamer[0]} -group {«port.name»_sink («port.name»)} -group {ctrl_plane} -label {current_state} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_streamer/i_«port.name»_sink/cs}
		add wave -noupdate -group {HWPE_streamer[0]} -group {«port.name»_sink («port.name»)} -group {ctrl_plane} -label {next_state} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_streamer/i_«port.name»_sink/ns}
		add wave -noupdate -group {HWPE_streamer[0]} -group {«port.name»_sink («port.name»)} -group {ctrl_plane} -label {ctrl_i} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_streamer/i_«port.name»_sink/ctrl_i}
		add wave -noupdate -group {HWPE_streamer[0]} -group {«port.name»_sink («port.name»)} -group {ctrl_plane} -label {flags_o} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_streamer/i_«port.name»_sink/flags_o}
		«ENDFOR»
		add wave -noupdate -group {HWPE_ctrl[0]} -label {clk_i} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_ctrl/i_slave/i_regfile/clk_i}
		add wave -noupdate -group {HWPE_ctrl[0]} -label {rst_ni} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_ctrl/i_slave/i_regfile/rst_ni}
		add wave -noupdate -group {HWPE_ctrl[0]} -group {cfg} -label {add} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_ctrl/i_slave/cfg/add}
		add wave -noupdate -group {HWPE_ctrl[0]} -group {cfg} -label {wen} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_ctrl/i_slave/cfg/wen}
		add wave -noupdate -group {HWPE_ctrl[0]} -group {cfg} -label {be} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_ctrl/i_slave/cfg/be}
		add wave -noupdate -group {HWPE_ctrl[0]} -group {cfg} -label {data} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_ctrl/i_slave/cfg/data}
		add wave -noupdate -group {HWPE_ctrl[0]} -group {cfg} -label {id} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_ctrl/i_slave/cfg/id}
		add wave -noupdate -group {HWPE_ctrl[0]} -group {cfg} -label {r_data} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_ctrl/i_slave/cfg/r_data}
		add wave -noupdate -group {HWPE_ctrl[0]} -group {cfg} -label {r_valid} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_ctrl/i_slave/cfg/r_valid}
		add wave -noupdate -group {HWPE_ctrl[0]} -group {cfg} -label {r_id} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_ctrl/i_slave/cfg/r_id}
		add wave -noupdate -group {HWPE_ctrl[0]} -group {regfile} -label {clear_i} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_ctrl/i_slave/i_regfile/clear_i}
		add wave -noupdate -group {HWPE_ctrl[0]} -group {regfile} -label {regfile/in} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_ctrl/i_slave/i_regfile/regfile_in_i}
		add wave -noupdate -group {HWPE_ctrl[0]} -group {regfile} -label {regfile/out} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_ctrl/i_slave/i_regfile/regfile_out_o}
		add wave -noupdate -group {HWPE_ctrl[0]} -group {regfile} -label {regfile/flags} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_ctrl/i_slave/i_regfile/flags_i}
		add wave -noupdate -group {HWPE_ctrl[0]} -group {regfile} -label {regfile/ctrl} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_ctrl/i_slave/i_regfile/reg_file}
		«FOR param: network.parameters»
		add wave -noupdate -group {HWPE_ctrl[0]} -group {regfile} -group {multi_dataflow_static_regs} -label {«param.name»} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_ctrl/static_reg_«param.name»}
		«ENDFOR»
		add wave -noupdate -group {HWPE_ctrl[0]} -group {uloop} -group {global} -label {clk_i} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_ctrl/i_uloop/clk_i}
		add wave -noupdate -group {HWPE_ctrl[0]} -group {uloop} -group {global} -label {rst_ni} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_ctrl/i_uloop/rst_ni}
		add wave -noupdate -group {HWPE_ctrl[0]} -group {uloop} -group {global} -label {test_mode_i} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_ctrl/i_uloop/test_mode_i}
		add wave -noupdate -group {HWPE_ctrl[0]} -group {uloop} -group {global} -label {clear_i} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_ctrl/i_uloop/clear_i}
		add wave -noupdate -group {HWPE_ctrl[0]} -group {uloop} -group {i/o} -label {ctrl_i} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_ctrl/i_uloop/ctrl_i}
		add wave -noupdate -group {HWPE_ctrl[0]} -group {uloop} -group {i/o} -label {flags_o} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_ctrl/i_uloop/flags_o}
		add wave -noupdate -group {HWPE_ctrl[0]} -group {uloop} -group {i/o} -label {uloop_code_i} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_ctrl/i_uloop/uloop_code_i}
		add wave -noupdate -group {HWPE_ctrl[0]} -group {uloop} -group {i/o} -label {registers_read_i} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_ctrl/i_uloop/registers_read_i}
		add wave -noupdate -group {HWPE_ctrl[0]} -group {FSM} -group {global} -label {clk_i} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_ctrl/i_fsm/clk_i}
		add wave -noupdate -group {HWPE_ctrl[0]} -group {FSM} -group {global} -label {rst_ni} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_ctrl/i_fsm/rst_ni}
		add wave -noupdate -group {HWPE_ctrl[0]} -group {FSM} -group {global} -label {test_mode_i} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_ctrl/i_fsm/test_mode_i}
		add wave -noupdate -group {HWPE_ctrl[0]} -group {FSM} -group {global} -label {clear_i} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_ctrl/i_fsm/clear_i}
		add wave -noupdate -group {HWPE_ctrl[0]} -group {FSM} -label {current_state} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_ctrl/i_fsm/curr_state}
		add wave -noupdate -group {HWPE_ctrl[0]} -group {FSM} -label {next_state} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_ctrl/i_fsm/next_state}
		add wave -noupdate -group {HWPE_ctrl[0]} -group {FSM} -label {ctrl_fsm_i} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_ctrl/i_fsm/ctrl_i}
		add wave -noupdate -group {HWPE_ctrl[0]} -group {FSM} -group {in_flags} -label {flags_streamer_i} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_ctrl/i_fsm/flags_streamer_i}
		add wave -noupdate -group {HWPE_ctrl[0]} -group {FSM} -group {in_flags} -label {flags_engine_i} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_ctrl/i_fsm/flags_engine_i}
		add wave -noupdate -group {HWPE_ctrl[0]} -group {FSM} -group {in_flags} -label {flags_ucode_i} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_ctrl/i_fsm/flags_ucode_i}
		add wave -noupdate -group {HWPE_ctrl[0]} -group {FSM} -group {in_flags} -label {flags_slave_i} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_ctrl/i_fsm/flags_slave_i}
		add wave -noupdate -group {HWPE_ctrl[0]} -group {FSM} -group {out_ctrl} -label {ctrl_streamer_o} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_ctrl/i_fsm/ctrl_streamer_o}
		add wave -noupdate -group {HWPE_ctrl[0]} -group {FSM} -group {out_ctrl} -label {ctrl_engine_o} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_ctrl/i_fsm/ctrl_engine_o}
		add wave -noupdate -group {HWPE_ctrl[0]} -group {FSM} -group {out_ctrl} -label {ctrl_ucode_o} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_ctrl/i_fsm/ctrl_ucode_o}
		add wave -noupdate -group {HWPE_ctrl[0]} -group {FSM} -group {out_ctrl} -label {ctrl_slave_o} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/hwpe_gen/hwpe_wrap_i/i_hwpe_top_wrap/i_multi_dataflow_top/i_ctrl/i_fsm/ctrl_slave_o}
		add wave -noupdate -group {cluster_interconnect} -group {tcdm_interco} -group {inputs} -label {s_core_tcdm_bus_add} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/s_core_tcdm_bus_add}
		add wave -noupdate -group {cluster_interconnect} -group {tcdm_interco} -group {inputs} -label {iconn_inp_wdata} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/iconn_inp_wdata}
		add wave -noupdate -group {cluster_interconnect} -group {tcdm_interco} -group {outputs (to AMO)} -label {s_tcdm_bus_amo_shim_req} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/s_tcdm_bus_amo_shim_req}
		add wave -noupdate -group {cluster_interconnect} -group {tcdm_interco} -group {outputs (to AMO)} -label {s_tcdm_bus_amo_shim_gnt} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/s_tcdm_bus_amo_shim_gnt}
		add wave -noupdate -group {cluster_interconnect} -group {tcdm_interco} -group {outputs (to AMO)} -label {s_tcdm_bus_amo_shim_add} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/s_tcdm_bus_amo_shim_add}
		add wave -noupdate -group {cluster_interconnect} -group {tcdm_interco} -group {outputs (to AMO)} -label {s_tcdm_bus_amo_shim_wen} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/s_tcdm_bus_amo_shim_wen}
		add wave -noupdate -group {cluster_interconnect} -group {tcdm_interco} -group {outputs (to AMO)} -label {iconn_oup_wdata        } {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/iconn_oup_wdata        }
		add wave -noupdate -group {cluster_interconnect} -group {tcdm_interco} -group {outputs (to AMO)} -label {s_tcdm_bus_amo_shim_be } {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/s_tcdm_bus_amo_shim_be }
		add wave -noupdate -group {cluster_interconnect} -group {tcdm_interco} -group {outputs (to AMO)} -label {iconn_oup_rdata        } {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/iconn_oup_rdata        }
		add wave -noupdate -group {cluster_interconnect} -group {tcdm_sram_master} -group {tcdm_sram_master[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/tcdm_sram_master[0]/wdata}
		add wave -noupdate -group {cluster_interconnect} -group {tcdm_sram_master} -group {tcdm_sram_master[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/tcdm_sram_master[0]/add}
		add wave -noupdate -group {cluster_interconnect} -group {tcdm_sram_master} -group {tcdm_sram_master[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/tcdm_sram_master[0]/req}
		add wave -noupdate -group {cluster_interconnect} -group {tcdm_sram_master} -group {tcdm_sram_master[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/tcdm_sram_master[0]/wen}
		add wave -noupdate -group {cluster_interconnect} -group {tcdm_sram_master} -group {tcdm_sram_master[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/tcdm_sram_master[0]/be}
		add wave -noupdate -group {cluster_interconnect} -group {tcdm_sram_master} -group {tcdm_sram_master[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/tcdm_sram_master[0]/rdata}
		add wave -noupdate -group {cluster_interconnect} -group {tcdm_sram_master} -group {tcdm_sram_master[1]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/tcdm_sram_master[1]/add}
		add wave -noupdate -group {cluster_interconnect} -group {tcdm_sram_master} -group {tcdm_sram_master[1]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/tcdm_sram_master[1]/wdata}
		add wave -noupdate -group {cluster_interconnect} -group {tcdm_sram_master} -group {tcdm_sram_master[1]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/tcdm_sram_master[1]/req}
		add wave -noupdate -group {cluster_interconnect} -group {tcdm_sram_master} -group {tcdm_sram_master[1]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/tcdm_sram_master[1]/wen}
		add wave -noupdate -group {cluster_interconnect} -group {tcdm_sram_master} -group {tcdm_sram_master[1]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/tcdm_sram_master[1]/be}
		add wave -noupdate -group {cluster_interconnect} -group {tcdm_sram_master} -group {tcdm_sram_master[1]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/tcdm_sram_master[1]/rdata}
		add wave -noupdate -group {cluster_interconnect} -group {tcdm_sram_master} -group {tcdm_sram_master[2]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/tcdm_sram_master[2]/add}
		add wave -noupdate -group {cluster_interconnect} -group {tcdm_sram_master} -group {tcdm_sram_master[2]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/tcdm_sram_master[2]/wdata}
		add wave -noupdate -group {cluster_interconnect} -group {tcdm_sram_master} -group {tcdm_sram_master[2]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/tcdm_sram_master[2]/req}
		add wave -noupdate -group {cluster_interconnect} -group {tcdm_sram_master} -group {tcdm_sram_master[2]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/tcdm_sram_master[2]/wen}
		add wave -noupdate -group {cluster_interconnect} -group {tcdm_sram_master} -group {tcdm_sram_master[2]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/tcdm_sram_master[2]/be}
		add wave -noupdate -group {cluster_interconnect} -group {tcdm_sram_master} -group {tcdm_sram_master[2]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/tcdm_sram_master[2]/rdata}
		add wave -noupdate -group {cluster_interconnect} -group {tcdm_sram_master} -group {tcdm_sram_master[3]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/tcdm_sram_master[3]/add}
		add wave -noupdate -group {cluster_interconnect} -group {tcdm_sram_master} -group {tcdm_sram_master[3]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/tcdm_sram_master[3]/wdata}
		add wave -noupdate -group {cluster_interconnect} -group {tcdm_sram_master} -group {tcdm_sram_master[3]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/tcdm_sram_master[3]/req}
		add wave -noupdate -group {cluster_interconnect} -group {tcdm_sram_master} -group {tcdm_sram_master[3]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/tcdm_sram_master[3]/wen}
		add wave -noupdate -group {cluster_interconnect} -group {tcdm_sram_master} -group {tcdm_sram_master[3]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/tcdm_sram_master[3]/be}
		add wave -noupdate -group {cluster_interconnect} -group {tcdm_sram_master} -group {tcdm_sram_master[3]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/tcdm_sram_master[3]/rdata}
		add wave -noupdate -group {sram} -group {intf_sram[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/gen_tcdm_banks[0]/i_mem/req_i}
		add wave -noupdate -group {sram} -group {intf_sram[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/gen_tcdm_banks[0]/i_mem/addr_i}
		add wave -noupdate -group {sram} -group {intf_sram[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/gen_tcdm_banks[0]/i_mem/we_i}
		add wave -noupdate -group {sram} -group {intf_sram[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/gen_tcdm_banks[0]/i_mem/wdata_i}
		add wave -noupdate -group {sram} -group {intf_sram[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/gen_tcdm_banks[0]/i_mem/be_i}
		add wave -noupdate -group {sram} -group {intf_sram[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/gen_tcdm_banks[0]/i_mem/rdata_o}
		add wave -noupdate -group {sram} -group {intf_sram[1]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/gen_tcdm_banks[1]/i_mem/req_i}
		add wave -noupdate -group {sram} -group {intf_sram[1]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/gen_tcdm_banks[1]/i_mem/addr_i}
		add wave -noupdate -group {sram} -group {intf_sram[1]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/gen_tcdm_banks[1]/i_mem/we_i}
		add wave -noupdate -group {sram} -group {intf_sram[1]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/gen_tcdm_banks[1]/i_mem/wdata_i}
		add wave -noupdate -group {sram} -group {intf_sram[1]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/gen_tcdm_banks[1]/i_mem/be_i}
		add wave -noupdate -group {sram} -group {intf_sram[1]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/gen_tcdm_banks[1]/i_mem/rdata_o}
		add wave -noupdate -group {sram} -group {intf_sram[2]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/gen_tcdm_banks[2]/i_mem/req_i}
		add wave -noupdate -group {sram} -group {intf_sram[2]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/gen_tcdm_banks[2]/i_mem/addr_i}
		add wave -noupdate -group {sram} -group {intf_sram[2]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/gen_tcdm_banks[2]/i_mem/we_i}
		add wave -noupdate -group {sram} -group {intf_sram[2]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/gen_tcdm_banks[2]/i_mem/wdata_i}
		add wave -noupdate -group {sram} -group {intf_sram[2]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/gen_tcdm_banks[2]/i_mem/be_i}
		add wave -noupdate -group {sram} -group {intf_sram[2]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/gen_tcdm_banks[2]/i_mem/rdata_o}
		add wave -noupdate -group {sram} -group {intf_sram[3]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/gen_tcdm_banks[3]/i_mem/req_i}
		add wave -noupdate -group {sram} -group {intf_sram[3]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/gen_tcdm_banks[3]/i_mem/addr_i}
		add wave -noupdate -group {sram} -group {intf_sram[3]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/gen_tcdm_banks[3]/i_mem/we_i}
		add wave -noupdate -group {sram} -group {intf_sram[3]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/gen_tcdm_banks[3]/i_mem/wdata_i}
		add wave -noupdate -group {sram} -group {intf_sram[3]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/gen_tcdm_banks[3]/i_mem/be_i}
		add wave -noupdate -group {sram} -group {intf_sram[3]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/gen_tcdm_banks[3]/i_mem/rdata_o}
		add wave -noupdate -group {cl_inp[0]} {/pulp_tb/dut/cl_inp[0]/aw_id}
		add wave -noupdate -group {cl_inp[0]} {/pulp_tb/dut/cl_inp[0]/aw_addr}
		add wave -noupdate -group {cl_inp[0]} {/pulp_tb/dut/cl_inp[0]/aw_len}
		add wave -noupdate -group {cl_inp[0]} {/pulp_tb/dut/cl_inp[0]/aw_size}
		add wave -noupdate -group {cl_inp[0]} {/pulp_tb/dut/cl_inp[0]/aw_burst}
		add wave -noupdate -group {cl_inp[0]} {/pulp_tb/dut/cl_inp[0]/aw_lock}
		add wave -noupdate -group {cl_inp[0]} {/pulp_tb/dut/cl_inp[0]/aw_cache}
		add wave -noupdate -group {cl_inp[0]} {/pulp_tb/dut/cl_inp[0]/aw_prot}
		add wave -noupdate -group {cl_inp[0]} {/pulp_tb/dut/cl_inp[0]/aw_qos}
		add wave -noupdate -group {cl_inp[0]} {/pulp_tb/dut/cl_inp[0]/aw_region}
		add wave -noupdate -group {cl_inp[0]} {/pulp_tb/dut/cl_inp[0]/aw_atop}
		add wave -noupdate -group {cl_inp[0]} {/pulp_tb/dut/cl_inp[0]/aw_user}
		add wave -noupdate -group {cl_inp[0]} {/pulp_tb/dut/cl_inp[0]/aw_valid}
		add wave -noupdate -group {cl_inp[0]} {/pulp_tb/dut/cl_inp[0]/aw_ready}
		add wave -noupdate -group {cl_inp[0]} {/pulp_tb/dut/cl_inp[0]/w_data}
		add wave -noupdate -group {cl_inp[0]} {/pulp_tb/dut/cl_inp[0]/w_strb}
		add wave -noupdate -group {cl_inp[0]} {/pulp_tb/dut/cl_inp[0]/w_last}
		add wave -noupdate -group {cl_inp[0]} {/pulp_tb/dut/cl_inp[0]/w_user}
		add wave -noupdate -group {cl_inp[0]} {/pulp_tb/dut/cl_inp[0]/w_valid}
		add wave -noupdate -group {cl_inp[0]} {/pulp_tb/dut/cl_inp[0]/w_ready}
		add wave -noupdate -group {cl_inp[0]} {/pulp_tb/dut/cl_inp[0]/b_id}
		add wave -noupdate -group {cl_inp[0]} {/pulp_tb/dut/cl_inp[0]/b_resp}
		add wave -noupdate -group {cl_inp[0]} {/pulp_tb/dut/cl_inp[0]/b_user}
		add wave -noupdate -group {cl_inp[0]} {/pulp_tb/dut/cl_inp[0]/b_valid}
		add wave -noupdate -group {cl_inp[0]} {/pulp_tb/dut/cl_inp[0]/b_ready}
		add wave -noupdate -group {cl_inp[0]} {/pulp_tb/dut/cl_inp[0]/ar_id}
		add wave -noupdate -group {cl_inp[0]} {/pulp_tb/dut/cl_inp[0]/ar_addr}
		add wave -noupdate -group {cl_inp[0]} {/pulp_tb/dut/cl_inp[0]/ar_len}
		add wave -noupdate -group {cl_inp[0]} {/pulp_tb/dut/cl_inp[0]/ar_size}
		add wave -noupdate -group {cl_inp[0]} {/pulp_tb/dut/cl_inp[0]/ar_burst}
		add wave -noupdate -group {cl_inp[0]} {/pulp_tb/dut/cl_inp[0]/ar_lock}
		add wave -noupdate -group {cl_inp[0]} {/pulp_tb/dut/cl_inp[0]/ar_cache}
		add wave -noupdate -group {cl_inp[0]} {/pulp_tb/dut/cl_inp[0]/ar_prot}
		add wave -noupdate -group {cl_inp[0]} {/pulp_tb/dut/cl_inp[0]/ar_qos}
		add wave -noupdate -group {cl_inp[0]} {/pulp_tb/dut/cl_inp[0]/ar_region}
		add wave -noupdate -group {cl_inp[0]} {/pulp_tb/dut/cl_inp[0]/ar_user}
		add wave -noupdate -group {cl_inp[0]} {/pulp_tb/dut/cl_inp[0]/ar_valid}
		add wave -noupdate -group {cl_inp[0]} {/pulp_tb/dut/cl_inp[0]/ar_ready}
		add wave -noupdate -group {cl_inp[0]} {/pulp_tb/dut/cl_inp[0]/r_id}
		add wave -noupdate -group {cl_inp[0]} {/pulp_tb/dut/cl_inp[0]/r_data}
		add wave -noupdate -group {cl_inp[0]} {/pulp_tb/dut/cl_inp[0]/r_resp}
		add wave -noupdate -group {cl_inp[0]} {/pulp_tb/dut/cl_inp[0]/r_last}
		add wave -noupdate -group {cl_inp[0]} {/pulp_tb/dut/cl_inp[0]/r_user}
		add wave -noupdate -group {cl_inp[0]} {/pulp_tb/dut/cl_inp[0]/r_valid}
		add wave -noupdate -group {cl_inp[0]} {/pulp_tb/dut/cl_inp[0]/r_ready}
		add wave -noupdate -group {cl_oup_predwc[0]} {/pulp_tb/dut/cl_oup_predwc[0]/aw_id}
		add wave -noupdate -group {cl_oup_predwc[0]} {/pulp_tb/dut/cl_oup_predwc[0]/aw_addr}
		add wave -noupdate -group {cl_oup_predwc[0]} {/pulp_tb/dut/cl_oup_predwc[0]/aw_len}
		add wave -noupdate -group {cl_oup_predwc[0]} {/pulp_tb/dut/cl_oup_predwc[0]/aw_size}
		add wave -noupdate -group {cl_oup_predwc[0]} {/pulp_tb/dut/cl_oup_predwc[0]/aw_burst}
		add wave -noupdate -group {cl_oup_predwc[0]} {/pulp_tb/dut/cl_oup_predwc[0]/aw_lock}
		add wave -noupdate -group {cl_oup_predwc[0]} {/pulp_tb/dut/cl_oup_predwc[0]/aw_cache}
		add wave -noupdate -group {cl_oup_predwc[0]} {/pulp_tb/dut/cl_oup_predwc[0]/aw_prot}
		add wave -noupdate -group {cl_oup_predwc[0]} {/pulp_tb/dut/cl_oup_predwc[0]/aw_qos}
		add wave -noupdate -group {cl_oup_predwc[0]} {/pulp_tb/dut/cl_oup_predwc[0]/aw_region}
		add wave -noupdate -group {cl_oup_predwc[0]} {/pulp_tb/dut/cl_oup_predwc[0]/aw_atop}
		add wave -noupdate -group {cl_oup_predwc[0]} {/pulp_tb/dut/cl_oup_predwc[0]/aw_user}
		add wave -noupdate -group {cl_oup_predwc[0]} {/pulp_tb/dut/cl_oup_predwc[0]/aw_valid}
		add wave -noupdate -group {cl_oup_predwc[0]} {/pulp_tb/dut/cl_oup_predwc[0]/aw_ready}
		add wave -noupdate -group {cl_oup_predwc[0]} {/pulp_tb/dut/cl_oup_predwc[0]/w_data}
		add wave -noupdate -group {cl_oup_predwc[0]} {/pulp_tb/dut/cl_oup_predwc[0]/w_strb}
		add wave -noupdate -group {cl_oup_predwc[0]} {/pulp_tb/dut/cl_oup_predwc[0]/w_last}
		add wave -noupdate -group {cl_oup_predwc[0]} {/pulp_tb/dut/cl_oup_predwc[0]/w_user}
		add wave -noupdate -group {cl_oup_predwc[0]} {/pulp_tb/dut/cl_oup_predwc[0]/w_valid}
		add wave -noupdate -group {cl_oup_predwc[0]} {/pulp_tb/dut/cl_oup_predwc[0]/w_ready}
		add wave -noupdate -group {cl_oup_predwc[0]} {/pulp_tb/dut/cl_oup_predwc[0]/b_id}
		add wave -noupdate -group {cl_oup_predwc[0]} {/pulp_tb/dut/cl_oup_predwc[0]/b_resp}
		add wave -noupdate -group {cl_oup_predwc[0]} {/pulp_tb/dut/cl_oup_predwc[0]/b_user}
		add wave -noupdate -group {cl_oup_predwc[0]} {/pulp_tb/dut/cl_oup_predwc[0]/b_valid}
		add wave -noupdate -group {cl_oup_predwc[0]} {/pulp_tb/dut/cl_oup_predwc[0]/b_ready}
		add wave -noupdate -group {cl_oup_predwc[0]} {/pulp_tb/dut/cl_oup_predwc[0]/ar_id}
		add wave -noupdate -group {cl_oup_predwc[0]} {/pulp_tb/dut/cl_oup_predwc[0]/ar_addr}
		add wave -noupdate -group {cl_oup_predwc[0]} {/pulp_tb/dut/cl_oup_predwc[0]/ar_len}
		add wave -noupdate -group {cl_oup_predwc[0]} {/pulp_tb/dut/cl_oup_predwc[0]/ar_size}
		add wave -noupdate -group {cl_oup_predwc[0]} {/pulp_tb/dut/cl_oup_predwc[0]/ar_burst}
		add wave -noupdate -group {cl_oup_predwc[0]} {/pulp_tb/dut/cl_oup_predwc[0]/ar_lock}
		add wave -noupdate -group {cl_oup_predwc[0]} {/pulp_tb/dut/cl_oup_predwc[0]/ar_cache}
		add wave -noupdate -group {cl_oup_predwc[0]} {/pulp_tb/dut/cl_oup_predwc[0]/ar_prot}
		add wave -noupdate -group {cl_oup_predwc[0]} {/pulp_tb/dut/cl_oup_predwc[0]/ar_qos}
		add wave -noupdate -group {cl_oup_predwc[0]} {/pulp_tb/dut/cl_oup_predwc[0]/ar_region}
		add wave -noupdate -group {cl_oup_predwc[0]} {/pulp_tb/dut/cl_oup_predwc[0]/ar_user}
		add wave -noupdate -group {cl_oup_predwc[0]} {/pulp_tb/dut/cl_oup_predwc[0]/ar_valid}
		add wave -noupdate -group {cl_oup_predwc[0]} {/pulp_tb/dut/cl_oup_predwc[0]/ar_ready}
		add wave -noupdate -group {cl_oup_predwc[0]} {/pulp_tb/dut/cl_oup_predwc[0]/r_id}
		add wave -noupdate -group {cl_oup_predwc[0]} {/pulp_tb/dut/cl_oup_predwc[0]/r_data}
		add wave -noupdate -group {cl_oup_predwc[0]} {/pulp_tb/dut/cl_oup_predwc[0]/r_resp}
		add wave -noupdate -group {cl_oup_predwc[0]} {/pulp_tb/dut/cl_oup_predwc[0]/r_last}
		add wave -noupdate -group {cl_oup_predwc[0]} {/pulp_tb/dut/cl_oup_predwc[0]/r_user}
		add wave -noupdate -group {cl_oup_predwc[0]} {/pulp_tb/dut/cl_oup_predwc[0]/r_valid}
		add wave -noupdate -group {cl_oup_predwc[0]} {/pulp_tb/dut/cl_oup_predwc[0]/r_ready}
		add wave -noupdate -group {cl_oup_prepacker[0]} {/pulp_tb/dut/cl_oup_prepacker[0]/aw_id}
		add wave -noupdate -group {cl_oup_prepacker[0]} {/pulp_tb/dut/cl_oup_prepacker[0]/aw_addr}
		add wave -noupdate -group {cl_oup_prepacker[0]} {/pulp_tb/dut/cl_oup_prepacker[0]/aw_len}
		add wave -noupdate -group {cl_oup_prepacker[0]} {/pulp_tb/dut/cl_oup_prepacker[0]/aw_size}
		add wave -noupdate -group {cl_oup_prepacker[0]} {/pulp_tb/dut/cl_oup_prepacker[0]/aw_burst}
		add wave -noupdate -group {cl_oup_prepacker[0]} {/pulp_tb/dut/cl_oup_prepacker[0]/aw_lock}
		add wave -noupdate -group {cl_oup_prepacker[0]} {/pulp_tb/dut/cl_oup_prepacker[0]/aw_cache}
		add wave -noupdate -group {cl_oup_prepacker[0]} {/pulp_tb/dut/cl_oup_prepacker[0]/aw_prot}
		add wave -noupdate -group {cl_oup_prepacker[0]} {/pulp_tb/dut/cl_oup_prepacker[0]/aw_qos}
		add wave -noupdate -group {cl_oup_prepacker[0]} {/pulp_tb/dut/cl_oup_prepacker[0]/aw_region}
		add wave -noupdate -group {cl_oup_prepacker[0]} {/pulp_tb/dut/cl_oup_prepacker[0]/aw_atop}
		add wave -noupdate -group {cl_oup_prepacker[0]} {/pulp_tb/dut/cl_oup_prepacker[0]/aw_user}
		add wave -noupdate -group {cl_oup_prepacker[0]} {/pulp_tb/dut/cl_oup_prepacker[0]/aw_valid}
		add wave -noupdate -group {cl_oup_prepacker[0]} {/pulp_tb/dut/cl_oup_prepacker[0]/aw_ready}
		add wave -noupdate -group {cl_oup_prepacker[0]} {/pulp_tb/dut/cl_oup_prepacker[0]/w_data}
		add wave -noupdate -group {cl_oup_prepacker[0]} {/pulp_tb/dut/cl_oup_prepacker[0]/w_strb}
		add wave -noupdate -group {cl_oup_prepacker[0]} {/pulp_tb/dut/cl_oup_prepacker[0]/w_last}
		add wave -noupdate -group {cl_oup_prepacker[0]} {/pulp_tb/dut/cl_oup_prepacker[0]/w_user}
		add wave -noupdate -group {cl_oup_prepacker[0]} {/pulp_tb/dut/cl_oup_prepacker[0]/w_valid}
		add wave -noupdate -group {cl_oup_prepacker[0]} {/pulp_tb/dut/cl_oup_prepacker[0]/w_ready}
		add wave -noupdate -group {cl_oup_prepacker[0]} {/pulp_tb/dut/cl_oup_prepacker[0]/b_id}
		add wave -noupdate -group {cl_oup_prepacker[0]} {/pulp_tb/dut/cl_oup_prepacker[0]/b_resp}
		add wave -noupdate -group {cl_oup_prepacker[0]} {/pulp_tb/dut/cl_oup_prepacker[0]/b_user}
		add wave -noupdate -group {cl_oup_prepacker[0]} {/pulp_tb/dut/cl_oup_prepacker[0]/b_valid}
		add wave -noupdate -group {cl_oup_prepacker[0]} {/pulp_tb/dut/cl_oup_prepacker[0]/b_ready}
		add wave -noupdate -group {cl_oup_prepacker[0]} {/pulp_tb/dut/cl_oup_prepacker[0]/ar_id}
		add wave -noupdate -group {cl_oup_prepacker[0]} {/pulp_tb/dut/cl_oup_prepacker[0]/ar_addr}
		add wave -noupdate -group {cl_oup_prepacker[0]} {/pulp_tb/dut/cl_oup_prepacker[0]/ar_len}
		add wave -noupdate -group {cl_oup_prepacker[0]} {/pulp_tb/dut/cl_oup_prepacker[0]/ar_size}
		add wave -noupdate -group {cl_oup_prepacker[0]} {/pulp_tb/dut/cl_oup_prepacker[0]/ar_burst}
		add wave -noupdate -group {cl_oup_prepacker[0]} {/pulp_tb/dut/cl_oup_prepacker[0]/ar_lock}
		add wave -noupdate -group {cl_oup_prepacker[0]} {/pulp_tb/dut/cl_oup_prepacker[0]/ar_cache}
		add wave -noupdate -group {cl_oup_prepacker[0]} {/pulp_tb/dut/cl_oup_prepacker[0]/ar_prot}
		add wave -noupdate -group {cl_oup_prepacker[0]} {/pulp_tb/dut/cl_oup_prepacker[0]/ar_qos}
		add wave -noupdate -group {cl_oup_prepacker[0]} {/pulp_tb/dut/cl_oup_prepacker[0]/ar_region}
		add wave -noupdate -group {cl_oup_prepacker[0]} {/pulp_tb/dut/cl_oup_prepacker[0]/ar_user}
		add wave -noupdate -group {cl_oup_prepacker[0]} {/pulp_tb/dut/cl_oup_prepacker[0]/ar_valid}
		add wave -noupdate -group {cl_oup_prepacker[0]} {/pulp_tb/dut/cl_oup_prepacker[0]/ar_ready}
		add wave -noupdate -group {cl_oup_prepacker[0]} {/pulp_tb/dut/cl_oup_prepacker[0]/r_id}
		add wave -noupdate -group {cl_oup_prepacker[0]} {/pulp_tb/dut/cl_oup_prepacker[0]/r_data}
		add wave -noupdate -group {cl_oup_prepacker[0]} {/pulp_tb/dut/cl_oup_prepacker[0]/r_resp}
		add wave -noupdate -group {cl_oup_prepacker[0]} {/pulp_tb/dut/cl_oup_prepacker[0]/r_last}
		add wave -noupdate -group {cl_oup_prepacker[0]} {/pulp_tb/dut/cl_oup_prepacker[0]/r_user}
		add wave -noupdate -group {cl_oup_prepacker[0]} {/pulp_tb/dut/cl_oup_prepacker[0]/r_valid}
		add wave -noupdate -group {cl_oup_prepacker[0]} {/pulp_tb/dut/cl_oup_prepacker[0]/r_ready}
		add wave -noupdate -group {cl_oup[0]} {/pulp_tb/dut/cl_oup[0]/aw_id}
		add wave -noupdate -group {cl_oup[0]} {/pulp_tb/dut/cl_oup[0]/aw_addr}
		add wave -noupdate -group {cl_oup[0]} {/pulp_tb/dut/cl_oup[0]/aw_len}
		add wave -noupdate -group {cl_oup[0]} {/pulp_tb/dut/cl_oup[0]/aw_size}
		add wave -noupdate -group {cl_oup[0]} {/pulp_tb/dut/cl_oup[0]/aw_burst}
		add wave -noupdate -group {cl_oup[0]} {/pulp_tb/dut/cl_oup[0]/aw_lock}
		add wave -noupdate -group {cl_oup[0]} {/pulp_tb/dut/cl_oup[0]/aw_cache}
		add wave -noupdate -group {cl_oup[0]} {/pulp_tb/dut/cl_oup[0]/aw_prot}
		add wave -noupdate -group {cl_oup[0]} {/pulp_tb/dut/cl_oup[0]/aw_qos}
		add wave -noupdate -group {cl_oup[0]} {/pulp_tb/dut/cl_oup[0]/aw_region}
		add wave -noupdate -group {cl_oup[0]} {/pulp_tb/dut/cl_oup[0]/aw_atop}
		add wave -noupdate -group {cl_oup[0]} {/pulp_tb/dut/cl_oup[0]/aw_user}
		add wave -noupdate -group {cl_oup[0]} {/pulp_tb/dut/cl_oup[0]/aw_valid}
		add wave -noupdate -group {cl_oup[0]} {/pulp_tb/dut/cl_oup[0]/aw_ready}
		add wave -noupdate -group {cl_oup[0]} {/pulp_tb/dut/cl_oup[0]/w_data}
		add wave -noupdate -group {cl_oup[0]} {/pulp_tb/dut/cl_oup[0]/w_strb}
		add wave -noupdate -group {cl_oup[0]} {/pulp_tb/dut/cl_oup[0]/w_last}
		add wave -noupdate -group {cl_oup[0]} {/pulp_tb/dut/cl_oup[0]/w_user}
		add wave -noupdate -group {cl_oup[0]} {/pulp_tb/dut/cl_oup[0]/w_valid}
		add wave -noupdate -group {cl_oup[0]} {/pulp_tb/dut/cl_oup[0]/w_ready}
		add wave -noupdate -group {cl_oup[0]} {/pulp_tb/dut/cl_oup[0]/b_id}
		add wave -noupdate -group {cl_oup[0]} {/pulp_tb/dut/cl_oup[0]/b_resp}
		add wave -noupdate -group {cl_oup[0]} {/pulp_tb/dut/cl_oup[0]/b_user}
		add wave -noupdate -group {cl_oup[0]} {/pulp_tb/dut/cl_oup[0]/b_valid}
		add wave -noupdate -group {cl_oup[0]} {/pulp_tb/dut/cl_oup[0]/b_ready}
		add wave -noupdate -group {cl_oup[0]} {/pulp_tb/dut/cl_oup[0]/ar_id}
		add wave -noupdate -group {cl_oup[0]} {/pulp_tb/dut/cl_oup[0]/ar_addr}
		add wave -noupdate -group {cl_oup[0]} {/pulp_tb/dut/cl_oup[0]/ar_len}
		add wave -noupdate -group {cl_oup[0]} {/pulp_tb/dut/cl_oup[0]/ar_size}
		add wave -noupdate -group {cl_oup[0]} {/pulp_tb/dut/cl_oup[0]/ar_burst}
		add wave -noupdate -group {cl_oup[0]} {/pulp_tb/dut/cl_oup[0]/ar_lock}
		add wave -noupdate -group {cl_oup[0]} {/pulp_tb/dut/cl_oup[0]/ar_cache}
		add wave -noupdate -group {cl_oup[0]} {/pulp_tb/dut/cl_oup[0]/ar_prot}
		add wave -noupdate -group {cl_oup[0]} {/pulp_tb/dut/cl_oup[0]/ar_qos}
		add wave -noupdate -group {cl_oup[0]} {/pulp_tb/dut/cl_oup[0]/ar_region}
		add wave -noupdate -group {cl_oup[0]} {/pulp_tb/dut/cl_oup[0]/ar_user}
		add wave -noupdate -group {cl_oup[0]} {/pulp_tb/dut/cl_oup[0]/ar_valid}
		add wave -noupdate -group {cl_oup[0]} {/pulp_tb/dut/cl_oup[0]/ar_ready}
		add wave -noupdate -group {cl_oup[0]} {/pulp_tb/dut/cl_oup[0]/r_id}
		add wave -noupdate -group {cl_oup[0]} {/pulp_tb/dut/cl_oup[0]/r_data}
		add wave -noupdate -group {cl_oup[0]} {/pulp_tb/dut/cl_oup[0]/r_resp}
		add wave -noupdate -group {cl_oup[0]} {/pulp_tb/dut/cl_oup[0]/r_last}
		add wave -noupdate -group {cl_oup[0]} {/pulp_tb/dut/cl_oup[0]/r_user}
		add wave -noupdate -group {cl_oup[0]} {/pulp_tb/dut/cl_oup[0]/r_valid}
		add wave -noupdate -group {cl_oup[0]} {/pulp_tb/dut/cl_oup[0]/r_ready}
		add wave -noupdate -group {core_region[0][0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/clk_i}
		add wave -noupdate -group {core_region[0][0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/rst_ni}
		add wave -noupdate -group {core_region[0][0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/init_ni}
		add wave -noupdate -group {core_region[0][0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/base_addr_i}
		add wave -noupdate -group {core_region[0][0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/cluster_id_i}
		add wave -noupdate -group {core_region[0][0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/irq_req_i}
		add wave -noupdate -group {core_region[0][0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/irq_ack_o}
		add wave -noupdate -group {core_region[0][0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/irq_id_i}
		add wave -noupdate -group {core_region[0][0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/irq_ack_id_o}
		add wave -noupdate -group {core_region[0][0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/clock_en_i}
		add wave -noupdate -group {core_region[0][0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/fetch_en_i}
		add wave -noupdate -group {core_region[0][0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/fregfile_disable_i}
		add wave -noupdate -group {core_region[0][0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/boot_addr_i}
		add wave -noupdate -group {core_region[0][0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/test_mode_i}
		add wave -noupdate -group {core_region[0][0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_busy_o}
		add wave -noupdate -group {core_region[0][0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/instr_req_o}
		add wave -noupdate -group {core_region[0][0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/instr_gnt_i}
		add wave -noupdate -group {core_region[0][0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/instr_addr_o}
		add wave -noupdate -group {core_region[0][0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/instr_r_rdata_i}
		add wave -noupdate -group {core_region[0][0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/instr_r_valid_i}
		add wave -noupdate -group {core_region[0][0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/debug_req_i}
		add wave -noupdate -group {core_region[0][0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/periph_data_master_atop}
		add wave -noupdate -group {core_region[0][0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/perf_counters}
		add wave -noupdate -group {core_region[0][0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/clk_int}
		add wave -noupdate -group {core_region[0][0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/FILE}
		add wave -noupdate -group {core_region[0][0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/instr_gnt_L2}
		add wave -noupdate -group {core_region[0][0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/instr_gnt_ROM}
		add wave -noupdate -group {core_region[0][0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/instr_r_rdata_ROM}
		add wave -noupdate -group {core_region[0][0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/instr_r_valid_ROM}
		add wave -noupdate -group {core_region[0][0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/instr_r_rdata_L2}
		add wave -noupdate -group {core_region[0][0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/instr_r_valid_L2}
		add wave -noupdate -group {core_region[0][0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/destination}
		add wave -noupdate -group {core_region[0][0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/reg_cache_refill}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/clk}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/rst_n}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/test_en_i}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/fetch_req_i}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/fetch_addr_i}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/fetch_gnt_o}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/fetch_rvalid_o}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/fetch_rdata_o}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_arid_o}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_araddr_o}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_arlen_o}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_arsize_o}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_arburst_o}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_arlock_o}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_arcache_o}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_arprot_o}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_arregion_o}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_aruser_o}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_arqos_o}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_arvalid_o}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_arready_i}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_rid_i}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_rdata_i}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_rresp_i}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_rlast_i}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_ruser_i}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_rvalid_i}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_rready_o}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_awid_o}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_awaddr_o}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_awlen_o}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_awsize_o}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_awburst_o}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_awlock_o}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_awcache_o}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_awprot_o}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_awregion_o}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_awuser_o}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_awqos_o}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_awvalid_o}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_awready_i}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_wdata_o}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_wstrb_o}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_wlast_o}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_wuser_o}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_wvalid_o}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_wready_i}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_bid_i}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_bresp_i}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_buser_i}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_bvalid_i}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_bready_o}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/DATA_read_req_int}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/DATA_read_addr_int}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/TAG_read_req_int}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/TAG_read_addr_int}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/TAG_read_rdata_int}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/SCM_TAG_write_req_int}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/SCM_TAG_write_addr_int}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/SCM_TAG_write_dest_int}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/SCM_TAG_write_wdata_int}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/SCM_TAG_write_way_int}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/SCM_DATA_write_req_int}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/SCM_DATA_write_addr_int}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/SCM_DATA_write_dest_int}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/SCM_DATA_write_wdata_int}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/SCM_DATA_write_way_int}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/TAG_ReadEnable}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/DATA_ReadEnable}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/TAG_ReadData}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/notify_refill_done}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/fetch_way_int}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/fetch_req_int}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/fetch_addr_int}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/fetch_gnt_int}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/fetch_rvalid_int}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/fetch_rdata_int}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/SCM_TAG_write_dest_OH_int}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/SCM_DATA_write_dest_OH_int}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/cache_is_bypassed}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/retry_fetch}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/bypass_icache}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/empty_fifo}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/flush_icache}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/flush_ack}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/sel_flush_req}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/sel_flush_addr}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/sel_flush_ack}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_arid_int}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_araddr_int}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_arlen_int}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_arsize_int}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_arburst_int}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_arlock_int}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_arcache_int}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_arprot_int}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_arregion_int}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_aruser_int}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_arqos_int}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_arvalid_int}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_arready_int}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_rid_int}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_rdata_int}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_rresp_int}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_rlast_int}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_ruser_int}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_rvalid_int}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/axi_master_rready_int}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/pf_req_to_cc}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/pf_addr_to_cc}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/pf_gnt_from_cc}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/pf_rvalid_from_cc}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/pf_req_to_master_cc}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/pf_addr_to_master_cc}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/pf_way_to_master_cc}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/pf_gnt_from_master_cc}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/pf_rvalid_from_master_cc}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/total_hit_count}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/total_trans_count}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/total_miss_count}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/bank_hit_count}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/bank_trans_count}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/bank_miss_count}
		add wave -noupdate -group {icache[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/icache_top_i/index}
		add wave -noupdate -group {core_region[0][1]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[1]/core_region_i/clk_i}
		add wave -noupdate -group {core_region[0][1]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[1]/core_region_i/rst_ni}
		add wave -noupdate -group {core_region[0][1]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[1]/core_region_i/init_ni}
		add wave -noupdate -group {core_region[0][1]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[1]/core_region_i/base_addr_i}
		add wave -noupdate -group {core_region[0][1]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[1]/core_region_i/cluster_id_i}
		add wave -noupdate -group {core_region[0][1]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[1]/core_region_i/irq_req_i}
		add wave -noupdate -group {core_region[0][1]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[1]/core_region_i/irq_ack_o}
		add wave -noupdate -group {core_region[0][1]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[1]/core_region_i/irq_id_i}
		add wave -noupdate -group {core_region[0][1]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[1]/core_region_i/irq_ack_id_o}
		add wave -noupdate -group {core_region[0][1]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[1]/core_region_i/clock_en_i}
		add wave -noupdate -group {core_region[0][1]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[1]/core_region_i/fetch_en_i}
		add wave -noupdate -group {core_region[0][1]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[1]/core_region_i/fregfile_disable_i}
		add wave -noupdate -group {core_region[0][1]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[1]/core_region_i/boot_addr_i}
		add wave -noupdate -group {core_region[0][1]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[1]/core_region_i/test_mode_i}
		add wave -noupdate -group {core_region[0][1]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[1]/core_region_i/core_busy_o}
		add wave -noupdate -group {core_region[0][1]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[1]/core_region_i/instr_req_o}
		add wave -noupdate -group {core_region[0][1]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[1]/core_region_i/instr_gnt_i}
		add wave -noupdate -group {core_region[0][1]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[1]/core_region_i/instr_addr_o}
		add wave -noupdate -group {core_region[0][1]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[1]/core_region_i/instr_r_rdata_i}
		add wave -noupdate -group {core_region[0][1]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[1]/core_region_i/instr_r_valid_i}
		add wave -noupdate -group {core_region[0][0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/debug_req_i}
		add wave -noupdate -group {core_region[0][1]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[1]/core_region_i/periph_data_master_atop}
		add wave -noupdate -group {core_region[0][1]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[1]/core_region_i/perf_counters}
		add wave -noupdate -group {core_region[0][1]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[1]/core_region_i/clk_int}
		add wave -noupdate -group {core_region[0][1]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[1]/core_region_i/FILE}
		add wave -noupdate -group {core_region[0][1]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[1]/core_region_i/instr_gnt_L2}
		add wave -noupdate -group {core_region[0][1]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[1]/core_region_i/instr_gnt_ROM}
		add wave -noupdate -group {core_region[0][1]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[1]/core_region_i/instr_r_rdata_ROM}
		add wave -noupdate -group {core_region[0][1]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[1]/core_region_i/instr_r_valid_ROM}
		add wave -noupdate -group {core_region[0][1]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[1]/core_region_i/instr_r_rdata_L2}
		add wave -noupdate -group {core_region[0][1]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[1]/core_region_i/instr_r_valid_L2}
		add wave -noupdate -group {core_region[0][1]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[1]/core_region_i/destination}
		add wave -noupdate -group {core_region[0][1]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[1]/core_region_i/reg_cache_refill}
		add wave -noupdate -group {cl_oup_async[0]} {/pulp_tb/dut/cl_oup_async[0]/aw_id}
		add wave -noupdate -group {cl_oup_async[0]} {/pulp_tb/dut/cl_oup_async[0]/aw_addr}
		add wave -noupdate -group {cl_oup_async[0]} {/pulp_tb/dut/cl_oup_async[0]/aw_len}
		add wave -noupdate -group {cl_oup_async[0]} {/pulp_tb/dut/cl_oup_async[0]/aw_size}
		add wave -noupdate -group {cl_oup_async[0]} {/pulp_tb/dut/cl_oup_async[0]/aw_burst}
		add wave -noupdate -group {cl_oup_async[0]} {/pulp_tb/dut/cl_oup_async[0]/aw_lock}
		add wave -noupdate -group {cl_oup_async[0]} {/pulp_tb/dut/cl_oup_async[0]/aw_cache}
		add wave -noupdate -group {cl_oup_async[0]} {/pulp_tb/dut/cl_oup_async[0]/aw_prot}
		add wave -noupdate -group {cl_oup_async[0]} {/pulp_tb/dut/cl_oup_async[0]/aw_qos}
		add wave -noupdate -group {cl_oup_async[0]} {/pulp_tb/dut/cl_oup_async[0]/aw_region}
		add wave -noupdate -group {cl_oup_async[0]} {/pulp_tb/dut/cl_oup_async[0]/aw_atop}
		add wave -noupdate -group {cl_oup_async[0]} {/pulp_tb/dut/cl_oup_async[0]/aw_user}
		add wave -noupdate -group {cl_oup_async[0]} {/pulp_tb/dut/cl_oup_async[0]/aw_writetoken}
		add wave -noupdate -group {cl_oup_async[0]} {/pulp_tb/dut/cl_oup_async[0]/aw_readpointer}
		add wave -noupdate -group {cl_oup_async[0]} {/pulp_tb/dut/cl_oup_async[0]/w_data}
		add wave -noupdate -group {cl_oup_async[0]} {/pulp_tb/dut/cl_oup_async[0]/w_strb}
		add wave -noupdate -group {cl_oup_async[0]} {/pulp_tb/dut/cl_oup_async[0]/w_last}
		add wave -noupdate -group {cl_oup_async[0]} {/pulp_tb/dut/cl_oup_async[0]/w_user}
		add wave -noupdate -group {cl_oup_async[0]} {/pulp_tb/dut/cl_oup_async[0]/w_writetoken}
		add wave -noupdate -group {cl_oup_async[0]} {/pulp_tb/dut/cl_oup_async[0]/w_readpointer}
		add wave -noupdate -group {cl_oup_async[0]} {/pulp_tb/dut/cl_oup_async[0]/b_id}
		add wave -noupdate -group {cl_oup_async[0]} {/pulp_tb/dut/cl_oup_async[0]/b_resp}
		add wave -noupdate -group {cl_oup_async[0]} {/pulp_tb/dut/cl_oup_async[0]/b_user}
		add wave -noupdate -group {cl_oup_async[0]} {/pulp_tb/dut/cl_oup_async[0]/b_writetoken}
		add wave -noupdate -group {cl_oup_async[0]} {/pulp_tb/dut/cl_oup_async[0]/b_readpointer}
		add wave -noupdate -group {cl_oup_async[0]} {/pulp_tb/dut/cl_oup_async[0]/ar_id}
		add wave -noupdate -group {cl_oup_async[0]} {/pulp_tb/dut/cl_oup_async[0]/ar_addr}
		add wave -noupdate -group {cl_oup_async[0]} {/pulp_tb/dut/cl_oup_async[0]/ar_len}
		add wave -noupdate -group {cl_oup_async[0]} {/pulp_tb/dut/cl_oup_async[0]/ar_size}
		add wave -noupdate -group {cl_oup_async[0]} {/pulp_tb/dut/cl_oup_async[0]/ar_burst}
		add wave -noupdate -group {cl_oup_async[0]} {/pulp_tb/dut/cl_oup_async[0]/ar_lock}
		add wave -noupdate -group {cl_oup_async[0]} {/pulp_tb/dut/cl_oup_async[0]/ar_cache}
		add wave -noupdate -group {cl_oup_async[0]} {/pulp_tb/dut/cl_oup_async[0]/ar_prot}
		add wave -noupdate -group {cl_oup_async[0]} {/pulp_tb/dut/cl_oup_async[0]/ar_qos}
		add wave -noupdate -group {cl_oup_async[0]} {/pulp_tb/dut/cl_oup_async[0]/ar_region}
		add wave -noupdate -group {cl_oup_async[0]} {/pulp_tb/dut/cl_oup_async[0]/ar_user}
		add wave -noupdate -group {cl_oup_async[0]} {/pulp_tb/dut/cl_oup_async[0]/ar_writetoken}
		add wave -noupdate -group {cl_oup_async[0]} {/pulp_tb/dut/cl_oup_async[0]/ar_readpointer}
		add wave -noupdate -group {cl_oup_async[0]} {/pulp_tb/dut/cl_oup_async[0]/r_id}
		add wave -noupdate -group {cl_oup_async[0]} {/pulp_tb/dut/cl_oup_async[0]/r_data}
		add wave -noupdate -group {cl_oup_async[0]} {/pulp_tb/dut/cl_oup_async[0]/r_resp}
		add wave -noupdate -group {cl_oup_async[0]} {/pulp_tb/dut/cl_oup_async[0]/r_last}
		add wave -noupdate -group {cl_oup_async[0]} {/pulp_tb/dut/cl_oup_async[0]/r_user}
		add wave -noupdate -group {cl_oup_async[0]} {/pulp_tb/dut/cl_oup_async[0]/r_writetoken}
		add wave -noupdate -group {cl_oup_async[0]} {/pulp_tb/dut/cl_oup_async[0]/r_readpointer}
		add wave -noupdate -group {core[0][0]/lsu} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/load_store_unit_i/data_req_o}
		add wave -noupdate -group {core[0][0]/lsu} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/load_store_unit_i/data_gnt_i}
		add wave -noupdate -group {core[0][0]/lsu} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/load_store_unit_i/data_addr_o}
		add wave -noupdate -group {core[0][0]/lsu} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/load_store_unit_i/data_we_o}
		add wave -noupdate -group {core[0][0]/lsu} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/load_store_unit_i/data_be_o}
		add wave -noupdate -group {core[0][0]/lsu} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/load_store_unit_i/data_wdata_o}
		add wave -noupdate -group {core[0][0]/lsu} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/load_store_unit_i/data_rvalid_i}
		add wave -noupdate -group {core[0][0]/lsu} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/load_store_unit_i/data_rdata_i}
		add wave -noupdate -group {core[0][0]/lsu} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/load_store_unit_i/data_err_i}
		add wave -noupdate -group {core[0][0]/lsu} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/load_store_unit_i/data_we_ex_i}
		add wave -noupdate -group {core[0][0]/lsu} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/load_store_unit_i/data_type_ex_i}
		add wave -noupdate -group {core[0][0]/lsu} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/load_store_unit_i/data_wdata_ex_i}
		add wave -noupdate -group {core[0][0]/lsu} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/load_store_unit_i/data_reg_offset_ex_i}
		add wave -noupdate -group {core[0][0]/lsu} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/load_store_unit_i/data_sign_ext_ex_i}
		add wave -noupdate -group {core[0][0]/lsu} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/load_store_unit_i/data_req_ex_i}
		add wave -noupdate -group {core[0][0]/lsu} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/load_store_unit_i/data_rdata_ex_o}
		add wave -noupdate -group {core[0][0]/lsu} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/load_store_unit_i/operand_a_ex_i}
		add wave -noupdate -group {core[0][0]/lsu} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/load_store_unit_i/operand_b_ex_i}
		add wave -noupdate -group {core[0][0]/lsu} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/load_store_unit_i/addr_useincr_ex_i}
		add wave -noupdate -group {core[0][0]/lsu} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/load_store_unit_i/data_misaligned_ex_i}
		add wave -noupdate -group {core[0][0]/lsu} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/load_store_unit_i/data_misaligned_o}
		add wave -noupdate -group {core[0][0]/lsu} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/load_store_unit_i/data_atop_ex_i}
		add wave -noupdate -group {core[0][0]/lsu} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/load_store_unit_i/data_atop_o}
		add wave -noupdate -group {core[0][0]/lsu} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/load_store_unit_i/lsu_ready_ex_o}
		add wave -noupdate -group {core[0][0]/lsu} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/load_store_unit_i/lsu_ready_wb_o}
		add wave -noupdate -group {core[0][0]/lsu} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/load_store_unit_i/ex_valid_i}
		add wave -noupdate -group {core[0][0]/lsu} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/load_store_unit_i/busy_o}
		add wave -noupdate -group {core[0][0]/lsu} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/load_store_unit_i/shamt}
		add wave -noupdate -group {core[0][0]/lsu} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/load_store_unit_i/shamt_q}
		add wave -noupdate -group {core[0][0]/lsu} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/load_store_unit_i/type_q}
		add wave -noupdate -group {core[0][0]/lsu} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/load_store_unit_i/sign_ext_q}
		add wave -noupdate -group {core[0][0]/lsu} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/load_store_unit_i/we_q}
		add wave -noupdate -group {core[0][0]/lsu} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/load_store_unit_i/rdata_d}
		add wave -noupdate -group {core[0][0]/lsu} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/load_store_unit_i/rdata_q}
		add wave -noupdate -group {core[0][0]/lsu} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/load_store_unit_i/stack_access_i}
		add wave -noupdate -group {core[0][0]/lsu} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/load_store_unit_i/stack_base_i}
		add wave -noupdate -group {core[0][0]/lsu} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/load_store_unit_i/stack_limit_i}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/clk}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/rst_ni}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/test_en_i}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/base_addr_i}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/data_req_i}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/data_gnt_o}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/data_add_i}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/data_wen_i}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/data_atop_i}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/data_wdata_i}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/data_be_i}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/data_r_gnt_i}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/data_r_valid_o}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/data_r_rdata_o}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/data_r_opc_o}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/data_req_o_SH}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/data_add_o_SH}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/data_wen_o_SH}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/data_wdata_o_SH}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/data_be_o_SH}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/data_gnt_i_SH}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/data_r_valid_i_SH}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/data_r_rdata_i_SH}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/data_req_o_EXT}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/data_add_o_EXT}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/data_wen_o_EXT}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/data_wdata_o_EXT}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/data_be_o_EXT}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/data_gnt_i_EXT}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/data_r_valid_i_EXT}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/data_r_rdata_i_EXT}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/data_r_opc_i_EXT}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/data_req_o_PE}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/data_add_o_PE}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/data_wen_o_PE}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/data_atop_o_PE}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/data_wdata_o_PE}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/data_be_o_PE}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/data_gnt_i_PE}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/data_r_valid_i_PE}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/data_r_opc_i_PE}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/data_r_rdata_i_PE}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/perf_l2_ld_o}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/perf_l2_st_o}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/perf_l2_ld_cyc_o}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/perf_l2_st_cyc_o}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/CLUSTER_ID}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/CLUSTER_ALIAS_BASE_11}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/CLUSTER_ALIAS_BASE_12}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/s_data_req_PE}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/s_data_gnt_PE}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/s_data_r_data_PE}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/s_data_r_valid_PE}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/s_data_r_opc_PE}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/s_data_r_data_PE_0}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/s_data_r_valid_PE_0}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/s_data_r_opc_PE_0}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/CS}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/NS}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/data_req_to_L2}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/data_add_to_L2}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/data_wen_to_L2}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/data_wdata_to_L2}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/data_be_to_L2}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/data_gnt_from_L2}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/request_destination}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/destination}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/data_add_int}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/data_busy_PE_fifo}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/data_req_PE_fifo}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/data_add_PE_fifo}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/data_wen_PE_fifo}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/data_atop_PE_fifo}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/data_wdata_PE_fifo}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/data_be_PE_fifo}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/data_gnt_PE_fifo}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/data_r_valid_PE_fifo}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/data_r_opc_PE_fifo}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/data_r_rdata_PE_fifo}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/TCDM_RW}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/TCDM_TS}
		add wave -noupdate -group {core_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/core_demux_i/DEM_PER}
		add wave -noupdate -group {eu_ctrl_master[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/eu_ctrl_master/req}
		add wave -noupdate -group {eu_ctrl_master[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/eu_ctrl_master/add}
		add wave -noupdate -group {eu_ctrl_master[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/eu_ctrl_master/wen}
		add wave -noupdate -group {eu_ctrl_master[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/eu_ctrl_master/wdata}
		add wave -noupdate -group {eu_ctrl_master[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/eu_ctrl_master/be}
		add wave -noupdate -group {eu_ctrl_master[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/eu_ctrl_master/gnt}
		add wave -noupdate -group {eu_ctrl_master[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/eu_ctrl_master/id}
		add wave -noupdate -group {eu_ctrl_master[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/eu_ctrl_master/r_valid}
		add wave -noupdate -group {eu_ctrl_master[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/eu_ctrl_master/r_opc}
		add wave -noupdate -group {eu_ctrl_master[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/eu_ctrl_master/r_id}
		add wave -noupdate -group {eu_ctrl_master[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/eu_ctrl_master/r_rdata}
		add wave -noupdate -group {periph_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/periph_demux_i/clk}
		add wave -noupdate -group {periph_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/periph_demux_i/rst_ni}
		add wave -noupdate -group {periph_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/periph_demux_i/data_req_i}
		add wave -noupdate -group {periph_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/periph_demux_i/data_add_i}
		add wave -noupdate -group {periph_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/periph_demux_i/data_wen_i}
		add wave -noupdate -group {periph_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/periph_demux_i/data_wdata_i}
		add wave -noupdate -group {periph_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/periph_demux_i/data_be_i}
		add wave -noupdate -group {periph_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/periph_demux_i/data_gnt_o}
		add wave -noupdate -group {periph_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/periph_demux_i/data_r_valid_o}
		add wave -noupdate -group {periph_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/periph_demux_i/data_r_rdata_o}
		add wave -noupdate -group {periph_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/periph_demux_i/data_r_opc_o}
		add wave -noupdate -group {periph_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/periph_demux_i/data_req_o_MH}
		add wave -noupdate -group {periph_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/periph_demux_i/data_add_o_MH}
		add wave -noupdate -group {periph_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/periph_demux_i/data_wen_o_MH}
		add wave -noupdate -group {periph_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/periph_demux_i/data_wdata_o_MH}
		add wave -noupdate -group {periph_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/periph_demux_i/data_be_o_MH}
		add wave -noupdate -group {periph_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/periph_demux_i/data_gnt_i_MH}
		add wave -noupdate -group {periph_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/periph_demux_i/data_r_valid_i_MH}
		add wave -noupdate -group {periph_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/periph_demux_i/data_r_rdata_i_MH}
		add wave -noupdate -group {periph_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/periph_demux_i/data_r_opc_i_MH}
		add wave -noupdate -group {periph_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/periph_demux_i/data_req_o_EU}
		add wave -noupdate -group {periph_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/periph_demux_i/data_add_o_EU}
		add wave -noupdate -group {periph_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/periph_demux_i/data_wen_o_EU}
		add wave -noupdate -group {periph_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/periph_demux_i/data_wdata_o_EU}
		add wave -noupdate -group {periph_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/periph_demux_i/data_be_o_EU}
		add wave -noupdate -group {periph_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/periph_demux_i/data_gnt_i_EU}
		add wave -noupdate -group {periph_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/periph_demux_i/data_r_valid_i_EU}
		add wave -noupdate -group {periph_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/periph_demux_i/data_r_rdata_i_EU}
		add wave -noupdate -group {periph_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/periph_demux_i/data_r_opc_i_EU}
		add wave -noupdate -group {periph_demux[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/periph_demux_i/request_destination}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/clk}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/rst_n}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/test_en_i}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/fregfile_disable_i}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/fetch_enable_i}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/ctrl_busy_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/core_ctrl_firstfetch_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/is_decoding_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/hwlp_dec_cnt_i}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/is_hwlp_i}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/instr_valid_i}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/instr_rdata_i}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/instr_req_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/branch_in_ex_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/branch_decision_i}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/jump_target_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/clear_instr_valid_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/pc_set_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/pc_mux_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/exc_pc_mux_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/trap_addr_mux_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/illegal_c_insn_i}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/is_compressed_i}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/pc_if_i}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/pc_id_i}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/halt_if_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/id_ready_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/ex_ready_i}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/wb_ready_i}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/id_valid_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/ex_valid_i}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/pc_ex_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/alu_operand_a_ex_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/alu_operand_b_ex_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/alu_operand_c_ex_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/bmask_a_ex_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/bmask_b_ex_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/imm_vec_ext_ex_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/alu_vec_mode_ex_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/regfile_waddr_ex_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/regfile_we_ex_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/regfile_alu_waddr_ex_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/regfile_alu_we_ex_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/alu_en_ex_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/alu_operator_ex_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/mult_operator_ex_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/mult_operand_a_ex_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/mult_operand_b_ex_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/mult_operand_c_ex_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/mult_en_ex_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/mult_sel_subword_ex_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/mult_signed_mode_ex_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/mult_imm_ex_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/mult_dot_op_a_ex_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/mult_dot_op_b_ex_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/mult_dot_op_c_ex_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/mult_dot_signed_ex_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/mult_is_clpx_ex_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/mult_clpx_shift_ex_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/mult_clpx_img_ex_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/apu_en_ex_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/apu_type_ex_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/apu_op_ex_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/apu_lat_ex_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/apu_flags_ex_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/apu_waddr_ex_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/apu_read_regs_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/apu_read_regs_valid_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/apu_read_dep_i}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/apu_write_regs_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/apu_write_regs_valid_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/apu_write_dep_i}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/apu_perf_dep_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/apu_busy_i}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/frm_i}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/csr_access_ex_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/csr_op_ex_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/current_priv_lvl_i}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/csr_irq_sec_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/csr_cause_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/csr_save_if_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/csr_save_id_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/csr_restore_mret_id_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/csr_restore_uret_id_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/csr_save_cause_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/hwlp_start_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/hwlp_end_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/hwlp_cnt_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/csr_hwlp_regid_i}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/csr_hwlp_we_i}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/csr_hwlp_data_i}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/data_req_ex_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/data_we_ex_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/data_type_ex_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/data_sign_ext_ex_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/data_reg_offset_ex_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/data_load_event_ex_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/data_misaligned_ex_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/prepost_useincr_ex_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/data_misaligned_i}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/atop_ex_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/irq_i}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/irq_sec_i}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/irq_id_i}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/m_irq_enable_i}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/u_irq_enable_i}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/irq_ack_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/irq_id_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/exc_cause_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/debug_mode_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/debug_cause_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/debug_csr_save_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/debug_req_i}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/debug_single_step_i}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/debug_ebreakm_i}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/debug_ebreaku_i}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/regfile_waddr_wb_i}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/regfile_we_wb_i}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/regfile_wdata_wb_i}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/regfile_alu_waddr_fw_i}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/regfile_alu_we_fw_i}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/regfile_alu_wdata_fw_i}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/mult_multicycle_i}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/perf_jump_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/perf_jr_stall_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/perf_ld_stall_o}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/instr}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/deassert_we}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/illegal_insn_dec}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/ebrk_insn}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/mret_insn_dec}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/uret_insn_dec}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/ecall_insn_dec}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/pipe_flush_dec}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/rega_used_dec}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/regb_used_dec}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/regc_used_dec}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/branch_taken_ex}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/jump_in_id}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/jump_in_dec}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/misaligned_stall}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/jr_stall}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/load_stall}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/csr_apu_stall}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/halt_id}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/imm_i_type}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/imm_iz_type}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/imm_s_type}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/imm_sb_type}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/imm_u_type}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/imm_uj_type}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/imm_z_type}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/imm_s2_type}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/imm_bi_type}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/imm_s3_type}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/imm_vs_type}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/imm_vu_type}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/imm_shuffleb_type}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/imm_shuffleh_type}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/imm_shuffle_type}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/imm_clip_type}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/imm_a}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/imm_b}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/jump_target}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/irq_req_ctrl}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/irq_sec_ctrl}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/irq_id_ctrl}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/exc_ack}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/exc_kill}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/regfile_addr_ra_id}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/regfile_addr_rb_id}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/regfile_addr_rc_id}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/regfile_fp_a}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/regfile_fp_b}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/regfile_fp_c}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/regfile_fp_d}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/regfile_waddr_id}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/regfile_alu_waddr_id}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/regfile_alu_we_id}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/regfile_data_ra_id}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/regfile_data_rb_id}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/regfile_data_rc_id}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/alu_en}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/alu_operator}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/alu_op_a_mux_sel}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/alu_op_b_mux_sel}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/alu_op_c_mux_sel}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/regc_mux}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/imm_a_mux_sel}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/imm_b_mux_sel}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/jump_target_mux_sel}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/mult_operator}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/mult_en}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/mult_int_en}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/mult_sel_subword}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/mult_signed_mode}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/mult_dot_en}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/mult_dot_signed}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/fpu_src_fmt}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/fpu_dst_fmt}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/fpu_int_fmt}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/apu_en}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/apu_type}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/apu_op}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/apu_lat}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/apu_flags}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/apu_waddr}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/apu_read_regs}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/apu_read_regs_valid}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/apu_write_regs}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/apu_write_regs_valid}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/apu_flags_src}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/apu_stall}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/fp_rnd_mode}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/regfile_we_id}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/regfile_alu_waddr_mux_sel}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/data_we_id}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/data_type_id}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/data_sign_ext_id}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/data_reg_offset_id}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/data_req_id}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/data_load_event_id}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/atop_id}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/hwloop_regid}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/hwloop_regid_int}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/hwloop_we}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/hwloop_we_int}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/hwloop_target_mux_sel}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/hwloop_start_mux_sel}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/hwloop_cnt_mux_sel}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/hwloop_target}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/hwloop_start}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/hwloop_start_int}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/hwloop_end}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/hwloop_cnt}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/hwloop_cnt_int}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/hwloop_valid}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/csr_access}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/csr_op}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/csr_status}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/prepost_useincr}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/operand_a_fw_mux_sel}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/operand_b_fw_mux_sel}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/operand_c_fw_mux_sel}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/operand_a_fw_id}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/operand_b_fw_id}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/operand_c_fw_id}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/operand_b}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/operand_b_vec}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/alu_operand_a}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/alu_operand_b}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/alu_operand_c}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/bmask_a_mux}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/bmask_b_mux}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/alu_bmask_a_mux_sel}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/alu_bmask_b_mux_sel}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/mult_imm_mux}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/bmask_a_id_imm}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/bmask_b_id_imm}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/bmask_a_id}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/bmask_b_id}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/imm_vec_ext_id}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/mult_imm_id}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/alu_vec_mode}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/scalar_replication}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/reg_d_ex_is_reg_a_id}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/reg_d_ex_is_reg_b_id}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/reg_d_ex_is_reg_c_id}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/reg_d_wb_is_reg_a_id}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/reg_d_wb_is_reg_b_id}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/reg_d_wb_is_reg_c_id}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/reg_d_alu_is_reg_a_id}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/reg_d_alu_is_reg_b_id}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/reg_d_alu_is_reg_c_id}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/opcode}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/funct3}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} -radix unsigned {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/rd}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} -radix unsigned {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/rs1}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} -radix unsigned {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/rs2}
		add wave -noupdate -group -group {core[0][0]} -group {id_stage} -group {tobeclassified} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/stack_access_o}
		add wave -noupdate -group {core[0][0]} -group {id_stage} -group {controller} -label {ctrl_fsm_cs} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/controller_i/ctrl_fsm_cs}
		add wave -noupdate -group {core[0][0]} -group {id_stage} -group {controller} -label {ctrl_fsm_ns} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/CORE[0]/core_region_i/RISCV_CORE/id_stage_i/controller_i/ctrl_fsm_ns}
		add wave -noupdate -group periph_mst /pulp_tb/dut/periph_mst/aw_id
		add wave -noupdate -group periph_mst /pulp_tb/dut/periph_mst/aw_addr
		add wave -noupdate -group periph_mst /pulp_tb/dut/periph_mst/aw_len
		add wave -noupdate -group periph_mst /pulp_tb/dut/periph_mst/aw_size
		add wave -noupdate -group periph_mst /pulp_tb/dut/periph_mst/aw_burst
		add wave -noupdate -group periph_mst /pulp_tb/dut/periph_mst/aw_lock
		add wave -noupdate -group periph_mst /pulp_tb/dut/periph_mst/aw_cache
		add wave -noupdate -group periph_mst /pulp_tb/dut/periph_mst/aw_prot
		add wave -noupdate -group periph_mst /pulp_tb/dut/periph_mst/aw_qos
		add wave -noupdate -group periph_mst /pulp_tb/dut/periph_mst/aw_region
		add wave -noupdate -group periph_mst /pulp_tb/dut/periph_mst/aw_atop
		add wave -noupdate -group periph_mst /pulp_tb/dut/periph_mst/aw_user
		add wave -noupdate -group periph_mst /pulp_tb/dut/periph_mst/aw_valid
		add wave -noupdate -group periph_mst /pulp_tb/dut/periph_mst/aw_ready
		add wave -noupdate -group periph_mst /pulp_tb/dut/periph_mst/w_data
		add wave -noupdate -group periph_mst /pulp_tb/dut/periph_mst/w_strb
		add wave -noupdate -group periph_mst /pulp_tb/dut/periph_mst/w_last
		add wave -noupdate -group periph_mst /pulp_tb/dut/periph_mst/w_user
		add wave -noupdate -group periph_mst /pulp_tb/dut/periph_mst/w_valid
		add wave -noupdate -group periph_mst /pulp_tb/dut/periph_mst/w_ready
		add wave -noupdate -group periph_mst /pulp_tb/dut/periph_mst/b_id
		add wave -noupdate -group periph_mst /pulp_tb/dut/periph_mst/b_resp
		add wave -noupdate -group periph_mst /pulp_tb/dut/periph_mst/b_user
		add wave -noupdate -group periph_mst /pulp_tb/dut/periph_mst/b_valid
		add wave -noupdate -group periph_mst /pulp_tb/dut/periph_mst/b_ready
		add wave -noupdate -group periph_mst /pulp_tb/dut/periph_mst/ar_id
		add wave -noupdate -group periph_mst /pulp_tb/dut/periph_mst/ar_addr
		add wave -noupdate -group periph_mst /pulp_tb/dut/periph_mst/ar_len
		add wave -noupdate -group periph_mst /pulp_tb/dut/periph_mst/ar_size
		add wave -noupdate -group periph_mst /pulp_tb/dut/periph_mst/ar_burst
		add wave -noupdate -group periph_mst /pulp_tb/dut/periph_mst/ar_lock
		add wave -noupdate -group periph_mst /pulp_tb/dut/periph_mst/ar_cache
		add wave -noupdate -group periph_mst /pulp_tb/dut/periph_mst/ar_prot
		add wave -noupdate -group periph_mst /pulp_tb/dut/periph_mst/ar_qos
		add wave -noupdate -group periph_mst /pulp_tb/dut/periph_mst/ar_region
		add wave -noupdate -group periph_mst /pulp_tb/dut/periph_mst/ar_user
		add wave -noupdate -group periph_mst /pulp_tb/dut/periph_mst/ar_valid
		add wave -noupdate -group periph_mst /pulp_tb/dut/periph_mst/ar_ready
		add wave -noupdate -group periph_mst /pulp_tb/dut/periph_mst/r_id
		add wave -noupdate -group periph_mst /pulp_tb/dut/periph_mst/r_data
		add wave -noupdate -group periph_mst /pulp_tb/dut/periph_mst/r_resp
		add wave -noupdate -group periph_mst /pulp_tb/dut/periph_mst/r_last
		add wave -noupdate -group periph_mst /pulp_tb/dut/periph_mst/r_user
		add wave -noupdate -group periph_mst /pulp_tb/dut/periph_mst/r_valid
		add wave -noupdate -group periph_mst /pulp_tb/dut/periph_mst/r_ready
		add wave -noupdate -group soc_periphs/axi /pulp_tb/dut/i_periphs/axi/aw_id
		add wave -noupdate -group soc_periphs/axi /pulp_tb/dut/i_periphs/axi/aw_addr
		add wave -noupdate -group soc_periphs/axi /pulp_tb/dut/i_periphs/axi/aw_len
		add wave -noupdate -group soc_periphs/axi /pulp_tb/dut/i_periphs/axi/aw_size
		add wave -noupdate -group soc_periphs/axi /pulp_tb/dut/i_periphs/axi/aw_burst
		add wave -noupdate -group soc_periphs/axi /pulp_tb/dut/i_periphs/axi/aw_lock
		add wave -noupdate -group soc_periphs/axi /pulp_tb/dut/i_periphs/axi/aw_cache
		add wave -noupdate -group soc_periphs/axi /pulp_tb/dut/i_periphs/axi/aw_prot
		add wave -noupdate -group soc_periphs/axi /pulp_tb/dut/i_periphs/axi/aw_qos
		add wave -noupdate -group soc_periphs/axi /pulp_tb/dut/i_periphs/axi/aw_region
		add wave -noupdate -group soc_periphs/axi /pulp_tb/dut/i_periphs/axi/aw_atop
		add wave -noupdate -group soc_periphs/axi /pulp_tb/dut/i_periphs/axi/aw_user
		add wave -noupdate -group soc_periphs/axi /pulp_tb/dut/i_periphs/axi/aw_valid
		add wave -noupdate -group soc_periphs/axi /pulp_tb/dut/i_periphs/axi/aw_ready
		add wave -noupdate -group soc_periphs/axi /pulp_tb/dut/i_periphs/axi/w_data
		add wave -noupdate -group soc_periphs/axi /pulp_tb/dut/i_periphs/axi/w_strb
		add wave -noupdate -group soc_periphs/axi /pulp_tb/dut/i_periphs/axi/w_last
		add wave -noupdate -group soc_periphs/axi /pulp_tb/dut/i_periphs/axi/w_user
		add wave -noupdate -group soc_periphs/axi /pulp_tb/dut/i_periphs/axi/w_valid
		add wave -noupdate -group soc_periphs/axi /pulp_tb/dut/i_periphs/axi/w_ready
		add wave -noupdate -group soc_periphs/axi /pulp_tb/dut/i_periphs/axi/b_id
		add wave -noupdate -group soc_periphs/axi /pulp_tb/dut/i_periphs/axi/b_resp
		add wave -noupdate -group soc_periphs/axi /pulp_tb/dut/i_periphs/axi/b_user
		add wave -noupdate -group soc_periphs/axi /pulp_tb/dut/i_periphs/axi/b_valid
		add wave -noupdate -group soc_periphs/axi /pulp_tb/dut/i_periphs/axi/b_ready
		add wave -noupdate -group soc_periphs/axi /pulp_tb/dut/i_periphs/axi/ar_id
		add wave -noupdate -group soc_periphs/axi /pulp_tb/dut/i_periphs/axi/ar_addr
		add wave -noupdate -group soc_periphs/axi /pulp_tb/dut/i_periphs/axi/ar_len
		add wave -noupdate -group soc_periphs/axi /pulp_tb/dut/i_periphs/axi/ar_size
		add wave -noupdate -group soc_periphs/axi /pulp_tb/dut/i_periphs/axi/ar_burst
		add wave -noupdate -group soc_periphs/axi /pulp_tb/dut/i_periphs/axi/ar_lock
		add wave -noupdate -group soc_periphs/axi /pulp_tb/dut/i_periphs/axi/ar_cache
		add wave -noupdate -group soc_periphs/axi /pulp_tb/dut/i_periphs/axi/ar_prot
		add wave -noupdate -group soc_periphs/axi /pulp_tb/dut/i_periphs/axi/ar_qos
		add wave -noupdate -group soc_periphs/axi /pulp_tb/dut/i_periphs/axi/ar_region
		add wave -noupdate -group soc_periphs/axi /pulp_tb/dut/i_periphs/axi/ar_user
		add wave -noupdate -group soc_periphs/axi /pulp_tb/dut/i_periphs/axi/ar_valid
		add wave -noupdate -group soc_periphs/axi /pulp_tb/dut/i_periphs/axi/ar_ready
		add wave -noupdate -group soc_periphs/axi /pulp_tb/dut/i_periphs/axi/r_id
		add wave -noupdate -group soc_periphs/axi /pulp_tb/dut/i_periphs/axi/r_data
		add wave -noupdate -group soc_periphs/axi /pulp_tb/dut/i_periphs/axi/r_resp
		add wave -noupdate -group soc_periphs/axi /pulp_tb/dut/i_periphs/axi/r_last
		add wave -noupdate -group soc_periphs/axi /pulp_tb/dut/i_periphs/axi/r_user
		add wave -noupdate -group soc_periphs/axi /pulp_tb/dut/i_periphs/axi/r_valid
		add wave -noupdate -group soc_periphs/axi /pulp_tb/dut/i_periphs/axi/r_ready
		add wave -noupdate -group soc_periphs/apb /pulp_tb/dut/i_periphs/apb/paddr
		add wave -noupdate -group soc_periphs/apb /pulp_tb/dut/i_periphs/apb/pwdata
		add wave -noupdate -group soc_periphs/apb /pulp_tb/dut/i_periphs/apb/pwrite
		add wave -noupdate -group soc_periphs/apb /pulp_tb/dut/i_periphs/apb/psel
		add wave -noupdate -group soc_periphs/apb /pulp_tb/dut/i_periphs/apb/penable
		add wave -noupdate -group soc_periphs/apb /pulp_tb/dut/i_periphs/apb/prdata
		add wave -noupdate -group soc_periphs/apb /pulp_tb/dut/i_periphs/apb/pready
		add wave -noupdate -group soc_periphs/apb /pulp_tb/dut/i_periphs/apb/pslverr
		add wave -noupdate -group soc_ctrl_regs/apb /pulp_tb/dut/i_periphs/i_soc_ctrl_regs/apb/paddr
		add wave -noupdate -group soc_ctrl_regs/apb /pulp_tb/dut/i_periphs/i_soc_ctrl_regs/apb/pwdata
		add wave -noupdate -group soc_ctrl_regs/apb /pulp_tb/dut/i_periphs/i_soc_ctrl_regs/apb/pwrite
		add wave -noupdate -group soc_ctrl_regs/apb /pulp_tb/dut/i_periphs/i_soc_ctrl_regs/apb/psel
		add wave -noupdate -group soc_ctrl_regs/apb /pulp_tb/dut/i_periphs/i_soc_ctrl_regs/apb/penable
		add wave -noupdate -group soc_ctrl_regs/apb /pulp_tb/dut/i_periphs/i_soc_ctrl_regs/apb/prdata
		add wave -noupdate -group soc_ctrl_regs/apb /pulp_tb/dut/i_periphs/i_soc_ctrl_regs/apb/pready
		add wave -noupdate -group soc_ctrl_regs/apb /pulp_tb/dut/i_periphs/i_soc_ctrl_regs/apb/pslverr
		add wave -noupdate -group {l2_mst[0]} {/pulp_tb/dut/l2_mst[0]/aw_id}
		add wave -noupdate -group {l2_mst[0]} {/pulp_tb/dut/l2_mst[0]/aw_addr}
		add wave -noupdate -group {l2_mst[0]} {/pulp_tb/dut/l2_mst[0]/aw_len}
		add wave -noupdate -group {l2_mst[0]} {/pulp_tb/dut/l2_mst[0]/aw_size}
		add wave -noupdate -group {l2_mst[0]} {/pulp_tb/dut/l2_mst[0]/aw_burst}
		add wave -noupdate -group {l2_mst[0]} {/pulp_tb/dut/l2_mst[0]/aw_lock}
		add wave -noupdate -group {l2_mst[0]} {/pulp_tb/dut/l2_mst[0]/aw_cache}
		add wave -noupdate -group {l2_mst[0]} {/pulp_tb/dut/l2_mst[0]/aw_prot}
		add wave -noupdate -group {l2_mst[0]} {/pulp_tb/dut/l2_mst[0]/aw_qos}
		add wave -noupdate -group {l2_mst[0]} {/pulp_tb/dut/l2_mst[0]/aw_region}
		add wave -noupdate -group {l2_mst[0]} {/pulp_tb/dut/l2_mst[0]/aw_atop}
		add wave -noupdate -group {l2_mst[0]} {/pulp_tb/dut/l2_mst[0]/aw_user}
		add wave -noupdate -group {l2_mst[0]} {/pulp_tb/dut/l2_mst[0]/aw_valid}
		add wave -noupdate -group {l2_mst[0]} {/pulp_tb/dut/l2_mst[0]/aw_ready}
		add wave -noupdate -group {l2_mst[0]} {/pulp_tb/dut/l2_mst[0]/w_data}
		add wave -noupdate -group {l2_mst[0]} {/pulp_tb/dut/l2_mst[0]/w_strb}
		add wave -noupdate -group {l2_mst[0]} {/pulp_tb/dut/l2_mst[0]/w_last}
		add wave -noupdate -group {l2_mst[0]} {/pulp_tb/dut/l2_mst[0]/w_user}
		add wave -noupdate -group {l2_mst[0]} {/pulp_tb/dut/l2_mst[0]/w_valid}
		add wave -noupdate -group {l2_mst[0]} {/pulp_tb/dut/l2_mst[0]/w_ready}
		add wave -noupdate -group {l2_mst[0]} {/pulp_tb/dut/l2_mst[0]/b_id}
		add wave -noupdate -group {l2_mst[0]} {/pulp_tb/dut/l2_mst[0]/b_resp}
		add wave -noupdate -group {l2_mst[0]} {/pulp_tb/dut/l2_mst[0]/b_user}
		add wave -noupdate -group {l2_mst[0]} {/pulp_tb/dut/l2_mst[0]/b_valid}
		add wave -noupdate -group {l2_mst[0]} {/pulp_tb/dut/l2_mst[0]/b_ready}
		add wave -noupdate -group {l2_mst[0]} {/pulp_tb/dut/l2_mst[0]/ar_id}
		add wave -noupdate -group {l2_mst[0]} {/pulp_tb/dut/l2_mst[0]/ar_addr}
		add wave -noupdate -group {l2_mst[0]} {/pulp_tb/dut/l2_mst[0]/ar_len}
		add wave -noupdate -group {l2_mst[0]} {/pulp_tb/dut/l2_mst[0]/ar_size}
		add wave -noupdate -group {l2_mst[0]} {/pulp_tb/dut/l2_mst[0]/ar_burst}
		add wave -noupdate -group {l2_mst[0]} {/pulp_tb/dut/l2_mst[0]/ar_lock}
		add wave -noupdate -group {l2_mst[0]} {/pulp_tb/dut/l2_mst[0]/ar_cache}
		add wave -noupdate -group {l2_mst[0]} {/pulp_tb/dut/l2_mst[0]/ar_prot}
		add wave -noupdate -group {l2_mst[0]} {/pulp_tb/dut/l2_mst[0]/ar_qos}
		add wave -noupdate -group {l2_mst[0]} {/pulp_tb/dut/l2_mst[0]/ar_region}
		add wave -noupdate -group {l2_mst[0]} {/pulp_tb/dut/l2_mst[0]/ar_user}
		add wave -noupdate -group {l2_mst[0]} {/pulp_tb/dut/l2_mst[0]/ar_valid}
		add wave -noupdate -group {l2_mst[0]} {/pulp_tb/dut/l2_mst[0]/ar_ready}
		add wave -noupdate -group {l2_mst[0]} {/pulp_tb/dut/l2_mst[0]/r_id}
		add wave -noupdate -group {l2_mst[0]} {/pulp_tb/dut/l2_mst[0]/r_data}
		add wave -noupdate -group {l2_mst[0]} {/pulp_tb/dut/l2_mst[0]/r_resp}
		add wave -noupdate -group {l2_mst[0]} {/pulp_tb/dut/l2_mst[0]/r_last}
		add wave -noupdate -group {l2_mst[0]} {/pulp_tb/dut/l2_mst[0]/r_user}
		add wave -noupdate -group {l2_mst[0]} {/pulp_tb/dut/l2_mst[0]/r_valid}
		add wave -noupdate -group {l2_mst[0]} {/pulp_tb/dut/l2_mst[0]/r_ready}
		add wave -noupdate -group {dma[0]/ext_master} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/dmac_wrap_i/ext_master/aw_id}
		add wave -noupdate -group {dma[0]/ext_master} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/dmac_wrap_i/ext_master/aw_addr}
		add wave -noupdate -group {dma[0]/ext_master} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/dmac_wrap_i/ext_master/aw_len}
		add wave -noupdate -group {dma[0]/ext_master} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/dmac_wrap_i/ext_master/aw_size}
		add wave -noupdate -group {dma[0]/ext_master} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/dmac_wrap_i/ext_master/aw_burst}
		add wave -noupdate -group {dma[0]/ext_master} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/dmac_wrap_i/ext_master/aw_lock}
		add wave -noupdate -group {dma[0]/ext_master} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/dmac_wrap_i/ext_master/aw_cache}
		add wave -noupdate -group {dma[0]/ext_master} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/dmac_wrap_i/ext_master/aw_prot}
		add wave -noupdate -group {dma[0]/ext_master} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/dmac_wrap_i/ext_master/aw_qos}
		add wave -noupdate -group {dma[0]/ext_master} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/dmac_wrap_i/ext_master/aw_region}
		add wave -noupdate -group {dma[0]/ext_master} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/dmac_wrap_i/ext_master/aw_atop}
		add wave -noupdate -group {dma[0]/ext_master} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/dmac_wrap_i/ext_master/aw_user}
		add wave -noupdate -group {dma[0]/ext_master} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/dmac_wrap_i/ext_master/aw_valid}
		add wave -noupdate -group {dma[0]/ext_master} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/dmac_wrap_i/ext_master/aw_ready}
		add wave -noupdate -group {dma[0]/ext_master} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/dmac_wrap_i/ext_master/w_data}
		add wave -noupdate -group {dma[0]/ext_master} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/dmac_wrap_i/ext_master/w_strb}
		add wave -noupdate -group {dma[0]/ext_master} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/dmac_wrap_i/ext_master/w_last}
		add wave -noupdate -group {dma[0]/ext_master} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/dmac_wrap_i/ext_master/w_user}
		add wave -noupdate -group {dma[0]/ext_master} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/dmac_wrap_i/ext_master/w_valid}
		add wave -noupdate -group {dma[0]/ext_master} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/dmac_wrap_i/ext_master/w_ready}
		add wave -noupdate -group {dma[0]/ext_master} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/dmac_wrap_i/ext_master/b_id}
		add wave -noupdate -group {dma[0]/ext_master} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/dmac_wrap_i/ext_master/b_resp}
		add wave -noupdate -group {dma[0]/ext_master} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/dmac_wrap_i/ext_master/b_user}
		add wave -noupdate -group {dma[0]/ext_master} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/dmac_wrap_i/ext_master/b_valid}
		add wave -noupdate -group {dma[0]/ext_master} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/dmac_wrap_i/ext_master/b_ready}
		add wave -noupdate -group {dma[0]/ext_master} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/dmac_wrap_i/ext_master/ar_id}
		add wave -noupdate -group {dma[0]/ext_master} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/dmac_wrap_i/ext_master/ar_addr}
		add wave -noupdate -group {dma[0]/ext_master} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/dmac_wrap_i/ext_master/ar_len}
		add wave -noupdate -group {dma[0]/ext_master} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/dmac_wrap_i/ext_master/ar_size}
		add wave -noupdate -group {dma[0]/ext_master} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/dmac_wrap_i/ext_master/ar_burst}
		add wave -noupdate -group {dma[0]/ext_master} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/dmac_wrap_i/ext_master/ar_lock}
		add wave -noupdate -group {dma[0]/ext_master} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/dmac_wrap_i/ext_master/ar_cache}
		add wave -noupdate -group {dma[0]/ext_master} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/dmac_wrap_i/ext_master/ar_prot}
		add wave -noupdate -group {dma[0]/ext_master} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/dmac_wrap_i/ext_master/ar_qos}
		add wave -noupdate -group {dma[0]/ext_master} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/dmac_wrap_i/ext_master/ar_region}
		add wave -noupdate -group {dma[0]/ext_master} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/dmac_wrap_i/ext_master/ar_user}
		add wave -noupdate -group {dma[0]/ext_master} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/dmac_wrap_i/ext_master/ar_valid}
		add wave -noupdate -group {dma[0]/ext_master} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/dmac_wrap_i/ext_master/ar_ready}
		add wave -noupdate -group {dma[0]/ext_master} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/dmac_wrap_i/ext_master/r_id}
		add wave -noupdate -group {dma[0]/ext_master} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/dmac_wrap_i/ext_master/r_data}
		add wave -noupdate -group {dma[0]/ext_master} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/dmac_wrap_i/ext_master/r_resp}
		add wave -noupdate -group {dma[0]/ext_master} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/dmac_wrap_i/ext_master/r_last}
		add wave -noupdate -group {dma[0]/ext_master} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/dmac_wrap_i/ext_master/r_user}
		add wave -noupdate -group {dma[0]/ext_master} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/dmac_wrap_i/ext_master/r_valid}
		add wave -noupdate -group {dma[0]/ext_master} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/dmac_wrap_i/ext_master/r_ready}
		add wave -noupdate -group {speriph_master[EOC]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/speriph_master[0]/req}
		add wave -noupdate -group {speriph_master[EOC]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/speriph_master[0]/add}
		add wave -noupdate -group {speriph_master[EOC]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/speriph_master[0]/wen}
		add wave -noupdate -group {speriph_master[EOC]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/speriph_master[0]/wdata}
		add wave -noupdate -group {speriph_master[EOC]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/speriph_master[0]/be}
		add wave -noupdate -group {speriph_master[EOC]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/speriph_master[0]/gnt}
		add wave -noupdate -group {speriph_master[EOC]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/speriph_master[0]/id}
		add wave -noupdate -group {speriph_master[EOC]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/speriph_master[0]/r_valid}
		add wave -noupdate -group {speriph_master[EOC]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/speriph_master[0]/r_opc}
		add wave -noupdate -group {speriph_master[EOC]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/speriph_master[0]/r_id}
		add wave -noupdate -group {speriph_master[EOC]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/speriph_master[0]/r_rdata}
		add wave -noupdate -group {speriph_master[TIMER]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/speriph_master[1]/req}
		add wave -noupdate -group {speriph_master[TIMER]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/speriph_master[1]/add}
		add wave -noupdate -group {speriph_master[TIMER]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/speriph_master[1]/wen}
		add wave -noupdate -group {speriph_master[TIMER]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/speriph_master[1]/wdata}
		add wave -noupdate -group {speriph_master[TIMER]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/speriph_master[1]/be}
		add wave -noupdate -group {speriph_master[TIMER]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/speriph_master[1]/gnt}
		add wave -noupdate -group {speriph_master[TIMER]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/speriph_master[1]/id}
		add wave -noupdate -group {speriph_master[TIMER]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/speriph_master[1]/r_valid}
		add wave -noupdate -group {speriph_master[TIMER]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/speriph_master[1]/r_opc}
		add wave -noupdate -group {speriph_master[TIMER]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/speriph_master[1]/r_id}
		add wave -noupdate -group {speriph_master[TIMER]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/speriph_master[1]/r_rdata}
		add wave -noupdate -group {speriph_master[EVENTU]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/speriph_master[2]/req}
		add wave -noupdate -group {speriph_master[EVENTU]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/speriph_master[2]/add}
		add wave -noupdate -group {speriph_master[EVENTU]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/speriph_master[2]/wen}
		add wave -noupdate -group {speriph_master[EVENTU]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/speriph_master[2]/wdata}
		add wave -noupdate -group {speriph_master[EVENTU]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/speriph_master[2]/be}
		add wave -noupdate -group {speriph_master[EVENTU]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/speriph_master[2]/gnt}
		add wave -noupdate -group {speriph_master[EVENTU]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/speriph_master[2]/id}
		add wave -noupdate -group {speriph_master[EVENTU]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/speriph_master[2]/r_valid}
		add wave -noupdate -group {speriph_master[EVENTU]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/speriph_master[2]/r_opc}
		add wave -noupdate -group {speriph_master[EVENTU]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/speriph_master[2]/r_id}
		add wave -noupdate -group {speriph_master[EVENTU]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/speriph_master[2]/r_rdata}
		add wave -noupdate -group {speriph_master[UNUSED]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/speriph_master[3]/req}
		add wave -noupdate -group {speriph_master[UNUSED]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/speriph_master[3]/add}
		add wave -noupdate -group {speriph_master[UNUSED]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/speriph_master[3]/wen}
		add wave -noupdate -group {speriph_master[UNUSED]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/speriph_master[3]/wdata}
		add wave -noupdate -group {speriph_master[UNUSED]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/speriph_master[3]/be}
		add wave -noupdate -group {speriph_master[UNUSED]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/speriph_master[3]/gnt}
		add wave -noupdate -group {speriph_master[UNUSED]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/speriph_master[3]/id}
		add wave -noupdate -group {speriph_master[UNUSED]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/speriph_master[3]/r_valid}
		add wave -noupdate -group {speriph_master[UNUSED]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/speriph_master[3]/r_opc}
		add wave -noupdate -group {speriph_master[UNUSED]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/speriph_master[3]/r_id}
		add wave -noupdate -group {speriph_master[UNUSED]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/speriph_master[3]/r_rdata}
		add wave -noupdate -group {speriph_master[HWPE]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/speriph_master[4]/req}
		add wave -noupdate -group {speriph_master[HWPE]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/speriph_master[4]/add}
		add wave -noupdate -group {speriph_master[HWPE]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/speriph_master[4]/wen}
		add wave -noupdate -group {speriph_master[HWPE]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/speriph_master[4]/wdata}
		add wave -noupdate -group {speriph_master[HWPE]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/speriph_master[4]/be}
		add wave -noupdate -group {speriph_master[HWPE]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/speriph_master[4]/gnt}
		add wave -noupdate -group {speriph_master[HWPE]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/speriph_master[4]/id}
		add wave -noupdate -group {speriph_master[HWPE]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/speriph_master[4]/r_valid}
		add wave -noupdate -group {speriph_master[HWPE]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/speriph_master[4]/r_opc}
		add wave -noupdate -group {speriph_master[HWPE]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/speriph_master[4]/r_id}
		add wave -noupdate -group {speriph_master[HWPE]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/speriph_master[4]/r_rdata}
		add wave -noupdate -group {core_periph_slave[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/core_periph_slave[0]/req}
		add wave -noupdate -group {core_periph_slave[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/core_periph_slave[0]/gnt}
		add wave -noupdate -group {core_periph_slave[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/core_periph_slave[0]/add}
		add wave -noupdate -group {core_periph_slave[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/core_periph_slave[0]/wen}
		add wave -noupdate -group {core_periph_slave[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/core_periph_slave[0]/wdata}
		add wave -noupdate -group {core_periph_slave[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/core_periph_slave[0]/be}
		add wave -noupdate -group {core_periph_slave[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/core_periph_slave[0]/id}
		add wave -noupdate -group {core_periph_slave[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/core_periph_slave[0]/r_valid}
		add wave -noupdate -group {core_periph_slave[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/core_periph_slave[0]/r_opc}
		add wave -noupdate -group {core_periph_slave[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/core_periph_slave[0]/r_id}
		add wave -noupdate -group {core_periph_slave[0]} {/pulp_tb/dut/gen_clusters[0]/gen_cluster_sync/i_cluster/i_ooc/i_bound/cluster_interconnect_wrap_i/core_periph_slave[0]/r_rdata}
		add wave -noupdate -group {TB I/O} /pulp_tb/dut/clk_i
		add wave -noupdate -group {TB I/O} /pulp_tb/dut/rst_ni
		add wave -noupdate -group {TB I/O} /pulp_tb/dut/cl_fetch_en_i
		add wave -noupdate -group {TB I/O} /pulp_tb/dut/cl_busy_o
		add wave -noupdate -group {TB I/O} /pulp_tb/dut/cl_eoc_o
		add wave -noupdate -group {TB I/O} /pulp_tb/from_pulp_req
		add wave -noupdate -group {TB I/O} /pulp_tb/from_pulp_resp
		add wave -noupdate -group {TB I/O} /pulp_tb/to_pulp_req
		add wave -noupdate -group {TB I/O} /pulp_tb/to_pulp_resp
		add wave -noupdate -group {TB I/O} /pulp_tb/rab_conf_req
		add wave -noupdate -group {TB I/O} /pulp_tb/rab_conf_resp
		WaveRestoreCursors {{Cursor 11} {35680473 ps} 1} {W {35686614 ps} 1} {{Cursor 13} {35800671 ps} 1} {{Cursor 14} {16000 ps} 0}
		quietly wave cursor active 4
		configure wave -namecolwidth 271
		configure wave -valuecolwidth 483
		configure wave -justifyvalue left
		configure wave -signalnamewidth 1
		configure wave -snapdistance 10
		configure wave -datasetprefix 0
		configure wave -rowmargin 4
		configure wave -childrowmargin 2
		configure wave -gridoffset 0
		configure wave -gridperiod 1
		configure wave -griddelta 40
		configure wave -timeline 0
		configure wave -timelineunits ns
		update
		WaveRestoreZoom {0 ps} {530958 ps}
		'''
	}
	
	def printRiscvHeader(){
		
		'''	
		
		/*
		 * Copyright (C) 2018-2019 ETH Zurich and University of Bologna
		 *
		 * Licensed under the Apache License, Version 2.0 (the "License");
		 * you may not use this file except in compliance with the License.
		 * You may obtain a copy of the License at
		 *
		 *     http://www.apache.org/licenses/LICENSE-2.0
		 *
		 * Unless required by applicable law or agreed to in writing, software
		 * distributed under the License is distributed on an "AS IS" BASIS,
		 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
		 * See the License for the specific language governing permissions and
		 * limitations under the License.
		 */
		/*
		 * Authors:     Francesco Conti <fconti@iis.ee.ethz.ch>
		 * Contribute:  Gianluca Bellocchi <gianluca.bellocchi@unimore.it>
		 */
		 '''		
	}
	
	def printRiscvRegs() {
		var counterReg = 0;
		var counterOffset = 64;
		'''
			/*
			 * Control and generic configuration register layout
			 * ================================================================================
			 *  # reg |  offset  |  bits   |   bitmask    ||  content
			 * -------+----------+---------+--------------++-----------------------------------
			 *     0  |  0x0000  |  31: 0  |  0xffffffff  ||  TRIGGER
			 *     1  |  0x0004  |  31: 0  |  0xffffffff  ||  ACQUIRE
			 *     2  |  0x0008  |  31: 0  |  0xffffffff  ||  EVT_ENABLE
			 *     3  |  0x000c  |  31: 0  |  0xffffffff  ||  STATUS
			 *     4  |  0x0010  |  31: 0  |  0xffffffff  ||  RUNNING_JOB
			 *     5  |  0x0014  |  31: 0  |  0xffffffff  ||  SOFT_CLEAR
			 *   6-7  |          |         |              ||  Reserved
			 *     8  |  0x0020  |  31: 0  |  0xffffffff  ||  BYTECODE0 [31:0]
			 *     9  |  0x0024  |  31: 0  |  0xffffffff  ||  BYTECODE1 [63:32]
			 *    10  |  0x0028  |  31: 0  |  0xffffffff  ||  BYTECODE2 [95:64]
			 *    11  |  0x002c  |  31: 0  |  0xffffffff  ||  BYTECODE3 [127:96]
			 *    12  |  0x0030  |  31: 0  |  0xffffffff  ||  BYTECODE4 [159:128]
			 *    13  |  0x0034  |  31:16  |  0xffff0000  ||  LOOPS0    [15:0]
			 *        |          |  15: 0  |  0x0000ffff  ||  BYTECODE5 [175:160]
			 *    14  |  0x0038  |  31: 0  |  0xffffffff  ||  LOOPS1    [47:16]
			 *    15  |          |  31: 0  |  0xffffffff  ||  Reserved
			 * ================================================================================
			 *
			 * Job-dependent registers layout
			 * ================================================================================
			 *  # reg |  offset  |  bits   |   bitmask    ||  content
			 * -------+----------+---------+--------------++-----------------------------------
			 «FOR port : inputMap.keySet»  
			 	*     «counterReg++»  |  0x«String.format("%04x", counterOffset)»«{counterOffset = counterOffset + 4; ""}»  |  31: 0  |  0xffffffff  ||  «port.name.toUpperCase»_ADDR
			 «ENDFOR»  
			 «FOR port : outputMap.keySet»  
			   	*     «counterReg++»  |  0x«String.format("%04x", counterOffset)»«{counterOffset = counterOffset + 4; ""}»  |  31: 0  |  0xffffffff  ||  «port.name.toUpperCase»_ADDR
			 «ENDFOR»  
			 *     «counterReg++»  |  0x«String.format("%04x", counterOffset)»«{counterOffset = counterOffset + 4; ""}»  |  31: 0  |  0xffffffff  ||  NB_ITER
			 *     «counterReg++»  |  0x«String.format("%04x", counterOffset)»«{counterOffset = counterOffset + 4; ""}»  |  31: 0  |  0xffffffff  ||  LEN_ITER
			 *     «counterReg++»  |  0x«String.format("%04x", counterOffset)»«{counterOffset = counterOffset + 4; ""}»  |  31:16  |  0xffff0000  ||  SHIFT
			 *        |          |   0: 0  |  0x00000001  ||  SIMPLEMUL
			 *     «counterReg++»  |  0x«String.format("%04x", counterOffset)»«{counterOffset = counterOffset + 4; ""}»  |  31: 0  |  0xffffffff  ||  VECTSTRIDE
			 *     «counterReg++»  |  0x«String.format("%04x", counterOffset)»«{counterOffset = counterOffset + 4; ""}»  |  31: 0  |  0xffffffff  ||  VECTSTRIDE2
			 «FOR param : network.parameters»
			 	*     «counterReg++»  |  0x«String.format("%04x", counterOffset)»«{counterOffset = counterOffset + 4; ""}»  |  31: 0  |  0xffffffff  ||  «param.name.toUpperCase»
			 «ENDFOR»
			 * ================================================================================
			 *
			 */
		'''
	}
	
	def printRiscvArchiHwpe() {

		var counterOffset2 = 64;
		'''	
			«printRiscvHeader()»
			#ifndef __ARCHI_HWPE_H__
			#define __ARCHI_HWPE_H__
			«printRiscvRegs»
			#define ARCHI_CL_EVT_ACC0 0
			#define ARCHI_CL_EVT_ACC1 1
			#define ARCHI_HWPE_ADDR_BASE 0x1b201000
			#define __builtin_bitinsert(a,b,c,d) (a | (((b << (32-c)) >> (32-c)) << d))
			// flag regs
			#define HWPE_TRIGGER          0x00
			#define HWPE_ACQUIRE          0x04
			#define HWPE_FINISHED         0x08
			#define HWPE_STATUS           0x0c
			#define HWPE_RUNNING_JOB      0x10
			#define HWPE_SOFT_CLEAR       0x14
			// Microcode-processor regs
			#define HWPE_BYTECODE         0x20
			#define HWPE_BYTECODE0_OFFS        0x00
			#define HWPE_BYTECODE1_OFFS        0x04
			#define HWPE_BYTECODE2_OFFS        0x08
			#define HWPE_BYTECODE3_OFFS        0x0c
			#define HWPE_BYTECODE4_OFFS        0x10
			#define HWPE_BYTECODE5_LOOPS0_OFFS 0x14
			#define HWPE_LOOPS1_OFFS           0x18
			// TCDM address regs
			   «FOR port : inputMap.keySet»  
			   	#define HWPE_«port.name.toUpperCase»_ADDR           0x«String.format("%02x", counterOffset2)»«{counterOffset2 = counterOffset2 + 4; ""}»
			   «ENDFOR»  
			   «FOR port : outputMap.keySet»  
			   	#define HWPE_«port.name.toUpperCase»_ADDR           0x«String.format("%02x", counterOffset2)»«{counterOffset2 = counterOffset2 + 4; ""}»
			   «ENDFOR»  
			// standard regs
			#define HWPE_NB_ITER          0x«String.format("%02x", counterOffset2)»«{counterOffset2 = counterOffset2 + 4; ""}»
			#define HWPE_LEN_ITER         0x«String.format("%02x", counterOffset2)»«{counterOffset2 = counterOffset2 + 4; ""}»
			#define HWPE_SHIFT_SIMPLEMUL  0x«String.format("%02x", counterOffset2)»«{counterOffset2 = counterOffset2 + 4; ""}»
			#define HWPE_VECTSTRIDE       0x«String.format("%02x", counterOffset2)»«{counterOffset2 = counterOffset2 + 4; ""}»
			#define HWPE_VECTSTRIDE2      0x«String.format("%02x", counterOffset2)»«{counterOffset2 = counterOffset2 + 4; ""}»
			// custom regs
			«FOR param : network.parameters»
				#define HWPE_«param.name.toUpperCase»           0x«String.format("%02x", counterOffset2)»«{counterOffset2 = counterOffset2 + 4; ""}»
			«ENDFOR»
			«IF !luts.empty»
				#define HWPE_ID_CONFIGURATION		0x«String.format("%02x", counterOffset2)»«{counterOffset2 = counterOffset2 + 4; ""}»
			«ENDIF»
			#endif
		'''
	}	
	
	def printRiscvHalHwpe() {

		'''	
			«printRiscvHeader()»
			#ifndef __HAL_HWPE_H__
			#define __HAL_HWPE_H__
			«printRiscvRegs()»
			/* LOW-LEVEL HAL */
			#define HWPE_ADDR_BASE ARCHI_FC_HWPE_ADDR
			#define HWPE_ADDR_SPACE 0x00000100
			// For all the following functions we use __builtin_pulp_OffsetedWrite and __builtin_pulp_OffsetedRead
			// instead of classic load/store because otherwise the compiler is not able to correctly factorize
			// the HWPE base in case several accesses are done, ending up with twice more code
			#define HWPE_WRITE(value, offset) *(volatile int *)(ARCHI_HWPE_ADDR_BASE + offset) = value
			#define HWPE_READ(offset) *(volatile int *)(ARCHI_HWPE_ADDR_BASE + offset)
			static inline void hwpe_bytecode_set(unsigned int offs, unsigned int value) {
			  HWPE_WRITE(value, HWPE_BYTECODE+offs);
			}
			// basic hal
			static inline void hwpe_trigger_job() {
			  HWPE_WRITE(0, HWPE_TRIGGER);
			}
			static inline int hwpe_acquire_job() {
			  return HWPE_READ(HWPE_ACQUIRE);
			}
			static inline unsigned int hwpe_get_status() {
			  return HWPE_READ(HWPE_STATUS);
			}
			static inline void hwpe_soft_clear() {
			  volatile int i;
			  HWPE_WRITE(0, HWPE_SOFT_CLEAR);
			}
			static inline void hwpe_cg_enable() {
			  return;
			}
			static inline void hwpe_cg_disable() {
			  return;
			}
			// TCDM address regs
			«FOR port : inputMap.keySet»  
			   static inline void hwpe_«port.name»_addr_set(«it.mdc.tool.utility.TypeConverter.translateToCParameter(port.type)» value) {
			     HWPE_WRITE(value, HWPE_«port.name.toUpperCase»_ADDR);
			   }
			«ENDFOR»  
			«FOR port : outputMap.keySet»  
			   static inline void hwpe_«port.name»_addr_set(«it.mdc.tool.utility.TypeConverter.translateToCParameter(port.type)» value) {
			     HWPE_WRITE(value, HWPE_«port.name.toUpperCase»_ADDR);
			   }
			«ENDFOR»  
			// standard hal
			static inline void hwpe_nb_iter_set(unsigned int value) {
			  HWPE_WRITE(value, HWPE_NB_ITER);
			}
			static inline void hwpe_len_iter_set(unsigned int value) {
			  HWPE_WRITE(value, HWPE_LEN_ITER);
			}
			static inline void hwpe_shift_simplemul_set(unsigned int value) {
			  HWPE_WRITE(value, HWPE_SHIFT_SIMPLEMUL);
			}
			static inline void hwpe_vectstride_set(unsigned int value) {
			  HWPE_WRITE(value, HWPE_VECTSTRIDE);
			}
			static inline void hwpe_vectstride2_set(unsigned int value) {
			  HWPE_WRITE(value, HWPE_VECTSTRIDE2);
			}
			static inline unsigned int hwpe_shift_simplemul_value(
			  unsigned short shift,
			  unsigned       simplemul
			) {
			  unsigned int res = 0;
			#if defined(__riscv__) && !defined(RV_ISA_RV32)
			  res = __builtin_bitinsert(0,   shift,     16, 16);
			  res = __builtin_bitinsert(res, simplemul,  8,  0);
			#else
			  res |= ((shift     & 0xffff) << 16) |
			         ((simplemul & 0xff));
			#endif
			  return res;
			}
			// custom hal
			«FOR param : network.parameters»
				static inline void hwpe_«param.name.toLowerCase»_set(unsigned int value) {
				  HWPE_WRITE(value, HWPE_«param.name.toUpperCase» );
				}
			«ENDFOR»  
			«IF !luts.empty»
				static inline void hwpe_ID_configuration_set(uint8_t value) {
				  HWPE_WRITE(value, HWPE_ID_CONFIGURATION );
				}
			«ENDIF»
			#endif /* __HAL_HWPE_H__ */
		'''
	}	
	
	def printRiscvTestHwpe() {
		var counterStim = 1;
		var counterOutput = 1;

		'''	
			
			/*
			 * Copyright (C) 2019 ETH Zurich and University of Bologna
			 *
			 * Licensed under the Apache License, Version 2.0 (the "License");
			 * you may not use this file except in compliance with the License.
			 * You may obtain a copy of the License at
			 *
			 *     http://www.apache.org/licenses/LICENSE-2.0
			 *
			 * Unless required by applicable law or agreed to in writing, software
			 * distributed under the License is distributed on an "AS IS" BASIS,
			 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
			 * See the License for the specific language governing permissions and
			 * limitations under the License.
			 */
			/*
			 *
			 * Authors:     Gianluca Bellocchi <gianluca.bellocchi@unimore.it>
			 *
			 */
			/* Libraries inclusion */
			#include <omp.h>
			#include <stdlib.h>
			#include <stdio.h>
			#include <stdbool.h>
			#include <stdint.h>
			#include "inc/hwpe_lib/archi_hwpe.h"
			#include "inc/hwpe_lib/hal_hwpe.h"
			#include "inc/hero_lib/hero_memory_map.h"
			//#include "inc/hero_lib/pulp_fc.h"
			#include "inc/test_lib/test_hwpe.h"
			/* Stimuli */
			#include "inc/stim/stim_def.h"
			#include "inc/stim/stim_input.h"
			#include "inc/stim/reg_values.h"
			#include "inc/stim/results.h"
			/* Defines */
			#include "inc/test_lib/defines.h"
			/* HWPE test */
			int multi_dataflow(uint32_t stim_dim, uint32_t stripe_len) {
			  /* Init */
			  omp_set_num_threads(1);
			  volatile int errors = 0;
			  int i,j,k,cnt;
			  int offload_id_tmp, offload_id;
			  const unsigned stim_dim_local   = stim_dim;
			  const unsigned stripe_len_local = stripe_len;
			  const unsigned num_unfiltered = stim_dim_local;
			  const unsigned num_stripe     = num_unfiltered / stripe_len_local;
			  /* L2 init - Input stimuli */
			  «FOR port : inputMap.keySet»  
			  	unsigned int * «port.name»_l2 = stim_«counterStim++»;
			  «ENDFOR»
			  /* L2 init - Output result */
			  «FOR port : outputMap.keySet»  
			  	unsigned int * «port.name»_l2 = hero_l2malloc(sizeof(unsigned int)*stripe_len_local);
			  «ENDFOR»
			  #if DB
			  #else
			    /* L1 init - Input stimuli */
			    «FOR port : inputMap.keySet»  
			    	__device unsigned int * «port.name»_l1 =  (__device  unsigned int *) hero_l1malloc(sizeof(unsigned int)*stripe_len_local);
			    «ENDFOR»  
			    /* L1 init - Output result */
			    «FOR port : outputMap.keySet»  
			    	__device unsigned int * «port.name»_l1 = (__device  unsigned int *) hero_l1malloc(sizeof(unsigned int)*stripe_len_local);
			    «ENDFOR»  
			  #endif
			  #if DB
			  #else
			    hwpe_cg_enable();
			    /* Processing loops */
			    for (i = 0; i < (num_stripe); i++){
			      while((offload_id_tmp = hwpe_acquire_job()) < 0)
			      /* Micro-code processor */
			      // Set up bytecode
			      hwpe_bytecode_set(HWPE_LOOPS1_OFFS,           0x00000000);
			      hwpe_bytecode_set(HWPE_BYTECODE5_LOOPS0_OFFS, 0x00040000);
			      hwpe_bytecode_set(HWPE_BYTECODE4_OFFS,        0x00000000);
			      hwpe_bytecode_set(HWPE_BYTECODE3_OFFS,        0x00000000);
			      hwpe_bytecode_set(HWPE_BYTECODE2_OFFS,        0x00000000);
			      hwpe_bytecode_set(HWPE_BYTECODE1_OFFS,        0x000008cd);
			      hwpe_bytecode_set(HWPE_BYTECODE0_OFFS,        0x11a12c05);
			      // Ucode parameters
			      hwpe_nb_iter_set(1);
			      hwpe_vectstride_set(sizeof(«inputMap.keySet.get(0).name»_l1)*4);
			      // Stripe -> TCDM
			        «FOR port : inputMap.keySet»  
			        hero_memcpy_host2dev(«port.name»_l1, (__host unsigned int *) («port.name»_l2 + i*stripe_len_local*sizeof(unsigned int)), sizeof(unsigned int)*stripe_len_local);
			      	«ENDFOR»  
			      	// Set TCDM address reg values
			      	  «FOR port : inputMap.keySet»  
			      	  hwpe_«port.name»_addr_set( «port.name»_l1 );
			      	«ENDFOR»  
			      	«FOR port : outputMap.keySet»  
			      		hwpe_«port.name»_addr_set( «port.name»_l1 );
			      	«ENDFOR»  
			      	hwpe_len_iter_set(stripe_len_local-1);
			      	// Set custom reg values
			      	  «FOR param : network.parameters»  
			      	  hwpe_«param.name.toLowerCase»_set( /* Value of «param.name.toUpperCase» */ );
			      	«ENDFOR»  
			      	«IF !luts.empty»
			      	  hwpe_ID_configuration_set( /* Value of ID_configuration */ );
			      	«ENDIF»
			      	hwpe_trigger_job();
			      	printf("Start of processing - STATUS: %x , STRIPE #%d\n", hwpe_get_status(), i);
			      	// Handle interrupt
			      	int u=1;
			      	while(u){
			      	  if (HWPE_READ(HWPE_FINISHED))
			      	    u=0;
			      	}
			      	printf("End of processing - STATUS: %x , STRIPE #%d\n", hwpe_get_status(), i);
			      	// Stripe -> L2
			      	  «FOR port : outputMap.keySet»  
			      	  hero_memcpy_dev2host((__host unsigned int *) («port.name»_l2 + i*stripe_len_local*sizeof(unsigned int)), (__device  unsigned int *) «port.name»_l1, sizeof(unsigned int)*stripe_len_local);
			      	«ENDFOR»  
			      	hwpe_soft_clear();
			    	}
			    	hwpe_cg_disable();
			  	#endif
			  	/* Error check */
			  «FOR port : outputMap.keySet»  
			  	for(i=0;i<num_unfiltered;i++){
			  	  printf("multi_dataflow -> #%d is %x (%d)\n\n", i, *(«port.name»_l2+i), *(res_«counterOutput»+i));
			  	  if(*(«port.name»_l2+i) != res_«counterOutput++»[i]) errors++;
			  	}
			  «ENDFOR»  
			  /* Free L2 memory */
			  «FOR port : inputMap.keySet»  
			    free(«port.name»_l2);
			  «ENDFOR»  
			  /* Return errors */
			  *(int *) 0x80000000 = errors;
			  printf("errors: %d\n", errors);
			  printf("end\n");
			  return errors;
			}
			int main() {
			  /* Dimension of stimuli array */
			  uint32_t stim_dim   = STIM_DIM;
			  /* Length of single stimuli stripe */
			  uint32_t stripe_len = STRIPE_LEN;
			  while(!multi_dataflow(stim_dim, stripe_len))
			  return 0;
			}
				'''
	}	
	
}