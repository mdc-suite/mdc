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
import java.util.List

import it.mdc.tool.core.platformComposer.ProtocolManager

/**
 * Vivado Template Interface Layer 
 * Memory-Mapped HW Accelerator Printer
 * 
 * @author Carlo Sau
 */
class WrapperPrinter extends TilPrinter {
	
	boolean dedicatedInterfaces = false
	boolean useDMA = false
	
	Map<String,Map<String,String>> netSysSignals;
	Map<String,Map<String,Map<String,String>>> modCommSignals;
	Map<String,Map<String,String>> wrapCommSignals;
	
	def initWrapperPrinter(	Map<String,Map<String,String>> netSysSignals, 
						Map<String,Map<String,Map<String,String>>> modCommSignals,
						Map<String,Map<String,String>> wrapCommSignals
	) {
		System.out.print("WP intialization!!!");
		this.netSysSignals = netSysSignals;
		this.modCommSignals = modCommSignals;
		this.wrapCommSignals = wrapCommSignals;
		System.out.println("netSysSignals " + this.netSysSignals);
		System.out.println("modCommSignals " + this.modCommSignals);
		System.out.println("wrapCommSignals " + this.wrapCommSignals);
	}
	
	def hasParameter(String portValue) {
		var boolean result = false;
		
		if(portValue.split("_").size > 3) {
			result = true;
		}
		
		return result;
	}
	
	def getDefaultValue(String portValue) {
		var int defaultValue;
				
		if(hasParameter(portValue)) {
			defaultValue = Integer.parseInt(portValue.split("_").get(portValue.split("_").size-1));
		} else {
			defaultValue = Integer.parseInt(portValue.split("_").get(2));
		}
		
		return defaultValue;
	}
	
	def getParameter(String portValue) {
		var String parameter = ""; 
		var int i = 2;
		
		if(portValue.split("_").size==4) {
			parameter = portValue.split("_").get(2);
		} else {
			while(i<portValue.split("_").size-1) {
				if(parameter.equals("")) {
					parameter = parameter + portValue.split("_").get(i);
				} else {
					parameter = parameter + "_" + portValue.split("_").get(i);
				}
				i=i+1;	
			}
		}
		
		return parameter;
	}
	
	def getDirection(String portValue) {
		var String direction = portValue;
		if(portValue.contains("_")) {
			direction = portValue.split("_").get(0);
		}
		return direction;
	}
	
	def getReverseDirection(String portValue) {
		var String direction = getDirection(portValue);
		if(direction.equals("in")) {
			direction = "out";
		} else {
			direction = "in";
		}
		return direction;
	}
	
	override printHdlSource(Network network, String module){
		
		if(module.equals("TOP")) {
			printTop(network);
		} else if(module.equals("CFG_REGS")) {
			printRegs();
		} else if(module.equals("TBENCH")) {
			printTestBench();
		}
	}
	
	def printTop(Network network) {
		
		mapInOut(network);
		mapSignals();
		
		'''	
		«printTopHeaderComments()»
		
		// ----------------------------------------------------------------------------
		// Module Interface
		// ----------------------------------------------------------------------------
		«printTopInterface()»
		
		// ----------------------------------------------------------------------------
		// Module Signals
		// ----------------------------------------------------------------------------
		«printTopSignals()»
		
		// ----------------------------------------------------------------------------
		// Body
		// ----------------------------------------------------------------------------
		«printTopBody()»
		
		endmodule
		// ----------------------------------------------------------------------------
		// ----------------------------------------------------------------------------
		// ----------------------------------------------------------------------------
		'''
		
	}
	
	def printTopHeaderComments(){
				
		var dateFormat = new SimpleDateFormat("yyyy/MM/dd HH:mm:ss");
		var date = new Date();
		'''
		// ----------------------------------------------------------------------------
		//
		// Multi-Dataflow Composer tool - Platform Composer
		// Template Interface Layer module - Memory-Mapped type
		// Date: «dateFormat.format(date)»
		//
		// ----------------------------------------------------------------------------
		'''	
		
	}
	
	def getSizePrefix(String size) {
		System.out.println("gsp " + size);
		if(size.equals("1")) {
			return ""
		} else {
			return "[" + size + "-1 : 0] "
		}
	}
	
	def getPortCommSigSize(Port port, String commSigId, Map<String,Map<String,String>> commSigIdMap) {
		System.out.println("port " + port + " " + commSigId + " " + commSigIdMap);
		if(commSigIdMap.containsKey(commSigId)){
			if(commSigIdMap.get(commSigId).get(ProtocolManager.SIZE).equals("variable")) {
				System.out.println("var " + port.type + " " + port.type.sizeInBits + " " + port.type.sizeInBits.toString);
				return port.type.sizeInBits.toString
			} else {
				return commSigIdMap.get(commSigId).get(ProtocolManager.SIZE)	
			}
		}
		return null
	}

	def printTopSignals() {
		
		'''
		// Wire(s) and Reg(s)
		wire [31 : 0] slv_reg0;
		«FOR port : portMap.keySet»
		wire [31 : 0] slv_reg«portMap.get(port)+1»;
		«ENDFOR»
		«IF dedicatedInterfaces»
		«ELSE»
		wire s01_axi_rden;
		wire s01_axi_wren;
		wire [C_S01_AXI_ADDR_WIDTH-3 : 0] s01_axi_address;
		wire [31 : 0] s01_axi_data_in;
		reg [31 : 0] s01_axi_data_out;
		«ENDIF»
		«FOR input : inputMap.keySet()»
		«FOR commSigId : getInFirstModCommSignals().keySet»
		wire «getSizePrefix(getPortCommSigSize(input,commSigId,getFirstModCommSignals()))»«input.getName()»_«getMatchingWrapMapping(getFirstModCommSignals().get(commSigId).get(ProtocolManager.CH))»;
		«ENDFOR»
		«ENDFOR»
	    «FOR input : inputMap.keySet()»
		wire en_«input.name»;
		wire done_«input.name»;
		wire [11:0]	count_«input.name»;
		wire wren_mem_«portMap.get(input)+1»;
		wire rden_mem_«portMap.get(input)+1»;
		wire [7:0] address_mem_«portMap.get(input)+1»;
		wire [31:0]	data_in_mem_«portMap.get(input)+1»;
		wire [31:0]	data_out_mem_«portMap.get(input)+1»;
		wire [31:0]	data_out_«portMap.get(input)+1»;
		wire ce_«portMap.get(input)+1»;
		«ENDFOR»
		«FOR output : outputMap.keySet()»
		«FOR commSigId : getOutLastModCommSignals().keySet»
		wire «getSizePrefix(getPortCommSigSize(output,commSigId,getLastModCommSignals()))»«output.getName()»_«getMatchingWrapMapping(getLastModCommSignals().get(commSigId).get(ProtocolManager.CH))»;
		«ENDFOR»
		«ENDFOR»
		«FOR output : outputMap.keySet()»
		wire en_«output.name»;
		wire done_«output.name»;
		wire [11:0] count_«output.name»;
		wire rden_mem_«portMap.get(output)+1»;
		wire wren_mem_«portMap.get(output)+1»;
		wire [7:0] address_mem_«portMap.get(output)+1»;
		wire [31:0]	data_in_mem_«portMap.get(output)+1»;
		wire [31:0]	data_out_mem_«portMap.get(output)+1»;
		wire [31:0]	data_out_«portMap.get(output)+1»;
		wire ce_«portMap.get(output)+1»;
		«ENDFOR»
		'''
		
		
	}
	
