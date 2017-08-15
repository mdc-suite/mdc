/*
 *
 */
 
package it.unica.diee.mdc.platformComposer

import java.util.List
import net.sf.orcc.df.Network

import java.util.ArrayList
import java.util.Map
import java.util.HashMap
import net.sf.orcc.df.Portimport it.unica.diee.mdc.ConfigManager

/*
 * Template Interface Layer 
 * Generic HW Accelerator Printer
 * 
 * @author Carlo Sau
 */
class TilPrinter {
	
	protected Map <Port,Integer> inputMap;
	protected Map <Port,Integer> outputMap;
	protected Map <Port,Integer> portMap;
	protected List <Integer> signals;
	protected int portSize;
	protected int dataSize = 32;
	protected Map<String,List<Port>> netPorts;
	
	protected int INOUT = 0;
	protected int IN = 1;
	protected int OUT = 2;
	
	protected def computeNetsPorts(Map<String,Map<String,String>> networkVertexMap) {
		
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
	
	protected def computeSizePointer() {
		return Math.round((((Math.log10(portMap.size)/Math.log10(2))+0.5) as float))
	}
	
	protected def getLongId(int id) {
		if(id<10) {
			return "0"+id.toString();
		} else {
			return id.toString();	
		}
	}
		
	protected def mapInOut(Network network) {
		
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
	
		
	protected def mapSignals() {
		
		var size = Math.max(inputMap.size,outputMap.size);
		var index = 1;
		signals = new ArrayList(size);
		
		while(index<=size) {
			signals.add(index-1,index)
			index = index + 1;
		}
				
	}
	
	def printHdlSource(Network network, String module){''''''}
	def printIpPackage(Network network, String file){''''''}
	def printSoftwareDriver(Network network, Map<String,Map<String,String>> networkVertexMap, ConfigManager configManager, String file){''''''}

}