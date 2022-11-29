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
class SboxPrinterGeneric {
	
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
	
	
	new (Map<String,Map<String,Map<String,String>>> modCommSignals){
		this.modCommSignals = modCommSignals
	}
	
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
	
	def printBody1x2MT() {
		'''
		parameter TAG_WIDTH = $clog2(NTHREADS);
		
		wire [TAG_WIDTH-1 : 0] tag;
		
		reg in1_full;
		
		assign tag = in1_data[TAG_WIDTH + SIZE -1 : SIZE];
		
		assign out1_data = sel[tag] ? '0 : in1_data;
		assign out2_data = sel[tag] ? in1_data : '0;
		assign out1_wr = sel[tag] ? '0: in1_wr;
		assign out2_wr = sel[tag] ? in1_wr : '0;
		
		integer i;
		always @(*)
			for(i = 0; i < NTHREADS; i = i+1)
				begin
				if(sel[i])
				  in1_full[i] = out2_full[i];
				else
				  in1_full[i] = out1_full[i];
				end
		'''	
	}
	
	
	def printBody2x1MT() {
		'''
		parameter TAG_WIDTH = $clog2(NTHREADS);
			
		logic [TAG_WIDTH-1 : 0] tag;
		
		reg out1_empty;
		reg in1_rd;
		reg in2_rd;
		
		««« Lo posso anche individuare con il for come negli attori
		always_comb
		    case(out1_rd)
		        2'b01: tag = 0;
		        2'b10: tag = 1;
		        default: tag = 'x;
		    endcase 
		
		assign out1_data = sel[tag] ? in2_data : in1_data;
		
		integer i;
		always @(*)
			for(i = 0; i < NTHREADS; i = i+1)
				begin
				if(sel[i])
				  begin
				  in2_rd[i] = out1_rd[i];
				  in1_rd[i] = '0;
				  out1_empty[i] = in2_empty[i];
				  end
				else
				  begin
				  in2_rd[i] = '0;
				  in1_rd[i] = out1_rd[i];
				  out1_empty[i] = in1_empty[i];
				  end
				end
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
			return "output logic"
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
	
	def printInterface1x2MT(){
		'''	
		module sbox1x2 #(
			parameter SIZE = 32,
			parameter NTHREADS = 0
		)(
			«FOR commSigId : modCommSignals.get(pred).keySet»
			«IF isInputSide(pred,commSigId)»
			«reverseKind(pred,commSigId)» «getCommSigDimension(pred,commSigId)»out1«getChannelSuffix(pred,commSigId)»,
			«reverseKind(pred,commSigId)» «getCommSigDimension(pred,commSigId)»out2«getChannelSuffix(pred,commSigId)»,
			«ENDIF»
			«ENDFOR»
			«FOR commSigId : modCommSignals.get(succ).keySet»
			«IF isOutputSide(succ,commSigId)»
			«reverseKind(succ,commSigId)» «getCommSigDimension(succ,commSigId)»in1«getChannelSuffix(succ,commSigId)»,
			«ENDIF»
			«ENDFOR»
			input [NTHREADS-1 : 0] sel
		);
		
		'''	
	}
	
	
	def printInterface2x1MT(){
		'''	
		module sbox2x1 #(
			parameter SIZE = 32,
			parameter NTHREADS = 0
		)(
			«FOR commSigId : modCommSignals.get(pred).keySet»
			«IF isInputSide(pred,commSigId)»
			«reverseKind(pred,commSigId)» «getCommSigDimension(pred,commSigId)»out1«getChannelSuffix(pred,commSigId)»,
			«ENDIF»
			«ENDFOR»
			«FOR commSigId : modCommSignals.get(succ).keySet»
			«IF isOutputSide(succ,commSigId)»
			«reverseKind(succ,commSigId)» «getCommSigDimension(succ,commSigId)»in1«getChannelSuffix(succ,commSigId)»,
			«reverseKind(succ,commSigId)» «getCommSigDimension(succ,commSigId)»in2«getChannelSuffix(succ,commSigId)»,
			«ENDIF»
			«ENDFOR»
			input [NTHREADS-1 : 0] sel
		);
		
		'''	
	}
	
	def printSbox(String type){

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
	
	
	def printSbox1x2MT(){
		pred = PRED;
		succ = ACTOR;
	
		'''		
		«headerComments("1x2")»
		
		«printInterface1x2MT()»
		
		«printBody1x2MT()»
		
		endmodule
		'''
	}
	
	def printSbox2x1MT(){
		pred = ACTOR;
		succ = PRED;
	
		'''		
		«headerComments("2x1")»
		
		«printInterface2x1MT()»
		
		«printBody2x1MT()»
		
		endmodule
		'''
	}	
	
	

}