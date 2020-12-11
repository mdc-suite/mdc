package it.mdc.tool.core.platformComposer;

import java.text.SimpleDateFormat
import java.util.Date
import java.util.List
import net.sf.orcc.df.Actor
import net.sf.orcc.df.Network
import net.sf.orcc.df.Port
import it.mdc.tool.core.sboxManagement.SboxLut
import java.util.Map
import net.sf.orcc.ir.util.ExpressionEvaluator
import net.sf.orcc.ir.Expression

/**
 * A Verilog Multi-Dataflow Network Test Bench printer
 * 
 * printNetwork() is in charge of printing the top module.
 * 
 * @author Carlo Sau
 */
class TestBenchPrinterGeneric {
	
	
	var Network network;
		
	var ProtocolManager protocolManager;
	
	var ExpressionEvaluator evaluator;
			
	def String printSysSigDimension(String module, String sysSigId) {
		if (protocolManager.getSysSigSize(module,sysSigId) != 1) {
			return "[" + (protocolManager.getSysSigSize(module,sysSigId)-1) + " : 0] " 
		} else {
			return ""
		}
	}
	
	def String printCommSigDimension(String module, Actor actor, String commSigId, Port port) {
		if (protocolManager.getCommSigSize(module,actor,commSigId,port) != 1) {
			return "[" + (protocolManager.getCommSigSize(module,actor,commSigId,port)-1) + " : 0] " 
		} else {
			return ""
		}
	}
		
	def String printNetSysSigKind(String sysSigId){
		if (protocolManager.getNetSysSignals.get(sysSigId).get(ProtocolManager.KIND).equals("input"))
			return "reg"
		else
			return "wire"
	}
	
	def String printModCommSigKind(String pred, String commSigId){
		if (protocolManager.getModCommSignals.get(pred).get(commSigId).get(ProtocolManager.KIND).equals("input"))
			return "reg"
		else
			return "wire"
	}

	/**
	 * Print test bench time scale.
	 */
	 def printTimeScale(){
	 	'''
	 	`timescale 1 ns / 1 ps
	 	'''
	 }
	 
	/**
	 * Print the header of the Verilog file.
	 */
	def headerComments(){
		var dateFormat = new SimpleDateFormat("yyyy/MM/dd HH:mm:ss");
		var date = new Date();
		'''
		// ----------------------------------------------------------------------------
		//
		// Multi-Dataflow Composer tool - Platform Composer
		// Multi-Dataflow Test Bench module 
		// Date: «dateFormat.format(date)»
		//
		// Please note that the testbench manages only common signals to dataflows
		// - clock system signals
		// - reset system signals
		// - dataflow communication signals
		//
		// ----------------------------------------------------------------------------
		'''	
	}
	 
	/**
	 * Print test bench parameters.
	 */
	 def printParameters(Map<Integer,String> configMap) {
	 	'''
	 	«FOR sysSigId : protocolManager.getNetSysSignals.keySet»
		«IF protocolManager.getNetSysSignals.get(sysSigId).containsKey(ProtocolManager.CLOCK)»parameter «protocolManager.getNetSysSignals.get(sysSigId).get(ProtocolManager.NETP).toUpperCase»_PERIOD = 10;
		«ENDIF»
		«ENDFOR»
		
		«FOR input : network.inputs»
		«FOR config : configMap.keySet»
		parameter «input.name.toUpperCase»_«configMap.get(config).toUpperCase»_FILE = "«input.name»_«configMap.get(config)»_file.mem";
		parameter «input.name.toUpperCase»_«configMap.get(config).toUpperCase»_SIZE = 64;
		«ENDFOR»				
	 	«ENDFOR»

		«FOR output : network.outputs»
		«FOR config : configMap.keySet»
		parameter «output.name.toUpperCase»_«configMap.get(config).toUpperCase»_FILE = "«output.name»_«configMap.get(config)»_file.mem";
		parameter «output.name.toUpperCase»_«configMap.get(config).toUpperCase»_SIZE = 64;
		«ENDFOR»
	 	«ENDFOR»

	 	«FOR netVar : network.variables»parameter «IF netVar.type.sizeInBits != 1»[«netVar.type.sizeInBits-1»:0] «ENDIF»«netVar.name» = «evaluator.evaluateAsInteger(netVar.initialValue as Expression)»;
	 	«ENDFOR»
	 	'''
	 }
	 
