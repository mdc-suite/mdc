package it.mdc.tool.core.platformComposer;

import java.util.HashMap;
import java.util.Map;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.File;
import java.io.InputStream;
import javax.xml.stream.XMLInputFactory;
import javax.xml.stream.XMLStreamException;
import javax.xml.stream.XMLStreamReader;

/**
 * 
 * 
 * @author Carlo Sau
 */
public class ProtocolManager {

	public static final String ACTOR = "actor";
	public static final String PRED = "predecessor";
	public static final String SUCC = "successor";
	public static final String WRAP = "wrapper";
	//TODO add broadcast

	public static final String NAME = "name";
	
	public static final String SYS = "sys_signals";
	public static final String PARMS = "comm_parameters";
	public static final String COMM = "comm_signals";

	public static final String SIGNAL = "signal";
	public static final String PARM = "parameter";
	public static final String ID = "id";
	public static final String NETP = "net_port";
	public static final String ACTP = "port";
	public static final String CH = "channel";
	public static final String KIND = "kind";
	public static final String CLOCK = "is_clock";
	public static final String RST = "is_reset";
	public static final String RSTN = "is_resetn";
	public static final String DIR = "dir";
	public static final String BROAD = "broadcast";
	public static final String SIZE = "size";
	public static final String VAL = "value";
	public static final String FILTER = "filter";
	public static final String MAP = "mapping";
	
	/**
	 * Protocol signals
	 */
	
	/**
	 * System signals (reset, clock...)
	 */
	private Map<String,Map<String,String>> netSysSignals;
	
	/**
	 * TODO add description
	 * */
	private Map<String,String> modNames;
	
	/**
	 * TODO add description
	 * */
	private Map<String,Map<String,Map<String,String>>> modSysSignals;
	
	/**
	 * TODO add description
	 * */
	private Map<String,Map<String,Map<String,String>>> modCommSignals;
	
	/**
	 * TODO add description
	 * */
	private Map<String,Map<String,Map<String,String>>> modCommParms;
	
	/**
	 * TODO add description
	 */
	private Map<String,Map<String,String>> wrapCommSignals;
	
/**
 * This class provides methods to parse the input protocol file
 * 
 * @author Carlo Sau
 *
 */
	private void acquireProtocol(String protocolFile) {

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
						
						if (reader.getLocalName().equals(WRAP)) {
							if(module == "") {
								System.out.println("wrap assigned");
								module = "wrap";
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
							if(reader.getAttributeValue("",RST) != null) {
								elemMap.put(RST,"HIGH");
							}
							if(reader.getAttributeValue("",RSTN) != null) {
								elemMap.put(RSTN,"LOW");
							}
							if(reader.getAttributeValue("",MAP) != null) {
								elemMap.put(MAP,reader.getAttributeValue("",MAP));
							}

							if(reader.getAttributeValue("",BROAD) != null) {
								elemMap.put(BROAD,reader.getAttributeValue("",BROAD));
							}
							if (reader.getAttributeValue("",FILTER) != null) {
								elemMap.put(FILTER,reader.getAttributeValue("",FILTER));
							}
							
							if(module.equals("net")) {
								netSysSignals.put(elemId, elemMap);
							} else if(module.equals("wrap")) {
								wrapCommSignals.put(elemId, elemMap);
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
	
	/**
	 * This method initializes the NetworkPrinter Class attributes.
	 * 
	 * @param outPath
	 * 			the output folder path
	 * @param configManager
	 * 			the manager of the network configuration
	 * @param network
	 * 			the multi-dataflow network
	 * @param protPath
	 * 			the protocol file path
	 * @throws IOException
	 */
	public ProtocolManager(String protocolFile) throws IOException{
		
		netSysSignals = new HashMap<String,Map<String,String>>();
		modNames = new HashMap<String,String>();
		modSysSignals = new HashMap<String,Map<String,Map<String,String>>>();
		modCommSignals = new HashMap<String,Map<String,Map<String,String>>>();
		modCommParms = new HashMap<String,Map<String,Map<String,String>>>();
		wrapCommSignals =  new HashMap<String,Map<String,String>>();
		
		acquireProtocol(protocolFile);

		System.out.println("netSysSignals " + netSysSignals);
		System.out.println("modNames " + modNames);
		System.out.println("modSysSignals " + modSysSignals);
		System.out.println("modCommSignals " + modCommSignals);
		System.out.println("modCommParms " + modCommParms);
		System.out.println("wrapCommSignals " + wrapCommSignals);
	}
	
	public Map<String,Map<String,String>> getNetSysSignals() {
		return netSysSignals;
	}
	
	public Map<String,String> getModNames() {
		return modNames;
	}
	
	public Map<String,Map<String,Map<String,String>>> getModSysSignals() {
		return modSysSignals;
	}
	
	public Map<String,Map<String,Map<String,String>>> getModCommSignals() {
		return modCommSignals;
	}
	
	public Map<String,Map<String,Map<String,String>>> getModCommParms() {
		return modCommParms;
	}
	
	public Map<String,Map<String,String>> getWrapCommSignals() {
		return wrapCommSignals;
	}
	
}
