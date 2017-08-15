/*
 *
 */
 
package it.mdc.tool.platformComposer

import java.text.SimpleDateFormat
import java.util.Date
import net.sf.orcc.df.Network
import java.util.ArrayList
import java.util.Map
import java.util.HashMap
import net.sf.orcc.df.Port
import it.mdc.tool.ConfigManager

/*
 * Vivado Template Interface Layer 
 * Memory-Mapped HW Accelerator Printer
 * 
 * @author Carlo Sau
 */
class TilPrinterVivadoMm extends TilPrinter {
	
	HashMap<String,String> AXIlitePorts;
	HashMap<String,String> AXIfullPorts;
	
	boolean dedicatedInterfaces = false
	boolean useDMA = false
	
	def initAXIlitePorts() {
		// slave side
		AXIlitePorts = new HashMap<String,String>();
		AXIlitePorts.put("AWADDR","in_bus_ADDR_WIDTH_32");
		AXIlitePorts.put("AWPROT","in_bus_3");
		AXIlitePorts.put("AWVALID","in");
		AXIlitePorts.put("AWREADY","out");
		AXIlitePorts.put("WDATA","in_bus_DATA_WIDTH_32");
		AXIlitePorts.put("WSTRB","in_bus_4");
		AXIlitePorts.put("WVALID","in");
		AXIlitePorts.put("WREADY","out");
		AXIlitePorts.put("BRESP","out_bus_2");
		AXIlitePorts.put("BVALID","out");
		AXIlitePorts.put("BREADY","in");
		AXIlitePorts.put("ARADDR","in_bus_ADDR_WIDTH_32");
		AXIlitePorts.put("ARPROT","in_bus_3");
		AXIlitePorts.put("ARVALID","in");
		AXIlitePorts.put("ARREADY","out");
		AXIlitePorts.put("RDATA","out_bus_DATA_WIDTH_32");
		AXIlitePorts.put("RRESP","out_bus_2");
		AXIlitePorts.put("RVALID","out");
		AXIlitePorts.put("RREADY","in");
	}
	
