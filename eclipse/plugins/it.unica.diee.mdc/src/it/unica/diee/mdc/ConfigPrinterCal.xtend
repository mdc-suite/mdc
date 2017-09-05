package it.unica.diee.mdc

import java.text.SimpleDateFormat
import java.util.Date
import java.util.List

import it.unica.diee.mdc.sboxManagement.SboxLut
import java.util.Map

/**
 * A CAL Network Configurator printer. 
 * 
 * printConfig() prints the CAL file:
 * <ul>
 * <li> print header comments: headerComments();
 * <li> print interface: printInterface();
 * <li> print body: printBody().
 * </ul> 
 * 
 * @author Carlo Sau
 */
class ConfigPrinterCal {
	
	var List<SboxLut> luts
	
	var Map<Integer,String> configMap
	
	
	/**
	 * Print the header of the file
	 */
	def headerComments(){
				
		var dateFormat = new SimpleDateFormat("yyyy/MM/dd HH:mm:ss");
		var date = new Date();
		'''
		// ----------------------------------------------------------------------------
		//
		// Multi-Dataflow Composer tool - XDF Generation
		// Network Configurator
		// Date: «dateFormat.format(date)»
		//
		// ----------------------------------------------------------------------------
		'''	
		
	}
	
	/**
	 * Print the body of the file
	 */
	def printBody(String type) {
		
		'''
		«IF type.equals("STATIC")»
		bool SEL[«luts.size()»] = SEL1;
		
		«FOR id : configMap.keySet»
		// ID = «id» «configMap.get(id)»
		bool SEL«id»[«luts.size()»] = [
		«FOR lut : luts SEPARATOR ","»	«lut.getLutValue(configMap.get(id))»
		«ENDFOR»];
		
		«ENDFOR»
		«ELSE»
		«FOR id : configMap.keySet»
		// ID = «id»
		execute_«configMap.get(id)»: action 
			ID : [id] 
				==>
		«FOR lut : luts SEPARATOR ","»
		sel«lut.getCount()»:[«lut.getLutValue(configMap.get(id))»]
		«ENDFOR»
		guard id = «id»
		end
		
		«ENDFOR»
		«ENDIF»
		'''
	}
	
	/**
	 * 
	 * Print the interface of the file
	 */
	def printInterface(String type) {
		
		var lastLut = luts.get(luts.size-1);
		
		'''
		«IF type.equals("STATIC")»
		unit Configurator:
		«ELSE»
		actor Configurator()
			int(size=8) ID 
				==> 
			«FOR lut : luts»
			bool sel«lut.getCount()»«IF !lut.equals(lastLut)»,«ENDIF»
«ENDFOR»:
		«ENDIF»
		'''
	}
	
	/**
	 * <ul>
	 * <li> print header comments: headerComments();
	 * <li> print interface: printInterface();
	 * <li> print the body of the CAL sbox: printBody().
	 * </ul>
	 */
	def printConfig(String type, String packageName, 
		List<SboxLut> luts, Map<Integer,String> configMap
	){
				
		// Initialize members
		this.luts = luts
		this.configMap = configMap;
		
		'''
		«headerComments()»
		package «packageName»;
		
		«printInterface(type)»
		
		«printBody(type)»
		end
		'''
	}
	
	

}