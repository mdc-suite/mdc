package it.mdc.tool.core;

import static it.mdc.tool.profiling.Profiler.DONT_MERGE;
import static net.sf.orcc.OrccLaunchConstants.BACKEND;
import static net.sf.orcc.OrccLaunchConstants.OUTPUT_FOLDER;
import static net.sf.orcc.OrccLaunchConstants.PROJECT;
import static net.sf.orcc.util.OrccUtil.getFile;

import java.util.Calendar;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;

import net.sf.orcc.OrccException;
import net.sf.orcc.OrccRuntimeException;
import net.sf.orcc.backends.AbstractBackend;
import net.sf.orcc.df.Actor;
import net.sf.orcc.df.DfFactory;
import net.sf.orcc.df.Instance;
import net.sf.orcc.df.Network;
import net.sf.orcc.df.transform.Instantiator;
import net.sf.orcc.df.transform.NetworkFlattener;
import net.sf.orcc.util.OrccLogger;
import net.sf.orcc.util.Result;
import net.sf.orcc.util.util.EcoreHelper;

import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.HelpFormatter;
import org.apache.commons.cli.Option;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.ParseException;
import org.apache.commons.cli.PosixParser;
import org.apache.commons.cli.UnrecognizedOptionException;
import org.eclipse.core.resources.IFile;
import org.eclipse.core.runtime.IProgressMonitor;
import org.eclipse.core.runtime.NullProgressMonitor;
import org.eclipse.core.runtime.OperationCanceledException;
import org.eclipse.core.runtime.Platform;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl;
import org.eclipse.emf.ecore.util.EcoreUtil.Copier;
import org.eclipse.equinox.app.IApplication;
import org.eclipse.equinox.app.IApplicationContext;
import org.osgi.framework.Bundle;

import it.mdc.tool.utility.*;
import it.mdc.tool.core.multiDataflowGenerator.EmpiricMerger;
import it.mdc.tool.core.multiDataflowGenerator.Merger;
import it.mdc.tool.core.multiDataflowGenerator.MoreanoMerger;
import it.mdc.tool.core.platformComposer.LogicRegionFinder;
import it.mdc.tool.core.platformComposer.LogicRegionMerger;
import it.mdc.tool.core.platformComposer.NetworkPrinter;
import it.mdc.tool.core.platformComposer.PlatformComposer;
import it.mdc.tool.core.sboxManagement.SboxLut;
import it.mdc.tool.profiling.CombinationsGenerator;
import it.mdc.tool.profiling.Profiler;
import it.mdc.tool.utility.FileCopier;
import it.mdc.tool.utility.Printer;

import java.io.File;
import java.io.IOException;

import net.sf.orcc.df.util.NetworkValidator;
import net.sf.orcc.graph.Vertex;



/**
 * <b>MDC backend</b>
 * 
 * <ul>
 * <li>the start() function is called to start the MDC application.
 * <ol> <li> It parses the command lines arguments and initializes the option map.
 * </ul>
 * 
 * <li> Then it runs the full compilation by launching: compile().
 * main steps of compile() method are: 
 * <ol> <li> parsing and validating input networks;
 * <li> setting configuration manager: it.mdc.tool.core.ConfigManager.setNetworkList();
 * <li> merge, once per time, the input networks: doMergingProcess();
 * <li> compose the HDL platform: doHdlCodeGeneration();
 * </ol>
 * 
 * <li> When the compilation is complete, it prints the correct usage of the backend.
 * <ol> <li> printUsage() </ol> </ul>
 * 
 * @author Carlo Sau
 * 
 */
public class MDCBackend extends AbstractBackend {
	// Attributes
	
	// General attributes
	////////////////////////////////////////////////////////
	/**
	 * The progress monitor
	 */
	private IProgressMonitor monitor;
	
	/**
	 * Algorithm to be adopted for the merging 
	 * dataflow process.
	 */
	private String mergingAlgorithm;
	/**
	 * Number of networks to be combined
	 */
	private int numFiles;
	
	/**
	 * List of input network files to be combined
	 */
	private List<IFile> inputFileList;
	
	/**
	 * Configuration LUTs of the mult-dataflow network
	 */
	private List<SboxLut> luts;
	
	/**
	 * Map of the vertex mapping of each merged network
	 * within the multi-dataflow one.
	 */
	private Map <String,Map<String,String>> networkVertexMap;
	
	/**
	 * Instances of each combined network within the
	 * multi-dataflow one
	 */
	private Map<String,Set<String>> netInstances;
	
	////////////////////////////////////////////////////////
	
	//  Instances
	////////////////////////////////////////////////////////
	/**
	 * MDC configuration manager instance
	 */
	private ConfigManager configManager;

	/**
	 * MDC profiler instance
	 */
	private Profiler profiler;
	
	/**
	 * MDC printer instance
	 */
	private Printer printer;
	////////////////////////////////////////////////////////	
	
	//  Profiling attributes
	////////////////////////////////////////////////////////
	/**
	 * Enable monitoring flag
	 */
	private boolean enMon;
	
	/**
	 * Enable ARTICo3 Kernel Generation
	 */
	
	private boolean enArtico;
	
	/**
	 * Enable Pulp Wrapper Generation
	 */
	
	private boolean enPulp;
	
	/**
	 * Hwpe wrapper generator tool folder
	 */
	private String hwpeWrapperGeneratorPath;
	
	/**
	 * Enable profiling flag
	 */
	private boolean profileEn;
	
	/**
	 * Profiling effort (area/power or frequency)
	 */
	private String profilingEffort;
	
	/**
	 * Profiler counter
	 */
	private int prifileCount;
	
	private Map<Network,Integer> bestInputMap;
	
	/**
	 * Profiling best multi-dataflow network
	 */
	private Network bestNetwork;
	
	/**
	 * Profiling best multi-dataflow values (area, power,
	 * frequency)
	 */
	private List<Float> bestValues;
	
	/**
	 * Profiling best mutli-dataflow configuration LUTs
	 */
	private List<SboxLut> bestLuts;

	/**
	 * Instances of each combined network within the
	 * profiling best multi-dataflow 
	 */
	private Map<String, Set<String>> bestNetInstances;
	////////////////////////////////////////////////////////
	
	//  HDL generation attributes
	////////////////////////////////////////////////////////
	/**
	 * Enable HDL generation
	 */
	private boolean genHDL;	
	
	/**
	 * Type of communication protocol file
	 */
	private String protocolFile;
	
	/**
	 * HDL component library
	 */
	private String hdlCompLib;

	/**
	 * Enable logic regions computing
	 */
	private boolean lrEn;

	
	/**
	 * Type of design flow
	 */
	private String desFlow;
	
	/**
	 * Logic region power saving technique (CLOCK GATING or POWER GATING)
	 */
	private String lrTech;
	
	/**
	 * Number of logic regions (ex number of clock gating cells)
	 */
	private int lrCells;
	
