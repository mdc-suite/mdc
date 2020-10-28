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
		assign stream_if_«input.name»_ready = «IF !isNegMatchingWrapMapping(getFullChannelWrapCommSignalID())»!«ENDIF»«input.getName()»_full;
		assign «input.getName()»_data = stream_if_«input.name»_data«IF getDataSize(input)<32» [«getDataSize(input)-1» : 0]«ENDIF»;
		assign «input.getName()»_push = stream_if_«input.name»_valid;
		«ENDFOR»
		«FOR output : outputMap.keySet()»
		assign stream_if_«output.name»_valid = «output.getName()»_push;
		assign stream_if_«output.name»_data = «IF getDataSize(output)<32»{{«32-getDataSize(output)»{1'b0}},«ENDIF»«output.getName()»_data«IF getDataSize(output)<32»}«ENDIF»;
		assign stream_if_«output.name»_strb = 4'b111;
		assign «output.getName()»_full = «IF !isNegMatchingWrapMapping(getFullChannelWrapCommSignalID())»!«ENDIF»stream_if_«output.name»_ready;
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
		  ucode_t   ucode;
		  ctrl_ucode_t   ucode_ctrl;
		  flags_ucode_t  ucode_flags;
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
  		  assign static_reg_«portMap.get(port)+1» = reg_file.hwpe_params[PORT_«port.name»];
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
		  
		  hwpe_ctrl_ucode #(
		    .NB_LOOPS       ( 1  ),
		    .NB_REG         ( 4  ),
		    .NB_RO_REG      ( 12 )		  
	     ) i_uloop (
		    .clk_i            ( clk_i                ),
		    .rst_ni           ( rst_ni               ),
		    .test_mode_i      ( test_mode_i          ),
		    .clear_i          ( clear_o              ),
		    .ctrl_i           ( ucode_ctrl           ),
		    .flags_o          ( ucode_flags          ),
		    .ucode_i          ( ucode                ),
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
		    fsm_ctrl.configuration    = static_reg_0;
		    «FOR port : portMap.keySet»
		    fsm_ctrl.port_«port.name»    = static_reg_«portMap.get(port)+1»;
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
		  output ctrl_ucode_t                           ctrl_ucode_o,
		  input  flags_ucode_t                          flags_ucode_i,
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
		    ctrl_engine_o.configuration    = ctrl_i.configuration;
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
		    logic unsigned [(32-1):0] configuration;
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
		    logic unsigned [(32-1):0] configuration;
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
		
		import multi_dataflow_package::*;
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
	      hwpe_stream_intf_stream.sink stream_if_«output.name»,
	    «ENDFOR»
		
		  // TCDM ports
		  hwpe_stream_intf_tcdm.master tcdm [MP-1:0],
		
		  // control channel
		  input  ctrl_streamer_t  ctrl_i,
		  output flags_streamer_t flags_o
		);
		
		logic «FOR input : inputMap.keySet SEPARATOR ", "»«input.name»_tcdm_fifo_ready«ENDFOR»;		
		
		«FOR input : portMap.keySet»
		  hwpe_stream_intf_stream #(
		    .DATA_WIDTH ( 32 )
		  ) «input.name»_prefifo (
		    .clk ( clk_i )
		  );
	    «ENDFOR»
		
		«FOR output : portMap.keySet»
		  hwpe_stream_intf_stream #(
		    .DATA_WIDTH ( 32 )
		  ) «output.name»_postfifo (
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
		  ) i_«output.name»_fifo (
		    .clk_i   ( clk_i             ),
		    .rst_ni  ( rst_ni            ),
		    .clear_i ( clear_i           ),
		    .push_i  ( stream_if_«output.name»               ),
		    .pop_o   ( «output.name»_postfifo.source ),
		    .flags_o (                   )
		  );
		  
		«ENDFOR»
		
		endmodule // multi_dataflow_streamer
		'''
	}
	
	def printWrap() {
		'''
		
		import multi_dataflow_package::*;
		import hwpe_ctrl_package::*;
		
		module multi_dataflow_top_wrap
		#(
		  parameter N_CORES = 2,
		  parameter MP  = «portMap.size»,
		  parameter ID  = 10
		)
		(
		  // global signals
		  input  logic                                  clk_i,
		  input  logic                                  rst_ni,
		  input  logic                                  test_mode_i,
		  // evnets
		  output logic [N_CORES-1:0][REGFILE_N_EVT-1:0] evt_o,
		  // tcdm master ports
		  output logic [MP-1:0]                         tcdm_req,
		  input  logic [MP-1:0]                         tcdm_gnt,
		  output logic [MP-1:0][31:0]                   tcdm_add,
		  output logic [MP-1:0]                         tcdm_wen,
		  output logic [MP-1:0][3:0]                    tcdm_be,
		  output logic [MP-1:0][31:0]                   tcdm_data,
		  input  logic [MP-1:0][31:0]                   tcdm_r_data,
		  input  logic [MP-1:0]                         tcdm_r_valid,
		  // periph slave port
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
	
}