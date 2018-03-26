/*
 *
 */
 
package it.mdc.tool.prototyping

import java.text.SimpleDateFormat
import java.util.Date
import net.sf.orcc.df.Network
import java.util.ArrayList
import java.util.Map
import java.util.HashMap
import net.sf.orcc.df.Port
import it.mdc.tool.core.ConfigManager

/**
 * Vivado AXI IP Driver Printer 
 * 
 * @author Tiziana Fanni
 * @author Carlo Sau
 */
class DriverPrinter {
	
	Map <Port,Integer> portMap;
	Map <Port,Integer> inputMap;
	Map <Port,Integer> outputMap;
	boolean useDMA = false
	String coupling = "mm"
	
	def initDriverPrinter(String coupling, Map <Port,Integer> portMap,
							Map <Port,Integer> inputMap,Map <Port,Integer> outputMap) {
		this.coupling = coupling;
		this.portMap = portMap;
		this.inputMap = inputMap;
		this.outputMap = outputMap;						
	}
	
	def printHighDriver(Network network, Map<String,Map<String,String>> networkVertexMap, ConfigManager configManager) {
		
		var dateFormat = new SimpleDateFormat("yyyy/MM/dd HH:mm:ss");
		var date = new Date();
		var Map<String,ArrayList<Port>> netIdPortMap = new HashMap<String,ArrayList<Port>>();		
		var i = 0;
		
		for (String net : networkVertexMap.keySet()) {
			i=0;
			for(id : portMap.values.sort) {
				for(port : portMap.keySet) {
					if(portMap.get(port).equals(id)) {
						if(networkVertexMap.get(net).values.contains(port.name)) {
							if(!netIdPortMap.containsKey(net)) {
								var newList = new ArrayList<Port>();
								newList.add(i,port);
								netIdPortMap.put(net,newList);
							} else {
								netIdPortMap.get(net).add(i,port);
							}
						}
					}			
				}
			}
		}
		
		'''
		/*****************************************************************************
		*  Filename:          «coupling»_accelerator_h.c
		*  Description:       «IF coupling.equals("mm")»Memory-Mapped«ELSE»Stream«ENDIF» Accelerator High Level Driver
		*  Date:              «dateFormat.format(date)» (by Multi-Dataflow Composer - Platform Composer)
		*****************************************************************************/
		
		#include "«coupling»_accelerator_h.h"

		«FOR net : networkVertexMap.keySet SEPARATOR "\n"»
		int «coupling»_accelerator_«net»(
			«FOR port : netIdPortMap.get(net) SEPARATOR ","»
			// port «port.name»
			int size_«portMap.get(port)», int* data_«portMap.get(port)»
			«ENDFOR»
			) {
			
			«IF coupling.equals("mm")»
			«IF !useDMA»
			«FOR port : portMap.keySet»
			int idx_«portMap.get(port)»;
			«ENDFOR»
			«ENDIF»
			
			// clear counters
			*((int*) MM_ACCELERATOR_CFG_BASEADDR) = 0x«Integer.toHexString((configManager.getNetworkId(net)<<24)+2)»;
			
			// configure I/O
			«FOR port : portMap.keySet»
			*((int*) (MM_ACCELERATOR_CFG_BASEADDR + «portMap.get(port)+1»*4)) = size_«portMap.get(port)»<<20;
			«ENDFOR»
			
			«FOR input : inputMap.keySet»
			// send data port «input.name»
			«IF useDMA»
			*((volatile int*) XPAR_AXI_CDMA_0_BASEADDR + (0x04>>2)) = 0x00000002; // verify idle
			//*((volatile int*) XPAR_AXI_CDMA_0_BASEADDR + (0x00>>2)) = 0x00001000;	// irq en (optional)
			*((volatile int*) XPAR_AXI_CDMA_0_BASEADDR + (0x18>>2)) = (int) data_«portMap.get(input)»; // src
			*((volatile int*) XPAR_AXI_CDMA_0_BASEADDR + (0x20>>2)) = MM_ACCELERATOR_MEM_BASEADDR + MM_ACCELERATOR_MEM_«portMap.get(input)+1»_OFFSET; // dst
			*((volatile int*) XPAR_AXI_CDMA_0_BASEADDR + (0x28>>2)) = size_«portMap.get(input)»*4; // size [B]
			while((*((volatile int*) XPAR_AXI_CDMA_0_BASEADDR + (0x04>>2)) & 0x2) != 0x2);
			«ELSE»
			for(idx_«portMap.get(input)»=0; idx_«portMap.get(input)»<size_«portMap.get(input)»; idx_«portMap.get(input)»++) {
				*((int *) (MM_ACCELERATOR_MEM_BASEADDR + MM_ACCELERATOR_MEM_«portMap.get(input)+1»_OFFSET + idx_«portMap.get(input)»*4)) = *(data_«portMap.get(input)»+idx_«portMap.get(input)»);
			}
			«ENDIF»
			«ENDFOR»
			
			// start execution
			*((int*) MM_ACCELERATOR_CFG_BASEADDR) = 0x«Integer.toHexString((configManager.getNetworkId(net)<<24)+1)»;
			
			«FOR output : outputMap.keySet»
			// receive data port «output.name»
			«IF useDMA»
			*((volatile int*) XPAR_AXI_CDMA_0_BASEADDR + (0x04>>2)) = 0x00000002; // verify idle
			//*((volatile int*) XPAR_AXI_CDMA_0_BASEADDR + (0x00>>2)) = 0x00001000;	// irq en (optional)
			*((volatile int*) XPAR_AXI_CDMA_0_BASEADDR + (0x18>>2)) = MM_ACCELERATOR_MEM_BASEADDR + MM_ACCELERATOR_MEM_«portMap.get(output)+1»_OFFSET; // src
			*((volatile int*) XPAR_AXI_CDMA_0_BASEADDR + (0x20>>2)) = (int) data_«portMap.get(output)»; // dst
			*((volatile int*) XPAR_AXI_CDMA_0_BASEADDR + (0x28>>2)) = size_«portMap.get(output)»*4; // size [B]
			while((*((volatile int*) XPAR_AXI_CDMA_0_BASEADDR + (0x04>>2)) & 0x2) != 0x2);
			«ELSE»
			for(idx_«portMap.get(output)»=0; idx_«portMap.get(output)»<size_«portMap.get(output)»; idx_«portMap.get(output)»++) {
				*(data_«portMap.get(output)»+idx_«portMap.get(output)») = *((int *) (MM_ACCELERATOR_MEM_BASEADDR + MM_ACCELERATOR_MEM_«portMap.get(output)+1»_OFFSET + idx_«portMap.get(output)»*4));
			}
			«ENDIF»
			«ENDFOR»
		«ELSE»
		«IF !useDMA»
		«FOR port : portMap.keySet»
			int idx_«portMap.get(port)»;
			«ENDFOR»
			«ENDIF»
			
			// start execution
			*((int*) S_ACCELERATOR_CFG_BASEADDR) = 0x«Integer.toHexString((configManager.getNetworkId(net)<<24)+1)»;
			
			«FOR input : inputMap.keySet»
			// send data port «input.name»
			«IF useDMA»
			*((volatile int*) XPAR_AXI_DMA_«inputMap.get(input)»_BASEADDR + (0x00>>2)) = 0x00000001; // start
			*((volatile int*) XPAR_AXI_DMA_«inputMap.get(input)»_BASEADDR + (0x04>>2)) = 0x00000000; // reset idle
			*((volatile int*) XPAR_AXI_DMA_«inputMap.get(input)»_BASEADDR + (0x18>>2)) = (int) data_«portMap.get(input)»; // src
			*((volatile int*) XPAR_AXI_DMA_«inputMap.get(input)»_BASEADDR + (0x28>>2)) = size_«portMap.get(input)»*4; // size [B]
			while(((*((volatile int*) XPAR_AXI_DMA_«inputMap.get(input)»_BASEADDR + (0x04>>2))) & 0x2) != 0x2);
			«ELSE»
			for(idx_«portMap.get(input)»=0; idx_«portMap.get(input)»<size_«portMap.get(input)»; idx_«portMap.get(input)»++) {
				putfsl(*(data_«portMap.get(input)»+idx_«portMap.get(input)»), «portMap.get(input)»);
			}
			«ENDIF»
			«ENDFOR»
			
			«FOR output : outputMap.keySet»
			«IF useDMA»
			*((volatile int*) XPAR_AXI_DMA_«outputMap.get(output)»_BASEADDR + (0x00>>2)) = 0x00000001; // start
			*((volatile int*) XPAR_AXI_DMA_«outputMap.get(output)»_BASEADDR + (0x04>>2)) = 0x00000000; // reset idle
			*((volatile int*) XPAR_AXI_DMA_«outputMap.get(output)»_BASEADDR + (0x18>>2)) = (int) data_«portMap.get(output)»; // dst
			*((volatile int*) XPAR_AXI_DMA_«outputMap.get(output)»_BASEADDR + (0x28>>2)) = size_«portMap.get(output)»*4; // size [B]
			while(((*((volatile int*) XPAR_AXI_DMA_«outputMap.get(output)»_BASEADDR + (0x04>>2))) & 0x2) != 0x2);
			«ELSE»
			// receive data port «output.name»
			for(idx_«portMap.get(output)»=0; idx_«portMap.get(output)»<size_«portMap.get(output)»; idx_«portMap.get(output)»++) {
				getfsl(*(data_«portMap.get(output)»+idx_«portMap.get(output)»), «portMap.get(output)»);
			}
			«ENDIF»
			«ENDFOR»
		«ENDIF»
					
					// stop execution
					*((int*) «coupling.toUpperCase»_ACCELERATOR_CFG_BASEADDR) = 0x«Integer.toHexString(0)»;
					
					return 0;
				}
		«ENDFOR»
		'''
		
	}	
	
