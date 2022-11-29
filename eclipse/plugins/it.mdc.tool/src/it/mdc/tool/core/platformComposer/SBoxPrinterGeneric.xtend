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
		
		assign tag = in1_din[TAG_WIDTH + SIZE -1 : SIZE];
		
		assign out1_din = sel[tag] ? '0 : in1_din;
		assign out2_din = sel[tag] ? in1_din : '0;
		assign out1_write = sel[tag] ? '0: in1_write;
		assign out2_write = sel[tag] ? in1_write : '0;
		
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
		
		integer j;
		always_comb
			begin                          
			for(j = 0; j < NTHREADS; j = j+1)
				if(out1_read == (1 << j)) 
					begin
						tag=j; 
						break;
					end
				else
					tag = 0;
			  end

		
		assign out1_dout = sel[tag] ? in2_dout : in1_dout;
		
		integer i;
		always_comb
			for(i = 0; i < NTHREADS; i = i+1)
				begin
				if(sel[i])
				  begin
				  in2_read[i] = out1_read[i];
				  in1_read[i] = '0;
				  out1_empty[i] = in2_empty[i];
				  end
				else
				  begin
				  in2_read[i] = '0;
				  in1_read[i] = out1_read[i];
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

	def String getCommSigSizeMT(String module, String commSigId) {
		if (modCommSignals.get(module).get(commSigId).get(SIZE).equals("variable") ) {
			return "$clog2(NTHREADS) + SIZE"
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

	def String getCommSigDimensionMT(String module, String commSigId) {
		if ( !getCommSigSizeMT(module,commSigId).equals("1") ) {
			return "[" + getCommSigSizeMT(module,commSigId) + "-1 : 0] " 
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
			«reverseKind(pred,commSigId)» «getCommSigDimensionMT(pred,commSigId)»out1«getChannelSuffix(pred,commSigId)»,
			«reverseKind(pred,commSigId)» «getCommSigDimensionMT(pred,commSigId)»out2«getChannelSuffix(pred,commSigId)»,
			«ENDIF»
			«ENDFOR»
			«FOR commSigId : modCommSignals.get(succ).keySet»
			«IF isOutputSide(succ,commSigId)»
			«reverseKind(succ,commSigId)» «getCommSigDimensionMT(succ,commSigId)»in1«getChannelSuffix(succ,commSigId)»,
			«ENDIF»
			«ENDFOR»
			input logic [NTHREADS-1 : 0] sel
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
			«reverseKind(pred,commSigId)» «getCommSigDimensionMT(pred,commSigId)»out1«getChannelSuffix(pred,commSigId)»,
			«ENDIF»
			«ENDFOR»
			«FOR commSigId : modCommSignals.get(succ).keySet»
			«IF isOutputSide(succ,commSigId)»
			«reverseKind(succ,commSigId)» «getCommSigDimensionMT(succ,commSigId)»in1«getChannelSuffix(succ,commSigId)»,
			«reverseKind(succ,commSigId)» «getCommSigDimensionMT(succ,commSigId)»in2«getChannelSuffix(succ,commSigId)»,
			«ENDIF»
			«ENDFOR»
			input logic [NTHREADS-1 : 0] sel
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