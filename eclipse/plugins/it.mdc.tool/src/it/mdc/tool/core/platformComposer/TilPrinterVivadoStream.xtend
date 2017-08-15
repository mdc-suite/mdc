/*
 *
 */
 
package it.mdc.tool.core.platformComposer

import java.text.SimpleDateFormat
import java.util.Date
import net.sf.orcc.df.Network
import java.util.ArrayList
import java.util.Map
import java.util.HashMap
import net.sf.orcc.df.Portimport net.sf.orcc.df.Actor
import it.mdc.tool.core.ConfigManager

/*
 * Vivado Template Interface Layer 
 * Stream HW Accelerator Printer
 * 
 * @author Carlo Sau
 */
class TilPrinterVivadoStream extends TilPrinter {
	
	HashMap<String,String> AXIlitePorts;
	HashMap<String,String> AXIstreamPorts;
	
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
	
	def initAXIstreamPorts() {
		//slave side
		AXIstreamPorts = new HashMap<String,String>();
		AXIstreamPorts.put("TDATA","in_bus_TDATA_WIDTH_32");
		AXIstreamPorts.put("TSTRB","in_bus_4");
		AXIstreamPorts.put("TLAST","in");
		AXIstreamPorts.put("TVALID","in");
		AXIstreamPorts.put("TREADY","out");
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
		// Template Interface Layer module - Stream type
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
		wire [31 : 0]				slv_reg«portMap.get(port)+1»;
	    «ENDFOR»
		«FOR input : inputMap.keySet()»
		wire [«input.type.sizeInBits-1» : 0]				«input.getName()»_data;
		wire 						«input.getName()»_send;
		wire						«input.getName()»_rdy;
		wire						«input.getName()»_ack;
		wire [15:0]					«input.getName()»_count;
		«ENDFOR»
		«FOR output : outputMap.keySet()»
		wire [«output.type.sizeInBits-1» : 0]				«output.getName()»_data;
		wire 						«output.getName()»_send;
		wire						«output.getName()»_rdy;
		wire						«output.getName()»_ack;
		wire [15:0]					«output.getName()»_count;
		«ENDFOR»
		'''
		
		
	}
	
	def printTopInterface() {
		
		'''
		module s_accelerator#
		(
			// Parameters of Axi Slave Bus Interface S00_AXI
			parameter integer C_S00_AXI_DATA_WIDTH	= 32,
			parameter integer C_S00_AXI_ADDR_WIDTH	= «computeSizePointer+2»,
			
			«FOR input : inputMap.keySet»// Parameters of Axi Slave Bus Interface S«getLongId(inputMap.get(input))»_AXIS
			parameter integer C_S«getLongId(inputMap.get(input))»_AXIS_TDATA_WIDTH	= 32,
			«ENDFOR»

			«FOR output : outputMap.keySet»// Parameters of Axi Master Bus Interface M«getLongId(outputMap.get(output))»_AXIS
			parameter integer C_M«getLongId(outputMap.get(output))»_AXIS_TDATA_WIDTH	= 32,
			parameter integer C_M«getLongId(outputMap.get(output))»_AXIS_START_COUNT	= 32
			«ENDFOR»
		)
		(
			«FOR input : inputMap.keySet»// Ports of Axi Slave Bus Interface S«getLongId(inputMap.get(input))»_AXIS
			input wire  s«getLongId(inputMap.get(input))»_axis_aclk,
			input wire  s«getLongId(inputMap.get(input))»_axis_aresetn,
			output wire  s«getLongId(inputMap.get(input))»_axis_tready,
			input wire [C_S«getLongId(inputMap.get(input))»_AXIS_TDATA_WIDTH-1 : 0] s«getLongId(inputMap.get(input))»_axis_tdata,
			input wire [(C_S«getLongId(inputMap.get(input))»_AXIS_TDATA_WIDTH/8)-1 : 0] s«getLongId(inputMap.get(input))»_axis_tstrb,
			input wire  s«getLongId(inputMap.get(input))»_axis_tlast,
			input wire  s«getLongId(inputMap.get(input))»_axis_tvalid,
			input wire [31 : 0] s«getLongId(inputMap.get(input))»_axis_data_count,
			«ENDFOR»
			«FOR output : outputMap.keySet()»// Ports of Axi Master Bus Interface M«getLongId(outputMap.get(output))»_AXIS
			input wire  m«getLongId(outputMap.get(output))»_axis_aclk,
			input wire  m«getLongId(outputMap.get(output))»_axis_aresetn,
			output wire  m«getLongId(outputMap.get(output))»_axis_tvalid,
			output wire [C_M«getLongId(outputMap.get(output))»_AXIS_TDATA_WIDTH-1 : 0] m«getLongId(outputMap.get(output))»_axis_tdata,
			output wire [(C_M«getLongId(outputMap.get(output))»_AXIS_TDATA_WIDTH/8)-1 : 0] m«getLongId(outputMap.get(output))»_axis_tstrb,
			output wire  m«getLongId(outputMap.get(output))»_axis_tlast,
			input wire  m«getLongId(outputMap.get(output))»_axis_tready,
			«ENDFOR»
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
			
		// Coprocessor Front-End(s)
		// ----------------------------------------------------------------------------
		«FOR input : inputMap.keySet()»
		front_end i_front_end_«inputMap.get(input)»(
			.aclk(s«getLongId(inputMap.get(input))»_axis_aclk),
			.aresetn(s«getLongId(inputMap.get(input))»_axis_aresetn),
			.start(slv_reg0[0]),
			.tvalid(s«getLongId(inputMap.get(input))»_axis_tvalid),
			.rdy(«input.name»_rdy),
			.ack(«input.name»_ack),
			.tready(s«getLongId(inputMap.get(input))»_axis_tready),
			.send(«input.name»_send)
		);
		«ENDFOR»
		// ----------------------------------------------------------------------------
			
		// Multi-Dataflow Reconfigurable Datapath
		// ----------------------------------------------------------------------------
		«printTopDatapath()»
		«FOR input :inputMap.keySet»
		assign «input.name»_data = s«getLongId(inputMap.get(input))»_axis_tdata«IF input.type.sizeInBits<32»[«input.type.sizeInBits-1»:0]«ENDIF»;
		assign «input.name»_count = s«getLongId(inputMap.get(input))»_axis_data_count[15:0];
		«ENDFOR»
		«FOR output :outputMap.keySet»
		assign m«getLongId(outputMap.get(output))»_axis_tdata = «IF output.type.sizeInBits<32»{{«output.type.sizeInBits»{1'b0}},«output.name»_data}«ELSE»«output.name»_data«ENDIF»;
		«ENDFOR»
		// ----------------------------------------------------------------------------	
		
		// Coprocessor Back-End(s)
		// ----------------------------------------------------------------------------
		«FOR output : outputMap.keySet()»
		back_end i_back_end_«outputMap.get(output)»(
			.aclk(s«getLongId(outputMap.get(output))»_axis_aclk),
			.aresetn(s«getLongId(outputMap.get(output))»_axis_aresetn),
			.start(slv_reg0[0]),
			.tready(m«getLongId(outputMap.get(output))»_axis_tready),
			.send(«output.name»_send),
			.tvalid(m«getLongId(outputMap.get(output))»_axis_tvalid),
			.rdy(«output.name»_rdy),
			.ack(«output.name»_ack)
		);
		
		assign m«getLongId(outputMap.get(output))»_axis_tstrb = 4'b0000;
		assign m«getLongId(outputMap.get(output))»_axis_tlast = 1'b0;
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
		parameter integer C_S_AXI_ADDR_WIDTH	= «size_pointer+2»
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
		initAXIstreamPorts();
							
		'''
		<?xml version="1.0" encoding="UTF-8"?>
		<spirit:component xmlns:xilinx="http://www.xilinx.com" xmlns:spirit="http://www.spiritconsortium.org/XMLSchema/SPIRIT/1685-2009" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
			<spirit:vendor>user.org</spirit:vendor>
			<spirit:library>user</spirit:library>
			<spirit:name>s_accelerator</spirit:name>
			<spirit:version>1.0</spirit:version>
			<spirit:busInterfaces>
			«printXmlAXIliteBusInterface("0","S")»
			«printXmlClockBusInterface("0","S","AXI","L")»
			«printXmlResetBusInterface("0","S","AXI","L")»
			«FOR input : network.inputs»
			«printXmlAXIstreamBusInterface(inputMap.get(input).toString(),"S")»
			«printXmlClockBusInterface(inputMap.get(input).toString(),"S","AXIS","L")»
			«printXmlResetBusInterface(inputMap.get(input).toString(),"S","AXIS","L")»
			«ENDFOR»
			«FOR output : network.outputs»
			«printXmlAXIstreamBusInterface(outputMap.get(output).toString(),"M")»
			«printXmlClockBusInterface(outputMap.get(output).toString(),"M","AXIS","L")»
			«printXmlResetBusInterface(outputMap.get(output).toString(),"M","AXIS","L")»
			«ENDFOR»
			</spirit:busInterfaces>
			<spirit:memoryMaps>
				«printXmlAXIliteRegMemoryMap("0","S")»
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
					«FOR input : network.inputs»
					«printXmlAXIstreamPorts(inputMap.get(input).toString(),"S")»
					«ENDFOR»
					«FOR output : network.outputs»
					«printXmlAXIstreamPorts(outputMap.get(output).toString(),"M")»
					«ENDFOR»
				</spirit:ports>
				<spirit:modelParameters>
					«printXmlAXIliteModelParameters("0","S")»
					«FOR input : network.inputs»
					«printXmlAXIstreamModelParameters(inputMap.get(input).toString(),"S")»
					«ENDFOR»
					«FOR output : network.outputs»
					«printXmlAXIstreamModelParameters(outputMap.get(output).toString(),"M")»
					«ENDFOR»
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
						<spirit:name>xgui/s_accelerator.tcl</spirit:name>
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
				«FOR input : network.inputs»
				«printXmlAXIstreamParameters(inputMap.get(input).toString(),"S")»
				«ENDFOR»
				«FOR output : network.outputs»
				«printXmlAXIstreamParameters(outputMap.get(output).toString(),"M")»
				«ENDFOR»
				<spirit:parameter>
					<spirit:name>Component_Name</spirit:name>
					<spirit:value spirit:resolve="user" spirit:id="PARAM_VALUE.Component_Name" spirit:order="1">s_accelerator</spirit:value>
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
					<xilinx:displayName>s_accelerator</xilinx:displayName>
					<xilinx:coreRevision>0</xilinx:coreRevision>
					<xilinx:coreCreationDateTime>2016-10-05T18:18:18Z</xilinx:coreCreationDateTime>
					<xilinx:tags>
						<xilinx:tag xilinx:name="user.org:user:s_accelerator:1.0_ARCHIVE_LOCATION">/home/csau/PRJ/vivado/vivado2015.4/ip_repo/s_accelerator</xilinx:tag>
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

	
	def printXmlAXIstreamParameters(String id, String type) {
		
		var String longId = id;
		if(Integer.parseInt(id)<10) {
			longId = "0" + id;
		}
		
		'''
		<spirit:parameter>
			<spirit:name>C_«type»«longId»_AXIS_TDATA_WIDTH</spirit:name>
			<spirit:displayName>C «type»«longId» AXIS TDATA WIDTH</spirit:displayName>
			<spirit:description>«IF type.equals("M")»Width of S_AXIS address bus. The slave accepts the read and write addresses of width C_M_AXIS_TDATA_WIDTH.«ELSE»AXI4Stream sink: Data Width«ENDIF»</spirit:description>
			<spirit:value spirit:format="long" spirit:resolve="user" spirit:id="PARAM_VALUE.C_«type»«longId»_AXIS_TDATA_WIDTH" spirit:choiceRef="choice_list_6fc15197" spirit:order="9">32</spirit:value>
			<spirit:vendorExtensions>
				<xilinx:parameterInfo>
					<xilinx:enablement>
						<xilinx:isEnabled xilinx:id="PARAM_ENABLEMENT.C_«type»«longId»_AXIS_TDATA_WIDTH">false</xilinx:isEnabled>
					</xilinx:enablement>
				</xilinx:parameterInfo>
			</spirit:vendorExtensions>
		</spirit:parameter>
		«IF type.equals("M")»<spirit:parameter>
			<spirit:name>C_«type»«longId»_AXIS_START_COUNT</spirit:name>
			<spirit:displayName>C «type»«longId» AXIS START COUNT</spirit:displayName>
			<spirit:description>Start count is the numeber of clock cycles the master will wait before initiating/issuing any transaction.</spirit:description>
			<spirit:value spirit:format="long" spirit:resolve="user" spirit:id="PARAM_VALUE.C_«type»«longId»_AXIS_START_COUNT" spirit:order="4" spirit:minimum="1" spirit:rangeType="long">32</spirit:value>
		</spirit:parameter>«ENDIF»
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
				<spirit:name>drivers/s_accelerator/data/s_accelerator.mdd</spirit:name>
				<spirit:userFileType>mdd</spirit:userFileType>
				<spirit:userFileType>driver_mdd</spirit:userFileType>
			</spirit:file>
			 <!--<spirit:file>
				<spirit:name>drivers/s_accelerator/data/s_accelerator.tcl</spirit:name>
				<spirit:fileType>tclSource</spirit:fileType>
				<spirit:userFileType>driver_tcl</spirit:userFileType>
			</spirit:file>
			<spirit:file>
				<spirit:name>drivers/s_accelerator/src/Makefile</spirit:name>
				<spirit:userFileType>driver_src</spirit:userFileType>
			</spirit:file>-->
			<spirit:file>
				<spirit:name>drivers/s_accelerator/src/s_accelerator_h.h</spirit:name>
				<spirit:fileType>cSource</spirit:fileType>
				<spirit:userFileType>driver_src</spirit:userFileType>
			</spirit:file>
			<spirit:file>
				<spirit:name>drivers/s_accelerator/src/s_accelerator_h.c</spirit:name>
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
				<spirit:name>hdl/front_end.v</spirit:name>
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
				<spirit:name>hdl/s_accelerator.v</spirit:name>
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
				<spirit:name>hdl/front_end.v</spirit:name>
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
				<spirit:name>hdl/s_accelerator.v</spirit:name>
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
	
	def printXmlAXIstreamModelParameters(String id, String type) {
		
		var String longId = id;
		if(Integer.parseInt(id)<10) {
			longId = "0" + id;
		}
		
		'''
		<spirit:modelParameter spirit:dataType="integer">
			<spirit:name>C_«type»«longId»_AXIS_TDATA_WIDTH</spirit:name>
			<spirit:displayName>C «type»«longId» AXIS TDATA WIDTH</spirit:displayName>
			<spirit:description>«IF type.equals("M")»Width of S_AXIS address bus. The slave accepts the read and write addresses of width C_M_AXIS_TDATA_WIDTH.«ELSE»AXI4Stream sink: Data Width«ENDIF»</spirit:description>
			<spirit:value spirit:format="long" spirit:resolve="generated" spirit:id="MODELPARAM_VALUE.C_«type»«longId»_AXIS_TDATA_WIDTH" spirit:order="3" spirit:rangeType="long">32</spirit:value>
		</spirit:modelParameter>
		«IF type.equals("M")»<spirit:modelParameter spirit:dataType="integer">
			<spirit:name>C_«type»«longId»_AXIS_START_COUNT</spirit:name>
			<spirit:displayName>C «type»«longId» AXIS START COUNT</spirit:displayName>
			<spirit:description>Start count is the numeber of clock cycles the master will wait before initiating/issuing any transaction.</spirit:description>
			<spirit:value spirit:format="long" spirit:resolve="generated" spirit:id="MODELPARAM_VALUE.C_«type»«longId»_AXIS_START_COUNT" spirit:order="4" spirit:minimum="1" spirit:rangeType="long">32</spirit:value>
		</spirit:modelParameter>«ENDIF»
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
	
	def printXmlAXIstreamPorts(String id, String type) {
		
		var String longId = id;
		if(Integer.parseInt(id)<10) {
			longId = "0" + id;
		}
		
		var boolean reverseDir = type=="M";
		
		'''
		<spirit:port>
			<spirit:name>«type.toLowerCase()»«longId»_axis_aclk</spirit:name>
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
			<spirit:name>«type.toLowerCase()»«longId»_axis_aresetn</spirit:name>
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
		«FOR port : AXIstreamPorts.keySet»
		<spirit:port>
			<spirit:name>«type.toLowerCase()»«longId»_axis_«port.toLowerCase()»</spirit:name>
			<spirit:wire>
			<spirit:direction>«IF reverseDir»«getReverseDirection(AXIstreamPorts.get(port))»«ELSE»«getDirection(AXIstreamPorts.get(port))»«ENDIF»</spirit:direction>
				«IF AXIstreamPorts.get(port).contains("bus")»<spirit:vector>
					<spirit:left spirit:format="long"«IF hasParameter(AXIstreamPorts.get(port))» spirit:resolve="dependent" spirit:dependency="(spirit:decode(id(&apos;MODELPARAM_VALUE.C_«type»«longId»_AXIS_«getParameter(AXIstreamPorts.get(port))»&apos;)) - 1)"«ENDIF»>«getDefaultValue(AXIstreamPorts.get(port))-1»</spirit:left>
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
		«IF type.equals("S")»
		<spirit:port>
			<spirit:name>«type.toLowerCase()»«longId»_axis_data_count</spirit:name>
			<spirit:wire>
			<spirit:direction>in</spirit:direction>
				<spirit:vector>
					<spirit:left spirit:format="long">31</spirit:left>
					<spirit:right spirit:format="long">0</spirit:right>
				</spirit:vector>
				<spirit:wireTypeDefs>
					<spirit:wireTypeDef>
						<spirit:typeName>reg</spirit:typeName>
						<spirit:viewNameRef>xilinx_anylanguagesynthesis</spirit:viewNameRef>
						<spirit:viewNameRef>xilinx_anylanguagebehavioralsimulation</spirit:viewNameRef>
					</spirit:wireTypeDef>
				</spirit:wireTypeDefs>
			</spirit:wire>
		</spirit:port>
		«ENDIF»
		'''
	}
	
	
	def printXmlView(String name, String display_name, String id, String language, String fileSetRef) {
		'''
		<spirit:view>
			<spirit:name>«name»</spirit:name>
			<spirit:displayName>«display_name»</spirit:displayName>
			<spirit:envIdentifier>«id»</spirit:envIdentifier>
			«IF !language.equals("")»<spirit:language>«language»</spirit:language>«ENDIF»
			<spirit:modelName>s_accelerator</spirit:modelName>
			<spirit:fileSetRef>
				<spirit:localName>«fileSetRef»</spirit:localName>
			</spirit:fileSetRef>
		</spirit:view>
		'''
	}
	
	def printXmlAXIliteRegMemoryMap(String id, String type) {
		
		var String longId = id;
		if(Integer.parseInt(id)<10) {
			longId = "0" + id;
		}
		
		'''
		<spirit:memoryMap>
			<spirit:name>«type»«longId»_AXI</spirit:name>
			<spirit:addressBlock>
				<spirit:name>«type»«longId»_AXI_reg</spirit:name>
				<spirit:baseAddress spirit:format="long" spirit:resolve="user">0</spirit:baseAddress>
				<spirit:range spirit:format="long">4096</spirit:range>
				<spirit:width spirit:format="long">32</spirit:width>
				<spirit:usage>register</spirit:usage>
				<spirit:parameters>
					<spirit:parameter>
						<spirit:name>OFFSET_BASE_PARAM</spirit:name>
						<spirit:value spirit:id="ADDRBLOCKPARAM_VALUE.«type»«longId»_AXI.«type»«longId»_AXI_REG.OFFSET_BASE_PARAM" spirit:dependency="ADDRBLOCKPARAM_VALUE.«type»«longId»_AXI_reg.OFFSET_BASE_PARAM">0</spirit:value>
					</spirit:parameter>
					<spirit:parameter>
						<spirit:name>OFFSET_HIGH_PARAM</spirit:name>
						<spirit:value spirit:id="ADDRBLOCKPARAM_VALUE.«type»«longId»_AXI.«type»«longId»_AXI_REG.OFFSET_HIGH_PARAM" spirit:dependency="ADDRBLOCKPARAM_VALUE.«type»«longId»_AXI_reg.OFFSET_HIGH_PARAM">0</spirit:value>
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
	
	
	def printXmlAXIstreamBusInterface(String id, String type) {
		
		var int data_width = 32;
		var String longId = id;
		if(Integer.parseInt(id)<10) {
			longId = "0" + id;
		}
		
		'''
		<spirit:busInterface>
			<spirit:name>«type»«longId»_AXIS</spirit:name>
			<spirit:busType spirit:vendor="xilinx.com" spirit:library="interface" spirit:name="axis" spirit:version="1.0"/>
			<spirit:abstractionType spirit:vendor="xilinx.com" spirit:library="interface" spirit:name="axis_rtl" spirit:version="1.0"/>
			<spirit:«IF type.equals("S")»slave«ELSE»master«ENDIF»/>
			<spirit:portMaps>
				«FOR port : AXIstreamPorts.keySet»
				«printXmlPortMap(port,type.toLowerCase()+longId+"_axis_"+port.toLowerCase())»
				«ENDFOR»
			</spirit:portMaps>
			<spirit:parameters>
			<spirit:parameter>
				<spirit:name>WIZ_DATA_WIDTH</spirit:name>
				<spirit:value spirit:format="long" spirit:id="BUSIFPARAM_VALUE.«type»«longId»_AXIS.WIZ_DATA_WIDTH" spirit:choiceRef="choice_list_6fc15197">«data_width»</spirit:value>
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
			«FOR input : inputMap.keySet»
			set C_S«getLongId(inputMap.get(input))»_AXIS_TDATA_WIDTH [ipgui::add_param $IPINST -name "C_S«getLongId(inputMap.get(input))»_AXIS_TDATA_WIDTH" -parent ${Page_0} -widget comboBox]
			set_property tooltip {AXI4Stream sink: Data Width} ${C_S«getLongId(inputMap.get(input))»_AXIS_TDATA_WIDTH}
			«ENDFOR»
			«FOR output : outputMap.keySet»
			set C_M«getLongId(outputMap.get(output))»_AXIS_TDATA_WIDTH [ipgui::add_param $IPINST -name "C_M«getLongId(outputMap.get(output))»_AXIS_TDATA_WIDTH" -parent ${Page_0} -widget comboBox]
			set_property tooltip {Width of S_AXIS address bus. The slave accepts the read and write addresses of width C_M_AXIS_TDATA_WIDTH.} ${C_M«getLongId(outputMap.get(output))»_AXIS_TDATA_WIDTH}
			set C_M«getLongId(outputMap.get(output))»_AXIS_START_COUNT [ipgui::add_param $IPINST -name "C_M«getLongId(outputMap.get(output))»_AXIS_START_COUNT" -parent ${Page_0}]
			set_property tooltip {Start count is the numeber of clock cycles the master will wait before initiating/issuing any transaction.} ${C_M«getLongId(outputMap.get(output))»_AXIS_START_COUNT}
  			«ENDFOR»
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

		«FOR input : inputMap.keySet»
		proc update_PARAM_VALUE.C_S«getLongId(inputMap.get(input))»_AXIS_TDATA_WIDTH { PARAM_VALUE.C_S«getLongId(inputMap.get(input))»_AXIS_TDATA_WIDTH } {
			# Procedure called to update C_S«getLongId(inputMap.get(input))»_AXIS_TDATA_WIDTH when any of the dependent parameters in the arguments change
		}

		proc validate_PARAM_VALUE.C_S«getLongId(inputMap.get(input))»_AXIS_TDATA_WIDTH { PARAM_VALUE.C_S«getLongId(inputMap.get(input))»_AXIS_TDATA_WIDTH } {
			# Procedure called to validate C_S«getLongId(inputMap.get(input))»_AXIS_TDATA_WIDTH
			return true
		}
		«ENDFOR»

		«FOR output : outputMap.keySet»
		proc update_PARAM_VALUE.C_M«getLongId(outputMap.get(output))»_AXIS_TDATA_WIDTH { PARAM_VALUE.C_M«getLongId(outputMap.get(output))»_AXIS_TDATA_WIDTH } {
			# Procedure called to update C_M«getLongId(outputMap.get(output))»_AXIS_TDATA_WIDTH when any of the dependent parameters in the arguments change
		}
		
		proc validate_PARAM_VALUE.C_M«getLongId(outputMap.get(output))»_AXIS_TDATA_WIDTH { PARAM_VALUE.C_M«getLongId(outputMap.get(output))»_AXIS_TDATA_WIDTH } {
			# Procedure called to validate C_M«getLongId(outputMap.get(output))»_AXIS_TDATA_WIDTH
			return true
		}
		
		proc update_PARAM_VALUE.C_M«getLongId(outputMap.get(output))»_AXIS_START_COUNT { PARAM_VALUE.C_M«getLongId(outputMap.get(output))»_AXIS_START_COUNT } {
			# Procedure called to update C_M«getLongId(outputMap.get(output))»_AXIS_START_COUNT when any of the dependent parameters in the arguments change
		}
		
		proc validate_PARAM_VALUE.C_M«getLongId(outputMap.get(output))»_AXIS_START_COUNT { PARAM_VALUE.C_M«getLongId(outputMap.get(output))»_AXIS_START_COUNT } {
			# Procedure called to validate C_M«getLongId(outputMap.get(output))»_AXIS_START_COUNT
			return true
		}
		«ENDFOR»
		
		# Model Parameters
		proc update_MODELPARAM_VALUE.C_S00_AXI_DATA_WIDTH { MODELPARAM_VALUE.C_S00_AXI_DATA_WIDTH PARAM_VALUE.C_S00_AXI_DATA_WIDTH } {
			# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
			set_property value [get_property value ${PARAM_VALUE.C_S00_AXI_DATA_WIDTH}] ${MODELPARAM_VALUE.C_S00_AXI_DATA_WIDTH}
		}
		
		proc update_MODELPARAM_VALUE.C_S00_AXI_ADDR_WIDTH { MODELPARAM_VALUE.C_S00_AXI_ADDR_WIDTH PARAM_VALUE.C_S00_AXI_ADDR_WIDTH } {
			# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
			set_property value [get_property value ${PARAM_VALUE.C_S00_AXI_ADDR_WIDTH}] ${MODELPARAM_VALUE.C_S00_AXI_ADDR_WIDTH}
		}

		«FOR input : inputMap.keySet»
		proc update_MODELPARAM_VALUE.C_S«getLongId(inputMap.get(input))»_AXIS_TDATA_WIDTH { MODELPARAM_VALUE.C_S«getLongId(inputMap.get(input))»_AXIS_TDATA_WIDTH PARAM_VALUE.C_S«getLongId(inputMap.get(input))»_AXIS_TDATA_WIDTH } {
			# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
			set_property value [get_property value ${PARAM_VALUE.C_S«getLongId(inputMap.get(input))»_AXIS_TDATA_WIDTH}] ${MODELPARAM_VALUE.C_S«getLongId(inputMap.get(input))»_AXIS_TDATA_WIDTH}
		}
		«ENDFOR»


		«FOR output : outputMap.keySet»
		proc update_MODELPARAM_VALUE.C_M«getLongId(outputMap.get(output))»_AXIS_TDATA_WIDTH { MODELPARAM_VALUE.C_M«getLongId(outputMap.get(output))»_AXIS_TDATA_WIDTH PARAM_VALUE.C_M«getLongId(outputMap.get(output))»_AXIS_TDATA_WIDTH } {
			# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
			set_property value [get_property value ${PARAM_VALUE.C_M«getLongId(outputMap.get(output))»_AXIS_TDATA_WIDTH}] ${MODELPARAM_VALUE.C_M«getLongId(outputMap.get(output))»_AXIS_TDATA_WIDTH}
		}
		
		proc update_MODELPARAM_VALUE.C_M«getLongId(outputMap.get(output))»_AXIS_START_COUNT { MODELPARAM_VALUE.C_M«getLongId(outputMap.get(output))»_AXIS_START_COUNT PARAM_VALUE.C_M«getLongId(outputMap.get(output))»_AXIS_START_COUNT } {
			# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
			set_property value [get_property value ${PARAM_VALUE.C_M«getLongId(outputMap.get(output))»_AXIS_START_COUNT}] ${MODELPARAM_VALUE.C_M«getLongId(outputMap.get(output))»_AXIS_START_COUNT}
		}
		«ENDFOR»
		'''
	}
	
	def printMdd() {
		'''
		OPTION psf_version = 2.1;

		BEGIN DRIVER s_accelerator
			OPTION supported_peripherals = (s_accelerator);
			OPTION copyfiles = all;
			OPTION VERSION = 1.0;
			OPTION NAME = s_accelerator;
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
		*  Filename:          s_accelerator_h.c
		*  Description:       Stream Accelerator High Level Driver
		*  Date:              «dateFormat.format(date)» (by Multi-Dataflow Composer - Platform Composer)
		*****************************************************************************/
		
		#include "s_accelerator_h.h"

		«FOR net : networkVertexMap.keySet SEPARATOR "\n"»
		int s_accelerator_«net»(
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
			
			// stop execution
			*((int*) S_ACCELERATOR_CFG_BASEADDR) = 0x«Integer.toHexString(0)»;
			
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
		*  Filename:          s_accelerator_h.h
		*  Description:       Stream Accelerator High Level Driver Header
		*  Date:              «dateFormat.format(date)» (by Multi-Dataflow Composer - Platform Composer)
		*****************************************************************************/
		
		#ifndef S_ACCELERATOR_H_H
		#define S_ACCELERATOR_H_H
		
		/***************************** Include Files *******************************/		
		#include "xparameters.h"
		«IF !useDMA»#include "fsl.h"«ENDIF»
		
		/************************** Constant Definitions ***************************/
		#define S_ACCELERATOR_CFG_BASEADDR 0x44A00000
		
		/************************* Functions Definitions ***************************/
		
		
		«FOR net : networkVertexMap.keySet»
		int s_accelerator_«net»(
			«FOR port : netIdPortMap.get(net) SEPARATOR ","»
			// port «port.name»
			int size_«portMap.get(port)», int* data_«portMap.get(port)»
			«ENDFOR»
		);
		«ENDFOR»
		
		#endif /** S_ACCELERATOR_H_H */
		'''
	}	
	

}