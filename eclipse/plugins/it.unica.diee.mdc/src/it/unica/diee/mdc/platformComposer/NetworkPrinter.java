package it.unica.diee.mdc.platformComposer;


import java.util.HashMap;
import java.util.List;
import java.util.Map;

import net.sf.orcc.df.Network;
import net.sf.orcc.util.OrccLogger;
import it.unica.diee.mdc.ConfigManager;
import it.unica.diee.mdc.powerSaving.CpfPrinter;
import it.unica.diee.mdc.powerSaving.PowerController;
import it.unica.diee.mdc.sboxManagement.*;
import net.sf.orcc.df.transform.Instantiator;
import net.sf.orcc.df.transform.NetworkFlattener;

import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.File;
import java.io.InputStream;
import java.io.PrintStream;

import javax.xml.stream.XMLInputFactory;
import javax.xml.stream.XMLStreamException;
import javax.xml.stream.XMLStreamReader;

/**
 * 
 * This class write HDL modules of the multi-dataflow
 * 
 * @author Carlo Sau
 * @see it.unica.diee.mdc.utility package
 */
public class NetworkPrinter extends PlatformComposer {
	
	/**
	 * Protocol signals
	 */
	private Map<String,Map<String,String>> netSysSignals;
	private Map<String,String> modNames;
	private Map<String,Map<String,Map<String,String>>> modSysSignals;
	private Map<String,Map<String,Map<String,String>>> modCommSignals;
	private Map<String,Map<String,Map<String,String>>> modCommParms;
	
	private class ProtocolParser {

		private static final String ACTOR = "actor";
		private static final String PRED = "predecessor";
		private static final String SUCC = "successor";

		private static final String NAME = "name";
		
		private static final String SYS = "sys_signals";
		private static final String PARMS = "comm_parameters";
		private static final String COMM = "comm_signals";

		private static final String SIGNAL = "signal";
		private static final String PARM = "parameter";
		private static final String ID = "id";
		private static final String NETP = "net_port";
		private static final String ACTP = "port";
		private static final String CH = "channel";
		private static final String KIND = "kind";
		private static final String CLOCK = "is_clock";
		private static final String DIR = "dir";
		private static final String BROAD = "broadcast";
		private static final String SIZE = "size";
		private static final String VAL = "value";
		private static final String FILTER = "filter";


