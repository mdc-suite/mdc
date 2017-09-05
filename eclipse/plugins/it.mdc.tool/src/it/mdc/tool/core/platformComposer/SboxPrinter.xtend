/*
 *
 */
 
package it.mdc.tool.core.platformComposer

import java.text.SimpleDateFormat
import java.util.Date
import java.util.List

/**
 * A Verilog Network Configurator printer
 * 
 * @author Carlo Sau
 */
class SBoxPrinter {
	
	/**
	 * Protocol signals flags
	 */
	var int DIRECTION = 0;
	var int OUT_PORT = 1;
	var int SIZE = 2;
	var int IN_PORT = 3;
	
	var List<String[]> signals;
	
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

	
	def getSize(String[] signal) {
		if(signal.get(SIZE).equals("bufferSize"))
			return "DATA_SIZE";
		return Integer.parseInt(signal.get(SIZE));
	}	
	
	def printBody(String type) {
		'''
		«FOR signal : signals»
		«IF signal.get(DIRECTION).equals("dx")»
		«IF type.equals("1x2")»
		assign out1«IF !signal.get(OUT_PORT).equals("")»_«signal.get(OUT_PORT)»«ENDIF» = (sel) ? {«getSize(signal)»{1'b0}} : in1«IF !signal.get(IN_PORT).equals("")»_«signal.get(IN_PORT)»«ENDIF»;
		assign out2«IF !signal.get(OUT_PORT).equals("")»_«signal.get(OUT_PORT)»«ENDIF» = (sel) ? in1«IF !signal.get(IN_PORT).equals("")»_«signal.get(IN_PORT)»«ENDIF» : {«getSize(signal)»{1'b0}};
		«ELSE»
		assign out1«IF !signal.get(OUT_PORT).equals("")»_«signal.get(OUT_PORT)»«ENDIF» = (sel) ? in2«IF !signal.get(IN_PORT).equals("")»_«signal.get(IN_PORT)»«ENDIF» : in1«IF !signal.get(IN_PORT).equals("")»_«signal.get(IN_PORT)»«ENDIF»;
		«ENDIF»
		«ELSE»
		«IF type.equals("2x1")»
		assign in1«IF !signal.get(IN_PORT).equals("")»_«signal.get(IN_PORT)»«ENDIF» = (sel) ? {«getSize(signal)»{1'b0}} : out1«IF !signal.get(OUT_PORT).equals("")»_«signal.get(OUT_PORT)»«ENDIF»;
		assign in2«IF !signal.get(IN_PORT).equals("")»_«signal.get(IN_PORT)»«ENDIF» = (sel) ? out1«IF !signal.get(OUT_PORT).equals("")»_«signal.get(OUT_PORT)»«ENDIF» : {«getSize(signal)»{1'b0}};
		«ELSE»
		assign in1«IF !signal.get(IN_PORT).equals("")»_«signal.get(IN_PORT)»«ENDIF» = (sel) ? out2«IF !signal.get(OUT_PORT).equals("")»_«signal.get(OUT_PORT)»«ENDIF» : out1«IF !signal.get(OUT_PORT).equals("")»_«signal.get(OUT_PORT)»«ENDIF»;
		«ENDIF»
		«ENDIF»
		«ENDFOR»
		''' 
	}
	
