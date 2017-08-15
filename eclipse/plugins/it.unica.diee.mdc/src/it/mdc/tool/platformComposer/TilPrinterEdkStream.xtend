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
import net.sf.orcc.df.Portimport net.sf.orcc.df.Actor
import it.mdc.tool.ConfigManager

/*
 * EDK Template Interface Layer 
 * Stream HW Accelerator Printer
 * 
 * @author Carlo Sau
 */
class TilPrinterEdkStream extends TilPrinter{

	override printHdlSource(Network network, String module) {
		if(module.equals("TOP")) {
			printTop(network);
		} else if(module.equals("CFG_REGS")) {
			printRegs();
		} else if(module.equals("REGS_BANK")) {
			printRegBank();
		} else if(module.equals("CLEAR")) {
			printClLogic();
		} else if(module.equals("TBENCH")) {
			printTestBench();
		} else if(module.equals("WRAP")) {
			printWrapper();
		}
	}
	
	def printTop(Network network){
		
		mapInOut(network);
		mapSignals();
		
		'''	
		«printTopHeaderComments()»
		
		// ----------------------------------------------------------------------------
		// Module Interface
		// ----------------------------------------------------------------------------
		«printTopInterface()»
		
		// ----------------------------------------------------------------------------
		// Module Parameters
		// ----------------------------------------------------------------------------
		«printTopParameters()»
		
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
	
	def printTopInterface() {
		
		'''
		module coprocessor(
			«FOR port : inputMap.keySet()»
			FSL«inputMap.get(port)»_S_DATA,		// FSL«inputMap.get(port)» slave data channel (port «port.name»)
			FSL«inputMap.get(port)»_S_CTRL, 	// FSL«inputMap.get(port)» slave control channel (port «port.name»)
			FSL«inputMap.get(port)»_S_READ, 	// FSL«inputMap.get(port)» slave read data channel (port «port.name»)
			FSL«inputMap.get(port)»_S_EXISTS,	// FSL«inputMap.get(port)» slave exists data channel (port «port.name»)
			«ENDFOR»
			«FOR port : outputMap.keySet()»
			FSL«outputMap.get(port)»_M_DATA,	// FSL«outputMap.get(port)» master data channel (port «port.name»)
			FSL«outputMap.get(port)»_M_CTRL, 	// FSL«outputMap.get(port)» master control channel (port «port.name»)
			FSL«outputMap.get(port)»_M_WRITE, 	// FSL«outputMap.get(port)» master write data channel (port «port.name»)
			FSL«outputMap.get(port)»_M_FULL,	// FSL«outputMap.get(port)» master full channel (port «port.name»)
			«ENDFOR»
			clk,					// system clock
			rst						// system reset
		);
		'''
	}
	
	def printTopParameters() {
		'''

		parameter SIZEID = 8;				// size of Kernel ID signal
		parameter SIZEADDRESS = 12;			// size of the local memory address signal
		parameter SIZECOUNT = 12;			// size of the size counters
		parameter SIZEPORT = «portSize»;	// bits needed to codify the number of ports
		parameter SIZEDATA = «dataSize»;	// size of the data signal
		parameter SIZEBURST = 8;			// size of the burst counter
		parameter SIZESIGNAL = 1; 			// size of the control signals
		parameter FIFO_DEPTH = 4; 			//	FIFO depth
		parameter NUM_OUTS = «outputMap.size»; 			//	number of output ports
		
		'''
	}	
		
	def printTopSignals() {
		
		'''
		// Input(s)
		input 						clk;
		input 						rst;
		«FOR port : inputMap.keySet()»
		input [31 : 0]				FSL«inputMap.get(port)»_S_DATA;
		input 						FSL«inputMap.get(port)»_S_CTRL;
		input						FSL«inputMap.get(port)»_S_EXISTS;
		«ENDFOR»
		«FOR port : outputMap.keySet()»
		input						FSL«outputMap.get(port)»_M_FULL;
		«ENDFOR»
		
		// Ouptut(s)
		«FOR port : inputMap.keySet()»
		output 						FSL«inputMap.get(port)»_S_READ;
		«ENDFOR»
		«FOR port : outputMap.keySet()»
		output [31 : 0]				FSL«outputMap.get(port)»_M_DATA;
		output 						FSL«outputMap.get(port)»_M_CTRL;
		output						FSL«outputMap.get(port)»_M_WRITE;
		«ENDFOR»
		
		// Wire(s) and Reg(s)
		// Input Wire(s)
		wire 						clk;
		wire 						rst;
		«FOR port : inputMap.keySet()»
		wire [31 : 0]				FSL«inputMap.get(port)»_S_DATA;
		wire 						FSL«inputMap.get(port)»_S_CTRL;
		wire						FSL«inputMap.get(port)»_S_EXISTS;
		«ENDFOR»
		«FOR port : outputMap.keySet()»
		wire						FSL«outputMap.get(port)»_M_FULL;
		«ENDFOR»
		
		// Output Wire(s)
		«FOR port : inputMap.keySet()»
		wire 						FSL«inputMap.get(port)»_S_READ;
		«ENDFOR»
		«FOR port : outputMap.keySet()»
		wire [31 : 0]				FSL«outputMap.get(port)»_M_DATA;
		wire 						FSL«outputMap.get(port)»_M_CTRL;
		wire						FSL«outputMap.get(port)»_M_WRITE;
		«ENDFOR»

		// Internal Wire(s)
		wire 						rd_FSMctrl;
		wire [SIZEID-1 : 0] 		kernelIDout;
		«FOR port : portMap.keySet»
		wire [SIZECOUNT-1 : 0] 		size_«portMap.get(port)»;
		«ENDFOR»
		«FOR input : inputMap.keySet»
		wire [SIZEBURST-1 : 0] 		sizeburst_«inputMap.get(input)»;
		«ENDFOR»
		«FOR output : outputMap.keySet»
		wire 						endsend«outputMap.get(output)»;
		wire [«output.type.sizeInBits-1» : 0] 					Out«outputMap.get(output)»;
		«ENDFOR»
		wire 						start;			
		wire 						clear;
		
		// Reconfigurable Datapath Wire(s)		
		«FOR input : inputMap.keySet()»
		wire 						IN_send«inputMap.get(input)»; 
		wire 						OUT_ack«inputMap.get(input)»;
		wire						OUT_rdy«inputMap.get(input)»; 
		wire [SIZEBURST-1 : 0] 		IN_count«inputMap.get(input)»;
		«ENDFOR»
		// to adapt profiling		
		«FOR output : outputMap.keySet()»		
		wire 						OUT_send«outputMap.get(output)»;
		wire 						IN_ack«outputMap.get(output)»;
		wire						IN_rdy«outputMap.get(output)»;
		«ENDFOR»
		'''
		
	}	
	
	def printTopBody() {
		
		'''
		// Configuration Registers
		// ----------------------------------------------------------------------------
		// (manage the interface with the processor)
		Registers #( 
			.SIZEID(SIZEID),
			.SIZEADDRESS(SIZEADDRESS),
			.SIZECOUNT(SIZECOUNT),
			.SIZEBURST(SIZEBURST),
			.SIZEDATA(SIZEDATA) )
		config_registers(
			.clk(clk),
			.reset(rst),
			«FOR port : portMap.keySet()»
			.size_«portMap.get(port)»(size_«portMap.get(port)»),
			«ENDFOR»
			«FOR port : inputMap.keySet()»
			.sizeburst_«portMap.get(port)»(sizeburst_«portMap.get(port)»),
			«ENDFOR»
			.din(FSL0_S_DATA),
			.clearKernelID(clear),
			.exists(FSL0_S_EXISTS),
			.start(start),
			.DC(FSL0_S_CTRL),
			.RD(rd_FSMctrl),
			.kernelIDout(kernelIDout)
		);
		// ----------------------------------------------------------------------------	
			