	def printTopInterface() {
		
		'''
		module mm_accelerator#
		(
			«IF dedicatedInterfaces»
			«FOR port : portMap.keySet»
			// Parameters of Axi Slave Bus Interface S«portMap.get(port)+1»_AXI
			parameter integer C_S«getLongId(portMap.get(port)+1)»_AXI_ID_WIDTH	= 1,
			parameter integer C_S«getLongId(portMap.get(port)+1)»_AXI_DATA_WIDTH	= 32,
			parameter integer C_S«getLongId(portMap.get(port)+1)»_AXI_ADDR_WIDTH	= «(Math.ceil(10+Math.log10(portMap.size) / Math.log10(2)).intValue).intValue()»,	// memory size 4096
			parameter integer C_S«getLongId(portMap.get(port)+1)»_AXI_AWUSER_WIDTH	= 0,
			parameter integer C_S«getLongId(portMap.get(port)+1)»_AXI_ARUSER_WIDTH	= 0,
			parameter integer C_S«getLongId(portMap.get(port)+1)»_AXI_WUSER_WIDTH	= 0,
			parameter integer C_S«getLongId(portMap.get(port)+1)»_AXI_RUSER_WIDTH	= 0,
			parameter integer C_S«getLongId(portMap.get(port)+1)»_AXI_BUSER_WIDTH	= 0,
			«ENDFOR»
			«ELSE»
			// Parameters of Axi Slave Bus Interface S01_AXI
			parameter integer C_S01_AXI_ID_WIDTH	= 1,
			parameter integer C_S01_AXI_DATA_WIDTH	= 32,
			parameter integer C_S01_AXI_ADDR_WIDTH	= «(Math.ceil(10+Math.log10(portMap.size) / Math.log10(2))).intValue()»,	// memory size 4096
			parameter integer C_S01_AXI_AWUSER_WIDTH	= 0,
			parameter integer C_S01_AXI_ARUSER_WIDTH	= 0,
			parameter integer C_S01_AXI_WUSER_WIDTH	= 0,
			parameter integer C_S01_AXI_RUSER_WIDTH	= 0,
			parameter integer C_S01_AXI_BUSER_WIDTH	= 0,
			«ENDIF»
			
			// Parameters of Axi Slave Bus Interface S00_AXI
			parameter integer C_S00_AXI_DATA_WIDTH	= 32,
			parameter integer C_S00_AXI_ADDR_WIDTH	= «computeSizePointer»
		)
		(
			«IF dedicatedInterfaces»
			«FOR port : portMap.keySet»
			// Ports of Axi Slave Bus Interface S«getLongId(portMap.get(port)+1)»_AXI
			input wire  s«getLongId(portMap.get(port)+1)»_axi_aclk,
			input wire  s«getLongId(portMap.get(port)+1)»_axi_aresetn,
			input wire [C_S01_AXI_ID_WIDTH-1 : 0] s«getLongId(portMap.get(port)+1)»_axi_awid,
			input wire [C_S01_AXI_ADDR_WIDTH-1 : 0] s«getLongId(portMap.get(port)+1)»_axi_awaddr,
			input wire [7 : 0] s«getLongId(portMap.get(port)+1)»_axi_awlen,
			input wire [2 : 0] s«getLongId(portMap.get(port)+1)»_axi_awsize,
			input wire [1 : 0] s«getLongId(portMap.get(port)+1)»_axi_awburst,
			input wire  s«getLongId(portMap.get(port)+1)»_axi_awlock,
			input wire [3 : 0] s«getLongId(portMap.get(port)+1)»_axi_awcache,
			input wire [2 : 0] s«getLongId(portMap.get(port)+1)»_axi_awprot,
			input wire [3 : 0] s«getLongId(portMap.get(port)+1)»_axi_awqos,
			input wire [3 : 0] s«getLongId(portMap.get(port)+1)»_axi_awregion,
			input wire [C_S01_AXI_AWUSER_WIDTH-1 : 0] s«getLongId(portMap.get(port)+1)»_axi_awuser,
			input wire  s«getLongId(portMap.get(port)+1)»_axi_awvalid,
			output wire  s«getLongId(portMap.get(port)+1)»_axi_awready,
			input wire [C_S01_AXI_DATA_WIDTH-1 : 0] s«getLongId(portMap.get(port)+1)»_axi_wdata,
			input wire [(C_S01_AXI_DATA_WIDTH/8)-1 : 0] s«getLongId(portMap.get(port)+1)»_axi_wstrb,
			input wire  s«getLongId(portMap.get(port)+1)»_axi_wlast,
			input wire [C_S01_AXI_WUSER_WIDTH-1 : 0] s«getLongId(portMap.get(port)+1)»_axi_wuser,
			input wire  s«getLongId(portMap.get(port)+1)»_axi_wvalid,
			output wire  s«getLongId(portMap.get(port)+1)»_axi_wready,
			output wire [C_S01_AXI_ID_WIDTH-1 : 0] s«getLongId(portMap.get(port)+1)»_axi_bid,
			output wire [1 : 0] s«getLongId(portMap.get(port)+1)»_axi_bresp,
			output wire [C_S01_AXI_BUSER_WIDTH-1 : 0] s«getLongId(portMap.get(port)+1)»_axi_buser,
			output wire  s«getLongId(portMap.get(port)+1)»_axi_bvalid,
			input wire  s«getLongId(portMap.get(port)+1)»_axi_bready,
			input wire [C_S01_AXI_ID_WIDTH-1 : 0] s«getLongId(portMap.get(port)+1)»_axi_arid,
			input wire [C_S01_AXI_ADDR_WIDTH-1 : 0] s«getLongId(portMap.get(port)+1)»_axi_araddr,
			input wire [7 : 0] s«getLongId(portMap.get(port)+1)»_axi_arlen,
			input wire [2 : 0] s«getLongId(portMap.get(port)+1)»_axi_arsize,
			input wire [1 : 0] s«getLongId(portMap.get(port)+1)»_axi_arburst,
			input wire  s«getLongId(portMap.get(port)+1)»_axi_arlock,
			input wire [3 : 0] s«getLongId(portMap.get(port)+1)»_axi_arcache,
			input wire [2 : 0] s«getLongId(portMap.get(port)+1)»_axi_arprot,
			input wire [3 : 0] s«getLongId(portMap.get(port)+1)»_axi_arqos,
			input wire [3 : 0] s«getLongId(portMap.get(port)+1)»_axi_arregion,
			input wire [C_S01_AXI_ARUSER_WIDTH-1 : 0] s«getLongId(portMap.get(port)+1)»_axi_aruser,
			input wire  s«getLongId(portMap.get(port)+1)»_axi_arvalid,
			output wire  s«getLongId(portMap.get(port)+1)»_axi_arready,
			output wire [C_S01_AXI_ID_WIDTH-1 : 0] s«getLongId(portMap.get(port)+1)»_axi_rid,
			output wire [C_S01_AXI_DATA_WIDTH-1 : 0] s«getLongId(portMap.get(port)+1)»_axi_rdata,
			output wire [1 : 0] s«getLongId(portMap.get(port)+1)»_axi_rresp,
			output wire  s«getLongId(portMap.get(port)+1)»_axi_rlast,
			output wire [C_S01_AXI_RUSER_WIDTH-1 : 0] s«getLongId(portMap.get(port)+1)»_axi_ruser,
			output wire  s«getLongId(portMap.get(port)+1)»_axi_rvalid,
			input wire  s«getLongId(portMap.get(port)+1)»_axi_rready,
			«ENDFOR»
			«ELSE»
			// Ports of Axi Slave Bus Interface S01_AXI
			input wire  s01_axi_aclk,
			input wire  s01_axi_aresetn,
			input wire [C_S01_AXI_ID_WIDTH-1 : 0] s01_axi_awid,
			input wire [C_S01_AXI_ADDR_WIDTH-1 : 0] s01_axi_awaddr,
			input wire [7 : 0] s01_axi_awlen,
			input wire [2 : 0] s01_axi_awsize,
			input wire [1 : 0] s01_axi_awburst,
			input wire  s01_axi_awlock,
			input wire [3 : 0] s01_axi_awcache,
			input wire [2 : 0] s01_axi_awprot,
			input wire [3 : 0] s01_axi_awqos,
			input wire [3 : 0] s01_axi_awregion,
			input wire [C_S01_AXI_AWUSER_WIDTH-1 : 0] s01_axi_awuser,
			input wire  s01_axi_awvalid,
			output wire  s01_axi_awready,
			input wire [C_S01_AXI_DATA_WIDTH-1 : 0] s01_axi_wdata,
			input wire [(C_S01_AXI_DATA_WIDTH/8)-1 : 0] s01_axi_wstrb,
			input wire  s01_axi_wlast,
			input wire [C_S01_AXI_WUSER_WIDTH-1 : 0] s01_axi_wuser,
			input wire  s01_axi_wvalid,
			output wire  s01_axi_wready,
			output wire [C_S01_AXI_ID_WIDTH-1 : 0] s01_axi_bid,
			output wire [1 : 0] s01_axi_bresp,
			output wire [C_S01_AXI_BUSER_WIDTH-1 : 0] s01_axi_buser,
			output wire  s01_axi_bvalid,
			input wire  s01_axi_bready,
			input wire [C_S01_AXI_ID_WIDTH-1 : 0] s01_axi_arid,
			input wire [C_S01_AXI_ADDR_WIDTH-1 : 0] s01_axi_araddr,
			input wire [7 : 0] s01_axi_arlen,
			input wire [2 : 0] s01_axi_arsize,
			input wire [1 : 0] s01_axi_arburst,
			input wire  s01_axi_arlock,
			input wire [3 : 0] s01_axi_arcache,
			input wire [2 : 0] s01_axi_arprot,
			input wire [3 : 0] s01_axi_arqos,
			input wire [3 : 0] s01_axi_arregion,
			input wire [C_S01_AXI_ARUSER_WIDTH-1 : 0] s01_axi_aruser,
			input wire  s01_axi_arvalid,
			output wire  s01_axi_arready,
			output wire [C_S01_AXI_ID_WIDTH-1 : 0] s01_axi_rid,
			output wire [C_S01_AXI_DATA_WIDTH-1 : 0] s01_axi_rdata,
			output wire [1 : 0] s01_axi_rresp,
			output wire  s01_axi_rlast,
			output wire [C_S01_AXI_RUSER_WIDTH-1 : 0] s01_axi_ruser,
			output wire  s01_axi_rvalid,
			input wire  s01_axi_rready,
			«ENDIF»
			
			// Ports of Axi Slave Bus Interface S00_AXI
			input wire  s00_axi_aclk,
			input wire  s00_axi_aresetn,
			input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
			input wire [2 : 0] s00_axi_awprot,
			input wire  s00_axi_awvalid,
			output wire  s00_axi_awready,
			input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
			input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
			input wire  s00_axi_wvalid,
			output wire  s00_axi_wready,
			output wire [1 : 0] s00_axi_bresp,
			output wire  s00_axi_bvalid,
			input wire  s00_axi_bready,
			input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
			input wire [2 : 0] s00_axi_arprot,
			input wire  s00_axi_arvalid,
			output wire  s00_axi_arready,
			output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
			output wire [1 : 0] s00_axi_rresp,
			output wire  s00_axi_rvalid,
			input wire  s00_axi_rready
		);
		
		'''
	}
			