	def printHighDriverHeader(Network network, Map<String,Map<String,String>> networkVertexMap) {
		
		var dateFormat = new SimpleDateFormat("yyyy/MM/dd HH:mm:ss");
		var date = new Date();
		var Map<String,ArrayList<Port>> netIdPortMap = new HashMap<String,ArrayList<Port>>();		
		var i = 0;
		
		for (String net : networkVertexMap.keySet()) {
			i=0;
			for(id : portMap.values.sort) {
				for(port : portMap.keySet) {
					if(portMap.get(port).equals(id)) {
						if(networkVertexMap.get(net).values.contains(port.name)) {
							if(!netIdPortMap.containsKey(net)) {
								var newList = new ArrayList<Port>();
								newList.add(i,port);
								netIdPortMap.put(net,newList);
							} else {
								netIdPortMap.get(net).add(i,port);
							}
						}
					}			
				}
			}
		}
		
		'''
		/*****************************************************************************
		*  Filename:          «coupling»_accelerator_h.h
		*  Description:       «IF coupling.equals("mm")»Memory-Mapped«ELSE»Stream«ENDIF» Accelerator High Level Driver Header
		*  Date:              «dateFormat.format(date)» (by Multi-Dataflow Composer - Platform Composer)
		*****************************************************************************/
		
		#ifndef «coupling.toUpperCase»_ACCELERATOR_H_H
		#define «coupling.toUpperCase»_ACCELERATOR_H_H
		
		/***************************** Include Files *******************************/		
		#include "xparameters.h"
		«IF coupling.equals("s")»#include "fsl.h"«ENDIF»
		
		/************************** Constant Definitions ***************************/
		#define «coupling.toUpperCase»_ACCELERATOR_CFG_BASEADDR 0x44A00000
		«IF coupling.equals("mm")»
		#define «coupling.toUpperCase»_ACCELERATOR_MEM_BASEADDR 0x76000000
		«FOR port : portMap.keySet»
		#define «coupling.toUpperCase»_ACCELERATOR_MEM_«portMap.get(port)+1»_OFFSET 0x«Integer.toHexString(portMap.get(port)*4*256)»
		«ENDFOR»
		«ENDIF»
		
		/************************* Functions Definitions ***************************/
		
		
		«FOR net : networkVertexMap.keySet»
		int «coupling»_accelerator_«net»(
			«FOR port : netIdPortMap.get(net) SEPARATOR ","»
			// port «port.name»
			int size_«portMap.get(port)», int* data_«portMap.get(port)»
			«ENDFOR»
		);
		
		«ENDFOR»
		
		#endif /** MM_ACCELERATOR_H_H */
		'''
	}	
	

}