	/**
	 * Print test bench internal signals.
	 */
	def printSignals(List<SboxLut> luts, Map<Integer,String> configMap) {
	 	
		'''
		reg start_feeding;
		«FOR input : network.inputs»
		«FOR commSigId : protocolManager.getFirstModCommSignals().keySet»
		«IF protocolManager.isInputSide(protocolManager.getFirstMod(),commSigId)»
		«printModCommSigKind(protocolManager.getFirstMod(),commSigId)» «printCommSigDimension(protocolManager.getFirstMod(),null,commSigId,input)»«protocolManager.getSigName(protocolManager.getFirstMod(),commSigId,input)»;
		«ENDIF»
		«ENDFOR»
		«FOR config : configMap.keySet»
		reg [«input.type.sizeInBits-1»:0] «input.name»_«configMap.get(config)»_file_data [«input.name.toUpperCase»_«configMap.get(config).toUpperCase»_SIZE-1:0];
		«ENDFOR»
		integer «input.name»_i = 0;
		«ENDFOR»
		
		«FOR output : network.outputs»
		«FOR commSigId :protocolManager.getLastModCommSignals().keySet»
		«IF protocolManager.isOutputSide(protocolManager.getLastMod(),commSigId)»
		«printModCommSigKind(protocolManager.getLastMod(),commSigId)» «printCommSigDimension(protocolManager.getLastMod(),null,commSigId,output)»«protocolManager.getSigName(protocolManager.getLastMod(),commSigId,output)»;
		«ENDIF»
		«ENDFOR»
		«FOR config : configMap.keySet»
		reg [«output.type.sizeInBits-1»:0] «output.name»_«configMap.get(config)»_file_data [«output.name.toUpperCase»_«configMap.get(config).toUpperCase»_SIZE-1:0];
		«ENDFOR»
		integer «output.name»_i = 0;
		«ENDFOR»
		
		«FOR netParm : network.parameters»
		reg «IF netParm.type.sizeInBits != 1»[«netParm.type.sizeInBits-1»:0] «ENDIF»«netParm.name»;
	 	«ENDFOR»
		
		«IF !luts.empty»
		reg [7:0] ID;
		«ENDIF»	
		
		«FOR sysSigId : protocolManager.getNetSysSignals.keySet»
		«printNetSysSigKind(sysSigId)» «printSysSigDimension(null,sysSigId)»«protocolManager.getNetSysSignals.get(sysSigId).get(ProtocolManager.NETP)»;
		«ENDFOR»	
		'''
	}
	
		 
	 /**
	  * read data files to initialize I/O
	  */
	 def readDataFiles(Map<Integer,String> configMap) {

	 	'''
	 	«FOR config : configMap.keySet»
	 	«FOR input : network.inputs»
	 	initial
	 	 	$readmemh(«input.name.toUpperCase»_«configMap.get(config).toUpperCase»_FILE, «input.name»_«configMap.get(config)»_file_data);
	 	«ENDFOR»
	 	«FOR output : network.outputs»
	 	initial
	 		$readmemh(«output.name.toUpperCase»_«configMap.get(config).toUpperCase»_FILE, «output.name»_«configMap.get(config)»_file_data);
	 	«ENDFOR»
	 	«ENDFOR»
	 	'''
	 }
	 
