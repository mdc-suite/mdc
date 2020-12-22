package it.mdc.tool.core.platformComposer;

import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.ArrayList;
import java.util.Map;
import java.util.Set;

import net.sf.orcc.df.Actor;
import net.sf.orcc.df.Instance;
import net.sf.orcc.df.Network;
import net.sf.orcc.df.Port;
import net.sf.orcc.graph.Edge;
import net.sf.orcc.graph.Vertex;
import net.sf.orcc.ir.Expression;
import net.sf.orcc.ir.util.ExpressionEvaluator;
import net.sf.orcc.util.OrccLogger;
import it.mdc.tool.core.ConfigManager;
import it.mdc.tool.core.sboxManagement.SboxLut;
import it.mdc.tool.core.platformComposer.ConfigPrinter;
import it.mdc.tool.prototyping.DriverPrinter;
import it.mdc.tool.prototyping.ScriptPrinter;
import it.mdc.tool.prototyping.WrapperPrinter;
import it.mdc.tool.utility.FileCopier;
import it.mdc.tool.prototyping.ArticoPrinter;
import it.mdc.tool.prototyping.PulpPrinter;
import it.mdc.tool.powerSaving.CgCellPrinter;
import it.mdc.tool.powerSaving.EnGenPrinter;
import net.sf.orcc.df.Connection;

import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.File;
import java.io.PrintStream;

/**
 * 
 * This class generates the source code and 
 * related files for the multi-dataflow implementation
 * 
 * @author Carlo Sau
 * @see it.unica.diee.mdc.utility package
 */
public abstract class PlatformComposer {
	
	/**
	 * The port flag values of sbox actors
	 */
	protected final static int INPUT_1 	= 0;
	protected final static int INPUT_2 	= 1;
	protected final static int OUTPUT_1 = 2;
	protected final static int OUTPUT_2 = 3;

	/**
	 * General output path
	 */
	protected String hdlPath;

	/**
	 * General output path
	 */
	protected ProtocolManager protocolManager;

	/**
	 * Clock domains of the network 
	 */
	protected Map<String,Set<String>> clockDomains;
	
	/**
	 * Logic Regions (LRs) of instances
	 */
	protected Map<String,Set<String>> logicRegions;

	/**
	 * Map of the LRs indices
	 */
	protected Map<String, Integer> logicRegionID;
	
	/**
	 * Map of the LRs for each networks
	 */
	
	protected Map<String,Set<String>> netRegions;
	
	/**
	 * Set of LRs that can be switched off
	 */
	
	protected Set<String> powerSets;
	
	/**
	 * Map with a index for each switchable LR
	 */
	
	protected Map<String,Integer> powerSetsIndex;
	
	/**
	 * Map of the type of regions. true is the region is sequential*/
	
	protected Map<String,Boolean> logicRegionsSeqMap;
	
	
	/**
	 * Domain gated sets
	 */
	protected Map<String,Map<String,Set<String>>> domainGatedSets;
	
	/**
	 * Multi-dataflow network
	 */
	protected Network network;
	
	/**
	 * Protocol signals flags
	 */
	protected final static int DIRECTION = 0;
	protected final static int OUT_PORT = 1;
	protected final static int SIZE = 2;
	protected final static int IN_PORT = 3;
	protected final static int IS_NATIVE = 4;
	protected final static int PORT = 1;
	
	/**
	 * Expression evaluator
	 */
	protected ExpressionEvaluator evaluator;
	
	/**
	 * Configuration manager
	 */
	protected ConfigManager configManager;
	
	protected final static int INOUT = 0;
	protected final static int IN = 1;
	protected final static int OUT = 2;
	
	/**
	 * The constructor
	 * 
	 * @param outPath
	 * 		generic output path
	 * @param configManager
	 * 		manager of the network configuration	
	 * @param network
	 * 		multi-dataflow network
	 * @throws IOException
	 */
	public PlatformComposer(String outPath, ConfigManager configManager, Network network, String protocolFile) throws IOException {
		
		this.hdlPath = outPath;
		this.network = network;
		this.configManager = configManager;
		logicRegions = new HashMap<String,Set<String>>();
		netRegions = new HashMap<String,Set<String>>();
		evaluator = new ExpressionEvaluator();
		protocolManager = new ProtocolManager(protocolFile);
	}
	
	/**
	 * Assign print flag to the vertex parameter
	 * 
	 * @param vertex
	 * 		printed vertex
	 */
	protected void assignPrintFlag(Vertex vertex) {
		vertex.setAttribute("printed", (Object) null);
	}

	/**
	 * Generate the multi-dataflow network top module
	 * 
	 * @param luts
	 * 		configuration Look-Up Tables
	 * @param options
	 * @throws IOException
	 */
	public void generateTop (List<SboxLut> luts, Map<String,Object> options) throws IOException
	{
		printNetwork(luts,options);
	}
	
	/**
	 * Generate the configurator top module
	 * 
	 * @param genCopr
	 * @param luts
	 * 		configuration Look-Up Tables
	 * @throws IOException
	 */
	public void generateConfig (boolean genCopr, List<SboxLut> luts) throws IOException{

		File dir = new File(hdlPath);
		// If directory doesn't exist, create it
		if (!dir.exists()) {
			dir.mkdirs();
		}
		
		String file = dir.getPath()  + File.separator + "configurator.v";
		
		CharSequence sequence = new ConfigPrinter().printConfig(network,luts,configManager);

		try {
			PrintStream ps = new PrintStream(new FileOutputStream(file));
			ps.print(sequence.toString());
			ps.close();
		} catch (FileNotFoundException e) {
			OrccLogger.severeln("File Not Found Exception: " + e.getMessage());
		}
		
	}
	
