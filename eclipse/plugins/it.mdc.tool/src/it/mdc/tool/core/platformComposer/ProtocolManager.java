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

import net.sf.orcc.df.Actor;
import net.sf.orcc.df.Connection;
import net.sf.orcc.df.Port;
import net.sf.orcc.util.OrccLogger;

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
	public static final String INV = "invert";
	
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

						if (reader.getLocalName().equals(SYS)) {
							if(module == "") {
								module = "net";
							}
						}
						
						if (reader.getLocalName().equals(WRAP)) {
							if(module == "") {
								module = "wrap";
							}
						}
						
						if (reader.getLocalName().equals(PRED) ||
								reader.getLocalName().equals(ACTOR) ||
								reader.getLocalName().equals(SUCC)) {
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
							if (reader.getAttributeValue("",INV) != null) {
								elemMap.put(INV,reader.getAttributeValue("",INV));
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

	}
	
	/**
	 * TODO add description
	 * 
	 * @param module
	 * @param actor
	 * @param commSigId
	 * @param port
	 * @return
	 */
	public int getCommSigSize(String module, Actor actor, String commSigId, Port port) {
		if (modCommSignals.get(module).get(commSigId).get(SIZE).equals("variable")) {
			return port.getType().getSizeInBits();
		} else if (modCommSignals.get(module).get(commSigId).get(SIZE).equals("broadcast")) {
			if (actor != null) {
			 	if (actor.getOutgoingPortMap().containsKey(port)) {
					if (actor.getOutgoingPortMap().get(port).get(0).hasAttribute("broadcast")) {
						actor.getOutgoingPortMap().get(port).size();
					} else {
						return 1;
					}
				} else {
					return 1;
				}
			} else if (port != null) {
				if(port.getOutgoing().size() != 0) {
					if (((Connection) port.getOutgoing().get(0)).hasAttribute("broadcast")) {
						port.getOutgoing().size();
					} else {
						return 1;
					}
				
				} else {
					return 1;
				}
			} else {
				return 1;
			}
		} else {	
			return Integer.parseInt(modCommSignals.get(module).get(commSigId).get(SIZE));
		}
		return 1;
	} 
	
	/**
	 * 
	 * @return
	 */
	public String getFirstMod(){
		if (modNames.containsKey(PRED)) {
			return PRED;
		} else {
			return ACTOR;	
	 	}
	}
	
	/**
	 * This method returns communication signals of the first module (PRED or ACTOR)
	 * 
	 * @return map of first module communication signals
	 */
	public Map<String,Map<String,String>> getFirstModCommSignals(){
		if(modCommSignals.containsKey(PRED)) {
			return modCommSignals.get(PRED);
		} else {
			return modCommSignals.get(ACTOR);
		}
	}
	
	/**
	 * TODO add description
	 * */
	public Map<String,String> getInFirstModCommSignals(){
		Map<String,String> result = new HashMap<String,String>();
		for(String commSigId : getFirstModCommSignals().keySet()) {
			if( (getFirstModCommSignals().get(commSigId).get(KIND).equals("input") 
					&& getFirstModCommSignals().get(commSigId).get(DIR).equals("direct") )
					|| (getFirstModCommSignals().get(commSigId).get(KIND).equals("output")
					&& getFirstModCommSignals().get(commSigId).get(DIR).equals("reverse") ) ) {
				result.put(commSigId,getFirstModCommSignals().get(commSigId).get(CH));		
			}
		}
		return result;
	} 
	
	/**
	 * 
	 * @return
	 */
	public String getLastMod(){
		if (modNames.containsKey(SUCC)) {
			return SUCC;
		} else {
			return ACTOR;	
	 	}
	}
	
	/**
	 * This method returns communication signals of the last module (SUCC or ACTOR)
	 * 
	 * @return map of last module communication signals
	 */
	public Map<String,Map<String,String>> getLastModCommSignals(){
		if(modCommSignals.containsKey(SUCC)) {
			return modCommSignals.get(SUCC);
		} else {
			return modCommSignals.get(ACTOR);
		}
	}
	
	/**
	 * This method returns mapping signal name of the channel passed as argument
	 * 
	 * @param channel
	 * 				the channel for which corresponding mapping signal name is asked
	 * 
	 * @return name of the mapping signal
	 */
 	public String getMatchingWrapMapping(String channel){
		for(String commSigId : wrapCommSignals.keySet()) {
			if(wrapCommSignals.get(commSigId).containsKey(CH)) {
				if(channel.equals(wrapCommSignals.get(commSigId).get(CH))) {
					return wrapCommSignals.get(commSigId).get(MAP);
				}
			}
		}
		return null;
	}

	/**
	 * 
	 * @param module
	 * @return
	 */
	public String getModName(String module) {
		if (modNames.containsKey(module)) {
			return modNames.get(module) + "_";
		} else {
			return "";
		}
	}
	
	/**
	 * TODO add description
	 * */
	public Map<String,String> getModNames() {
		return modNames;
	}
	
	/**
	 * TODO add description
	 * */
	public Map<String,Map<String,Map<String,String>>> getModCommSignals() {
		return modCommSignals;
	}
	
	/**
	 * TODO add description
	 * */
	public Map<String,Map<String,Map<String,String>>> getModCommParms() {
		return modCommParms;
	}
	
	/**
	 * TODO add description
	 * */
	public Map<String,Map<String,String>> getWrapCommSignals() {
		return wrapCommSignals;
	}
	
	/**
	 * TODO add description
	 * */
	public Map<String,Map<String,Map<String,String>>> getModSysSignals() {
		return modSysSignals;
	}
	
	/**
	 * TODO add description
	 * */
	public Map<String,Map<String,String>> getNetSysSignals() {
		return netSysSignals;
	}
	

	public Map<String,String> getOutLastModCommSignals(){
		Map<String,String> result = new HashMap<String,String>();
		for(String commSigId : getLastModCommSignals().keySet()) {
			if( (getLastModCommSignals().get(commSigId).get(KIND).equals("output") 
					&& getLastModCommSignals().get(commSigId).get(DIR).equals("direct") )
					|| (getLastModCommSignals().get(commSigId).get(KIND).equals("input")
					&& getLastModCommSignals().get(commSigId).get(DIR).equals("reverse") ) ) {
				result.put(commSigId,getLastModCommSignals().get(commSigId).get(CH));	
			}
		}
		return result;
	}
	
	/**
	 * TODO add description
	 * 
	 * @param module
	 * @param commSigId
	 * @param port
	 * @return
	 */
	public String getSigName(String module, String commSigId, Port port) {
		if (!modCommSignals.get(module).get(commSigId).get(CH).equals("")) {
			return port.getLabel() + "_" + modCommSignals.get(module).get(commSigId).get(CH);
		} else {
			return port.getLabel();
		}
	}
	
	/**
	 * 
	 * @param module
	 * @param commSigId
	 * @return
	 */
	public int getSysSigSize(String module, String commSigId) {
		if(module == null) {
			return Integer.parseInt(netSysSignals.get(commSigId).get(SIZE));
		} else {
			return Integer.parseInt(modSysSignals.get(module).get(commSigId).get(SIZE));
		}
	}
	
	/**
	 * TODO add description
	 * */
	public boolean isInputSide(String module, String commSigId) {
		if( (modCommSignals.get(module).get(commSigId).get(KIND).equals("input")
			&& modCommSignals.get(module).get(commSigId).get(DIR).equals("direct"))
			|| (modCommSignals.get(module).get(commSigId).get(KIND).equals("output")
			&& modCommSignals.get(module).get(commSigId).get(DIR).equals("reverse")) ) {
			return true;	
		} else {
			return false;
		}
	}

	/**
	 * TODO add description
	 * */
	public boolean isInputSideDirect(String module, String commSigId) {
		if( (modCommSignals.get(module).get(commSigId).get(KIND).equals("input")
			&& modCommSignals.get(module).get(commSigId).get(DIR).equals("direct")) ) {
			return true;	
		} else {
			return false;
		}
	}
	
	/**
	 * TODO add description
	 * */
	public boolean isInputSideReverse(String module, String commSigId) {
		if( (modCommSignals.get(module).get(commSigId).get(KIND).equals("output")
			&& modCommSignals.get(module).get(commSigId).get(DIR).equals("reverse")) ) {
			return true;	
		} else {
			return false;
		}
	}
	
	/**
	 * This method returns if the matching wrapping signal is discordant or not with the channel passed as argument
	 * 
	 * @param channel
	 * 				the channel for which corresponding mapping signal discordance is asked
	 * @return true if the matching wrapping signal is discordant, false otherwise
	 */
	public boolean isNegMatchingWrapMapping(String channel){
		for(String commSigId : wrapCommSignals.keySet()) {
			if(wrapCommSignals.get(commSigId).containsKey(CH)) {
				if(channel.equals(wrapCommSignals.get(commSigId).get(CH))) {
					return wrapCommSignals.get(commSigId).containsKey(INV);
				}
			}
		}
		return false;
	}
	
	/**
	 * TODO add description
	 * */	
	public boolean isOutputSide(String module, String commSigId) {
		if( (modCommSignals.get(module).get(commSigId).get(KIND).equals("output")
			&& modCommSignals.get(module).get(commSigId).get(DIR).equals("direct"))
			|| (modCommSignals.get(module).get(commSigId).get(KIND).equals("input")
			&& modCommSignals.get(module).get(commSigId).get(DIR).equals("reverse")) ) {
			return true;		
		} else {
			return false;
		}
	}
	
	/**
	 * TODO add description
	 * */	
	public boolean isOutputSideDirect(String module, String commSigId) {
		if( (modCommSignals.get(module).get(commSigId).get(KIND).equals("output")
			&& modCommSignals.get(module).get(commSigId).get(DIR).equals("direct")) ) {
			return true;
		} else {
			return false;
		}
	}
	
	/**
	 * TODO add description
	 * */	
	public boolean isOutputSideReverse(String module, String commSigId) {
		if( (modCommSignals.get(module).get(commSigId).get(KIND).equals("input")
			&& modCommSignals.get(module).get(commSigId).get(DIR).equals("reverse")) ) {
			return true;	
		} else {
			return false;
		}
	}
	
	
	
}
