package it.unica.diee.mdc;

import org.xronos.orcc.backend.Xronos;

import static net.sf.orcc.OrccLaunchConstants.BACKEND;
import static net.sf.orcc.OrccLaunchConstants.OUTPUT_FOLDER;
import static net.sf.orcc.OrccLaunchConstants.PROJECT;
import static net.sf.orcc.util.OrccUtil.getFile;

import java.util.Calendar;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;

import net.sf.orcc.OrccException;
import net.sf.orcc.OrccRuntimeException;
import net.sf.orcc.backends.AbstractBackend;
import net.sf.orcc.backends.Backend;
import net.sf.orcc.backends.BackendFactory;
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

import it.unica.diee.mdc.merging.EmpiricMerger;
import it.unica.diee.mdc.merging.MoreanoMerger;
import it.unica.diee.mdc.platformComposer.*;
import it.unica.diee.mdc.profiling.*;
import it.unica.diee.mdc.sboxManagement.*;
import it.unica.diee.mdc.utility.*;
import it.unica.diee.mdc.merging.*;
import static it.unica.diee.mdc.profiling.Profiler.DONT_MERGE;

import java.io.File;
import java.io.IOException;

import net.sf.orcc.df.util.NetworkValidator;
import net.sf.orcc.graph.Vertex;



/**
 * MDC backend
 * 
 * @author Carlo Sau
 * 
 */
public class MdcBackendImpl extends AbstractBackend {

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
	
	// Instances
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
	
	// Profiling attributes
	////////////////////////////////////////////////////////
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
	
	// HDL generation attributes
	////////////////////////////////////////////////////////
	/**
	 * Enable HDL generation
	 */
	private boolean genHDL;	
	
	/**
	 * Type of communication protocol
	 */
	private String protType;	
	
	/**
	 * Type of communication protocol file
	 */
	private String customProtocolFile;

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
	