	/**
	 * Wrap the multi-dataflow network with the logic necessary to
	 * generate a ARTICo3 Compliant Kernel
	 * 
	 * @return
	 * @throws IOException 
	 */
	public void generateArticoKernel(List<SboxLut> luts, Map<String,Map<String,String>> networkVertexMap, Map<String,Object> options) throws IOException {			
		
		//	Enable Monitoring
		Boolean enableMonitoring = (Boolean) options.get("it.unica.diee.mdc.monitoring");
		List<String> monList = new ArrayList<String>();
		
		// Initialize List of monitors
		
		if((Boolean) options.get("it.unica.diee.mdc.monFifo"))
			for(Port port: network.getInputs())
				monList.add("count_full_" + port.getName());
		
		if((Boolean) options.get("it.unica.diee.mdc.monCC"))
			monList.add("count_clock_cycles");
		
		if((Boolean) options.get("it.unica.diee.mdc.monInTokens"))
			for(Port port: network.getInputs())
				monList.add("count_in_tokens_" + port.getName());
		
		if((Boolean) options.get("it.unica.diee.mdc.outTokens"))
			for(Port port: network.getOutputs())
				monList.add("count_out_tokens_" + port.getName());
				
		
		/// <ul>
		String file;
		CharSequence sequence;

		ArticoPrinter articoPrinter;
		

		/// <li> Initialize TIL printer
		articoPrinter = new ArticoPrinter();
		((ArticoPrinter) articoPrinter).initArticoPrinter(enableMonitoring,monList,
				protocolManager.getNetSysSignals(),
				protocolManager.getModCommSignals(),
				protocolManager.getWrapCommSignals());

		
		////////////////////////
		/// <li> HDL sources 
		
		File hdlDir = new File(hdlPath);
		// If directory doesn't exist, create it
		if (!hdlDir.exists()) {
			hdlDir.mkdirs();
		}
		
		// TODO fix stream with tlast signal generation (slv_reg and counter!)
		
		/// <ol> <li> Generate top module
		file = hdlDir.getPath() + File.separator +  "cgr_accelerator.v";
		sequence = articoPrinter.printTop(network);
		try {
			PrintStream ps = new PrintStream(new FileOutputStream(file));
			ps.print(sequence.toString());
			ps.close();
		} catch (FileNotFoundException e) {
			OrccLogger.severeln("File Not Found Exception: " + e.getMessage());
		}
		

		
		/// <li> Generate XML configuration file for the MDC-PAPI component
		if(enableMonitoring){
			file = hdlDir.getPath().replaceFirst("src" + File.separator + "a3_cgr_accelerator" + File.separator + "verilog", "") + File.separator +  "mdc-papi_info.xml";
			sequence = articoPrinter.printXML();
			try {
				PrintStream ps = new PrintStream(new FileOutputStream(file));
				ps.print(sequence.toString());
				ps.close();
			} catch (FileNotFoundException e) {
				OrccLogger.severeln("File Not Found Exception: " + e.getMessage());
			}
		}
				

		
		/// </ol> </ul>
		/////////////////////////
	}
	

	/**
	 * Generates all the directory hierarchy necessary to generate
	 * a Pulp Compliant HWPE Wrapper
	 * 
	 */
	public void generatePulpStaticFolders(String hwpeWrapperGeneratorPath, String outputPath) {

		FileCopier copier = new FileCopier();
		// output/deps 
		File deps = new File(outputPath + File.separator + "deps");
		// If directory doesn't exist, create it
		if (!deps.exists()) {
			deps.mkdirs();
		}
		// output/deps/hwpe-multidataflow-wrapper
		File hwpeMultiDataflowWrapper = new File(deps + File.separator + "hwpe-multidataflow-wrapper");
		// If directory doesn't exist, create it
		if (!hwpeMultiDataflowWrapper.exists()) {
			hwpeMultiDataflowWrapper.mkdirs();
		}
		// output/deps/hwpe-multidataflow-wrapper/rtl
		File hwpeMultiDataflowWrapperRtl = new File(hwpeMultiDataflowWrapper + File.separator + "rtl");
		// If directory doesn't exist, create it
		if (!hwpeMultiDataflowWrapperRtl.exists()) {
			hwpeMultiDataflowWrapperRtl.mkdirs();
		}		
		// output/deps/hwpe-multidataflow-wrapper/rtl/hwpe-ctrl
		try {
			copier.copy(hwpeWrapperGeneratorPath + File.separator + "static" + File.separator + "static_rtl" + File.separator + 
					"hwpe-ctrl" + File.separator + "rtl", hwpeMultiDataflowWrapperRtl + File.separator + "hwpe-ctrl");
		} catch (IOException e) {
			OrccLogger.severeln("The hwpe-ctrl folder could not have been copied: " + e.getMessage());
		}

		// output/deps/hwpe-multidataflow-wrapper/rtl/hwpe-engine
		File hwpeEngine = new File(hwpeMultiDataflowWrapperRtl + File.separator + "hwpe-engine");
		// If directory doesn't exist, create it
		if (!hwpeEngine.exists()) {
			hwpeEngine.mkdirs();
		}	
		// output/deps/hwpe-multidataflow-wrapper/rtl/hwpe-engine/engine_dev
		File hwpeEngineDev = new File(hwpeEngine + File.separator + "engine_dev");
		// If directory doesn't exist, create it
		if (!hwpeEngineDev.exists()) {
			hwpeEngineDev.mkdirs();
		}		
		// output/deps/hwpe-multidataflow-wrapper/rtl/hwpe-stream
		try {
		copier.copy(hwpeWrapperGeneratorPath + File.separator + "static" + File.separator + "static_rtl" + File.separator + 
				"hwpe-stream" + File.separator + "rtl", hwpeMultiDataflowWrapperRtl + File.separator + "hwpe-stream");
		} catch (IOException e) {
			OrccLogger.severeln("The hwpe-stream folder could not have been copied: " + e.getMessage());
		}
		// output/deps/hwpe-multidataflow-wrapper/rtl/wrap
		File hwpeWrap = new File(hwpeMultiDataflowWrapperRtl + File.separator + "wrap");
		// If directory doesn't exist, create it
		if (!hwpeWrap.exists()) {
			hwpeWrap.mkdirs();
		}		
		// output/deps/hwpe-multidataflow-wrapper/sw
		File hwpeMultiDataflowWrapperSw = new File(hwpeMultiDataflowWrapper + File.separator + "sw");
		// If directory doesn't exist, create it
		if (!hwpeMultiDataflowWrapperSw.exists()) {
			hwpeMultiDataflowWrapperSw.mkdirs();
		}
		// output/deps/hwpe-multidataflow-wrapper/sw/hwpe-multidataflow-riscv
		File hwpeMultiDataflowRiscV = new File(hwpeMultiDataflowWrapperSw + File.separator + "hwpe-multidataflow-riscv");
		// If directory doesn't exist, create it
		if (!hwpeMultiDataflowRiscV.exists()) {
			hwpeMultiDataflowRiscV.mkdirs();
		}
		// output/deps/hwpe-multidataflow-wrapper/sw/hwpe-multidataflow-riscv/inc
		File hwpeMultiDataflowRiscVInc = new File(hwpeMultiDataflowRiscV + File.separator + "inc");
		// If directory doesn't exist, create it
		if (!hwpeMultiDataflowRiscVInc.exists()) {
			hwpeMultiDataflowRiscVInc.mkdirs();
		}
		// output/deps/hwpe-multidataflow-wrapper/sw/hwpe-multidataflow-riscv/inc/common
		try {
		copier.copy(hwpeWrapperGeneratorPath + File.separator + "static" + File.separator + "static_baremetal" + File.separator + 
				"inc" + File.separator + "common", hwpeMultiDataflowRiscVInc + File.separator + "common");
		} catch (IOException e) {
			OrccLogger.severeln("The hwpe-common folder could not have been copied: " + e.getMessage());
		}
		// output/deps/hwpe-multidataflow-wrapper/sw/hwpe-multidataflow-riscv/inc/hero_lib
		try {
		copier.copy(hwpeWrapperGeneratorPath + File.separator + "static" + File.separator + "static_baremetal" + File.separator + 
				"inc" + File.separator + "hero_lib", hwpeMultiDataflowRiscVInc + File.separator + "hero_lib");
		} catch (IOException e) {
			OrccLogger.severeln("The hero_lib folder could not have been copied: " + e.getMessage());
		}
		// output/deps/hwpe-multidataflow-wrapper/sw/hwpe-multidataflow-riscv/inc/hwpe_lib
		File hwpeLib = new File(hwpeMultiDataflowRiscVInc + File.separator + "hwpe_lib");
		// If directory doesn't exist, create it
		if (!hwpeLib.exists()) {
			hwpeLib.mkdirs();
		}
		// output/deps/hwpe-multidataflow-wrapper/sw/hwpe-multidataflow-riscv/inc/stim
		File hwpeStim = new File(hwpeMultiDataflowRiscVInc + File.separator + "stim");
		// If directory doesn't exist, create it
		if (!hwpeStim.exists()) {
			hwpeStim.mkdirs();
		}
		// output/deps/hwpe-multidataflow-wrapper/sw/hwpe-multidataflow-riscv/inc/sw_tb
		/*
		 * sw_tb
		 */
		// output/deps/hwpe-multidataflow-wrapper/sw/hwpe-multidataflow-riscv/inc/test_lib
		try {
		copier.copy(hwpeWrapperGeneratorPath + File.separator + "static" + File.separator + "static_baremetal" + File.separator + 
				"inc" + File.separator + "test_lib", hwpeMultiDataflowRiscVInc + File.separator + "test_lib");
		} catch (IOException e) {
			OrccLogger.severeln("The test_lib folder could not have been copied: " + e.getMessage());
		}
		// output/deps/hwpe-multidataflow-wrapper/sw/hwpe-multidataflow-riscv/Makefile file
		File makefile = new File(hwpeWrapperGeneratorPath + File.separator + "static" + File.separator + "static_baremetal");
		try {
		copier.copy(makefile, hwpeMultiDataflowRiscV);
		} catch (IOException e) {
			OrccLogger.severeln("The Malefile could not have been copied: " + e.getMessage());
		}
		// output/deps/pulp_cluster
		File pulp_cluster = new File(deps + File.separator + "pulp_cluster");
		// If directory doesn't exist, create it
		if (!pulp_cluster.exists()) {
			pulp_cluster.mkdirs();
		}
		// output/deps/pulp_cluster/rtl
		File pulp_cluster_rtl = new File(pulp_cluster + File.separator + "rtl");
		// If directory doesn't exist, create it
		if (!pulp_cluster_rtl.exists()) {
			pulp_cluster_rtl.mkdirs();
		}
		// output/src
		File src = new File(outputPath + File.separator + "src");
		// If directory doesn't exist, create it
		if (!src.exists()) {
			src.mkdirs();
		}
		// output/test
		File test = new File(outputPath + File.separator + "test");
		// If directory doesn't exist, create it
		if (!test.exists()) {
			test.mkdirs();
		}
	}
	