	def initAXIfullPorts() {
		//slave side
		AXIfullPorts = new HashMap<String,String>();
		AXIfullPorts.put("AWID","in_bus_ID_WIDTH_1");
		AXIfullPorts.put("AWADDR","in_bus_ADDR_WIDTH_" + Math.ceil(10+Math.log10(portMap.size) / Math.log10(2)).intValue);
		AXIfullPorts.put("AWLEN","in_bus_8");
		AXIfullPorts.put("AWSIZE","in_bus_3");
		AXIfullPorts.put("AWBURST","in_bus_2");
		AXIfullPorts.put("AWLOCK","in");
		AXIfullPorts.put("AWCACHE","in_bus_4");
		AXIfullPorts.put("AWPROT","in_bus_3");
		AXIfullPorts.put("AWREGION","in_bus_4");
		AXIfullPorts.put("AWQOS","in_bus_4");
		AXIfullPorts.put("AWUSER","in_bus_AWUSER_WIDTH_1");
		AXIfullPorts.put("AWVALID","in");
		AXIfullPorts.put("AWREADY","out");
		AXIfullPorts.put("WDATA","in_bus_DATA_WIDTH_32");
		AXIfullPorts.put("WSTRB","in_bus_4");
		AXIfullPorts.put("WLAST","in");
		AXIfullPorts.put("WUSER","in_bus_WUSER_WIDTH_1");
		AXIfullPorts.put("WVALID","in");
		AXIfullPorts.put("WREADY","out");
		AXIfullPorts.put("BID","out_bus_ID_WIDTH_1");
		AXIfullPorts.put("BRESP","out_bus_2");
		AXIfullPorts.put("BUSER","out_bus_BUSER_WIDTH_1");
		AXIfullPorts.put("BVALID","out");
		AXIfullPorts.put("BREADY","in");
		AXIfullPorts.put("ARID","in_bus_ID_WIDTH_1");
		AXIfullPorts.put("ARADDR","in_bus_ADDR_WIDTH_32");
		AXIfullPorts.put("ARLEN","in_bus_8");
		AXIfullPorts.put("ARSIZE","in_bus_3");
		AXIfullPorts.put("ARBURST","in_bus_2");
		AXIfullPorts.put("ARLOCK","in");
		AXIfullPorts.put("ARCACHE","in_bus_4");
		AXIfullPorts.put("ARPROT","in_bus_3");
		AXIfullPorts.put("ARREGION","in_bus_4");
		AXIfullPorts.put("ARQOS","in_bus_4");
		AXIfullPorts.put("ARUSER","in_bus_ARUSER_WIDTH_1");
		AXIfullPorts.put("ARVALID","in");
		AXIfullPorts.put("ARREADY","out");
		AXIfullPorts.put("RID","out_bus_ID_WIDTH_1");
		AXIfullPorts.put("RDATA","out_bus_DATA_WIDTH_32");
		AXIfullPorts.put("RRESP","out_bus_2");
		AXIfullPorts.put("RLAST","out");
		AXIfullPorts.put("RUSER","out_bus_RUSER_WIDTH_1");
		AXIfullPorts.put("RVALID","out");
		AXIfullPorts.put("RREADY","in");
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

	def printTopSignals() {
		
		'''
		// Wire(s) and Reg(s)
		wire [31 : 0]				slv_reg0;
		«FOR port : portMap.keySet»
		wire [31 : 0]				slv_reg«portMap.get(port)+1»;«ENDFOR»
		«IF dedicatedInterfaces»
		«ELSE»
		wire 						s01_axi_rden;
		wire 						s01_axi_wren;
		wire [C_S01_AXI_ADDR_WIDTH-3 : 0]				s01_axi_address;
		wire [31 : 0]				s01_axi_data_in;
		reg [31 : 0]				s01_axi_data_out;
		«ENDIF»
	    «FOR input : inputMap.keySet()»
		wire [«input.type.sizeInBits-1» : 0]				«input.getName()»_data;
		wire 						«input.getName()»_send;
		wire						«input.getName()»_rdy;
		wire						«input.getName()»_ack;
		wire [15:0]					«input.getName()»_count;
		wire 						en_«input.name»;
		wire 						done_«input.name»;
		wire [11:0]					count_«input.name»;
		wire						wren_mem_«portMap.get(input)+1»;
		wire						rden_mem_«portMap.get(input)+1»;
		wire [7:0]					address_mem_«portMap.get(input)+1»;
		wire [31:0]					data_in_mem_«portMap.get(input)+1»;
		wire [31:0]					data_out_mem_«portMap.get(input)+1»;
		wire [31:0]					data_out_«portMap.get(input)+1»;
		wire						ce_«portMap.get(input)+1»;
		«ENDFOR»
		«FOR output : outputMap.keySet()»
		wire [«output.type.sizeInBits-1» : 0]				«output.getName()»_data;
		wire 						«output.getName()»_send;
		wire						«output.getName()»_rdy;
		wire						«output.getName()»_ack;
		wire [15:0]					«output.getName()»_count;
		wire 						en_«output.name»;
		wire 						done_«output.name»;
		wire [11:0]					count_«output.name»;
		wire						rden_mem_«portMap.get(output)+1»;
		wire						wren_mem_«portMap.get(output)+1»;
		wire [7:0]					address_mem_«portMap.get(output)+1»;
		wire [31:0]					data_in_mem_«portMap.get(output)+1»;
		wire [31:0]					data_out_mem_«portMap.get(output)+1»;
		wire [31:0]					data_out_«portMap.get(output)+1»;
		wire						ce_«portMap.get(output)+1»;
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
			parameter integer C_S«getLongId(portMap.get(port)+1)»_AXI_ADDR_WIDTH	= «Math.ceil(10+Math.log10(portMap.size) / Math.log10(2)).intValue»,	// memory size 4096
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
			parameter integer C_S01_AXI_ADDR_WIDTH	= «Math.ceil(10+Math.log10(portMap.size) / Math.log10(2))»,	// memory size 4096
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
			.rdy(«input.name»_rdy),
			.ack(«input.name»_ack),
			.en(en_«input.name»),
			.rden(rden_mem_«portMap.get(input)+1»),
			.send(«input.name»_send)
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
			.send(«output.name»_send),
			.wren(wren_mem_«portMap.get(output)+1»),
			.en(en_«output.name»),
			.rdy(«output.name»_rdy),
			.ack(«output.name»_ack)
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
			«FOR input : inputMap.keySet()».«input.getName()»_data(«input.getName()»_data),
			.«input.getName()»_send(«input.getName()»_send),
			.«input.getName()»_ack(«input.getName()»_ack),
			.«input.getName()»_rdy(«input.getName()»_rdy),
			.«input.getName()»_count(«input.getName()»_count),
			«ENDFOR»
			// Multi-Dataflow Output(s)
			«FOR output : outputMap.keySet()».«output.getName()»_data(«output.getName()»_data),
			.«output.getName()»_send(«output.getName()»_send),
			.«output.getName()»_ack(«output.getName()»_ack),
			.«output.getName()»_rdy(«output.getName()»_rdy),
			.«output.getName()»_count(«output.getName()»_count),
			«ENDFOR»
			// Multi-Dataflow Clock and Reset
			.CLK(s00_axi_aclk),
			.RESET(!s00_axi_aresetn),
			// Multi-Dataflow Kernel ID
			.ID(slv_reg0[31:24])	
		);
		'''
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


	
	def printXmlComponent(Network network) {
		
		// init AXI buses ports
		initAXIlitePorts();
		initAXIfullPorts();
							
		'''
		<?xml version="1.0" encoding="UTF-8"?>
		<spirit:component xmlns:xilinx="http://www.xilinx.com" xmlns:spirit="http://www.spiritconsortium.org/XMLSchema/SPIRIT/1685-2009" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
			<spirit:vendor>user.org</spirit:vendor>
			<spirit:library>user</spirit:library>
			<spirit:name>mm_accelerator</spirit:name>
			<spirit:version>1.0</spirit:version>
			<spirit:busInterfaces>
			«printXmlAXIliteBusInterface("0","S")»
			«printXmlClockBusInterface("0","S","AXI","L")»
			«printXmlResetBusInterface("0","S","AXI","L")»
			«IF dedicatedInterfaces»
			«FOR input : network.inputs»
			«printXmlAXIfullBusInterface((portMap.get(input)+1).toString(),"S")»
			«printXmlClockBusInterface((portMap.get(input)+1).toString(),"S","AXI","L")»
			«printXmlResetBusInterface((portMap.get(input)+1).toString(),"S","AXI","L")»
			«ENDFOR»
			«FOR output : network.outputs»
			«printXmlAXIfullBusInterface((portMap.get(output)+1).toString(),"S")»
			«printXmlClockBusInterface((portMap.get(output)+1).toString(),"S","AXI","L")»
			«printXmlResetBusInterface((portMap.get(output)+1).toString(),"S","AXI","L")»
			«ENDFOR»
			«ELSE»
			«printXmlAXIfullBusInterface("1","S")»
			«printXmlClockBusInterface("1","S","AXI","L")»
			«printXmlResetBusInterface("1","S","AXI","L")»
			«ENDIF»
			</spirit:busInterfaces>
			<spirit:memoryMaps>
				«printXmlAXIMemoryMap("0","S","reg")»
				«IF dedicatedInterfaces»
				«FOR input : network.inputs»
					«printXmlAXIMemoryMap((portMap.get(input)+1).toString(),"S","mem")»
				«ENDFOR»
				«FOR output : network.outputs»
					«printXmlAXIMemoryMap((portMap.get(output)+1).toString(),"S","mem")»
				«ENDFOR»
				«ELSE»
				«printXmlAXIMemoryMap("1","S","mem")»
				«ENDIF»
			</spirit:memoryMaps>
			<spirit:model>
				<spirit:views>
					«printXmlView("xilinx_anylanguagesynthesis","Synthesis",":vivado.xilinx.com:synthesis","","xilinx_anylanguagesynthesis_view_fileset")»
					«printXmlView("xilinx_anylanguagebehavioralsimulation","Simulation",":vivado.xilinx.com:simulation","","xilinx_anylanguagebehavioralsimulation_view_fileset")»
					«printXmlView("xilinx_softwaredriver","Software Driver",":vivado.xilinx.com:sw.driver","","xilinx_softwaredriver_view_fileset")»
					«printXmlView("xilinx_xpgui","UI Layout",":vivado.xilinx.com:xgui.ui","","xilinx_xpgui_view_fileset")»
					«printXmlView("bd_tcl","Block Diagram",":vivado.xilinx.com:block.diagram","","bd_tcl_view_fileset")»
				</spirit:views>
				<spirit:ports>
					«printXmlAXIlitePorts("0","S")»
					«IF dedicatedInterfaces»
					«FOR input : network.inputs»
					«printXmlAXIfullPorts((portMap.get(input)+1).toString(),"S")»
					«ENDFOR»
					«FOR output : network.outputs»
					«printXmlAXIfullPorts((portMap.get(output)+1).toString(),"S")»
					«ENDFOR»
					«ELSE»
					«printXmlAXIfullPorts("1","S")»
					«ENDIF»
				</spirit:ports>
				<spirit:modelParameters>
					«printXmlAXIliteModelParameters("0","S")»
					«IF dedicatedInterfaces»
					«FOR input : network.inputs»
					«printXmlAXIfullModelParameters((portMap.get(input)+1).toString(),"S")»
					«ENDFOR»
					«FOR output : network.outputs»
					«printXmlAXIfullModelParameters((portMap.get(output)+1).toString(),"S")»
					«ENDFOR»
					«ELSE»
					«printXmlAXIfullModelParameters("1","S")»
					«ENDIF»
				</spirit:modelParameters>
			</spirit:model>
			<spirit:choices>
				<spirit:choice>
					<spirit:name>choice_list_6fc15197</spirit:name>
					<spirit:enumeration>32</spirit:enumeration>
				</spirit:choice>
				<spirit:choice>
					<spirit:name>choice_pairs_ce1226b1</spirit:name>
					<spirit:enumeration spirit:text="true">1</spirit:enumeration>
					<spirit:enumeration spirit:text="false">0</spirit:enumeration>
				</spirit:choice>
			</spirit:choices>
			<spirit:fileSets>
				«printXmlSynthesisFileSet(network)»
				«printXmlSimulationFileSet(network)»
				«printXmlSoftwareDriverFileSet()»
				<spirit:fileSet>
					<spirit:name>xilinx_xpgui_view_fileset</spirit:name>
					<spirit:file>
						<spirit:name>xgui/mm_accelerator.tcl</spirit:name>
						<spirit:fileType>tclSource</spirit:fileType>
						<spirit:userFileType>CHECKSUM_89f55ece</spirit:userFileType>
						<spirit:userFileType>XGUI_VERSION_2</spirit:userFileType>
					</spirit:file>
				</spirit:fileSet>
				<!--<spirit:fileSet>
					<spirit:name>bd_tcl_view_fileset</spirit:name>
					<spirit:file>
						<spirit:name>bd/bd.tcl</spirit:name>
						<spirit:fileType>tclSource</spirit:fileType>
					</spirit:file>
				</spirit:fileSet>-->
			</spirit:fileSets>
			<spirit:description>CGR Accelerator (automatically created by MDC)</spirit:description>
			<spirit:parameters>
				«printXmlAXIliteParameters("0","S")»
				«IF dedicatedInterfaces»
				«FOR input : network.inputs»
				«printXmlAXIfullParameters((portMap.get(input)+1).toString(),"S")»
				«ENDFOR»
				«FOR output : network.outputs»
				«printXmlAXIfullParameters((portMap.get(output)+1).toString(),"S")»
				«ENDFOR»
				«ELSE»
				«printXmlAXIfullParameters("1","S")»
				«ENDIF»
				<spirit:parameter>
					<spirit:name>Component_Name</spirit:name>
					<spirit:value spirit:resolve="user" spirit:id="PARAM_VALUE.Component_Name" spirit:order="1">mm_accelerator</spirit:value>
				</spirit:parameter>
			</spirit:parameters>
			<spirit:vendorExtensions>
				<xilinx:coreExtensions>
					<xilinx:supportedFamilies>
						<xilinx:family xilinx:lifeCycle="Pre-Production">zynq</xilinx:family>
					</xilinx:supportedFamilies>
					<xilinx:taxonomies>
						<xilinx:taxonomy>AXI_Peripheral</xilinx:taxonomy>
					</xilinx:taxonomies>
					<xilinx:displayName>mm_accelerator</xilinx:displayName>
					<xilinx:coreRevision>0</xilinx:coreRevision>
					<xilinx:coreCreationDateTime>2016-10-05T18:18:18Z</xilinx:coreCreationDateTime>
					<xilinx:tags>
						<xilinx:tag xilinx:name="user.org:user:mm_accelerator:1.0_ARCHIVE_LOCATION">/home/csau/PRJ/vivado/vivado2015.4/ip_repo/mm_accelerator</xilinx:tag>
					</xilinx:tags>
				</xilinx:coreExtensions>
				<xilinx:packagingInfo>
					<xilinx:xilinxVersion>2015.4</xilinx:xilinxVersion>
					<xilinx:checksum xilinx:scope="busInterfaces" xilinx:value="91cbc71b"/>
					<xilinx:checksum xilinx:scope="memoryMaps" xilinx:value="ca22a6c3"/>
					<xilinx:checksum xilinx:scope="fileGroups" xilinx:value="8ccccfc4"/>
					<xilinx:checksum xilinx:scope="ports" xilinx:value="81a8a888"/>
					<xilinx:checksum xilinx:scope="hdlParameters" xilinx:value="ec8a3998"/>
					<xilinx:checksum xilinx:scope="parameters" xilinx:value="0bc47e0b"/>
				</xilinx:packagingInfo>
			</spirit:vendorExtensions>
		</spirit:component>
		'''
	}

	
	def printXmlAXIfullParameters(String id, String type) {
		
		var String longId = id;
		if(Integer.parseInt(id)<10) {
			longId = "0" + id;
		}
		
		'''
		<spirit:parameter>
			<spirit:name>C_«type»«longId»_AXI_ID_WIDTH</spirit:name>
			<spirit:displayName>C «type»«longId» AXI ID WIDTH</spirit:displayName>
			<spirit:description>Width of ID for for write address, write data, read address and read data</spirit:description>
			<spirit:value spirit:format="long" spirit:resolve="user" spirit:id="PARAM_VALUE.C_«type»«longId»_AXI_ID_WIDTH" spirit:order="3" spirit:minimum="0" spirit:maximum="32" spirit:rangeType="long">1</spirit:value>
		</spirit:parameter>
		<spirit:parameter>
			<spirit:name>C_«type»«longId»_AXI_DATA_WIDTH</spirit:name>
			<spirit:displayName>C «type»«longId» AXI DATA WIDTH</spirit:displayName>
			<spirit:description>Width of S_AXI data bus</spirit:description>
			<spirit:value spirit:format="long" spirit:resolve="user" spirit:id="PARAM_VALUE.C_«type»«longId»_AXI_DATA_WIDTH" spirit:choiceRef="choice_list_6fc15197" spirit:order="4">32</spirit:value>
			<spirit:vendorExtensions>
				<xilinx:parameterInfo>
					<xilinx:enablement>
						<xilinx:isEnabled xilinx:id="PARAM_ENABLEMENT.C_«type»«longId»_AXI_DATA_WIDTH">false</xilinx:isEnabled>
					</xilinx:enablement>
				</xilinx:parameterInfo>
			</spirit:vendorExtensions>
		</spirit:parameter>
		<spirit:parameter>
			<spirit:name>C_«type»«longId»_AXI_ADDR_WIDTH</spirit:name>
			<spirit:displayName>C «type»«longId» AXI ADDR WIDTH</spirit:displayName>
			<spirit:description>Width of S_AXI address bus</spirit:description>
			<spirit:value spirit:format="long" spirit:resolve="user" spirit:id="PARAM_VALUE.C_«type»«longId»_AXI_ADDR_WIDTH" spirit:order="5" spirit:rangeType="long">«Math.ceil(10+Math.log10(portMap.size) / Math.log10(2)).intValue»</spirit:value>
			<spirit:vendorExtensions>
				<xilinx:parameterInfo>
					<xilinx:enablement>
						<xilinx:isEnabled xilinx:id="PARAM_ENABLEMENT.C_«type»«longId»_AXI_ADDR_WIDTH">false</xilinx:isEnabled>
					</xilinx:enablement>
				</xilinx:parameterInfo>
			</spirit:vendorExtensions>
		</spirit:parameter>
		<spirit:parameter>
			<spirit:name>C_«type»«longId»_AXI_AWUSER_WIDTH</spirit:name>
			<spirit:displayName>C «type»«longId» AXI AWUSER WIDTH</spirit:displayName>
			<spirit:description>Width of optional user defined signal in write address channel</spirit:description>
			<spirit:value spirit:format="long" spirit:resolve="user" spirit:id="PARAM_VALUE.C_«type»«longId»_AXI_AWUSER_WIDTH" spirit:order="6" spirit:minimum="0" spirit:maximum="1024" spirit:rangeType="long">0</spirit:value>
		</spirit:parameter>
		<spirit:parameter>
			<spirit:name>C_«type»«longId»_AXI_ARUSER_WIDTH</spirit:name>
			<spirit:displayName>C «type»«longId» AXI ARUSER WIDTH</spirit:displayName>
			<spirit:description>Width of optional user defined signal in read address channel</spirit:description>
			<spirit:value spirit:format="long" spirit:resolve="user" spirit:id="PARAM_VALUE.C_«type»«longId»_AXI_ARUSER_WIDTH" spirit:order="7" spirit:minimum="0" spirit:maximum="1024" spirit:rangeType="long">0</spirit:value>
		</spirit:parameter>
		<spirit:parameter>
			<spirit:name>C_«type»«longId»_AXI_WUSER_WIDTH</spirit:name>
			<spirit:displayName>C «type»«longId» AXI WUSER WIDTH</spirit:displayName>
			<spirit:description>Width of optional user defined signal in write data channel</spirit:description>
			<spirit:value spirit:format="long" spirit:resolve="user" spirit:id="PARAM_VALUE.C_«type»«longId»_AXI_WUSER_WIDTH" spirit:order="8" spirit:minimum="0" spirit:maximum="1024" spirit:rangeType="long">0</spirit:value>
		</spirit:parameter>
		<spirit:parameter>
			<spirit:name>C_«type»«longId»_AXI_RUSER_WIDTH</spirit:name>
			<spirit:displayName>C «type»«longId» AXI RUSER WIDTH</spirit:displayName>
			<spirit:description>Width of optional user defined signal in read data channel</spirit:description>
			<spirit:value spirit:format="long" spirit:resolve="user" spirit:id="PARAM_VALUE.C_«type»«longId»_AXI_RUSER_WIDTH" spirit:order="9" spirit:minimum="0" spirit:maximum="1024" spirit:rangeType="long">0</spirit:value>
		</spirit:parameter>
		<spirit:parameter>
			<spirit:name>C_«type»«longId»_AXI_BUSER_WIDTH</spirit:name>
			<spirit:displayName>C «type»«longId» AXI BUSER WIDTH</spirit:displayName>
			<spirit:description>Width of optional user defined signal in write response channel</spirit:description>
			<spirit:value spirit:format="long" spirit:resolve="user" spirit:id="PARAM_VALUE.C_«type»«longId»_AXI_BUSER_WIDTH" spirit:order="10" spirit:minimum="0" spirit:maximum="1024" spirit:rangeType="long">0</spirit:value>
		</spirit:parameter>
		<spirit:parameter>
			<spirit:name>C_«type»«longId»_AXI_BASEADDR</spirit:name>
			<spirit:displayName>C «type»«longId» AXI BASEADDR</spirit:displayName>
			<spirit:value spirit:format="bitString" spirit:resolve="user" spirit:id="PARAM_VALUE.C_«type»«longId»_AXI_BASEADDR" spirit:order="11" spirit:bitStringLength="32">0xFFFFFFFF</spirit:value>
			<spirit:vendorExtensions>
				<xilinx:parameterInfo>
					<xilinx:enablement>
						<xilinx:isEnabled xilinx:id="PARAM_ENABLEMENT.C_«type»«longId»_AXI_BASEADDR">false</xilinx:isEnabled>
					</xilinx:enablement>
				</xilinx:parameterInfo>
			</spirit:vendorExtensions>
		</spirit:parameter>
		<spirit:parameter>
			<spirit:name>C_«type»«longId»_AXI_HIGHADDR</spirit:name>
			<spirit:displayName>C «type»«longId» AXI HIGHADDR</spirit:displayName>
			<spirit:value spirit:format="bitString" spirit:resolve="user" spirit:id="PARAM_VALUE.C_«type»«longId»_AXI_HIGHADDR" spirit:order="12" spirit:bitStringLength="32">0x00000000</spirit:value>
			<spirit:vendorExtensions>
				<xilinx:parameterInfo>
					<xilinx:enablement>
						<xilinx:isEnabled xilinx:id="PARAM_ENABLEMENT.C_«type»«longId»_AXI_HIGHADDR">false</xilinx:isEnabled>
					</xilinx:enablement>
				</xilinx:parameterInfo>
			</spirit:vendorExtensions>
		</spirit:parameter>
		'''
	}
	
	def printXmlAXIliteParameters(String id, String type) {
		
		var String longId = id;
		if(Integer.parseInt(id)<10) {
			longId = "0" + id;
		}
		
		'''
		<spirit:parameter>
			<spirit:name>C_«type»«longId»_AXI_DATA_WIDTH</spirit:name>
			<spirit:displayName>C «type»«longId» AXI DATA WIDTH</spirit:displayName>
			<spirit:description>Width of S_AXI data bus</spirit:description>
			<spirit:value spirit:format="long" spirit:resolve="user" spirit:id="PARAM_VALUE.C_«type»«longId»_AXI_DATA_WIDTH" spirit:choiceRef="choice_list_6fc15197" spirit:order="5">32</spirit:value>
			<spirit:vendorExtensions>
				<xilinx:parameterInfo>
					<xilinx:enablement>
						<xilinx:isEnabled xilinx:id="PARAM_ENABLEMENT.C_«type»«longId»_AXI_DATA_WIDTH">false</xilinx:isEnabled>
					</xilinx:enablement>
				</xilinx:parameterInfo>
			</spirit:vendorExtensions>
		</spirit:parameter>
		<spirit:parameter>
			<spirit:name>C_«type»«longId»_AXI_ADDR_WIDTH</spirit:name>
			<spirit:displayName>C «type»«longId» AXI ADDR WIDTH</spirit:displayName>
			<spirit:description>Width of S_AXI address bus</spirit:description>
			<spirit:value spirit:format="long" spirit:resolve="user" spirit:id="PARAM_VALUE.C_«type»«longId»_AXI_ADDR_WIDTH" spirit:order="6" spirit:rangeType="long">4</spirit:value>
			<spirit:vendorExtensions>
				<xilinx:parameterInfo>
					<xilinx:enablement>
						<xilinx:isEnabled xilinx:id="PARAM_ENABLEMENT.C_«type»«longId»_AXI_ADDR_WIDTH">false</xilinx:isEnabled>
					</xilinx:enablement>
				</xilinx:parameterInfo>
			</spirit:vendorExtensions>
		</spirit:parameter>
		<spirit:parameter>
			<spirit:name>C_«type»«longId»_AXI_BASEADDR</spirit:name>
			<spirit:displayName>C «type»«longId» AXI BASEADDR</spirit:displayName>
			<spirit:value spirit:format="bitString" spirit:resolve="user" spirit:id="PARAM_VALUE.C_«type»«longId»_AXI_BASEADDR" spirit:order="7" spirit:bitStringLength="32">0xFFFFFFFF</spirit:value>
			<spirit:vendorExtensions>
				<xilinx:parameterInfo>
					<xilinx:enablement>
						<xilinx:isEnabled xilinx:id="PARAM_ENABLEMENT.C_«type»«longId»_AXI_BASEADDR">false</xilinx:isEnabled>
					</xilinx:enablement>
				</xilinx:parameterInfo>
			</spirit:vendorExtensions>
		</spirit:parameter>
		<spirit:parameter>
			<spirit:name>C_«type»«longId»_AXI_HIGHADDR</spirit:name>
			<spirit:displayName>C «type»«longId» AXI HIGHADDR</spirit:displayName>
			<spirit:value spirit:format="bitString" spirit:resolve="user" spirit:id="PARAM_VALUE.C_«type»«longId»_AXI_HIGHADDR" spirit:order="8" spirit:bitStringLength="32">0x00000000</spirit:value>
			<spirit:vendorExtensions>
				<xilinx:parameterInfo>
					<xilinx:enablement>
						<xilinx:isEnabled xilinx:id="PARAM_ENABLEMENT.C_«type»«longId»_AXI_HIGHADDR">false</xilinx:isEnabled>
					</xilinx:enablement>
				</xilinx:parameterInfo>
			</spirit:vendorExtensions>
		</spirit:parameter>
		'''
	}
	
	def printXmlSoftwareDriverFileSet() {
		'''
		<spirit:fileSet>
			<spirit:name>xilinx_softwaredriver_view_fileset</spirit:name>
			<spirit:file>
				<spirit:name>drivers/mm_accelerator/data/mm_accelerator.mdd</spirit:name>
				<spirit:userFileType>mdd</spirit:userFileType>
				<spirit:userFileType>driver_mdd</spirit:userFileType>
			</spirit:file>
			 <!--<spirit:file>
				<spirit:name>drivers/mm_accelerator/data/mm_accelerator.tcl</spirit:name>
				<spirit:fileType>tclSource</spirit:fileType>
				<spirit:userFileType>driver_tcl</spirit:userFileType>
			</spirit:file>
			<spirit:file>
				<spirit:name>drivers/mm_accelerator/src/Makefile</spirit:name>
				<spirit:userFileType>driver_src</spirit:userFileType>
			</spirit:file>-->
			<spirit:file>
				<spirit:name>drivers/mm_accelerator/src/mm_accelerator_h.h</spirit:name>
				<spirit:fileType>cSource</spirit:fileType>
				<spirit:userFileType>driver_src</spirit:userFileType>
			</spirit:file>
			<spirit:file>
				<spirit:name>drivers/mm_accelerator/src/mm_accelerator_h.c</spirit:name>
				<spirit:fileType>cSource</spirit:fileType>
				<spirit:userFileType>driver_src</spirit:userFileType>
			</spirit:file>
		</spirit:fileSet>
	    '''
	}
	
	def printXmlSynthesisFileSet(Network network) {
		'''
		<spirit:fileSet>
			<spirit:name>xilinx_anylanguagesynthesis_view_fileset</spirit:name>
			<spirit:file>
				<spirit:name>hdl/config_regs.v</spirit:name>
				<spirit:fileType>verilogSource</spirit:fileType>
			</spirit:file>
			<spirit:file>
				<spirit:name>hdl/axi_full_ipif.v</spirit:name>
				<spirit:fileType>verilogSource</spirit:fileType>
			</spirit:file>
			<spirit:file>
				<spirit:name>hdl/local_memory.v</spirit:name>
				<spirit:fileType>verilogSource</spirit:fileType>
			</spirit:file>
			<spirit:file>
				<spirit:name>hdl/front_end.v</spirit:name>
				<spirit:fileType>verilogSource</spirit:fileType>
			</spirit:file>
			<spirit:file>
				<spirit:name>hdl/counter.v</spirit:name>
				<spirit:fileType>verilogSource</spirit:fileType>
			</spirit:file>
			<spirit:file>
				<spirit:name>hdl/configurator.v</spirit:name>
				<spirit:fileType>verilogSource</spirit:fileType>
			</spirit:file>
			«FOR actor : network.children.filter(typeof(Actor))»
			«IF !actor.hasAttribute("sbox")»
			<spirit:file>
				<spirit:name>hdl/«actor.simpleName».v</spirit:name>
				<spirit:fileType>verilogSource</spirit:fileType>
			</spirit:file>
			«ENDIF»
			«ENDFOR»
			<spirit:file>
				<spirit:name>hdl/mdc.vhd</spirit:name>
				<spirit:fileType>vhdlSource</spirit:fileType>
				<spirit:logicalName>SystemMdc</spirit:logicalName>
			</spirit:file>
			<spirit:file>
				<spirit:name>hdl/sbtypes.vhdl</spirit:name>
				<spirit:fileType>vhdlSource</spirit:fileType>
				<spirit:logicalName>SystemBuilder</spirit:logicalName>
			</spirit:file>
			<spirit:file>
				<spirit:name>hdl/sbfifo.vhdl</spirit:name>
				<spirit:fileType>vhdlSource</spirit:fileType>
				<spirit:logicalName>SystemBuilder</spirit:logicalName>
			</spirit:file>
			<spirit:file>
				<spirit:name>hdl/sbfifo_behavioral.vhdl</spirit:name>
				<spirit:fileType>vhdlSource</spirit:fileType>
				<spirit:logicalName>SystemBuilder</spirit:logicalName>
			</spirit:file>
			<spirit:file>
				<spirit:name>hdl/multi_dataflow.vhd</spirit:name>
				<spirit:fileType>vhdlSource</spirit:fileType>
			</spirit:file>
			<spirit:file>
				<spirit:name>hdl/back_end.v</spirit:name>
				<spirit:fileType>verilogSource</spirit:fileType>
			</spirit:file>
			<spirit:file>
				<spirit:name>hdl/mm_accelerator.v</spirit:name>
				<spirit:fileType>verilogSource</spirit:fileType>
			</spirit:file>
		</spirit:fileSet>
		'''
	}
	
	
	def printXmlSimulationFileSet(Network network) {
		'''
		<spirit:fileSet>
			<spirit:name>xilinx_anylanguagebehavioralsimulation_view_fileset</spirit:name>
			<spirit:file>
				<spirit:name>hdl/config_regs.v</spirit:name>
				<spirit:fileType>verilogSource</spirit:fileType>
			</spirit:file>
			<spirit:file>
				<spirit:name>hdl/axi_full_ipif.v</spirit:name>
				<spirit:fileType>verilogSource</spirit:fileType>
			</spirit:file>
			<spirit:file>
				<spirit:name>hdl/local_memory.v</spirit:name>
				<spirit:fileType>verilogSource</spirit:fileType>
			</spirit:file>
			<spirit:file>
				<spirit:name>hdl/front_end.v</spirit:name>
				<spirit:fileType>verilogSource</spirit:fileType>
			</spirit:file>
			<spirit:file>
				<spirit:name>hdl/counter.v</spirit:name>
				<spirit:fileType>verilogSource</spirit:fileType>
			</spirit:file>
			<spirit:file>
				<spirit:name>hdl/configurator.v</spirit:name>
				<spirit:fileType>verilogSource</spirit:fileType>
			</spirit:file>
			«FOR actor : network.children.filter(typeof(Actor))»
			«IF !actor.hasAttribute("sbox")»
			<spirit:file>
				<spirit:name>hdl/«actor.simpleName».v</spirit:name>
				<spirit:fileType>verilogSource</spirit:fileType>
			</spirit:file>
			«ENDIF»
			«ENDFOR»
			<spirit:file>
				<spirit:name>hdl/mdc.vhd</spirit:name>
				<spirit:fileType>vhdlSource</spirit:fileType>
				<spirit:logicalName>SystemMdc</spirit:logicalName>
			</spirit:file>
			<spirit:file>
				<spirit:name>hdl/sbtypes.vhdl</spirit:name>
				<spirit:fileType>vhdlSource</spirit:fileType>
				<spirit:logicalName>SystemBuilder</spirit:logicalName>
			</spirit:file>
			<spirit:file>
				<spirit:name>hdl/sbfifo.vhdl</spirit:name>
				<spirit:fileType>vhdlSource</spirit:fileType>
				<spirit:logicalName>SystemBuilder</spirit:logicalName>
			</spirit:file>
			<spirit:file>
				<spirit:name>hdl/sbfifo_behavioral.vhdl</spirit:name>
				<spirit:fileType>vhdlSource</spirit:fileType>
				<spirit:logicalName>SystemBuilder</spirit:logicalName>
			</spirit:file>
			<spirit:file>
				<spirit:name>hdl/multi_dataflow.vhd</spirit:name>
				<spirit:fileType>vhdlSource</spirit:fileType>
			</spirit:file>
			<spirit:file>
				<spirit:name>hdl/back_end.v</spirit:name>
				<spirit:fileType>verilogSource</spirit:fileType>
			</spirit:file>
			<spirit:file>
				<spirit:name>hdl/mm_accelerator.v</spirit:name>
				<spirit:fileType>verilogSource</spirit:fileType>
			</spirit:file>
		</spirit:fileSet>
		'''
	}
	
	def printXmlAXIliteModelParameters(String id, String type) {
		
		var String longId = id;
		if(Integer.parseInt(id)<10) {
			longId = "0" + id;
		}
		
		'''
		<spirit:modelParameter xsi:type="spirit:nameValueTypeType" spirit:dataType="integer">
			<spirit:name>C_«type»«longId»_AXI_DATA_WIDTH</spirit:name>
			<spirit:displayName>C «type»«longId» AXI DATA WIDTH</spirit:displayName>
			<spirit:description>Width of S_AXI data bus</spirit:description>
			<spirit:value spirit:format="long" spirit:resolve="generated" spirit:id="MODELPARAM_VALUE.C_«type»«longId»_AXI_DATA_WIDTH" spirit:order="5" spirit:rangeType="long">32</spirit:value>
		</spirit:modelParameter>
		<spirit:modelParameter spirit:dataType="integer">
			<spirit:name>C_«type»«longId»_AXI_ADDR_WIDTH</spirit:name>
			<spirit:displayName>C «type»«longId» AXI ADDR WIDTH</spirit:displayName>
			<spirit:description>Width of S_AXI address bus</spirit:description>
			<spirit:value spirit:format="long" spirit:resolve="generated" spirit:id="MODELPARAM_VALUE.C_«type»«longId»_AXI_ADDR_WIDTH" spirit:order="6" spirit:rangeType="long">4</spirit:value>
		</spirit:modelParameter>
      '''
	}
	
	def printXmlAXIfullModelParameters(String id, String type) {
		
		var String longId = id;
		if(Integer.parseInt(id)<10) {
			longId = "0" + id;
		}
		
		'''
		<spirit:modelParameter xsi:type="spirit:nameValueTypeType" spirit:dataType="integer">
			<spirit:name>C_«type»«longId»_AXI_ID_WIDTH</spirit:name>
			<spirit:displayName>C «type»«longId» AXI ID WIDTH</spirit:displayName>
			<spirit:description>Width of ID for for write address, write data, read address and read data</spirit:description>
			<spirit:value spirit:format="long" spirit:resolve="dependent" spirit:id="MODELPARAM_VALUE.C_«type»«longId»_AXI_ID_WIDTH" spirit:dependency="((spirit:decode(id(&apos;PARAM_VALUE.C_«type»«longId»_AXI_ID_WIDTH&apos;)) &lt;= 0 ) + (spirit:decode(id(&apos;PARAM_VALUE.C_«type»«longId»_AXI_ID_WIDTH&apos;))))" spirit:order="3" spirit:minimum="0" spirit:maximum="32" spirit:rangeType="long">1</spirit:value>
		</spirit:modelParameter>
		<spirit:modelParameter spirit:dataType="integer">
			<spirit:name>C_«type»«longId»_AXI_DATA_WIDTH</spirit:name>
			<spirit:displayName>C «type»«longId» AXI DATA WIDTH</spirit:displayName>
			<spirit:description>Width of S_AXI data bus</spirit:description>
			<spirit:value spirit:format="long" spirit:resolve="generated" spirit:id="MODELPARAM_VALUE.C_«type»«longId»_AXI_DATA_WIDTH" spirit:order="4" spirit:rangeType="long">32</spirit:value>
		</spirit:modelParameter>
		<spirit:modelParameter spirit:dataType="integer">
			<spirit:name>C_«type»«longId»_AXI_ADDR_WIDTH</spirit:name>
			<spirit:displayName>C «type»«longId» AXI ADDR WIDTH</spirit:displayName>
			<spirit:description>Width of S_AXI address bus</spirit:description>
			<spirit:value spirit:format="long" spirit:resolve="generated" spirit:id="MODELPARAM_VALUE.C_«type»«longId»_AXI_ADDR_WIDTH" spirit:order="5" spirit:rangeType="long">«Math.ceil(10+Math.log10(portMap.size) / Math.log10(2)).intValue»</spirit:value>
		</spirit:modelParameter>
		<spirit:modelParameter spirit:dataType="integer">
			<spirit:name>C_«type»«longId»_AXI_AWUSER_WIDTH</spirit:name>
			<spirit:displayName>C «type»«longId» AXI AWUSER WIDTH</spirit:displayName>
			<spirit:description>Width of optional user defined signal in write address channel</spirit:description>
			<spirit:value spirit:format="long" spirit:resolve="dependent" spirit:id="MODELPARAM_VALUE.C_«type»«longId»_AXI_AWUSER_WIDTH" spirit:dependency="((spirit:decode(id(&apos;PARAM_VALUE.C_«type»«longId»_AXI_AWUSER_WIDTH&apos;)) &lt;= 0 ) + (spirit:decode(id(&apos;PARAM_VALUE.C_«type»«longId»_AXI_AWUSER_WIDTH&apos;))))" spirit:order="6" spirit:minimum="0" spirit:maximum="1024" spirit:rangeType="long">1</spirit:value>
		</spirit:modelParameter>
		<spirit:modelParameter spirit:dataType="integer">
			<spirit:name>C_«type»«longId»_AXI_ARUSER_WIDTH</spirit:name>
			<spirit:displayName>C «type»«longId» AXI ARUSER WIDTH</spirit:displayName>
			<spirit:description>Width of optional user defined signal in read address channel</spirit:description>
			<spirit:value spirit:format="long" spirit:resolve="dependent" spirit:id="MODELPARAM_VALUE.C_«type»«longId»_AXI_ARUSER_WIDTH" spirit:dependency="((spirit:decode(id(&apos;PARAM_VALUE.C_«type»«longId»_AXI_ARUSER_WIDTH&apos;)) &lt;= 0 ) + (spirit:decode(id(&apos;PARAM_VALUE.C_«type»«longId»_AXI_ARUSER_WIDTH&apos;))))" spirit:order="7" spirit:minimum="0" spirit:maximum="1024" spirit:rangeType="long">1</spirit:value>
		</spirit:modelParameter>
		<spirit:modelParameter spirit:dataType="integer">
			<spirit:name>C_«type»«longId»_AXI_WUSER_WIDTH</spirit:name>
			<spirit:displayName>C «type»«longId» AXI WUSER WIDTH</spirit:displayName>
			<spirit:description>Width of optional user defined signal in write data channel</spirit:description>
			<spirit:value spirit:format="long" spirit:resolve="dependent" spirit:id="MODELPARAM_VALUE.C_«type»«longId»_AXI_WUSER_WIDTH" spirit:dependency="((spirit:decode(id(&apos;PARAM_VALUE.C_«type»«longId»_AXI_WUSER_WIDTH&apos;)) &lt;= 0 ) + (spirit:decode(id(&apos;PARAM_VALUE.C_«type»«longId»_AXI_WUSER_WIDTH&apos;))))" spirit:order="8" spirit:minimum="0" spirit:maximum="1024" spirit:rangeType="long">1</spirit:value>
		</spirit:modelParameter>
		<spirit:modelParameter spirit:dataType="integer">
			<spirit:name>C_«type»«longId»_AXI_RUSER_WIDTH</spirit:name>
			<spirit:displayName>C «type»«longId» AXI RUSER WIDTH</spirit:displayName>
			<spirit:description>Width of optional user defined signal in read data channel</spirit:description>
			<spirit:value spirit:format="long" spirit:resolve="dependent" spirit:id="MODELPARAM_VALUE.C_«type»«longId»_AXI_RUSER_WIDTH" spirit:dependency="((spirit:decode(id(&apos;PARAM_VALUE.C_«type»«longId»_AXI_RUSER_WIDTH&apos;)) &lt;= 0 ) + (spirit:decode(id(&apos;PARAM_VALUE.C_«type»«longId»_AXI_RUSER_WIDTH&apos;))))" spirit:order="9" spirit:minimum="0" spirit:maximum="1024" spirit:rangeType="long">1</spirit:value>
		</spirit:modelParameter>
		<spirit:modelParameter spirit:dataType="integer">
			<spirit:name>C_«type»«longId»_AXI_BUSER_WIDTH</spirit:name>
			<spirit:displayName>C «type»«longId» AXI BUSER WIDTH</spirit:displayName>
			<spirit:description>Width of optional user defined signal in write response channel</spirit:description>
			<spirit:value spirit:format="long" spirit:resolve="dependent" spirit:id="MODELPARAM_VALUE.C_«type»«longId»_AXI_BUSER_WIDTH" spirit:dependency="((spirit:decode(id(&apos;PARAM_VALUE.C_«type»«longId»_AXI_BUSER_WIDTH&apos;)) &lt;= 0 ) + (spirit:decode(id(&apos;PARAM_VALUE.C_«type»«longId»_AXI_BUSER_WIDTH&apos;))))" spirit:order="10" spirit:minimum="0" spirit:maximum="1024" spirit:rangeType="long">1</spirit:value>
		</spirit:modelParameter>
      	'''
	}
	
	def printXmlAXIlitePorts(String id, String type) {
		
		var String longId = id;
		if(Integer.parseInt(id)<10) {
			longId = "0" + id;
		}
		
		var boolean reverseDir = type=="M";
		
		'''
		<spirit:port>
			<spirit:name>«type.toLowerCase()»«longId»_axi_aclk</spirit:name>
			<spirit:wire>
				<spirit:direction>in</spirit:direction>
				<spirit:wireTypeDefs>
					<spirit:wireTypeDef>
						<spirit:typeName>wire</spirit:typeName>
						<spirit:viewNameRef>xilinx_anylanguagesynthesis</spirit:viewNameRef>
						<spirit:viewNameRef>xilinx_anylanguagebehavioralsimulation</spirit:viewNameRef>
					</spirit:wireTypeDef>
				</spirit:wireTypeDefs>
			</spirit:wire>
		</spirit:port>
		<spirit:port>
			<spirit:name>«type.toLowerCase()»«longId»_axi_aresetn</spirit:name>
			<spirit:wire>
				<spirit:direction>in</spirit:direction>
				<spirit:wireTypeDefs>
					<spirit:wireTypeDef>
						<spirit:typeName>wire</spirit:typeName>
						<spirit:viewNameRef>xilinx_anylanguagesynthesis</spirit:viewNameRef>
						<spirit:viewNameRef>xilinx_anylanguagebehavioralsimulation</spirit:viewNameRef>
					</spirit:wireTypeDef>
				</spirit:wireTypeDefs>
			</spirit:wire>
		</spirit:port>
		«FOR port : AXIlitePorts.keySet»
		<spirit:port>
			<spirit:name>«type.toLowerCase()»«longId»_axi_«port.toLowerCase()»</spirit:name>
			<spirit:wire>
			<spirit:direction>«IF reverseDir»«getReverseDirection(AXIlitePorts.get(port))»«ELSE»«getDirection(AXIlitePorts.get(port))»«ENDIF»</spirit:direction>
				«IF AXIlitePorts.get(port).contains("bus")»<spirit:vector>
					<spirit:left spirit:format="long"«IF hasParameter(AXIlitePorts.get(port))» spirit:resolve="dependent" spirit:dependency="(spirit:decode(id(&apos;MODELPARAM_VALUE.C_«type»«longId»_AXI_«getParameter(AXIlitePorts.get(port))»&apos;)) - 1)"«ENDIF»>«getDefaultValue(AXIlitePorts.get(port))-1»</spirit:left>
					<spirit:right spirit:format="long">0</spirit:right>
				</spirit:vector>«ENDIF»
				<spirit:wireTypeDefs>
					<spirit:wireTypeDef>
						<spirit:typeName>reg</spirit:typeName>
						<spirit:viewNameRef>xilinx_anylanguagesynthesis</spirit:viewNameRef>
						<spirit:viewNameRef>xilinx_anylanguagebehavioralsimulation</spirit:viewNameRef>
					</spirit:wireTypeDef>
				</spirit:wireTypeDefs>
			</spirit:wire>
		</spirit:port>
		«ENDFOR»
		'''
	}
	
	def printXmlAXIfullPorts(String id, String type) {
		
		var String longId = id;
		if(Integer.parseInt(id)<10) {
			longId = "0" + id;
		}
		
		var boolean reverseDir = type=="M";
		
		'''
		<spirit:port>
			<spirit:name>«type.toLowerCase()»«longId»_axi_aclk</spirit:name>
			<spirit:wire>
				<spirit:direction>in</spirit:direction>
				<spirit:wireTypeDefs>
					<spirit:wireTypeDef>
						<spirit:typeName>wire</spirit:typeName>
						<spirit:viewNameRef>xilinx_anylanguagesynthesis</spirit:viewNameRef>
						<spirit:viewNameRef>xilinx_anylanguagebehavioralsimulation</spirit:viewNameRef>
					</spirit:wireTypeDef>
				</spirit:wireTypeDefs>
			</spirit:wire>
		</spirit:port>
		<spirit:port>
			<spirit:name>«type.toLowerCase()»«longId»_axi_aresetn</spirit:name>
			<spirit:wire>
				<spirit:direction>in</spirit:direction>
				<spirit:wireTypeDefs>
					<spirit:wireTypeDef>
						<spirit:typeName>wire</spirit:typeName>
						<spirit:viewNameRef>xilinx_anylanguagesynthesis</spirit:viewNameRef>
						<spirit:viewNameRef>xilinx_anylanguagebehavioralsimulation</spirit:viewNameRef>
					</spirit:wireTypeDef>
				</spirit:wireTypeDefs>
			</spirit:wire>
		</spirit:port>
		«FOR port : AXIfullPorts.keySet»
		<spirit:port>
			<spirit:name>«type.toLowerCase()»«longId»_axi_«port.toLowerCase()»</spirit:name>
			<spirit:wire>
			<spirit:direction>«IF reverseDir»«getReverseDirection(AXIfullPorts.get(port))»«ELSE»«getDirection(AXIfullPorts.get(port))»«ENDIF»</spirit:direction>
				«IF AXIfullPorts.get(port).contains("bus")»<spirit:vector>
					<spirit:left spirit:format="long"«IF hasParameter(AXIfullPorts.get(port))» spirit:resolve="dependent" spirit:dependency="(spirit:decode(id(&apos;MODELPARAM_VALUE.C_«type»«longId»_AXI_«getParameter(AXIfullPorts.get(port))»&apos;)) - 1)"«ENDIF»>«getDefaultValue(AXIfullPorts.get(port))-1»</spirit:left>
					<spirit:right spirit:format="long">0</spirit:right>
				</spirit:vector>«ENDIF»
				<spirit:wireTypeDefs>
					<spirit:wireTypeDef>
						<spirit:typeName>reg</spirit:typeName>
						<spirit:viewNameRef>xilinx_anylanguagesynthesis</spirit:viewNameRef>
						<spirit:viewNameRef>xilinx_anylanguagebehavioralsimulation</spirit:viewNameRef>
					</spirit:wireTypeDef>
				</spirit:wireTypeDefs>
			</spirit:wire>
		</spirit:port>
		«ENDFOR»
		'''
	}
	
	
	def printXmlView(String name, String display_name, String id, String language, String fileSetRef) {
		'''
		<spirit:view>
			<spirit:name>«name»</spirit:name>
			<spirit:displayName>«display_name»</spirit:displayName>
			<spirit:envIdentifier>«id»</spirit:envIdentifier>
			«IF !language.equals("")»<spirit:language>«language»</spirit:language>«ENDIF»
			<spirit:modelName>mm_accelerator</spirit:modelName>
			<spirit:fileSetRef>
				<spirit:localName>«fileSetRef»</spirit:localName>
			</spirit:fileSetRef>
		</spirit:view>
		'''
	}
	
	def printXmlAXIMemoryMap(String id, String type, String memType) {
		
		var String longId = id;
		if(Integer.parseInt(id)<10) {
			longId = "0" + id;
		}
		
		var String memTypeLong = "";
		if(memType.equals("reg")) {
			memTypeLong = "register";
		} else {
			memTypeLong = "memory";
		}
		
		'''
		<spirit:memoryMap>
			<spirit:name>«type»«longId»_AXI</spirit:name>
			<spirit:addressBlock>
				<spirit:name>«type»«longId»_AXI_«memType»</spirit:name>
				<spirit:baseAddress spirit:format="long" spirit:resolve="user">0</spirit:baseAddress>
				<spirit:range spirit:format="long">4096</spirit:range>
				<spirit:width spirit:format="long">32</spirit:width>
				<spirit:usage>«memTypeLong»</spirit:usage>
				<spirit:parameters>
					<spirit:parameter>
						<spirit:name>OFFSET_BASE_PARAM</spirit:name>
						<spirit:value spirit:id="ADDRBLOCKPARAM_VALUE.«type»«longId»_AXI.«type»«longId»_AXI_«memType.toUpperCase».OFFSET_BASE_PARAM" spirit:dependency="ADDRBLOCKPARAM_VALUE.«type»«longId»_AXI_«memType».OFFSET_BASE_PARAM">0</spirit:value>
					</spirit:parameter>
					<spirit:parameter>
						<spirit:name>OFFSET_HIGH_PARAM</spirit:name>
						<spirit:value spirit:id="ADDRBLOCKPARAM_VALUE.«type»«longId»_AXI.«type»«longId»_AXI_«memType.toUpperCase».OFFSET_HIGH_PARAM" spirit:dependency="ADDRBLOCKPARAM_VALUE.«type»«longId»_AXI_«memType».OFFSET_HIGH_PARAM">0</spirit:value>
					</spirit:parameter>
				</spirit:parameters>
			</spirit:addressBlock>
		</spirit:memoryMap>
		'''
	}
	
	def printXmlClockBusInterface(String id, String type, String bus, String polarity) {
		
		var String longId = id;
		if(Integer.parseInt(id)<10) {
			longId = "0" + id;
		}
		
		var String longPolarity = "";
		if(polarity.equals("L")) {
			longPolarity = "n";
		}
		
		'''
		<spirit:busInterface>
			<spirit:name>«type»«longId»_«bus»_CLK</spirit:name>
			<spirit:busType spirit:vendor="xilinx.com" spirit:library="signal" spirit:name="clock" spirit:version="1.0"/>
			<spirit:abstractionType spirit:vendor="xilinx.com" spirit:library="signal" spirit:name="clock_rtl" spirit:version="1.0"/>
			<spirit:slave/>
			<spirit:portMaps>
				«printXmlPortMap("CLK",type.toLowerCase+longId+"_"+bus.toLowerCase()+"_aclk")»
			</spirit:portMaps>
			<spirit:parameters>
				<spirit:parameter>
					<spirit:name>ASSOCIATED_BUSIF</spirit:name>
					<spirit:value spirit:id="BUSIFPARAM_VALUE.«type»«longId»_«bus»_CLK.ASSOCIATED_BUSIF">«type»«longId»_«bus»</spirit:value>
				</spirit:parameter>
				<spirit:parameter>
					<spirit:name>ASSOCIATED_RESET</spirit:name>
					<spirit:value spirit:id="BUSIFPARAM_VALUE.«type»«longId»_«bus»_CLK.ASSOCIATED_RESET">«type.toLowerCase()»«longId»_«bus.toLowerCase()»_areset«longPolarity»</spirit:value>
				</spirit:parameter>
			</spirit:parameters>
		</spirit:busInterface>
		'''
	}
	
	def printXmlResetBusInterface(String id, String type, String bus, String polarity) {
		
		var String longId = id;
		if(Integer.parseInt(id)<10) {
			longId = "0" + id;
		}
		
		var String longPolarity = "";
		if(polarity.equals("L")) {
			longPolarity = "n";
		}
		
		'''
		<spirit:busInterface>
			<spirit:name>«type»«longId»_«bus»_RST</spirit:name>
			<spirit:busType spirit:vendor="xilinx.com" spirit:library="signal" spirit:name="reset" spirit:version="1.0"/>
			<spirit:abstractionType spirit:vendor="xilinx.com" spirit:library="signal" spirit:name="reset_rtl" spirit:version="1.0"/>
			<spirit:slave/>
			<spirit:portMaps>
				«printXmlPortMap("RST",type.toLowerCase+longId+"_"+bus.toLowerCase()+"_areset"+longPolarity)»
			</spirit:portMaps>
			<spirit:parameters>
				<spirit:parameter>
					<spirit:name>POLARITY</spirit:name>
					<spirit:value spirit:id="BUSIFPARAM_VALUE.«type»«longId»_«bus»_RST.POLARITY">ACTIVE_«IF polarity.equals("H")»HIGH«ELSE»LOW«ENDIF»</spirit:value>
				</spirit:parameter>
			</spirit:parameters>
		</spirit:busInterface>
		'''
	}
	
	
	def printXmlAXIfullBusInterface(String id, String type) {
		
		var int data_width = 32;
		var String longId = id;
		if(Integer.parseInt(id)<10) {
			longId = "0" + id;
		}
		
		'''
		<spirit:busInterface>
			 <spirit:name>«type»«longId»_AXI</spirit:name>
			 <spirit:busType spirit:vendor="xilinx.com" spirit:library="interface" spirit:name="aximm" spirit:version="1.0"/>
			 <spirit:abstractionType spirit:vendor="xilinx.com" spirit:library="interface" spirit:name="aximm_rtl" spirit:version="1.0"/>
			 <spirit:«IF type.equals("S")»slave«ELSE»master«ENDIF»>
			 	<spirit:memoryMapRef spirit:memoryMapRef="«type»«longId»_AXI"/>
		 	</spirit:«IF type.equals("S")»slave«ELSE»master«ENDIF»>
			<spirit:portMaps>
				«FOR port : AXIfullPorts.keySet»
				«printXmlPortMap(port,type.toLowerCase()+longId+"_axi_"+port.toLowerCase())»
				«ENDFOR»
			</spirit:portMaps>
			<spirit:parameters>
				<spirit:parameter>
					<spirit:name>WIZ_DATA_WIDTH</spirit:name>
					<spirit:value spirit:format="long" spirit:id="BUSIFPARAM_VALUE.«type»«longId»_AXI.WIZ_DATA_WIDTH" spirit:choiceRef="choice_list_6fc15197">32</spirit:value>
				</spirit:parameter>
				<spirit:parameter>
					<spirit:name>WIZ_MEMORY_SIZE</spirit:name>
					<spirit:value spirit:format="long" spirit:id="BUSIFPARAM_VALUE.«type»«longId»_AXI.WIZ_MEMORY_SIZE" >1024</spirit:value>
				</spirit:parameter>
				<spirit:parameter>
					<spirit:name>SUPPORTS_NARROW_BURST</spirit:name>
					<spirit:value spirit:format="long" spirit:id="BUSIFPARAM_VALUE.«type»«longId»_AXI.SUPPORTS_NARROW_BURST" spirit:choiceRef="choice_pairs_ce1226b1">0</spirit:value>
				</spirit:parameter>
			</spirit:parameters>
		</spirit:busInterface>
		'''
	}
	
	def printXmlAXIliteBusInterface(String id, String type) {
		
		var numConfigRegs = 4;
		if((portMap.size+1)>4) {
			numConfigRegs = portMap.size+1;
		}
		
		var String longId = id;
		if(Integer.parseInt(id)<10) {
			longId = "0" + id;
		}
		
		'''
		<spirit:busInterface>
			<spirit:name>«type»«longId»_AXI</spirit:name>
			<spirit:busType spirit:vendor="xilinx.com" spirit:library="interface" spirit:name="aximm" spirit:version="1.0"/>
			<spirit:abstractionType spirit:vendor="xilinx.com" spirit:library="interface" spirit:name="aximm_rtl" spirit:version="1.0"/>
			<spirit:«IF type.equals("S")»slave«ELSE»master«ENDIF»>
				<spirit:memoryMapRef spirit:memoryMapRef="«type»«longId»_AXI"/>
			</spirit:«IF type.equals("S")»slave«ELSE»master«ENDIF»>
			<spirit:portMaps>
				«FOR port : AXIlitePorts.keySet»
				«printXmlPortMap(port,type.toLowerCase()+longId+"_axi_"+port.toLowerCase())»
				«ENDFOR»
			</spirit:portMaps>
			<spirit:parameters>
				<spirit:parameter>
					<spirit:name>WIZ_DATA_WIDTH</spirit:name>
					<spirit:value spirit:format="long" spirit:id="BUSIFPARAM_VALUE.«type»«longId»_AXI.WIZ_DATA_WIDTH" spirit:choiceRef="choice_list_6fc15197">32</spirit:value>
				</spirit:parameter>
				<spirit:parameter>
					<spirit:name>WIZ_NUM_REG</spirit:name>
					<spirit:value spirit:format="long" spirit:id="BUSIFPARAM_VALUE.«type»«longId»_AXI.WIZ_NUM_REG" spirit:minimum="4" spirit:maximum="512" spirit:rangeType="long">«numConfigRegs»</spirit:value>
				</spirit:parameter>
				<spirit:parameter>
					<spirit:name>SUPPORTS_NARROW_BURST</spirit:name>
					<spirit:value spirit:format="long" spirit:id="BUSIFPARAM_VALUE.«type»«longId»_AXI.SUPPORTS_NARROW_BURST" spirit:choiceRef="choice_pairs_ce1226b1">0</spirit:value>
				</spirit:parameter>
			</spirit:parameters>
		</spirit:busInterface>
		'''
	}
	
	def printXmlPortMap(String logicalPort,String physicalPort) {
		'''
		<spirit:portMap>
			<spirit:logicalPort>
				<spirit:name>«logicalPort»</spirit:name>
			</spirit:logicalPort>
			<spirit:physicalPort>
				<spirit:name>«physicalPort»</spirit:name>
			</spirit:physicalPort>
		</spirit:portMap>
		'''
	}
	
	def printGuiTcl() {
		
		'''
		# Definitional proc to organize widgets for parameters.
		proc init_gui { IPINST } {
			ipgui::add_param $IPINST -name "Component_Name"
			#Adding Page
			set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
			set C_S00_AXI_DATA_WIDTH [ipgui::add_param $IPINST -name "C_S00_AXI_DATA_WIDTH" -parent ${Page_0} -widget comboBox]
			set_property tooltip {Width of S_AXI data bus} ${C_S00_AXI_DATA_WIDTH}
			set C_S00_AXI_ADDR_WIDTH [ipgui::add_param $IPINST -name "C_S00_AXI_ADDR_WIDTH" -parent ${Page_0}]
			set_property tooltip {Width of S_AXI address bus} ${C_S00_AXI_ADDR_WIDTH}
			ipgui::add_param $IPINST -name "C_S00_AXI_BASEADDR" -parent ${Page_0}
			ipgui::add_param $IPINST -name "C_S00_AXI_HIGHADDR" -parent ${Page_0}
			«IF dedicatedInterfaces»
			«FOR input : inputMap.keySet»
			set C_S«getLongId(portMap.get(input)+1)»_AXI_ID_WIDTH [ipgui::add_param $IPINST -name "C_S«getLongId(portMap.get(input)+1)»_AXI_ID_WIDTH" -parent ${Page_0}]
			set_property tooltip {Width of ID for for write address, write data, read address and read data} ${C_S«getLongId(portMap.get(input)+1)»_AXI_ID_WIDTH}
			set C_S«getLongId(portMap.get(input)+1)»_AXI_DATA_WIDTH [ipgui::add_param $IPINST -name "C_S«getLongId(portMap.get(input)+1)»_AXI_DATA_WIDTH" -parent ${Page_0} -widget comboBox]
			set_property tooltip {Width of S_AXI data bus} ${C_S«getLongId(portMap.get(input)+1)»_AXI_DATA_WIDTH}
			set C_S«getLongId(portMap.get(input)+1)»_AXI_ADDR_WIDTH [ipgui::add_param $IPINST -name "C_S«getLongId(portMap.get(input)+1)»_AXI_ADDR_WIDTH" -parent ${Page_0}]
			set_property tooltip {Width of S_AXI address bus} ${C_S«getLongId(portMap.get(input)+1)»_AXI_ADDR_WIDTH}
			set C_S«getLongId(portMap.get(input)+1)»_AXI_AWUSER_WIDTH [ipgui::add_param $IPINST -name "C_S«getLongId(portMap.get(input)+1)»_AXI_AWUSER_WIDTH" -parent ${Page_0}]
			set_property tooltip {Width of optional user defined signal in write address channel} ${C_S«getLongId(portMap.get(input)+1)»_AXI_AWUSER_WIDTH}
			set C_S«getLongId(portMap.get(input)+1)»_AXI_ARUSER_WIDTH [ipgui::add_param $IPINST -name "C_S«getLongId(portMap.get(input)+1)»_AXI_ARUSER_WIDTH" -parent ${Page_0}]
			set_property tooltip {Width of optional user defined signal in read address channel} ${C_S«getLongId(portMap.get(input)+1)»_AXI_ARUSER_WIDTH}
			set C_S«getLongId(portMap.get(input)+1)»_AXI_WUSER_WIDTH [ipgui::add_param $IPINST -name "C_S«getLongId(portMap.get(input)+1)»_AXI_WUSER_WIDTH" -parent ${Page_0}]
			set_property tooltip {Width of optional user defined signal in write data channel} ${C_S«getLongId(portMap.get(input)+1)»_AXI_WUSER_WIDTH}
			set C_S«getLongId(portMap.get(input)+1)»_AXI_RUSER_WIDTH [ipgui::add_param $IPINST -name "C_S«getLongId(portMap.get(input)+1)»_AXI_RUSER_WIDTH" -parent ${Page_0}]
			set_property tooltip {Width of optional user defined signal in read data channel} ${C_S«getLongId(portMap.get(input)+1)»_AXI_RUSER_WIDTH}
			set C_S«getLongId(portMap.get(input)+1)»_AXI_BUSER_WIDTH [ipgui::add_param $IPINST -name "C_S«getLongId(portMap.get(input)+1)»_AXI_BUSER_WIDTH" -parent ${Page_0}]
			set_property tooltip {Width of optional user defined signal in write response channel} ${C_S«getLongId(portMap.get(input)+1)»_AXI_BUSER_WIDTH}
			ipgui::add_param $IPINST -name "C_S«getLongId(portMap.get(input)+1)»_AXI_BASEADDR" -parent ${Page_0}
			ipgui::add_param $IPINST -name "C_S«getLongId(portMap.get(input)+1)»_AXI_HIGHADDR" -parent ${Page_0}
			«ENDFOR»
			«FOR output : outputMap.keySet»
			set C_S«getLongId(portMap.get(output)+1)»_AXI_ID_WIDTH [ipgui::add_param $IPINST -name "C_S«getLongId(portMap.get(output)+1)»_AXI_ID_WIDTH" -parent ${Page_0}]
			set_property tooltip {Width of ID for for write address, write data, read address and read data} ${C_S«getLongId(portMap.get(output)+1)»_AXI_ID_WIDTH}
			set C_S«getLongId(portMap.get(output)+1)»_AXI_DATA_WIDTH [ipgui::add_param $IPINST -name "C_S«getLongId(portMap.get(output)+1)»_AXI_DATA_WIDTH" -parent ${Page_0} -widget comboBox]
			set_property tooltip {Width of S_AXI data bus} ${C_S«getLongId(portMap.get(output)+1)»_AXI_DATA_WIDTH}
			set C_S«getLongId(portMap.get(output)+1)»_AXI_ADDR_WIDTH [ipgui::add_param $IPINST -name "C_S«getLongId(portMap.get(output)+1)»_AXI_ADDR_WIDTH" -parent ${Page_0}]
			set_property tooltip {Width of S_AXI address bus} ${C_S«getLongId(portMap.get(output)+1)»_AXI_ADDR_WIDTH}
			set C_S«getLongId(portMap.get(output)+1)»_AXI_AWUSER_WIDTH [ipgui::add_param $IPINST -name "C_S«getLongId(portMap.get(output)+1)»_AXI_AWUSER_WIDTH" -parent ${Page_0}]
			set_property tooltip {Width of optional user defined signal in write address channel} ${C_S«getLongId(portMap.get(output)+1)»_AXI_AWUSER_WIDTH}
			set C_S«getLongId(portMap.get(output)+1)»_AXI_ARUSER_WIDTH [ipgui::add_param $IPINST -name "C_S«getLongId(portMap.get(output)+1)»_AXI_ARUSER_WIDTH" -parent ${Page_0}]
			set_property tooltip {Width of optional user defined signal in read address channel} ${C_S«getLongId(portMap.get(output)+1)»_AXI_ARUSER_WIDTH}
			set C_S«getLongId(portMap.get(output)+1)»_AXI_WUSER_WIDTH [ipgui::add_param $IPINST -name "C_S«getLongId(portMap.get(output)+1)»_AXI_WUSER_WIDTH" -parent ${Page_0}]
			set_property tooltip {Width of optional user defined signal in write data channel} ${C_S«getLongId(portMap.get(output)+1)»_AXI_WUSER_WIDTH}
			set C_S«getLongId(portMap.get(output)+1)»_AXI_RUSER_WIDTH [ipgui::add_param $IPINST -name "C_S«getLongId(portMap.get(output)+1)»_AXI_RUSER_WIDTH" -parent ${Page_0}]
			set_property tooltip {Width of optional user defined signal in read data channel} ${C_S«getLongId(portMap.get(output)+1)»_AXI_RUSER_WIDTH}
			set C_S«getLongId(portMap.get(output)+1)»_AXI_BUSER_WIDTH [ipgui::add_param $IPINST -name "C_S«getLongId(portMap.get(output)+1)»_AXI_BUSER_WIDTH" -parent ${Page_0}]
			set_property tooltip {Width of optional user defined signal in write response channel} ${C_S«getLongId(portMap.get(output)+1)»_AXI_BUSER_WIDTH}
			ipgui::add_param $IPINST -name "C_S«getLongId(portMap.get(output)+1)»_AXI_BASEADDR" -parent ${Page_0}
			ipgui::add_param $IPINST -name "C_S«getLongId(portMap.get(output)+1)»_AXI_HIGHADDR" -parent ${Page_0}
			«ENDFOR»
			«ELSE»
			set C_S01_AXI_ID_WIDTH [ipgui::add_param $IPINST -name "C_S01_AXI_ID_WIDTH" -parent ${Page_0}]
			set_property tooltip {Width of ID for for write address, write data, read address and read data} ${C_S01_AXI_ID_WIDTH}
			set C_S01_AXI_DATA_WIDTH [ipgui::add_param $IPINST -name "C_S01_AXI_DATA_WIDTH" -parent ${Page_0} -widget comboBox]
			set_property tooltip {Width of S_AXI data bus} ${C_S01_AXI_DATA_WIDTH}
			set C_S01_AXI_ADDR_WIDTH [ipgui::add_param $IPINST -name "C_S01_AXI_ADDR_WIDTH" -parent ${Page_0}]
			set_property tooltip {Width of S_AXI address bus} ${C_S01_AXI_ADDR_WIDTH}
			set C_S01_AXI_AWUSER_WIDTH [ipgui::add_param $IPINST -name "C_S01_AXI_AWUSER_WIDTH" -parent ${Page_0}]
			set_property tooltip {Width of optional user defined signal in write address channel} ${C_S01_AXI_AWUSER_WIDTH}
			set C_S01_AXI_ARUSER_WIDTH [ipgui::add_param $IPINST -name "C_S01_AXI_ARUSER_WIDTH" -parent ${Page_0}]
			set_property tooltip {Width of optional user defined signal in read address channel} ${C_S01_AXI_ARUSER_WIDTH}
			set C_S01_AXI_WUSER_WIDTH [ipgui::add_param $IPINST -name "C_S01_AXI_WUSER_WIDTH" -parent ${Page_0}]
			set_property tooltip {Width of optional user defined signal in write data channel} ${C_S01_AXI_WUSER_WIDTH}
			set C_S01_AXI_RUSER_WIDTH [ipgui::add_param $IPINST -name "C_S01_AXI_RUSER_WIDTH" -parent ${Page_0}]
			set_property tooltip {Width of optional user defined signal in read data channel} ${C_S01_AXI_RUSER_WIDTH}
			set C_S01_AXI_BUSER_WIDTH [ipgui::add_param $IPINST -name "C_S01_AXI_BUSER_WIDTH" -parent ${Page_0}]
			set_property tooltip {Width of optional user defined signal in write response channel} ${C_S01_AXI_BUSER_WIDTH}
			ipgui::add_param $IPINST -name "C_S01_AXI_BASEADDR" -parent ${Page_0}
			ipgui::add_param $IPINST -name "C_S01_AXI_HIGHADDR" -parent ${Page_0}
			«ENDIF»
		}

		# Parameters
		proc update_PARAM_VALUE.C_S00_AXI_DATA_WIDTH { PARAM_VALUE.C_S00_AXI_DATA_WIDTH } {
			# Procedure called to update C_S00_AXI_DATA_WIDTH when any of the dependent parameters in the arguments change
		}
		
		proc validate_PARAM_VALUE.C_S00_AXI_DATA_WIDTH { PARAM_VALUE.C_S00_AXI_DATA_WIDTH } {
			# Procedure called to validate C_S00_AXI_DATA_WIDTH
			return true
		}
		
		proc update_PARAM_VALUE.C_S00_AXI_ADDR_WIDTH { PARAM_VALUE.C_S00_AXI_ADDR_WIDTH } {
			# Procedure called to update C_S00_AXI_ADDR_WIDTH when any of the dependent parameters in the arguments change
		}
		
		proc validate_PARAM_VALUE.C_S00_AXI_ADDR_WIDTH { PARAM_VALUE.C_S00_AXI_ADDR_WIDTH } {
			# Procedure called to validate C_S00_AXI_ADDR_WIDTH
			return true
		}
		
		proc update_PARAM_VALUE.C_S00_AXI_BASEADDR { PARAM_VALUE.C_S00_AXI_BASEADDR } {
			# Procedure called to update C_S00_AXI_BASEADDR when any of the dependent parameters in the arguments change
		}
		
		proc validate_PARAM_VALUE.C_S00_AXI_BASEADDR { PARAM_VALUE.C_S00_AXI_BASEADDR } {
			# Procedure called to validate C_S00_AXI_BASEADDR
			return true
		}
		
		proc update_PARAM_VALUE.C_S00_AXI_HIGHADDR { PARAM_VALUE.C_S00_AXI_HIGHADDR } {
			# Procedure called to update C_S00_AXI_HIGHADDR when any of the dependent parameters in the arguments change
		}
		
		proc validate_PARAM_VALUE.C_S00_AXI_HIGHADDR { PARAM_VALUE.C_S00_AXI_HIGHADDR } {
			# Procedure called to validate C_S00_AXI_HIGHADDR
			return true
		}

		«IF dedicatedInterfaces»
		«FOR input : inputMap.keySet»
		proc update_PARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_ID_WIDTH { PARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_ID_WIDTH } {
			# Procedure called to update C_S«getLongId(portMap.get(input)+1)»_AXI_ID_WIDTH when any of the dependent parameters in the arguments change
		}
		
		proc validate_PARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_ID_WIDTH { PARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_ID_WIDTH } {
			# Procedure called to validate C_S«getLongId(portMap.get(input)+1)»_AXI_ID_WIDTH
			return true
		}
		
		proc update_PARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_DATA_WIDTH { PARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_DATA_WIDTH } {
			# Procedure called to update C_S«getLongId(portMap.get(input)+1)»_AXI_DATA_WIDTH when any of the dependent parameters in the arguments change
		}
		
		proc validate_PARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_DATA_WIDTH { PARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_DATA_WIDTH } {
			# Procedure called to validate C_S«getLongId(portMap.get(input)+1)»_AXI_DATA_WIDTH
			return true
		}
		
		proc update_PARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_ADDR_WIDTH { PARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_ADDR_WIDTH } {
			# Procedure called to update C_S«getLongId(portMap.get(input)+1)»_AXI_ADDR_WIDTH when any of the dependent parameters in the arguments change
		}
		
		proc validate_PARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_ADDR_WIDTH { PARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_ADDR_WIDTH } {
			# Procedure called to validate C_S«getLongId(portMap.get(input)+1)»_AXI_ADDR_WIDTH
			return true
		}
		
		proc update_PARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_AWUSER_WIDTH { PARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_AWUSER_WIDTH } {
			# Procedure called to update C_S«getLongId(portMap.get(input)+1)»_AXI_AWUSER_WIDTH when any of the dependent parameters in the arguments change
		}
		
		proc validate_PARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_AWUSER_WIDTH { PARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_AWUSER_WIDTH } {
			# Procedure called to validate C_S«getLongId(portMap.get(input)+1)»_AXI_AWUSER_WIDTH
			return true
		}
		
		proc update_PARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_ARUSER_WIDTH { PARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_ARUSER_WIDTH } {
			# Procedure called to update C_S«getLongId(portMap.get(input)+1)»_AXI_ARUSER_WIDTH when any of the dependent parameters in the arguments change
		}
		
		proc validate_PARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_ARUSER_WIDTH { PARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_ARUSER_WIDTH } {
			# Procedure called to validate C_S«getLongId(portMap.get(input)+1)»_AXI_ARUSER_WIDTH
			return true
		}
		
		proc update_PARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_WUSER_WIDTH { PARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_WUSER_WIDTH } {
			# Procedure called to update C_S«getLongId(portMap.get(input)+1)»_AXI_WUSER_WIDTH when any of the dependent parameters in the arguments change
		}
		
		proc validate_PARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_WUSER_WIDTH { PARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_WUSER_WIDTH } {
			# Procedure called to validate C_S«getLongId(portMap.get(input)+1)»_AXI_WUSER_WIDTH
			return true
		}
		
		proc update_PARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_RUSER_WIDTH { PARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_RUSER_WIDTH } {
			# Procedure called to update C_S«getLongId(portMap.get(input)+1)»_AXI_RUSER_WIDTH when any of the dependent parameters in the arguments change
		}
		
		proc validate_PARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_RUSER_WIDTH { PARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_RUSER_WIDTH } {
			# Procedure called to validate C_S«getLongId(portMap.get(input)+1)»_AXI_RUSER_WIDTH
			return true
		}
		
		proc update_PARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_BUSER_WIDTH { PARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_BUSER_WIDTH } {
			# Procedure called to update C_S«getLongId(portMap.get(input)+1)»_AXI_BUSER_WIDTH when any of the dependent parameters in the arguments change
		}
		
		proc validate_PARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_BUSER_WIDTH { PARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_BUSER_WIDTH } {
			# Procedure called to validate C_S«getLongId(portMap.get(input)+1)»_AXI_BUSER_WIDTH
			return true
		}
		
		proc update_PARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_BASEADDR { PARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_BASEADDR } {
			# Procedure called to update C_S«getLongId(portMap.get(input)+1)»_AXI_BASEADDR when any of the dependent parameters in the arguments change
		}
		
		proc validate_PARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_BASEADDR { PARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_BASEADDR } {
			# Procedure called to validate C_S«getLongId(portMap.get(input)+1)»_AXI_BASEADDR
			return true
		}
		
		proc update_PARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_HIGHADDR { PARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_HIGHADDR } {
			# Procedure called to update C_S«getLongId(portMap.get(input)+1)»_AXI_HIGHADDR when any of the dependent parameters in the arguments change
		}
		
		proc validate_PARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_HIGHADDR { PARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_HIGHADDR } {
			# Procedure called to validate C_S«getLongId(portMap.get(input)+1)»_AXI_HIGHADDR
			return true
		}
		«ENDFOR»

		«FOR output : outputMap.keySet»
		proc update_PARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_ID_WIDTH { PARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_ID_WIDTH } {
			# Procedure called to update C_S«getLongId(portMap.get(output)+1)»_AXI_ID_WIDTH when any of the dependent parameters in the arguments change
		}
		
		proc validate_PARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_ID_WIDTH { PARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_ID_WIDTH } {
			# Procedure called to validate C_S«getLongId(portMap.get(output)+1)»_AXI_ID_WIDTH
			return true
		}
		
		proc update_PARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_DATA_WIDTH { PARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_DATA_WIDTH } {
			# Procedure called to update C_S«getLongId(portMap.get(output)+1)»_AXI_DATA_WIDTH when any of the dependent parameters in the arguments change
		}
		
		proc validate_PARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_DATA_WIDTH { PARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_DATA_WIDTH } {
			# Procedure called to validate C_S«getLongId(portMap.get(output)+1)»_AXI_DATA_WIDTH
			return true
		}
		
		proc update_PARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_ADDR_WIDTH { PARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_ADDR_WIDTH } {
			# Procedure called to update C_S«getLongId(portMap.get(output)+1)»_AXI_ADDR_WIDTH when any of the dependent parameters in the arguments change
		}
		
		proc validate_PARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_ADDR_WIDTH { PARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_ADDR_WIDTH } {
			# Procedure called to validate C_S«getLongId(portMap.get(output)+1)»_AXI_ADDR_WIDTH
			return true
		}
		
		proc update_PARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_AWUSER_WIDTH { PARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_AWUSER_WIDTH } {
			# Procedure called to update C_S«getLongId(portMap.get(output)+1)»_AXI_AWUSER_WIDTH when any of the dependent parameters in the arguments change
		}
		
		proc validate_PARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_AWUSER_WIDTH { PARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_AWUSER_WIDTH } {
			# Procedure called to validate C_S«getLongId(portMap.get(output)+1)»_AXI_AWUSER_WIDTH
			return true
		}
		
		proc update_PARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_ARUSER_WIDTH { PARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_ARUSER_WIDTH } {
			# Procedure called to update C_S«getLongId(portMap.get(output)+1)»_AXI_ARUSER_WIDTH when any of the dependent parameters in the arguments change
		}
		
		proc validate_PARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_ARUSER_WIDTH { PARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_ARUSER_WIDTH } {
			# Procedure called to validate C_S«getLongId(portMap.get(output)+1)»_AXI_ARUSER_WIDTH
			return true
		}
		
		proc update_PARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_WUSER_WIDTH { PARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_WUSER_WIDTH } {
			# Procedure called to update C_S«getLongId(portMap.get(output)+1)»_AXI_WUSER_WIDTH when any of the dependent parameters in the arguments change
		}
		
		proc validate_PARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_WUSER_WIDTH { PARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_WUSER_WIDTH } {
			# Procedure called to validate C_S«getLongId(portMap.get(output)+1)»_AXI_WUSER_WIDTH
			return true
		}
		
		proc update_PARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_RUSER_WIDTH { PARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_RUSER_WIDTH } {
			# Procedure called to update C_S«getLongId(portMap.get(output)+1)»_AXI_RUSER_WIDTH when any of the dependent parameters in the arguments change
		}
		
		proc validate_PARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_RUSER_WIDTH { PARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_RUSER_WIDTH } {
			# Procedure called to validate C_S«getLongId(portMap.get(output)+1)»_AXI_RUSER_WIDTH
			return true
		}
		
		proc update_PARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_BUSER_WIDTH { PARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_BUSER_WIDTH } {
			# Procedure called to update C_S«getLongId(portMap.get(output)+1)»_AXI_BUSER_WIDTH when any of the dependent parameters in the arguments change
		}
		
		proc validate_PARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_BUSER_WIDTH { PARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_BUSER_WIDTH } {
			# Procedure called to validate C_S«getLongId(portMap.get(output)+1)»_AXI_BUSER_WIDTH
			return true
		}
		
		proc update_PARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_BASEADDR { PARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_BASEADDR } {
			# Procedure called to update C_S«getLongId(portMap.get(output)+1)»_AXI_BASEADDR when any of the dependent parameters in the arguments change
		}
		
		proc validate_PARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_BASEADDR { PARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_BASEADDR } {
			# Procedure called to validate C_S«getLongId(portMap.get(output)+1)»_AXI_BASEADDR
			return true
		}
		
		proc update_PARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_HIGHADDR { PARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_HIGHADDR } {
			# Procedure called to update C_S«getLongId(portMap.get(output)+1)»_AXI_HIGHADDR when any of the dependent parameters in the arguments change
		}
		
		proc validate_PARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_HIGHADDR { PARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_HIGHADDR } {
			# Procedure called to validate C_S«getLongId(portMap.get(output)+1)»_AXI_HIGHADDR
			return true
		}
		«ENDFOR»
		«ELSE»
		proc update_PARAM_VALUE.C_S01_AXI_ID_WIDTH { PARAM_VALUE.C_S01_AXI_ID_WIDTH } {
			# Procedure called to update C_S01_AXI_ID_WIDTH when any of the dependent parameters in the arguments change
		}
		
		proc validate_PARAM_VALUE.C_S01_AXI_ID_WIDTH { PARAM_VALUE.C_S01_AXI_ID_WIDTH } {
			# Procedure called to validate C_S01_AXI_ID_WIDTH
			return true
		}
		
		proc update_PARAM_VALUE.C_S01_AXI_DATA_WIDTH { PARAM_VALUE.C_S01_AXI_DATA_WIDTH } {
			# Procedure called to update C_S01_AXI_DATA_WIDTH when any of the dependent parameters in the arguments change
		}
		
		proc validate_PARAM_VALUE.C_S01_AXI_DATA_WIDTH { PARAM_VALUE.C_S01_AXI_DATA_WIDTH } {
			# Procedure called to validate C_S01_AXI_DATA_WIDTH
			return true
		}
		
		proc update_PARAM_VALUE.C_S01_AXI_ADDR_WIDTH { PARAM_VALUE.C_S01_AXI_ADDR_WIDTH } {
			# Procedure called to update C_S01_AXI_ADDR_WIDTH when any of the dependent parameters in the arguments change
		}
		
		proc validate_PARAM_VALUE.C_S01_AXI_ADDR_WIDTH { PARAM_VALUE.C_S01_AXI_ADDR_WIDTH } {
			# Procedure called to validate C_S01_AXI_ADDR_WIDTH
			return true
		}
		
		proc update_PARAM_VALUE.C_S01_AXI_AWUSER_WIDTH { PARAM_VALUE.C_S01_AXI_AWUSER_WIDTH } {
			# Procedure called to update C_S01_AXI_AWUSER_WIDTH when any of the dependent parameters in the arguments change
		}
		
		proc validate_PARAM_VALUE.C_S01_AXI_AWUSER_WIDTH { PARAM_VALUE.C_S01_AXI_AWUSER_WIDTH } {
			# Procedure called to validate C_S01_AXI_AWUSER_WIDTH
			return true
		}
		
		proc update_PARAM_VALUE.C_S01_AXI_ARUSER_WIDTH { PARAM_VALUE.C_S01_AXI_ARUSER_WIDTH } {
			# Procedure called to update C_S01_AXI_ARUSER_WIDTH when any of the dependent parameters in the arguments change
		}
		
		proc validate_PARAM_VALUE.C_S01_AXI_ARUSER_WIDTH { PARAM_VALUE.C_S01_AXI_ARUSER_WIDTH } {
			# Procedure called to validate C_S01_AXI_ARUSER_WIDTH
			return true
		}
		
		proc update_PARAM_VALUE.C_S01_AXI_WUSER_WIDTH { PARAM_VALUE.C_S01_AXI_WUSER_WIDTH } {
			# Procedure called to update C_S01_AXI_WUSER_WIDTH when any of the dependent parameters in the arguments change
		}
		
		proc validate_PARAM_VALUE.C_S01_AXI_WUSER_WIDTH { PARAM_VALUE.C_S01_AXI_WUSER_WIDTH } {
			# Procedure called to validate C_S01_AXI_WUSER_WIDTH
			return true
		}
		
		proc update_PARAM_VALUE.C_S01_AXI_RUSER_WIDTH { PARAM_VALUE.C_S01_AXI_RUSER_WIDTH } {
			# Procedure called to update C_S01_AXI_RUSER_WIDTH when any of the dependent parameters in the arguments change
		}
		
		proc validate_PARAM_VALUE.C_S01_AXI_RUSER_WIDTH { PARAM_VALUE.C_S01_AXI_RUSER_WIDTH } {
			# Procedure called to validate C_S01_AXI_RUSER_WIDTH
			return true
		}
		
		proc update_PARAM_VALUE.C_S01_AXI_BUSER_WIDTH { PARAM_VALUE.C_S01_AXI_BUSER_WIDTH } {
			# Procedure called to update C_S01_AXI_BUSER_WIDTH when any of the dependent parameters in the arguments change
		}
		
		proc validate_PARAM_VALUE.C_S01_AXI_BUSER_WIDTH { PARAM_VALUE.C_S01_AXI_BUSER_WIDTH } {
			# Procedure called to validate C_S01_AXI_BUSER_WIDTH
			return true
		}
		
		proc update_PARAM_VALUE.C_S01_AXI_BASEADDR { PARAM_VALUE.C_S01_AXI_BASEADDR } {
			# Procedure called to update C_S01_AXI_BASEADDR when any of the dependent parameters in the arguments change
		}
		
		proc validate_PARAM_VALUE.C_S01_AXI_BASEADDR { PARAM_VALUE.C_S01_AXI_BASEADDR } {
			# Procedure called to validate C_S01_AXI_BASEADDR
			return true
		}
		
		proc update_PARAM_VALUE.C_S01_AXI_HIGHADDR { PARAM_VALUE.C_S01_AXI_HIGHADDR } {
			# Procedure called to update C_S01_AXI_HIGHADDR when any of the dependent parameters in the arguments change
		}
		
		proc validate_PARAM_VALUE.C_S01_AXI_HIGHADDR { PARAM_VALUE.C_S01_AXI_HIGHADDR } {
			# Procedure called to validate C_S01_AXI_HIGHADDR
			return true
		}
		«ENDIF»
		
		# Model Parameters
		proc update_MODELPARAM_VALUE.C_S00_AXI_DATA_WIDTH { MODELPARAM_VALUE.C_S00_AXI_DATA_WIDTH PARAM_VALUE.C_S00_AXI_DATA_WIDTH } {
			# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
			set_property value [get_property value ${PARAM_VALUE.C_S00_AXI_DATA_WIDTH}] ${MODELPARAM_VALUE.C_S00_AXI_DATA_WIDTH}
		}
		
		proc update_MODELPARAM_VALUE.C_S00_AXI_ADDR_WIDTH { MODELPARAM_VALUE.C_S00_AXI_ADDR_WIDTH PARAM_VALUE.C_S00_AXI_ADDR_WIDTH } {
			# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
			set_property value [get_property value ${PARAM_VALUE.C_S00_AXI_ADDR_WIDTH}] ${MODELPARAM_VALUE.C_S00_AXI_ADDR_WIDTH}
		}

		«IF dedicatedInterfaces»
		«FOR input : inputMap.keySet»
		proc update_MODELPARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_ID_WIDTH { MODELPARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_ID_WIDTH PARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_ID_WIDTH } {
			# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
			set_property value [get_property value ${PARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_ID_WIDTH}] ${MODELPARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_ID_WIDTH}
		}
		
		proc update_MODELPARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_DATA_WIDTH { MODELPARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_DATA_WIDTH PARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_DATA_WIDTH } {
			# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
			set_property value [get_property value ${PARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_DATA_WIDTH}] ${MODELPARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_DATA_WIDTH}
		}
		
		proc update_MODELPARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_ADDR_WIDTH { MODELPARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_ADDR_WIDTH PARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_ADDR_WIDTH } {
			# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
			set_property value [get_property value ${PARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_ADDR_WIDTH}] ${MODELPARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_ADDR_WIDTH}
		}
		
		proc update_MODELPARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_AWUSER_WIDTH { MODELPARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_AWUSER_WIDTH PARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_AWUSER_WIDTH } {
			# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
			set_property value [get_property value ${PARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_AWUSER_WIDTH}] ${MODELPARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_AWUSER_WIDTH}
		}
		
		proc update_MODELPARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_ARUSER_WIDTH { MODELPARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_ARUSER_WIDTH PARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_ARUSER_WIDTH } {
			# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
			set_property value [get_property value ${PARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_ARUSER_WIDTH}] ${MODELPARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_ARUSER_WIDTH}
		}
		
		proc update_MODELPARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_WUSER_WIDTH { MODELPARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_WUSER_WIDTH PARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_WUSER_WIDTH } {
			# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
			set_property value [get_property value ${PARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_WUSER_WIDTH}] ${MODELPARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_WUSER_WIDTH}
		}
		
		proc update_MODELPARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_RUSER_WIDTH { MODELPARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_RUSER_WIDTH PARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_RUSER_WIDTH } {
			# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
			set_property value [get_property value ${PARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_RUSER_WIDTH}] ${MODELPARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_RUSER_WIDTH}
		}
		
		proc update_MODELPARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_BUSER_WIDTH { MODELPARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_BUSER_WIDTH PARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_BUSER_WIDTH } {
			# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
			set_property value [get_property value ${PARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_BUSER_WIDTH}] ${MODELPARAM_VALUE.C_S«getLongId(portMap.get(input)+1)»_AXI_BUSER_WIDTH}
		}
		«ENDFOR»


		«FOR output : outputMap.keySet»
		proc update_MODELPARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_ID_WIDTH { MODELPARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_ID_WIDTH PARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_ID_WIDTH } {
			# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
			set_property value [get_property value ${PARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_ID_WIDTH}] ${MODELPARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_ID_WIDTH}
		}
		
		proc update_MODELPARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_DATA_WIDTH { MODELPARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_DATA_WIDTH PARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_DATA_WIDTH } {
			# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
			set_property value [get_property value ${PARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_DATA_WIDTH}] ${MODELPARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_DATA_WIDTH}
		}
		
		proc update_MODELPARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_ADDR_WIDTH { MODELPARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_ADDR_WIDTH PARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_ADDR_WIDTH } {
			# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
			set_property value [get_property value ${PARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_ADDR_WIDTH}] ${MODELPARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_ADDR_WIDTH}
		}
		
		proc update_MODELPARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_AWUSER_WIDTH { MODELPARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_AWUSER_WIDTH PARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_AWUSER_WIDTH } {
			# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
			set_property value [get_property value ${PARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_AWUSER_WIDTH}] ${MODELPARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_AWUSER_WIDTH}
		}
		
		proc update_MODELPARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_ARUSER_WIDTH { MODELPARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_ARUSER_WIDTH PARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_ARUSER_WIDTH } {
			# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
			set_property value [get_property value ${PARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_ARUSER_WIDTH}] ${MODELPARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_ARUSER_WIDTH}
		}
		
		proc update_MODELPARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_WUSER_WIDTH { MODELPARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_WUSER_WIDTH PARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_WUSER_WIDTH } {
			# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
			set_property value [get_property value ${PARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_WUSER_WIDTH}] ${MODELPARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_WUSER_WIDTH}
		}
		
		proc update_MODELPARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_RUSER_WIDTH { MODELPARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_RUSER_WIDTH PARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_RUSER_WIDTH } {
			# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
			set_property value [get_property value ${PARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_RUSER_WIDTH}] ${MODELPARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_RUSER_WIDTH}
		}
		
		proc update_MODELPARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_BUSER_WIDTH { MODELPARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_BUSER_WIDTH PARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_BUSER_WIDTH } {
			# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
			set_property value [get_property value ${PARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_BUSER_WIDTH}] ${MODELPARAM_VALUE.C_S«getLongId(portMap.get(output)+1)»_AXI_BUSER_WIDTH}
		}
		«ENDFOR»
		«ELSE»
		proc update_MODELPARAM_VALUE.C_S01_AXI_ID_WIDTH { MODELPARAM_VALUE.C_S01_AXI_ID_WIDTH PARAM_VALUE.C_S01_AXI_ID_WIDTH } {
			# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
			set_property value [get_property value ${PARAM_VALUE.C_S01_AXI_ID_WIDTH}] ${MODELPARAM_VALUE.C_S01_AXI_ID_WIDTH}
		}
		
		proc update_MODELPARAM_VALUE.C_S01_AXI_DATA_WIDTH { MODELPARAM_VALUE.C_S01_AXI_DATA_WIDTH PARAM_VALUE.C_S01_AXI_DATA_WIDTH } {
			# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
			set_property value [get_property value ${PARAM_VALUE.C_S01_AXI_DATA_WIDTH}] ${MODELPARAM_VALUE.C_S01_AXI_DATA_WIDTH}
		}
		
		proc update_MODELPARAM_VALUE.C_S01_AXI_ADDR_WIDTH { MODELPARAM_VALUE.C_S01_AXI_ADDR_WIDTH PARAM_VALUE.C_S01_AXI_ADDR_WIDTH } {
			# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
			set_property value [get_property value ${PARAM_VALUE.C_S01_AXI_ADDR_WIDTH}] ${MODELPARAM_VALUE.C_S01_AXI_ADDR_WIDTH}
		}
		
		proc update_MODELPARAM_VALUE.C_S01_AXI_AWUSER_WIDTH { MODELPARAM_VALUE.C_S01_AXI_AWUSER_WIDTH PARAM_VALUE.C_S01_AXI_AWUSER_WIDTH } {
			# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
			set_property value [get_property value ${PARAM_VALUE.C_S01_AXI_AWUSER_WIDTH}] ${MODELPARAM_VALUE.C_S01_AXI_AWUSER_WIDTH}
		}
		
		proc update_MODELPARAM_VALUE.C_S01_AXI_ARUSER_WIDTH { MODELPARAM_VALUE.C_S01_AXI_ARUSER_WIDTH PARAM_VALUE.C_S01_AXI_ARUSER_WIDTH } {
			# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
			set_property value [get_property value ${PARAM_VALUE.C_S01_AXI_ARUSER_WIDTH}] ${MODELPARAM_VALUE.C_S01_AXI_ARUSER_WIDTH}
		}
		
		proc update_MODELPARAM_VALUE.C_S01_AXI_WUSER_WIDTH { MODELPARAM_VALUE.C_S01_AXI_WUSER_WIDTH PARAM_VALUE.C_S01_AXI_WUSER_WIDTH } {
			# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
			set_property value [get_property value ${PARAM_VALUE.C_S01_AXI_WUSER_WIDTH}] ${MODELPARAM_VALUE.C_S01_AXI_WUSER_WIDTH}
		}
		
		proc update_MODELPARAM_VALUE.C_S01_AXI_RUSER_WIDTH { MODELPARAM_VALUE.C_S01_AXI_RUSER_WIDTH PARAM_VALUE.C_S01_AXI_RUSER_WIDTH } {
			# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
			set_property value [get_property value ${PARAM_VALUE.C_S01_AXI_RUSER_WIDTH}] ${MODELPARAM_VALUE.C_S01_AXI_RUSER_WIDTH}
		}
		
		proc update_MODELPARAM_VALUE.C_S01_AXI_BUSER_WIDTH { MODELPARAM_VALUE.C_S01_AXI_BUSER_WIDTH PARAM_VALUE.C_S01_AXI_BUSER_WIDTH } {
			# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
			set_property value [get_property value ${PARAM_VALUE.C_S01_AXI_BUSER_WIDTH}] ${MODELPARAM_VALUE.C_S01_AXI_BUSER_WIDTH}
		}
		«ENDIF»
		'''
	}
	
	def printMdd() {
		'''
		OPTION psf_version = 2.1;

		BEGIN DRIVER mm_accelerator
			OPTION supported_peripherals = (mm_accelerator);
			OPTION copyfiles = all;
			OPTION VERSION = 1.0;
			OPTION NAME = mm_accelerator;
		END DRIVER
		'''
	}

	override printIpPackage(Network network,String file) {
		if(file.equals("COMPONENT")) {
			printXmlComponent(network);
		} else if (file.equals("GUI_TCL")) {
			printGuiTcl();
		} else if (file.equals("SW_MDD")) {
			printMdd();
		}
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