	/**
	 * Print top module interface.
	 */
	def printDUT(List<SboxLut> luts) {
		
		'''
		multi_dataflow «IF !network.variables.empty»
			«FOR netVar : network.variables SEPARATOR ","»
			.«netVar.name»(«netVar.name»)
			«ENDFOR»
		) «ENDIF»dut (
			«FOR input : network.inputs»
			«FOR commSigId : protocolManager.getModCommSignals.get(protocolManager.getFirstMod()).keySet»
			«IF protocolManager.isInputSide(protocolManager.getFirstMod(),commSigId)»
			.«protocolManager.getSigName(protocolManager.getFirstMod(),commSigId,input)»(«protocolManager.getSigName(protocolManager.getFirstMod(),commSigId,input)»),
			«ENDIF»
			«ENDFOR»
			
			«ENDFOR»
			«FOR output : network.outputs»
			«FOR commSigId : protocolManager.getModCommSignals.get(protocolManager.getLastMod()).keySet»
			«IF protocolManager.isOutputSide(protocolManager.getLastMod(),commSigId)»
			.«protocolManager.getSigName(protocolManager.getLastMod(),commSigId,output)»(«protocolManager.getSigName(protocolManager.getLastMod(),commSigId,output)»),
			«ENDIF»
			«ENDFOR»
			«ENDFOR»	
			
			«FOR netParm : network.parameters»
			.«netParm.name»(«netParm.name»),
			«ENDFOR»
			
			«IF !luts.empty»
			.ID(ID),
			«ENDIF»
					
			«FOR sysSigId : protocolManager.getNetSysSignals.keySet SEPARATOR ","»
			.«protocolManager.getNetSysSignals.get(sysSigId).get(ProtocolManager.NETP)»(«protocolManager.getNetSysSignals.get(sysSigId).get(ProtocolManager.NETP)»)
			«ENDFOR»
		);	
		'''
	}
	