	def printSignals(String type) {
		
		'''
		// Input(s)
		«FOR signal : signals»
		«IF signal.get(DIRECTION).equals("dx")»
		input«IF !getSize(signal).equals("1")» [«getSize(signal)»-1 : 0]«ENDIF» in1«IF !signal.get(IN_PORT).equals("")»_«signal.get(IN_PORT)»«ENDIF»;
		«IF type.equals("2x1")»
		input«IF !getSize(signal).equals("1")» [«getSize(signal)»-1 : 0]«ENDIF» in2«IF !signal.get(IN_PORT).equals("")»_«signal.get(IN_PORT)»«ENDIF»;
		«ENDIF»
		«ELSE»
		input«IF !getSize(signal).equals("1")» [«getSize(signal)»-1 : 0]«ENDIF» out1«IF !signal.get(OUT_PORT).equals("")»_«signal.get(OUT_PORT)»«ENDIF»;
		«IF type.equals("1x2")»
		input«IF !getSize(signal).equals("1")» [«getSize(signal)»-1 : 0]«ENDIF» out2«IF !signal.get(OUT_PORT).equals("")»_«signal.get(OUT_PORT)»«ENDIF»;
		«ENDIF»
		«ENDIF»
		«ENDFOR»
		input sel;
		
		// Ouptut(s)
		«FOR signal : signals»
		«IF signal.get(DIRECTION).equals("dx")»
		output«IF !getSize(signal).equals("1")» [«getSize(signal)»-1 : 0]«ENDIF» out1«IF !signal.get(OUT_PORT).equals("")»_«signal.get(OUT_PORT)»«ENDIF»;
		«IF type.equals("1x2")»
		output«IF !getSize(signal).equals("1")» [«getSize(signal)»-1 : 0]«ENDIF» out2«IF !signal.get(OUT_PORT).equals("")»_«signal.get(OUT_PORT)»«ENDIF»;
		«ENDIF»
		«ELSE»
		output«IF !getSize(signal).equals("1")» [«getSize(signal)»-1 : 0]«ENDIF» in1«IF !signal.get(IN_PORT).equals("")»_«signal.get(IN_PORT)»«ENDIF»;
		«IF type.equals("2x1")»
		output«IF !getSize(signal).equals("1")» [«getSize(signal)»-1 : 0]«ENDIF» in2«IF !signal.get(IN_PORT).equals("")»_«signal.get(IN_PORT)»«ENDIF»;
		«ENDIF»
		«ENDIF»
		«ENDFOR»
		
		// Wire(s)
		«FOR signal : signals»
		wire«IF !getSize(signal).equals("1")» [«getSize(signal)»-1 : 0]«ENDIF» in1«IF !signal.get(IN_PORT).equals("")»_«signal.get(IN_PORT)»«ENDIF»;
		«IF type.equals("2x1")»
		wire«IF !getSize(signal).equals("1")» [«getSize(signal)»-1 : 0]«ENDIF» in2«IF !signal.get(IN_PORT).equals("")»_«signal.get(IN_PORT)»«ENDIF»;
		«ENDIF»
		wire«IF !getSize(signal).equals("1")» [«getSize(signal)»-1 : 0]«ENDIF» out1«IF !signal.get(OUT_PORT).equals("")»_«signal.get(OUT_PORT)»«ENDIF»;
		«IF type.equals("1x2")»
		wire«IF !getSize(signal).equals("1")» [«getSize(signal)»-1 : 0]«ENDIF» out2«IF !signal.get(OUT_PORT).equals("")»_«signal.get(OUT_PORT)»«ENDIF»;
		«ENDIF»
		«ENDFOR»
		wire sel;
		'''
	}

	
	def printInterface(String type) {
		
		'''	
		module sbox«type»(
			«FOR signal : signals»
			in1«IF !signal.get(IN_PORT).equals("")»_«signal.get(IN_PORT)»«ENDIF»,
			«IF type.equals("2x1")»
			in2«IF !signal.get(IN_PORT).equals("")»_«signal.get(IN_PORT)»«ENDIF»,
			«ENDIF»
			out1«IF !signal.get(OUT_PORT).equals("")»_«signal.get(OUT_PORT)»«ENDIF»,
			«IF type.equals("1x2")»
			out2«IF !signal.get(OUT_PORT).equals("")»_«signal.get(OUT_PORT)»«ENDIF»,
			«ENDIF»
			«ENDFOR»
			sel
		);
		
		'''
	}
	
	def printSbox(String type, List<String[]> signals){
				
		this.signals = signals;

		'''
		«headerComments(type)»
		
		// ----------------------------------------------------------------------------
		// Module Interface
		// ----------------------------------------------------------------------------
		«printInterface(type)»
		// ----------------------------------------------------------------------------
		
		// ----------------------------------------------------------------------------
		// Module Parameter
		// ----------------------------------------------------------------------------
		parameter DATA_SIZE = 32;
		// ----------------------------------------------------------------------------
		
		// ----------------------------------------------------------------------------
		// Module Signals
		// ----------------------------------------------------------------------------
		«printSignals(type)»
		// ----------------------------------------------------------------------------
		
		// ----------------------------------------------------------------------------
		// Body
		// ----------------------------------------------------------------------------
		«printBody(type)»
		// ----------------------------------------------------------------------------
		
		endmodule
		// ----------------------------------------------------------------------------
		// ----------------------------------------------------------------------------
		// ----------------------------------------------------------------------------
		'''
	}
	
	
	

}