	def printTopBody() {
		'''
		// Configuration Registers
		// ----------------------------------------------------------------------------
		// Instantiation of Configuration Registers
		config_registers # ( 
			.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
			.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
		) i_config_registers (
			.S_AXI_ACLK(s00_axi_aclk),
			.S_AXI_ARESETN(s00_axi_aresetn),
			.S_AXI_AWADDR(s00_axi_awaddr),
			.S_AXI_AWPROT(s00_axi_awprot),
			.S_AXI_AWVALID(s00_axi_awvalid),
			.S_AXI_AWREADY(s00_axi_awready),
			.S_AXI_WDATA(s00_axi_wdata),
			.S_AXI_WSTRB(s00_axi_wstrb),
			.S_AXI_WVALID(s00_axi_wvalid),
			.S_AXI_WREADY(s00_axi_wready),
			.S_AXI_BRESP(s00_axi_bresp),
			.S_AXI_BVALID(s00_axi_bvalid),
			.S_AXI_BREADY(s00_axi_bready),
			.S_AXI_ARADDR(s00_axi_araddr),
			.S_AXI_ARPROT(s00_axi_arprot),
			.S_AXI_ARVALID(s00_axi_arvalid),
			.S_AXI_ARREADY(s00_axi_arready),
			.S_AXI_RDATA(s00_axi_rdata),
			.S_AXI_RRESP(s00_axi_rresp),
			.S_AXI_RVALID(s00_axi_rvalid),
			.S_AXI_RREADY(s00_axi_rready),
		    «FOR port : portMap.keySet»
		    .slv_reg«portMap.get(port)+1»(slv_reg«portMap.get(port)+1»),
		    «ENDFOR»
		    .slv_reg0(slv_reg0)
		);
		// ----------------------------------------------------------------------------
		
		// Local Memories
		// ----------------------------------------------------------------------------
		// Instantiation of Local Memories
		// ----------------------------------------------------------------------------
		«IF dedicatedInterfaces»
		«FOR port : portMap.keySet»// local memory «portMap.get(port)+1»
		axi_full_ipif # (
			.C_S_AXI_ID_WIDTH(C_S«getLongId(portMap.get(port)+1)»_AXI_ID_WIDTH),
			.C_S_AXI_DATA_WIDTH(C_S«getLongId(portMap.get(port)+1)»_AXI_DATA_WIDTH),
			.C_S_AXI_ADDR_WIDTH(C_S«getLongId(portMap.get(port)+1)»_AXI_ADDR_WIDTH),
			.C_S_AXI_AWUSER_WIDTH(C_S«getLongId(portMap.get(port)+1)»_AXI_AWUSER_WIDTH),
			.C_S_AXI_ARUSER_WIDTH(C_S«getLongId(portMap.get(port)+1)»_AXI_ARUSER_WIDTH),
			.C_S_AXI_WUSER_WIDTH(C_S«getLongId(portMap.get(port)+1)»_AXI_WUSER_WIDTH),
			.C_S_AXI_RUSER_WIDTH(C_S«getLongId(portMap.get(port)+1)»_AXI_RUSER_WIDTH),
			.C_S_AXI_BUSER_WIDTH(C_S«getLongId(portMap.get(port)+1)»_AXI_BUSER_WIDTH)
		) i_local_memory_«portMap.get(port)+1» (
			.S_AXI_ACLK(s«getLongId(portMap.get(port)+1)»_axi_aclk),
			.S_AXI_ARESETN(s«getLongId(portMap.get(port)+1)»_axi_aresetn),
			.S_AXI_AWID(s«getLongId(portMap.get(port)+1)»_axi_awid),
			.S_AXI_AWADDR(s«getLongId(portMap.get(port)+1)»_axi_awaddr),
			.S_AXI_AWLEN(s«getLongId(portMap.get(port)+1)»_axi_awlen),
			.S_AXI_AWSIZE(s«getLongId(portMap.get(port)+1)»_axi_awsize),
			.S_AXI_AWBURST(s«getLongId(portMap.get(port)+1)»_axi_awburst),
			.S_AXI_AWLOCK(s«getLongId(portMap.get(port)+1)»_axi_awlock),
			.S_AXI_AWCACHE(s«getLongId(portMap.get(port)+1)»_axi_awcache),
			.S_AXI_AWPROT(s«getLongId(portMap.get(port)+1)»_axi_awprot),
			.S_AXI_AWQOS(s«getLongId(portMap.get(port)+1)»_axi_awqos),
			.S_AXI_AWREGION(s«getLongId(portMap.get(port)+1)»_axi_awregion),
			.S_AXI_AWUSER(s«getLongId(portMap.get(port)+1)»_axi_awuser),
			.S_AXI_AWVALID(s«getLongId(portMap.get(port)+1)»_axi_awvalid),
			.S_AXI_AWREADY(s«getLongId(portMap.get(port)+1)»_axi_awready),
			.S_AXI_WDATA(s«getLongId(portMap.get(port)+1)»_axi_wdata),
			.S_AXI_WSTRB(s«getLongId(portMap.get(port)+1)»_axi_wstrb),
			.S_AXI_WLAST(s«getLongId(portMap.get(port)+1)»_axi_wlast),
			.S_AXI_WUSER(s«getLongId(portMap.get(port)+1)»_axi_wuser),
			.S_AXI_WVALID(s«getLongId(portMap.get(port)+1)»_axi_wvalid),
			.S_AXI_WREADY(s«getLongId(portMap.get(port)+1)»_axi_wready),
			.S_AXI_BID(s«getLongId(portMap.get(port)+1)»_axi_bid),
			.S_AXI_BRESP(s«getLongId(portMap.get(port)+1)»_axi_bresp),
			.S_AXI_BUSER(s«getLongId(portMap.get(port)+1)»_axi_buser),
			.S_AXI_BVALID(s«getLongId(portMap.get(port)+1)»_axi_bvalid),
			.S_AXI_BREADY(s«getLongId(portMap.get(port)+1)»_axi_bready),
			.S_AXI_ARID(s«getLongId(portMap.get(port)+1)»_axi_arid),
			.S_AXI_ARADDR(s«getLongId(portMap.get(port)+1)»_axi_araddr),
			.S_AXI_ARLEN(s«getLongId(portMap.get(port)+1)»_axi_arlen),
			.S_AXI_ARSIZE(s«getLongId(portMap.get(port)+1)»_axi_arsize),
			.S_AXI_ARBURST(s«getLongId(portMap.get(port)+1)»_axi_arburst),
			.S_AXI_ARLOCK(s«getLongId(portMap.get(port)+1)»_axi_arlock),
			.S_AXI_ARCACHE(s«getLongId(portMap.get(port)+1)»_axi_arcache),
			.S_AXI_ARPROT(s«getLongId(portMap.get(port)+1)»_axi_arprot),
			.S_AXI_ARQOS(s«getLongId(portMap.get(port)+1)»_axi_arqos),
			.S_AXI_ARREGION(s«getLongId(portMap.get(port)+1)»_axi_arregion),
			.S_AXI_ARUSER(s«getLongId(portMap.get(port)+1)»_axi_aruser),
			.S_AXI_ARVALID(s«getLongId(portMap.get(port)+1)»_axi_arvalid),
			.S_AXI_ARREADY(s«getLongId(portMap.get(port)+1)»_axi_arready),
			.S_AXI_RID(s«getLongId(portMap.get(port)+1)»_axi_rid),
			.S_AXI_RDATA(s«getLongId(portMap.get(port)+1)»_axi_rdata),
			.S_AXI_RRESP(s«getLongId(portMap.get(port)+1)»_axi_rresp),
			.S_AXI_RLAST(s«getLongId(portMap.get(port)+1)»_axi_rlast),
			.S_AXI_RUSER(s«getLongId(portMap.get(port)+1)»_axi_ruser),
			.S_AXI_RVALID(s«getLongId(portMap.get(port)+1)»_axi_rvalid),
			.S_AXI_RREADY(s«getLongId(portMap.get(port)+1)»_axi_rready),
			.rden(accelerator_mem_«portMap.get(port)+1»_rden),
			.wren(accelerator_mem_«portMap.get(port)+1»_wren),
			.address(accelerator_mem_«portMap.get(port)+1»_address),
			.data_in(accelerator_mem_«portMap.get(port)+1»_data_in),
			.data_out(accelerator_mem_«portMap.get(port)+1»_data_out)
		);
		«ENDFOR»
		«ELSE»
		axi_full_ipif # (
			.C_S_AXI_ID_WIDTH(C_S01_AXI_ID_WIDTH),
			.C_S_AXI_DATA_WIDTH(C_S01_AXI_DATA_WIDTH),
			.C_S_AXI_ADDR_WIDTH(C_S01_AXI_ADDR_WIDTH),
			.C_S_AXI_AWUSER_WIDTH(C_S01_AXI_AWUSER_WIDTH),
			.C_S_AXI_ARUSER_WIDTH(C_S01_AXI_ARUSER_WIDTH),
			.C_S_AXI_WUSER_WIDTH(C_S01_AXI_WUSER_WIDTH),
			.C_S_AXI_RUSER_WIDTH(C_S01_AXI_RUSER_WIDTH),
			.C_S_AXI_BUSER_WIDTH(C_S01_AXI_BUSER_WIDTH)
		) i_axi_full_ipif (
			.S_AXI_ACLK(s01_axi_aclk),
			.S_AXI_ARESETN(s01_axi_aresetn),
			.S_AXI_AWID(s01_axi_awid),
			.S_AXI_AWADDR(s01_axi_awaddr),
			.S_AXI_AWLEN(s01_axi_awlen),
			.S_AXI_AWSIZE(s01_axi_awsize),
			.S_AXI_AWBURST(s01_axi_awburst),
			.S_AXI_AWLOCK(s01_axi_awlock),
			.S_AXI_AWCACHE(s01_axi_awcache),
			.S_AXI_AWPROT(s01_axi_awprot),
			.S_AXI_AWQOS(s01_axi_awqos),
			.S_AXI_AWREGION(s01_axi_awregion),
			.S_AXI_AWUSER(s01_axi_awuser),
			.S_AXI_AWVALID(s01_axi_awvalid),
			.S_AXI_AWREADY(s01_axi_awready),
			.S_AXI_WDATA(s01_axi_wdata),
			.S_AXI_WSTRB(s01_axi_wstrb),
			.S_AXI_WLAST(s01_axi_wlast),
			.S_AXI_WUSER(s01_axi_wuser),
			.S_AXI_WVALID(s01_axi_wvalid),
			.S_AXI_WREADY(s01_axi_wready),
			.S_AXI_BID(s01_axi_bid),
			.S_AXI_BRESP(s01_axi_bresp),
			.S_AXI_BUSER(s01_axi_buser),
			.S_AXI_BVALID(s01_axi_bvalid),
			.S_AXI_BREADY(s01_axi_bready),
			.S_AXI_ARID(s01_axi_arid),
			.S_AXI_ARADDR(s01_axi_araddr),
			.S_AXI_ARLEN(s01_axi_arlen),
			.S_AXI_ARSIZE(s01_axi_arsize),
			.S_AXI_ARBURST(s01_axi_arburst),
			.S_AXI_ARLOCK(s01_axi_arlock),
			.S_AXI_ARCACHE(s01_axi_arcache),
			.S_AXI_ARPROT(s01_axi_arprot),
			.S_AXI_ARQOS(s01_axi_arqos),
			.S_AXI_ARREGION(s01_axi_arregion),
			.S_AXI_ARUSER(s01_axi_aruser),
			.S_AXI_ARVALID(s01_axi_arvalid),
			.S_AXI_ARREADY(s01_axi_arready),
			.S_AXI_RID(s01_axi_rid),
			.S_AXI_RDATA(s01_axi_rdata),
			.S_AXI_RRESP(s01_axi_rresp),
			.S_AXI_RLAST(s01_axi_rlast),
			.S_AXI_RUSER(s01_axi_ruser),
			.S_AXI_RVALID(s01_axi_rvalid),
			.S_AXI_RREADY(s01_axi_rready),
			.rden(s01_axi_rden),
			.wren(s01_axi_wren),
			.address(s01_axi_address),
			.data_in(s01_axi_data_in),
			.data_out(s01_axi_data_out)
		);
		«FOR port : portMap.keySet»// local memory «portMap.get(port)+1»
		local_memory # (
			.SIZE_MEM(256),
			.SIZE_ADDR(8)
		) i_local_memory_«portMap.get(port)+1» (
			.aclk(s01_axi_aclk),
			.ce_a(ce_«portMap.get(port)+1»),
			.rden_a(s01_axi_rden),
			.wren_a(s01_axi_wren),
			.address_a(s01_axi_address),
			.data_in_a(s01_axi_data_in),
			.data_out_a(data_out_«portMap.get(port)+1»),
			.rden_b(rden_mem_«portMap.get(port)+1»),
			.wren_b(wren_mem_«portMap.get(port)+1»),
			.address_b(address_mem_«portMap.get(port)+1»),
			.data_in_b(data_in_mem_«portMap.get(port)+1»),
			.data_out_b(data_out_mem_«portMap.get(port)+1»)
		);
		
		assign ce_«portMap.get(port)+1» = (s01_axi_rden || s01_axi_wren) && (s01_axi_address[«8+Math.ceil(Math.log10(portMap.size) / Math.log10(2)).intValue-1»:8] == «portMap.get(port)»);
		«ENDFOR»
		
		always@(s01_axi_address or «FOR port : portMap.keySet SEPARATOR " or "»data_out_«portMap.get(port)+1»«ENDFOR»)
			case(s01_axi_address[«8+Math.ceil(Math.log10(portMap.size) / Math.log10(2)).intValue-1»:8])
				«FOR port : portMap.keySet»
					«portMap.get(port)»:	s01_axi_data_out = data_out_«portMap.get(port)+1»;
				«ENDFOR»
				default:	s01_axi_data_out = 0;
			endcase
		«ENDIF»
		// ----------------------------------------------------------------------------
		
		// Coprocessor Front-End(s)
		// ----------------------------------------------------------------------------
		«FOR input : inputMap.keySet()»
		front_end i_front_end_«input.name»(
			.aclk(s«IF dedicatedInterfaces»«getLongId(portMap.get(input)+1)»«ELSE»01«ENDIF»_axi_aclk),
			.aresetn(s«IF dedicatedInterfaces»«getLongId(portMap.get(input)+1)»«ELSE»01«ENDIF»_axi_aresetn),
			.start(slv_reg0[0]),
			.done(done_«input.name»),
			.full(«input.name»_full),
			.en(en_«input.name»),
			.rden(rden_mem_«portMap.get(input)+1»),
			.wr(«input.name»_wr)
		);
		
		counter #(			
			.SIZE(12) ) 
		i_counter_«input.name» (
			.aclk(s«IF dedicatedInterfaces»«getLongId(portMap.get(input)+1)»«ELSE»01«ENDIF»_axi_aclk),
			.aresetn(s«IF dedicatedInterfaces»«getLongId(portMap.get(input)+1)»«ELSE»01«ENDIF»_axi_aresetn),
			.clr(slv_reg0[1]),
			.en(en_«input.name»),
			.max(slv_reg«portMap.get(input)+1»[31:20]),
			.count(count_«input.name»),
			.done(done_«input.name»)
		);
		
		assign address_mem_«portMap.get(input)+1» = count_«input.name»+slv_reg«portMap.get(input)+1»[11:4];
		assign wren_mem_«portMap.get(input)+1» = 1'b0;
		assign data_in_mem_«portMap.get(input)+1» = 32'b0;
		assign «input.name»_count = {8'b0,slv_reg«portMap.get(input)+1»[31:20]-count_«input.name»};
		
		«ENDFOR»
		// ----------------------------------------------------------------------------
			
		// Multi-Dataflow Reconfigurable Datapath
		// ----------------------------------------------------------------------------
		«printTopDatapath()»
		«FOR input :inputMap.keySet»
		assign «input.name»_data = data_out_mem_«portMap.get(input)+1»«IF input.type.sizeInBits<32»[«input.type.sizeInBits-1»:0]«ENDIF»;
		«ENDFOR»
		«FOR output :outputMap.keySet»
		assign data_in_mem_«portMap.get(output)+1» = «IF output.type.sizeInBits<32»{{«output.type.sizeInBits»{1'b0}},«output.name»_data}«ELSE»«output.name»_data«ENDIF»;
		«ENDFOR»
		// ----------------------------------------------------------------------------	
		
		// Coprocessor Back-End(s)
		// ----------------------------------------------------------------------------
		«FOR output : outputMap.keySet()»
		back_end i_back_end_«output.name»(
			.aclk(s«IF dedicatedInterfaces»«getLongId(portMap.get(output)+1)»«ELSE»01«ENDIF»_axi_aclk),
			.aresetn(s«IF dedicatedInterfaces»«getLongId(portMap.get(output)+1)»«ELSE»01«ENDIF»_axi_aresetn),
			.start(slv_reg0[0]),
			.done(done_«output.name»),
			.wr(«output.name»_wr),
			.wren(wren_mem_«portMap.get(output)+1»),
			.en(en_«output.name»),
			.full(«output.name»_full)
		);
		
		counter #(			
			.SIZE(12) ) 
		i_counter_«output.name» (
			.aclk(s«IF dedicatedInterfaces»«getLongId(portMap.get(output)+1)»«ELSE»01«ENDIF»_axi_aclk),
			.aresetn(s«IF dedicatedInterfaces»«getLongId(portMap.get(output)+1)»«ELSE»01«ENDIF»_axi_aresetn),
			.clr(slv_reg0[1]),
			.en(en_«output.name»),
			.max(slv_reg«portMap.get(output)+1»[31:20]),
			.count(count_«output.name»),
			.done(done_«output.name»)
		);
		
		assign address_mem_«portMap.get(output)+1» = count_«output.name»+slv_reg«portMap.get(output)+1»[11:4];
		assign rden_mem_«portMap.get(output)+1» = 1'b0;
		
		«ENDFOR»
		// ----------------------------------------------------------------------------
		'''
	}
	