		public ProtocolParser(String protocolFile) {

			File inputFile = new File(protocolFile);
			String module = "";
			String elemId = "";
			Map<String,Map<String,String>> moduleMap = null;
			Map<String,String> elemMap = null;
			
			try {
				InputStream inStream = new FileInputStream(inputFile);
				XMLInputFactory xmlFactory = XMLInputFactory.newInstance();
				try {
					XMLStreamReader reader = xmlFactory
							.createXMLStreamReader(inStream);
					while (reader.hasNext()) {
						reader.next();
						if (reader.getEventType() == XMLStreamReader.START_ELEMENT) {
							System.out.println(reader.getLocalName());

							if (reader.getLocalName().equals(SYS)) {
								if(module == "") {
									System.out.println("net assigned");
									module = "net";
								}
							}
							
							if (reader.getLocalName().equals(PRED) ||
									reader.getLocalName().equals(ACTOR) ||
									reader.getLocalName().equals(SUCC)) {
								System.out.println("mod assigned");
								module = reader.getLocalName();
								moduleMap = new HashMap<String,Map<String,String>>();
							}
							
							if (reader.getLocalName().equals(NAME)) {
								if(!module.equals("net")) {
									modNames.put(module, reader.getElementText());
								}
							}
							
							if (reader.getLocalName().equals(SIGNAL)) {
								elemId = reader.getAttributeValue("",ID);
								elemMap = new HashMap<String,String>();
								elemMap.put(SIZE,reader.getAttributeValue("",SIZE));
								if(reader.getAttributeValue("",NETP) != null) {
									elemMap.put(NETP,reader.getAttributeValue("",NETP));
								}
								if(reader.getAttributeValue("",ACTP) != null) {
									elemMap.put(ACTP,reader.getAttributeValue("",ACTP));
								}
								if(reader.getAttributeValue("",CH) != null) {
									elemMap.put(CH,reader.getAttributeValue("",CH));
								}
								if(reader.getAttributeValue("",KIND) != null) {
									elemMap.put(KIND,reader.getAttributeValue("",KIND));
								}
								if(reader.getAttributeValue("",DIR) != null) {
									elemMap.put(DIR,reader.getAttributeValue("",DIR));
								}
								if(reader.getAttributeValue("",CLOCK) != null) {
									elemMap.put(CLOCK,"");
								}

								if(reader.getAttributeValue("",BROAD) != null) {
									elemMap.put(BROAD,reader.getAttributeValue("",BROAD));
								}
								if (reader.getAttributeValue("",FILTER) != null) {
									elemMap.put(FILTER,reader.getAttributeValue("",FILTER));
								}
								
								if(module.equals("net")) {
									netSysSignals.put(elemId, elemMap);
								} else {
									moduleMap.put(elemId,elemMap);
								}
							}
							
							if (reader.getLocalName().equals(PARM)) {
								elemId = reader.getAttributeValue("",ID);
								elemMap = new HashMap<String,String>();
								elemMap.put(NAME,reader.getAttributeValue("",NAME));
								elemMap.put(VAL,reader.getAttributeValue("",VAL));
								moduleMap.put(elemId,elemMap);
							}
							
							if(reader.getLocalName().equals(COMM) || 
									reader.getLocalName().equals(PARMS)) {
								moduleMap = new HashMap<String,Map<String,String>>();
							}
							
						} else if (reader.getEventType() == XMLStreamReader.END_ELEMENT) {
							
							if(reader.getLocalName().equals(PRED) ||
									reader.getLocalName().equals(ACTOR) ||
									reader.getLocalName().equals(SUCC)) {
								System.out.println("mod unassigned");
								module = "";
							}
							
							if(reader.getLocalName().equals(SYS)) {
								if(!module.equals("net")) {
									modSysSignals.put(module, moduleMap);
								}
								moduleMap = null;
							}
							
							if(reader.getLocalName().equals(COMM)) {
								modCommSignals.put(module, moduleMap);
								moduleMap = null;
							}
							
							if(reader.getLocalName().equals(PARMS)) {
								modCommParms.put(module, moduleMap);
								moduleMap = null;
							}
						}

					}

				} catch (XMLStreamException e) {
					e.printStackTrace();
				}

			} catch (FileNotFoundException e) {
				e.printStackTrace();
			}
		}

	}
	
	
	public NetworkPrinter(String outPath, ConfigManager configManager, Network network, String protPath) throws IOException{
		super(outPath,configManager,network);
		
		netSysSignals = new HashMap<String,Map<String,String>>();
		modNames = new HashMap<String,String>();
		modSysSignals = new HashMap<String,Map<String,Map<String,String>>>();
		modCommSignals = new HashMap<String,Map<String,Map<String,String>>>();
		modCommParms = new HashMap<String,Map<String,Map<String,String>>>();
		
		if(!protPath.equals("")){
			new ProtocolParser(protPath);
		}
		
		System.out.println("netSysSignals " + netSysSignals);
		System.out.println("modNames " + modNames);
		System.out.println("modSysSignals " + modSysSignals);
		System.out.println("modCommSignals " + modCommSignals);
		System.out.println("modCommParms " + modCommParms);
	}

