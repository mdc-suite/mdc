/*
 *
 */
 
package it.mdc.tool.platformComposer

import java.text.SimpleDateFormat
import java.util.Date
import net.sf.orcc.df.Network
import java.util.ArrayList
import java.util.Mapimport net.sf.orcc.df.Actor
import it.mdc.tool.ConfigManager

/*
 * EDK Template Interface Layer 
 * Memory-Mapped HW Accelerator Printer
 * 
 * @author Carlo Sau
 */
class TilPrinterEdkMm extends TilPrinter{

	override printHdlSource(Network network, String module) {
		if(module.equals("TOP")) {
			printTop(network);
		} else if(module.equals("CFG_REGS")) {
			printRegs();
		} else if(module.equals("MUX")) {
			printMux();
		} else if(module.equals("DEMUX")) {
			printDemux();
		} else if(module.equals("ADDR_GEN")) {
			printAddrGen();
		} else if(module.equals("PORT_SEL")) {
			printPortSel(INOUT);
		} else if(module.equals("PORT_SEL_IN")) {
			printPortSel(IN);
		} else if(module.equals("PORT_SEL_OUT")) {
			printPortSel(OUT);
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
	
	def printTopInterface() {
		
		'''
		
		module coprocessor(
			clk,					// system clock
			rst,					// system reset
			datain,					// local memory input data (port 1)
			addressrd,				// local memory read address (port 2)
			addresswr,				// local memory write address (port 1)
			enablerd,				// local memory enable (port 2)
			enablewr,				// local memory enable (port 1)
			write,					// local memory write enable (port 1)
			kernelIDin,				// kernel ID register input data
			kernelIDen,				// kernel ID register enable
			kernelIDout,			// kernel ID register output data
			«FOR port : portMap.keySet()»
			confin_«portMap.get(port)»,				// config port «port.getName()»
			en_«portMap.get(port)»,					// enable port «port.getName()»
			«ENDFOR»	
			dataout,				// local memory output data (port 2)
			finish					// finish computation flag (irq)
		);
		
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
		// Input(s)
		input 						clk;
		input 						rst;
		input [SIZEDATA-1 : 0]		datain;
		input [SIZEADDRESS-1 : 0]	addressrd;
		input [SIZEADDRESS-1 : 0]	addresswr;
		input						enablerd;
		input 						enablewr;
		input 						write;
		input [SIZEID-1 : 0]		kernelIDin;
		input 						kernelIDen;
		«FOR port : portMap.keySet()»
		input [SIZEDATA-1 : 0] 		confin_«portMap.get(port)»;
		input 						en_«portMap.get(port)»;
		«ENDFOR»
		
		// Ouptut(s)
		output [SIZEDATA-1 : 0]		dataout;
		output [SIZEID-1 : 0]		kernelIDout;
		output						finish;
			
		// Wire(s) and Reg(s)
		// Input Wire(s)
		wire 						clk;
		wire 						rst;
		wire [SIZEDATA-1 : 0]		datain;
		wire [SIZEADDRESS-1 : 0]	addressrd;
		wire [SIZEADDRESS-1 : 0]	addresswr;
		wire						enablerd;
		wire 						enablewr;
		wire 						write;
		wire [SIZEID-1 : 0]			kernelIDin;
		wire 						kernelIDen;
		«FOR port : portMap.keySet()»
		wire [SIZEDATA-1 : 0] 		confin_«portMap.get(port)»;
		wire 						en_«portMap.get(port)»;
		«ENDFOR»
		
		// Output Wire(s)
		wire [SIZEDATA-1 : 0]		dataout;
		wire [SIZEID-1 : 0]			kernelIDout;
			
		// Internal Wire(s)
		«FOR port : portMap.keySet()»
		wire [SIZEADDRESS-1 : 0] 	baseaddr_«portMap.get(port)»;
		wire [SIZECOUNT-1 : 0] 		size_«portMap.get(port)»;
		wire [SIZEBURST-1 : 0] 		sizeburst_«portMap.get(port)»;
		«ENDFOR»
		wire [SIZECOUNT-1 : 0]		size;
		wire [SIZEBURST-1 : 0]		sizeburst;
		«FOR input : inputMap.keySet()»
		wire		 				endcount«inputMap.get(input)»in;
		wire [SIZECOUNT-1 : 0] 		RegCnt«inputMap.get(input)»_out;
		«ENDFOR»
		wire [SIZEBURST-1:0] 		numb;
		wire [SIZEBURST-1:0] 		rest;
		wire [SIZECOUNT-1 : 0] 		count_out;
		wire [SIZECOUNT-1 : 0] 		countOut;
		
		«FOR output : outputMap.keySet()»
		wire [«output.type.sizeInBits-1» : 0] 		datareg«portMap.get(output)»out;
		wire						endcount«portMap.get(output)»out;
		wire [SIZECOUNT-1:0]		RegCnt«outputMap.get(output)»Output;
		«ENDFOR»
		
		wire [SIZEDATA-1 : 0]		dataoutmem_in;
		wire [SIZEADDRESS-1 : 0]	address_in;
		wire [SIZEPORT-1 : 0] 		port_in;
		wire [SIZEPORT-1 : 0] 		SelectedPort_in;
		wire						free;
		wire						En_RegCnt;
		wire						go_in;
		wire						enablemem_in;
		wire						portEn_in;
		wire 						start;
		wire						endburst;
		wire 						free_out;
		wire						selected_out;
		wire [SIZEPORT-1 : 0] 		port_out;
		wire [SIZEPORT-1 : 0] 		SelectedPort_out;
		wire [SIZEPORT-1 : 0]		lastport_in;
		wire [SIZEPORT-1 : 0]		lastport_out;
		wire 						enable_out;
		wire [SIZEDATA-1 : 0] 		datamemin_out;
		wire [SIZEADDRESS-1 : 0]	address_out;
		wire						emptyFF;
		wire 						rd_en;
		wire 						portEn_out;
		wire 						end_send;
		wire 						end_write;
		wire                 		load;
		wire                 		clear_out;
		wire                 		load_out;
		wire [SIZECOUNT-1 : 0] 		lastvalue;
		wire [SIZECOUNT-1 : 0] 		lastvalue_out;
		wire [SIZECOUNT-1 : 0] 		size_out_cnt;
		
				
		// Reg(s)
		reg 						finish;
		reg [SIZEADDRESS-1 : 0] 	address2mux;
		reg 						enable2mux;
		reg 						kernelIDenmux;
		reg [SIZEID-1 : 0] 			kernelIDinmux;
		reg 						enable1mux;
		reg [SIZEADDRESS-1 : 0] 	address1mux;
		
		// Reconfigurable Datapath Wire(s)		
		«FOR input : inputMap.keySet()»
		wire [SIZEDATA-1 : 0]		IN_data«inputMap.get(input)»;
		wire 						IN_send«inputMap.get(input)»; 
		wire 						OUT_ack«inputMap.get(input)»;
		wire						OUT_rdy«inputMap.get(input)»; 
		wire [SIZEBURST-1 : 0] 		IN_count«inputMap.get(input)»;
		«ENDFOR»
		// to adapt profiling		
		«FOR output : outputMap.keySet()»		
		wire [«output.type.sizeInBits-1» : 0]		OUT_data«outputMap.get(output)»;
		wire 						OUT_send«outputMap.get(output)»;
		wire 						IN_ack«outputMap.get(output)»;
		wire						IN_rdy«outputMap.get(output)»;
		wire 						w_enOUT«outputMap.get(output)»;
		wire 						f_full_flag«outputMap.get(output)»;
		wire 						f_empty_flag«outputMap.get(output)»;
		wire 						r_enOUT«outputMap.get(output)»;
		«ENDFOR»
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
		bench(
			.clk(clk),
			.reset(rst),
			«FOR port : portMap.keySet()»
			.confin_«portMap.get(port)»(confin_«portMap.get(port)»),
			.en_«portMap.get(port)»(en_«portMap.get(port)»),
			.baseaddr_«portMap.get(port)»(baseaddr_«portMap.get(port)»),
			.size_«portMap.get(port)»(size_«portMap.get(port)»),
			.sizeburst_«portMap.get(port)»(sizeburst_«portMap.get(port)»),
			«ENDFOR»
			.kernelIDin(kernelIDinmux),
			.kernelIDen(kernelIDenmux),
			.kernelIDout(kernelIDout)
		);
		// ----------------------------------------------------------------------------	
			
		// Dual Port Memory
		// ----------------------------------------------------------------------------
		DualPortMemory #(	
			.SIZEDATA(SIZEDATA),
			.SIZEADDRESS(SIZEADDRESS) ) 
		mem (
			.clk1(clk),						// system clock port 1
			.clk2(clk),						// system clock port 1
			.address1(address1mux),			// r/w address port 1
			.enable1(enable1mux),			// enable port 1
			.write1(write),					// write enable port 1
			.datain1(datain),				// input data port 1
			.dataout1(dataoutmem_in),		// output data port 1
			.address2(address2mux),			// r/w address port 2
			.enable2(enable2mux),			// enable port 2
			.write2(enable_out),			// write enable port 2
			.datain2(datamemin_out),		// input data port 2
			.dataout2(dataout)				// output data port 2
		);
		// ----------------------------------------------------------------------------
			
		// Coprocessor Front-End
		// ----------------------------------------------------------------------------
		«printTopFrontEnd()»		
		// ----------------------------------------------------------------------------	
		
		// Multi-Dataflow Reconfigurable Datapath
		// ----------------------------------------------------------------------------
		«printTopDatapath()»
		// ----------------------------------------------------------------------------	
		
		// Coprocessor Back-End
		// ----------------------------------------------------------------------------
		«printTopBackend()»
		// ----------------------------------------------------------------------------
		'''
	}
	
	def printTopFrontEnd() {
	
		'''
		// Input Address Loader
		Address_Loader #(
			.SIZEADDRESS(SIZEADDRESS),
			.SIZECOUNT(SIZECOUNT),
			.SIZEPORT(SIZEPORT) ) 
		addloadin (			
			«FOR input : inputMap.keySet()»
			.b_add«inputMap.get(input)»(baseaddr_«inputMap.get(input)»), 		// base address input port «input.getName()»
			«ENDFOR»
			.count(count_out), 						// count value for the current port
			.port(port_in),							// current input port
			.address(address_in)					// local memory address
		);
		
		// End burst calculation
		assign {numb,rest} = {(count_out+1),8'b0}>>(sizeburst>>1);
		assign endburst = rest==0;
	
		// Size Counter
		Cnt2 #(			
			.SIZECOUNT(SIZECOUNT) ) 
		cnt_in (
			.clk(clk),						// system clock
			.reset(rst),					// system reset
			.clear(finish),					// internal clear
			.maxValue(size),				// maximum value
			.loadValue(lastvalue), 			// last value stored
			.go(go_in),						// enable count
			.load(load),         			// load value
			.count(count_out)				// current count 
		);
	
		// Port Selector
		«IF inputMap.size==outputMap.size»Port_Selector«ELSE»Port_Selector_In«ENDIF» #(
			.SIZEPORT(SIZEPORT) )
		selPortIN (			
			«FOR input : inputMap.keySet()»
			.ready«inputMap.get(input)»(OUT_rdy«inputMap.get(input)»&&!endcount«inputMap.get(input)»in),		// «input» ready signal
			«ENDFOR»
			.CurrentPort(lastport_in),		// current input port
			.SelectedPort(SelectedPort_in)	// selected input port
		);
	
		// input port register
		Reg #(
			.SIZEDATA(SIZEPORT) )
		portRegIN (			
			.clk(clk),					// system clock
			.reset(rst),				// system reset
			.enable(portEn_in),			// register enable
			.clear(free), 				// internal clear
			.datain(SelectedPort_in),	// input data
			.dataout(port_in)			// output data
		);
		
		// last selected port register
		Reg #(
			.SIZEDATA(SIZEPORT) )
		lastPortRegIN(
			.clk(clk),
			.enable(portEn_in),
			.reset(rst),
			.clear(1'b0),
			.datain(SelectedPort_in),
			.dataout(lastport_in)	
		);
		
		assign selected_in = (port_in) ? 1 : 0;
		
		// Partial Count Registers for Inputs
		«FOR input : inputMap.keySet() SEPARATOR "\n"»Reg2 #(
		.SIZEDATA(SIZECOUNT) )
		RegCnt«inputMap.get(input)» (			
		.clk(clk),					
		.reset(rst),				
		.enable(En_RegCnt«inputMap.get(input)»),			
		.clear(clear), 				
		.datain(count_out),	
		.dataout(RegCnt«inputMap.get(input)»_out)			
		);
		«ENDFOR»
		
		// Start Elaboration Register
		Start_Network  #(
			.SIZEID(SIZEID) )
		startin (
			.kernelID(kernelIDout),		// computing kernel ID
			.start(start)				// start computation
		);
		
		// Input Finite State Machine
		fsmIN_RDmem R_fsm (
			.clk(clk),					// system clock
			.rst(rst),					// system reset
			.start(start),				// start computation
			.OUT_rdy(OUT_rdy), 			// datapath ready
			.selected(selected_in),		// selected input port
			.endburst(endburst),		// end burst
			.endsend(end_send),			// end size
			.IN_send(IN_send),			// send data
			.go(go_in),					// go counter
			.portEn(portEn_in),		 	// enable input port register
			.free(free),				// reset current selected port
			.load(load),				// load current partial count
			.clear(clear)				// clear current partial counters
		);
		
		// to move inside the fsm
		assign En_RegCnt = free;
		assign enablemem_in = go_in;
	
		// Demultiplexer Load Partial Count Register
		Demultiplexer #(	
			.SIZESIGNAL(SIZESIGNAL),
			.SIZEPORT(SIZEPORT) ) 
		dmux_LD_Reg(
			«FOR input : inputMap.keySet()»
			.signal«inputMap.get(input)»(En_RegCnt«inputMap.get(input)»),
			«ENDFOR»
			.mainsignal(En_RegCnt),
			.port(port_in)
		);
	
		// Demultiplexer Send
		Demultiplexer #(	
			.SIZESIGNAL(SIZESIGNAL),
			.SIZEPORT(SIZEPORT) ) 
		dmux_IN_send(
			«FOR input : inputMap.keySet()»
			.signal«inputMap.get(input)»(IN_send«inputMap.get(input)»),
			«ENDFOR»
			.mainsignal(IN_send),
			.port(port_in)
		);
	
		// Demultiplexer Data
		Demultiplexer #(
			.SIZESIGNAL(SIZEDATA),
			.SIZEPORT(SIZEPORT) ) 
		dmux_IN_data (
			«FOR input : inputMap.keySet()»
			.signal«inputMap.get(input)»(IN_data«inputMap.get(input)»),
			«ENDFOR»
			.mainsignal(dataoutmem_in),
			.port(port_in)
		);
	
		// Multiplexer Ready
		Multiplexer #(
			.SIZESIGNAL(SIZESIGNAL),
			.SIZEPORT(SIZEPORT) ) 
		mux_OUT_rdy (
			«FOR input : inputMap.keySet()»
			.signal«inputMap.get(input)»(OUT_rdy«inputMap.get(input)»),
			«ENDFOR»
			.port(port_in),
			.outsignal(OUT_rdy)	
		);
		
		// Multiplexer Partial Count Register
		Multiplexer #(
			.SIZESIGNAL(SIZECOUNT),
			.SIZEPORT(SIZEPORT) ) 
		mux_cnt_reg (
			«FOR input : inputMap.keySet()»
			.signal«inputMap.get(input)»(RegCnt«inputMap.get(input)»_out),
			«ENDFOR»
			.port(port_in),
			.outsignal(lastvalue)	
		);
		
		// Multiplexer Max Count
		Multiplexer #(
			.SIZESIGNAL(SIZECOUNT),
			.SIZEPORT(SIZEPORT) ) 
		mux_cnt_maxval (
			«FOR input : inputMap.keySet()»
			.signal«inputMap.get(input)»(size_«inputMap.get(input)»),
			«ENDFOR»
			.port(port_in),
			.outsignal(size)	
		);
		
		// Multiplexer Sizeburst
		Multiplexer #(
			.SIZESIGNAL(SIZEBURST),
			.SIZEPORT(SIZEPORT) )
		mux_endCNT_in (
			«FOR input : inputMap.keySet()»
			.signal«inputMap.get(input)»(sizeburst_«inputMap.get(input)»),
			«ENDFOR»
			.port(port_in),
			.outsignal(sizeburst)
		);
		
		«FOR input : inputMap.keySet() SEPARATOR "\n"» 
		assign endcount«inputMap.get(input)»in = size_«inputMap.get(input)» == RegCnt«inputMap.get(input)»_out;«ENDFOR»
		assign end_send = «FOR input : inputMap.keySet()» & endcount«inputMap.get(input)»in«ENDFOR»;
		
		// Memory Arbitration
		always @ (start,address_in,addresswr)
			if(start) 	address1mux=address_in;
			else 		address1mux=addresswr;
	
		always @ (start,enablemem_in,enablewr)
			if(start) 	enable1mux=enablemem_in;
			else 		enable1mux=enablewr;
		
		'''
	}
	
	def printTopDatapath() {
		'''
		«FOR input : inputMap.keySet()»
		assign IN_count«inputMap.get(input)» = sizeburst_«inputMap.get(input)»;
		«ENDFOR»
		// to adapt profiling
		multi_dataflow reconf_dpath (
			// Multi-Dataflow Input(s)
			«FOR input : inputMap.keySet()»	.«input.getName()»_data(IN_data«inputMap.get(input)»«IF input.type.sizeInBits!=dataSize»[«input.type.sizeInBits-1»:0]«ENDIF»),
			.«input.getName()»_send(IN_send«inputMap.get(input)»),
			.«input.getName()»_ack(OUT_ack«inputMap.get(input)»),
			.«input.getName()»_rdy(OUT_rdy«inputMap.get(input)»),
			.«input.getName()»_count({{8'b0},IN_count«inputMap.get(input)»}),
			«ENDFOR»
			// Multi-Dataflow Output(s)
			«FOR output : outputMap.keySet()»	.«output.getName()»_data(OUT_data«outputMap.get(output)»«IF output.type.sizeInBits!=dataSize»[«output.type.sizeInBits-1»:0]«ENDIF»),
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
		'''
	}
	
	def printTopBackend() {
		'''
		«FOR output : outputMap.keySet()»
		assign IN_ack«outputMap.get(output)»=w_enOUT«outputMap.get(output)»;
		«ENDFOR»
	
		«FOR output : outputMap.keySet()»
		assign IN_rdy«outputMap.get(output)»=!f_full_flag«outputMap.get(output)»;
		«ENDFOR»
	
		«FOR output : outputMap.keySet()»
		assign w_enOUT«outputMap.get(output)» = OUT_send«outputMap.get(output)» && IN_rdy«outputMap.get(output)»;
		«ENDFOR»
		
		«FOR output : outputMap.keySet()»
		// Output «output.getName()» FIFO
		a_fifo #(	
			.f_width(«output.type.sizeInBits»), 
			.f_depth(FIFO_DEPTH),
			.f_ptr_width(FIFO_DEPTH+1),
			.f_half_full_value(FIFO_DEPTH/2), 
			.f_almost_full_value(FIFO_DEPTH-1),
			.f_almost_empty_value(1))
		FIFO_out_«outputMap.get(output)» (
			.d_out(datareg«portMap.get(output)»out),  			// NOME DA CAMBIARE
			.f_full_flag(f_full_flag«outputMap.get(output)»), 	//
			.f_half_full_flag(), 								//
			.f_empty_flag(f_empty_flag«outputMap.get(output)»), //
			.f_almost_full_flag(), 								//
			.f_almost_empty_flag(), 							//
			.d_in(OUT_data«outputMap.get(output)»), 			//
			.r_en(r_enOUT«outputMap.get(output)»), 				//
			.w_en(w_enOUT«outputMap.get(output)»),				//
			.r_clk(clk), 										//
			.w_clk(clk), 										//
			.reset(rst) 										//
		);
		«ENDFOR»
		
		// Output Finite State Machine
		fsmOUT_WRmem OUT_FSM(
			.clk(clk),					// system clock
			.rst(rst),					// system reset
			.empty(emptyFF), 			// empty FIFO
			.selected(selected_out),	// selected output port
			.endwrite(end_write),       // end write flag
			.enablemem(enable_out),		// enable memory
			.rd_en(rd_en),				//	read FIFO
			.go(go_out),				//	go count
			.portEn(portEn_out),		//	enable output port register
			.free(free_out),			//	reset current selected port
			.clear(clear_out),          //  clear partial count register
			.load(load_out)             //  load partial count
		);
	
		// Output Port Selector
		«IF inputMap.size==outputMap.size»Port_Selector«ELSE»Port_Selector_Out«ENDIF» #(
			.SIZEPORT(SIZEPORT) )
		selPortOUT (
		«FOR output : outputMap.keySet()»
			.ready«outputMap.get(output)»(!f_empty_flag«outputMap.get(output)»),
		«ENDFOR»			
			.CurrentPort(lastport_out),
			.SelectedPort(SelectedPort_out)
		);
	
		// Output Port Register
		Reg #(
			.SIZEDATA(SIZEPORT) ) 
		portRegOUT(
			.clk(clk),					// system clock
			.reset(rst),				// system reset
			.enable(portEn_out),		// enable
			.clear(free_out), 			// internal clear
			.datain(SelectedPort_out),	// input data
			.dataout(port_out)			// output data
		);
		
		// Last Output Port Register	
		Reg #(
			.SIZEDATA(SIZEPORT) ) 
		LastPortRegOUT(
			.clk(clk),					// system clock
			.reset(rst),				// system reset
			.enable(portEn_out),		// enable
			.clear(1'b0), 				// internal clear
			.datain(SelectedPort_out),	// input data
			.dataout(lastport_out)		// output data
		);
		
		assign selected_out = (port_out) ? 1 : 0;
		
		// Partial Count Registers for Outputs
		«FOR output : outputMap.keySet() SEPARATOR "\n"»Reg2 #(
		.SIZEDATA(SIZECOUNT) )
		RegCntOut«outputMap.get(output)» (			
		.clk(clk),					
		.reset(rst),				
		.enable(En_RegCnt«outputMap.get(output)»_out),			
		.clear(clear_out), 				
		.datain(countOut),	
		.dataout(RegCnt«outputMap.get(output)»Output)			
		);
		«ENDFOR»
	
		// Multiplexer Data
		Multiplexer #(
			.SIZESIGNAL(SIZEDATA),
			.SIZEPORT(SIZEPORT) ) 
		mux_DMEM(
			«FOR output : outputMap.keySet()»	
			.signal«outputMap.get(output)»(«IF output.type.sizeInBits!=dataSize»{{«dataSize-output.type.sizeInBits»'b0},datareg«portMap.get(output)»out}«ELSE»«portMap.get(output)»out«ENDIF»),
			«ENDFOR»
			.port(port_out),
			.outsignal(datamemin_out)
		);
	
		// Multiplexer Empty
		Multiplexer #(
			.SIZESIGNAL(SIZESIGNAL),
			.SIZEPORT(SIZEPORT) ) 
		mux_emptyFF(
			«FOR output : outputMap.keySet()»
			.signal«outputMap.get(output)»(f_empty_flag«outputMap.get(output)»),
			«ENDFOR»
			.port(port_out),
			.outsignal(emptyFF)
		);
		
		// Multiplexer Partial Count Out
		Multiplexer #(
			.SIZESIGNAL(SIZECOUNT),
			.SIZEPORT(SIZEPORT) ) 
		mux_cnt_reg_out(
			«FOR output : outputMap.keySet()»
			.signal«outputMap.get(output)»(RegCnt«outputMap.get(output)»Output),
			«ENDFOR»
			.port(port_out),
			.outsignal(lastvalue_out)
		);
		
		// Multiplexer Max Count Out
		Multiplexer #(
			.SIZESIGNAL(SIZECOUNT),
			.SIZEPORT(SIZEPORT) ) 
		mux_cnt_maxval_out(
			«FOR output : outputMap.keySet()»
			.signal«outputMap.get(output)»(size_«portMap.get(output)»),
			«ENDFOR»
			.port(port_out),
			.outsignal(size_out_cnt)
		);
	
		// Demultiplexer Read
		Demultiplexer #(
			.SIZESIGNAL(SIZESIGNAL),
			.SIZEPORT(SIZEPORT) )
		dmux_rdEN_FF(
			«FOR output : outputMap.keySet()»
			.signal«outputMap.get(output)»(r_enOUT«outputMap.get(output)»),
			«ENDFOR»
			.mainsignal(rd_en),
			.port(port_out)
		);
		
		// Demultiplexer Load Output Counter
		Demultiplexer #(
			.SIZESIGNAL(SIZESIGNAL),
			.SIZEPORT(SIZEPORT) )
		demux_LD_Reg_out(
			«FOR output : outputMap.keySet()»
			.signal«outputMap.get(output)»(En_RegCnt«outputMap.get(output)»_out),
			«ENDFOR»
			.mainsignal(free_out),
			.port(port_out)
		);
		
		
	
		// Output Size Counter
		Cnt2 #(
			.SIZECOUNT(SIZECOUNT) ) 
		cnt_out(
			.clk(clk),
			.reset(rst),
			.clear(finish),				// Internal reset
			.maxValue(size_out_cnt),	// Maximum count
			.loadValue(lastvalue_out),  // Partial count input
			.go(go_out),				// Enable all'avanzamento
			.load(load_out),			// Load partial count
			.count(countOut)			// Current counter value
		);
		
		«FOR output : outputMap.keySet() SEPARATOR "\n"» 
		assign endcount«portMap.get(output)»out = size_«portMap.get(output)» == RegCnt«outputMap.get(output)»Output;«ENDFOR»
		assign end_write =«FOR output : outputMap.keySet()» & endcount«portMap.get(output)»out«ENDFOR»;
	
		always @ (posedge clk or posedge rst)
			if(rst) finish <= 0;
			else 	finish <= end_write;
	
		// Output Address Loader
		Address_Loader #(
			.SIZEADDRESS(SIZEADDRESS),
			.SIZECOUNT(SIZECOUNT),
			.SIZEPORT(SIZEPORT)) 
		addloadout(
			«FOR output : outputMap.keySet()»
			.b_add«outputMap.get(output)»(baseaddr_«portMap.get(output)»),
			«ENDFOR»
			.count(countOut),
			.port(port_out),
			.address(address_out)
		);
		
		// Memory Arbitration
		always @ (start,address_out,addressrd)
			if(start) 	address2mux=address_out;
			else 		address2mux=addressrd;
	
		always @ (start,enable_out,enablerd)
			if(start) 	enable2mux=enable_out;
			else 		enable2mux=enablerd;
	
		// Kernel ID Register Arbitration
		always @ (start,finish,kernelIDen)
			if(start) 	kernelIDenmux=finish;
			else 		kernelIDenmux=kernelIDen;
	
		always @ (start,kernelIDin)
			if(start)	kernelIDinmux=0;
			else 		kernelIDinmux=kernelIDin;
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
	
	def printAddrGen(){
		
		var dateFormat = new SimpleDateFormat("yyyy/MM/dd HH:mm:ss");
		var date = new Date();
		
		'''
		// ----------------------------------------------------------------------------
		//
		// Multi-Dataflow Composer tool - Platform Composer
		// Address Loader module 
		// Date: «dateFormat.format(date)»
		//
		// ----------------------------------------------------------------------------	
		
		// ----------------------------------------------------------------------------
		// Module Interface
		// ----------------------------------------------------------------------------
		module Address_Loader(
			«FOR signal : signals SEPARATOR "\n"»b_add«signal»,«ENDFOR»
			count,
			port,
			address
		);
		// ----------------------------------------------------------------------------
							 
		// ----------------------------------------------------------------------------
		// Module Parameters
		// ----------------------------------------------------------------------------
		parameter SIZEADDRESS = 5;
		parameter SIZECOUNT = 5;
		parameter SIZEPORT = 3;
		// ----------------------------------------------------------------------------

		// ----------------------------------------------------------------------------
		// Module Signals
		// ----------------------------------------------------------------------------
		// Input(s)
		«FOR signal : signals SEPARATOR "\n"»input [SIZEADDRESS-1:0] 	b_add«signal»;«ENDFOR»
		input [SIZECOUNT-1:0] 	count;
		input [SIZEPORT-1:0]	port;
		// Output(s)
		output reg [SIZEADDRESS-1:0] address;
		// ----------------------------------------------------------------------------

		// ----------------------------------------------------------------------------
		// Body
		// ----------------------------------------------------------------------------
		always @(«FOR signal : signals»b_add«signal»,«ENDFOR»port,count)
			case (port)
				«FOR signal : signals»«signal»:	address = b_add«signal» + count;«ENDFOR»
				default: 	address = 0;
			endcase
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
			«FOR port : portMap.keySet()»confin_«portMap.get(port)»,
			en_«portMap.get(port)»,
			baseaddr_«portMap.get(port)»,
			size_«portMap.get(port)»,
			sizeburst_«portMap.get(port)»,
			«ENDFOR»
			kernelIDin,			//Ingresso registro kernel ID
			kernelIDen,		//Enable registro kernel ID
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
		input clk;
		input reset;
		input [SIZEID-1:0] kernelIDin;
		input kernelIDen;
		«FOR port : portMap.keySet()»input [SIZEDATA-1:0] confin_«portMap.get(port)»;
		input en_«portMap.get(port)»;
		«ENDFOR»
		// Output(s)
		«FOR port : portMap.keySet()»output reg [SIZEADDRESS-1:0] baseaddr_«portMap.get(port)»;
		output reg [SIZECOUNT-1:0] size_«portMap.get(port)»;
		output reg [SIZEBURST-1:0] sizeburst_«portMap.get(port)»;
		«ENDFOR»
		output reg [SIZEID-1:0] kernelIDout;
		// ----------------------------------------------------------------------------			  
		
		// ----------------------------------------------------------------------------
		// Body
		// ----------------------------------------------------------------------------	
		// kernel ID
		always @ (posedge clk or posedge reset)
			if (reset)
				kernelIDout <= 0;
			else if (kernelIDen)
				kernelIDout <= kernelIDin;

		«FOR port : portMap.keySet()»
		// port «portMap.get(port)»
		always @ (posedge clk or posedge reset)
			if(reset)
				baseaddr_«portMap.get(port)» <= 0;
			else if (en_«portMap.get(port)»)
				baseaddr_«portMap.get(port)» <= confin_«portMap.get(port)»[SIZEADDRESS-1:0];
				
		always @ (posedge clk or posedge reset)
			if(reset)
				size_«portMap.get(port)» <= 0;
			else if (en_«portMap.get(port)»)
				size_«portMap.get(port)» <= confin_«portMap.get(port)»[SIZECOUNT-1+SIZEADDRESS:SIZEADDRESS];
				
		always @ (posedge clk or posedge reset)
			if(reset)
				sizeburst_«portMap.get(port)» <= 0;
			else if (en_«portMap.get(port)»)
				sizeburst_«portMap.get(port)» <= confin_«portMap.get(port)»[SIZEBURST-1+SIZECOUNT+SIZEADDRESS:SIZECOUNT+SIZEADDRESS];
				
		«ENDFOR»
		// ----------------------------------------------------------------------------
		
		endmodule		
		// ----------------------------------------------------------------------------
		// ----------------------------------------------------------------------------
		// ----------------------------------------------------------------------------
		'''
	}
	
	def printPortSel(int type){
		
		var dateFormat = new SimpleDateFormat("yyyy/MM/dd HH:mm:ss");
		var date = new Date();
		var inputArrayList = new ArrayList<Integer> (inputMap.values().sort());
		var outputArrayList = new ArrayList<Integer> (outputMap.values().sort());
		
		'''
		// ----------------------------------------------------------------------------
		//
		// Multi-Dataflow Composer tool - Platform Composer
		// «IF type!=INOUT»«IF type==IN»In «ELSE»Out «ENDIF»«ENDIF»Port Selector module 
		// Date: «dateFormat.format(date)»
		//
		// ----------------------------------------------------------------------------	
		
		// ----------------------------------------------------------------------------
		// Module Interface
		// ----------------------------------------------------------------------------
		module Port_Selector«IF type!=INOUT»«IF type==IN»_In«ELSE»_Out«ENDIF»«ENDIF»(
		«IF type==IN»
		«FOR index : inputArrayList»	ready«index»,«ENDFOR»
		«ELSE»
		«FOR index : outputArrayList»	ready«index»,«ENDFOR»
		«ENDIF»
			CurrentPort,
			SelectedPort
		);
		// ----------------------------------------------------------------------------	
		
		// ----------------------------------------------------------------------------
		// Module Parameters
		// ----------------------------------------------------------------------------
		parameter SIZEPORT = 3;
		// ----------------------------------------------------------------------------	
		
		// ----------------------------------------------------------------------------
		// Module Signals
		// ----------------------------------------------------------------------------
		// Input(s)
		«IF type==IN»
		«FOR index : inputArrayList SEPARATOR "\n"»input 		ready«index»;«ENDFOR»
		«ELSE»
		«FOR index : outputArrayList SEPARATOR "\n"»input 		ready«index»;«ENDFOR»
		«ENDIF»
		input[SIZEPORT-1 : 0] 		CurrentPort;
		// Output(s)
		output reg [SIZEPORT-1 : 0] SelectedPort;
		// ----------------------------------------------------------------------------	
		
		// ----------------------------------------------------------------------------
		// Body
		// ----------------------------------------------------------------------------
		«IF type==IN»
		always @ («FOR index : inputArrayList»ready«index»,«ENDFOR»CurrentPort)
			case(CurrentPort)
				0:	if (ready1)	SelectedPort = 1;
					«FOR index : inputArrayList»«IF index!=1»else if (ready«index»)	SelectedPort = «index»;«ENDIF»«ENDFOR»
					else 				SelectedPort = 0;
			«FOR index : inputArrayList» «index»:	if (ready«IF index<=(inputArrayList.size-1)»«index+1») SelectedPort = «index+1»;«ELSE»«1») SelectedPort = «1»;«ENDIF»
					«FOR otherIndex : inputArrayList»«IF otherIndex>index+1»else if (ready«otherIndex»)	SelectedPort = «otherIndex»;«ENDIF»
					«ENDFOR»
					«FOR otherIndex : inputArrayList»«IF (otherIndex<index+1)&&(index-otherIndex!=(inputArrayList.size-1))»else if (ready«otherIndex»)	SelectedPort = «otherIndex»;«ENDIF»
					«ENDFOR»
					else 				SelectedPort = 0;«ENDFOR»
				default: SelectedPort=0;
			endcase
		«ELSE»
		always @ («FOR index : outputArrayList»ready«index»,«ENDFOR»CurrentPort)
			case(CurrentPort)
				0:	if (ready1)	SelectedPort = 1;
					«FOR index : outputArrayList»«IF index!=1»else if (ready«index»)	SelectedPort = «index»;«ENDIF»«ENDFOR»
					else 				SelectedPort = 0;
			«FOR index : outputArrayList» «index»:	if (ready«IF index<=(outputArrayList.size-1)»«index+1») SelectedPort = «index+1»;«ELSE»«1») SelectedPort = «1»;«ENDIF»
					«FOR otherIndex : outputArrayList»«IF otherIndex>index+1»else if (ready«otherIndex»)	SelectedPort = «otherIndex»;«ENDIF»
					«ENDFOR»
					«FOR otherIndex : outputArrayList»«IF (otherIndex<index+1)&&(index-otherIndex!=(outputArrayList.size-1))»else if (ready«otherIndex»)	SelectedPort = «otherIndex»;«ENDIF»
					«ENDFOR»
					else 				SelectedPort = 0;«ENDFOR»
				default: SelectedPort=0;
			endcase
		«ENDIF»
		// ----------------------------------------------------------------------------
		
		endmodule		
		// ----------------------------------------------------------------------------
		// ----------------------------------------------------------------------------
		// ----------------------------------------------------------------------------
		'''
	}
	
	def printDemux(){
		
		var dateFormat = new SimpleDateFormat("yyyy/MM/dd HH:mm:ss");
		var date = new Date();
		
		'''
		// ----------------------------------------------------------------------------
		//
		// Multi-Dataflow Composer tool - Platform Composer
		// Demultiplexer module 
		// Date: «dateFormat.format(date)»
		//
		// ----------------------------------------------------------------------------	
		
		// ----------------------------------------------------------------------------
		// Module Interface
		// ----------------------------------------------------------------------------
		module Demultiplexer(		
			«FOR signal : signals»signal«signal»,«ENDFOR»
			port,		// selector
			mainsignal	
		);
		// ----------------------------------------------------------------------------
		
		// ----------------------------------------------------------------------------
		// Module Parameters
		// ----------------------------------------------------------------------------
		parameter SIZESIGNAL = 1;
		parameter SIZEPORT = 3;
		// ----------------------------------------------------------------------------

		// ----------------------------------------------------------------------------
		// Module Signals
		// ----------------------------------------------------------------------------
		// Input(s)
		input [SIZESIGNAL-1 : 0] 	mainsignal;
		input [SIZEPORT-1 : 0] 		port;
		// Output(s)
		«FOR signal : signals»output [SIZESIGNAL-1 : 0] 	signal«signal»;«ENDFOR»
		// ----------------------------------------------------------------------------

		// ----------------------------------------------------------------------------
		// Body
		// ----------------------------------------------------------------------------
		«FOR signal : signals»assign signal«signal» = (port==«signal») ? mainsignal : 0;«ENDFOR»
		// ----------------------------------------------------------------------------
		
		endmodule		
		// ----------------------------------------------------------------------------
		// ----------------------------------------------------------------------------
		// ----------------------------------------------------------------------------
		'''
	}
	
	def printMux(){
		
		var dateFormat = new SimpleDateFormat("yyyy/MM/dd HH:mm:ss");
		var date = new Date();
				
		'''
		// ----------------------------------------------------------------------------
		//
		// Multi-Dataflow Composer tool - Platform Composer
		// Multiplexer module 
		// Date: «dateFormat.format(date)»
		//
		// ----------------------------------------------------------------------------	
		
		// ----------------------------------------------------------------------------
		// Module Interface
		// ----------------------------------------------------------------------------
		module Multiplexer(
			«FOR signal : signals»signal«signal»,«ENDFOR»
			port,		// selector
			outsignal
		);
		// ----------------------------------------------------------------------------
						 						 
		// ----------------------------------------------------------------------------
		// Module Parameters
		// ----------------------------------------------------------------------------
		parameter SIZESIGNAL = 32;
		parameter SIZEPORT = 3;
		// ----------------------------------------------------------------------------
		
		// ----------------------------------------------------------------------------
		// Module Signals
		// ----------------------------------------------------------------------------
		// Input(s)
		«FOR signal : signals»input [SIZESIGNAL-1:0] signal«signal»;«ENDFOR»
		input [SIZEPORT-1:0] port;
		// Output(s)
		output reg [SIZESIGNAL-1:0]  outsignal;
		// ----------------------------------------------------------------------------
		
		// ----------------------------------------------------------------------------
		// Body
		// ----------------------------------------------------------------------------
		always @ («FOR signal : signals»signal«signal», «ENDFOR»port) begin
			«FOR signal : signals»
			if(port==«signal») 		outsignal = signal«signal»;
			else 
			«ENDFOR»	
			outsignal = 0;
		end
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
		var numReg =portMap.size+1;
		
		
		'''
		// ----------------------------------------------------------------------------
		//
		// Multi-Dataflow Composer tool - Platform Composer
		// User Logic Wrapper module 
		// Date: «dateFormat.format(date)»
		//
		// ----------------------------------------------------------------------------	
		
		/*
		ul_wrapper #(
			.C_SLV_AWIDTH(C_SLV_AWIDTH),
			.C_SLV_DWIDTH(C_SLV_DWIDTH),
			.C_NUM_REG(C_NUM_REG),
			.C_NUM_MEM(C_NUM_MEM)
		) wrapper_til (
			.Bus2IP_Clk(Bus2IP_Clk),				// Bus to IP clock
			.Bus2IP_Reset(Bus2IP_Reset),			// Bus to IP reset
			.Bus2IP_Addr(Bus2IP_Addr),			// Bus to IP address bus
			.Bus2IP_CS(Bus2IP_CS),				// Bus to IP chip select for user logic memory selection
			.Bus2IP_RNW(Bus2IP_RNW),				// Bus to IP read/not write
			.Bus2IP_Data(Bus2IP_Data),			// Bus to IP data bus
			.Bus2IP_BE(Bus2IP_BE),				// Bus to IP byte enables
			.Bus2IP_RdCE(Bus2IP_RdCE),			// Bus to IP read chip enable
			.Bus2IP_WrCE(Bus2IP_WrCE),			// Bus to IP write chip enable
			.IP2Bus_Data(IP2Bus_Data),			// IP to Bus data bus
			.IP2Bus_RdAck(IP2Bus_RdAck),			// IP to Bus read chip enable
			.IP2Bus_WrAck(IP2Bus_WrAck),			// IP to Bus write chip enable
			.IP2Bus_Error(IP2Bus_Error),			// IP to Bus error response
			.irq(irq)
		);
		*/
		
		// ----------------------------------------------------------------------------
		// Module Interface
		// ----------------------------------------------------------------------------
		module ul_wrapper(
			Bus2IP_Clk,				// Bus to IP clock
			Bus2IP_Reset,			// Bus to IP reset
			Bus2IP_Addr,			// Bus to IP address bus
			Bus2IP_CS,				// Bus to IP chip select for user logic memory selection
			Bus2IP_RNW,				// Bus to IP read/not write
			Bus2IP_Data,			// Bus to IP data bus
			Bus2IP_BE,				// Bus to IP byte enables
			Bus2IP_RdCE,			// Bus to IP read chip enable
			Bus2IP_WrCE,			// Bus to IP write chip enable
			IP2Bus_Data,			// IP to Bus data bus
			IP2Bus_RdAck,			// IP to Bus read chip enable
			IP2Bus_WrAck,			// IP to Bus write chip enable
			IP2Bus_Error,			// IP to Bus error response
			irq						// interrupt request
		);
		// ----------------------------------------------------------------------------
		
		// ----------------------------------------------------------------------------
		// Module Parameters
		// ----------------------------------------------------------------------------			  
		parameter C_SLV_AWIDTH 	= 32;
		parameter C_SLV_DWIDTH 	= 32;
		parameter C_NUM_REG	= «numReg»;
		parameter C_NUM_MEM 	= 1;
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
		// Input(s)
		input 						Bus2IP_Clk;
		input 						Bus2IP_Reset;
		input  [0:C_SLV_AWIDTH-1]	Bus2IP_Addr;
		input  [0:C_NUM_MEM-1]		Bus2IP_CS;
		input 						Bus2IP_RNW;
		input  [0:C_SLV_DWIDTH-1]	Bus2IP_Data;
		input  [0:C_SLV_DWIDTH/8-1]	Bus2IP_BE;
		input  [0:C_NUM_REG-1]		Bus2IP_RdCE;
		input  [0:C_NUM_REG-1]		Bus2IP_WrCE;
		output [0:C_SLV_DWIDTH-1]	IP2Bus_Data;
		output						IP2Bus_RdAck;
		output						IP2Bus_WrAck;
		output						IP2Bus_Error;
		output						irq;
		
		wire   [0:7]				slv_reg0;
		wire   [0:C_NUM_REG-1]		slv_reg_write_sel;
		wire   [0:C_SLV_DWIDTH-1]	slv_ip2bus_data;
		wire   [0:11]				addr_mem;
		wire						slv_read_ack;
		wire						slv_write_ack;
		reg							slv_read_ack_reg;
		reg							slv_write_ack_reg;
		// ----------------------------------------------------------------------------			  	
						
		// ----------------------------------------------------------------------------
		// Body
		// ----------------------------------------------------------------------------	
		
		always@(posedge Bus2IP_Clk)
			slv_write_ack_reg <= slv_write_ack;
		
		always@(posedge Bus2IP_Clk)
			slv_read_ack_reg <= slv_read_ack;
			
		assign IP2Bus_Data			= Bus2IP_CS[0] ? slv_ip2bus_data : {{24{1'b0}},slv_reg0};
		assign IP2Bus_WrAck 		= slv_write_ack_reg && slv_write_ack;
		assign IP2Bus_RdAck 		= slv_read_ack_reg && slv_read_ack;
		assign IP2Bus_Error 		= 0;
		
		assign slv_reg_write_sel 	= Bus2IP_WrCE;
		assign slv_write_ack 		= (Bus2IP_CS[0] && !Bus2IP_RNW) ||
										«FOR port : portMap.keySet()»
										Bus2IP_WrCE[«portMap.get(port)»] ||
										«ENDFOR»
										Bus2IP_WrCE[0];
		assign slv_read_ack 		= (Bus2IP_CS[0] && Bus2IP_RNW) ||
										«FOR port : portMap.keySet()»
										Bus2IP_RdCE[«portMap.get(port)»] ||
										«ENDFOR»
										Bus2IP_RdCE[0];
		assign read_mem 			= Bus2IP_CS[0] && Bus2IP_RNW;
		assign write_mem 			= Bus2IP_CS[0] && !Bus2IP_RNW;
		assign addr_mem 			= Bus2IP_Addr[18:29];
		
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
		) copr (
			.clk(Bus2IP_Clk),
			.rst(Bus2IP_Reset),
			.datain(Bus2IP_Data),
			.addressrd(addr_mem),
			.addresswr(addr_mem),
			.enablerd(read_mem),
			.enablewr(write_mem),
			.write(write_mem),
			.kernelIDin(Bus2IP_Data[24:31]),
			.kernelIDen(slv_reg_write_sel[0]),
			.kernelIDout(slv_reg0),
			«FOR port : portMap.keySet()»
			.confin_«portMap.get(port)»(Bus2IP_Data),
			.en_«portMap.get(port)»(slv_reg_write_sel[«portMap.get(port)»]),
			«ENDFOR»
			.dataout(slv_ip2bus_data),
			.finish(irq)
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
		'''TO BE FILLED'''
	}
	
	def printPao(int type, Network network){
		
		var dateFormat = new SimpleDateFormat("yyyy/MM/dd HH:mm:ss");
		var date = new Date();
		
		'''
		##############################################################################
		## Filename:          mm_accelerator.pao
		## Description:       Peripheral Analysis Order
		## Date:              «dateFormat.format(date)» (by Multi-Dataflow Composer - Platform Composer)
		##############################################################################
		
		lib proc_common_v3_00_a all vhdl
		lib plbv46_slave_single_v1_01_a all vhdl
		
		lib mm_accelerator_v1_00_a config_regs verilog
		lib mm_accelerator_v1_00_a DualPortMemory verilog
		lib mm_accelerator_v1_00_a address_generator verilog
		lib mm_accelerator_v1_00_a Cnt2 verilog
		«IF type != INOUT»
		lib mm_accelerator_v1_00_a port_selector_in verilog
		«ELSE»
		lib mm_accelerator_v1_00_a port_selector verilog
		«ENDIF»
		lib mm_accelerator_v1_00_a Reg verilog
		lib mm_accelerator_v1_00_a Reg2 verilog
		lib mm_accelerator_v1_00_a Start_Network verilog
		lib mm_accelerator_v1_00_a fsmIN_RDmem verilog
		lib mm_accelerator_v1_00_a demux verilog
		lib mm_accelerator_v1_00_a mux verilog
		lib SystemMdc mdc vhdl
		lib SystemBuilder sbtypes.vhdl vhdl
		lib SystemBuilder sbfifo.vhdl vhdl
		lib SystemBuilder sbfifo_behavioral.vhdl vhdl
		«FOR actor : network.children.filter(typeof(Actor))»
		«IF !actor.hasAttribute("sbox")»
		lib mm_accelerator_v1_00_a «actor.simpleName» verilog
		«ENDIF»
		«ENDFOR»
		lib mm_accelerator_v1_00_a configurator verilog
		lib mm_accelerator_v1_00_a multi_dataflow vhdl
		lib mm_accelerator_v1_00_a b_counter verilog
		lib mm_accelerator_v1_00_a afifo verilog
		lib mm_accelerator_v1_00_a fsmOUT_WRmem verilog
		«IF type != INOUT»
		lib mm_accelerator_v1_00_a port_selector_out verilog
		«ENDIF»
		lib mm_accelerator_v1_00_a coprocessor_til verilog
		lib mm_accelerator_v1_00_a ul_wrapper verilog
		lib mm_accelerator_v1_00_a user_logic verilog	
		lib mm_accelerator_v1_00_a mm_accelerator vhdl		
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
	
	def printDriverHighSrc(Network network, Map<String,Map<String,String>> networkVertexMap, ConfigManager configManager) {
		
		var dateFormat = new SimpleDateFormat("yyyy/MM/dd HH:mm:ss");
		var date = new Date();
		
		'''
		/*****************************************************************************
		*  Filename:          mm_accelerator_h.c
		*  Description:       Accelerator High Level Driver
		*  Date:              «dateFormat.format(date)» (by Multi-Dataflow Composer - Platform Composer)
		*****************************************************************************/
		
		#include "xil_io.h"
		#include "mm_accelerator_l.h"
		#include "mm_accelerator_h.h"

		int copr(«FOR id : portMap.values.sort SEPARATOR "\n"»		int b«id», int s«id», int sb«id», int* d«id»,«ENDFOR»
				int KID
		)
		{
			int i;
		
			«FOR port : portMap.keySet»
			COPROCESSOR_mWriteSlaveReg«portMap.get(port)»(0,0,sb«portMap.get(port)»<<24|s«portMap.get(port)»<<12|b«portMap.get(port)»);
			«ENDFOR»
			
			«FOR input : inputMap.keySet SEPARATOR "\n"»
			// scrittura vettore data «portMap.get(input)»
			if (s«portMap.get(input)»!=0) {
				for(i=0; i<s«portMap.get(input)»; i++) {
					COPROCESSOR_mWriteMemory(MEM_BASE_ADDR+(b«portMap.get(input)»<<2)+4*i,*(d«portMap.get(input)»+i));
				}
			}
			«ENDFOR»
		
			// Kernel ID
			COPROCESSOR_mWriteSlaveReg0(0,0,KID);
			while (COPROCESSOR_mReadSlaveReg0(0,0)!=0);
		
			«FOR output : outputMap.keySet SEPARATOR "\n"»
			// leggi vettore data «portMap.get(output)»
			if (s«portMap.get(output)»!=0)
			for(i=0; i<s«portMap.get(output)»; i++)
			*(d«portMap.get(output)»+i)=COPROCESSOR_mReadMemory(MEM_BASE_ADDR+(b«portMap.get(output)»<<2)+4*i);
			«ENDFOR»
		
			return 0;
		}
		
		«FOR net : netPorts.keySet»
		int copr_«net»(
		«FOR port : netPorts.get(net) SEPARATOR ","»
			int b«portMap.get(port)»,	// «port.name»
			int s«portMap.get(port)»,
			int sb«portMap.get(port)»,
			int* d«portMap.get(port)»
			«ENDFOR»
		)
		{
			«FOR port : portMap.keySet»
			«IF !networkVertexMap.get(net).values.contains(port.name)»
			int b«portMap.get(port)» = 0; 
			int s«portMap.get(port)» = 0;
			int sb«portMap.get(port)» = 0;
			int* d«portMap.get(port)» = 0;
			«ENDIF»
			«ENDFOR»
			
			
			copr(
				«FOR id : portMap.values.sort»
				«FOR port : portMap.keySet»
				«IF portMap.get(port).equals(id)»
				b«portMap.get(port)», s«portMap.get(port)», sb«portMap.get(port)», d«portMap.get(port)»,
				«ENDIF»
				«ENDFOR»
				«ENDFOR»
				«configManager.getNetworkId(net)»);
				
			return 0;
			
		}
		«ENDFOR»
		'''
		
	}
	
	def printDriverHighHead(Network network, Map<String,Map<String,String>> networkVertexMap) {
		
		var dateFormat = new SimpleDateFormat("yyyy/MM/dd HH:mm:ss");
		var date = new Date();
		computeNetsPorts(networkVertexMap);
		
		'''
		/*****************************************************************************
		*  Filename:          mm_accelerator_h.h
		*  Description:       Accelerator High Level Driver
		*  Date:              «dateFormat.format(date)» (by Multi-Dataflow Composer - Platform Composer)
		*****************************************************************************/
		
		#ifndef MM_ACCELERATOR_H_H
		#define MM_ACCELERATOR_H_H
		
		/***************************** Include Files *******************************/
		
		/************************** Constant Definitions ***************************/
		#define SIZEADDRESS 12;
		#define SIZECOUNT 12;
		/************************* Functions Definitions ***************************/
		
		int copr(
		«FOR id : portMap.values.sort SEPARATOR "\n"»		int b«id», int s«id», int sb«id», int* d«id»,«ENDFOR»
				int KID
		);
		
		«FOR net : netPorts.keySet»
		int copr_«net»(
			«FOR port : netPorts.get(net) SEPARATOR ","»
			// «port.name»
			int b«portMap.get(port)», int s«portMap.get(port)», int sb«portMap.get(port)», int* d«portMap.get(port)»
			«ENDFOR»
		);
		«ENDFOR»

		
		#endif /** MM_ACCELERATOR_H_H */
		'''
	}
	
	def printDriverLowHead(Network network){
		
		var dateFormat = new SimpleDateFormat("yyyy/MM/dd HH:mm:ss");
		var date = new Date();
		
		'''
		/*****************************************************************************
		*  Filename:          mm_accelerator_l.h
		*  Description:       Accelerator Low Level Driver
		*  Date:              «dateFormat.format(date)» (by Multi-Dataflow Composer - Platform Composer)
		*****************************************************************************/
		
		#ifndef MM_ACCELERATOR_L_H
		#define MM_ACCELERATOR_L_H
		
		/***************************** Include Files *******************************/
		
		#include "xbasic_types.h"
		#include "xil_io.h"
		
		/************************** Constant Definitions ***************************/
		
		
		/**
		 * User Logic Slave Space Offsets
		 * -- SLV_REG0 : user logic slave module register 0
		 * -- SLV_REG1 : user logic slave module register 1
		 * -- SLV_REG2 : user logic slave module register 2
		 * -- SLV_REG3 : user logic slave module register 3
		 * -- SLV_REG4 : user logic slave module register 4
		 * -- SLV_REG5 : user logic slave module register 5
		 * -- SLV_REG6 : user logic slave module register 6
		 * -- SLV_REG7 : user logic slave module register 7
		 * -- SLV_REG8 : user logic slave module register 8
		 * -- SLV_REG9 : user logic slave module register 9
		 * -- SLV_REG10 : user logic slave module register 10
		 * -- SLV_REG11 : user logic slave module register 11
		 * -- SLV_REG12 : user logic slave module register 12
		 * -- SLV_REG13 : user logic slave module register 13
		 * -- SLV_REG14 : user logic slave module register 14
		 * -- SLV_REG15 : user logic slave module register 15
		 */
		#define MEM_BASE_ADDR (0x00000000)
		#define COPROCESSOR_USER_SLV_SPACE_OFFSET (0x00000000)
		
		#define COPROCESSOR_SLV_REG0_OFFSET (COPROCESSOR_USER_SLV_SPACE_OFFSET + 0x00000000)
		#define COPROCESSOR_SLV_REG1_OFFSET (COPROCESSOR_USER_SLV_SPACE_OFFSET + 0x00000004)
		#define COPROCESSOR_SLV_REG2_OFFSET (COPROCESSOR_USER_SLV_SPACE_OFFSET + 0x00000008)
		#define COPROCESSOR_SLV_REG3_OFFSET (COPROCESSOR_USER_SLV_SPACE_OFFSET + 0x0000000C)
		#define COPROCESSOR_SLV_REG4_OFFSET (COPROCESSOR_USER_SLV_SPACE_OFFSET + 0x00000010)
		#define COPROCESSOR_SLV_REG5_OFFSET (COPROCESSOR_USER_SLV_SPACE_OFFSET + 0x00000014)
		#define COPROCESSOR_SLV_REG6_OFFSET (COPROCESSOR_USER_SLV_SPACE_OFFSET + 0x00000018)
		#define COPROCESSOR_SLV_REG7_OFFSET (COPROCESSOR_USER_SLV_SPACE_OFFSET + 0x0000001C)
		#define COPROCESSOR_SLV_REG8_OFFSET (COPROCESSOR_USER_SLV_SPACE_OFFSET + 0x00000020)
		#define COPROCESSOR_SLV_REG9_OFFSET (COPROCESSOR_USER_SLV_SPACE_OFFSET + 0x00000024)
		#define COPROCESSOR_SLV_REG10_OFFSET (COPROCESSOR_USER_SLV_SPACE_OFFSET + 0x00000028)
		#define COPROCESSOR_SLV_REG11_OFFSET (COPROCESSOR_USER_SLV_SPACE_OFFSET + 0x0000002C)
		#define COPROCESSOR_SLV_REG12_OFFSET (COPROCESSOR_USER_SLV_SPACE_OFFSET + 0x00000030)
		#define COPROCESSOR_SLV_REG13_OFFSET (COPROCESSOR_USER_SLV_SPACE_OFFSET + 0x00000034)
		#define COPROCESSOR_SLV_REG14_OFFSET (COPROCESSOR_USER_SLV_SPACE_OFFSET + 0x00000038)
		#define COPROCESSOR_SLV_REG15_OFFSET (COPROCESSOR_USER_SLV_SPACE_OFFSET + 0x0000003C)
		
		/**************************** Type Definitions *****************************/
		
		
		/***************** Macros (Inline Functions) Definitions *******************/
		
		/**
		 *
		 * Write a value to a COPROCESSOR register. A 32 bit write is performed.
		 * If the component is implemented in a smaller width, only the least
		 * significant data is written.
		 *
		 * @param   BaseAddress is the base address of the COPROCESSOR device.
		 * @param   RegOffset is the register offset from the base to write to.
		 * @param   Data is the data written to the register.
		 *
		 * @return  None.
		 *
		 * @note
		 * C-style signature:
		 * 	void COPROCESSOR_mWriteReg(Xuint32 BaseAddress, unsigned RegOffset, Xuint32 Data)
		 *
		 */
		#define COPROCESSOR_mWriteReg(BaseAddress, RegOffset, Data) \
		 	Xil_Out32((BaseAddress) + (RegOffset), (Xuint32)(Data))
		
		/**
		 *
		 * Read a value from a COPROCESSOR register. A 32 bit read is performed.
		 * If the component is implemented in a smaller width, only the least
		 * significant data is read from the register. The most significant data
		 * will be read as 0.
		 *
		 * @param   BaseAddress is the base address of the COPROCESSOR device.
		 * @param   RegOffset is the register offset from the base to write to.
		 *
		 * @return  Data is the data from the register.
		 *
		 * @note
		 * C-style signature:
		 * 	Xuint32 COPROCESSOR_mReadReg(Xuint32 BaseAddress, unsigned RegOffset)
		 *
		 */
		#define COPROCESSOR_mReadReg(BaseAddress, RegOffset) \
		 	Xil_In32((BaseAddress) + (RegOffset))
		
		
		/**
		 *
		 * Write/Read 32 bit value to/from COPROCESSOR user logic slave registers.
		 *
		 * @param   BaseAddress is the base address of the COPROCESSOR device.
		 * @param   RegOffset is the offset from the slave register to write to or read from.
		 * @param   Value is the data written to the register.
		 *
		 * @return  Data is the data from the user logic slave register.
		 *
		 * @note
		 * C-style signature:
		 * 	void COPROCESSOR_mWriteSlaveRegn(Xuint32 BaseAddress, unsigned RegOffset, Xuint32 Value)
		 * 	Xuint32 COPROCESSOR_mReadSlaveRegn(Xuint32 BaseAddress, unsigned RegOffset)
		 *
		 */
		#define COPROCESSOR_mWriteSlaveReg0(BaseAddress, RegOffset, Value) \
		 	Xil_Out32((BaseAddress) + (COPROCESSOR_SLV_REG0_OFFSET) + (RegOffset), (Xuint32)(Value))
		#define COPROCESSOR_mWriteSlaveReg1(BaseAddress, RegOffset, Value) \
		 	Xil_Out32((BaseAddress) + (COPROCESSOR_SLV_REG1_OFFSET) + (RegOffset), (Xuint32)(Value))
		#define COPROCESSOR_mWriteSlaveReg2(BaseAddress, RegOffset, Value) \
		 	Xil_Out32((BaseAddress) + (COPROCESSOR_SLV_REG2_OFFSET) + (RegOffset), (Xuint32)(Value))
		#define COPROCESSOR_mWriteSlaveReg3(BaseAddress, RegOffset, Value) \
		 	Xil_Out32((BaseAddress) + (COPROCESSOR_SLV_REG3_OFFSET) + (RegOffset), (Xuint32)(Value))
		#define COPROCESSOR_mWriteSlaveReg4(BaseAddress, RegOffset, Value) \
		 	Xil_Out32((BaseAddress) + (COPROCESSOR_SLV_REG4_OFFSET) + (RegOffset), (Xuint32)(Value))
		#define COPROCESSOR_mWriteSlaveReg5(BaseAddress, RegOffset, Value) \
		 	Xil_Out32((BaseAddress) + (COPROCESSOR_SLV_REG5_OFFSET) + (RegOffset), (Xuint32)(Value))
		#define COPROCESSOR_mWriteSlaveReg6(BaseAddress, RegOffset, Value) \
		 	Xil_Out32((BaseAddress) + (COPROCESSOR_SLV_REG6_OFFSET) + (RegOffset), (Xuint32)(Value))
		#define COPROCESSOR_mWriteSlaveReg7(BaseAddress, RegOffset, Value) \
		 	Xil_Out32((BaseAddress) + (COPROCESSOR_SLV_REG7_OFFSET) + (RegOffset), (Xuint32)(Value))
		#define COPROCESSOR_mWriteSlaveReg8(BaseAddress, RegOffset, Value) \
		 	Xil_Out32((BaseAddress) + (COPROCESSOR_SLV_REG8_OFFSET) + (RegOffset), (Xuint32)(Value))
		#define COPROCESSOR_mWriteSlaveReg9(BaseAddress, RegOffset, Value) \
		 	Xil_Out32((BaseAddress) + (COPROCESSOR_SLV_REG9_OFFSET) + (RegOffset), (Xuint32)(Value))
		#define COPROCESSOR_mWriteSlaveReg10(BaseAddress, RegOffset, Value) \
		 	Xil_Out32((BaseAddress) + (COPROCESSOR_SLV_REG10_OFFSET) + (RegOffset), (Xuint32)(Value))
		#define COPROCESSOR_mWriteSlaveReg11(BaseAddress, RegOffset, Value) \
		 	Xil_Out32((BaseAddress) + (COPROCESSOR_SLV_REG11_OFFSET) + (RegOffset), (Xuint32)(Value))
		#define COPROCESSOR_mWriteSlaveReg12(BaseAddress, RegOffset, Value) \
		 	Xil_Out32((BaseAddress) + (COPROCESSOR_SLV_REG12_OFFSET) + (RegOffset), (Xuint32)(Value))
		#define COPROCESSOR_mWriteSlaveReg13(BaseAddress, RegOffset, Value) \
		 	Xil_Out32((BaseAddress) + (COPROCESSOR_SLV_REG13_OFFSET) + (RegOffset), (Xuint32)(Value))
		#define COPROCESSOR_mWriteSlaveReg14(BaseAddress, RegOffset, Value) \
		 	Xil_Out32((BaseAddress) + (COPROCESSOR_SLV_REG14_OFFSET) + (RegOffset), (Xuint32)(Value))
		#define COPROCESSOR_mWriteSlaveReg15(BaseAddress, RegOffset, Value) \
		 	Xil_Out32((BaseAddress) + (COPROCESSOR_SLV_REG15_OFFSET) + (RegOffset), (Xuint32)(Value))
		
		#define COPROCESSOR_mReadSlaveReg0(BaseAddress, RegOffset) \
		 	Xil_In32((BaseAddress) + (COPROCESSOR_SLV_REG0_OFFSET) + (RegOffset))
		#define COPROCESSOR_mReadSlaveReg1(BaseAddress, RegOffset) \
		 	Xil_In32((BaseAddress) + (COPROCESSOR_SLV_REG1_OFFSET) + (RegOffset))
		#define COPROCESSOR_mReadSlaveReg2(BaseAddress, RegOffset) \
		 	Xil_In32((BaseAddress) + (COPROCESSOR_SLV_REG2_OFFSET) + (RegOffset))
		#define COPROCESSOR_mReadSlaveReg3(BaseAddress, RegOffset) \
		 	Xil_In32((BaseAddress) + (COPROCESSOR_SLV_REG3_OFFSET) + (RegOffset))
		#define COPROCESSOR_mReadSlaveReg4(BaseAddress, RegOffset) \
		 	Xil_In32((BaseAddress) + (COPROCESSOR_SLV_REG4_OFFSET) + (RegOffset))
		#define COPROCESSOR_mReadSlaveReg5(BaseAddress, RegOffset) \
		 	Xil_In32((BaseAddress) + (COPROCESSOR_SLV_REG5_OFFSET) + (RegOffset))
		#define COPROCESSOR_mReadSlaveReg6(BaseAddress, RegOffset) \
		 	Xil_In32((BaseAddress) + (COPROCESSOR_SLV_REG6_OFFSET) + (RegOffset))
		#define COPROCESSOR_mReadSlaveReg7(BaseAddress, RegOffset) \
		 	Xil_In32((BaseAddress) + (COPROCESSOR_SLV_REG7_OFFSET) + (RegOffset))
		#define COPROCESSOR_mReadSlaveReg8(BaseAddress, RegOffset) \
		 	Xil_In32((BaseAddress) + (COPROCESSOR_SLV_REG8_OFFSET) + (RegOffset))
		#define COPROCESSOR_mReadSlaveReg9(BaseAddress, RegOffset) \
		 	Xil_In32((BaseAddress) + (COPROCESSOR_SLV_REG9_OFFSET) + (RegOffset))
		#define COPROCESSOR_mReadSlaveReg10(BaseAddress, RegOffset) \
		 	Xil_In32((BaseAddress) + (COPROCESSOR_SLV_REG10_OFFSET) + (RegOffset))
		#define COPROCESSOR_mReadSlaveReg11(BaseAddress, RegOffset) \
		 	Xil_In32((BaseAddress) + (COPROCESSOR_SLV_REG11_OFFSET) + (RegOffset))
		#define COPROCESSOR_mReadSlaveReg12(BaseAddress, RegOffset) \
		 	Xil_In32((BaseAddress) + (COPROCESSOR_SLV_REG12_OFFSET) + (RegOffset))
		#define COPROCESSOR_mReadSlaveReg13(BaseAddress, RegOffset) \
		 	Xil_In32((BaseAddress) + (COPROCESSOR_SLV_REG13_OFFSET) + (RegOffset))
		#define COPROCESSOR_mReadSlaveReg14(BaseAddress, RegOffset) \
		 	Xil_In32((BaseAddress) + (COPROCESSOR_SLV_REG14_OFFSET) + (RegOffset))
		#define COPROCESSOR_mReadSlaveReg15(BaseAddress, RegOffset) \
		 	Xil_In32((BaseAddress) + (COPROCESSOR_SLV_REG15_OFFSET) + (RegOffset))
		
		/**
		 *
		 * Write/Read 32 bit value to/from COPROCESSOR user logic memory (BRAM).
		 *
		 * @param   Address is the memory address of the COPROCESSOR device.
		 * @param   Data is the value written to user logic memory.
		 *
		 * @return  The data from the user logic memory.
		 *
		 * @note
		 * C-style signature:
		 * 	void COPROCESSOR_mWriteMemory(Xuint32 Address, Xuint32 Data)
		 * 	Xuint32 COPROCESSOR_mReadMemory(Xuint32 Address)
		 *
		 */
		#define COPROCESSOR_mWriteMemory(Address, Data) \
		 	Xil_Out32(Address, (Xuint32)(Data))
		#define COPROCESSOR_mReadMemory(Address) \
		 	Xil_In32(Address)
		
		
		#endif /** MM_ACCELERATOR_L_H */
		
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