	def printTopDatapath() {
		'''
		// to adapt profiling
		multi_dataflow reconf_dpath (
			// Multi-Dataflow Input(s)
			«FOR input : inputMap.keySet()»
			«FOR commSigId : getInFirstModCommSignals().keySet»
			.«input.getName()»«getSuffix(getInFirstModCommSignals(),commSigId)»(«input.getName()»_«getMatchingWrapMapping(getFirstModCommSignals().get(commSigId).get(ProtocolManager.CH))»),
			«ENDFOR»
			«ENDFOR»
			// Multi-Dataflow Output(s)
			«FOR output : outputMap.keySet()»
			«FOR commSigId : getOutLastModCommSignals().keySet»
			.«output.getName()»«getSuffix(getOutLastModCommSignals(),commSigId)»(«output.getName()»_«getMatchingWrapMapping(getLastModCommSignals().get(commSigId).get(ProtocolManager.CH))»),
			«ENDFOR»
			«ENDFOR»
			«FOR clockSignal : getClockSysSignals()»
			.«clockSignal»(s00_axi_aclk),
			«ENDFOR»
			«FOR resetSignal : getResetSysSignals().keySet»
			.«resetSignal»(«IF getResetSysSignals().get(resetSignal).equals("HIGH")»!«ENDIF»s00_axi_aresetn),
			«ENDFOR»
			// Multi-Dataflow Kernel ID
			.ID(slv_reg0[31:24])	
		);
		'''
	}
	