	protected boolean printNetwork(List<SboxLut> luts, Map<String,Object> options) 
	{
			
		/////////////////////////////////////////////////////////////
		new Instantiator(true).doSwitch(network);
		new NetworkFlattener().doSwitch(network);
		//new TypeResizer(false, true, false, false).doSwitch(network);
		// Compute the Network Template
		network.computeTemplateMaps();
		/////////////////////////////////////////////////////////////
		
		//if enableClockGating is high, Clock Gating methodology is enabled
		boolean enableClockGating = ((Boolean) options.get("it.unica.diee.mdc.computeLogicRegions"))
				&& (options.get("it.unica.diee.mdc.lrPowerSaving").equals("CLOCK_GATING")
					|| (options.get("it.unica.diee.mdc.lrPowerSaving").equals("HYBRID")) );
		
		//if enablePSO is high, Power Shut Off methodology is enabled
		boolean enablePowerGating = ((Boolean) options.get("it.unica.diee.mdc.computeLogicRegions"))
				&& (options.get("it.unica.diee.mdc.lrPowerSaving").equals("POWER_GATING")
					|| (options.get("it.unica.diee.mdc.lrPowerSaving").equals("HYBRID")) );

		File dir; 
		if((Boolean) options.get("it.unica.diee.mdc.genCopr")) {
			dir = new File(hdlPath);
		} else {
			dir = new File(hdlPath + File.separator + "verilog");
		}
		// If directory doesn't exist, create it
		if (!dir.exists()) {
			dir.mkdirs();
		}
		
		String file = dir.getPath() + File.separator + network.getSimpleName()
		+ ".v";	
		
		NetworkPrinterGeneric printer  = new NetworkPrinterGeneric();
		CharSequence sequence = printer.printNetwork(network,luts,logicRegions,
				enableClockGating,enablePowerGating, 
				netSysSignals,modNames,modSysSignals,modCommSignals,modCommParms,
				logicRegions, netRegions, powerSets, powerSetsIndex, logicRegionsSeqMap);
		logicRegionID = printer.getClockDomainIndex();
		
		try {
			PrintStream ps = new PrintStream(new FileOutputStream(file));
			ps.print(sequence.toString());
			ps.close();
		} catch (FileNotFoundException e) {
			OrccLogger.severeln("File Not Found Exception: " + e.getMessage());
		}
		
		
		if(enablePowerGating){			
			File cpfDir = new File(hdlPath.replace("hdl", "cpf"));
			// If directory doesn't exist, create it
			if (!cpfDir.exists()) {
				cpfDir.mkdirs();
			}
			
			//Generate CPF file
			String CPFfile = cpfDir.getPath() + File.separator + network.getSimpleName() + ".cpf";
			CpfPrinter printCPF = new CpfPrinter();
			CharSequence sequenceCPF = printCPF.printCPF(network, luts, logicRegions, 
					netRegions, logicRegionID, configManager, powerSets, logicRegionsSeqMap);
			//System.out.println("sequenceCPF  " + sequenceCPF);
			
			try {
				PrintStream psCPF = new PrintStream(new FileOutputStream(CPFfile));
				psCPF.print(sequenceCPF.toString());
				psCPF.close();
			} catch (FileNotFoundException e) {
				OrccLogger.severeln("File Not Found Exception: " + e.getMessage());
			  }
			
			
			//Generate Verilog Power Controller which generates all the power logic enables.			
			String PowerControllerFile = dir.getPath() + File.separator + "PowerController" + ".v";
			PowerController printPowerController = new PowerController();
			CharSequence sequencePowerController = printPowerController.printPowerController(network, luts, 
					logicRegions, netRegions, logicRegionID, configManager, powerSets, logicRegionsSeqMap);
			//System.out.println("sequencePowerController  " + sequencePowerController);
			
			try {
				PrintStream psPowerController = new PrintStream(new FileOutputStream(PowerControllerFile));
				psPowerController.print(sequencePowerController.toString());
				psPowerController.close();
			} catch (FileNotFoundException e) {
				OrccLogger.severeln("File Not Found Exception: " + e.getMessage());
			  }	
		}
		
		// Print sbox modules
		if(!luts.isEmpty())
		{
			String sbox1x2File = dir.getPath() + File.separator + "sbox1x2.v";
			String sbox2x1File = dir.getPath() + File.separator + "sbox2x1.v";
			
			SBoxPrinterGeneric sboxPrinter  = new SBoxPrinterGeneric();
			CharSequence sequence1x2 = sboxPrinter.printSbox("1x2",modCommSignals);
			CharSequence sequence2x1 = sboxPrinter.printSbox("2x1",modCommSignals);
			
			try {
				PrintStream ps1x2 = new PrintStream(new FileOutputStream(sbox1x2File));
				ps1x2.print(sequence1x2.toString());
				ps1x2.close();
				PrintStream ps2x1 = new PrintStream(new FileOutputStream(sbox2x1File));
				ps2x1.print(sequence2x1.toString());
				ps2x1.close();
			} catch (FileNotFoundException e) {
				OrccLogger.severeln("File Not Found Exception: " + e.getMessage());
			}
		}
			
		return false;
	
	}
	
}