	/**
	 * Print test bench clocks behavior.
	 */
	 def printClocks() {
	 	'''
		«FOR sysSigId : protocolManager.getNetSysSignals.keySet»
		«IF protocolManager.getNetSysSignals.get(sysSigId).containsKey(ProtocolManager.CLOCK)»
		always #(«protocolManager.getNetSysSignals.get(sysSigId).get(ProtocolManager.NETP).toUpperCase»_PERIOD/2)
			«protocolManager.getNetSysSignals.get(sysSigId).get(ProtocolManager.NETP)» = ~«protocolManager.getNetSysSignals.get(sysSigId).get(ProtocolManager.NETP)»;
		«ENDIF»
		«ENDFOR»
		'''
	 }
	 
	 
	 /**
	  * print signals initialization and behavior
	  */
	 def printInitial(List<SboxLut> luts, Map<Integer,String> configMap) {
	 	
	 	
	 	'''	 	
	 	initial
	 	begin
	 		// feeding flag initialization
	 		start_feeding = 0;
	 		
	 		«IF !luts.empty»
	 		// network configuration
	 		ID = 8'd0;
	 		«ENDIF»
	 		
	 		«IF !network.parameters.empty»
	 		// dynamic parameters initialization
	 		«FOR netParm : network.parameters»
			«netParm.name» = 0;
	 		«ENDFOR»
	 		«ENDIF»

	 		// clocks initialization
	 		«FOR sysSigId : protocolManager.getNetSysSignals.keySet»
			«IF protocolManager.getNetSysSignals.get(sysSigId).containsKey(ProtocolManager.CLOCK)»		«protocolManager.getNetSysSignals.get(sysSigId).get(ProtocolManager.NETP)» = 0;
			«ENDIF»
			«ENDFOR»

	 		// network signals initialization
			«FOR input : network.inputs»
			«FOR commSigId : protocolManager.getModCommSignals.get(protocolManager.getFirstMod()).keySet»
			«IF protocolManager.isInputSideDirect(protocolManager.getFirstMod(),commSigId)»
			«IF protocolManager.getMatchingWrapMapping(protocolManager.getFirstModCommSignals().get(commSigId).get(ProtocolManager.CH)).equals("data")»«protocolManager.getSigName(protocolManager.getFirstMod(),commSigId,input)» = 0;
			«ELSE»
			«protocolManager.getSigName(protocolManager.getFirstMod(),commSigId,input)»  = 1'b«IF protocolManager.isNegMatchingWrapMapping(protocolManager.getFirstModCommSignals().get(commSigId).get(ProtocolManager.CH))»1«ELSE»0«ENDIF»;
			«ENDIF»
			«ENDIF»
			«ENDFOR»
			«ENDFOR»
			«FOR output : network.outputs»
			«FOR commSigId : protocolManager.modCommSignals.get(protocolManager.getLastMod()).keySet»
			«IF protocolManager.isOutputSideReverse(protocolManager.getLastMod(),commSigId)»
			«protocolManager.getSigName(protocolManager.getLastMod(),commSigId,output)» = 1'b«IF protocolManager.isNegMatchingWrapMapping(protocolManager.getLastModCommSignals().get(commSigId).get(ProtocolManager.CH))»1«ELSE»0«ENDIF»;
			«ENDIF»
			«ENDFOR»
			«ENDFOR»
	 	
	 		// initial reset
			«FOR sysSigId : protocolManager.getNetSysSignals.keySet»
			«IF protocolManager.getNetSysSignals.get(sysSigId).containsKey(ProtocolManager.RST) || protocolManager.getNetSysSignals.get(sysSigId).containsKey(ProtocolManager.RSTN)»
			«protocolManager.getNetSysSignals.get(sysSigId).get(ProtocolManager.NETP)» = «IF protocolManager.getNetSysSignals.get(sysSigId).containsKey(ProtocolManager.RST)»0«ELSE»1«ENDIF»;
			«ENDIF»
			«ENDFOR»
	 		#2
			«FOR sysSigId : protocolManager.getNetSysSignals.keySet»
			«IF protocolManager.getNetSysSignals.get(sysSigId).containsKey(ProtocolManager.RST) || protocolManager.getNetSysSignals.get(sysSigId).containsKey(ProtocolManager.RSTN)»
			«protocolManager.getNetSysSignals.get(sysSigId).get(ProtocolManager.NETP)» = «IF protocolManager.getNetSysSignals.get(sysSigId).containsKey(ProtocolManager.RST)»1«ELSE»0«ENDIF»;
			«ENDIF»
			«ENDFOR»
	 		#100
			«FOR sysSigId : protocolManager.getNetSysSignals.keySet»
			«IF protocolManager.getNetSysSignals.get(sysSigId).containsKey(ProtocolManager.RST) || protocolManager.getNetSysSignals.get(sysSigId).containsKey(ProtocolManager.RSTN)»
			«protocolManager.getNetSysSignals.get(sysSigId).get(ProtocolManager.NETP)» = «IF protocolManager.getNetSysSignals.get(sysSigId).containsKey(ProtocolManager.RST)»0«ELSE»1«ENDIF»;
			«ENDIF»
			«ENDFOR»
	 		#100
	 	
	 		// network inputs (output side)
			«FOR output : network.outputs»
			«FOR commSigId : protocolManager.getModCommSignals.get(protocolManager.getLastMod()).keySet»
			«IF protocolManager.isOutputSideReverse(protocolManager.getLastMod(),commSigId)»
			«protocolManager.getSigName(protocolManager.getLastMod(),commSigId,output)» = 1'b«IF protocolManager.isNegMatchingWrapMapping(protocolManager.getLastModCommSignals().get(commSigId).get(ProtocolManager.CH))»1«ELSE»0«ENDIF»;
			«ENDIF»
			«ENDFOR»
			«ENDFOR»
			
	 		«FOR config : configMap.keySet»
	 		// executing «configMap.get(config)»
	 		ID = 8'd«config»;
			start_feeding = 1;
			«FOR input : network.inputs»
			while(«input.name»_i != «input.name.toUpperCase»_«configMap.get(config).toUpperCase»_SIZE)
				#10;
			«ENDFOR»
			start_feeding = 0;
			«FOR input : network.inputs»
			«FOR commSigId : protocolManager.getModCommSignals.get(protocolManager.getFirstMod()).keySet»
			«IF protocolManager.isInputSideDirect(protocolManager.getFirstMod(),commSigId)»
			«IF protocolManager.getMatchingWrapMapping(protocolManager.getFirstModCommSignals().get(commSigId).get(ProtocolManager.CH)).equals("data")»
			«protocolManager.getSigName(protocolManager.getFirstMod(),commSigId,input)» = 0;
			«ELSE»
			«protocolManager.getSigName(protocolManager.getFirstMod(),commSigId,input)»  = 1'b«IF protocolManager.isNegMatchingWrapMapping(protocolManager.getFirstModCommSignals().get(commSigId).get(ProtocolManager.CH))»1«ELSE»0«ENDIF»;
			«ENDIF»
			«ENDIF»
			«ENDFOR»
			«input.name»_i = 0;
			«ENDFOR»
			#1000
			«ENDFOR»

	 		$stop;
	 	end
	 	'''
	 }
	 