	/**
	 * Enable co-processing layer generation
	 */
	private boolean genCopr;
	
	/**
	 *Co-processing layer generation type
	 */
	private String coprType;
	////////////////////////////////////////////////////////
	
	
	//  CAL generation attributes
	////////////////////////////////////////////////////////
	/**
	 * Enable CAL generation
	 */
	private boolean genCAL;

	/**
	 * Sbox type for the CAL generation
	 */
	private String calType;
	
	/**
	 * Output folder for the RVC-CAL generation
	 */
	private String rvcCalOutputFolder;
	////////////////////////////////////////////////////////
	

	/**
	 * This function assigns DONT_MERGE flag to the actors involved in 
	 * networks that must not be merged
	 * 
	 * @param netMap
	 * 		the map of input dataflow networks
	 */
	private void assignFlag(Map<Network,Integer> netMap) {
		
		for(Network net: netMap.keySet()){
			for(Vertex vertex: net.getChildren()){
				if(netMap.get(net).equals(DONT_MERGE)){
					vertex.getAdapter(Instance.class).setAttribute("don't merge", "");
				}
			}
		}
		
	}
	
	void purgeDirectory(File dir) {
	    for (File file: dir.listFiles()) {
	        if (file.isDirectory()) purgeDirectory(file);
	        file.delete();
	    }
	}
	
	
	/**
	 * Compilation of the applications:
	 * <ul> <li> parsing and validating input networks;
	 * <li> setting configuration manager: ConfigManager.setNetworkList();
	 * <li> merge, once per time, the input networks: doMergingProcess();
	 * <li> compose the HDL platform: doHdlCodeGeneration();
	 * </ul>
	 *
	 *@param progressMonitor: add description of the progress monitor
	 *
	 * */
	@Override
	public void compile(IProgressMonitor progressMonitor){	 
		///Start compile() <ul>
		
		//remove all files and directories from the output directory
		//purgeDirectory(new File(outputPath));

		//Monitor initialization. Can be used to stop the back-end
		// execution and provide feedback to user
		monitor = progressMonitor;
		
		String orccVersion = "<unknown>";
		Bundle bundle = Platform.getBundle(Activator.PLUGIN_ID);
		if (bundle != null) {
			orccVersion = bundle.getHeaders().get("Bundle-Version");
		}

		// Monitor initialization. Can be used to stop the back-end
		// execution and provide feedback to user
		monitor = progressMonitor;
		
		String backendName = getOption(BACKEND, "<unknown>");

		OrccLogger.traceln("*********************************************"
				+ "************************************");
		OrccLogger.traceln("* Orcc version : " + orccVersion);
		OrccLogger.traceln("* Backend : " + backendName);
		OrccLogger.traceln("* Project : " + project.getName());
		OrccLogger.traceln("* Start MDC backend...");
		
		// resource set
		ResourceSet set = new ResourceSetImpl();
	    
		/// <li> Declare input networks list 
		List<Network> networks = new ArrayList<Network>();
		
		/// <li> Parse input list of networks 

		for(IFile fileIN : inputFileList){
			
			
			if(fileIN == null) {
				throw new OrccRuntimeException("The input XDF file does not exist.");
			}
			Network currNet= (Network) EcoreHelper.getEObject(set, fileIN);			
			
			/// <ol> <li> validate current network (check if the input network is broken - e.g. missing source, missing connections...
			new NetworkValidator().doSwitch(currNet);
			
			/// <li> add current network to the input network list </ol> 
			networks.add(currNet);
	    }	
		
		/// <li> Set configuration manager with the input networks list: ConfigManager.setNetworkList()
		configManager.setNetworkList(networks);
		
		/// <li> Check the input networks number, to verify it matches with the specified value of networks to be merged
		try{
			if (numFiles!=networks.size()) {
				throw new OrccException("");
			}
		} catch (OrccException e) {
			OrccLogger.traceln("WARNING: The number of given input XDF networks" +
					" does not match the specified value of networks to be merged!");
		}
		
		/// <li> Generate the list of maps of input networks
		List<Map<Network,Integer>> netMapList = getNetMapList(networks);
		
		// <li> Extract size map and progress (for profiling purposes)
		int sizeMap = netMapList.size();
		int progress=0;
				
		if(profileEn) {
			OrccLogger.traceln("* Design space size: " + sizeMap + " points");
			OrccLogger.trace("* Profile design space...0%");
		}
		
		/// <li> Analyze the maps of input networks 
		for(Map<Network,Integer> currMap : netMapList) {
			// print profiling progress 
			if(profileEn) {
				if(progress==(int)sizeMap/10)
					OrccLogger.traceRaw("...10%");
				else if(progress==(int)2*sizeMap/10)
					OrccLogger.traceRaw("...20%");
				else if(progress==(int)3*sizeMap/10)
					OrccLogger.traceRaw("...30%");
				else if(progress==(int)4*sizeMap/10)
					OrccLogger.traceRaw("...40%");
				else if(progress==(int)sizeMap/2)	
					OrccLogger.traceRaw("...50%");
				else if(progress==(int)6*sizeMap/10)
					OrccLogger.traceRaw("...60%");
				else if(progress==(int)7*sizeMap/10)
					OrccLogger.traceRaw("...70%");
				else if(progress==(int)8*sizeMap/10)
					OrccLogger.traceRaw("...80%");
				else if(progress==(int)9*sizeMap/10)
					OrccLogger.traceRaw("...90%");
				else if(progress==sizeMap-1)	
					OrccLogger.traceRaw("...100%\n");
				progress++;
			}	
			try {
				/// <ol> <li> Merge current map of input networks into the resulting network: doMergingProcess()
				Network resultNetwork = doMergingProcess(copyMap(currMap), true);

				
				/// <li> Generate the resulting network report
				if(!profileEn)
					printer.printReport(currMap,resultNetwork,outputPath,genCopr,coprType);
				
				///<li> generate the resulting dataflow specification.
				/// Set result network name and launch beforeGeneration()
				if(!profileEn && genCAL) {
					resultNetwork.setName("multi_dataflow");
					beforeGeneration(resultNetwork);	
				}

				/// <li> Compose the HDL platform of the generated resulting network: doHdlCodeGeneration() </ol> 
				if(!profileEn && genHDL) {
					doHdlCodeGeneration(resultNetwork);					
				}
				
				/// <li> If the coprocessor generation is enabled:
				/// Generate configuration file: ConfigManager.generateConfigFile()
				if(!profileEn) {
					configManager.generateConfigFile(genCopr,coprType);
				}	
			} catch (Exception e) {
				System.out.println("Exception on doXdfCodeGenerationList!");
				e.printStackTrace();
			}
		}
		/// <li> If profiling is enable
		/// <ol> <li> Print the profiling resulting network and generate the related report: it.mdc.tool.utility.Printer.printReport() </ol> 
		if(profileEn){
			OrccLogger.traceln("* Profiling effort: " + profilingEffort);
			OrccLogger.traceln("* Best network " + bestNetwork.getSimpleName());
			OrccLogger.traceln("*\tBest values " + bestValues.get(profiler.AREA) + " um2, " +
					bestValues.get(profiler.POWER) + " nW, " +
					bestValues.get(profiler.FREQ) + " kHz.");
			//OrccLogger.traceln("netMapList.get(0) " + netMapList.get(0) );
			printer.printReport(bestInputMap,bestNetwork,outputPath,genCopr,coprType);
			bestNetwork.setName("multi_dataflow");
		}
			
		if(profileEn) {
			profiler.closeFile();
			profiler.compressProfilingFile(outputPath);
		}
		
		// Generate the profiling of the resulting dataflow specification
		if(profileEn && genCAL) {
			beforeGeneration(bestNetwork);	
		}	
		
		// compose the HDL platform of the profiling resulting network
		if(profileEn && genHDL) {
			doHdlCodeGeneration(bestNetwork);
		}
		
		OrccLogger.traceln("* End MDC backend...");
		OrccLogger.traceln("*********************************************"
				+ "************************************");
		
		///End compile() (<i> Go back to start() or to it.mdc.tool.core.MDCBackend(). </i>) </ul>
	}
	