	def getSuffix(Map<String,String> idNameMap, String id) {
		if(idNameMap.containsKey(id)) {
			if(idNameMap.get(id).equals("")) {
				return ""
			} else {
				return "_" + idNameMap.get(id)
			}
		}
		return null
	}
	
	def getMatchingWrapMapping(String channel){
		for(commSigId : wrapCommSignals.keySet) {
			if(wrapCommSignals.get(commSigId).containsKey(ProtocolManager.CH)) {
				if(channel.equals(wrapCommSignals.get(commSigId).get(ProtocolManager.CH))) {
					return wrapCommSignals.get(commSigId).get(ProtocolManager.MAP)
				}
			}
		}
		return null
	}
		
	def getOutLastModCommSignals(){
		var Map<String,String> result = new HashMap<String,String>();
		for(commSigId : getLastModCommSignals().keySet) {
			if( (getLastModCommSignals().get(commSigId).get(ProtocolManager.KIND).equals("output") 
					&& getLastModCommSignals().get(commSigId).get(ProtocolManager.DIR).equals("direct") )
					|| (getLastModCommSignals().get(commSigId).get(ProtocolManager.KIND).equals("input")
					&& getLastModCommSignals().get(commSigId).get(ProtocolManager.DIR).equals("reverse") ) ) {
				System.out.println("lmcs " + commSigId + " " + getLastModCommSignals().get(commSigId).get(ProtocolManager.CH))
				result.put(commSigId,getLastModCommSignals().get(commSigId).get(ProtocolManager.CH));	
			}
		}
		return result
	}
	
