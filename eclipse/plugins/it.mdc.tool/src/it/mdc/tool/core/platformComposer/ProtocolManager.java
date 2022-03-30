package it.mdc.tool.core.platformComposer;

import java.util.ArrayList;
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
 * This class provides methods to manage the protocol file
 * 
 * @author Carlo Sau
 */
public class ProtocolManager {
	
	/**
	 * Protocol labels
	 */
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
	public static final String TAG = "tag_size";

	/**
	 * System signals of the whole network
	 */
	private Map<String,Map<String,String>> netSysSignals;
	
	/**
	 * Name of the modules (predecessor, successor)
	 */
	private Map<String,String> modNames;
	
	/**
	 * System signals of the modules (actor, predecessor, successor)
	 */
	private Map<String,Map<String,Map<String,String>>> modSysSignals;
	
	/**
	 * Communication signals of the modules (actor, predecessor, successor)
	 */
	private Map<String,Map<String,Map<String,String>>> modCommSignals;
	
	/**
	 * Communication parameters of the modules (actor, predecessor, successor)
	 */
	private Map<String,Map<String,Map<String,String>>> modCommParms;
	
	/**
	 * Communication signals of the wrapper
	 */
	private Map<String,Map<String,String>> wrapCommSignals;
	
	/**
	 * Acquire the protocol file and initialize attributes accordingly
	 * 
	 * @param protocolFile
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
							if(reader.getAttributeValue("",TAG) != null) {
								elemMap.put(TAG,reader.getAttributeValue("",TAG));
							} else {
								elemMap.put(TAG,"0");	/* if not specified tag_size is 0 */
							}							
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
	 * Initializer of the ProtocolManager (maps instantiation and initialization)
	 * 
	 * @param protocolFile
	 * 			the protocol file to be used to initialize the object
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
	 * Return signal to be printed for the given communication signal and actor port
	 * 
	 * @param commSigId
	 * 		communication signal ID
	 * @param port
	 * 		involved port
	 * @return
	 * 		signal to be printed for the given communication signal and actor port
	 */
	public String getActorPortPrintSignal(String commSigId, Port port) {
		if(modCommSignals.get(ACTOR).get(commSigId).get(ACTP).equals("")) {
			return port.getLabel();	
		} else {
			return port.getLabel() + "_" + modCommSignals.get(ACTOR).get(commSigId).get(ACTP);
		}
	}
	
	/**
	 * Return a list of all actor system signals
	 * 
	 * @param actor
	 * 		involved actor
	 * @return
	 * 		list of all actor system signals
	 */
	public ArrayList<String> getActorSysSignals(Actor actor) {
		ArrayList<String> actorSysSignalsId = new ArrayList<String>();
		for(String sysSigId : modSysSignals.get(ACTOR).keySet()) {
			if(modSysSignals.get(ACTOR).get(sysSigId).containsKey(FILTER)) {
				if(actor.hasAttribute(modSysSignals.get(ACTOR).get(sysSigId).get(FILTER))) {
					actorSysSignalsId.add(sysSigId);
				}
			} else {
				actorSysSignalsId.add(sysSigId);
			}
		}
		return actorSysSignalsId;
	}
	
	/**
	 * Return a list of all actor communication signals
	 * 
	 * @param actor
	 * 		involved actor
	 * @return
	 * 		list of all actor communication signals
	 */
	public ArrayList<String> getActorCommSignals(Actor actor) {
		ArrayList<String> actorCommSignalsId = new ArrayList<String>();
		for(String commSigId : modCommSignals.get(ACTOR).keySet()) {
			if(modCommSignals.get(ACTOR).get(commSigId).containsKey(FILTER)) {
				if(actor.hasAttribute(modCommSignals.get(ACTOR).get(commSigId).get(FILTER))) {
					actorCommSignalsId.add(commSigId);
				}
			} else {
				actorCommSignalsId.add(commSigId);
			}
		}
		return actorCommSignalsId;
	}
	
	/**
	 * Return a list of actor input communication signals
	 * 
	 * @param actor
	 * 		involved actor
	 * @return
	 * 		list of actor input communication signals
	 */
	public ArrayList<String> getActorInputCommSignals(Actor actor) {
		ArrayList<String> actorInputCommSignalsId = new ArrayList<String>();
		for(String commSigId : getActorCommSignals(actor)) {
			if(isInputSide(ACTOR,commSigId)) {
				actorInputCommSignalsId.add(commSigId);
			}
		}
		return actorInputCommSignalsId;
	}
	
	/**
	 * Return a list of actor output communication signals
	 * 
	 * @param actor
	 * 		involved actor
	 * @return
	 * 		list of actor output communication signals
	 */
	public ArrayList<String> getActorOutputCommSignals(Actor actor) {
		ArrayList<String> actorOutputCommSignalsId = new ArrayList<String>();
		for(String commSigId : getActorCommSignals(actor)) {
			if(isOutputSide(ACTOR,commSigId)) {
				actorOutputCommSignalsId.add(commSigId);
			}
		}
		return actorOutputCommSignalsId;
	}
	
	/**
	 * Return channel suffix to be printed for the given communication signal and module
	 * 
	 * @param module
	 * 		involved module
	 * @param commSigId
	 * 		communication signal ID
	 * @return
	 * 		channel suffix to be printed for the given communication signal and module
	 */
	public String getChannelPrintSuffix(String module, String commSigId) {
		if(modCommSignals.get(module).get(commSigId).get(CH).equals("")) {
			return "";
		} else {
			return "_" + modCommSignals.get(module).get(commSigId).get(CH);
		}
	}
	
	/**
	 * Return clock system signals
	 * 
	 * @return
	 * 			list of clock sistem signals
	 */
	public ArrayList<String> getClockSysSignals(){
		ArrayList<String> result = new ArrayList<String>();
		for(String sysSigId : netSysSignals.keySet()) {
			if(netSysSignals.get(sysSigId).containsKey(ProtocolManager.CLOCK)) {
				result.add(netSysSignals.get(sysSigId).get(ProtocolManager.NETP));
			}
		}
		return result;
	}
	
	/**
	 * Return the data size of the communication signal
	 * 
	 * @param module 
	 * 			involved module label (actor, predecessor, successor)
	 * @param actor
	 * 			involved actor  
	 * @param commSigId
	 * 			communication signal ID
	 * @param port
	 * 			involved port
	 * @return
	 * 			data size of the communication signal
	 */
	public int getCommSigDataSize(String module, Actor actor, String commSigId, Port port) {
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
	 * Return the tag size of the communication signal
	 * 
	 * @param module 
	 * 			involved module label (actor, predecessor, successor)
	 * @param actor
	 * 			involved actor  
	 * @param commSigId
	 * 			communication signal ID
	 * @param port
	 * 			involved port
	 * @return
	 * 			tag size of the communication signal
	 */
	public int getCommSigTagSize(String module, String commSigId) {
		return Integer.parseInt(modCommSignals.get(module).get(commSigId).get(TAG));
	}	
	
	/**
	 * Return the size (tag + data) of the communication signal
	 * 
	 * @param module 
	 * 			involved module label (actor, predecessor, successor)
	 * @param actor
	 * 			involved actor  
	 * @param commSigId
	 * 			communication signal ID
	 * @param port
	 * 			involved port
	 * @return
	 * 			size (tag + data) of the communication signal
	 */	
	public int getCommSigSize(String module, Actor actor, String commSigId, Port port) {
		return getCommSigTagSize(module,commSigId) + getCommSigDataSize(module,actor,commSigId,port);
	}
	
	/**
	 * Return range of the communication signal to be printed for the module, actor and port
	 * 
	 * @param module
	 * 				involved module
	 * @param actor
	 * 				involved actor
	 * @param commSigId
	 * 				communication signal ID
	 * @param port
	 * 				involved port
	 * @return
	 * 				range of the communication signal to be printed 
	 */
	public String getCommSigPrintRange(String module, Actor actor, String commSigId, Port port) {
		if (getCommSigSize(module,actor,commSigId,port) != 1) {
			return "[" + (getCommSigSize(module,actor,commSigId,port)-1) + " : 0] ";
		} else {
			return "";
		}
	}
	
	/**
	 * Return size in bits of the given port data channel
	 * 
	 * @param port
	 * 				involved port
	 * @return
	 * 				size in bit of the port data channel
	 */
	public int getDataSize(Port port) {
		for(String commSigId : wrapCommSignals.keySet()) {
			if(wrapCommSignals.get(commSigId).get(ProtocolManager.MAP).equals("data")) {
				if(wrapCommSignals.get(commSigId).get(ProtocolManager.SIZE).equals("variable")) {
					return port.getType().getSizeInBits();
				} else {
					return Integer.parseInt(wrapCommSignals.get(commSigId).get(ProtocolManager.SIZE));
				}
			}
		}
		return 1;
	}
	
	/**
	 * Return first module in the protocol chain (predecessor, if any, or actor)
	 * 
	 * @return
	 * 			first module label
	 */
	public String getFirstMod(){
		if (modNames.containsKey(PRED)) {
			return PRED;
		} else {
			return ACTOR;	
	 	}
	}
	
	/**
	 * Return communication signals of the first module in the protocol chain
	 * 
	 * @return 
	 * 			map of the first module communication signals
	 */
	public Map<String,Map<String,String>> getFirstModCommSignals(){
		if(modCommSignals.containsKey(PRED)) {
			return modCommSignals.get(PRED);
		} else {
			return modCommSignals.get(ACTOR);
		}
	}
	
	/**
	 * Return all inputs within communication signals of the first module in the protocol chain
	 * 
	 * @return
	 * 			map of the first module communication input signals
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
	 * Return ID of the wrapper full channel
	 * 
	 * @return
	 * 			full channel ID
	 */
	public String getFullChannelWrapCommSignalID() {
		for(String commSigId : wrapCommSignals.keySet()) {
			if(wrapCommSignals.get(commSigId).get(ProtocolManager.MAP).equals("full")) {
				return wrapCommSignals.get(commSigId).get(ProtocolManager.CH);
			}		
		}
		return null;
	}
	
	/**
	 * Return last module in the protocol chain (successor, if any, or actor)
	 * 
	 * @return
	 * 			last module label
	 */
	public String getLastMod(){
		if (modNames.containsKey(SUCC)) {
			return SUCC;
		} else {
			return ACTOR;	
	 	}
	}
	
	/**
	 * Return communication signals of the last module in the protocol chain
	 * 
	 * @return 
	 * 			map of the last module communication signals
	 */
	public Map<String,Map<String,String>> getLastModCommSignals(){
		if(modCommSignals.containsKey(SUCC)) {
			return modCommSignals.get(SUCC);
		} else {
			return modCommSignals.get(ACTOR);
		}
	}
	
	/**
	 * Returns wrapper mapping signal of the channel passed as argument
	 * 
	 * @param channel
	 * 				involved channel
	 * 
	 * @return 
	 * 				wrapper mapping signal
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
	 * Return the name of the passed module (predecessor, successor)
	 * 
	 * @param module
	 * 				involved module
	 * @return
	 * 				name of the involved module, if any
	 */
	public String getModName(String module) {
		if (modNames.containsKey(module)) {
			return modNames.get(module) + "_";
		} else {
			return "";
		}
	}
	
	/**
	 * Return names of the modules in the protocol chain
	 * 
	 * @return
	 * 			map of names of the modules
	 */
	public Map<String,String> getModNames() {
		return modNames;
	}
	
	/**
	 * Return the modules communication signals
	 * 
	 * @return
	 * 			map of the modules communication signals
	 */
	public Map<String,Map<String,Map<String,String>>> getModCommSignals() {
		return modCommSignals;
	}
	
	/**
	 * Return the modules communication parameters
	 * 
	 * @return
	 * 			map of the modules communication parameters
	 */
	public Map<String,Map<String,Map<String,String>>> getModCommParms() {
		return modCommParms;
	}
	
	/**
	 * Return the wrapper communication signals
	 * 
	 * @return
	 * 			map of the wrapper communication signals
	 */
	public Map<String,Map<String,String>> getWrapCommSignals() {
		return wrapCommSignals;
	}
	
	/**
	 * Return the module system signals
	 * 
	 * @return
	 * 			map of the module system signals
	 */
	public Map<String,Map<String,Map<String,String>>> getModSysSignals() {
		return modSysSignals;
	}
	
	/**
	 * Return the network system signals
	 * 
	 * @return
	 * 			map of the network system signals
	 */
	public Map<String,Map<String,String>> getNetSysSignals() {
		return netSysSignals;
	}
	
	/**
	 * Return all outputs within communication signals of the last module in the protocol chain
	 * 
	 * @return
	 * 			map of the last module communication output signals
	 * */
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
	 * Return reset system signals
	 * 
	 * @return
	 * 			map of reset system signals
	 */
	public Map<String,String> getResetSysSignals(){
		HashMap<String,String> result = new HashMap<String,String>();
		for(String sysSigId : netSysSignals.keySet()) {
			if(netSysSignals.get(sysSigId).containsKey(ProtocolManager.RST)) {
				result.put(netSysSignals.get(sysSigId).get(ProtocolManager.NETP),"HIGH");
			} else if(netSysSignals.get(sysSigId).containsKey(ProtocolManager.RSTN)) {
				result.put(netSysSignals.get(sysSigId).get(ProtocolManager.NETP),"LOW");
			}
		}
		return result;
	}
	
	/**
	 * Return whole signal name to be printed (port name + communication signal name)
	 * 
	 * @param module
	 * 				involved module
	 * @param commSigId
	 * 				communication signal ID
	 * @param port
	 * 				involved port
	 * @return
	 * 				signal name to be printed
	 */
	public String getSigPrintName(String module, String commSigId, Port port) {
		if (!modCommSignals.get(module).get(commSigId).get(CH).equals("")) {
			return port.getLabel() + "_" + modCommSignals.get(module).get(commSigId).get(CH);
		} else {
			return port.getLabel();
		}
	}
	
	/**
	 * Return range of the system signal to be printed for the module
	 * 
	 * @param module
	 * 				involved module
	 * @param sysSigId
	 * 				system signal ID
	 * @return
	 * 				range of the system signal to be printed 
	 */
	public String getSysSigPrintRange(String module, String sysSigId) {
		if (getSysSigSize(module,sysSigId) != 1) {
			return "[" + (getSysSigSize(module,sysSigId)-1) + " : 0] "; 
		} else {
			return "";
		}
	}
	
	/**
	 * Return the size of the system signal
	 * 
	 * @param module 
	 * 				involved module label (network, actor, predecessor, successor)  
	 * @param sysSigId
	 * 				system signal ID
	 * @return
	 * 				size of the system signal
	 */
	public int getSysSigSize(String module, String sysSigId) {
		if(module == null) {
			return Integer.parseInt(netSysSignals.get(sysSigId).get(SIZE));
		} else {
			return Integer.parseInt(modSysSignals.get(module).get(sysSigId).get(SIZE));
		}
	}
	
	/**
	 * Return the target signal for the given communication signal, connection and predecessor
	 * 
	 * @param connection
	 * 				involved connection
	 * @param pred
	 * 				predecessor
	 * @param commSigId
	 * 				communication signal ID
	 * @return
	 * 				target signal
	 */
	public String getTargetSignal(Connection connection, String pred, String commSigId) {
		
		String prefix = "";
		if (connection.getTarget() instanceof Actor) {
			if(!(connection.getTarget().getAdapter(Actor.class)).hasAttribute("sbox")) {
				if(getModName(pred) != "") {
					prefix = getModName(pred);
				}	
			}
		}

		String suffix = "";
		if(!modCommSignals.get(pred).get(commSigId).get(ProtocolManager.CH).equals("")) {
			suffix = "_" + modCommSignals.get(pred).get(commSigId).get(ProtocolManager.CH);	
		}
		
		if (connection.getTargetPort() == null) {
			
			return prefix + connection.getTarget().getLabel() + suffix;
		} else {
			return prefix + connection.getTarget().getLabel() + "_" + connection.getTargetPort().getLabel() + suffix;
		}	
	}

	/**
	 * Return true if the communication signal is an input
	 * 
	 * @param module
	 * 				involved module label (actor, predecessor, successor)
	 * @param commSigId
	 * 				communication signal ID
	 * @return
	 * 				true if the signal is an input, false otherwise
	 */
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
	 * Return true if the communication signal is an input of the input protocol interface
	 * 
	 * @param module
	 * 				involved module label (actor, predecessor, successor)
	 * @param commSigId
	 * 				communication signal ID
	 * @return
	 * 				true if the signal is an input of the input protocol interface, false otherwise
	 */
	public boolean isInputSideDirect(String module, String commSigId) {
		if( (modCommSignals.get(module).get(commSigId).get(KIND).equals("input")
			&& modCommSignals.get(module).get(commSigId).get(DIR).equals("direct")) ) {
			return true;	
		} else {
			return false;
		}
	}
	
	/**
	 * Return true if the communication signal is an input of the output protocol interface
	 * 
	 * @param module
	 * 				involved module label (actor, predecessor, successor)
	 * @param commSigId
	 * 				communication signal ID
	 * @return
	 * 				true if the signal is an input of the output protocol interface, false otherwise
	 */
	public boolean isInputSideReverse(String module, String commSigId) {
		if( (modCommSignals.get(module).get(commSigId).get(KIND).equals("output")
			&& modCommSignals.get(module).get(commSigId).get(DIR).equals("reverse")) ) {
			return true;	
		} else {
			return false;
		}
	}
	
	/**
	 * Return true if the wrapper mapping signal is negated with respect to a channel
	 * 
	 * @param channel
	 * 				involved channel
	 * @return 
	 * 				true if the wrapper mapping signal is negated with respect to the channel, false otherwise
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
	 * Return true if the communication signal is an output
	 * 
	 * @param module
	 * 				involved module label (actor, predecessor, successor)
	 * @param commSigId
	 * 				communication signal ID
	 * @return
	 * 				true if the signal is an output, false otherwise
	 */
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
	 * Return true if the communication signal is an output of the output protocol interface
	 * 
	 * @param module
	 * 				involved module label (actor, predecessor, successor)
	 * @param commSigId
	 * 				communication signal ID
	 * @return
	 * 				true if the signal is an output of the output protocol interface, false otherwise
	 */
	public boolean isOutputSideDirect(String module, String commSigId) {
		if( (modCommSignals.get(module).get(commSigId).get(KIND).equals("output")
			&& modCommSignals.get(module).get(commSigId).get(DIR).equals("direct")) ) {
			return true;
		} else {
			return false;
		}
	}
	
	/**
	 * Return true if the communication signal is an output of the input protocol interface
	 * 
	 * @param module
	 * 				involved module label (actor, predecessor, successor)
	 * @param commSigId
	 * 				communication signal ID
	 * @return
	 * 				true if the signal is an output of the input protocol interface, false otherwise
	 */	
	public boolean isOutputSideReverse(String module, String commSigId) {
		if( (modCommSignals.get(module).get(commSigId).get(KIND).equals("input")
			&& modCommSignals.get(module).get(commSigId).get(DIR).equals("reverse")) ) {
			return true;	
		} else {
			return false;
		}
	}
	
	
	
}
