package it.mdc.tool.core.platformComposer;

import java.text.SimpleDateFormat
import java.util.Date
import java.util.List
import net.sf.orcc.df.Actor
import net.sf.orcc.df.Network
import net.sf.orcc.df.Port
import it.mdc.tool.core.sboxManagement.SboxLut

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
	 def printParameters() {
	 	'''
	 	«FOR sysSigId : protocolManager.getNetSysSignals.keySet»
		«IF protocolManager.getNetSysSignals.get(sysSigId).containsKey(ProtocolManager.CLOCK)»parameter «protocolManager.getNetSysSignals.get(sysSigId).get(ProtocolManager.NETP).toUpperCase»_PERIOD = 10;
		«ENDIF»
		«ENDFOR»
		«FOR input : network.inputs»
		parameter «input.name.toUpperCase»_FILE = "«input.name»_file.mem";
		parameter «input.name.toUpperCase»_SIZE = 64;
	 	«ENDFOR»

		«FOR output : network.outputs»
		parameter «output.name.toUpperCase»_FILE = "«output.name»_file.mem";
		parameter «output.name.toUpperCase»_SIZE = 64;
	 	«ENDFOR»
	 	'''
	 }
	 
	/**
	 * Print test bench internal signals.
	 */
	def printSignals(List<SboxLut> luts) {
	 	
		'''
		«FOR input : network.inputs»
		integer i_«input.name» = 0;
		«FOR commSigId : protocolManager.getFirstModCommSignals().keySet»
		«IF protocolManager.isInputSide(protocolManager.getFirstMod(),commSigId)»
		«printModCommSigKind(protocolManager.getFirstMod(),commSigId)» «printCommSigDimension(protocolManager.getFirstMod(),null,commSigId,input)»«protocolManager.getSigName(protocolManager.getFirstMod(),commSigId,input)»;
		«ENDIF»
		«ENDFOR»
		reg [«input.type.sizeInBits-1»:0] «input.name»_file_data [«input.name.toUpperCase»_SIZE-1:0];
		«ENDFOR»
		
		«FOR output : network.outputs»
		integer i_«output.name» = 0;
		«FOR commSigId :protocolManager.getLastModCommSignals().keySet»
		«IF protocolManager.isOutputSide(protocolManager.getLastMod(),commSigId)»
		«printModCommSigKind(protocolManager.getLastMod(),commSigId)» «printCommSigDimension(protocolManager.getLastMod(),null,commSigId,output)»«protocolManager.getSigName(protocolManager.getLastMod(),commSigId,output)»;
		«ENDIF»
		«ENDFOR»
		reg [«output.type.sizeInBits-1»:0] «output.name»_file_data [«output.name.toUpperCase»_SIZE-1:0];
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
	 def readDataFiles() {

	 	'''
	 	«FOR input : network.inputs»

	 	initial
	 	 	$readmemh(«input.name.toUpperCase»_FILE, «input.name»_file_data);
	 	«ENDFOR»
	 	«FOR output : network.outputs»

	 	initial
	 		$readmemh(«output.name.toUpperCase»_FILE, «output.name»_file_data);
	 	«ENDFOR»
	 	
	 	'''
	 }
	 
	/**
	 * Print top module interface.
	 */
	def printDUT(List<SboxLut> luts) {
		
		'''
		multi_dataflow dut(
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
	 def printInitial(List<SboxLut> luts) {
	 	
	 	'''	 	
	 	initial
	 	begin
	 		«IF !luts.empty»
	 		// network configuration
	 		ID = 8'd1;
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
	 	
	 		// network inputs (input side)
	 		«FOR input : network.inputs»while(i_«input.name» < «input.name.toUpperCase»_SIZE)
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
					«protocolManager.getSigName(protocolManager.getFirstMod(),commSigId,input)» = «input.name»_file_data[i_«input.name»];
					«ELSE»
					«protocolManager.getSigName(protocolManager.getFirstMod(),commSigId,input)»  = 1'b«IF protocolManager.isNegMatchingWrapMapping(protocolManager.getFirstModCommSignals().get(commSigId).get(ProtocolManager.CH))»0«ELSE»1«ENDIF»;
					«ENDIF»
					«ENDIF»
					«ENDFOR»
	 				i_«input.name» = i_«input.name» + 1;
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
			«ENDFOR»

	 		#1000
	 		$stop;
	 	end
	 	'''
	 }
	 	 
	 /**
	  * print output check logic
	  */
	 def printOutputCheck(){

	 	
	 	'''	 	
	 	«FOR output : network.outputs»always@(posedge «FOR sysSigId : protocolManager.getNetSysSignals.keySet»«IF protocolManager.getNetSysSignals.get(sysSigId).containsKey(ProtocolManager.CLOCK)»«protocolManager.getNetSysSignals.get(sysSigId).get(ProtocolManager.NETP)»«ENDIF»«ENDFOR»)
			«FOR commSigId : protocolManager.getModCommSignals.get(protocolManager.getLastMod()).keySet»
			«IF protocolManager.getMatchingWrapMapping(protocolManager.getLastModCommSignals().get(commSigId).get(ProtocolManager.CH)).equals("push")»if(«protocolManager.getSigName(protocolManager.getLastMod(),commSigId,output)» == «IF protocolManager.isNegMatchingWrapMapping(protocolManager.getLastModCommSignals().get(commSigId).get(ProtocolManager.CH))»0«ELSE»1«ENDIF»)«ENDIF»
			«ENDFOR»
			«FOR commSigId : protocolManager.getModCommSignals.get(protocolManager.getLastMod()).keySet»
			«IF protocolManager.isOutputSideDirect(protocolManager.getLastMod(),commSigId)»
			«IF protocolManager.getMatchingWrapMapping(protocolManager.getLastModCommSignals().get(commSigId).get(ProtocolManager.CH)).equals("data")»	begin	
				if(«protocolManager.getSigName(protocolManager.getLastMod(),commSigId,output)» != «output.name»_file_data[i_«output.name»])
					$display("Error on output %d: obtained %d, expected %d", i_«output.name», «protocolManager.getSigName(protocolManager.getLastMod(),commSigId,output)», «output.name»_file_data[i_«output.name»]);
				i_«output.name» = i_«output.name» + 1;
				end
			«ENDIF»
			«ENDIF»
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
		ProtocolManager protocolManager
	){	 	
		
		// Initialize members
		this.network = network; 
		this.protocolManager = protocolManager;
		
		'''
		«printTimeScale()»
		«headerComments()»

		module tb_multi_dataflow;
		
		// test bench parameters
		// ----------------------------------------------------------------------------
			«printParameters()»
		// ----------------------------------------------------------------------------
			
		// multi_dataflow signals
		// ----------------------------------------------------------------------------
			«printSignals(luts)»
		// ----------------------------------------------------------------------------
		
		// network input and output files
		// ----------------------------------------------------------------------------
			«readDataFiles()»
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
			«printInitial(luts)»
		// ----------------------------------------------------------------------------
		
		// output check
		// ----------------------------------------------------------------------------
			«printOutputCheck()»
		// ----------------------------------------------------------------------------
		
		endmodule
		'''
	}
	
}
