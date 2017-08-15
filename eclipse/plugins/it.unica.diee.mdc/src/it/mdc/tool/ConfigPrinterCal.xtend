package it.mdc.tool

import java.text.SimpleDateFormat
import java.util.Date
import java.util.List

import it.mdc.tool.sboxManagement.SboxLut
import java.util.Map

/*
 * A CAL Network Configurator printer
 * 
 * @author Carlo Sau
 */
class ConfigPrinterCal {
	
	var List<SboxLut> luts
	
	var Map<Integer,String> configMap
	
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