		// Coprocessor Front-End(s)
		// ----------------------------------------------------------------------------
		«FOR input : inputMap.keySet()»
		front_end #( 
			.SIZECOUNT(SIZECOUNT),
			.SIZEBURST(SIZEBURST),
			.SIZESIGNAL(SIZESIGNAL)	)
		Front_End_«inputMap.get(input)»(
			.FSL_S_READ(FSL«inputMap.get(input)»_S_READ),
			.FSL_S_EXISTS(FSL«inputMap.get(input)»_S_EXISTS),
			.clear(clear),
			.rd_FSMctrl(«IF inputMap.get(input)==0»rd_FSMctrl«ELSE»1'b0«ENDIF»),
			.start(start),
			.size(size_«portMap.get(input)»),
			.sizeburst(sizeburst_«portMap.get(input)»),
			.IN_send(IN_send«portMap.get(input)»),
			.OUT_rdy(OUT_rdy«portMap.get(input)»),
			.IN_count(IN_count«portMap.get(input)»),
			.clk(clk),
			.rst(rst)
		);
		«ENDFOR»
		// ----------------------------------------------------------------------------
			
		// Multi-Dataflow Reconfigurable Datapath
		// ----------------------------------------------------------------------------
		«printTopDatapath()»
		// ----------------------------------------------------------------------------	
		
		// Coprocessor Back-End(s)
		// ----------------------------------------------------------------------------
		«FOR output : outputMap.keySet()»
		assign FSL«outputMap.get(output)»_M_CTRL=1'b0;

		back_end #( 
			.SIZECOUNT(SIZECOUNT),
			.SIZESIGNAL(SIZESIGNAL)	)
		Back_End_«outputMap.get(output)»(
			.clk(clk),
			.rst(rst),
			.FSL_M_WRITE(FSL«outputMap.get(output)»_M_WRITE),
			.FSL_M_FULL(FSL«outputMap.get(output)»_M_FULL),
			.clear(clear),
			.size(size_«portMap.get(output)»),
			.endsend(endsend«outputMap.get(output)»),
			.OUT_send(OUT_send«outputMap.get(output)»),
			.IN_ack(IN_ack«outputMap.get(output)»),
			.IN_rdy(IN_rdy«outputMap.get(output)»)
		);
		«ENDFOR»
		cl_logic	#(
			.NUM_OUTS(NUM_OUTS)	)
		Clear_logic(
			.clk(clk),
			.rst(rst),
			«FOR output : outputMap.keySet()»
			.endsend«outputMap.get(output)»(endsend«outputMap.get(output)»),
			«ENDFOR»
			.clear(clear)
		);
		
		// ----------------------------------------------------------------------------
		'''
	}
	
	def printTopDatapath() {
		'''
		// to adapt profiling
		multi_dataflow reconf_dpath (
			// Multi-Dataflow Input(s)
			«FOR input : inputMap.keySet()»	.«input.getName()»_data(FSL«inputMap.get(input)»_S_DATA«IF input.type.sizeInBits!=32»[«input.type.sizeInBits-1»:0]«ENDIF»),
			.«input.getName()»_send(IN_send«portMap.get(input)»),
			.«input.getName()»_ack(OUT_ack«portMap.get(input)»),
			.«input.getName()»_rdy(OUT_rdy«portMap.get(input)»),
			.«input.getName()»_count({{8'b0},IN_count«portMap.get(input)»}),
			«ENDFOR»
			// Multi-Dataflow Output(s)
			«FOR output : outputMap.keySet()»	.«output.getName()»_data(Out«outputMap.get(output)»),
			.«output.getName()»_send(OUT_send«outputMap.get(output)»),
			.«output.getName()»_ack(IN_ack«outputMap.get(output)»),
			.«output.getName()»_rdy(IN_rdy«outputMap.get(output)»),
			.«output.getName()»_count(),
			«ENDFOR»
			// Multi-Dataflow Clock and Reset
			.CLK(clk),
			.RESET(rst),
			// Multi-Dataflow Kernel ID
			.ID(kernelIDout)	
		);
		
		«FOR output : outputMap.keySet()»
		assign FSL«outputMap.get(output)»_M_DATA = «IF output.type.sizeInBits!=32»{«32-output.type.sizeInBits»'b0,Out«outputMap.get(output)»}«ELSE»Out«outputMap.get(output)»«ENDIF»;
		«ENDFOR»
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
	
	def printRegBank(){
		var dateFormat = new SimpleDateFormat("yyyy/MM/dd HH:mm:ss");
		var date = new Date();
		
		'''
		// ----------------------------------------------------------------------------
		//
		// Multi-Dataflow Composer tool - Platform Composer
		// Register Bank module 
		// Date: «dateFormat.format(date)»
		//
		// ----------------------------------------------------------------------------
		
		// ----------------------------------------------------------------------------
		// Module Interface
		// ----------------------------------------------------------------------------
		module cfg_regs(
			clk,
			reset,
			din,
			pointer,
			write,
			clearKernelID,
			«FOR port : portMap.keySet()»
			size_«portMap.get(port)»,
			«IF !outputMap.containsKey(port)»sizeburst_«portMap.get(port)»,«ENDIF»
			«ENDFOR»
			kernelIDout
		);
		// ----------------------------------------------------------------------------
		
		// ----------------------------------------------------------------------------
		// Module Parameters
		// ----------------------------------------------------------------------------
		parameter SIZE_PTR = 2;
		parameter SIZEID = 8;
		parameter SIZECOUNT = 12;
		parameter SIZEBURST = 8;
		parameter SIZEDATA = 32;
		parameter SIZEADDRESS = 12;
		// ----------------------------------------------------------------------------
		
		// ----------------------------------------------------------------------------
		// Module Signals
		// ----------------------------------------------------------------------------	
		// Input(s)
		input						clk;
		input						reset;
		input [SIZEDATA-1 : 0]		din;
		input [SIZE_PTR-1 : 0]		pointer;
		input						write;
		input						clearKernelID;
		
		// Ouput(s)
		«FOR port : portMap.keySet()»
		output [SIZECOUNT-1 : 0]	size_«portMap.get(port)»;
		«IF !outputMap.containsKey(port)»output [SIZEBURST-1 : 0]	sizeburst_«portMap.get(port)»;«ENDIF»
		«ENDFOR»
		output [SIZEID-1 : 0]		kernelIDout;
		
		// Input Wire(s)
		wire						clk;
		wire						reset;
		wire [SIZEDATA-1 : 0]		din;
		wire [SIZE_PTR-1 : 0]				pointer;
		wire						write;
		wire						clearKernelID;
		
		// Ouput Reg(s)
		«FOR port : portMap.keySet()»
		reg [SIZECOUNT-1 : 0]	size_«portMap.get(port)»;
		«IF !outputMap.containsKey(port)»reg [SIZEBURST-1 : 0]	sizeburst_«portMap.get(port)»;«ENDIF»
		«ENDFOR»
		reg [SIZEID-1 : 0]		kernelIDout;
		
		// Internal Wire(s)
		«FOR port : portMap.keySet()»
		wire					wr_port«portMap.get(port)»;
		«ENDFOR»
		wire					wr_kernelID;
		// ----------------------------------------------------------------------------			  	
						
		// ----------------------------------------------------------------------------
		// Body
		// ----------------------------------------------------------------------------
		«FOR port : portMap.keySet()»
		// Size port «port» (id=«portMap.get(port)»)
		always @(posedge clk or posedge reset)
		begin
			if (reset)
				size_«portMap.get(port)» <= 0;
			else if (wr_port«portMap.get(port)»)
				size_«portMap.get(port)» <= din[SIZECOUNT-1+SIZEADDRESS : SIZEADDRESS];
			end
			
		«IF !outputMap.containsKey(port)»
		// Sizeburst port «port» (id=«portMap.get(port)»)
		always @(posedge clk or posedge reset)
		begin
			if (reset)
				sizeburst_«portMap.get(port)» <= 0;
			else if (wr_port«portMap.get(port)»)
				sizeburst_«portMap.get(port)» <= din[SIZEBURST-1+SIZECOUNT+SIZEADDRESS : SIZECOUNT+SIZEADDRESS];
			end
			
		«ENDIF»
		«ENDFOR»
		
		// Kernel ID
		always @(posedge clk or posedge reset)
		begin
			if (reset)
				kernelIDout <= 0;
			else if (clearKernelID)
				kernelIDout <= 0;
		  	else if (wr_kernelID)	  
		           kernelIDout <= din[SIZEID-1 : 0];
		end
		
		// Write Demux
		«FOR port : portMap.keySet()»		
		assign wr_port«portMap.get(port)» = (pointer==«portMap.get(port)») ? write : 0;
		«ENDFOR»
		assign wr_kernelID = (pointer==«portMap.size») ? write : 0;
		// ----------------------------------------------------------------------------
		
		endmodule		
		// ----------------------------------------------------------------------------
		// ----------------------------------------------------------------------------
		// ----------------------------------------------------------------------------
		'''
	}
	
	def printClLogic() {
		
		var dateFormat = new SimpleDateFormat("yyyy/MM/dd HH:mm:ss");
		var date = new Date();
		
		'''
		`timescale 1ns / 1ps
		// ----------------------------------------------------------------------------
		//
		// Multi-Dataflow Composer tool - Platform Composer
		// Clear Logic
		// Date: «dateFormat.format(date)»
		//
		// ----------------------------------------------------------------------------	
		
		// ----------------------------------------------------------------------------
		// Module Interface
		// ----------------------------------------------------------------------------
		module cl_logic(
			clk,			// system clock
			rst,			// system reset
				«FOR output : outputMap.keySet»endsend«outputMap.get(output)»,		// output «outputMap.get(output)» endsend
	 		«ENDFOR»
			clear
			);
		// ----------------------------------------------------------------------------
		
		// ----------------------------------------------------------------------------
		// Module Parameters
		// ----------------------------------------------------------------------------
		parameter NUM_OUTS = 2;
		// ----------------------------------------------------------------------------
		
		// ----------------------------------------------------------------------------
		// Module Signals
		// ----------------------------------------------------------------------------
		// Input(s)
		input 				clk;
		input 				rst;
		«FOR output : outputMap.keySet»
		input 				endsend«outputMap.get(output)»;
	 	«ENDFOR»
		// Output(s)
		output				clear;
		
		// I/O Wire(s)
		wire 				clk;
		wire 				rst;
		«FOR output : outputMap.keySet»
		wire 				endsend«outputMap.get(output)»;
	 	«ENDFOR»

		// I/O Reg(s)
		reg 				clear;
		
		// Internal Wire(s)
		wire [NUM_OUTS-1:0] endsend;
		// ----------------------------------------------------------------------------
		
		// ----------------------------------------------------------------------------
		// Body
		// ----------------------------------------------------------------------------
		assign endsend = {
		«FOR output : outputMap.keySet SEPARATOR ",\n"»		endsend«outputMap.get(output)»«ENDFOR»
		};

		// Clear Generation
		always @(posedge clk or posedge rst)
			if(rst) 
				clear <= 0;
			else 	
				clear <= &endsend;
		// ----------------------------------------------------------------------------
		
		endmodule		
		// ----------------------------------------------------------------------------
		// ----------------------------------------------------------------------------
		// ----------------------------------------------------------------------------'''
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
		module Registers(
			clk,				// system clock
			reset,				// system reset
			din,				// input data (from FSL)
			clearKernelID,		// clear kernel ID
			exists,				// exist data (from FSL)
			start,				// output start flag
			DC,
			RD,
			«FOR port : portMap.keySet()»size_«portMap.get(port)»,
			«IF !outputMap.containsKey(port)»sizeburst_«portMap.get(port)»,«ENDIF»
			«ENDFOR»
			kernelIDout		//Uscita registro kernel ID
		);
		// ----------------------------------------------------------------------------
		
		// ----------------------------------------------------------------------------
		// Module Parameters
		// ----------------------------------------------------------------------------			  
		parameter SIZEID = 8;
		parameter SIZEADDRESS = 12;
		parameter SIZECOUNT = 12;
		parameter SIZEBURST = 8;
		parameter SIZEDATA = 32;
		// ----------------------------------------------------------------------------			  
		
		// ----------------------------------------------------------------------------
		// Module Signals
		// ----------------------------------------------------------------------------	
		// Input(s)
		input 						clk;
		input 						reset;
		input [SIZEDATA-1 : 0]		din;
		input 						clearKernelID;
		input						exists;
		input						DC;
		
		// Output(s)
		output						start;
		output						RD;
		«FOR port : portMap.keySet()»
		output [SIZECOUNT-1 : 0] 	size_«portMap.get(port)»;
		«IF !outputMap.containsKey(port)»output [SIZEBURST-1 : 0] 	sizeburst_«portMap.get(port)»;«ENDIF»
		«ENDFOR»
		output [SIZEID-1 : 0] 		kernelIDout;
		
		// Input Wire(s)
		wire 						clk;
		wire 						reset;
		wire [SIZEDATA-1 : 0]		din;
		wire 						clearKernelID;
		wire						exists;
		wire						DC;
		
		// Output Wire(s)
		wire						start;
		wire						RD;
		«FOR port : portMap.keySet()»
		wire [SIZECOUNT-1 : 0] 	size_«portMap.get(port)»;
		«IF !outputMap.containsKey(port)»wire [SIZEBURST-1 : 0] 	sizeburst_«portMap.get(port)»;«ENDIF»
		«ENDFOR»
		wire [SIZEID-1 : 0] 		kernelIDout;
		
		// Internal Wire(s)
		wire [«size_pointer-1» : 0] 				pointer; // verify size!!!!
		// ----------------------------------------------------------------------------			  
		
		// ----------------------------------------------------------------------------
		// Body
		// ----------------------------------------------------------------------------	
		// Configuration Register Bank
		cfg_regs #(
			.SIZEID(SIZEID),
			.SIZECOUNT(SIZECOUNT),
			.SIZEBURST(SIZEBURST),
			.SIZEDATA(SIZEDATA),
			.SIZEADDRESS(SIZEADDRESS),
			.SIZE_PTR(«size_pointer»)
		) registers (
			.clk(clk),
			.reset(reset),
			.din(din),
			.pointer(pointer),
			.write(write),
			.clearKernelID(clearKernelID),
			«FOR port : portMap.keySet()»
			.size_«portMap.get(port)»(size_«portMap.get(port)»),
			«IF !outputMap.containsKey(port)».sizeburst_«portMap.get(port)»(sizeburst_«portMap.get(port)»),«ENDIF»
			«ENDFOR»
			.kernelIDout(kernelIDout)
		);
		
		// Configuration Register Pointer
		cfg_cnt #(
			.MAX_CNT(«portMap.size»),
			.SIZE_PTR(«size_pointer»)
		)pointer_cnt(
			.clk(clk),
			.reset(reset),	
			.go(write),
			.pointer(pointer),
			.endldcr(endldcr)
		);
		
		// Configuration Register Finite State Machine
		cfg_FSM fsm(
			.clk(clk),
			.reset(reset),
				.exists(exists),
			.start(start),
			.DC(DC),
			.endldcr(endldcr),
			.RD(RD),
			.write(write)
		);
		
		// Start Flag Register
		Start_Network  #(
			.SIZEID(SIZEID)
		) startin (
			.kernelID(kernelIDout),
			.start(start)
		);
		// ----------------------------------------------------------------------------
		
		endmodule		
		// ----------------------------------------------------------------------------
		// ----------------------------------------------------------------------------
		// ----------------------------------------------------------------------------
		'''
	}
		
	def printWrapper(){
		
		var dateFormat = new SimpleDateFormat("yyyy/MM/dd HH:mm:ss");
		var date = new Date();
		
		'''
		// ----------------------------------------------------------------------------
		//
		// Multi-Dataflow Composer tool - Platform Composer
		// Accelerator Stream module 
		// Date: «dateFormat.format(date)»
		//
		// ----------------------------------------------------------------------------
		
		// ----------------------------------------------------------------------------
		// Module Interface
		// ----------------------------------------------------------------------------
		module s_accelerator(
			«FOR port : inputMap.keySet()»
			«IF inputMap.size>=outputMap.size»
			FSL«inputMap.get(port)»_Clk,
			FSL«inputMap.get(port)»_Rst,
			«ENDIF»
			FSL«inputMap.get(port)»_S_Clk,
			FSL«inputMap.get(port)»_S_Read,
			FSL«inputMap.get(port)»_S_Data,
			FSL«inputMap.get(port)»_S_Control,
			FSL«inputMap.get(port)»_S_Exists,
			«ENDFOR»
			«FOR port : outputMap.keySet() SEPARATOR ","»
			«IF outputMap.size<outputMap.size»
			FSL«inputMap.get(port)»_Clk,
			FSL«inputMap.get(port)»_Rst,
			«ENDIF»
			FSL«outputMap.get(port)»_M_Clk,
			FSL«outputMap.get(port)»_M_Write,
			FSL«outputMap.get(port)»_M_Data,
			FSL«outputMap.get(port)»_M_Control,
			FSL«outputMap.get(port)»_M_Full
			«ENDFOR»
		);
		// ----------------------------------------------------------------------------
		
		// ----------------------------------------------------------------------------
		// Module Parameters
		// ----------------------------------------------------------------------------
		// ----------------------------------------------------------------------------
		
		// ----------------------------------------------------------------------------
		// Module Signals
		// ----------------------------------------------------------------------------	
		// Input(s)
		«FOR port : inputMap.keySet()»
		«IF inputMap.size>=outputMap.size»
		input 							FSL«inputMap.get(port)»_Clk;
		input							FSL«inputMap.get(port)»_Rst;
		«ENDIF»
		output							FSL«inputMap.get(port)»_S_Clk;
		input [0 : 31]					FSL«inputMap.get(port)»_S_Data;
		input							FSL«inputMap.get(port)»_S_Control;
		input							FSL«inputMap.get(port)»_S_Exists;
		«ENDFOR»
		«FOR port : outputMap.keySet()»
		«IF outputMap.size<outputMap.size»
		input 							FSL«inputMap.get(port)»_Clk;
		input 							FSL«inputMap.get(port)»_Rst;
		«ENDIF»
		output 							FSL«outputMap.get(port)»_M_Clk;
		input 							FSL«outputMap.get(port)»_M_Full;
		«ENDFOR»
			
		// Ouput(s)
		«FOR port : inputMap.keySet()»
		output							FSL«inputMap.get(port)»_S_Read;
		«ENDFOR»
		«FOR port : outputMap.keySet()»
		output							FSL«outputMap.get(port)»_M_Write;
		output [31 : 0]					FSL«outputMap.get(port)»_M_Data;
		output							FSL«outputMap.get(port)»_M_Control;
		«ENDFOR»
		// ----------------------------------------------------------------------------			  	
						
		// ----------------------------------------------------------------------------
		// Body
		// ----------------------------------------------------------------------------
		«FOR port : outputMap.keySet()»
		«IF !inputMap.values.contains(outputMap.get(port))»
		assign FSL«outputMap.get(port)»_M_Write = 1'b0;
		assign FSL«outputMap.get(port)»_M_Control = 1'b0;
		«ENDIF»
		«ENDFOR»
		
		coprocessor copr(
			.clk(FSL0_Clk),
			.rst(FSL0_Rst),
			«FOR port : inputMap.keySet()»
			.FSL«inputMap.get(port)»_S_DATA(FSL«inputMap.get(port)»_S_Data), 
			.FSL«inputMap.get(port)»_S_CTRL(FSL«inputMap.get(port)»_S_Control),
			.FSL«inputMap.get(port)»_S_READ(FSL«inputMap.get(port)»_S_Read),
			.FSL«inputMap.get(port)»_S_EXISTS(FSL«inputMap.get(port)»_S_Exists),
			«ENDFOR»
			«FOR port : outputMap.keySet() SEPARATOR ","»
			.FSL«outputMap.get(port)»_M_DATA(FSL«outputMap.get(port)»_M_Data),
			.FSL«outputMap.get(port)»_M_CTRL(FSL«outputMap.get(port)»_M_Control),
			.FSL«outputMap.get(port)»_M_WRITE(FSL«outputMap.get(port)»_M_Write),
			.FSL«outputMap.get(port)»_M_FULL(FSL«outputMap.get(port)»_M_Full)
			«ENDFOR»
		);
		// ----------------------------------------------------------------------------
		
		endmodule		
		// ----------------------------------------------------------------------------
		// ----------------------------------------------------------------------------
		// ----------------------------------------------------------------------------
		'''
	}
		
	override printIpPackage(Network network, String file) {
		if(file.equals("PAO")) {
			printPao(INOUT,network);
		} else if(file.equals("PAO_IN")) {
			printPao(IN,network);
		} else if(file.equals("MPD")) {
			printMpd();
		}
	}
		
	def printMpd(){
		
		var dateFormat = new SimpleDateFormat("yyyy/MM/dd HH:mm:ss");
		var date = new Date();
		
		'''
		## ############################################################################
		##
		## Multi-Dataflow Composer tool - Platform Composer
		## Accelerator Stream MPD
		## Date: «dateFormat.format(date)»
		##
		## ############################################################################
		
		BEGIN s_accelerator
		
		## Peripheral Options
		OPTION IPTYPE = PERIPHERAL
		OPTION IMP_NETLIST = TRUE
		OPTION DESC = S_ACCELERATOR
		OPTION IP_GROUP = MICROBLAZE:PPC:USER
		OPTION ARCH_SUPPORT_MAP = (others=DEVELOPMENT)
		OPTION HDL = MIXED
		
		## Bus Interfaces
		«FOR input : inputMap.keySet»
		BUS_INTERFACE BUS=SFSL«inputMap.get(input)», BUS_STD=FSL, BUS_TYPE=SLAVE
		BUS_INTERFACE BUS=MFSL«inputMap.get(input)», BUS_STD=FSL, BUS_TYPE=MASTER
		«ENDFOR»
		«FOR output : outputMap.keySet»
		«IF !inputMap.values.contains(outputMap.get(output))»
		BUS_INTERFACE BUS=SFSL«outputMap.get(output)», BUS_STD=FSL, BUS_TYPE=SLAVE
		BUS_INTERFACE BUS=MFSL«outputMap.get(output)», BUS_STD=FSL, BUS_TYPE=MASTER
		«ENDIF»
		«ENDFOR»
		
		## Peripheral ports
		«FOR input : inputMap.keySet»
		# FSL«inputMap.get(input)»
		PORT FSL«inputMap.get(input)»_Clk = FSL_Clk, DIR=I, SIGIS=Clk, BUS=MFSL«inputMap.get(input)»:SFSL«inputMap.get(input)»
		PORT FSL«inputMap.get(input)»_Rst = FSL_Rst, DIR=I, SIGIS=Rst, BUS=MFSL«inputMap.get(input)»:SFSL«inputMap.get(input)»
		# FSL«inputMap.get(input)» SLAVE
		PORT FSL«inputMap.get(input)»_S_Clk = FSL_S_Clk, DIR=O, SIGIS=Clk, BUS=SFSL«inputMap.get(input)»
		PORT FSL«inputMap.get(input)»_S_Read = FSL_S_Read, DIR=O, BUS=SFSL«inputMap.get(input)»
		PORT FSL«inputMap.get(input)»_S_Data = FSL_S_Data, DIR=I, VEC=[0:31], BUS=SFSL«inputMap.get(input)»
		PORT FSL«inputMap.get(input)»_S_Control = FSL_S_Control, DIR=I, BUS=SFSL«inputMap.get(input)»
		PORT FSL«inputMap.get(input)»_S_Exists = FSL_S_Exists, DIR=I, BUS=SFSL«inputMap.get(input)»
		«ENDFOR»
		«FOR output : outputMap.keySet»
		«IF !inputMap.values.contains(outputMap.get(output))»
		# FSL«outputMap.get(output)»
		PORT FSL«outputMap.get(output)»_Clk = FSL_Clk, DIR=I, SIGIS=Clk, BUS=MFSL«outputMap.get(output)»:SFSL«outputMap.get(output)»
		PORT FSL«outputMap.get(output)»_Rst = FSL_Rst, DIR=I, SIGIS=Rst, BUS=MFSL«outputMap.get(output)»:SFSL«outputMap.get(output)»
		«ENDIF»
		# FSL«outputMap.get(output)» MASTER
		PORT FSL«outputMap.get(output)»_M_Clk = FSL_M_Clk, DIR=O, SIGIS=Clk, BUS=MFSL«outputMap.get(output)»
		PORT FSL«outputMap.get(output)»_M_Write = FSL_M_Write, DIR=O, BUS=MFSL«outputMap.get(output)»
		PORT FSL«outputMap.get(output)»_M_Data = FSL_M_Data, DIR=O, VEC=[0:31], BUS=MFSL«outputMap.get(output)»
		PORT FSL«outputMap.get(output)»_M_Control = FSL_M_Control, DIR=O, BUS=MFSL«outputMap.get(output)»
		PORT FSL«outputMap.get(output)»_M_Full = FSL_M_Full, DIR=I, BUS=MFSL«outputMap.get(output)»
		«ENDFOR»
		
		END
		'''
	}

	
	def printPao(int type, Network network){
		
		var dateFormat = new SimpleDateFormat("yyyy/MM/dd HH:mm:ss");
		var date = new Date();
		
		'''
		##############################################################################
		## Filename:          s_accelerator.pao
		## Description:       Peripheral Analysis Order
		## Date:              «dateFormat.format(date)» (by Multi-Dataflow Composer - Platform Composer)
		##############################################################################
		
		lib SystemMdc mdc vhdl
		lib SystemBuilder sbtypes.vhdl vhdl
		lib SystemBuilder sbfifo_behavioral.vhdl vhdl
		lib SystemBuilder sbfifo.vhdl vhdl
		lib s_accelerator_v1_00_a cfg_FSM verilog
		lib s_accelerator_v1_00_a cfg_cnt verilog
		lib s_accelerator_v1_00_a cfg_regs verilog
		lib s_accelerator_v1_00_a Start_Network verilog
		lib s_accelerator_v1_00_a config_regs verilog
		lib s_accelerator_v1_00_a front_end verilog
		lib s_accelerator_v1_00_a fsmIN_RDmem verilog
		lib s_accelerator_v1_00_a s_cnt verilog
		lib s_accelerator_v1_00_a b_logic verilog
		lib s_accelerator_v1_00_a s_logic verilog
		lib s_accelerator_v1_00_a configurator verilog
		«FOR actor : network.children.filter(typeof(Actor))»
		«IF !actor.hasAttribute("sbox")»
		lib s_accelerator_v1_00_a «actor.simpleName» verilog
		«ENDIF»
		«ENDFOR»
		lib s_accelerator_v1_00_a multi_dataflow vhdl
		lib s_accelerator_v1_00_a back_end verilog
		lib s_accelerator_v1_00_a cl_logic verilog
		lib s_accelerator_v1_00_a coprocessor_til verilog
		lib s_accelerator_v1_00_a s_accelerator verilog
		
		'''
	}
			
	override printSoftwareDriver(Network network, Map<String,Map<String,String>> networkVertexMap, ConfigManager configManager, String file){
		if(file.equals("LOW_HEAD")) {
			printDriverLowHead(network);
		} else if(file.equals("HIGH_HEAD")) {
			printDriverHighHead(network,networkVertexMap);
		} else if(file.equals("HIGH_SRC")) {
			printDriverHighSrc(network,networkVertexMap,configManager);
		} 
	}
	
	def printDriverLowHead(Network network){
		
		var dateFormat = new SimpleDateFormat("yyyy/MM/dd HH:mm:ss");
		var date = new Date();
		
		'''
		/*****************************************************************************
		*  Filename:          s_accelerator_l.h
		*  Description:       Stream Accelerator Low Level Driver
		*  Date:              «dateFormat.format(date)» (by Multi-Dataflow Composer - Platform Composer)
		*****************************************************************************/
		
		#ifndef S_ACCELERATOR_L_H
		#define S_ACCELERATOR_L_H
		
		/***************************** Include Files *******************************/
		
		/************************** Constant Definitions ***************************/
		
		
		#endif /** ACCELERATOR_L_H */
		
		'''
	}
	
	def printDriverHighSrc(Network network, Map<String,Map<String,String>> networkVertexMap, ConfigManager configManager) {
		
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
		
		#include "fsl.h"
		#include "s_accelerator_h.h"

		const int SIZEADDRESS=12;
		const int SIZECOUNT=12;

		int copr(«FOR id : portMap.values.sort SEPARATOR "\n"»		int s«id», int sb«id», int* d«id»,«ENDFOR»
				int KID) {
			int i;
			«FOR input : inputMap.keySet»
			int v«inputMap.get(input)» = 0;
			«ENDFOR»
			
			// Accelerator Configuration
			«FOR id : portMap.values.sort SEPARATOR "\n"»cputfsl( (sb«id»<<(SIZEADDRESS+SIZECOUNT) | s«id»<<(SIZEADDRESS) ), 0);«ENDFOR»
			cputfsl(KID, 0);
			 // Data Sending
			 while ( !(«FOR input : inputMap.keySet SEPARATOR "&&"»(v«inputMap.get(input)»==s«inputMap.get(input)»)«ENDFOR») ) {
			 	«FOR input : inputMap.keySet SEPARATOR "\n"»
			 	if(v«inputMap.get(input)»<s«inputMap.get(input)») {
			 		putfsl(*(d«inputMap.get(input)»+v«inputMap.get(input)»), «inputMap.get(input)»);
			 		v«inputMap.get(input)»++;
			 	}«ENDFOR»
			 }
			 
			// Data Receiving
			«FOR output : outputMap.keySet SEPARATOR "\n"»if(s«portMap.get(output)» != 0) {
				for(i=0; i<s«portMap.get(output)»; i++) {
					getfsl(*(d«portMap.get(output)»+i), «outputMap.get(output)»);
					}
				}«ENDFOR»
				
			return 0;
			
		}
			
		«FOR net : networkVertexMap.keySet SEPARATOR "\n"»
		int copr_«net»(
			«FOR port : netIdPortMap.get(net) SEPARATOR ","»
			int s«portMap.get(port)»«IF !outputMap.containsKey(port)», int sb«portMap.get(port)»«ENDIF», int* d«portMap.get(port)»	/*«port.name»*/
			«ENDFOR»
			) {
			«FOR id : portMap.values.sort»
			«FOR port : portMap.keySet»
			«IF portMap.get(port).equals(id)»
			«IF !networkVertexMap.get(net).values.contains(port.name)»// «port.name»
			int s«portMap.get(port)»=0; 
			int sb«portMap.get(port)» = 0;
			int* d«portMap.get(port)» = 0;
			«ELSE»
			«IF outputMap.containsKey(port)»// «port.name»
			int sb«portMap.get(port)» = 0;
			«ENDIF»
			«ENDIF»
			«ENDIF»
			«ENDFOR»
			«ENDFOR»
			
			copr(«FOR id : portMap.values.sort SEPARATOR "\n"»		s«id», sb«id», d«id»,«ENDFOR»
				«configManager.getNetworkId(net)»);

			return 0;
		}
		«ENDFOR»
		'''
		
	}	
	
	def printDriverHighHead(Network network, Map<String,Map<String,String>> networkVertexMap) {
		
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
		
		/************************** Constant Definitions ***************************/
		
		/************************* Functions Definitions ***************************/
		
		int copr(
		«FOR id : portMap.values.sort SEPARATOR "\n"»		int s«id», int sb«id», int* d«id»,«ENDFOR»
				int KID
		);
		
		«FOR net : networkVertexMap.keySet»
		int copr_«net»(
			«FOR port : netIdPortMap.get(net) SEPARATOR ","»
			int s«portMap.get(port)»«IF !outputMap.containsKey(port)», int sb«portMap.get(port)»«ENDIF», int* d«portMap.get(port)»	/*«port.name»*/	
			«ENDFOR»
		);
		«ENDFOR»
		
		#endif /** S_ACCELERATOR_H_H */
		'''
	}
	
	def printTest(Map<Network,Integer> configMap){
		
		var dateFormat = new SimpleDateFormat("yyyy/MM/dd HH:mm:ss");
		var date = new Date();
				
		'''
		// ----------------------------------------------------------------------------
		//
		// Multi-Dataflow Composer tool - Platform Composer
		// Test Reconfigurable Accelerator
		// Date: «dateFormat.format(date)»
		//
		// ----------------------------------------------------------------------------	
		
		#include <stdio.h>
		#include "platform.h"
		#include "accelerator.h"
		#include "mb_interface.h"
		
		int go = 0;
		
		«FOR net : configMap.keySet()»
		#define «net.name.toUpperCase» «configMap.get(net)»
		«ENDFOR»

		#define ID «configMap.keySet.get(0).name.toUpperCase»

		void ACCELERATOR_isr(){
			print("Finish computation\n\r");
			go = 1;
		}

		void print(char *str);

		int ACCELERATOR_test()
		{
			init_platform();
			
			int i;
			«FOR input : inputMap.keySet»
			int in«inputMap.get(input)» = «inputMap.get(input)*10»;
			«ENDFOR»
		
			print("Start\n\r");
		
			// conf setting
			// TODO disable not involved ports
			«FOR port : portMap.keySet»
			unsigned int conf«portMap.get(port)»;
			unsigned int burst«portMap.get(port)»=1;
			unsigned int size«portMap.get(port)»=4;
			unisgned int addr«portMap.get(port)»=size*4*(«portMap.get(port)»-1);
			conf«portMap.get(port)» = (burst«portMap.get(port)»<<24)|(size«portMap.get(port)»<<12)|(addr«portMap.get(port)»>>2);
			«ENDFOR»
		
			print("Config ports\n\r");
			«FOR port : portMap.keySet»
			ACCELERATOR_mWriteSlaveReg«portMap.get(port)»(0,0,conf«portMap.get(port)»);	//conf port«portMap.get(port)»
	    	«ENDFOR»
			
			print("Write data\n\r");
			«FOR input : inputMap.keySet»
			for(i=0; i<4; i=i+1) {
				ACCELERATOR_mWriteMemory(addr«inputMap.get(input)»+4*i,in«inputMap.get(input)»+i);	//data[0] in1
			}
			«ENDFOR»
			«FOR input : inputMap.keySet»
			for(i=0; i<4; i=i+1) {
				if(ACCELERATOR_mReadMemory(addr«inputMap.get(input)»+4*i)!=(in1+i))
					print("in«inputMap.get(input)» failed\n\r");
			}
			«ENDFOR»
		
			microblaze_enable_interrupts();
			print("Config ID: Start computation\n\r");
			ACCELERATOR_mWriteSlaveReg0(0,0,ID);	// ID

			while(go==0);
			microblaze_disable_interrupts();

			print("Testing results\n\r")
			«FOR net : configMap.keySet»
			if(ID==«net.name.toUpperCase») {
				// TODO evaluation
			} 
			«ENDFOR»

			print("Finish\n\r");
		
			cleanup_platform();
			
			return 0;
		}

		'''
	}
	
	

}