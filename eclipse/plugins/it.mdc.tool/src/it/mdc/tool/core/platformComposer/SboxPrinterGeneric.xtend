/*
 *
 */
 
package it.mdc.tool.core.platformComposer

import java.text.SimpleDateFormat
import java.util.Date
import java.util.Map

/**
 * A Verilog Network Configurator printer
 * 
 * @author Carlo Sau
 */
class SBoxPrinterGeneric {
	
	var String pred;
	var String succ;
	
	/**
	 * Protocol signals flags
	 */	
	private static final String ACTOR = "actor";
	private static final String PRED = "predecessor";
	private static final String SUCC = "successor";
	
	private static final String CH = "channel";
	private static final String KIND = "kind";
	private static final String DIR = "dir";
	private static final String SIZE = "size";
	
	var Map<String,Map<String,Map<String,String>>> modCommSignals;
	
	def headerComments(String type){
				
		var dateFormat = new SimpleDateFormat("yyyy/MM/dd HH:mm:ss");
		var date = new Date();

		'''
		// ----------------------------------------------------------------------------
		//
		// Multi-Dataflow Composer tool - Platform Composer
		// Sbox «type» module 
		// Date: «dateFormat.format(date)»
		//
		// ----------------------------------------------------------------------------
		'''	
		
	}	
	
	def getSourceSig(String module, String commSigId) {
		for (srcCommSigId : modCommSignals.get(succ).keySet ) {
			if(modCommSignals.get(module).get(commSigId).get(CH).equals(modCommSignals.get(succ).get(srcCommSigId).get(CH))) {
				return modCommSignals.get(succ).get(srcCommSigId).get(CH)
			}
		}
	}
	
	def printBody(String type) {
		'''
		«FOR commSigId : modCommSignals.get(pred).keySet»
		«IF isInputSide(pred,commSigId) && modCommSignals.get(pred).get(commSigId).get(DIR).equals("direct")»
		assign out1«getChannelSuffix(pred,commSigId)» = sel ? «IF type.equals("1x2")»{«getCommSigSize(pred, commSigId)»{1'b0}}«ELSE»in2«getChannelSuffix(succ,commSigId)»«ENDIF» : in1«getChannelSuffix(succ,commSigId)»;
		«IF type.equals("1x2")»
		assign out2«getChannelSuffix(pred,commSigId)» = sel ? in1«getChannelSuffix(succ,commSigId)» : {«getCommSigSize(pred, commSigId)»{1'b0}};
		«ENDIF»
		«ENDIF»
		«ENDFOR»
		«FOR commSigId : modCommSignals.get(succ).keySet»
		«IF isOutputSide(succ,commSigId) && modCommSignals.get(succ).get(commSigId).get(DIR).equals("reverse")»
		assign in1«getChannelSuffix(succ,commSigId)» = sel ? «IF type.equals("2x1")»{«getCommSigSize(succ, commSigId)»{1'b0}}«ELSE»out2«getChannelSuffix(pred,commSigId)»«ENDIF» : out1«getChannelSuffix(pred,commSigId)»;
		«IF type.equals("2x1")»
		assign in2«getChannelSuffix(succ,commSigId)» = sel ? out1«getChannelSuffix(pred,commSigId)» : {«getCommSigSize(pred, commSigId)»{1'b0}};
		«ENDIF»
		«ENDIF»
		«ENDFOR»
		''' 
	}
	
	def boolean isInputSide(String module, String commSigId) {
		if( (modCommSignals.get(module).get(commSigId).get(KIND).equals("input")
			&& modCommSignals.get(module).get(commSigId).get(DIR).equals("direct"))
			|| (modCommSignals.get(module).get(commSigId).get(KIND).equals("output")
			&& modCommSignals.get(module).get(commSigId).get(DIR).equals("reverse")) ) {
			return true		
		} else {
			return false
		}
	}
	
	def boolean isOutputSide(String module, String commSigId) {
		if( (modCommSignals.get(module).get(commSigId).get(KIND).equals("output")
			&& modCommSignals.get(module).get(commSigId).get(DIR).equals("direct"))
			|| (modCommSignals.get(module).get(commSigId).get(KIND).equals("input")
			&& modCommSignals.get(module).get(commSigId).get(DIR).equals("reverse")) ) {
			return true		
		} else {
			return false
		}
	}
	
	def String reverseKind(String module, String commSigId) {
		if(modCommSignals.get(module).get(commSigId).get(KIND).equals("input")) {
			return "output"
		} else {
			return "input"
		}
	}
	
	def String getCommSigSize(String module, String commSigId) {
		if (modCommSignals.get(module).get(commSigId).get(SIZE).equals("variable") ) {
			return "SIZE"
		} else if (modCommSignals.get(module).get(commSigId).get(SIZE).equals("broadcast") ) {
			return "1"
		} else {
			return modCommSignals.get(module).get(commSigId).get(SIZE)
		}
	}
	
	def String getCommSigDimension(String module, String commSigId) {
		if ( !getCommSigSize(module,commSigId).equals("1") ) {
			return "[" + getCommSigSize(module,commSigId) + "-1 : 0] " 
		} else {
			return ""
		}
	}
	
	def String getChannelSuffix(String module, String commSigId) {
		if(modCommSignals.get(module).get(commSigId).get(CH).equals("")) {
			""
		} else {
			"_" + modCommSignals.get(module).get(commSigId).get(CH)
		}
	}		
	
	def printInterface(String type) {
		
		
		'''	
		module sbox«type» #(
			parameter SIZE = 32
		)(
			«FOR commSigId : modCommSignals.get(pred).keySet»
			«IF isInputSide(pred,commSigId)»
			«reverseKind(pred,commSigId)» «getCommSigDimension(pred,commSigId)»out1«getChannelSuffix(pred,commSigId)»,
			«IF type.equals("1x2")»
			«reverseKind(pred,commSigId)» «getCommSigDimension(pred,commSigId)»out2«getChannelSuffix(pred,commSigId)»,
			«ENDIF»
			«ENDIF»
			«ENDFOR»
			«FOR commSigId : modCommSignals.get(succ).keySet»
			«IF isOutputSide(succ,commSigId)»
			«reverseKind(succ,commSigId)» «getCommSigDimension(succ,commSigId)»in1«getChannelSuffix(succ,commSigId)»,
			«IF type.equals("2x1")»
			«reverseKind(succ,commSigId)» «getCommSigDimension(succ,commSigId)»in2«getChannelSuffix(succ,commSigId)»,
			«ENDIF»
			«ENDIF»
			«ENDFOR»
			input sel
		);
		
		'''
	}
	
	def printSbox(String type, Map<String,Map<String,Map<String,String>>> modCommSignals){
				
		this.modCommSignals = modCommSignals;

		if (this.modCommSignals.containsKey(PRED)) {
			pred = PRED;
		} else {
			pred = ACTOR;	
	 	}
		if (this.modCommSignals.containsKey(SUCC)) {
			succ = SUCC;
		} else {
			succ = ACTOR;	
	 	}
	 	
		'''
		«headerComments(type)»
		
		«printInterface(type)»
		
		«printBody(type)»
		
		endmodule
		'''
	}
	
	
	

}