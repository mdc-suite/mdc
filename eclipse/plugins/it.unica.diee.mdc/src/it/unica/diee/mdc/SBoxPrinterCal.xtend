package it.unica.diee.mdc

import java.text.SimpleDateFormat
import java.util.Date
import java.util.List
import net.sf.orcc.df.Network

import it.unica.diee.mdc.sboxManagement.SboxLut
import java.util.Map
               
/**
 * A CAL Switching Boxes (SBoxes) printer.
 * 
 * printSboxes() prints the CAL file:
 * 
 * <ul>
 * <li> print header comments: headerComments();
 * <li> print interface: printInterface();
 * <li> print body: printBody().
 * </ul>
 * @author Carlo Sau
 */
class SBoxPrinterCal {
	
	var List<SboxLut> luts
	
	var Map<Integer,Network> configMap
	
	var String typeData
	var String typeSize
	var String typeSB
	
	/**
	 * Print the header of the file
	 */
	def headerComments(String ports){
				
		var dateFormat = new SimpleDateFormat("yyyy/MM/dd HH:mm:ss");
		var date = new Date();
		'''
		// ----------------------------------------------------------------------------
		//
		// Multi-Dataflow Composer tool - XDF Generation
		«IF ports.equals("1x2")»// 1-input 2-outputs Switching Box (1x2 SBox) - «typeData»«typeSize»
		«ELSE»// 2-inpus 1-output Switching Box (2x1 SBox) - «typeData»
		«ENDIF»
		// Date: «dateFormat.format(date)»
		//
		// ----------------------------------------------------------------------------
		'''	
		
	}
	
	/**
	 * Print the body of the file
	 */
	def printBody(String ports) {
		
		'''
		«IF !typeSB.equals("DUMMY")»
		«IF typeSB.equals("DYNAMIC")»
			bool selector := false;
			configure: action sel:[s] ==>
			do
				selector := s;
			end
			
			forward0: action in1: [a] ==> out1: [a]
			guard not selector
			end
			
			«IF ports.equals("1x2")»
			forward1: action in1: [a] ==> out2: [a]
			guard selector
			end
			«ELSE»
			forward1: action in2: [a] ==> out1: [a]
			guard selector
			end
			«ENDIF»
			
			schedule fsm init:
				init (configure) --> wait;
				wait (forward0) --> wait;
				wait (forward1) --> wait;
				wait (configure) --> wait;
			end
					
		«ELSE»
			forward0: action in1: [a] ==> out1: [a]
			guard not SEL[ID]
			end
			
			«IF ports.equals("1x2")»
			forward1: action in1: [a] ==> out2: [a]
			guard SEL[ID] 
			end
			«ELSE»
			forward1: action in2: [a] ==> out1: [a]
			guard SEL[ID] 
			end
			«ENDIF»
		«ENDIF»
		«ENDIF»
		'''
	}
	
	/**
	 * 
	 * Print the interface of the file
	 */
	def printInterface(String ports) {
		
		'''
		actor Sbox«IF ports.equals("1x2")»1x2«ELSE»2x1«ENDIF»«typeData»«IF typeData.equals("int")»«typeSize»«ENDIF» («IF typeSB.equals("STATIC")»int ID=0«IF typeData.equals("int")», int SIZE=«typeSize»«ENDIF»«ELSE»«IF typeData.equals("int")»int SIZE=«typeSize»«ENDIF»«ENDIF») 
			«IF typeSB.equals("DYNAMIC")»bool sel,«ENDIF»
			«typeData»«IF typeData.equals("int")»(size=SIZE)«ENDIF» in1«IF ports.equals("2x1")»,«ENDIF»
			«IF ports.equals("2x1")»«typeData»«IF typeData.equals("int")»(size=SIZE)«ENDIF» in2«ENDIF»
				==>
			«typeData»«IF typeData.equals("int")»(size=SIZE)«ENDIF» out1«IF ports.equals("1x2")»,«ENDIF»
			«IF ports.equals("1x2")»«typeData»«IF typeData.equals("int")»(size=SIZE)«ENDIF» out2«ENDIF»
		:
		'''
	}
	
	
	/**
	 * 
	 * <ul>
	 * <li> print header comments: headerComments();
	 * <li> print interface: printInterface();
	 * <li> print body: printBody().
	 * </ul>
	 */
	def printSboxes(String typeSB, String typeData, String typeSize, String ports, String packageName){
		
			
		this.typeData = typeData;
		this.typeSize = typeSize;
		this.typeSB = typeSB;
		
		// Initialize members
		this.luts = luts
		this.configMap = configMap;
		
		'''
		«headerComments(ports)»
		package «packageName»;
		«IF typeSB.equals("STATIC")»import «packageName».Configurator.SEL;«ENDIF»
		
		«printInterface(ports)»
		
		«printBody(ports)»
		end
		'''
	}
	
	

}