	/**
	 * Wrap the multi-dataflow network with the logic necessary to
	 * generate a Pulp Compliant HWPE Wrapper
	 * 
	 * @return
	 * @throws IOException 
	 */
	public void generatePulpWrapper(List<SboxLut> luts, Map<String,Map<String,String>> networkVertexMap, Map<String,Object> options) throws IOException {			
		
		/// <ul>
		String file;
		CharSequence sequence;
		String hdlCompLib = (String) options.get("it.mdc.tool.hdlCompLib");

		PulpPrinter pulpPrinter;
		

		/// <li> Initialize TIL printer
		pulpPrinter = new PulpPrinter();
		((PulpPrinter) pulpPrinter).initPulpPrinter(
				luts,
				protocolManager.getNetSysSignals(),
				protocolManager.getModCommSignals(),
				protocolManager.getWrapCommSignals(),
				network);

		
		////////////////////////
		/// <li> HDL sources 
		//output/deps/hwpe-multidataflow-wrapper/rtl/hwpe-engine
		File hdlDir = new File(hdlPath + File.separator + "deps" + File.separator + "hwpe-multidataflow-wrapper" + 
							File.separator + "rtl" + File.separator + "hwpe-engine");
		// If directory doesn't exist, create it
		if (!hdlDir.exists()) {
			hdlDir.mkdirs();
		}
		
		// TODO fix stream with tlast signal generation (slv_reg and counter!)
		
		
		/// <ol> <li> Generate multi_dataflow_reconf_datapath_top
		file = hdlDir.getPath() + File.separator +  "multi_dataflow_reconf_datapath_top.sv";
		sequence = pulpPrinter.printTop(network);
		try {
			PrintStream ps = new PrintStream(new FileOutputStream(file));
			ps.print(sequence.toString());
			ps.close();
		} catch (FileNotFoundException e) {
			OrccLogger.severeln("File Not Found Exception: " + e.getMessage());
		}
		
		/// </ol> </ul>
		/////////////////////////
		
		
		/// <ol> <li> Generate multi_dataflow_engine
		file = hdlDir.getPath() + File.separator +  "multi_dataflow_engine.sv";
		sequence = pulpPrinter.printEngine();
		try {
			PrintStream ps = new PrintStream(new FileOutputStream(file));
			ps.print(sequence.toString());
			ps.close();
		} catch (FileNotFoundException e) {
			OrccLogger.severeln("File Not Found Exception: " + e.getMessage());
		}
		
		/// </ol> </ul>
		/////////////////////////

		/// <ol> <li> Generate top module
		file = hdlDir.getPath() + File.separator +  "multi_dataflow_top.sv";
		sequence = pulpPrinter.printPulpTop();
		try {
			PrintStream ps = new PrintStream(new FileOutputStream(file));
			ps.print(sequence.toString());
			ps.close();
		} catch (FileNotFoundException e) {
			OrccLogger.severeln("File Not Found Exception: " + e.getMessage());
		}
		
		/// </ol> </ul>
		/////////////////////////
		
		/// <ol> <li> Generate streamer
		file = hdlDir.getPath() + File.separator +  "multi_dataflow_streamer.sv";
		sequence = pulpPrinter.printStreamer();
		try {
			PrintStream ps = new PrintStream(new FileOutputStream(file));
			ps.print(sequence.toString());
			ps.close();
		} catch (FileNotFoundException e) {
			OrccLogger.severeln("File Not Found Exception: " + e.getMessage());
		}
		
		/// </ol> </ul>
		/////////////////////////

		/// <ol> <li> Generate ctrl
		file = hdlDir.getPath() + File.separator +  "multi_dataflow_ctrl.sv";
		sequence = pulpPrinter.printCtrl();
		try {
			PrintStream ps = new PrintStream(new FileOutputStream(file));
			ps.print(sequence.toString());
			ps.close();
		} catch (FileNotFoundException e) {
			OrccLogger.severeln("File Not Found Exception: " + e.getMessage());
		}
		
		/// </ol> </ul>
		/////////////////////////

		/// <ol> <li> Generate FSM
		file = hdlDir.getPath() + File.separator +  "multi_dataflow_fsm.sv";
		sequence = pulpPrinter.printFSM();
		try {
			PrintStream ps = new PrintStream(new FileOutputStream(file));
			ps.print(sequence.toString());
			ps.close();
		} catch (FileNotFoundException e) {
			OrccLogger.severeln("File Not Found Exception: " + e.getMessage());
		}
		
		/// </ol> </ul>
		/////////////////////////

		/// <ol> <li> Generate package
		file = hdlDir.getPath() + File.separator +  "multi_dataflow_package.sv";
		sequence = pulpPrinter.printPackage();
		try {
			PrintStream ps = new PrintStream(new FileOutputStream(file));
			ps.print(sequence.toString());
			ps.close();
		} catch (FileNotFoundException e) {
			OrccLogger.severeln("File Not Found Exception: " + e.getMessage());
		}
		
		/// </ol> </ul>
		/////////////////////////

		/// <ol> <li> Generate Wrap
		File wrapDir = new File(hdlDir.getPath().replaceFirst("hwpe-engine","wrap"));
		// If directory doesn't exist, create it
		if (!wrapDir.exists()) {
			wrapDir.mkdirs();
		}
		file = wrapDir.getPath() + File.separator + "multi_dataflow_top_wrapper.sv";
		sequence = pulpPrinter.printWrap();
		try {
			PrintStream ps = new PrintStream(new FileOutputStream(file));
			ps.print(sequence.toString());
			ps.close();
		} catch (FileNotFoundException e) {
			OrccLogger.severeln("File Not Found Exception: " + e.getMessage());
		}
		
		/// </ol> </ul>
		/////////////////////////

		/// <ol> <li> Generate Bender
		file = hdlPath + File.separator + "deps" + File.separator + "hwpe-multidataflow-wrapper" + 
				File.separator + "Bender.yml";
		//hdlDir.getPath().replaceFirst("rtl","") + File.separator +  "src_files.yml";
		sequence = pulpPrinter.printBender(hdlCompLib);
		try {
			PrintStream ps = new PrintStream(new FileOutputStream(file));
			ps.print(sequence.toString());
			ps.close();
		} catch (FileNotFoundException e) {
			OrccLogger.severeln("File Not Found Exception: " + e.getMessage());
		}
		
		/// </ol> </ul>
		/////////////////////////


		/// <ol> <li> Generate pulp_hwpe_wrap
		file = hdlPath + File.separator + "deps" + File.separator + "pulp_cluster" + 
				File.separator + "rtl" + File.separator + "pulp_hwpe_wrap.sv";
		sequence = pulpPrinter.printPulpHwpeWrap();
		try {
			PrintStream ps = new PrintStream(new FileOutputStream(file));
			ps.print(sequence.toString());
			ps.close();
		} catch (FileNotFoundException e) {
			OrccLogger.severeln("File Not Found Exception: " + e.getMessage());
		}
		
		/// </ol> </ul>
		/////////////////////////


		/// <ol> <li> Generate pulp_cluster_hwpe_pkg
		file = hdlPath + File.separator + "src" + File.separator + "pulp_cluster_hwpe_pkg.sv";
		sequence = pulpPrinter.printPulpClusterHwpePkg();
		try {
			PrintStream ps = new PrintStream(new FileOutputStream(file));
			ps.print(sequence.toString());
			ps.close();
		} catch (FileNotFoundException e) {
			OrccLogger.severeln("File Not Found Exception: " + e.getMessage());
		}
		
		/// </ol> </ul>
		/////////////////////////


		/// <ol> <li> Generate pulp_cluster_hwpe_pkg
		file = hdlPath + File.separator + "test" + File.separator + "pulp_tb.wave.do";
		sequence = pulpPrinter.printPulpTbWave();
		try {
			PrintStream ps = new PrintStream(new FileOutputStream(file));
			ps.print(sequence.toString());
			ps.close();
		} catch (FileNotFoundException e) {
			OrccLogger.severeln("File Not Found Exception: " + e.getMessage());
		}
		
		/// </ol> </ul>
		/////////////////////////

		/*
		 * Now it's time to generate the sw part
		 */

		/// <ol> <li> Generate archi_hwpe.h
		file = hdlPath + File.separator + "deps" + File.separator + "hwpe-multidataflow-wrapper" + File.separator + "sw" + File.separator +
						"hwpe-multidataflow-riscv" + File.separator + "inc" + File.separator + "hwpe_lib" + File.separator + 
						"archi_hwpe.h";
		sequence = pulpPrinter.printRiscvArchiHwpe();
		try {
			PrintStream ps = new PrintStream(new FileOutputStream(file));
			ps.print(sequence.toString());
			ps.close();
		} catch (FileNotFoundException e) {
			OrccLogger.severeln("File Not Found Exception: " + e.getMessage());
		}
		
		/// </ol> </ul>
		/////////////////////////

		/// <ol> <li> Generate hal_hwpe.h
		file = hdlPath + File.separator + "deps" + File.separator + "hwpe-multidataflow-wrapper" + File.separator + "sw" + File.separator +
						"hwpe-multidataflow-riscv" + File.separator + "inc" + File.separator + "hwpe_lib" + File.separator + 
						"hal_hwpe.h";
		sequence = pulpPrinter.printRiscvHalHwpe();
		try {
			PrintStream ps = new PrintStream(new FileOutputStream(file));
			ps.print(sequence.toString());
			ps.close();
		} catch (FileNotFoundException e) {
			OrccLogger.severeln("File Not Found Exception: " + e.getMessage());
		}
		
		/// </ol> </ul>
		/////////////////////////

		/// <ol> <li> Generate test_hwpe.c
		file = hdlPath + File.separator + "deps" + File.separator + "hwpe-multidataflow-wrapper" + File.separator + "sw" + File.separator +
						"hwpe-multidataflow-riscv" + File.separator + "test_hwpe.c";
		sequence = pulpPrinter.printRiscvTestHwpe();
		try {
			PrintStream ps = new PrintStream(new FileOutputStream(file));
			ps.print(sequence.toString());
			ps.close();
		} catch (FileNotFoundException e) {
			OrccLogger.severeln("File Not Found Exception: " + e.getMessage());
		}
		
		/// </ol> </ul>
		/////////////////////////
		
		
		
		/// <ol> <li> Generate Bender
		/*file = hdlDir.getPath().replaceFirst("rtl","") + File.separator +  "hwpe-multi-dataflow.mk";
		sequence = pulpPrinter.printMk(hdlCompLib);
		try {
			PrintStream ps = new PrintStream(new FileOutputStream(file));
			ps.print(sequence.toString());
			ps.close();
		} catch (FileNotFoundException e) {
			OrccLogger.severeln("File Not Found Exception: " + e.getMessage());
		}*/
		
		/// </ol> </ul>
		/////////////////////////
	}