	def getLastModCommSignals(){
		if(modCommSignals.containsKey(ProtocolManager.SUCC)) {
			return modCommSignals.get(ProtocolManager.SUCC)
		} else {
			return modCommSignals.get(ProtocolManager.ACTOR)
		}
	}
	
	def getInFirstModCommSignals(){
		var Map<String,String> result = new HashMap<String,String>();
		for(commSigId : getFirstModCommSignals().keySet) {
			if( (getFirstModCommSignals().get(commSigId).get(ProtocolManager.KIND).equals("input") 
					&& getFirstModCommSignals().get(commSigId).get(ProtocolManager.DIR).equals("direct") )
					|| (getFirstModCommSignals().get(commSigId).get(ProtocolManager.KIND).equals("output")
					&& getFirstModCommSignals().get(commSigId).get(ProtocolManager.DIR).equals("reverse") ) ) {
				System.out.println("fmcs " + commSigId + " " + getFirstModCommSignals().get(commSigId).get(ProtocolManager.CH))
				result.put(commSigId,getFirstModCommSignals().get(commSigId).get(ProtocolManager.CH));		
			}
		}
		return result
	}
	
	def getFirstModCommSignals(){
		if(modCommSignals.containsKey(ProtocolManager.PRED)) {
			return modCommSignals.get(ProtocolManager.PRED)
		} else {
			return modCommSignals.get(ProtocolManager.ACTOR)
		}
	}
	
	def getClockSysSignals(){
		var List<String> result = new ArrayList<String>();
		for(String sysSigId : netSysSignals.keySet) {
			if(netSysSignals.get(sysSigId).containsKey(ProtocolManager.CLOCK)) {
				result.add(netSysSignals.get(sysSigId).get(ProtocolManager.NETP))
			}
		}
		return result
	}
	
	def getResetSysSignals(){
		var Map<String,String> result = new HashMap<String,String>();
		for(String sysSigId : netSysSignals.keySet) {
			if(netSysSignals.get(sysSigId).containsKey(ProtocolManager.RST)) {
				result.put(netSysSignals.get(sysSigId).get(ProtocolManager.NETP),"HIGH")
			} else if(netSysSignals.get(sysSigId).containsKey(ProtocolManager.RSTN)) {
				result.put(netSysSignals.get(sysSigId).get(ProtocolManager.NETP),"LOW")
			}
		}
		return result
	}
	
	def printTestBench() {
		
		var dateFormat = new SimpleDateFormat("yyyy/MM/dd HH:mm:ss");
		var date = new Date();
		
		'''
		`timescale 1ns / 1ps
		// ----------------------------------------------------------------------------
		//
		// Multi-Dataflow Composer tool - Platform Composer
		// TIL Test Bench module 
		// Date: «dateFormat.format(date)»
		//
		// ----------------------------------------------------------------------------	
		
		// ----------------------------------------------------------------------------
		// Module Interface
		// ----------------------------------------------------------------------------
		module tb_copr;
		// ----------------------------------------------------------------------------
		
		// ----------------------------------------------------------------------------
		// Module Parameters
		// ----------------------------------------------------------------------------
		parameter SIZEID = 8;				// size of Kernel ID signal
		parameter SIZEADDRESS = 12;			// size of the local memory address signal
		parameter SIZECOUNT = 12;			// size of the size counters
		parameter SIZEPORT = «portSize»;	// bits needed to codify the number of ports
		parameter SIZEDATA = «dataSize»;	// size of the data signal
		parameter SIZEBURST = 8;			// size of the burst counter
		parameter SIZESIGNAL = 1; 			// size of the control signals
		parameter FIFO_DEPTH = 4; 				//	FIFO depth
		parameter f_ptr_width = 5; 			//	because depth =16 + OVERFLOW
		parameter f_half_full_value = 8;	//
		parameter f_almost_full_value = 14;	//
		parameter f_almost_empty_value = 2;	//
		// ----------------------------------------------------------------------------
		
		// ----------------------------------------------------------------------------
		// Module Signals
		// ----------------------------------------------------------------------------
		// Input Reg(s)
		reg clk;
		reg rst;
		reg [SIZEDATA-1 : 0] 		datain;		// local memory - data in
		reg [SIZEADDRESS-1 : 0] 	addressrd;	// local memory - read address
		reg [SIZEADDRESS-1 : 0] 	addresswr; 	// local memory - write address
		reg 						enablerd;	// local memory - enable read port
		reg							enablewr;   // local memory - enable write port
		reg 						write;      // local memory - write enable
		reg [SIZEID-1 : 0] 			kernelIDin; // kernel ID
		reg 						kernelIDen;
		«FOR port : portMap.keySet()»
		reg [SIZEDATA-1 : 0] 		confin_«portMap.get(port)»;
		reg 						en_«portMap.get(port)»;
		«ENDFOR»
		// Output Wire(s)
		wire [SIZEDATA-1 : 0] 		dataout;
		wire [SIZEID-1 : 0] 		kernelIDout;
		//wire 						finish;
		
		integer i;
		// ----------------------------------------------------------------------------
		
		// ----------------------------------------------------------------------------
		// Unit Under Test Instantiation
		// ----------------------------------------------------------------------------
		coprocessor #(
			.SIZEID(SIZEID),
			.SIZEADDRESS(SIZEADDRESS),
			.SIZECOUNT(SIZECOUNT),
			.SIZEPORT(SIZEPORT),
			.SIZEDATA(SIZEDATA),
			.SIZEBURST(SIZEBURST),
			.SIZESIGNAL(SIZESIGNAL),
			.FIFO_DEPTH(FIFO_DEPTH)//,
			//.f_ptr_width(f_ptr_width)//,
			//.f_half_full_value(f_ptr_width), 
			//.f_almost_full_value(f_almost_full_value),
			//.f_almost_empty_value(f_almost_empty_value) 
			)
		uut (
			.clk(clk),
			.rst(rst),
			.datain(datain),
			.addressrd(addressrd),
			.addresswr(addresswr),
			.enablerd(enablerd),
			.enablewr(enablewr),
			.write(write),
			.kernelIDin(kernelIDin),
			.kernelIDen(kernelIDen),
			.kernelIDout(kernelIDout),
			«FOR port : portMap.keySet()»
			.confin_«portMap.get(port)»(confin_«portMap.get(port)»),
			.en_«portMap.get(port)»(en_«portMap.get(port)»),
			«ENDFOR»
			.dataout(dataout)
			//.finish(finish)
		);
		// ----------------------------------------------------------------------------
		
		// ----------------------------------------------------------------------------
		// Body
		// ----------------------------------------------------------------------------
		
		// Clock Always
		always 
			#5 clk = ~clk;
		
		// Input(s) Setting
		initial begin
		
			// Initialize Input(s)
			clk = 0;
			rst = 0;
			datain = 0;
			addressrd = 0;
			addresswr = 0;
			enablerd = 0;
			enablewr = 0;
			write = 0;
			kernelIDin = 0;
			kernelIDen = 0;
			«FOR port : portMap.keySet()»
			confin_«portMap.get(port)» = 0;
			en_«portMap.get(port)» = 0;
			«ENDFOR»
			// Reset System
			#12	rst = 1;
			#10	rst = 0;
			
			// Write Data into Memory
			#10	enablewr = 1;	// enable writing port
				write = 1;		// enable write
				«FOR input : inputMap.keySet()»
				for(i=0;i<4;i=i+1)
				begin
				datain = «inputMap.get(input)*10»+i;		// written data «inputMap.get(input)*10»
				addresswr = «inputMap.get(input)*10»+i;	// write address «inputMap.get(input)-1»
				#10;
				end
				«ENDFOR»
				enablewr = 0; 	// disable writing port
				write = 0;		// disable write
		
			// Setting Configuration Registers
			#10
				«FOR port : portMap.keySet()»
				confin_«portMap.get(port)» = (1<<(SIZEADDRESS+SIZECOUNT))	// burst port «portMap.get(port)»
												| (4<<SIZEADDRESS)			// size port «portMap.get(port)»
												| «portMap.get(port)» *10;	// baseaddr port «portMap.get(port)»
				en_«portMap.get(port)» = 1;
				«ENDFOR»
			#10
				«FOR port : portMap.keySet()»
				en_«portMap.get(port)» = 0;
				«ENDFOR»
			
			// Setting Kernel ID (Start Computation)
			#10	kernelIDin = 1;	// kernel ID 1
				kernelIDen = 1;
			#10 kernelIDen = 0;
		
			#200 $stop;
		end
		// ----------------------------------------------------------------------------
		
		endmodule		
		// ----------------------------------------------------------------------------
		// ----------------------------------------------------------------------------
		// ----------------------------------------------------------------------------
		'''
	}
		
