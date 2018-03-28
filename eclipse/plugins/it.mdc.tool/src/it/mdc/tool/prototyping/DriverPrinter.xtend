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
	
	String coupling
	String processor
	boolean enDma
	Map <Port,Integer> portMap;
	Map <Port,Integer> inputMap;
	Map <Port,Integer> outputMap;
	
	def isMemoryMapped(){
		if(coupling.equals("mm")) {
			return true
		} else {
			return false
		}
	}
	
	def initDriverPrinter(String coupling, String processor, Boolean enDma,
			Map <Port,Integer> portMap,Map <Port,Integer> inputMap,Map <Port,Integer> outputMap) {
		this.coupling = coupling;
		this.portMap = portMap;
		this.inputMap = inputMap;
		this.outputMap = outputMap;
		this.processor = processor;
		this.enDma = enDma;						
	}
	
	def printDriverSource(Network network, Map<String,Map<String,String>> networkVertexMap, ConfigManager configManager) {
		
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
		*  Filename:          «coupling»_accelerator.c
		*  Description:       «IF isMemoryMapped»Memory-Mapped«ELSE»Stream«ENDIF» Accelerator Driver
		*  Date:              «dateFormat.format(date)» (by Multi-Dataflow Composer - Platform Composer)
		*****************************************************************************/
		
		#include "«coupling»_accelerator.h"

		«FOR net : networkVertexMap.keySet SEPARATOR "\n"»
		int «coupling»_accelerator_«net»(
			«FOR port : netIdPortMap.get(net) SEPARATOR ","»
			// port «port.name»
			int size_«port.name», int* data_«port.name»
			«ENDFOR»
			) {
			
			volatile int* config = (int*) XPAR_«coupling.toUpperCase»_ACCELERATOR_0_CFG_BASEADDR;
			«IF !enDma»
			«FOR port : portMap.keySet»
			int idx_«port.name»;
			«ENDFOR»
			«ENDIF»

			«IF isMemoryMapped»
			// configure I/O
			«FOR port : portMap.keySet»
			*((int*) (XPAR_MM_ACCELERATOR_0_CFG_BASEADDR + «portMap.get(port)+1»*4)) = size_«port.name»;
			«ENDFOR»
			
			«FOR input : inputMap.keySet»
			// send data port «input.name»
			«IF enDma»
			*((volatile int*) XPAR_AXI_CDMA_0_BASEADDR + (0x04>>2)) = 0x00000002; // verify idle
			//*((volatile int*) XPAR_AXI_CDMA_0_BASEADDR + (0x00>>2)) = 0x00001000;	// irq en (optional)
			*((volatile int*) XPAR_AXI_CDMA_0_BASEADDR + (0x18>>2)) = (int) data_«input.name»; // src
			*((volatile int*) XPAR_AXI_CDMA_0_BASEADDR + (0x20>>2)) = XPAR_MM_ACCELERATOR_0_MEM_BASEADDR + MM_ACCELERATOR_MEM_«portMap.get(input)+1»_OFFSET; // dst
			*((volatile int*) XPAR_AXI_CDMA_0_BASEADDR + (0x28>>2)) = size_«input.name»*4; // size [B]
			while((*((volatile int*) XPAR_AXI_CDMA_0_BASEADDR + (0x04>>2)) & 0x2) != 0x2);
			«ELSE»
			for(idx_«input.name»=0; idx_«input.name»<size_«input.name»; idx_«input.name»++) {
				*((int *) (XPAR_MM_ACCELERATOR_0_MEM_BASEADDR + MM_ACCELERATOR_MEM_«portMap.get(input)+1»_OFFSET + idx_«input.name»*4)) = *(data_«input.name»+idx_«input.name»);
			}
			«ENDIF»
			«ENDFOR»
			
			«ENDIF»
			// start execution
			*(config) = 0x«Integer.toHexString((configManager.getNetworkId(net)<<24)+1)»;
			
			«IF !isMemoryMapped»
			«FOR input : inputMap.keySet»
			// send data port «input.name»
			«IF enDma»
			*((volatile int*) XPAR_AXI_DMA_«inputMap.get(input)»_BASEADDR + (0x00>>2)) = 0x00000001; // start
			*((volatile int*) XPAR_AXI_DMA_«inputMap.get(input)»_BASEADDR + (0x04>>2)) = 0x00000000; // reset idle
			*((volatile int*) XPAR_AXI_DMA_«inputMap.get(input)»_BASEADDR + (0x18>>2)) = (int) data_«input.name»; // src
			*((volatile int*) XPAR_AXI_DMA_«inputMap.get(input)»_BASEADDR + (0x28>>2)) = size_«input.name»*4; // size [B]
			while(((*((volatile int*) XPAR_AXI_DMA_«inputMap.get(input)»_BASEADDR + (0x04>>2))) & 0x2) != 0x2);
			«ELSE»
			for(idx_«input.name»=0; idx_«input.name»<size_«input.name»; idx_«input.name»++) {
				putfsl(*(data_«input.name»+idx_«input.name»), «inputMap.get(input)»);
			}
			«ENDIF»
			«ENDFOR»
			«FOR output : outputMap.keySet»
			«IF enDma»
			*((volatile int*) XPAR_AXI_DMA_«outputMap.get(output)»_BASEADDR + (0x00>>2)) = 0x00000001; // start
			*((volatile int*) XPAR_AXI_DMA_«outputMap.get(output)»_BASEADDR + (0x04>>2)) = 0x00000000; // reset idle
			*((volatile int*) XPAR_AXI_DMA_«outputMap.get(output)»_BASEADDR + (0x18>>2)) = (int) data_«output.name»; // dst
			*((volatile int*) XPAR_AXI_DMA_«outputMap.get(output)»_BASEADDR + (0x28>>2)) = size_«output.name»*4; // size [B]
			while(((*((volatile int*) XPAR_AXI_DMA_«outputMap.get(output)»_BASEADDR + (0x04>>2))) & 0x2) != 0x2);
			«ELSE»
			// receive data port «output.name»
			for(idx_«output.name»=0; idx_«output.name»<size_«output.name»; idx_«output.name»++) {
				getfsl(*(data_«output.name»+idx_«output.name»), «outputMap.get(output)»);
			}
			«ENDIF»
			«ENDFOR»
			
			«ELSE»
			
			// wait for completion
			while( ((*(config)) & 0x4) != 0x4 );
						
			«FOR output : outputMap.keySet»
			// receive data port «output.name»
			«IF enDma»
			*((volatile int*) XPAR_AXI_CDMA_0_BASEADDR + (0x04>>2)) = 0x00000002; // verify idle
			//*((volatile int*) XPAR_AXI_CDMA_0_BASEADDR + (0x00>>2)) = 0x00001000;	// irq en (optional)
			*((volatile int*) XPAR_AXI_CDMA_0_BASEADDR + (0x18>>2)) = XPAR_MM_ACCELERATOR_0_MEM_BASEADDR + MM_ACCELERATOR_MEM_«portMap.get(output)+1»_OFFSET; // src
			*((volatile int*) XPAR_AXI_CDMA_0_BASEADDR + (0x20>>2)) = (int) data_«output.name»; // dst
			*((volatile int*) XPAR_AXI_CDMA_0_BASEADDR + (0x28>>2)) = size_«output.name»*4; // size [B]
			while((*((volatile int*) XPAR_AXI_CDMA_0_BASEADDR + (0x04>>2)) & 0x2) != 0x2);
			«ELSE»
			for(idx_«output.name»=0; idx_«output.name»<size_«output.name»; idx_«output.name»++) {
				*(data_«output.name»+idx_«output.name») = *((int *) (XPAR_MM_ACCELERATOR_0_MEM_BASEADDR + MM_ACCELERATOR_MEM_«portMap.get(output)+1»_OFFSET + idx_«output.name»*4));
			}
			«ENDIF»
			«ENDFOR»
			«ENDIF»
								
			// stop execution
			*(config) = 0x«Integer.toHexString(0)»;
			
			return 0;
		}
		«ENDFOR»
		'''
		
	}	
	
	def printDriverHeader(Network network, Map<String,Map<String,String>> networkVertexMap) {
		
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
		*  Filename:          «coupling»_accelerator.h
		*  Description:       «IF isMemoryMapped»Memory-Mapped«ELSE»Stream«ENDIF» Accelerator Driver Header
		*  Date:              «dateFormat.format(date)» (by Multi-Dataflow Composer - Platform Composer)
		*****************************************************************************/
		
		#ifndef «coupling.toUpperCase»_ACCELERATOR_H
		#define «coupling.toUpperCase»_ACCELERATOR_H
		
		/***************************** Include Files *******************************/		
		#include "xparameters.h"
		«IF !isMemoryMapped && !enDma»#include "fsl.h"«ENDIF»
		
		/************************** Constant Definitions ***************************/
		// #define XPAR_«coupling.toUpperCase»_ACCELERATOR_0_CFG_BASEADDR 0x44A00000
		«IF isMemoryMapped»
		// #define XPAR_«coupling.toUpperCase»_ACCELERATOR_0_MEM_BASEADDR 0x76000000
		«FOR port : portMap.keySet»
		// «port.name» local memory offset
		#define «coupling.toUpperCase»_ACCELERATOR_MEM_«portMap.get(port)+1»_OFFSET 0x«Integer.toHexString(portMap.get(port)*4*256)»
		«ENDFOR»
		«ENDIF»
		
		/************************* Functions Definitions ***************************/
		
		
		«FOR net : networkVertexMap.keySet»
		int «coupling»_accelerator_«net»(
			«FOR port : netIdPortMap.get(net) SEPARATOR ","»
			// port «port.name»
			int size_«port.name», int* data_«port.name»
			«ENDFOR»
		);
		
		«ENDFOR»
		
		#endif /** MM_ACCELERATOR_H */
		'''
	}
	
	def printDriverTcl() {
		// TODO BASE/HIGH ADDRESSES not used at the moment
		'''
		proc generate {drv_handle} {
			xdefine_include_file $drv_handle "xparameters.h" "«coupling»_accelerator" "NUM_INSTANCES" "DEVICE_ID"  "C_CFG_BASEADDR" "C_CFG_HIGHADDR" «IF isMemoryMapped»"C_MEM_BASEADDR" "C_MEM_HIGHADDR"«ENDIF»
		}
		'''
	}
	
	def printDriverMdd() {
		'''
		OPTION psf_version = 2.1;
		
		BEGIN DRIVER «coupling»_accelerator
			OPTION supported_peripherals = («coupling»_accelerator);
			OPTION copyfiles = all;
			OPTION VERSION = 1.0;
			OPTION NAME = «coupling»_accelerator;
		END DRIVER
		'''
	}
	

}