	/**
	 * Generate a co-processing layer around the multi-dataflow
	 * network
	 * 
	 * @return
	 * @throws IOException 
	 */
	public void generateCopr(List<SboxLut> luts, Map<String,Map<String,String>> networkVertexMap, Map<String,Object> options) throws IOException {			
		
		String hdlCompLib = (String) options.get("it.mdc.tool.hdlCompLib");
		String type = (String) options.get("it.unica.diee.mdc.tilType");
		String processor = (String) options.get("it.mdc.tool.ipProc");
		Boolean enDma = (Boolean) options.get("it.mdc.tool.ipEnDma");
		String boardpart = (String) options.get("it.mdc.tool.ipTgtBpart");
		String partname = (String) options.get("it.mdc.tool.ipTgtPart");
		//	Enable Monitoring
		Boolean enableMonitoring = (Boolean) options.get("it.unica.diee.mdc.monitoring");
		List<String> monList = new ArrayList<String>();
		
		// Initialize List of monitors
		if(enableMonitoring) {
			if((Boolean) options.get("it.unica.diee.mdc.monFifo"))
				for(Port port: network.getInputs())
					monList.add("count_full_" + port.getName());
			
			if((Boolean) options.get("it.unica.diee.mdc.monCC"))
				monList.add("count_clock_cycles");
			
			if((Boolean) options.get("it.unica.diee.mdc.monInTokens"))
				for(Port port: network.getInputs())
					monList.add("count_in_tokens_" + port.getName());
			
			if((Boolean) options.get("it.unica.diee.mdc.outTokens"))
				for(Port port: network.getOutputs())
					monList.add("count_out_tokens_" + port.getName());
		}	
		
		/// <ul>
		String file;
		String prefix = "";
		CharSequence sequence;

		WrapperPrinter wrapperPrinter;
		if(type.equals("MEMORY-MAPPED")) {
			//printer = new TilPrinterVivadoMm();
			prefix = "mm";
		} else if(type.equals("STREAM")) {
			//printer = new TilPrinterVivadoStream();	
			prefix = "s";
		} else {
			//TODO hybrid
			wrapperPrinter = null;
		}
		/// <li> Initialize TIL printer
		wrapperPrinter = new WrapperPrinter();
		((WrapperPrinter) wrapperPrinter).initWrapperPrinter(prefix,enableMonitoring,monList,luts,
				protocolManager);

		
		////////////////////////
		/// <li> HDL sources 
		
		File hdlDir = new File(hdlPath);
		// If directory doesn't exist, create it
		if (!hdlDir.exists()) {
			hdlDir.mkdirs();
		}
		
		// TODO fix stream with tlast signal generation (slv_reg and counter!)
		
		/// <ol> <li> Generate top module
		file = hdlDir.getPath() + File.separator +  prefix + "_accelerator.v";
		sequence = wrapperPrinter.printHdlSource(network,"TOP");
		try {
			PrintStream ps = new PrintStream(new FileOutputStream(file));
			ps.print(sequence.toString());
			ps.close();
		} catch (FileNotFoundException e) {
			OrccLogger.severeln("File Not Found Exception: " + e.getMessage());
		}
		
		/// <li> Generate configuration register modules
		file = hdlDir.getPath() + File.separator +  "config_regs.v";
		sequence = wrapperPrinter.printHdlSource(network,"CFG_REGS");
		try {
			PrintStream ps = new PrintStream(new FileOutputStream(file));
			ps.print(sequence.toString());
			ps.close();
		} catch (FileNotFoundException e) {
			OrccLogger.severeln("File Not Found Exception: " + e.getMessage());
		}
		
		/// <li> Generate test bench module
		file = hdlDir.getPath() + File.separator +  "tb_" + prefix + "_accelerator.v";
		sequence = wrapperPrinter.printHdlSource(network,"TBENCH");
		try {
			PrintStream ps = new PrintStream(new FileOutputStream(file));
			ps.print(sequence.toString());
			ps.close();
		} catch (FileNotFoundException e) {
			OrccLogger.severeln("File Not Found Exception: " + e.getMessage());
		}
		
		/// <li> Generate XML configuration file for the MDC-PAPI component
		if(enableMonitoring){
			file = hdlDir.getPath().replaceFirst("hdl", "") + File.separator +  "mdc-papi_info.xml";
			sequence = wrapperPrinter.printXML();
			try {
				PrintStream ps = new PrintStream(new FileOutputStream(file));
				ps.print(sequence.toString());
				ps.close();
			} catch (FileNotFoundException e) {
				OrccLogger.severeln("File Not Found Exception: " + e.getMessage());
			}
		}
				
		/// </ol>
		/////////////////////////
		
		// Get libraries
		List<String> libraries = new ArrayList<String>();
		File libFolder = new File(hdlCompLib+"/lib");
		
		if(libFolder.exists()){
			File[] listOfFiles = libFolder.listFiles();
		    for (int i = 0; i < listOfFiles.length; i++) {
		    	if (listOfFiles[i].isDirectory()) {
		        libraries.add(listOfFiles[i].getName());
		      }
		    }
		}

				
		ScriptPrinter scriptPrinter = new ScriptPrinter();
		scriptPrinter.initScriptPrinter(libraries,prefix,processor,enDma,
											boardpart,partname);
		
		File scriptDir = new File(hdlPath.replace(prefix + "_accelerator" + File.separator + "hdl", "scripts"));
		// If directory doesn't exist, create it
		if (!scriptDir.exists()) {
			scriptDir.mkdirs();
		}
		
		file = scriptDir.getPath() + File.separator +  "generate_ip.tcl";
		sequence = scriptPrinter.printIpScript();
		try {
			PrintStream ps = new PrintStream(new FileOutputStream(file));
			ps.print(sequence.toString());
			ps.close();
		} catch (FileNotFoundException e) {
			OrccLogger.severeln("File Not Found Exception: " + e.getMessage());
		}
		file = scriptDir.getPath() + File.separator +  File.separator +  "generate_top.tcl";
		sequence = scriptPrinter.printTopScript(network);
		try {
			PrintStream ps = new PrintStream(new FileOutputStream(file));
			ps.print(sequence.toString());
			ps.close();
		} catch (FileNotFoundException e) {
			OrccLogger.severeln("File Not Found Exception: " + e.getMessage());
		}
		
		//////////////////////////
		/// <li> SW drivers 
		DriverPrinter driverPrinter = new DriverPrinter();
		driverPrinter.initDriverPrinter(prefix,processor, enDma,
				wrapperPrinter.getPortMap(),wrapperPrinter.getInputMap(),wrapperPrinter.getOutputMap());

		File srcDir = new File(hdlPath.replace("hdl", "drivers") + File.separator + "src");
		// If directory doesn't exist, create it
		if (!srcDir.exists()) {
			srcDir.mkdirs();
		}
		
		/// <ol> <li> Generate Driver Header
		file = srcDir.getPath() + File.separator +  prefix + "_accelerator.h";
		sequence = driverPrinter.printDriverHeader(network,networkVertexMap);
				
		try {
			PrintStream ps = new PrintStream(new FileOutputStream(file));
			ps.print(sequence.toString());
			ps.close();
		} catch (FileNotFoundException e) {
			OrccLogger.severeln("File Not Found Exception: " + e.getMessage());
		}
		
		/// <li> Generate Driver Source
		file = srcDir.getPath() + File.separator +  prefix + "_accelerator.c";
		sequence = driverPrinter.printDriverSource(network, networkVertexMap, configManager);
						
		try {
			PrintStream ps = new PrintStream(new FileOutputStream(file));
			ps.print(sequence.toString());
			ps.close();
		} catch (FileNotFoundException e) {
			OrccLogger.severeln("File Not Found Exception: " + e.getMessage());
		}
		
		srcDir = new File(hdlPath.replace("hdl", "drivers") + File.separator + "data");
		// If directory doesn't exist, create it
		if (!srcDir.exists()) {
			srcDir.mkdirs();
		}
		
		/// <ol> <li> Generate Driver Tcl
		file = srcDir.getPath() + File.separator +  prefix + "_accelerator.tcl";
		sequence = driverPrinter.printDriverTcl();
				
		try {
			PrintStream ps = new PrintStream(new FileOutputStream(file));
			ps.print(sequence.toString());
			ps.close();
		} catch (FileNotFoundException e) {
			OrccLogger.severeln("File Not Found Exception: " + e.getMessage());
		}
		
		/// <li> Generate Driver Mdd
		file = srcDir.getPath() + File.separator +  prefix + "_accelerator.mdd";
		sequence = driverPrinter.printDriverMdd();
						
		try {
			PrintStream ps = new PrintStream(new FileOutputStream(file));
			ps.print(sequence.toString());
			ps.close();
		} catch (FileNotFoundException e) {
			OrccLogger.severeln("File Not Found Exception: " + e.getMessage());
		}
		
		/// </ol> </ul>
		/////////////////////////
	}
	