	def printRegs(){
		
		var dateFormat = new SimpleDateFormat("yyyy/MM/dd HH:mm:ss");
		var date = new Date();
		var size_pointer = computeSizePointer();
		
		'''
	// ----------------------------------------------------------------------------
	//
	// Multi-Dataflow Composer tool - Platform Composer
	// Configuration Registers module 
	// Date: «dateFormat.format(date)»
	//
	// ----------------------------------------------------------------------------	
	
	// ----------------------------------------------------------------------------
	// Module Interface
	// ----------------------------------------------------------------------------
	module config_registers #(
		// Width of S_AXI data bus
		parameter integer C_S_AXI_DATA_WIDTH	= 32,
		// Width of S_AXI address bus
		parameter integer C_S_AXI_ADDR_WIDTH	= «size_pointer»
	)
	(
		output reg [C_S_AXI_DATA_WIDTH-1:0]    slv_reg0,
		«FOR port : portMap.keySet»output reg [C_S_AXI_DATA_WIDTH-1:0]    slv_reg«portMap.get(port)+1»,
		«ENDFOR»

		// Global Clock Signal
		input wire  S_AXI_ACLK,
		// Global Reset Signal. This Signal is Active LOW
		input wire  S_AXI_ARESETN,
		// Write address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
		// Write channel Protection type. This signal indicates the
		// privilege and security level of the transaction, and whether
		// the transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_AWPROT,
		// Write address valid. This signal indicates that the master signaling
		// valid write address and control information.
		input wire  S_AXI_AWVALID,
		// Write address ready. This signal indicates that the slave is ready
		// to accept an address and associated control signals.
		output wire  S_AXI_AWREADY,
		// Write data (issued by master, acceped by Slave) 
		input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
		// Write strobes. This signal indicates which byte lanes hold
		// valid data. There is one write strobe bit for each eight
		// bits of the write data bus.    
		input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
		// Write valid. This signal indicates that valid write
		// data and strobes are available.
		input wire  S_AXI_WVALID,
		// Write ready. This signal indicates that the slave
		// can accept the write data.
		output wire  S_AXI_WREADY,
		// Write response. This signal indicates the status
		// of the write transaction.
		output wire [1 : 0] S_AXI_BRESP,
		// Write response valid. This signal indicates that the channel
		// is signaling a valid write response.
		output wire  S_AXI_BVALID,
		// Response ready. This signal indicates that the master
		// can accept a write response.
		input wire  S_AXI_BREADY,
		// Read address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
		// Protection type. This signal indicates the privilege
		// and security level of the transaction, and whether the
		// transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_ARPROT,
		// Read address valid. This signal indicates that the channel
		// is signaling valid read address and control information.
		input wire  S_AXI_ARVALID,
		// Read address ready. This signal indicates that the slave is
		// ready to accept an address and associated control signals.
		output wire  S_AXI_ARREADY,
		// Read data (issued by slave)
		output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
		// Read response. This signal indicates the status of the
		// read transfer.
		output wire [1 : 0] S_AXI_RRESP,
		// Read valid. This signal indicates that the channel is
		// signaling the required read data.
		output wire  S_AXI_RVALID,
		// Read ready. This signal indicates that the master can
		// accept the read data and response information.
		input wire  S_AXI_RREADY
	);
	
		// AXI4LITE signals
		reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
		reg  	axi_awready;
		reg  	axi_wready;
		reg [1 : 0] 	axi_bresp;
		reg  	axi_bvalid;
		reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
		reg  	axi_arready;
		reg [C_S_AXI_DATA_WIDTH-1 : 0] 	axi_rdata;
		reg [1 : 0] 	axi_rresp;
		reg  	axi_rvalid;
	
		// Example-specific design signals
		// local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
		// ADDR_LSB is used for addressing 32/64 bit registers/memories
		// ADDR_LSB = 2 for 32 bits (n downto 2)
		// ADDR_LSB = 3 for 64 bits (n downto 3)
		localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
		localparam integer OPT_MEM_ADDR_BITS = 1;
		//----------------------------------------------
		//-- Signals for user logic register space example
		//------------------------------------------------
		wire	 slv_reg_rden;
		wire	 slv_reg_wren;
		reg [C_S_AXI_DATA_WIDTH-1:0]	 reg_data_out;
		integer	 byte_index;
	
		// I/O Connections assignments
	
		assign S_AXI_AWREADY	= axi_awready;
		assign S_AXI_WREADY	= axi_wready;
		assign S_AXI_BRESP	= axi_bresp;
		assign S_AXI_BVALID	= axi_bvalid;
		assign S_AXI_ARREADY	= axi_arready;
		assign S_AXI_RDATA	= axi_rdata;
		assign S_AXI_RRESP	= axi_rresp;
		assign S_AXI_RVALID	= axi_rvalid;
		
		
		// Implement axi_awready generation
		// axi_awready is asserted for one S_AXI_ACLK clock cycle when both
		// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
		// de-asserted when reset is low.
		always @( posedge S_AXI_ACLK )
		begin
		  if ( S_AXI_ARESETN == 1'b0 )
		    begin
		      axi_awready <= 1'b0;
		    end 
		  else
		    begin    
		      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID)
		        begin
		          // slave is ready to accept write address when 
		          // there is a valid write address and write data
		          // on the write address and data bus. This design 
		          // expects no outstanding transactions. 
		          axi_awready <= 1'b1;
		        end
		      else           
		        begin
		          axi_awready <= 1'b0;
		        end
		    end 
		end
		
		// Implement axi_awaddr latching
		// This process is used to latch the address when both 
		// S_AXI_AWVALID and S_AXI_WVALID are valid. 
		always @( posedge S_AXI_ACLK )
		begin
		  if ( S_AXI_ARESETN == 1'b0 )
		    begin
		      axi_awaddr <= 0;
		    end 
		  else
		    begin    
		      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID)
		        begin
		          // Write Address latching 
		          axi_awaddr <= S_AXI_AWADDR;
		        end
		    end 
		end
		
		// Implement axi_wready generation
		// axi_wready is asserted for one S_AXI_ACLK clock cycle when both
		// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
		// de-asserted when reset is low. 
		always @( posedge S_AXI_ACLK )
		begin
		  if ( S_AXI_ARESETN == 1'b0 )
		    begin
		      axi_wready <= 1'b0;
		    end 
		  else
		    begin    
		      if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID)
		        begin
		          // slave is ready to accept write data when 
		          // there is a valid write address and write data
		          // on the write address and data bus. This design 
		          // expects no outstanding transactions. 
		          axi_wready <= 1'b1;
		        end
		      else
		        begin
		          axi_wready <= 1'b0;
		        end
		    end 
		end
		
		// Implement memory mapped register select and write logic generation
		// The write data is accepted and written to memory mapped registers when
		// axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
		// select byte enables of slave registers while writing.
		// These registers are cleared when reset (active low) is applied.
		// Slave register write enable is asserted when valid address and data are available
		// and the slave is ready to accept the write address and write data.
		assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;
		always @( posedge S_AXI_ACLK )
		begin
		  if ( S_AXI_ARESETN == 1'b0 )
		    begin
		      slv_reg0 <= 0;
		      «FOR port : portMap.keySet»
		      slv_reg«portMap.get(port)+1» <= 0;
		      «ENDFOR»
		    end 
		  else begin
		    if (slv_reg_wren)
		      begin
		        case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
		          «size_pointer»'h0:
		            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
		              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
		                // Respective byte enables are asserted as per write strobes 
		                // Slave register 0
		                slv_reg0[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
		              end
	          	  «FOR port : portMap.keySet»«size_pointer»'h«portMap.get(port)+1»:
	          	  	for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	          	  		if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	          	  			// Respective byte enables are asserted as per write strobes
	          	  			// Slave register «portMap.get(port)+1»
	          	  			slv_reg«portMap.get(port)+1»[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	          	  			end
	              «ENDFOR»
		          default : begin
		                      slv_reg0 <= slv_reg0;
		                      «FOR port : portMap.keySet»slv_reg«portMap.get(port)+1» <= slv_reg«portMap.get(port)+1»;
							  «ENDFOR»
		                    end
		        endcase
		      end
		  end
		end
		
		// Implement write response logic generation
		// The write response and response valid signals are asserted by the slave 
		// when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
		// This marks the acceptance of address and indicates the status of 
		// write transaction.
		always @( posedge S_AXI_ACLK )
		begin
		  if ( S_AXI_ARESETN == 1'b0 )
		    begin
		      axi_bvalid  <= 0;
		      axi_bresp   <= 2'b0;
		    end 
		  else
		    begin    
		      if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
		        begin
		          // indicates a valid write response is available
		          axi_bvalid <= 1'b1;
		          axi_bresp  <= 2'b0; // 'OKAY' response 
		        end                   // work error responses in future
		      else
		        begin
		          if (S_AXI_BREADY && axi_bvalid) 
		            //check if bready is asserted while bvalid is high) 
		            //(there is a possibility that bready is always asserted high)   
		            begin
		              axi_bvalid <= 1'b0; 
		            end  
		        end
		    end
		end
		
		// Implement axi_arready generation
		// axi_arready is asserted for one S_AXI_ACLK clock cycle when
		// S_AXI_ARVALID is asserted. axi_awready is 
		// de-asserted when reset (active low) is asserted. 
		// The read address is also latched when S_AXI_ARVALID is 
		// asserted. axi_araddr is reset to zero on reset assertion.
		always @( posedge S_AXI_ACLK )
		begin
		  if ( S_AXI_ARESETN == 1'b0 )
		    begin
		      axi_arready <= 1'b0;
		      axi_araddr  <= 32'b0;
		    end 
		  else
		    begin    
		      if (~axi_arready && S_AXI_ARVALID)
		        begin
		          // indicates that the slave has acceped the valid read address
		          axi_arready <= 1'b1;
		          // Read address latching
		          axi_araddr  <= S_AXI_ARADDR;
		        end
		      else
		        begin
		          axi_arready <= 1'b0;
		        end
		    end 
		end 
		
		// Implement axi_arvalid generation
		// axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
		// S_AXI_ARVALID and axi_arready are asserted. The slave registers 
		// data are available on the axi_rdata bus at this instance. The 
		// assertion of axi_rvalid marks the validity of read data on the 
		// bus and axi_rresp indicates the status of read transaction.axi_rvalid 
		// is deasserted on reset (active low). axi_rresp and axi_rdata are 
		// cleared to zero on reset (active low).  
		always @( posedge S_AXI_ACLK )
		begin
		  if ( S_AXI_ARESETN == 1'b0 )
		    begin
		      axi_rvalid <= 0;
		      axi_rresp  <= 0;
		    end 
		  else
		    begin    
		      if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
		        begin
		          // Valid read data is available at the read data bus
		          axi_rvalid <= 1'b1;
		          axi_rresp  <= 2'b0; // 'OKAY' response
		        end   
		      else if (axi_rvalid && S_AXI_RREADY)
		        begin
		          // Read data is accepted by the master
		          axi_rvalid <= 1'b0;
		        end                
		    end
		end
		
		// Implement memory mapped register select and read logic generation
		// Slave register read enable is asserted when valid address is available
		// and the slave is ready to accept the read address.
		assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;
		always @(*)
		begin
		      // Address decoding for reading registers
		      case ( axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
		         «size_pointer»'h0   : reg_data_out <= slv_reg0;
	            «FOR port : portMap.keySet»2'h«portMap.get(port)+1»   : reg_data_out <= slv_reg«portMap.get(port)+1»;
				«ENDFOR»
		        default : reg_data_out <= 0;
		      endcase
		end
		
		// Output register or memory read data
		always @( posedge S_AXI_ACLK )
		begin
		  if ( S_AXI_ARESETN == 1'b0 )
		    begin
		      axi_rdata  <= 0;
		    end 
		  else
		    begin    
		      // When there is a valid read address (S_AXI_ARVALID) with 
		      // acceptance of read address by the slave (axi_arready), 
		      // output the read dada 
		      if (slv_reg_rden)
		        begin
		          axi_rdata <= reg_data_out;     // register read data
		        end   
		    end
		end

	endmodule
	'''
	}

	
	override printSoftwareDriver(Network network, Map<String,Map<String,String>> networkVertexMap, ConfigManager configManager, String file){
		
		if (file.equals("HIGH_HEAD")) {
			printHighDriverHeader(network,networkVertexMap);
		} else if (file.equals("HIGH_SRC")) {
			printHighDriver(network,networkVertexMap,configManager);
		}
		
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
		*  Filename:          mm_accelerator_h.c
		*  Description:       Memory-Mapped Accelerator High Level Driver
		*  Date:              «dateFormat.format(date)» (by Multi-Dataflow Composer - Platform Composer)
		*****************************************************************************/
		
		#include "mm_accelerator_h.h"

		«FOR net : networkVertexMap.keySet SEPARATOR "\n"»
		int mm_accelerator_«net»(
			«FOR port : netIdPortMap.get(net) SEPARATOR ","»
			// port «port.name»
			int size_«portMap.get(port)», int* data_«portMap.get(port)»
			«ENDFOR»
			) {
			
			
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
			
			// stop execution
			*((int*) MM_ACCELERATOR_CFG_BASEADDR) = 0x«Integer.toHexString(0)»;
			
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
		*  Filename:          m_accelerator_h.h
		*  Description:       Memory-Mapped Accelerator High Level Driver Header
		*  Date:              «dateFormat.format(date)» (by Multi-Dataflow Composer - Platform Composer)
		*****************************************************************************/
		
		#ifndef MM_ACCELERATOR_H_H
		#define MM_ACCELERATOR_H_H
		
		/***************************** Include Files *******************************/		
		#include "xparameters.h"
		#include "fsl.h"
		
		/************************** Constant Definitions ***************************/
		#define MM_ACCELERATOR_CFG_BASEADDR 0x44A00000
		#define MM_ACCELERATOR_MEM_BASEADDR 0x76000000
		«FOR port : portMap.keySet»
		#define MM_ACCELERATOR_MEM_«portMap.get(port)+1»_OFFSET 0x«Integer.toHexString(portMap.get(port)*4*256)»
		«ENDFOR»
		
		/************************* Functions Definitions ***************************/
		
		
		«FOR net : networkVertexMap.keySet»
		int mm_accelerator_«net»(
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