	/**
	 * Copy the given map of dataflow networks
	 * 
	 * @param netMap
	 * 		the map of dataflow networks
	 * @return
	 * 		the copy of the map of dataflow networks
	 */
	private Map<Network,Integer> copyMap(Map<Network,Integer> netMap) {
		
		// instantiate result map
		Map<Network,Integer> resNetMap = new HashMap<Network,Integer>();
		
		// copy map
		for(Network net: netMap.keySet()){
			Copier copier = new Copier();
			Network netCopy = (Network) copier.copy(net);
			copier.copyReferences();
	
			resNetMap.put(netCopy, netMap.get(net));
		}
		
		// return copied map
		return resNetMap;
	}


	/**
	 * This function executes the steps necessary to 
	 * generate the HDL top modules of the given network multi-functional network.
	 * 
	 * @param network
	 * 		the network whose top modules have to be
	 * 		generated
	 */
	protected void doHdlCodeGeneration(Network network){
		/// Start platform composing process
		OrccLogger.traceln("*\tStart platform composing process...");

		FileCopier copier = new FileCopier();
		
		///  <ul> <li> set hdl directory
		File hdlDir= new File("");
		if(genCopr) {
			if(coprType.equals("MEMORY-MAPPED")) {
				hdlDir = new File(outputPath + File.separator + "mm_accelerator" + File.separator  + "hdl");
			} else {
				hdlDir = new File(outputPath + File.separator + "s_accelerator" + File.separator  + "hdl");
			}
		} else if(enArtico && !genCopr) {
			   hdlDir = new File(outputPath + File.separator + "src" + File.separator + "a3_cgr_accelerator" + File.separator + "verilog");
		} else if(enPulp && !genCopr) {
			   hdlDir = new File(outputPath);
		}
		else{
			hdlDir = new File(outputPath + File.separator + "hdl");
		}
				
		// if directory doesn't exist, create it
		if (!hdlDir.exists()) {
			hdlDir.mkdirs();
		}
		
		
		/// <li> set network name: multi_dataflow
		network.setName("multi_dataflow"); 

		/// <li> write the HDL code
		try {
			/// <ol>
			// get the platform composer for the selected language
			PlatformComposer hdlWriter = new NetworkPrinter(hdlDir.getPath(),configManager,network,protocolFile);
			List<SboxLut> lutsToGen;
			Map<String,Set<String>> netInstancesToGen;
			Map<String,Double> powerMap;
			
			if(profileEn) {
				lutsToGen = bestLuts;
				netInstancesToGen = bestNetInstances;
				powerMap = 	profiler.getPowerMap();
			} else {
				lutsToGen = luts;
				netInstancesToGen = netInstances;
				powerMap = null;
			}
			
			// TODO  integrazione con profiler --> occhio al nuovo file estratto dal merger (networkVertexMap)!! -- dev'essere il best! 
			
			// import and combine buffer size files
			boolean importBufferSizeFileList = getOption("it.unica.diee.mdc.importBufferSizeFileList", false);
			if (importBufferSizeFileList) {
				OrccLogger.traceln("*\t\tImport buffer size file list...");
				
				String bufferSizeFilesFolder = getOption("it.unica.diee.mdc.it.unica.diee.mdc.bufferSizeFilesFolder", "<unknown>");
				
				List<String> bufferSizeFileList = new ArrayList<String>();
				
				for(String networkName : networkVertexMap.keySet()) {
					bufferSizeFileList.add(bufferSizeFilesFolder + File.separator 
							+ "buffers_config_" + networkName + ".ybm");
				}		
				
				new NetworkBufferSizeCombiner(bufferSizeFileList,networkVertexMap).doSwitch(network);
				
			}
			
			// import and combine clock domain files
			boolean importClockDomainFilesList = getOption("it.unica.diee.mdc.importClockDomainFileList", false);
			Map<String,Set<String>> clockDomains = new HashMap<String,Set<String>>();
			if (importClockDomainFilesList) {
				OrccLogger.traceln("*\t\tImport clock domains file list...");
				
				String clockDomainFilesFolder = getOption("it.unica.diee.mdc.it.unica.diee.mdc.clockDomainFilesFolder", "<unknown>");
				
				List<String> clockDomainFilesList = new ArrayList<String>();
				
				for(String networkName : networkVertexMap.keySet()) {
					clockDomainFilesList.add(clockDomainFilesFolder + File.separator 
							+ "report_partitioning_" + networkName + ".xml");
				}
					
				NetworkClockDomainCombiner clkDomainCombiner = 
						new NetworkClockDomainCombiner(clockDomainFilesList,networkVertexMap);
				clkDomainCombiner.combineClockDomain();
				clockDomains = clkDomainCombiner.getClockDomains();
			}
			
			//TODO  uniformare notazioni per clock domains e logic regions e gestire caso con 0 lr e 0 cd
			
			if(!lrEn) {	/// <li> if logic regions computing is disabled

				/// <ol><li> generate top module
				hdlWriter.initClockDomains(clockDomains);
				hdlWriter.generateTop(lutsToGen,getOptions());
				
				/// <li> generate network configurator PlatformComposer.generateConfig()</ol>
				if(!luts.isEmpty())
					hdlWriter.generateConfig(genCopr,lutsToGen);
				
			} else if(!luts.isEmpty()) { /// <li> if logic regions computing is enabled

				OrccLogger.traceln("*\t\tLogic regions computing...");
				
				///<ol><li> Logic Regions (LRs) identification: it.mdc.tool.core.platformComposer.LogicRegionFinder.findRegions()
				LogicRegionFinder lrFinder = new LogicRegionFinder();
				lrFinder.findRegions(netInstancesToGen);
				
				Map<String,Set<String>> logicRegions = lrFinder.getRegions();
				Map<String,Set<String>> netRegions = lrFinder.getNetRegions();
				Map<String,Set<String>> logicRegionsNetsMap  = new HashMap <String,Set<String>>();
				Set<String> powerSets  = new HashSet <String>();
				Map<String,Integer> powerSetsIndex  = new HashMap <String,Integer>();
				Map<String,Boolean> logicRegionsSeqMap  = new HashMap <String,Boolean>();
								
				/// <li> Logic Regions (LRs) merging:  it.mdc.tool.core.platformComposer.LogicRegionMerger.mergeRegions()
				if(lrCells < logicRegions.size() && !desFlow.equals("ASIC") ) {
					LogicRegionMerger lrMerger = new LogicRegionMerger(logicRegions, lrCells);
					
					if(powerMap != null)
						lrMerger.mergeRegions(powerMap);
					else
						lrMerger.mergeRegions();
					
					logicRegions = lrMerger.getLogicRegions();
					Map<String,Set<String>> indexMap = lrMerger.getIndexMap();
					netRegions = lrFinder.updateNetSets(netRegions,indexMap);
					
				}
				
				//Computing map combinatorial and sequential LRs
				for(String lr: logicRegions.keySet()){					
					boolean seqFlag = false;
					for(String instance : logicRegions.get(lr)){
							if(!network.getChild(instance).getAdapter(Actor.class).hasAttribute("combinational")){
							seqFlag = true; 
							break;
						}
					}	
					logicRegionsSeqMap.put(lr, seqFlag);
				}
				
				

				//Computing map of networks corresponding to each logic regions				
				for(String lr: logicRegions.keySet()){
					logicRegionsNetsMap.put(lr, new HashSet<String>());
						for(String net : netRegions.keySet())
							if(netRegions.get(net).contains(lr))
								logicRegionsNetsMap.get(lr).add(net);					
				}
				
				int numSeqLr = 0;
				//Only LR not shared by almost all nets are printable
				for(String lr: logicRegionsNetsMap.keySet())
					if(logicRegionsNetsMap.get(lr).size() < netRegions.size()) //not add the LR shared by all the nets
						//if(logicRegionsNetsMap.get(lr).size() < 18) //the second term should be minor or equal to netRegions.size()
							{powerSets.add(lr);
							if(logicRegionsSeqMap.get(lr)){
								powerSetsIndex.put(lr, numSeqLr);
								numSeqLr++;
							}
					}
				
				OrccLogger.traceln("*\t\tNumber of clock domains: " + clockDomains.size());
				OrccLogger.traceln("*\t\tNumber of logic regions: " + logicRegions.size());
									
				
					/// <li> initialize platform composer with the identified LRs
					hdlWriter.initClockDomains(clockDomains);
					hdlWriter.initLogicRegions(logicRegions);
					hdlWriter.initNetRegions(netRegions);
					hdlWriter.initPowerSets(powerSets);
					hdlWriter.initPowerSetsIndex(powerSetsIndex);
					hdlWriter.initlogicRegionsSeqMap(logicRegionsSeqMap);
									
					/// <li> generate top module and network configurator
					hdlWriter.generateTop(lutsToGen,getOptions());
					hdlWriter.generateConfig(genCopr,lutsToGen);
					
					//OrccLogger.traceln(netRegions);
					
					/// <li> generate LRs enable generator </ol>
					if(!lrTech.equals("POWER_GATING"))
					{
						hdlWriter.generateEnableGenerator(netRegions);
						}
					
					hdlWriter.generateClockGatingCell(desFlow);
					
				
					printer.printLogicRegionsReport(outputPath, genCopr, coprType, logicRegions, netRegions, logicRegionsNetsMap);
					///</ol>  
			}

			/// <li> If the Coprocessor generation is enabled generate coprocessor HDL code
			if(genCopr){
				// TODO  to uniform the networks name for the config id (currently they include the path)
				hdlWriter.generateCopr(luts,networkVertexMap,getOptions());
			}
			
			if(!genCopr && enArtico){
				hdlWriter.generateArticoKernel(luts,networkVertexMap,getOptions());
			}
			
			if(!genCopr && enPulp){
				hdlWriter.generatePulpStaticFolders(hwpeWrapperGeneratorPath, outputPath);
				hdlWriter.moveMultiDataflowFile(luts, getOptions());
				hdlWriter.generatePulpWrapper(luts,networkVertexMap,getOptions());
			}
			
		}catch(Exception e) {
			System.out.println("Exception catched on HDLwriter operations!\n\t" + e);
			for(StackTraceElement se : e.getStackTrace())
				System.out.println("" + se);
		}
		
		// HDL component library import
		// TODO fix folder
		String subfolder = "hdl";
		if(genCopr) {
			if(coprType.equals("MEMORY-MAPPED")) {
				subfolder = "mm_accelerator" + File.separator + "hdl";
			} else if(coprType.equals("STREAM")) {	
				subfolder = "s_accelerator" + File.separator + "hdl";
			} else {
				//TODO hybrid
			}
		} else  if(enArtico && !genCopr){
			subfolder = "src" + File.separator + "a3_cgr_accelerator" + File.separator + "verilog";
		} /*else  if(enPulp && !genCopr){
			subfolder = "rtl";
		}*/
		try {
			if(enArtico && !genCopr){
				copier.copyOnlyFiles(hdlCompLib, outputPath + File.separator + subfolder);
			} else if(enPulp && !genCopr){
				copier.copyOnlyFiles(hdlCompLib, outputPath + File.separator + "deps" + File.separator + "hwpe-multidataflow-wrapper" +
						File.separator + "rtl" + File.separator + "hwpe-engine" + File.separator + "engine_dev");
			} else {
				copier.copy(hdlCompLib, outputPath + File.separator + subfolder);
			}
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		

		// -----------------------------------------------------
		// Libraries files export
		// -----------------------------------------------------
		// If user checked the option "Don't export library", the method
		// extractLibraries() must not be called
		if (true) {	//(!getOption(NO_LIBRARY_EXPORT, false)) {
			stopIfRequested();
			final long t0 = System.currentTimeMillis();
			
			boolean exportPowerGatingLibraries = false;
			if(lrEn) {
				if(lrTech.equals("POWER_GATING"))
					exportPowerGatingLibraries = true;
			}
				
			
			if(genCopr | exportPowerGatingLibraries)
			{	
				final Result result = doLibrariesExtraction();
				if(!result.isEmpty()) {
					OrccLogger.traceln("*\tLibrary export done in " + getDuration(t0) + "s");
				}
			}
			
			if(enArtico && !genCopr)
			{	
				final Result result = doLibrariesExtraction();
				if(!result.isEmpty()) {
					OrccLogger.traceln("*\tLibrary export done in " + getDuration(t0) + "s");
				}
			}
			
			if(enPulp && !genCopr)
			{	
				final Result result = doLibrariesExtraction();
				if(!result.isEmpty()) {
					OrccLogger.traceln("*\tLibrary export done in " + getDuration(t0) + "s");
				}
			}
		}
		OrccLogger.traceln("*\tEnd platform composing process...");
		
		///</ol> </ul>
		/// Platform composing process completed (<i> Back to compile()</i> )
		
	}
	
	/**
	 * Initialize internal variables
	 */
	protected void doInitializeInternalVariables() {

		////////////////////////
		// General attributes //
		////////////////////////
		
		luts = new ArrayList<SboxLut>();
		networkVertexMap = new LinkedHashMap<String,Map<String,String>>();
		netInstances = new LinkedHashMap<String,Set<String>>();

		//////////////////////////
		// Profiling attributes //
		//////////////////////////
		enMon = false;
		enArtico = false;
		enPulp = false;
		profileEn = false;
		bestInputMap = new LinkedHashMap<Network,Integer>();
		bestValues = new ArrayList<Float>();
		bestLuts = new ArrayList<SboxLut>();
		bestNetInstances = new LinkedHashMap<String,Set<String>>();

		///////////////////////////////
		// HDL generation attributes //
		///////////////////////////////
		genHDL = false;	
		lrEn = false;
		genCopr = false;

		///////////////////////////////
		// CAL generation attributes //
		///////////////////////////////
		genCAL = false;
	}

	@Override
	/**
	 * Initialize general attributes with options set by the Users*/
	protected void doInitializeOptions() {
		
		doInitializeInternalVariables();

		printer = new Printer();
				
		numFiles = Integer.parseInt(getOption("it.unica.diee.mdc.xdfNum", "<unknown>"));
		
		mergingAlgorithm = getOption("it.unica.diee.mdc.mergingAlgorithm","");
		
		inputFileList = new ArrayList<IFile>();
		for(String net: getOption("it.unica.diee.mdc.xdfList", "<unknown>").split(", ")){
			inputFileList.add(getFile(project, net, "xdf"));
		}
			   
		genCAL = getOption("it.unica.diee.mdc.genCAL", false);
		if(genCAL) {
			Calendar c = Calendar.getInstance();
			String date = c.get(Calendar.DAY_OF_MONTH) + "_" + (c.get(Calendar.MONTH)+1) + "_" + c.get(Calendar.YEAR);
			String hour = c.get(Calendar.HOUR_OF_DAY) + "_" + c.get(Calendar.MINUTE) + "_" + c.get(Calendar.SECOND);
			OrccLogger.traceln("* date " +  date);
			OrccLogger.traceln("* hour " + hour);
			calType = getOption("it.unica.diee.mdc.calType", "<unknown>");
			rvcCalOutputFolder = project.getLocation().toOSString() + File.separator + "src" + File.separator + "mdc__" + date + "__" + hour;
		}
		
		genHDL = getOption("it.unica.diee.mdc.genHDL", false);
		if(genHDL) {
			protocolFile = getOption("it.unica.diee.mdc.protocolFile","<unknown>");
			hdlCompLib = getOption("it.mdc.tool.hdlCompLib","");
			lrEn = getOption("it.unica.diee.mdc.computeLogicRegions",false);
			genCopr = getOption("it.unica.diee.mdc.genCopr",false);
			if(genCopr) {
				coprType = getOption("it.unica.diee.mdc.tilType","<unknown>");
			}
			enMon = getOption("it.unica.diee.mdc.monitoring", false);			
			enArtico = getOption("it.unica.diee.mdc.artico", false);			
			enPulp = getOption("it.unica.diee.mdc.pulp", false);
			if(enPulp) {
				hwpeWrapperGeneratorPath = getOption("it.unica.diee.mdc.hwpeWrapperGenTool", "<unknown>");
			}
		}
		

		
		profileEn = getOption("it.unica.diee.mdc.profile", false);
		if(profileEn) {
			profiler = new Profiler();
			String areaFile = getOption("it.unica.diee.mdc.areaFile", "<unknown>");
			String powerFile = getOption("it.unica.diee.mdc.powerFile", "<unknown>");
			String timingFile = getOption("it.unica.diee.mdc.timingFile", "<unknown>");
			profiler.initializeProfiler(outputPath,areaFile,powerFile,timingFile);
			bestValues = new ArrayList<Float>();
			bestNetwork = null;
			bestLuts = new ArrayList<SboxLut>();
			bestInputMap = new LinkedHashMap<Network,Integer>();
			profilingEffort = getOption("it.unica.diee.mdc.effort", "<unknown>");
		}
		prifileCount = 0;

		if(lrEn) {
			desFlow = getOption("it.unica.diee.mdc.flowType", "");
			lrTech = getOption("it.unica.diee.mdc.lrPowerSaving", "");
			lrCells = Integer.parseInt(getOption("it.unica.diee.mdc.fpgaCgCells", "<unknown>"));
		}
		configManager = new ConfigManager(outputPath,rvcCalOutputFolder);
	}
	
	/**
	 * Libraries extraction*/
	@Override
	protected Result doLibrariesExtraction() {
				
		final Result result = FilesManagerMdc.extract("/bundle/README.txt",outputPath);
		
		String prefix = "";
		if(genCopr){
			if(coprType.equals("MEMORY-MAPPED")) {
				prefix = "mm";
			} else {
				prefix = "s";
			}
		}
		
		/// If coprocessor generation is enabled, extract libraries depending on the processor-coprocessor communication
		if(genCopr) {
			/// <ol> <li> MEMORY-MAPPED
			result.merge(FilesManagerMdc.extract("/bundle/copr/vivado/Makefile", (outputPath + File.separator + prefix + "_accelerator" + File.separator + "drivers" + File.separator + "src")));
			if(coprType.equals("MEMORY-MAPPED")) {
				result.merge(FilesManagerMdc.extract("/bundle/copr/vivado/mm/front_end.v", (outputPath + File.separator + "mm_accelerator" + File.separator + "hdl")));
				result.merge(FilesManagerMdc.extract("/bundle/copr/vivado/mm/back_end.v", (outputPath + File.separator + "mm_accelerator" + File.separator + "hdl")));
				result.merge(FilesManagerMdc.extract("/bundle/copr/vivado/mm/axi_full_ipif.v", (outputPath + File.separator + "mm_accelerator" + File.separator + "hdl")));
				result.merge(FilesManagerMdc.extract("/bundle/copr/vivado/mm/local_memory.v", (outputPath + File.separator + "mm_accelerator" + File.separator + "hdl")));
				result.merge(FilesManagerMdc.extract("/bundle/copr/vivado/mm/counter.v", (outputPath + File.separator + "mm_accelerator" + File.separator + "hdl")));
				result.merge(FilesManagerMdc.extract("/bundle/copr/vivado/mm/bd.tcl", (outputPath + File.separator + "mm_accelerator" + File.separator + "bd")));
				if (lrEn){ // power gating not allowed for coprocessor generator
					result.merge(FilesManagerMdc.extract("/bundle/powerGating/FSM_cg.v", (outputPath + File.separator + "mm_accelerator" + File.separator +"hdl")));
					result.merge(FilesManagerMdc.extract("/bundle/powerGating/FSM.v", (outputPath + File.separator + "mm_accelerator" + File.separator +"hdl")));
				}
			/// <li> STREAM </ol>
			} else if(coprType.equals("STREAM")) {
				result.merge(FilesManagerMdc.extract("/bundle/copr/vivado/stream/counter.v", (outputPath + File.separator + "s_accelerator" + File.separator + "hdl")));
				if (lrEn){ // power gating not allowed for coprocessor generator
					result.merge(FilesManagerMdc.extract("/bundle/powerGating/FSM_cg.v", (outputPath + File.separator + "s_accelerator" + File.separator +"hdl")));
					result.merge(FilesManagerMdc.extract("/bundle/powerGating/FSM.v", (outputPath + File.separator + "s_accelerator" + File.separator +"hdl")));
				}
			}
		/// </ul>
		} else {
			if(lrEn){	// TODO  possible problem --> libraries in else if!!		
				if(lrTech.equals("POWER_GATING")) {
					result.merge(FilesManagerMdc.extract("/bundle/powerGating/FSM_cg.v", (outputPath + File.separator +"hdl")));
				} else {
					result.merge(FilesManagerMdc.extract("/bundle/powerGating/FSM_cg.v", (outputPath + File.separator +"hdl")));
					result.merge(FilesManagerMdc.extract("/bundle/powerGating/FSM.v", (outputPath + File.separator +"hdl")));
				}
			}
		}
		
		
		/// If the generation of a  ARTICo³ compliant kernel is enabled, extract libraries depending on the memory-mapped processor-coprocessor communication
		if(enArtico && !genCopr) {
			result.merge(FilesManagerMdc.extract("/bundle/copr/vivado/mm/front_end.v", (outputPath + File.separator + "src" + File.separator + "a3_cgr_accelerator" + File.separator + "verilog")));
			result.merge(FilesManagerMdc.extract("/bundle/copr/vivado/mm/back_end.v", (outputPath + File.separator + "src" + File.separator + "a3_cgr_accelerator" + File.separator + "verilog")));
			result.merge(FilesManagerMdc.extract("/bundle/copr/vivado/mm/counter.v", (outputPath + File.separator + "src" + File.separator + "a3_cgr_accelerator" + File.separator + "verilog")));
		} 
		
		if(enPulp && !genCopr) {
			result.merge(FilesManagerMdc.extract("/bundle/copr/pulp/interface_wrapper.sv", (outputPath + File.separator + "deps" 
		    + File.separator + "hwpe-multidataflow-wrapper" + File.separator + "rtl" + File.separator + "hwpe-engine"
		    + File.separator + "engine_dev")));
		}
				
		
		return result;
	}

	/**
	 * Merge the given input set of dataflow networks sharing, 
	 * if possible, the common actors
	 * 
	 * @param netMap
	 * 		the map of the input networks
	 * @param profileThisCase 
	 * 		to inhibit profiling when profiling is enabled (for the heuristic method)
	 * @return
	 * 		the resulting multi-dataflow network
	 */
	protected Network doMergingProcess(Map<Network,Integer> netMap, boolean profileThisCase) {
		/// Start merging process
		if(!profileEn)
			OrccLogger.traceln("*\tStart merging process...");
		
		/// <ul><li> instantiate network merger. It can be used the
		Merger merger = null;
		/// <ol><li> Moreano algorithm it.mdc.tool.core.multiDataflowGenerator.MoreanoMerger();
		/// <li> Empiric algorithm it.mdc.tool.core.multiDataflowGenerator.EmpiricMerger()</ol>
		if(mergingAlgorithm.equals("MOREANO")) {
			merger = new MoreanoMerger();
		} else if(mergingAlgorithm.equals("EMPIRIC")) {
			merger = new EmpiricMerger();
		}
		
		OrccLogger.traceln("*\tSelected merging algorithm: " + mergingAlgorithm);
		/// <li> instantiate and flatten networks 
		for(Network net : netMap.keySet()){
			new Instantiator(false).doSwitch(net);
			new NetworkFlattener().doSwitch(net);
		}
			
		/// <li> assign don't merge flag: assignFlag()
		assignFlag(netMap);	
		
		/// <li> If profiler is enabled calculate critical path: it.mdc.tool.profiling.Profiler.calculateCriticalPath()
		if(profileEn) {
			profiler.calculateCriticalPath(netMap.keySet());
		}
				
		/// <li> merging networks in the result network
		Network resultNetwork = DfFactory.eINSTANCE.createNetwork();
		try{
			
			/// <ol> <li> keep trace of the don't merge flags </ol>
			List<Network> currentList = new ArrayList<Network>();
			String id = "";
			for(int i=0; i<=netMap.size(); i++) {
				for(Network net: netMap.keySet())
					if(netMap.get(net) == i) {
						if(i != DONT_MERGE)
							id += net.getSimpleName() + "1";
						else
							id += net.getSimpleName() + "0";
						currentList.add(net);
					}
			}
			
			/// <li> merge networks
			resultNetwork = merger.merge(currentList,outputPath);
			//printer.printNetwork(resultNetwork);
			
			/// <li> set result network name with the don't merge trace
			if(prifileCount<10)
				resultNetwork.setName(0 + "" + prifileCount + "_" + id);
			else
				resultNetwork.setName(prifileCount + "_" + id);
			prifileCount++;

			
			/// <li> If profiler is enables update best network
			if(profileEn && profileThisCase) {
				List<Float> currValues = profiler.writeFile(resultNetwork);
				if(bestNetwork == null) {
					updateBestSolution(resultNetwork,merger,netMap,currValues);
				}
				
			/// <ol> <li> Frequency optimization
				if(profilingEffort.equals("FREQUENCY")){
					if( (currValues.get(profiler.FREQ).compareTo(bestValues.get(profiler.FREQ)))>0 ) {
						updateBestSolution(resultNetwork,merger,netMap,currValues);
					} else if( (currValues.get(profiler.FREQ).compareTo(bestValues.get(profiler.FREQ)))==0 ) {
						if( (currValues.get(profiler.AREA).compareTo(bestValues.get(profiler.AREA)))<0 
								&&(currValues.get(profiler.POWER).compareTo(bestValues.get(profiler.POWER)))<0 ) {
							updateBestSolution(resultNetwork,merger,netMap,currValues);
						}
					}
			/// <li> Area/Power optimization </ol>
				} else if(profilingEffort.equals("AREA/POWER")) {
					if(	(currValues.get(profiler.AREA).compareTo(bestValues.get(profiler.AREA)))<0 
							&& (currValues.get(profiler.POWER).compareTo(bestValues.get(profiler.POWER)))<0 ) {
						updateBestSolution(resultNetwork,merger,netMap,currValues);
					} else if(	(currValues.get(profiler.AREA).compareTo(bestValues.get(profiler.AREA)))==0 
							&& (currValues.get(profiler.POWER).compareTo(bestValues.get(profiler.POWER)))==0 ) {
						if (currValues.get(profiler.FREQ).compareTo(bestValues.get(profiler.FREQ))>0 ) {
							updateBestSolution(resultNetwork,merger,netMap,currValues);
						}
					}
				}
				
			}
			
		}catch(Exception e) {
			System.out.println("Exception on merging process! " + e);
			for(StackTraceElement se : e.getStackTrace())
				System.out.println("" + se);
		}
		
		/// <li> retrieve luts and instance sets infos (for HDL code generation)
		luts = merger.getSboxLuts();
		//TODO  gestire clk o no in base a power saving selezionato
		//netInstances = merger.getNetworksClkInstances();
		netInstances = merger.getNetworksInstances();
		networkVertexMap = merger.getNetworksVertexMap();

		if(!profileEn)
			OrccLogger.traceln("*\tEnd merging process...");
		
		netMap.clear();
		return resultNetwork;
		/// </ul>
		/// End merging process (<i> Back to compile()</i> )
	}
	
	/**
	 * This function executes the steps needed before the Hardware Generation.
	 * 
	 * @param resultNetwork
	 * network generated by the merging process ( doMergingProcess() ).
	 */
	@Override
	protected void beforeGeneration(Network resultNewtork)  {
	
		OrccLogger.traceln("*\tStart multi-dataflow printing process...");
		/// Start printing process completed. <ul>
		
		/// <li> create a copy of result multi-functional network
		Copier copier =  new Copier();
		Network network = (Network) copier.copy(resultNewtork);
		copier.copyReferences();
		
		File rvcCalPath = new File(rvcCalOutputFolder);
		// If directory doesn't exist, create it
		if (!rvcCalPath.exists()) {
			rvcCalPath.mkdirs();
					
		}
		
		// set the path name
		String pathName = rvcCalOutputFolder + File.separator + network.getSimpleName() + ".xdf";
		
		// delete previously generated diag (layout) files
		File f = new File(rvcCalOutputFolder + File.separator + network.getSimpleName() + ".xdfdiag");
		if(f.exists() && !f.isDirectory()) { 
			f.delete(); 
			OrccLogger.traceln("*\tDeleted already existent file " + f.getName());
		}
				
		/// <li> new resource set
		URI uri = URI.createFileURI(pathName);
		ResourceSet set = new ResourceSetImpl();		
		Resource resource = set.createResource(uri);
		
		/// <li> generate RVC-CAL specifications: 
		/// <ol> <li> Generate SBoxes: ConfigManager.generateSboxes()
		try {
			if(profileEn)
				configManager.generateSboxes(network,bestLuts,calType);
			else
				configManager.generateSboxes(network,luts,calType);
		/// <li> Add the input generated network to the resource set and save the set. </ol>
			resource.getContents().add(network);
			resource.save(null);

		} catch (IOException e) {
			System.out.println("Exception catched on XDF code generation process!\n\t" + e);
			for(StackTraceElement se : e.getStackTrace())
				System.out.println("" + se);
		}		

		OrccLogger.traceln("*\tEnd multi-dataflow printing process...");
		/// </ul>
		/// Printing process completed. (<i> Back to compile()</i>)
	}

	
	/**
	 * Give the list of maps where the input dataflow networks are 
	 * associated to integers to define their merging order.
	 * 
	 * @param networks
	 * 		the list of input dataflow networks
	 * @return
	 * 		the list of maps of input dataflow networks
	 */
	private List<Map<Network, Integer>> getNetMapList(List<Network> networks) {
		
		OrccLogger.traceln("* Generate list of nets maps..");
		
		// create the nets maps list
		List<Map<Network,Integer>> netMapList = new ArrayList<Map<Network,Integer>>();
		
		if(networks.size() > 1) {
			if(profileEn) {					// profiling enabled: all the combinations have to be calculated
				OrccLogger.traceln("* Calculate profiling combinations...");
				if((networks.size()<9)) {	// if the size is less than 9 all the combinations are calculated
					netMapList = new CombinationsGenerator().calculateCombinations(networks);
					//OrccLogger.traceln("Combinations created!");
				} else {					// if the size is greater or equal than 9 only a subset of combinations is calculated 
					int indx=1;
					Map<Network,Integer> map = new LinkedHashMap<Network,Integer>();
					for(Network net : networks) {
						map.put(net,indx);
						indx++;
					}
					// the subset is identified through a heuristic method basing on the percentage of the networks shared actors
					Network resultNetwork = doMergingProcess(copyMap(map), true);
					int numInstances = 0;
					for(Vertex v : resultNetwork.getChildren())
						if(!v.getAdapter(Actor.class).hasAttribute("sbox"))
							numInstances++;
					Map<Network,Map<Network,Integer>> preAnalysisMap = profiler.preAnalyze(networks,numInstances);
					profiler.writePreAnalyzeTab(preAnalysisMap);
					profiler.flagNetworks(networks);
					netMapList = new CombinationsGenerator().calculateCombinationsEff(networks);
				}
			} else {						// profiling disabled: generation of the map with the given input networks order
				int indx=1;
				Map<Network,Integer> map = new LinkedHashMap<Network,Integer>();
				for(Network net : networks) {
					map.put(net,indx);
					indx++;
				}
				netMapList.add(map);
			}
		} else { 							// there is only one network in the list of input networks
			Map<Network,Integer> newMap = new LinkedHashMap<Network,Integer>();
			newMap.put(networks.get(0),DONT_MERGE);
			netMapList.add(newMap);
		}
		return netMapList;
	}

	/**
	 * Print the correct usage of the backend
	 * 
	 * @param context
	 * 		the application context
	 * @param options
	 * 		the options of the backend
	 * @param parserMsg
	 * 		the parser message
	 */
	private void printUsage(IApplicationContext context, Options options,
			String parserMsg) {

		String footer = "";
		if (parserMsg != null && !parserMsg.isEmpty()) {
			footer = "\nMessage of the command line parser :\n" + parserMsg;
		}

		HelpFormatter helpFormatter = new HelpFormatter();
		helpFormatter.setWidth(80);
		helpFormatter.printHelp(getClass().getSimpleName()
				+ " [options] <network.qualified.name>", "Valid options are :",
				options, footer);
	}
	
	
	/**
	 *Start the MDC backend run
	 *
	 * @param context
	 * 		the application context
	 * */
	@Override
	public Object start(IApplicationContext context) throws Exception {

		Options options = new Options();
		Option opt;

		// Required command line arguments
		opt = new Option("p", "project", true, "Project name");
		opt.setRequired(true);
		options.addOption(opt);

		opt = new Option("o", "output", true, "Output folder");
		opt.setRequired(true);
		options.addOption(opt);

		// Optional command line arguments
		options.addOption("n", "numNets", false, "Number of networks");
		options.addOption("g", "mergeAlgo", false, "Merging process algorithm");
		options.addOption("x", "sboxCal", false, "Generate sbox Cal");
		options.addOption("y", "calType", false, "Sbox Cal type");
		options.addOption("h", "writeHdl", false, "Write HDL top module");
		options.addOption("f", "protocolFile", false, "Hardware Communication protocol file");
		options.addOption("f", "hdlCompLib", false, "HDL Component Library");
		options.addOption("i", "importBS", false, "Import Buffer Size Files");
		options.addOption("b", "folderBS", false, "Folder of Buffer Size Files");
		options.addOption("t", "genCopr", false, "Generate Coprocessor Template Layer");
		options.addOption("k", "coprType", false, "Coprocessor TIL type");
		options.addOption("e", "lrEn", false, "Enable logic regions computing");
		options.addOption("s", "desFlow", false, "Type of design flow");
		options.addOption("c", "cgCells", false, "Clock gating cells number");
		options.addOption("m", "profileEn", false, "Profiler enable");
		options.addOption("a", "areaFile", false, "Area profiler file");
		options.addOption("w", "powerFile", false, "Power profiler file");
		options.addOption("t", "timingFile", false, "Power profiler file");
		options.addOption("r", "profEffort", false, "Profiling effort");
		options.addOption("z", "partname", false, "Xilinx Board partname");
		options.addOption("d", "boardpart", false, "Xilinx Board boardpart");

		try {
			
			CommandLineParser parser = new PosixParser();

			///<ul> <li> parse the command line arguments
			CommandLine line = parser.parse(options, (String[]) context
					.getArguments().get(IApplicationContext.APPLICATION_ARGS));

			///<li> parse network names arguments
			List<String> networkNames = new ArrayList<String>();
			for (String arg : line.getArgs()) {
				networkNames.add(arg);
			}
			/// <li> initialize options map
			Map<String, Object> optionMap = new HashMap<String, Object>();
			
			optionMap.put(PROJECT, line.getOptionValue('p'));
			optionMap.put(OUTPUT_FOLDER, line.getOptionValue('o'));
			optionMap.put("it.unica.diee.mdc.xdfNum", line.getOptionValue('n'));
			optionMap.put("it.unica.diee.mdc.xdfList", networkNames);
			optionMap.put("it.unica.diee.mdc.mergingAlgorithm", line.getOptionValue('g'));
			optionMap.put("it.unica.diee.mdc.genCAL", line.getOptionValue('x'));
			optionMap.put("it.unica.diee.mdc.calType", line.getOptionValue('y'));
			optionMap.put("it.unica.diee.mdc.genHDL", line.getOptionValue('h'));
			optionMap.put("it.unica.diee.mdc.protocolFile", line.getOptionValue('f'));
			optionMap.put("it.mdc.tool.hdlCompLib", line.getOptionValue('l'));
			optionMap.put("it.unica.diee.mdc.genCopr", line.getOptionValue('t'));
			optionMap.put("it.unica.diee.mdc.coprType", line.getOptionValue('k'));
			optionMap.put("it.mdc.tool.ipTgtBpart", line.getOptionValue('d'));
			optionMap.put("it.mdc.tool.ipTgtPart", line.getOptionValue('z'));
			optionMap.put("it.unica.diee.mdc.computeLogicRegions", line.getOptionValue('e'));
			optionMap.put("it.unica.diee.mdc.importBufferSizeFileList", line.getOptionValue('i'));
			optionMap.put("it.unica.diee.mdc.bufferSizeFilesFolder", line.getOptionValue('b'));
			optionMap.put("it.unica.diee.mdc.flowType", line.getOptionValue('s'));
			optionMap.put("it.unica.diee.mdc.fpgaCgCells", line.getOptionValue('c'));
			optionMap.put("it.unica.diee.mdc.profile", line.getOptionValue('m'));
			optionMap.put("it.unica.diee.mdc.areaFile", line.getOptionValue('a'));
			optionMap.put("it.unica.diee.mdc.powerFile", line.getOptionValue('w'));
			optionMap.put("it.unica.diee.mdc.timingFile", line.getOptionValue('t'));
			optionMap.put("it.unica.diee.mdc.effort", line.getOptionValue('r'));
			
			try {
				///<li> set options
				setOptions(optionMap);
				///<li> launch compile()
				compile(new NullProgressMonitor());
				return IApplication.EXIT_OK;
			} catch (OrccRuntimeException e) {
				OrccLogger.severeln(e.getMessage());
				OrccLogger.severeln("Could not run the back-end with \""
						+ networkNames + "\" :");
				OrccLogger.severeln(e.getLocalizedMessage());
			} catch (Exception e) {
				OrccLogger.severeln("Could not run the back-end with \""
						+ networkNames + "\" :");
				OrccLogger.severeln(e.getLocalizedMessage());
				e.printStackTrace();
			}
			return IApplication.EXIT_RELAUNCH;
				
		} catch (UnrecognizedOptionException uoe) {
		/// <li> launch printUsage()
			printUsage(context, options, uoe.getLocalizedMessage());
		} catch (ParseException exp) {
			printUsage(context, options, exp.getLocalizedMessage());
		}
		return IApplication.EXIT_RELAUNCH;
		/// </ul>
		
		///End start() (<i> Back to it.mdc.tool.core.MDCBackend() or go to compile(). </i>) </ul>
	}
	
	/**
	 * Check the current ProgressMonitor for cancellation, and throws a
	 * OperationCanceledException if needed. This will simply stop the back-end
	 * execution.
	 */
	protected void stopIfRequested() {
		if (monitor != null) {
			if (monitor.isCanceled()) {
				throw new OperationCanceledException();
			}
		}
	}
	
	/**
	 * Update the best solution fields (profiling flow)
	 * 
	 * @param resultNetwork
	 * @param merger
	 * @param netMap
	 * @param currValues
	 */
	private void updateBestSolution(Network resultNetwork,
			Merger merger, Map<Network, Integer> netMap,
			List<Float> currValues) {
		bestValues = currValues;
		bestNetwork = resultNetwork;
		bestLuts = merger.getSboxLuts();
		//TODO  gestire clk o no in base a power saving selezionato
		//bestNetInstances = merger.getNetworksClkInstances();
		bestNetInstances = merger.getNetworksInstances();
		bestInputMap =  new LinkedHashMap<Network,Integer>(netMap);
	}
		
}