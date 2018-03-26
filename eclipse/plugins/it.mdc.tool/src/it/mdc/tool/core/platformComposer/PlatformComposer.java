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
	 * HDL component library
	 */
	private String hdlCompLib;
	
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
	 * Generate a co-processing layer around the multi-dataflow
	 * network
	 * 
	 * @return
	 * @throws IOException 
	 */
	public void generateCopr(String type, List<SboxLut> luts, Map<String,Map<String,String>> networkVertexMap, String hdlCompLib, String partname, String boardpart) throws IOException {		
		generateCoprVivado(type, luts, networkVertexMap, hdlCompLib, partname, boardpart);
	}
	
	/**
	 * Generate a co-processing for Xilinx Vivado
	 * 
	 * @return
	 * @throws IOException 
	 */
	private void generateCoprVivado(String type, List<SboxLut> luts,
			Map<String, Map<String, String>> networkVertexMap, String hdlCompLib, String partname, String boardpart) {
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
		((WrapperPrinter) wrapperPrinter).initWrapperPrinter(prefix,
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
		/// </ol>
		/////////////////////////
		
		// TODO to be replaced with tcl scripts generation
		// Get libraries
		List<String> libraries = new ArrayList<String>();
		File compFolder = new File(hdlCompLib);
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
		scriptPrinter.initScriptPrinter(partname,
										boardpart,
										prefix,
										libraries);
		
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
		/// <li> IP package  
		/// <ol><li> Generate XML component
		/*file = hdlDir.getPath().replace(File.separator+"hdl", "") + File.separator +  "component.xml";
		sequence = printer.printIpPackage(network,"COMPONENT");
		try {
			PrintStream ps = new PrintStream(new FileOutputStream(file));
			ps.print(sequence.toString());
			ps.close();
		} catch (FileNotFoundException e) {
			OrccLogger.severeln("File Not Found Exception: " + e.getMessage());
		}

		/// <li> Generate GUI tcl
		File guiDir = new File(hdlPath.replace("hdl", "xgui"));
		// If directory doesn't exist, create it
		if (!guiDir.exists()) {
			guiDir.mkdirs();
		}
		
		file = guiDir.getPath() + File.separator + prefix + "_accelerator.tcl";
		sequence = printer.printIpPackage(network,"GUI_TCL");
		try {
			PrintStream ps = new PrintStream(new FileOutputStream(file));
			ps.print(sequence.toString());
			ps.close();
		} catch (FileNotFoundException e) {
			OrccLogger.severeln("File Not Found Exception: " + e.getMessage());
		}
		

		File dataDir = new File(hdlPath.replace("hdl", "drivers") + File.separator + prefix + "_accelerator" + File.separator + "data");
		// If directory doesn't exist, create it
		if (!dataDir.exists()) {
			dataDir.mkdirs();
		}
		
		/// <li> Generate SW MDD
		file = dataDir.getPath() + File.separator +  prefix + "_accelerator.mdd";
		sequence = printer.printIpPackage(network,"SW_MDD");
						
		try {
			PrintStream ps = new PrintStream(new FileOutputStream(file));
			ps.print(sequence.toString());
			ps.close();
		} catch (FileNotFoundException e) {
			OrccLogger.severeln("File Not Found Exception: " + e.getMessage());
		}
		/// </ol>
		// bd>bd.tcl
		// example_designs>...*/
		/////////////////////////
		
		//////////////////////////
		/// <li> SW drivers 
		DriverPrinter driverPrinter = new DriverPrinter();
		driverPrinter.initDriverPrinter(prefix, wrapperPrinter.getPortMap(),
				wrapperPrinter.getInputMap(),wrapperPrinter.getOutputMap());

		File srcDir = new File(hdlPath.replace("hdl", "drivers") + File.separator + "src");
		// If directory doesn't exist, create it
		if (!srcDir.exists()) {
			srcDir.mkdirs();
		}
		
		/// <ol> <li> Generate High Level Driver Header
		file = srcDir.getPath() + File.separator +  prefix + "_accelerator_h.h";
		sequence = driverPrinter.printHighDriverHeader(network,networkVertexMap);
				
		try {
			PrintStream ps = new PrintStream(new FileOutputStream(file));
			ps.print(sequence.toString());
			ps.close();
		} catch (FileNotFoundException e) {
			OrccLogger.severeln("File Not Found Exception: " + e.getMessage());
		}
		
		/// <li> Generate High Level Driver Source
		file = srcDir.getPath() + File.separator +  prefix + "_accelerator_h.c";
		sequence = driverPrinter.printHighDriver(network, networkVertexMap, configManager);
						
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