	/**
	 * Generate a latch-based clock gating cell module
	 * 
	 * @throws IOException
	 * 
	 * TODO move in the NetworkPrinter.java?
	 */
	public void generateClockGatingCell(String type) throws IOException {
		
		File verilogDir = new File(hdlPath + File.separator + "verilog");
		// If directory doesn't exist, create it
		if (!verilogDir.exists()) {
			verilogDir.mkdirs();
		}
		
		String file = verilogDir.getPath() + File.separator + "clock_gating_cell.v";
				
		CgCellPrinter printer  = new CgCellPrinter();
		CharSequence sequence = printer.printCgCell(type);

		try {
			PrintStream ps = new PrintStream(new FileOutputStream(file));
			ps.print(sequence.toString());
			ps.close();
		} catch (FileNotFoundException e) {
			OrccLogger.severeln("File Not Found Exception: " + e.getMessage());
		}	

	}

	/**
	 * Generate the enable generator top module
	 * 
	 * @param networksInstances
	 * 		map of the CGSs involved in each merged network
	 * @throws IOException
	 * 
	 * TODO move in the NetworkPrinter.java?
	 */
	public void generateEnableGenerator(Map<String,Set<String>> networksInstances) throws IOException {
		
		File verilogDir = new File(hdlPath + File.separator + "verilog");
		// If directory doesn't exist, create it
		if (!verilogDir.exists()) {
			verilogDir.mkdirs();
		}
		
		String file = verilogDir.getPath() + File.separator + "enable_generator.v";
				
		EnGenPrinter printer  = new EnGenPrinter();
		CharSequence sequence = printer.printEnGen(network, configManager, logicRegions, networksInstances, 
				logicRegionID, powerSets, netRegions, powerSetsIndex, logicRegionsSeqMap);

		try {
			PrintStream ps = new PrintStream(new FileOutputStream(file));
			ps.print(sequence.toString());
			ps.close();
		} catch (FileNotFoundException e) {
			OrccLogger.severeln("File Not Found Exception: " + e.getMessage());
		}		
		
	}
	