	 def printInputFeeding(Map<Integer,String> configMap){
	 	'''
	 	«FOR config : configMap.keySet»
	 	«FOR input : network.inputs»
	 	always@(*)
	 		if(start_feeding && ID == «config»)
 			begin
	 			while(«input.name»_i < «input.name.toUpperCase»_«configMap.get(config).toUpperCase»_SIZE)
	 			begin
	 				#10
		 			«FOR commSigId : protocolManager.getModCommSignals.get(protocolManager.getFirstMod()).keySet»
		 			«IF protocolManager.getMatchingWrapMapping(protocolManager.getFirstModCommSignals().get(commSigId).get(ProtocolManager.CH)).equals("full")»
		 			if(«protocolManager.getSigName(protocolManager.getFirstMod(),commSigId,input)» == «IF protocolManager.isNegMatchingWrapMapping(protocolManager.getFirstModCommSignals().get(commSigId).get(ProtocolManager.CH))»1«ELSE»0«ENDIF»)
		 			begin
					«ENDIF»
					«ENDFOR»
						«FOR commSigId : protocolManager.getModCommSignals.get(protocolManager.getFirstMod()).keySet»
						«IF protocolManager.isInputSideDirect(protocolManager.getFirstMod(),commSigId)»
						«IF protocolManager.getMatchingWrapMapping(protocolManager.getFirstModCommSignals().get(commSigId).get(ProtocolManager.CH)).equals("data")»
						«protocolManager.getSigName(protocolManager.getFirstMod(),commSigId,input)» = «input.name»_«configMap.get(config)»_file_data[«input.name»_i];
						«ELSE»
						«protocolManager.getSigName(protocolManager.getFirstMod(),commSigId,input)»  = 1'b«IF protocolManager.isNegMatchingWrapMapping(protocolManager.getFirstModCommSignals().get(commSigId).get(ProtocolManager.CH))»0«ELSE»1«ENDIF»;
						«ENDIF»
						«ENDIF»
						«ENDFOR»
	 					«input.name»_i = «input.name»_i + 1;
	 				end
	 				else
	 				begin
						«FOR commSigId : protocolManager.getModCommSignals.get(protocolManager.getFirstMod()).keySet»
						«IF protocolManager.isInputSideDirect(protocolManager.getFirstMod(),commSigId)»
						«IF protocolManager.getMatchingWrapMapping(protocolManager.getFirstModCommSignals().get(commSigId).get(ProtocolManager.CH)).equals("data")»
						«protocolManager.getSigName(protocolManager.getFirstMod(),commSigId,input)» = 0;
						«ELSE»
						«protocolManager.getSigName(protocolManager.getFirstMod(),commSigId,input)»  = 1'b«IF protocolManager.isNegMatchingWrapMapping(protocolManager.getFirstModCommSignals().get(commSigId).get(ProtocolManager.CH))»1«ELSE»0«ENDIF»;
						«ENDIF»
						«ENDIF»
						«ENDFOR»						
	 				end
	 			end
	 			#10
				«FOR commSigId : protocolManager.getModCommSignals.get(protocolManager.getFirstMod()).keySet»
				«IF protocolManager.isInputSideDirect(protocolManager.getFirstMod(),commSigId)»
				«IF protocolManager.getMatchingWrapMapping(protocolManager.getFirstModCommSignals().get(commSigId).get(ProtocolManager.CH)).equals("data")»
				«protocolManager.getSigName(protocolManager.getFirstMod(),commSigId,input)» = 0;
				«ELSE»
				«protocolManager.getSigName(protocolManager.getFirstMod(),commSigId,input)»  = 1'b«IF protocolManager.isNegMatchingWrapMapping(protocolManager.getFirstModCommSignals().get(commSigId).get(ProtocolManager.CH))»1«ELSE»0«ENDIF»;
				«ENDIF»
				«ENDIF»
				«ENDFOR»						
			end
		«ENDFOR»
		«ENDFOR»
	 	'''
	 }
	 	 