	/**
	 *Co-processing layer targeted environment
	 */
	private String coprEnv;
	////////////////////////////////////////////////////////
	
	
	// CAL generation attributes
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
	 * Assign DONT_MERGE flag to the actors involved in 
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
	
	
	@Override
	public void compile(IProgressMonitor progressMonitor){	 
		
		//remove all files and directories from the output directory
		//purgeDirectory(new File(outputPath));
		
		// Initialize the monitor. Can be used to stop the back-end
		// execution and provide feedback to user
		monitor = progressMonitor;
		
		String orccVersion = "<unknown>";
		Bundle bundle = Platform.getBundle(Activator.PLUGIN_ID);
		if (bundle != null) {
			orccVersion = bundle.getHeaders().get("Bundle-Version");
		}

		// Initialize the monitor. Can be used to stop the back-end
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
	    
		// input networks list
		List<Network> networks = new ArrayList<Network>();
		
		// parse list of networks
		for(IFile fileIN : inputFileList){
			
			if(fileIN == null) {
				throw new OrccRuntimeException("The input XDF file does not exist.");
			}
			Network currNet= (Network) EcoreHelper.getEObject(set, fileIN);			
			
			// validate network
			new NetworkValidator().doSwitch(currNet);
			
			// add network to the input network list
			networks.add(currNet);
	    }	
		
		// set configuration manager input networks list
		configManager.setNetworkList(networks);
		
		// verify the input networks number
		try{
			if (numFiles!=networks.size()) {
				throw new OrccException("");
			}
		} catch (OrccException e) {
			OrccLogger.traceln("WARNING: The number of given input XDF networks" +
					" does not match the specified value of networks to be merged!");
		}
		
		// generate the list of maps of input networks
		List<Map<Network,Integer>> netMapList = getNetMapList(networks);
		
		// extract size map and progress (for profiling purposes)
		int sizeMap = netMapList.size();
		int progress=0;
				
		if(profileEn) {
			OrccLogger.traceln("* Design space size: " + sizeMap + " points");
			OrccLogger.trace("* Profile design space...0%");
		}
		
		// analyze the maps of input networks 
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
				
				// merge current map of input networks into the resulting network
				Network resultNetwork = doMergingProcess(copyMap(currMap), true);
				
				//OrccLogger.traceln("v " + resultNetwork.getVertices());
				//OrccLogger.traceln("c " + resultNetwork.getConnections());
				
				// generate the resulting network report
				// TODO fix error on copr path
				if(!profileEn)
					printer.printReport(currMap,resultNetwork,outputPath,genCopr,coprType,coprEnv);
				
				// generate the resulting network RVC-CAL specification
				if(!profileEn && genCAL) {
					resultNetwork.setName("multi_dataflow");
					beforeGeneration(resultNetwork);	
				}

				// compose the HDL platform of the generated resulting network
				if(!profileEn && genHDL) {
					doHdlCodeGeneration(resultNetwork);					
				}
				
				// TODO remove DPM OR PATH?
				if(!profileEn) {
					configManager.generateConfigFile(genCopr,coprEnv,coprType);
				}
				
			} catch (Exception e) {
				System.out.println("Exception on doXdfCodeGenerationList!");
				e.printStackTrace();
			}
		}
		
		// print the profiling resulting network and generate the related report
		if(profileEn){
			OrccLogger.traceln("* Profiling effort: " + profilingEffort);
			OrccLogger.traceln("* Best network " + bestNetwork.getSimpleName());
			OrccLogger.traceln("*\tBest values " + bestValues.get(profiler.AREA) + " um2, " +
					bestValues.get(profiler.POWER) + " nW, " +
					bestValues.get(profiler.FREQ) + " kHz.");
			//OrccLogger.traceln("netMapList.get(0) " + netMapList.get(0) );
			printer.printReport(bestInputMap,bestNetwork,outputPath,genCopr,coprType,coprEnv);
			bestNetwork.setName("multi_dataflow");
		}
			
		if(profileEn) {
			profiler.closeFile();
			profiler.compressProfilingFile(outputPath);
		}
		
		// generate the profiling resulting network RVC-CAL specification
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
	 * Generate HDL top modules of the given network
	 * 
	 * @param network
	 * 		the network whose top modules have to be
	 * 		generated
	 */
	protected void doHdlCodeGeneration(Network network){
		
		OrccLogger.traceln("*\tStart platform composing process...");

		FileCopier copier = new FileCopier();
		
		// set hdl directory
		File hdlDir= new File("");
		if(!genCopr) {
			hdlDir = new File(outputPath + File.separator + "hdl");
		} else {
			if(coprEnv.equals("ISE")) {
				if(coprType.equals("MEMORY-MAPPED")) {
					hdlDir = new File(outputPath + File.separator + "mm_accelerator_v1_00_a" + File.separator  + "hdl");
				} else {
					hdlDir = new File(outputPath + File.separator + "s_accelerator_v1_00_a" + File.separator  + "hdl");
				}
			} else {
				if(coprType.equals("MEMORY-MAPPED")) {
					hdlDir = new File(outputPath + File.separator + "mm_accelerator" + File.separator  + "hdl");
				} else {
					hdlDir = new File(outputPath + File.separator + "s_accelerator" + File.separator  + "hdl");
				}
			}
				
		}
		// if directory doesn't exist, create it
		if (!hdlDir.exists()) {
			hdlDir.mkdirs();
		}

		
		if(profileEn)
			OrccLogger.traceln("*\tComposing network name: " + network.getName());
		
		// set network name
		network.setName("multi_dataflow"); 

		// write HDL code
		try {
			
			// get the platform composer for the selected language
			PlatformComposer hdlWriter = getPlatformComposer(hdlDir.getPath(), network);
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
			
			// TODO integrazione con profiler --> occhio al nuovo file estratto dal merger (networkVertexMap)!! -- dev'essere il best! 
			
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
			
			
			//TODO uniformare notazioni per clock domains e logic regions
			//		e gestire caso con 0 lr e 0 cd
			
			if(!lrEn) {	// logic regions computing disabled
				
				// generate top module
				hdlWriter.initClockDomains(clockDomains);
				hdlWriter.generateTop(lutsToGen,getOptions());
				
				// generate network configurator
				if(!luts.isEmpty())
					hdlWriter.generateConfig(genCopr,lutsToGen);
				
			} else if(!luts.isEmpty()) { // logic regions computing

				OrccLogger.traceln("*\t\tLogic regions computing...");
				
				// Logic Regions (LRs) identification
				LogicRegionFinder lrFinder = new LogicRegionFinder();
				lrFinder.findRegions(netInstancesToGen);
				
				Map<String,Set<String>> logicRegions = lrFinder.getRegions();
				Map<String,Set<String>> netRegions = lrFinder.getNetRegions();
				Map<String,Set<String>> logicRegionsNetsMap  = new HashMap <String,Set<String>>();
				Set<String> powerSets  = new HashSet <String>();
				Map<String,Integer> powerSetsIndex  = new HashMap <String,Integer>();
				Map<String,Boolean> logicRegionsSeqMap  = new HashMap <String,Boolean>();
								
				// Logic Regions (LRs) merging
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
									
				
					// inizialize platform composer with the found LRs
					hdlWriter.initClockDomains(clockDomains);
					hdlWriter.initLogicRegions(logicRegions);
					hdlWriter.initNetRegions(netRegions);
					hdlWriter.initPowerSets(powerSets);
					hdlWriter.initPowerSetsIndex(powerSetsIndex);
					hdlWriter.initlogicRegionsSeqMap(logicRegionsSeqMap);
									
					// generate top module and network configurator
					hdlWriter.generateTop(lutsToGen,getOptions());
					hdlWriter.generateConfig(genCopr,lutsToGen);
					
					//OrccLogger.traceln(netRegions);
					
					// generate LRs enable generator
					if(!lrTech.equals("POWER_GATING"))
					{
						hdlWriter.generateEnableGenerator(netRegions);
						}
					
					hdlWriter.generateClockGatingCell(desFlow);
					
					//System.out.println("logic regions " + logicRegions);
					//System.out.println("logicRegionsNetsMap " + logicRegionsNetsMap);
					//System.out.println("netRegions " + netRegions);
				
					printer.printLogicRegionsReport(outputPath, genCopr, coprType, logicRegions, netRegions, logicRegionsNetsMap);
			}

			String pcoresDir = outputPath + File.separator + "pcores";
			
			// generate computational actors through Xronos
			if(protType.equals("RVC")) {
				OrccLogger.traceln("*\tLaunching Xronos HLS to synthesize actors...");
				Backend backend = BackendFactory.getInstance().getBackend("Xronos Verilog");
				backend.setOptions(getOptions());
				((Xronos) backend).generateInstances(network);
			    			
				if(genCopr) {
					if(coprEnv.equals("ISE")) {
						File pcores = new File(pcoresDir);
						if(!pcores.exists()) {
							pcores.mkdir();
						}
					}
				}
			}
			
			// generate coprocessor HDL code
			if(genCopr){
				// TODO uniformare nomi reti (include path ora) per config id
				hdlWriter.generateCopr(coprType,coprEnv,luts,networkVertexMap);
				if(coprEnv.equals("ISE")) {
					if(coprType.equals("STREAM")) { 
						copier.copy(outputPath + File.separator + "s_accelerator_v1_00_a", pcoresDir + File.separator + "s_accelerator_v1_00_a");
						copier.copy(outputPath + File.separator + "rtl", pcoresDir + File.separator + "s_accelerator_v1_00_a" + File.separator + "hdl" + File.separator + "verilog");
						File delDir = new File(outputPath + File.separator + "sim");
						copier.delete(delDir);
						delDir = new File(outputPath + File.separator + "testbench");
						copier.delete(delDir);
						delDir = new File(outputPath + File.separator + "s_accelerator_v1_00_a");
						copier.delete(delDir);
						delDir = new File(outputPath + File.separator + "pcores" + File.separator + "s_accelerator_v1_00_a" + File.separator + "hdl" + File.separator + "verilog" + File.separator + "report");
						copier.delete(delDir);
						delDir = new File(outputPath + File.separator + "rtl");
						copier.delete(delDir);
					} else if(coprType.equals("MEMORY-MAPPED")) {
						copier.copy(outputPath + File.separator + "mm_accelerator_v1_00_a", pcoresDir + File.separator + "mm_accelerator_v1_00_a");
						copier.copy(outputPath + File.separator + "rtl", pcoresDir + File.separator + "mm_accelerator_v1_00_a" + File.separator + "hdl" + File.separator + "verilog");
						File delDir = new File(outputPath + File.separator + "sim");
						copier.delete(delDir);
						delDir = new File(outputPath + File.separator + "testbench");
						copier.delete(delDir);
						delDir = new File(outputPath + File.separator + "mm_accelerator_v1_00_a");
						copier.delete(delDir);
						delDir = new File(outputPath + File.separator + "pcores" + File.separator + "mm_accelerator_v1_00_a" + File.separator + "hdl" + File.separator + "verilog" + File.separator + "report");
						copier.delete(delDir);
						delDir = new File(outputPath + File.separator + "rtl");
						copier.delete(delDir); 
					}
				} else {
					String prefix = "";
					if(coprType.equals("MEMORY-MAPPED")) {
						prefix = "mm";
					} else if(coprType.equals("STREAM")) {	
						prefix = "s";
					} else {
						//TODO hybrid
					}
					copier.copy(outputPath + File.separator + "rtl", outputPath + File.separator + prefix + "_accelerator" + File.separator + "hdl");
					File delDir = new File(outputPath + File.separator + "sim");
					copier.delete(delDir);
					delDir = new File(outputPath + File.separator + "testbench");
					copier.delete(delDir);
					delDir = new File(outputPath + File.separator + prefix + "_accelerator" + File.separator + "hdl" + File.separator + "report");
					copier.delete(delDir);
					delDir = new File(outputPath + File.separator + "rtl");
					copier.delete(delDir);
				}
			}
			
		}catch(Exception e) {
			System.out.println("Exception catched on HDLwriter operations!\n\t" + e);
			for(StackTraceElement se : e.getStackTrace())
				System.out.println("" + se);
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
				
			
			if(genCopr | protType.equals("RVC") | exportPowerGatingLibraries)
			{	
				final Result result = doLibrariesExtraction();
				if(!result.isEmpty()) {
					OrccLogger.traceln("*\tLibrary export done in " + getDuration(t0) + "s");
				}
			}
		}
		OrccLogger.traceln("*\tEnd platform composing process...");
		
	}

	@Override
	protected void doInitializeOptions() {

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
		
		protType = getOption("it.unica.diee.mdc.protocol", "<unknown>");
		
		if((protType.equals("CUSTOM") || protType.equals("CUSTOM full (beta)")) && getOption("it.unica.diee.mdc.customProtocol", false)) {
			customProtocolFile= getOption("it.unica.diee.mdc.customProtocolFile", "<unknown>");
		}
		
			   
		lrEn = getOption("it.unica.diee.mdc.computeLogicRegions",false);

		genCopr = getOption("it.unica.diee.mdc.genCopr",false);
		coprType = getOption("it.unica.diee.mdc.tilType","<unknown>");
		coprEnv = getOption("it.unica.diee.mdc.tilEnv","<unknown>");
		
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
			bestInputMap = new HashMap<Network,Integer>();
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
	
	@Override
	protected Result doLibrariesExtraction() {
				
		final Result result;

		if(genCopr) {
			if(coprEnv.equals("ISE")) {
				if(coprType.equals("MEMORY-MAPPED")) {
					result = FilesManagerMdc.extract("/bundle/copr/mm/hdl/verilog", (outputPath + File.separator + "pcores" + File.separator + "mm_accelerator_v1_00_a" + File.separator + "hdl"));
					result.merge(FilesManagerMdc.extract("/bundle/copr/mm/hdl/vhdl", (outputPath + File.separator + "pcores" + File.separator + "mm_accelerator_v1_00_a" + File.separator + "hdl")));
					result.merge(FilesManagerMdc.extract("/bundle/copr/mm/data", (outputPath + File.separator + "pcores" +  File.separator + "mm_accelerator_v1_00_a")));
					if(protType.equals("RVC")) {
						result.merge(FilesManagerMdc.extract("/bundle/copr/SystemMdc", (outputPath + File.separator + "pcores")));
						result.merge(FilesManagerMdc.extract("/bundle/copr/SystemBuilder", (outputPath + File.separator + "pcores")));
					}
				} else if(coprType.equals("STREAM")) {
					result = FilesManagerMdc.extract("/bundle/copr/stream/hdl/verilog", (outputPath + File.separator + "pcores" + File.separator + "s_accelerator_v1_00_a" + File.separator + "hdl"));
					if(protType.equals("RVC")) {
						result.merge(FilesManagerMdc.extract("/bundle/copr/SystemMdc", (outputPath + File.separator + "pcores")));
						result.merge(FilesManagerMdc.extract("/bundle/copr/SystemBuilder", (outputPath + File.separator + "pcores")));
					}
				} else {
					result = FilesManagerMdc.extract("/bundle/copr/stream", (outputPath + File.separator + "hdl" + File.separator + "verilog"));
					if(protType.equals("RVC")) {
							result.merge(FilesManagerMdc.extract("/bundle/lib", (outputPath + File.separator)));
					}
				}
			} else {
				String prefix = "";
				if(coprType.equals("MEMORY-MAPPED")) {
					prefix = "mm";
				} else {
					prefix = "s";
				}
				result = FilesManagerMdc.extract("/bundle/lib/SystemBuilder/sbfifo.vhdl", (outputPath + File.separator + prefix + "_accelerator" + File.separator + "hdl"));
				result.merge(FilesManagerMdc.extract("/bundle/lib/SystemBuilder/sbfifo_behavioral.vhdl", (outputPath + File.separator + prefix + "_accelerator" + File.separator + "hdl")));
				result.merge(FilesManagerMdc.extract("/bundle/lib/SystemBuilder/sbtypes.vhdl", (outputPath + File.separator + prefix + "_accelerator" + File.separator + "hdl")));
				result.merge(FilesManagerMdc.extract("/bundle/lib/SystemMdc/mdc.vhd", (outputPath + File.separator + prefix + "_accelerator" + File.separator + "hdl")));
				if(coprType.equals("MEMORY-MAPPED")) {
					result.merge(FilesManagerMdc.extract("/bundle/copr/vivado/mm/front_end.v", (outputPath + File.separator + "mm_accelerator" + File.separator + "hdl")));
					result.merge(FilesManagerMdc.extract("/bundle/copr/vivado/mm/back_end.v", (outputPath + File.separator + "mm_accelerator" + File.separator + "hdl")));
					result.merge(FilesManagerMdc.extract("/bundle/copr/vivado/mm/axi_full_ipif.v", (outputPath + File.separator + "mm_accelerator" + File.separator + "hdl")));
					result.merge(FilesManagerMdc.extract("/bundle/copr/vivado/mm/local_memory.v", (outputPath + File.separator + "mm_accelerator" + File.separator + "hdl")));
					result.merge(FilesManagerMdc.extract("/bundle/copr/vivado/mm/counter.v", (outputPath + File.separator + "mm_accelerator" + File.separator + "hdl")));
				} else if(coprType.equals("STREAM")) {
					result.merge(FilesManagerMdc.extract("/bundle/copr/vivado/stream/front_end.v", (outputPath + File.separator + "s_accelerator" + File.separator + "hdl")));
					result.merge(FilesManagerMdc.extract("/bundle/copr/vivado/stream/back_end.v", (outputPath + File.separator + "s_accelerator" + File.separator + "hdl")));
				}
			}
		} else if (lrEn){
			//lrTech.equals("POWER_GATING")
			//System.out.println("FSM extraction in " +  (outputPath + File.separator + "hdl" + File.separator + "verilog"));
			
			result = FilesManagerMdc.extract("/bundle/powerGating/FSM_cg.v", (outputPath +  File.separator +"hdl" + File.separator + "verilog"));
			result.merge(FilesManagerMdc.extract("/bundle/powerGating/FSM.v", (outputPath +  File.separator +"hdl" + File.separator + "verilog")));
	
		}
		
		else {

			result = FilesManagerMdc.extract("/bundle/lib/SystemBuilder", (outputPath + File.separator + "lib"));
			result.merge(FilesManagerMdc.extract("/bundle/lib/SystemMdc", (outputPath + File.separator + "lib")));
		}
		if (lrEn){	// TODO possible problem --> libraries in else if!!		
			 if(lrTech.equals("POWER_GATING")) {
				 result.merge(FilesManagerMdc.extract("/bundle/powerGating/FSM_cg.v", (outputPath +  File.separator +"hdl" + File.separator + "verilog")));
			 }
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
		
		if(!profileEn)
			OrccLogger.traceln("*\tStart merging process...");
		
		//OrccLogger.traceln("map " + netMap);
		
		// instantiate network merger
		Merger merger = null;
		//MergerMoreano merger = new MergerMoreano();
		if(mergingAlgorithm.equals("MOREANO")) {
			merger = new MoreanoMerger();
		} else if(mergingAlgorithm.equals("EMPIRIC")) {
			merger = new EmpiricMerger();
		}
		//OrccLogger.traceln("*\tSelected merging algorithm: " + mergingAlgorithm);
		// instantiate and flatten networks 
		for(Network net : netMap.keySet()){
			
			//OrccLogger.traceln("Instantiating " + net + "...");
			new Instantiator(false).doSwitch(net);
			
			//OrccLogger.traceln("Flattening " + net + "...");
			new NetworkFlattener().doSwitch(net);
			
		}
			
		// assign don't merge flag
		assignFlag(netMap);	
		
		// calculate critical path (for profiling purposes)
		if(profileEn) {
			profiler.calculateCriticalPath(netMap.keySet());
		}
				
		// merging networks in the result network
		Network resultNetwork = DfFactory.eINSTANCE.createNetwork();
		try{
			
			// keep trace of the don't merge flags
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
			
			// merge networks
			//System.out.println("pre merg");
			resultNetwork = merger.merge(currentList,outputPath);
			//printer.printNetwork(resultNetwork);
			//System.out.println("post merg");
			
			// set result network name with the don't merge trace
			if(prifileCount<10)
				resultNetwork.setName(0 + "" + prifileCount + "_" + id);
			else
				resultNetwork.setName(prifileCount + "_" + id);
			prifileCount++;

			//System.out.println("pre calc");
			
			// update best network (for profiling purposes)
			if(profileEn && profileThisCase) {
				List<Float> currValues = profiler.writeFile(resultNetwork);
				//System.out.println("post calc");
				if(bestNetwork == null) {
					updateBestSolution(resultNetwork,merger,netMap,currValues);
				}
				
				if(profilingEffort.equals("FREQUENCY")){
					if( (currValues.get(profiler.FREQ).compareTo(bestValues.get(profiler.FREQ)))>0 ) {
						updateBestSolution(resultNetwork,merger,netMap,currValues);
					} else if( (currValues.get(profiler.FREQ).compareTo(bestValues.get(profiler.FREQ)))==0 ) {
						if( (currValues.get(profiler.AREA).compareTo(bestValues.get(profiler.AREA)))<0 
								&&(currValues.get(profiler.POWER).compareTo(bestValues.get(profiler.POWER)))<0 ) {
							updateBestSolution(resultNetwork,merger,netMap,currValues);
						}
					}

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
		
		// retrieve luts and instance sets infos (for HDL code generation)
		luts = merger.getSboxLuts();
		//TODO gestire clk o no in base a power saving selezionato
		//netInstances = merger.getNetworksClkInstances();
		netInstances = merger.getNetworksInstances();
		networkVertexMap = merger.getNetworksVertexMap();
		
		/*for(String net : netInstances.keySet()) {
			System.out.println("NET " + net);
			for(String inst : netInstances.get(net)) {
			System.out.println("\t " + inst);
			}
		}*/
		if(!profileEn)
			OrccLogger.traceln("*\tEnd merging process...");
		
		netMap.clear();
		return resultNetwork;
	}

	@Override
	protected void beforeGeneration(Network resultNewtork)  {
	
		OrccLogger.traceln("*\tStart multi-dataflow printing process...");
	
		// copy result network
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
				
		// new resource set
		URI uri = URI.createFileURI(pathName);
		ResourceSet set = new ResourceSetImpl();		
		Resource resource = set.createResource(uri);
		
		// generate RVC-CAL specifications 
		try {
			if(profileEn)
				configManager.generateSboxes(network,bestLuts,calType);
			else
				configManager.generateSboxes(network,luts,calType);

			resource.getContents().add(network);
			resource.save(null);

		} catch (IOException e) {
			System.out.println("Exception catched on XDF code generation process!\n\t" + e);
			for(StackTraceElement se : e.getStackTrace())
				System.out.println("" + se);
		}		

		OrccLogger.traceln("*\tEnd multi-dataflow printing process...");
			
	}
	
	/**
	 * Calculate the time elapsed between the given <em>t0</em> and the current
	 * timestamp.
	 * 
	 * @return The number of seconds, as a float
	 */
	final private float getDuration(long t0) {
		return (float) (System.currentTimeMillis() - t0) / 1000;
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
					Map<Network,Integer> map = new HashMap<Network,Integer>();
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
				Map<Network,Integer> map = new HashMap<Network,Integer>();
				for(Network net : networks) {
					map.put(net,indx);
					indx++;
				}
				netMapList.add(map);
			}
		} else { 							// there is only one network in the list of input networks
			Map<Network,Integer> newMap = new HashMap<Network,Integer>();
			newMap.put(networks.get(0),DONT_MERGE);
			netMapList.add(newMap);
		}
		return netMapList;
	}


	/**
	 * Give a type of platform composer object basing on the 
	 * selected protocol file
	 * 
	 * @param hdlPath
	 * 		output path of the HDL generation
	 * @param
	 * 		the multi-dataflow network for the HDL generation
	 * @return
	 * 		the desired platform composer instance
	 * @throws IOException
	 */
	private PlatformComposer getPlatformComposer(String hdlPath, Network network) throws IOException {
		
		if(protType.equals("RVC"))
				return new RvcPrinter(hdlPath,configManager,network);
		else if(protType.equals("CUSTOM")) {
			//System.out.println("customProtocolFile " + customProtocolFile);
				return new CustomPrinter(hdlPath,configManager,network,customProtocolFile);
		}else if(protType.equals("CUSTOM full (beta)")) {
				return new NetworkPrinter(hdlPath,configManager,network,customProtocolFile);
		}
	
		return null;
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
		options.addOption("l", "protocol", false, "Preferred HDL protocol");
		options.addOption("f", "protFile", false, "Communication protocol file");
		options.addOption("i", "importBS", false, "Import Buffer Size Files");
		options.addOption("b", "folderBS", false, "Folder of Buffer Size Files");
		options.addOption("t", "genCopr", false, "Generate Coprocessor Template Layer");
		options.addOption("k", "coprType", false, "Coprocessor TIL type");
		options.addOption("v", "coprEnv", false, "Coprocessor environment");
		options.addOption("e", "lrEn", false, "Enable logic regions computing");
		options.addOption("s", "desFlow", false, "Type of design flow");
		options.addOption("c", "cgCells", false, "Clock gating cells number");
		options.addOption("m", "profileEn", false, "Profiler enable");
		options.addOption("a", "areaFile", false, "Area profiler file");
		options.addOption("w", "powerFile", false, "Power profiler file");
		options.addOption("t", "timingFile", false, "Power profiler file");
		options.addOption("r", "profEffort", false, "Profiling effort");

		try {
			
			CommandLineParser parser = new PosixParser();

			// parse the command line arguments
			CommandLine line = parser.parse(options, (String[]) context
					.getArguments().get(IApplicationContext.APPLICATION_ARGS));

			// parse network names arguments
			List<String> networkNames = new ArrayList<String>();
			for (String arg : line.getArgs()) {
				networkNames.add(arg);
			}
			Map<String, Object> optionMap = new HashMap<String, Object>();
			
			optionMap.put(PROJECT, line.getOptionValue('p'));
			optionMap.put(OUTPUT_FOLDER, line.getOptionValue('o'));
			optionMap.put("it.unica.diee.mdc.xdfNum", line.getOptionValue('n'));
			optionMap.put("it.unica.diee.mdc.xdfList", networkNames);
			optionMap.put("it.unica.diee.mdc.mergingAlgorithm", line.getOptionValue('g'));
			optionMap.put("it.unica.diee.mdc.genCAL", line.getOptionValue('x'));
			optionMap.put("it.unica.diee.mdc.calType", line.getOptionValue('y'));
			optionMap.put("it.unica.diee.mdc.genHDL", line.getOptionValue('h'));
			optionMap.put("it.unica.diee.mdc.protocol", line.getOptionValue('l'));
			optionMap.put("it.unica.diee.mdc.protFile", line.getOptionValue('f'));
			optionMap.put("it.unica.diee.mdc.genCopr", line.getOptionValue('t'));
			optionMap.put("it.unica.diee.mdc.coprType", line.getOptionValue('k'));
			optionMap.put("it.unica.diee.mdc.coprEnv", line.getOptionValue('v'));
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
				setOptions(optionMap);
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
			printUsage(context, options, uoe.getLocalizedMessage());
		} catch (ParseException exp) {
			printUsage(context, options, exp.getLocalizedMessage());
		}
		return IApplication.EXIT_RELAUNCH;
	}
	
	/**
	 * Check the current ProgressMonitor for cancellation, and throws a
	 * OperationCanceledException if needed. This will simply stop the back-end
	 * execution.
	 */
	private void stopIfRequested() {
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
		//TODO gestire clk o no in base a power saving selezionato
		//bestNetInstances = merger.getNetworksClkInstances();
		bestNetInstances = merger.getNetworksInstances();
		bestInputMap =  new HashMap<Network,Integer>(netMap);
	}
		
}