	/**
	 * Get the size of a given port
	 * 
	 * @param port
	 * 		the given port
	 * @return
	 */
	protected int getSize(Port port) {
		return port.getType().getSizeInBits();
	}
	
	/**
	 * Get the size of a signal
	 * 
	 * @param signal
	 * 		the given signal
	 * @return
	 */
	protected Integer getSize(String[] signal) {
		if(signal[SIZE].equals("bufferSize"))
			return null;
		else return Integer.parseInt(signal[SIZE]);
	}

	/**
	 * Get the size of a signal related to a specific port
	 * 
	 * @param signal
	 * 		the given signal
	 * @param port
	 * 		the given port
	 * @return
	 */
	protected int getSize(String[] signal, Port port) {
		
		if(signal[SIZE].equals("bufferSize")) {
			for(Edge edge : port.getConnecting()) {
				if(((Connection) edge).hasAttribute("bufferSize")) {
					if(edge.getAttribute("bufferSize").getReferencedValue()!=null) {
						ExpressionEvaluator ev = new ExpressionEvaluator();
						return ev.evaluateAsInteger((Expression) edge.getAttribute("bufferSize").getReferencedValue());
					}
					return ((Connection) edge).getSize();
				} else {
					return port.getType().getSizeInBits();
				}
			}
			return port.getType().getSizeInBits();
		} else {
			return Integer.parseInt(signal[SIZE]);
		}
	}
	