	 /**
	  * print output check logic
	  */
	 def printOutputCheck(Map<Integer,String> configMap){

	 	'''
	 	«FOR config : configMap.keySet»	
	 	«FOR output : network.outputs»always@(posedge «FOR sysSigId : protocolManager.getNetSysSignals.keySet»«IF protocolManager.getNetSysSignals.get(sysSigId).containsKey(ProtocolManager.CLOCK)»«protocolManager.getNetSysSignals.get(sysSigId).get(ProtocolManager.NETP)»«ENDIF»«ENDFOR»)
			if(ID == «config»)
				begin
				«FOR commSigId : protocolManager.getModCommSignals.get(protocolManager.getLastMod()).keySet»
				«IF protocolManager.getMatchingWrapMapping(protocolManager.getLastModCommSignals().get(commSigId).get(ProtocolManager.CH)).equals("push")»if(«protocolManager.getSigName(protocolManager.getLastMod(),commSigId,output)» == «IF protocolManager.isNegMatchingWrapMapping(protocolManager.getLastModCommSignals().get(commSigId).get(ProtocolManager.CH))»0«ELSE»1«ENDIF»)«ENDIF»
				«ENDFOR»
				«FOR commSigId : protocolManager.getModCommSignals.get(protocolManager.getLastMod()).keySet»
				«IF protocolManager.isOutputSideDirect(protocolManager.getLastMod(),commSigId)»
				«IF protocolManager.getMatchingWrapMapping(protocolManager.getLastModCommSignals().get(commSigId).get(ProtocolManager.CH)).equals("data")»	begin	
					if(«protocolManager.getSigName(protocolManager.getLastMod(),commSigId,output)» != «output.name»_«configMap.get(config)»_file_data[«output.name»_i])
						$display("Error for config %d on output %d: obtained %d, expected %d", «config», «output.name»_i, «protocolManager.getSigName(protocolManager.getLastMod(),commSigId,output)», «output.name»_«configMap.get(config)»_file_data[«output.name»_i]);
					«output.name»_i = «output.name»_i + 1;
					end
				«ENDIF»
				«ENDIF»
				«ENDFOR»
				if(«output.name»_i == «output.name.toUpperCase»_«configMap.get(config).toUpperCase»_SIZE)
					«output.name»_i = 0;
				end
		«ENDFOR»
		«ENDFOR»
	 	'''
	 }	
	
	/**
	 * Print the top module of the merged network.
	 * 
	 * <ul>
	 * <li> headerComments()
	 * <li> printInterface()
	 * <li> printInternalSignals()
	 * <li> printConfig()
	 * <li> printAssignments()
	 * </ul> 
	 * According with user options, also the following can be run.
	 * <ul>
	 * <li> printActors()
	 * <li> printEnableGenerator()
	 * <li> printPowerController()
	 * 
	 * </ul>
	 */
	def printTestBench(
		Network network, 
		List<SboxLut> luts,
		ProtocolManager protocolManager,
		Map<Integer,String> configMap
	){	 	
		
		// Initialize members
		this.network = network; 
		this.protocolManager = protocolManager;
		this.evaluator = new ExpressionEvaluator();
		
		'''
		«printTimeScale()»
		«headerComments()»

		module tb_multi_dataflow;
		
			// test bench parameters
			// ----------------------------------------------------------------------------
			«printParameters(configMap)»
			// ----------------------------------------------------------------------------
			
			// multi_dataflow signals
			// ----------------------------------------------------------------------------
			«printSignals(luts,configMap)»
			// ----------------------------------------------------------------------------
		
			// network input and output files
			// ----------------------------------------------------------------------------
			«readDataFiles(configMap)»
			// ----------------------------------------------------------------------------
		
			// dut
			// ----------------------------------------------------------------------------
			«printDUT(luts)»
			// ----------------------------------------------------------------------------
		
			// clocks
			// ----------------------------------------------------------------------------
			«printClocks()»
			// ----------------------------------------------------------------------------
		
			// signals evolution
			// ----------------------------------------------------------------------------
			«printInitial(luts,configMap)»
			// ----------------------------------------------------------------------------
		
			// input feeding
			// ----------------------------------------------------------------------------
			«printInputFeeding(configMap)»
			// ----------------------------------------------------------------------------
		
			// output check
			// ----------------------------------------------------------------------------
			«printOutputCheck(configMap)»
			// ----------------------------------------------------------------------------
		
		endmodule
		'''
	}
	
}
