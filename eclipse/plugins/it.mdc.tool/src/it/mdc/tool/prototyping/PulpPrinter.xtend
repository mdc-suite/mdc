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
	int dataSize = 32;
	Map<String,List<Port>> netPorts;
	
	boolean dedicatedInterfaces = false
	String coupling = ""
	boolean enableMonitoring;
	
	Map<String,Map<String,String>> netSysSignals;
	Map<String,Map<String,Map<String,String>>> modCommSignals;
	Map<String,Map<String,String>> wrapCommSignals;
	List<String> monList;
	
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
						Map<String,Map<String,String>> wrapCommSignals
	) {
		this.coupling = coupling;
		this.enableMonitoring = enableMonitoring;
		this.monList = monList;
		this.luts = luts;
		this.netSysSignals = netSysSignals;
		this.modCommSignals = modCommSignals;
		this.wrapCommSignals = wrapCommSignals;
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
	
	def printHdlSource(Network network, String module){
		
		if(module.equals("TOP")) {
			printTop(network);
		} else if(module.equals("CFG_REGS")) {
			printRegs();
		} else if(module.equals("TBENCH")) {
			printTestBench();
		}
	}
	
	def printTop(Network network) {
		
		mapInOut(network);
		mapSignals();
		
		'''	
		«printTopHeaderComments()»
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
			return "[" + size + "-1 : 0] "
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
		// system level signals
		logic enable, clear;
		ctrl_streamer_t  streamer_ctrl;
		flags_streamer_t streamer_flags;
		ctrl_engine_t    engine_ctrl;
		flags_engine_t   engine_flags;
		
		// communication signals
		«FOR input : inputMap.keySet()»
		«FOR commSigId : getInFirstModCommSignals().keySet»
		wire «getSizePrefix(getPortCommSigSize(input,commSigId,getFirstModCommSignals()))»«input.getName()»_«getMatchingWrapMapping(getFirstModCommSignals().get(commSigId).get(ProtocolManager.CH))»;
		«ENDFOR»
		wire [31:0] stream_if_«input.name»_data;
		wire stream_if_«input.name»_valid;
		wire stream_if_«input.name»_ready;
		wire [3:0] stream_if_«input.name»_strb;
		«ENDFOR»
		«FOR output : outputMap.keySet()»
		«FOR commSigId : getOutLastModCommSignals().keySet»
		wire «getSizePrefix(getPortCommSigSize(output,commSigId,getLastModCommSignals()))»«output.getName()»_«getMatchingWrapMapping(getLastModCommSignals().get(commSigId).get(ProtocolManager.CH))»;
		«ENDFOR»
		wire [31:0] stream_if_«output.name»_data;
		wire stream_if_«output.name»_valid;
		wire stream_if_«output.name»_ready;
		wire [3:0] stream_if_«output.name»_strb;
		«ENDFOR»
		'''
		
	}
	
	def printTopInterface() {
		
		'''
		module multi_dataflow_top 
		#(
			parameter int unsigned N_CORES = 2,
		  	parameter int unsigned MP  = «portMap.size»,
		  	parameter int unsigned ID  = 10 
		)
		(
			// global signals
			input  logic                                  clk_i,
			input  logic                                  rst_ni,
			input  logic                                  test_mode_i,
			// events
			output logic [N_CORES-1:0][REGFILE_N_EVT-1:0] evt_o,
			// tcdm master ports
			hwpe_stream_intf_tcdm.master                  tcdm[MP-1:0],
			// periph slave port
			hwpe_ctrl_intf_periph.slave                   periph
		);
		
		'''
	}
			
	def printTopBody() {
		//TODO check zero and last for size=0 with stream accelerator
		
		'''
		// hwpe stream interfaces
		«FOR port : portMap.keySet»// hwpe stream intf «port.name»
		hwpe_stream_intf_stream #(
			.DATA_WIDTH(32)
		) stream_if_«port.name» (
			.clk ( clk_i )
		);
  		«ENDFOR»
		
		// hwpe strem interface wrappers
		«FOR input : inputMap.keySet»// hwpe stream intf in «input.name»
		interface_wrapper_in i_interface_wrapper_in_«input.name»(
			.in_data(stream_if_«input.name»_data),
			.in_valid(stream_if_«input.name»_valid),
			.in_ready(stream_if_«input.name»_ready),
			.in_strb(stream_if_«input.name»_strb),
			.in(stream_if_«input.name».sink)
		);
		«ENDFOR»
		«FOR output : outputMap.keySet»// hwpe stream intf out «output.name»
		interface_wrapper_out i_interface_wrapper_out_«output.name»(
			.out_data(stream_if_«output.name»_data),
			.out_valid(stream_if_«output.name»_valid),
			.out_ready(stream_if_«output.name»_ready),
			.out_strb(stream_if_«output.name»_strb),
			.out(stream_if_«output.name».source)
		);
		«ENDFOR»
		
		// Multi-Dataflow Reconfigurable Datapath
		// ----------------------------------------------------------------------------
		«printTopDatapath()»
		«FOR input :inputMap.keySet»
		assign stream_if_«input.name»_ready = «IF isNegMatchingWrapMapping(getFullChannelWrapCommSignalID())»!«ENDIF»«input.getName()»_full;
		assign «input.getName()»_data = stream_if_«input.name»_data«IF getDataSize(input)<32» [«getDataSize(input)-1» : 0]«ENDIF»;
		assign «input.getName()»_push = stream_if_«input.name»_valid;
		«ENDFOR»
		«FOR output : outputMap.keySet()»
		assign stream_if_«output.name»_valid = «output.getName()»_push;
		assign stream_if_«output.name»_data = «IF getDataSize(output)<32»{{«32-getDataSize(output)»{1'b0}},«ENDIF»«output.getName()»_data«IF getDataSize(output)<32»}«ENDIF»;
		assign stream_if_«output.name»_strb = 4'b111;
		assign «output.getName()»_full = «IF isNegMatchingWrapMapping(getFullChannelWrapCommSignalID())»!«ENDIF»stream_if_«output.name»_ready;
		«ENDFOR»
		// ----------------------------------------------------------------------------	
		
		«FOR output : outputMap.keySet()»
		// Output Counter(s)
		// ----------------------------------------------------------------------------
		//counter #(			
		//	.SIZE(SIZE_ADDR_«portMap.get(output)+1») ) 
		//i_counter_«output.name» (
		//	.aclk(s00_axi_aclk),
		//	.aresetn(s00_axi_aresetn),
		//	.clr(slv_reg0[2]),
		//	.en(«output.getName()»_push),
		//	.max(slv_reg«outputMap.get(output)+1»[SIZE_ADDR_«portMap.get(output)+1»-1:0]),
		//	.count(),
		//	.last(m«getLongId(outputMap.get(output))»_axis_tlast)
		//);
		«ENDFOR»
		
		multi_dataflow_streamer #(
		    .MP ( MP )
		) i_streamer (
		    .clk_i            ( clk_i          ),
		    .rst_ni           ( rst_ni         ),
		    .test_mode_i      ( test_mode_i    ),
		    .enable_i         ( enable         ),
		    .clear_i          ( clear          ),
		    «FOR input : inputMap.keySet»
		    .stream_if_«input.name» (stream_if_«input.name».source),
      		«ENDFOR»
		    «FOR output : outputMap.keySet»
		    .stream_if_«output.name» (stream_if_«output.name».sink),
      		«ENDFOR»
		    .tcdm             ( tcdm           ),
		    .ctrl_i           ( streamer_ctrl  ),
		    .flags_o          ( streamer_flags )
		);
		
		multi_dataflow_ctrl #(
		    .N_CORES   ( 2  ),
		    .N_CONTEXT ( 2  ),
		    .N_IO_REGS ( «outputMap.size+1» ),
		    .ID ( ID )
		) i_ctrl (
		    .clk_i            ( clk_i          ),
		    .rst_ni           ( rst_ni         ),
		    .test_mode_i      ( test_mode_i    ),
		    .evt_o            ( evt_o          ),
		    .clear_o          ( clear          ),
		    .ctrl_streamer_o  ( streamer_ctrl  ),
		    .flags_streamer_i ( streamer_flags ),
		    .ctrl_engine_o    ( engine_ctrl    ),
		    .flags_engine_i   ( engine_flags   ),
		    .periph           ( periph         )
		);
		
		assign enable = 1'b1;
		// ----------------------------------------------------------------------------
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
			«FOR clockSignal : getClockSysSignals()»
			.«clockSignal»(clk_i)«IF !(getResetSysSignals().empty && this.luts.empty)»,«ENDIF»
			«ENDFOR»
			«FOR resetSignal : getResetSysSignals().keySet»
			.«resetSignal»(«IF getResetSysSignals().get(resetSignal).equals("HIGH")»!«ENDIF»rst_ni)«IF !(this.luts.empty)»,«ENDIF»
			«ENDFOR»
			«IF !(this.luts.empty)»// Multi-Dataflow Kernel ID
			.ID(slv_reg0[31:24])«ENDIF»
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
	
	def printCtrl(){
		'''
		/*
		 * Module: multi_dataflow_ctrl.sv
		 */
		 
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
		  // Ctrl/flags signals
		  ctrl_slave_t   slave_ctrl;
		  flags_slave_t  slave_flags;
		  ctrl_regfile_t reg_file;
		  // Uloop signals
		  logic [223:0]  ucode_flat;
		  uloop_code_t   ucode;
		  ctrl_uloop_t   ucode_ctrl;
		  flags_uloop_t  ucode_flags;
		  logic [11:0][31:0] ucode_registers_read;
		  // Standard registers
		  logic unsigned [31:0] static_reg_nb_iter;
		  logic unsigned [31:0] static_reg_len_iter;
		  logic unsigned [31:0] static_reg_vectstride;
		  logic unsigned [31:0] static_reg_onestride;
		  logic unsigned [15:0] static_reg_shift;
		  logic static_reg_simplemul;
		  // Custom register files
  		  logic unsigned [(32-1):0] static_reg_0;
		  «FOR port : portMap.keySet»
		  logic unsigned [(32-1):0] static_reg_«portMap.get(port)+1»;
		  «ENDFOR»
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
		  assign evt_o = slave_flags.evt;
		  
		  /* Direct register file mappings */
		  // Standard registers
		  assign static_reg_nb_iter    = reg_file.hwpe_params[REG_NB_ITER]  + 1;
		  assign static_reg_len_iter   = reg_file.hwpe_params[REG_LEN_ITER] + 1;
		  assign static_reg_shift      = reg_file.hwpe_params[REG_SHIFT_SIMPLEMUL][31:16];
		  assign static_reg_simplemul  = reg_file.hwpe_params[REG_SHIFT_SIMPLEMUL][0];
		  assign static_reg_vectstride = reg_file.hwpe_params[REG_SHIFT_VECTSTRIDE];
		  assign static_reg_onestride  = 4;
		  
		  // Custom registers
		  assign static_reg_0 = reg_file.hwpe_params[CONFIG];
  		«FOR port : portMap.keySet»
  		  assign static_reg_«portMap.get(port)» = reg_file.hwpe_params[PORT_«port.name»];
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
		  assign ucode_registers_read[UCODE_MNEM_ITERSTRIDE] = static_reg_vectstride;
		  assign ucode_registers_read[UCODE_MNEM_ONESTRIDE]  = static_reg_onestride;
		  assign ucode_registers_read[11:3] = '0;
		  
		  hwpe_ctrl_uloop #(
		    .NB_LOOPS       ( 1  ),
		    .NB_REG         ( 4  ),
		    .NB_RO_REG      ( 12 ),
		    .DEBUG_DISPLAY  ( 0  )
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
		    fsm_ctrl.simple_mul = static_reg_simplemul;
		    fsm_ctrl.shift      = static_reg_shift[$clog2(32)-1:0];
		    fsm_ctrl.len        = static_reg_len_iter[$clog2(CNT_LEN):0];
		    // Custom register file mappings to fsm
		    fsm_ctrl.config    = static_reg_0;
		    «FOR port : portMap.keySet»
		    fsm_ctrl.port_«port.name»    = static_reg_«portMap.get(port)»;
		    «ENDFOR»
		  end
		  
		endmodule
		'''
	}
	
	def printFSM(){
		'''
		
		/*
		 * Module: multi_dataflow_fsm.sv
		 */
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
		    // direct mappings - these have to be here due to blocking/non-blocking assignment
		    // combination with the same ctrl_engine_o/ctrl_streamer_o variable
		    // shift-by-3 due to conversion from bits to bytes
		    //
		    // INITIALIZATION
		    //
		    
		    /* INPUT FLOW */
		    «FOR input : inputMap.keySet»
		    // «input.name» stream
		    ctrl_streamer_o.«input.name»_source_ctrl.addressgen_ctrl.trans_size  = ctrl_i.len;
		    ctrl_streamer_o.«input.name»_source_ctrl.addressgen_ctrl.line_stride = '0;
		    ctrl_streamer_o.«input.name»_source_ctrl.addressgen_ctrl.line_length = ctrl_i.len;
		    ctrl_streamer_o.«input.name»_source_ctrl.addressgen_ctrl.feat_stride = '0;
		    ctrl_streamer_o.«input.name»_source_ctrl.addressgen_ctrl.feat_length = 1;
		    ctrl_streamer_o.«input.name»_source_ctrl.addressgen_ctrl.base_addr   = reg_file_i.hwpe_params[PORT_«input.name»_ADDR] + (flags_ucode_i.offs[PORT_«input.name»_UCODE_OFFS]);
		    ctrl_streamer_o.«input.name»_source_ctrl.addressgen_ctrl.feat_roll   = '0;
		    ctrl_streamer_o.«input.name»_source_ctrl.addressgen_ctrl.loop_outer  = '0;
		    ctrl_streamer_o.«input.name»_source_ctrl.addressgen_ctrl.realign_type = '0;
		    
		    «ENDFOR»
		    
		    /* OUTPUT FLOW */
		    «FOR output : outputMap.keySet»
		    // «output.name» stream
		    // ctrl_streamer_o.«output.name»_sink_ctrl.addressgen_ctrl.trans_size  = (ctrl_i.simple_mul) ? ctrl_i.len : 1;
		    ctrl_streamer_o.«output.name»_sink_ctrl.addressgen_ctrl.trans_size  =  ctrl_i.len;
		    ctrl_streamer_o.«output.name»_sink_ctrl.addressgen_ctrl.line_stride = '0;
		    // ctrl_streamer_o.«output.name»_sink_ctrl.addressgen_ctrl.line_length = (ctrl_i.simple_mul) ? ctrl_i.len : 1;
		    ctrl_streamer_o.«output.name»_sink_ctrl.addressgen_ctrl.line_length =  ctrl_i.len;
		    ctrl_streamer_o.«output.name»_sink_ctrl.addressgen_ctrl.feat_stride = '0;
		    ctrl_streamer_o.«output.name»_sink_ctrl.addressgen_ctrl.feat_length = 1;
		    ctrl_streamer_o.«output.name»_sink_ctrl.addressgen_ctrl.base_addr   = reg_file_i.hwpe_params[PORT_«output.name»_ADDR] + (flags_ucode_i.offs[PORT_«output.name»_UCODE_OFFS]);
		    ctrl_streamer_o.«output.name»_sink_ctrl.addressgen_ctrl.feat_roll   = '0;
		    ctrl_streamer_o.«output.name»_sink_ctrl.addressgen_ctrl.loop_outer  = '0;
		    ctrl_streamer_o.«output.name»_sink_ctrl.addressgen_ctrl.realign_type = '0;
		    //
		    
		    «ENDFOR»
		    
		    // ucode
		    // ctrl_ucode_o.accum_loop = '0; // this is not relevant for this simple accelerator, and it should be moved from
		                                     // ucode to an accelerator-specific module
		    // engine
		    ctrl_engine_o.clear      = '1;
		    ctrl_engine_o.enable     = '1;
		    ctrl_engine_o.start      = '0;
		    ctrl_engine_o.simple_mul = ctrl_i.simple_mul;
		    ctrl_engine_o.shift      = ctrl_i.shift;
		    ctrl_engine_o.len        = ctrl_i.len;
		    ctrl_engine_o.config    = ctrl_i.config;
		    «FOR port : portMap.keySet»
		    ctrl_engine_o.port_«port.name»    = ctrl_i.port_«port.name»;
		    «ENDFOR»
		
		    // slave
		    ctrl_slave_o.done = '0;
		    ctrl_slave_o.evt  = '0;
		    
		    // real finite-state machine
		    next_state   = curr_state;
        	«FOR input : inputMap.keySet»
          	ctrl_streamer_o.«input.name»_source_ctrl.req_start    = '0;
          	«ENDFOR»
	        «FOR output : outputMap.keySet SEPARATOR " & "»
    		ctrl_streamer_o.«output.name»_sink_ctrl.req_start      = '0;
    		«ENDFOR»
		    ctrl_ucode_o.enable                        = '0;
		    ctrl_ucode_o.clear                         = '0;
		    
		    //
		    // STATES
		    //
		    case(curr_state)
		      FSM_IDLE: begin
		        // wait for a start signal
		        ctrl_ucode_o.clear = '1;
		        if(flags_slave_i.start) begin
		          next_state = FSM_START;
		        end
		      end
		      FSM_START: begin
		        // update the indeces, then load the first feature
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
		          ctrl_engine_o.enable = 1'b1;
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
		        //if((flags_engine_i.cnt == ctrl_i.len) & flags_engine_i.acc_valid)
		          //next_state = FSM_UPDATEIDX;
		        if (flags_engine_i.cnt == ctrl_i.len)
		          next_state = FSM_TERMINATE;
		        if(flags_engine_i.ready) begin
		          ctrl_engine_o.start  = 1'b1;
		          ctrl_engine_o.clear  = 1'b0;
		          ctrl_engine_o.enable = 1'b1;
		        end
		      end
		      FSM_UPDATEIDX: begin
		        // update the indeces, then go back to load or idle
		        if(flags_ucode_i.valid == 1'b0) begin
		          ctrl_ucode_o.enable = 1'b1;
		        end
		        else if(flags_ucode_i.done) begin
		        // else if(flags_engine_i.cnt == ctrl_i.len) begin // interface with Vivado HLS --> finished filtering input data?
		        // if(flags_engine_i.cnt == ctrl_i.len) begin
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
		          ctrl_engine_o.enable = 1'b1;
		          «FOR input : inputMap.keySet»
		          ctrl_streamer_o.«input.name»_source_ctrl.req_start = 1'b1;
				  «ENDFOR»
				  «FOR output : outputMap.keySet SEPARATOR " & "»
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
		        ctrl_engine_o.enable = 1'b0;
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
		          ctrl_engine_o.enable = 1'b1;
  		          «FOR input : inputMap.keySet»
  		          ctrl_streamer_o.«input.name»_source_ctrl.req_start = 1'b1;
  				  «ENDFOR»
  				  «FOR output : outputMap.keySet SEPARATOR " & "»
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
	
	def printBender(){
		'''
		hw-mac-engine:
		  incdirs : [
		    rtl
		  ]
		  files : [
		    rtl/multi_dataflow_package.sv,
		    rtl/multi_dataflow_fsm.sv,
		    rtl/multi_dataflow_ctrl.sv,
		    rtl/multi_dataflow_streamer.sv,
		    rtl/multi_dataflow_engine.sv,
		    rtl/multi_dataflow_top.sv,
		    wrap/multi_dataflow_top_wrap.sv
		  ]
		  vlog_opts : [
		    "-L hwpe_ctrl_lib",
		    "-L hwpe_stream_lib"
		  ]
		'''
	}
	
	def printPackage(){
		'''
		
		/*
		 * Module: multi_dataflow_package.sv
		 */
		 
		import hwpe_stream_package::*;
		
		package multi_dataflow_package;
		  parameter int unsigned CNT_LEN = 1024; // maximum length of the vectors for a scalar product
		  /* Registers */
		  // TCDM addresses
		  «FOR port : portMap.keySet»
		  parameter int unsigned PORT_«port.name»_ADDR              = «portMap.get(port)»;
		  «ENDFOR»
		  
		  // Standard registers
		  parameter int unsigned REG_NB_ITER              = «portMap.size»;
		  parameter int unsigned REG_LEN_ITER             = «portMap.size+1»;
		  parameter int unsigned REG_SHIFT_SIMPLEMUL      = «portMap.size+2»;
		  parameter int unsigned REG_SHIFT_VECTSTRIDE     = «portMap.size+3»;
		  parameter int unsigned REG_SHIFT_VECTSTRIDE2    = «portMap.size+4»; // Added to be aligned with sw (not used in hw)
		  
		  // Custom register files
		  parameter int unsigned CONFIG             = «portMap.size+5»;
		  «FOR port : portMap.keySet»
		  parameter int unsigned PORT_«port.name»             = «portMap.get(port)+6»;
		  «ENDFOR»
		  
		  // microcode offset indeces -- this should be aligned to the microcode compiler of course!
		  «FOR port : portMap.keySet»
		  parameter int unsigned PORT_«port.name»_UCODE_OFFS              = «portMap.get(port)»;
		  «ENDFOR»
		  
		  // microcode mnemonics -- this should be aligned to the microcode compiler of course!
		  parameter int unsigned UCODE_MNEM_NBITER     = 4 - 4;
		  parameter int unsigned UCODE_MNEM_ITERSTRIDE = 5 - 4;
		  parameter int unsigned UCODE_MNEM_ONESTRIDE  = 6 - 4;
		  
		  typedef struct packed {
		    logic clear;
		    logic enable;
		    logic simple_mul;
		    logic start;
		    logic unsigned [$clog2(32)-1       :0] shift;
		    logic unsigned [$clog2(CNT_LEN):0] len; // 1 bit more as cnt starts from 1, not 0
		    // Custom register files
		    logic unsigned [(32-1):0] config;
		    «FOR port : portMap.keySet»
		    logic unsigned [(32-1):0] port_«port.name»;
		    «ENDFOR»
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
		    logic simple_mul;
		    logic unsigned [$clog2(32)-1       :0] shift;
		    logic unsigned [$clog2(CNT_LEN):0] len; // 1 bit more as cnt starts from 1, not 0
		    // Custom register files
		    logic unsigned [(32-1):0] config;
		    «FOR port : portMap.keySet»
		    logic unsigned [(32-1):0] port_«port.name»;
		    «ENDFOR»
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
	
	def printStreamer(){
		'''
		/*
		 * multi_dataflow_streamer.sv
		 */
		
		import mac_package::*;
		import hwpe_stream_package::*;
		
		module multi_dataflow_streamer
		#(
		  parameter int unsigned MP = «portMap.size», // number of master ports
		  parameter int unsigned FD = 2  // FIFO depth
		)
		(
		  // global signals
		  input  logic                   clk_i,
		  input  logic                   rst_ni,
		  input  logic                   test_mode_i,
		  // local enable & clear
		  input  logic                   enable_i,
		  input  logic                   clear_i,
		
	    «FOR input : inputMap.keySet»
	      // input «input.name» stream + handshake
	      hwpe_stream_intf_stream.source stream_if_«input.name»,
	    «ENDFOR»
	    «FOR output : outputMap.keySet»
	      // output «output.name» stream + handshake
	      hwpe_stream_intf_stream.sink stream_if_«output.name».sink,
	    «ENDFOR»
		
		  // TCDM ports
		  hwpe_stream_intf_tcdm.master tcdm [MP-1:0],
		
		  // control channel
		  input  ctrl_streamer_t  ctrl_i,
		  output flags_streamer_t flags_o
		);
		
		logic «FOR input : inputMap.keySet SEPARATOR ", "»«input.name»_tcdm_fifo_ready«ENDFOR»;		
		
		«FOR port : portMap.keySet»
		  hwpe_stream_intf_stream #(
		    .DATA_WIDTH ( 32 )
		  ) stream_if_«port.name»_prefifo (
		    .clk ( clk_i )
		  );
	    «ENDFOR»
		
		  hwpe_stream_intf_tcdm tcdm_fifo [MP-1:0] (
		    .clk ( clk_i )
		  );
		
  		«FOR port : portMap.keySet»
  		  hwpe_stream_intf_tcdm tcdm_fifo_«portMap.get(port)» [0:0] (
		    .clk ( clk_i )
		  );
		«ENDFOR»
		
		  // source and sink modules
		  «FOR input : inputMap.keySet»
		  hwpe_stream_source #(
		    .DATA_WIDTH ( 32 ),
		    .DECOUPLED  ( 1  )
		  ) i_«input.name»_source (
		    .clk_i              ( clk_i                  ),
		    .rst_ni             ( rst_ni                 ),
		    .test_mode_i        ( test_mode_i            ),
		    .clear_i            ( clear_i                ),
		    .tcdm               ( tcdm_fifo_«portMap.get(input)»), // this syntax is necessary for Verilator as hwpe_stream_source expects an array of interfaces
		    .stream             ( «input.name»_prefifo.source),
		    .ctrl_i             ( ctrl_i.«input.name»_source_ctrl   ),
		    .flags_o            ( flags_o.«input.name»_source_flags ),
		    .tcdm_fifo_ready_o  ( «input.name»_tcdm_fifo_ready      )
		  );
		  
		  «ENDFOR»
		  «FOR output : outputMap.keySet»
		  hwpe_stream_sink #(
		    .DATA_WIDTH ( 32 )
		  ) i_d_sink (
		    .clk_i       ( clk_i                ),
		    .rst_ni      ( rst_ni               ),
		    .test_mode_i ( test_mode_i          ),
		    .clear_i     ( clear_i              ),
		    .tcdm        ( tcdm_fifo_«portMap.get(output)»), // this syntax is necessary for Verilator as hwpe_stream_source expects an array of interfaces
		    .stream      ( «output.name»_postfifo.sink      ),
		    .ctrl_i      ( ctrl_i.«output.name»_sink_ctrl   ),
		    .flags_o     ( flags_o.«output.name»_sink_flags )
		  );
		  
		  «ENDFOR»
		
		
		  // TCDM-side FIFOs
		«FOR input : inputMap.keySet»
		  hwpe_stream_tcdm_fifo_load #(
		    .FIFO_DEPTH ( 4 )
		  ) i_«input.name»_tcdm_fifo_load (
		    .clk_i       ( clk_i             ),
		    .rst_ni      ( rst_ni            ),
		    .clear_i     ( clear_i           ),
		    .flags_o     (                   ),
		    .ready_i     ( «input.name»_tcdm_fifo_ready ),
		    .tcdm_slave  ( tcdm_fifo_«portMap.get(input)»[0]    ),
		    .tcdm_master ( tcdm      [«portMap.get(input)»]     )
		  );
		  
		«ENDFOR»
		
		«FOR output : outputMap.keySet»
		  hwpe_stream_tcdm_fifo_store #(
		    .FIFO_DEPTH ( 4 )
		  ) i_«output.name»_tcdm_fifo_store (
		    .clk_i       ( clk_i          ),
		    .rst_ni      ( rst_ni         ),
		    .clear_i     ( clear_i        ),
		    .flags_o     (                ),
		    .tcdm_slave  ( tcdm_fifo_«portMap.get(output)»[0] ),
		    .tcdm_master ( tcdm       [«portMap.get(output)»] )
		  );
		«ENDFOR»
		
		  // datapath-side FIFOs
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
		    .pop_o   ( stream_if_«input.name»            ),
		    .flags_o (                )
		  );
		  
		«ENDFOR»
		
		«FOR output : outputMap.keySet»
		  hwpe_stream_fifo #(
		    .DATA_WIDTH( 32 ),
		    .FIFO_DEPTH( 2  ),
		    .LATCH_FIFO( 0  )
		  ) i_«output»_fifo (
		    .clk_i   ( clk_i             ),
		    .rst_ni  ( rst_ni            ),
		    .clear_i ( clear_i           ),
		    .push_i  ( «output.name»_i               ),
		    .pop_o   ( stream_if_«output.name»_postfifo.source ),
		    .flags_o (                   )
		  );
		  
		«ENDFOR»
		
		endmodule // multi_dataflow_streamer
		'''
	}
	
	def printTestBench() {
		
		var dateFormat = new SimpleDateFormat("yyyy/MM/dd HH:mm:ss");
		var date = new Date();
		
		'''
		`timescale 1ns / 1ps
		// ----------------------------------------------------------------------------
		//
		// This file has been automatically generated by:
		// Multi-Dataflow Composer tool - Platform Composer
		// TIL Test Bench module
		// on «dateFormat.format(date)»
		// More info available at http://sites.unica.it/rpct/		
		//
		// ----------------------------------------------------------------------------	
		
		// ----------------------------------------------------------------------------
		// Module Interface
		// ----------------------------------------------------------------------------
		module tb_copr;
		// ----------------------------------------------------------------------------
		
		// ----------------------------------------------------------------------------
		// Module Parameters
		// ----------------------------------------------------------------------------
		parameter SIZEID = 8;				// size of Kernel ID signal
		parameter SIZEADDRESS = 12;			// size of the local memory address signal
		parameter SIZECOUNT = 12;			// size of the size counters
		parameter SIZEPORT = «portSize»;	// bits needed to codify the number of ports
		parameter SIZEDATA = «dataSize»;	// size of the data signal
		parameter SIZEBURST = 8;			// size of the burst counter
		parameter SIZESIGNAL = 1; 			// size of the control signals
		parameter FIFO_DEPTH = 4; 				//	FIFO depth
		parameter f_ptr_width = 5; 			//	because depth =16 + OVERFLOW
		parameter f_half_full_value = 8;	//
		parameter f_almost_full_value = 14;	//
		parameter f_almost_empty_value = 2;	//
		// ----------------------------------------------------------------------------
		
		// ----------------------------------------------------------------------------
		// Module Signals
		// ----------------------------------------------------------------------------
		// Input Reg(s)
		reg clk;
		reg rst;
		reg [SIZEDATA-1 : 0] 		datain;		// local memory - data in
		reg [SIZEADDRESS-1 : 0] 	addressrd;	// local memory - read address
		reg [SIZEADDRESS-1 : 0] 	addresswr; 	// local memory - write address
		reg 						enablerd;	// local memory - enable read port
		reg							enablewr;   // local memory - enable write port
		reg 						write;      // local memory - write enable
		reg [SIZEID-1 : 0] 			kernelIDin; // kernel ID
		reg 						kernelIDen;
		«FOR port : portMap.keySet()»
		reg [SIZEDATA-1 : 0] 		confin_«portMap.get(port)»;
		reg 						en_«portMap.get(port)»;
		«ENDFOR»
		// Output Wire(s)
		wire [SIZEDATA-1 : 0] 		dataout;
		wire [SIZEID-1 : 0] 		kernelIDout;
		//wire 						finish;
		
		integer i;
		// ----------------------------------------------------------------------------
		
		// ----------------------------------------------------------------------------
		// Unit Under Test Instantiation
		// ----------------------------------------------------------------------------
		coprocessor #(
			.SIZEID(SIZEID),
			.SIZEADDRESS(SIZEADDRESS),
			.SIZECOUNT(SIZECOUNT),
			.SIZEPORT(SIZEPORT),
			.SIZEDATA(SIZEDATA),
			.SIZEBURST(SIZEBURST),
			.SIZESIGNAL(SIZESIGNAL),
			.FIFO_DEPTH(FIFO_DEPTH)//,
			//.f_ptr_width(f_ptr_width)//,
			//.f_half_full_value(f_ptr_width), 
			//.f_almost_full_value(f_almost_full_value),
			//.f_almost_empty_value(f_almost_empty_value) 
			)
		uut (
			.clk(clk),
			.rst(rst),
			.datain(datain),
			.addressrd(addressrd),
			.addresswr(addresswr),
			.enablerd(enablerd),
			.enablewr(enablewr),
			.write(write),
			.kernelIDin(kernelIDin),
			.kernelIDen(kernelIDen),
			.kernelIDout(kernelIDout),
			«FOR port : portMap.keySet()»
			.confin_«portMap.get(port)»(confin_«portMap.get(port)»),
			.en_«portMap.get(port)»(en_«portMap.get(port)»),
			«ENDFOR»
			.dataout(dataout)
			//.finish(finish)
		);
		// ----------------------------------------------------------------------------
		
		// ----------------------------------------------------------------------------
		// Body
		// ----------------------------------------------------------------------------
		
		// Clock Always
		always 
			#5 clk = ~clk;
		
		// Input(s) Setting
		initial begin
		
			// Initialize Input(s)
			clk = 0;
			rst = 0;
			datain = 0;
			addressrd = 0;
			addresswr = 0;
			enablerd = 0;
			enablewr = 0;
			write = 0;
			kernelIDin = 0;
			kernelIDen = 0;
			«FOR port : portMap.keySet()»
			confin_«portMap.get(port)» = 0;
			en_«portMap.get(port)» = 0;
			«ENDFOR»
			// Reset System
			#12	rst = 1;
			#10	rst = 0;
			
			// Write Data into Memory
			#10	enablewr = 1;	// enable writing port
				write = 1;		// enable write
				«FOR input : inputMap.keySet()»
				for(i=0;i<4;i=i+1)
				begin
				datain = «inputMap.get(input)*10»+i;		// written data «inputMap.get(input)*10»
				addresswr = «inputMap.get(input)*10»+i;	// write address «inputMap.get(input)-1»
				#10;
				end
				«ENDFOR»
				enablewr = 0; 	// disable writing port
				write = 0;		// disable write
		
			// Setting Configuration Registers
			#10
				«FOR port : portMap.keySet()»
				confin_«portMap.get(port)» = (1<<(SIZEADDRESS+SIZECOUNT))	// burst port «portMap.get(port)»
												| (4<<SIZEADDRESS)			// size port «portMap.get(port)»
												| «portMap.get(port)» *10;	// baseaddr port «portMap.get(port)»
				en_«portMap.get(port)» = 1;
				«ENDFOR»
			#10
				«FOR port : portMap.keySet()»
				en_«portMap.get(port)» = 0;
				«ENDFOR»
			
			// Setting Kernel ID (Start Computation)
			#10	kernelIDin = 1;	// kernel ID 1
				kernelIDen = 1;
			#10 kernelIDen = 0;
		
			#200 $stop;
		end
		// ----------------------------------------------------------------------------
		
		endmodule		
		// ----------------------------------------------------------------------------
		// ----------------------------------------------------------------------------
		// ----------------------------------------------------------------------------
		'''
	}
		
	def printRegs(){
		
		var dateFormat = new SimpleDateFormat("yyyy/MM/dd HH:mm:ss");
		var date = new Date();
		var log2_regnumb = computeSizePointer();
		
		'''
	// ----------------------------------------------------------------------------
	//
	// This file has been automatically generated by:
	// Multi-Dataflow Composer tool - Platform Composer
	// Configuration Registers module
	// on «dateFormat.format(date)»
	// More info available at http://sites.unica.it/rpct// 
	//
	// ----------------------------------------------------------------------------	
	
	// ----------------------------------------------------------------------------
	// Module Interface
	// ----------------------------------------------------------------------------
	module config_registers #(
		// Width of S_AXI data bus
		parameter integer C_S_AXI_DATA_WIDTH	= 32,
		// Width of S_AXI address bus
		parameter integer C_S_AXI_ADDR_WIDTH	= «log2_regnumb+2»
	)
	(
		«IF coupling.equals("mm")»
		input done,
		«IF enableMonitoring»
		«FOR String monitor: monList»
		// Monitor «monList.indexOf(monitor)»: «monitor»
		input [C_S_AXI_DATA_WIDTH - 1 : 0] «monitor»,
		output clear_monitor_«monList.indexOf(monitor)»,
		«ENDFOR»
		«ENDIF»
		// Config Regs
		«FOR port : portMap.keySet»
		output reg [C_S_AXI_DATA_WIDTH-1:0]    slv_reg«portMap.get(port)+1»,
		«ENDFOR»
		«IF enableMonitoring»
		// Monitoring Config Registers
		«FOR String monitor: monList»	
		output reg [C_S_AXI_DATA_WIDTH-1:0]    slv_reg«portMap.size+1+monList.indexOf(monitor)»,
		«ENDFOR»
		«ENDIF»
		output start,
		«ELSE»
		«FOR output : outputMap.keySet»output reg [C_S_AXI_DATA_WIDTH-1:0]    slv_reg«outputMap.get(output)+1»,
		«ENDFOR»
		«ENDIF»
		output reg [C_S_AXI_DATA_WIDTH-1:0]    slv_reg0,

		// Global Clock Signal
		input wire  S_AXI_ACLK,
		// Global Reset Signal. This Signal is Active LOW
		input wire  S_AXI_ARESETN,
		// Write address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
		// Write channel Protection type. This signal indicates the
		// privilege and security level of the transaction, and whether
		// the transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_AWPROT,
		// Write address valid. This signal indicates that the master signaling
		// valid write address and control information.
		input wire  S_AXI_AWVALID,
		// Write address ready. This signal indicates that the slave is ready
		// to accept an address and associated control signals.
		output wire  S_AXI_AWREADY,
		// Write data (issued by master, acceped by Slave) 
		input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
		// Write strobes. This signal indicates which byte lanes hold
		// valid data. There is one write strobe bit for each eight
		// bits of the write data bus.    
		input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
		// Write valid. This signal indicates that valid write
		// data and strobes are available.
		input wire  S_AXI_WVALID,
		// Write ready. This signal indicates that the slave
		// can accept the write data.
		output wire  S_AXI_WREADY,
		// Write response. This signal indicates the status
		// of the write transaction.
		output wire [1 : 0] S_AXI_BRESP,
		// Write response valid. This signal indicates that the channel
		// is signaling a valid write response.
		output wire  S_AXI_BVALID,
		// Response ready. This signal indicates that the master
		// can accept a write response.
		input wire  S_AXI_BREADY,
		// Read address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
		// Protection type. This signal indicates the privilege
		// and security level of the transaction, and whether the
		// transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_ARPROT,
		// Read address valid. This signal indicates that the channel
		// is signaling valid read address and control information.
		input wire  S_AXI_ARVALID,
		// Read address ready. This signal indicates that the slave is
		// ready to accept an address and associated control signals.
		output wire  S_AXI_ARREADY,
		// Read data (issued by slave)
		output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
		// Read response. This signal indicates the status of the
		// read transfer.
		output wire [1 : 0] S_AXI_RRESP,
		// Read valid. This signal indicates that the channel is
		// signaling the required read data.
		output wire  S_AXI_RVALID,
		// Read ready. This signal indicates that the master can
		// accept the read data and response information.
		input wire  S_AXI_RREADY
	);
	
		// AXI4LITE signals
		reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
		reg  	axi_awready;
		reg  	axi_wready;
		reg [1 : 0] 	axi_bresp;
		reg  	axi_bvalid;
		reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
		reg  	axi_arready;
		reg [C_S_AXI_DATA_WIDTH-1 : 0] 	axi_rdata;
		reg [1 : 0] 	axi_rresp;
		reg  	axi_rvalid;
	
		// Example-specific design signals
		// local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
		// ADDR_LSB is used for addressing 32/64 bit registers/memories
		// ADDR_LSB = 2 for 32 bits (n downto 2)
		// ADDR_LSB = 3 for 64 bits (n downto 3)
		localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
		localparam integer OPT_MEM_ADDR_BITS = «log2_regnumb»;

		//----------------------------------------------
		//-- Signals for user logic register space example
		//------------------------------------------------
		wire	 slv_reg_rden;
		wire	 slv_reg_wren;
		reg [C_S_AXI_DATA_WIDTH-1:0]	 reg_data_out;
		integer	 byte_index;
	
		// I/O Connections assignments
	
		assign S_AXI_AWREADY	= axi_awready;
		assign S_AXI_WREADY	= axi_wready;
		assign S_AXI_BRESP	= axi_bresp;
		assign S_AXI_BVALID	= axi_bvalid;
		assign S_AXI_ARREADY	= axi_arready;
		assign S_AXI_RDATA	= axi_rdata;
		assign S_AXI_RRESP	= axi_rresp;
		assign S_AXI_RVALID	= axi_rvalid;
		
		
		// Implement axi_awready generation
		// axi_awready is asserted for one S_AXI_ACLK clock cycle when both
		// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
		// de-asserted when reset is low.
		always @( posedge S_AXI_ACLK )
		begin
		  if ( S_AXI_ARESETN == 1'b0 )
		    begin
		      axi_awready <= 1'b0;
		    end 
		  else
		    begin    
		      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID)
		        begin
		          // slave is ready to accept write address when 
		          // there is a valid write address and write data
		          // on the write address and data bus. This design 
		          // expects no outstanding transactions. 
		          axi_awready <= 1'b1;
		        end
		      else           
		        begin
		          axi_awready <= 1'b0;
		        end
		    end 
		end
		
		// Implement axi_awaddr latching
		// This process is used to latch the address when both 
		// S_AXI_AWVALID and S_AXI_WVALID are valid. 
		always @( posedge S_AXI_ACLK )
		begin
		  if ( S_AXI_ARESETN == 1'b0 )
		    begin
		      axi_awaddr <= 0;
		    end 
		  else
		    begin    
		      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID)
		        begin
		          // Write Address latching 
		          axi_awaddr <= S_AXI_AWADDR;
		        end
		    end 
		end
		
		// Implement axi_wready generation
		// axi_wready is asserted for one S_AXI_ACLK clock cycle when both
		// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
		// de-asserted when reset is low. 
		always @( posedge S_AXI_ACLK )
		begin
		  if ( S_AXI_ARESETN == 1'b0 )
		    begin
		      axi_wready <= 1'b0;
		    end 
		  else
		    begin    
		      if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID)
		        begin
		          // slave is ready to accept write data when 
		          // there is a valid write address and write data
		          // on the write address and data bus. This design 
		          // expects no outstanding transactions. 
		          axi_wready <= 1'b1;
		        end
		      else
		        begin
		          axi_wready <= 1'b0;
		        end
		    end 
		end
		
	// Implement memory mapped register select and write logic generation
	// The write data is accepted and written to memory mapped registers when
	// axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
	// select byte enables of slave registers while writing.
	// These registers are cleared when reset (active low) is applied.
	// Slave register write enable is asserted when valid address and data are available
	// and the slave is ready to accept the write address and write data.
	assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
      slv_reg0 <=  32'd4; //inizialize the accelerator as ready
      «IF coupling.equals("mm")»
      «FOR port : portMap.keySet»
      slv_reg«portMap.get(port)+1» <= 0;
      «ENDFOR» 
      «IF enableMonitoring»
  	  «FOR String monitor: monList»	
  	  slv_reg«portMap.size+1+monList.indexOf(monitor)» <= 0;
  	  «ENDFOR»
      «ENDIF»
      «ELSE»
      «FOR output : outputMap.keySet»
      slv_reg«outputMap.get(output)+1» <= 0;
      «ENDFOR»
      «ENDIF»
		end 
		else begin
		«IF coupling.equals("mm")»
		if (done)
			slv_reg0 <= {slv_reg0[31:3],1'b1,slv_reg0[1:0]};
		else
		«ENDIF»
		if (slv_reg_wren)
		begin
		case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS-1:ADDR_LSB] )
		«log2_regnumb»'h0:
		for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
		if ( S_AXI_WSTRB[byte_index] == 1 ) begin
		// Respective byte enables are asserted as per write strobes 
		// Slave register 0
		slv_reg0[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
		end
		«IF coupling.equals("mm")»
	    «FOR port : portMap.keySet»		«log2_regnumb»'h«portMap.get(port)+1»:
	    	for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	    	if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	        	// Respective byte enables are asserted as per write strobes
	        	// Slave register «portMap.get(port)+1»
	        	slv_reg«portMap.get(port)+1»[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	        	end
	    «ENDFOR»
	    «IF enableMonitoring»
      	«FOR String monitor: monList»    	«log2_regnumb»'h«portMap.size+1+monList.indexOf(monitor)»:	
      		for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
		if ( S_AXI_WSTRB[byte_index] == 1 ) begin
    		// Respective byte enables are asserted as per write strobes
    		// Slave register «portMap.size+1+monList.indexOf(monitor)»
    		slv_reg«portMap.size+1+monList.indexOf(monitor)»[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
    	end
      	«ENDFOR»
		«ENDIF»
	    «ELSE»
	    «FOR output : outputMap.keySet»		«log2_regnumb»'h«outputMap.get(output)+4»:
	    		for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	    			if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	        		// Respective byte enables are asserted as per write strobes
	        		// Slave register «outputMap.get(output)+4»
	        		slv_reg«outputMap.get(output)+1»[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	        		end
	        	
	    «ENDFOR»
	    «ENDIF»
		default : begin
		slv_reg0 <= slv_reg0;
		«IF coupling.equals("mm")»
		«FOR port : portMap.keySet»
		slv_reg«portMap.get(port)+1» <= slv_reg«portMap.get(port)+1»;
		«ENDFOR»
		«FOR String monitor: monList»
		slv_reg«portMap.size+1+monList.indexOf(monitor)» <= slv_reg«portMap.size+1+monList.indexOf(monitor)»;
		«ENDFOR»
		«ELSE»
	  	«FOR output : outputMap.keySet»
	  	slv_reg«outputMap.get(output)+1» <= slv_reg«outputMap.get(output)+1»;
	  	«ENDFOR»
		«ENDIF»
		end
		endcase
		end
	  end
	end
		
		assign start = (slv_reg_wren) && (axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS-1:ADDR_LSB]==0) &&
						(S_AXI_WSTRB[0]==1) && (S_AXI_WDATA[0]==1'b1);
						
		«IF enableMonitoring»
		«FOR String monitor: monList»
		// clear of monitor «monitor»
		assign clear_monitor_«monList.indexOf(monitor)» = (slv_reg_wren) && (axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS-1:ADDR_LSB]==«portMap.size+1+monList.indexOf(monitor)») && 
								(S_AXI_WSTRB[0]==1) && (S_AXI_WDATA[31]==1'b1);
		«ENDFOR»
		«ENDIF»	
		
		// Implement write response logic generation
		// The write response and response valid signals are asserted by the slave 
		// when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
		// This marks the acceptance of address and indicates the status of 
		// write transaction.
		always @( posedge S_AXI_ACLK )
		begin
		  if ( S_AXI_ARESETN == 1'b0 )
		    begin
		      axi_bvalid  <= 0;
		      axi_bresp   <= 2'b0;
		    end 
		  else
		    begin    
		      if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
		        begin
		          // indicates a valid write response is available
		          axi_bvalid <= 1'b1;
		          axi_bresp  <= 2'b0; // 'OKAY' response 
		        end                   // work error responses in future
		      else
		        begin
		          if (S_AXI_BREADY && axi_bvalid) 
		            //check if bready is asserted while bvalid is high) 
		            //(there is a possibility that bready is always asserted high)   
		            begin
		              axi_bvalid <= 1'b0; 
		            end  
		        end
		    end
		end
		
		// Implement axi_arready generation
		// axi_arready is asserted for one S_AXI_ACLK clock cycle when
		// S_AXI_ARVALID is asserted. axi_awready is 
		// de-asserted when reset (active low) is asserted. 
		// The read address is also latched when S_AXI_ARVALID is 
		// asserted. axi_araddr is reset to zero on reset assertion.
		always @( posedge S_AXI_ACLK )
		begin
		  if ( S_AXI_ARESETN == 1'b0 )
		    begin
		      axi_arready <= 1'b0;
		      axi_araddr  <= 32'b0;
		    end 
		  else
		    begin    
		      if (~axi_arready && S_AXI_ARVALID)
		        begin
		          // indicates that the slave has acceped the valid read address
		          axi_arready <= 1'b1;
		          // Read address latching
		          axi_araddr  <= S_AXI_ARADDR;
		        end
		      else
		        begin
		          axi_arready <= 1'b0;
		        end
		    end 
		end 
		
		// Implement axi_arvalid generation
		// axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
		// S_AXI_ARVALID and axi_arready are asserted. The slave registers 
		// data are available on the axi_rdata bus at this instance. The 
		// assertion of axi_rvalid marks the validity of read data on the 
		// bus and axi_rresp indicates the status of read transaction.axi_rvalid 
		// is deasserted on reset (active low). axi_rresp and axi_rdata are 
		// cleared to zero on reset (active low).  
		always @( posedge S_AXI_ACLK )
		begin
		  if ( S_AXI_ARESETN == 1'b0 )
		    begin
		      axi_rvalid <= 0;
		      axi_rresp  <= 0;
		    end 
		  else
		    begin    
		      if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
		        begin
		          // Valid read data is available at the read data bus
		          axi_rvalid <= 1'b1;
		          axi_rresp  <= 2'b0; // 'OKAY' response
		        end   
		      else if (axi_rvalid && S_AXI_RREADY)
		        begin
		          // Read data is accepted by the master
		          axi_rvalid <= 1'b0;
		        end                
		    end
		end
		
		// Implement memory mapped register select and read logic generation
		// Slave register read enable is asserted when valid address is available
		// and the slave is ready to accept the read address.
		assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;
		always @(*)
		begin
			// Address decoding for reading registers
			case ( axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS-1:ADDR_LSB] )
			«log2_regnumb»'h0   : reg_data_out <= slv_reg0;
			«IF coupling.equals("mm")»«FOR port : portMap.keySet»
			«log2_regnumb»'h«portMap.get(port)+1»   : reg_data_out <= slv_reg«portMap.get(port)+1»;
			«ENDFOR»
			«IF enableMonitoring»
			«FOR String monitor: monList»
			«log2_regnumb»'h«portMap.size+1+monList.indexOf(monitor)»   : reg_data_out <= «monitor»;
			«ENDFOR»
			«ENDIF»
			«ELSE»«FOR output : outputMap.keySet»«log2_regnumb»'h«outputMap.get(output)+1»   : reg_data_out <= slv_reg«outputMap.get(output)+1»;
			«ENDFOR»«ENDIF»
			default : reg_data_out <= 0;
			endcase
		end
		
		// Output register or memory read data
		always @( posedge S_AXI_ACLK )
		begin
		  if ( S_AXI_ARESETN == 1'b0 )
		    begin
		      axi_rdata  <= 0;
		    end 
		  else
		    begin    
		      // When there is a valid read address (S_AXI_ARVALID) with 
		      // acceptance of read address by the slave (axi_arready), 
		      // output the read dada 
		      if (slv_reg_rden)
		        begin
		          axi_rdata <= reg_data_out;     // register read data
		        end   
		    end
		end

	endmodule
	'''
	}
	
	def printXML(){
		
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

}