	/**
	 * Verify if the given connection is printed or not
	 * 
	 * @param connection
	 * 		the given connection
	 * @return
	 */
	protected boolean isPrinted(Connection connection) {
		
		Vertex source = connection.getSource();
		Port sourcePort = connection.getSourcePort();
		
		if( sourcePort != null ){
			return isPrinted(sourcePort);
		}else
			return isPrinted(source);
		
	}
	
	/**
	 * For each connection,
	 * if the connection has already been printed, remove
	 * the "printed" attribute from its source port or vertex
	 * (removePrintFlag()).
	 * @param network
	 */
	protected void removeAllPrintFlags(Network network) {
		
		for(Connection connection : network.getConnections())
			if(isPrinted(connection))
				removePrintFlag(connection);
		
	}
	
	/**
	 * For the given connection, remove the attribute "printed"
	 * from  its source port or vertex.
	 * 
	 * @param connection
	 * 		the given connection.
	 */
	protected void removePrintFlag(Connection connection) {
		
		Vertex source = connection.getSource();
		Port sourcePort = connection.getSourcePort();
		
		if( sourcePort != null )
			sourcePort.removeAttribute("printed");
		else
			source.removeAttribute("printed");
	}

	/**
	 * Returns the connection in the passed network that matches the given source and target
	 * 
	 * @param network
	 * @param source
	 * @param sourcePort
	 * @param target
	 * @param targetPort
	 * @return
	 */
	protected Connection getConnection(Network network, Vertex source, Port sourcePort, Vertex target, Port targetPort) {

		for(Connection connection : network.getConnections())
			if(sourcePort != null) {
				if(connection.getSource() != null 
						&& connection.getSourcePort() != null
						&& connection.getTarget() != null
						&& connection.getTargetPort() != null)
					if(connection.getSource().equals(source) 
							&& connection.getSourcePort().equals(sourcePort)
							&& connection.getTarget().equals(target)
							&& connection.getTargetPort().equals(targetPort))
						return connection;
			} else {
				if(connection.getSource() != null 
						&& connection.getSourcePort() == null 
						&& connection.getTarget() != null
						&& connection.getTargetPort() != null)
					if(connection.getSource().equals(source) 
							&& connection.getTarget().equals(target)
							&& connection.getTargetPort().equals(targetPort))
						return connection;
			}
			
		return null;
	}

	
	/**
	 * Get bufferSize parameter of the connection
	 * 
	 * @param signal
	 * @param c
	 * @return
	 */
	protected int getSize(String[] signal, Connection c) {
		
		if(signal[SIZE].equals("bufferSize")) {
			if(c.hasAttribute("bufferSize")) {
				
				return c.getSize();
				
			} else {
				if(c.getSourcePort() != null) {
					return getSize(c.getSourcePort());
				} else if(c.getSource().getAdapter(Port.class) != null) {
					return getSize(c.getSource().getAdapter(Port.class));
				} else if(c.getTargetPort() != null) {
					return getSize(c.getTargetPort());
				} else {
					return getSize(c.getTarget().getAdapter(Port.class));
				}
			}
		} else {
			return Integer.parseInt(signal[SIZE]);
		}
	}
	
	/**
	 * TODO \todo to check
	 * 
	 * get the direction of an input signal.
	 * "in" if signals arrives from predecessor,
	 * "out" if it arrives from successor.
	 * 
	 * @param signal
	 * @return
	 */
	protected String getDirectionInput(String[] signal) {
		String direction;
		if (signal[DIRECTION].equals("dx")) {
			direction = "in";
		} else {
			direction = "out";
		}
		return direction;
	}
	
	/**
	 * TODO \todo to check
	 * 
	 * get the direction of an output signal.
	 * "out" if signals goes to successor,
	 * "in" if it goes to predecessor.
	 * 
	 * @param signal
	 * @return
	 */
	protected String getDirectionOutput(String[] signal) {
		String direction;
		if (signal[DIRECTION].equals("dx")) {
			direction = "out";
		} else {
			direction = "in";
		}
		return direction;
	}

	/**
	 * Get lut value for the selected network and section
	 * 
	 * @param lut
	 * @param network
	 * @param section
	 * @return
	 */
	protected int getLutValueInteger(SboxLut lut, Network network, int section) {
		if(lut.getLutValue(network,section))
			return 1;
		return 0;
	}
	
	/**
	 * TODO \todo add description and comments
	 * 
	 * @param connection
	 * @return
	 */
	protected boolean getNotPrint(Connection connection) {
		if(connection.getSourcePort()!=null && connection.getTargetPort()!=null)
			return false;
		else if(connection.getSourcePort()==null && connection.getTargetPort()==null)
			return false;
		else
			return true;
	}
	
	/**
	 * Return the size of the current SBox
	 * 
	 * @param signal
	 * @param sbox
	 * @return
	 */
	protected int getSboxSize(String[] signal, Vertex sbox) {
		int size = 0;
		if(signal[SIZE].equals("bufferSize")) {	
			if(isSbox2x1(sbox))
				for(Connection c : sbox.getAdapter(Instance.class).getIncomingPortMap().values())
					size += c.getTargetPort().getType().getSizeInBits();
			else
				for(Port p : sbox.getAdapter(Instance.class).getOutgoingPortMap().keySet())
					size += p.getType().getSizeInBits();
		} else {
			size = Integer.parseInt(signal[SIZE])*2;
		}
		return size;
	}

	/**
	 * Return the size of the current port.
	 * 
	 * @param port
	 * @param signal
	 * @return
	 */
	protected int getSize(Port port, String[] signal) {
		if(signal[SIZE].equals("bufferSize"))
			return port.getType().getSizeInBits();
		else
			return Integer.parseInt(signal[SIZE]);
	}
	
	/**
	 *  Return the size of the current connection.
	 * 
	 * @param connection
	 * @param signal
	 * @return
	 */
	protected int getSize(Connection connection, String[] signal) {
		if(signal[SIZE].equals("bufferSize"))
			if(connection.getSourcePort() != null)
				return connection.getSourcePort().getType().getSizeInBits();
			else
				return connection.getSource().getAdapter(Port.class).getType().getSizeInBits();
		else
			return Integer.parseInt(signal[SIZE]);
	}
	
	/**
	 * Return the size of the current connection.
	 * 
	 * @param connection
	 * @return
	 */
	protected int getSize(Connection connection) {
		if(connection.getSourcePort()!=null)
			return getSize(connection.getSourcePort());
		else
			return getSize(connection.getSource().getAdapter(Port.class));
	}
	
	/**
	 * Return the size of the current connection.
	 * 
	 * @param connection
	 * @return
	 */
	protected int getBufferSize(Connection connection) {
		return getSize(connection);//connection.getSize();
	}
	
	/**
	 * Initialize the logicRegions map with the current logicRegions map.
	 * 
	 * @param logicRegions
	 */
	public void initLogicRegions(Map<String,Set<String>> logicRegions){	
		
		this.logicRegions = new HashMap<String,Set<String>>(logicRegions);
	}
	
	/**
	 * Initialize the netRegions map with the current netRegions map.
	 * 
	 * @param netRegions
	 */
	public void initNetRegions(Map<String,Set<String>> netRegions){	
		
		this.netRegions = new HashMap<String,Set<String>>(netRegions);
	}
	
	/**
	 * Initialize the powerSetsIndex map with the current powerSetsIndex map.
	 * 
	 * @param powerSetsIndex
	 */
	public void initPowerSetsIndex(Map<String,Integer> powerSetsIndex){	
		
		this.powerSetsIndex = new HashMap <String,Integer>(powerSetsIndex);
	}
	
	/**
	 * Initialize the logicRegionsSeqMap map with the current logicRegionsSeqMap map.
	 * 
	 * @param logicRegionsSeqMap
	 */
	public void initlogicRegionsSeqMap(Map<String,Boolean> logicRegionsSeqMap){	
		
		this.logicRegionsSeqMap = new HashMap <String,Boolean>(logicRegionsSeqMap);
	}
	
	/**
	 * Initialize the powerSets map with the current powerSets map.
	 * 
	 * @param powerSets
	 */
	public void initPowerSets(Set<String>  powerSets){	
		
		this.powerSets = new HashSet <String>(powerSets);
	}
	
	/**
	 * Initialize the clockDomains map with the current clockDomains map.
	 * 
	 * @param clockDomains
	 */
	public void initClockDomains(Map<String, Set<String>> clockDomains) {
		this.clockDomains = new HashMap<String, Set<String>> (clockDomains);
		
	}
	
	/**
	 * Initialize the domainGatedSets map with the current domainGatedSets map.
	 * 
	 * @param domainGatedSets
	 */
	public void initializeClock(Map<String,Map<String,Set<String>>> domainGatedSets){	
		
		this.domainGatedSets = new HashMap<String,Map<String,Set<String>>>(domainGatedSets);
	}
	
	/**
	 * Check if a connection is a broadcast.
	 * 
	 * @param connection
	 * @return
	 */
	protected boolean isBroadcast(Connection connection) {
		return connection.hasAttribute("broadcast");
	}
	
	/**
	 * Check if a signal has attribute "not_sync"
	 * 
	 * @param signal
	 * @return
	 */
	protected boolean isNative(String[] signal) {
		if(signal[IS_NATIVE].equals("not_sync"))
			return true;
		else
			return false;
		
	}
	
	/**
	 * Check if a vertex has already been printed.
	 * 
	 * @param vertex
	 * 			vertex to check
	 * @return boolean
	 */
	protected boolean isPrinted(Vertex vertex) {
		return vertex.hasAttribute("printed");
	}
	
	/**
	 * Check if a vertex is a SBox
	 * 
	 * @param vertex
	 * @return
	 */
	protected boolean isSbox(Vertex vertex) {
	
		if(vertex.getAdapter(Actor.class)!=null)
			if(vertex.getAdapter(Actor.class).hasAttribute("sbox"))		
				return true;
			
		return false;
	}
	
	/**
	 * Check if a vertex is a SBox1x2 (1 input and 2 outputs).
	 * 
	 * @param vertex
	 * @return
	 */
	protected boolean isSbox1x2(Vertex vertex) {
		
		if(vertex.getAdapter(Actor.class)!=null)
			if(vertex.getAdapter(Actor.class).hasAttribute("sbox"))		
				if(vertex.getAdapter(Actor.class).getAttribute("type").getStringValue().equals("1x2"))
					return true;
			
		return false;
	}
	
	/**
	 * Check if a vertex is a SBox2x1 (2 inputs and 1 output).
	 * 
	 * @param vertex
	 * @return
	 */
	protected boolean isSbox2x1(Vertex vertex) {
		
		if(vertex.getAdapter(Actor.class)!=null)
			if(vertex.getAdapter(Actor.class).hasAttribute("sbox"))		
				if(vertex.getAdapter(Actor.class).getAttribute("type").getStringValue().equals("2x1"))
					return true;
			
		return false;
	}
	
	/**
	 * Print top module network
	 * 
	 * @param luts
	 * 			SBox Look Up Table
	 * @param options
	 * 			Map of options
	 * @return
	 */
	abstract protected boolean printNetwork(List<SboxLut> luts, Map<String,Object> options);

	
}