/*
 *
 */
 
package it.mdc.tool.core.platformComposer;

import java.text.SimpleDateFormat
import java.util.Date
import java.util.HashMap
import java.util.List
import java.util.Map
import net.sf.orcc.df.Actor
import net.sf.orcc.df.Connection
import net.sf.orcc.df.Entity
import net.sf.orcc.df.Network
import net.sf.orcc.df.Port
import net.sf.orcc.graph.Vertex
import java.util.Set
import it.mdc.tool.core.sboxManagement.SboxLut
import net.sf.orcc.ir.util.ExpressionEvaluator
import net.sf.orcc.ir.Var
import java.util.ArrayList
import net.sf.orcc.df.Instance
import net.sf.orcc.ir.Expression
import net.sf.orcc.util.OrccLogger

/**
 * A Verilog FIFO-based Generic Protocol Network printer
 * 
 * printNetwork() is in charge of printing the top module.
 * 
 * @author Carlo Sau
 */
class NetworkPrinterGeneric {
	
	private ExpressionEvaluator evaluator;
	
	private Map<String,Map<String,String>> netSysSignals;
	private Map<String,String> modNames;
	private Map<String,Map<String,Map<String,String>>> modSysSignals;
	private Map<String,Map<String,Map<String,String>>> modCommSignals;
	private Map<String,Map<String,Map<String,String>>> modCommParms;	
	
	private static final String ACTOR = "actor";
	private static final String PRED = "predecessor";
	private static final String SUCC = "successor";

	private static final String NAME = "name";

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
		
	
	var Network network;
	
	var Boolean lastParm = false;
	
	var Boolean enableClockGating;
	
	var Boolean enablePowerGating;
	
	var Map<String,Object> options
	
	var Map<String,Set<String>> logicRegions;
	
	var Map<String,Set<String>> netRegions;
		
	var Set<String> powerSets;
	
	var Map<String,Integer> powerSetsIndex;
	
	var Map<String,Boolean> logicRegionsSeqMap;
	
	
	
	var String DEFAULT_CLOCK_DOMAIN = "CLK";
	/**
	 * Map which contains the Clock Domain of a port
	 */
	var Map<Port, String> portClockDomain;

	/**
	 * Map which contains the Clock Domain of an instance
	 */
	var Map<Actor, String> instanceClockDomain;

	/**
	 * Contains a Map which indicates the number of the broadcasted actor
	 */
	var Map<Connection, Integer> networkPortConnectionFanout;

	/**
	 * Contains a Map which indicates the number of a Network Port broadcasted
	 */
	var Map<Port, Integer> networkPortFanout;

	/**
	 * Contains a Map which indicates the index of the given clock
	 */

	var Map<String, Integer> clockDomainsIndex;
	

	var Map<Connection, List<Integer>> connectionsClockDomain;
	
	/**
	 * Count the fanout of the actor's output port
	 * 
	 * @param network
	 */
	 
	//var Boolean doubleBuffering;
	
	String clockSignal
	
	int idParm = 0;

	def computeActorOutputPortFanout(Network network) {
		for (Vertex vertex : network.getVertices()) {
			if (vertex instanceof Actor) {
				var Actor actor = vertex as Actor;
				var Map<Port, List<Connection>> map = actor.getAdapter((typeof(Entity))).getOutgoingPortMap()
	
				for (List<Connection> values : map.values()) {
					var int cp = 0;
					for (Connection connection : values) {
						networkPortConnectionFanout.put(connection, cp);
						cp = cp + 1;
					}
				}
			}
		}
	}
	
	
	def computeNetworkInputPortFanout(Network network) {
		for (Port port : network.getInputs()) {
			var int cp = 0;
			for (Connection connection : network.getConnections()) {
				if (connection.getSource() == port) {
					networkPortFanout.put(port, cp + 1);
					networkPortConnectionFanout.put(connection, cp);
					cp = cp + 1;
				}
			}
		}
	}
	
	/**
	 * Returns the Map which indicates the index of the given clock
	 */
	def Map<String, Integer> getClockDomainIndex(){ //deve diventare getLogicRegionIndex
		return clockDomainsIndex; //deve diventare logicRegionIndex
	}
	
	/**
	 * Create the map which indicates the index of each clock
	 */	
	def void computeNetworkClockDomains(Network network,
			 Map<String,Set<String>> clockSets) {


		// Fill the the portClockDomain with "CLK" for the I/O of the network
		for (Port port : network.getInputs()) {
			portClockDomain.put(port, DEFAULT_CLOCK_DOMAIN);
		}

		for (Port port : network.getOutputs()) {
			portClockDomain.put(port, DEFAULT_CLOCK_DOMAIN);
		}

		// For each instance on the network give the clock domain specified by
		// the mapping configuration tab or if not give the default clock domain
		var int clkIndex = 0;
		clockDomainsIndex.put(DEFAULT_CLOCK_DOMAIN, clkIndex);
		clkIndex = clkIndex + 1;
		
	//	System.out.println("clockSets.keySet() " + clockSets.keySet());
		
		for (String clkId : clockSets.keySet()) {
		//	System.out.println("clkId " + clkId);
			clockDomainsIndex.put(clkId.toString(), clkIndex);
		//	System.out.println("clkIndex " + clkIndex);
			clkIndex = clkIndex + 1;
		}

		for (Vertex vertex : network.getVertices()) {
			if (vertex instanceof Actor) {
				var Actor actor = vertex as Actor;
				if (!clockSets.isEmpty()) {   //deve diventare logicRegions clockSets deve avere a che fare solo con i domini di CG
					for(String clkId : clockSets.keySet()) { 
						for(String instance : clockSets.get(clkId)){						
							if (instance.equals(actor.getName())) {
								var String domain = clkId.toString();
								instanceClockDomain.put(actor, domain); //Qui ci devono essere solo istanze e domini relativi al CG
								//clockSetsIndex.put(clkId,clkIndex);
							} else if (!instanceClockDomain.containsKey(actor)) {
								instanceClockDomain.put(actor, DEFAULT_CLOCK_DOMAIN);
							}
						}
					}
				} else {
					instanceClockDomain.put(actor, DEFAULT_CLOCK_DOMAIN);//Questa opzione deve essere valida anche per i domini di power
				}
			}
		}
		
		/*if (clockDomainsIndex.size() > 1 && !instanceClockDomain.empty) {
			connectionsClockDomain = new HashMap<Connection, List<Integer>>();
			for (Connection connection : network.getConnections()) {
				if (connection.getSource() instanceof Port) {
					var List<Integer> sourceTarget = new ArrayList<Integer>();
					var int srcIndex = clockDomainsIndex.get(portClockDomain
							.get(connection.getSource()));
					var int tgtIndex = clockDomainsIndex
							.get(instanceClockDomain.get(connection
									.getTarget()));
					if (srcIndex != tgtIndex) {
						sourceTarget.add(0, srcIndex);
						sourceTarget.add(1, tgtIndex);
						connectionsClockDomain
								.put(connection, sourceTarget);
					}
				} else {
					if (connection.getTarget() instanceof Port) {
						var List<Integer> sourceTarget = new ArrayList<Integer>();
						var int srcIndex = clockDomainsIndex
								.get(instanceClockDomain.get(connection
										.getSource()));
						var int tgtIndex = clockDomainsIndex
								.get(portClockDomain.get(connection
										.getTarget()));
						if (srcIndex != tgtIndex) {
							sourceTarget.add(0, srcIndex);
							sourceTarget.add(1, tgtIndex);
							connectionsClockDomain.put(connection,
									sourceTarget);
						}
					} else {
						var List<Integer> sourceTarget = new ArrayList<Integer>();
						var int srcIndex = clockDomainsIndex
								.get(instanceClockDomain.get(connection
										.getSource()));
						var int tgtIndex = clockDomainsIndex
								.get(instanceClockDomain.get(connection
										.getTarget()));
						if (srcIndex != tgtIndex) {
							sourceTarget.add(0, srcIndex);
							sourceTarget.add(1, tgtIndex);
							connectionsClockDomain.put(connection,
									sourceTarget);
						}
					}

				}
			}
		}*/
	}
	

	/**
	 * Print the header of the Verilog file
	 */
	def headerComments(){
		var dateFormat = new SimpleDateFormat("yyyy/MM/dd HH:mm:ss");
		var date = new Date();
		'''
		// ----------------------------------------------------------------------------
		//
		// Multi-Dataflow Composer tool - Platform Composer
		// Multi-Dataflow Network module 
		// Date: «dateFormat.format(date)»
		//
		// ----------------------------------------------------------------------------
		'''	
	}
	
	/**
	 * Print clock domains information
	 */
	def printClockInformation(){
		'''
		// ----------------------------------------------------------------------------
		// Clock Domain(s) Information on the Network "«network.simpleName»"
		//
		// Network input port(s) clock domain:
		
		// Actor(s) clock domains (for clock gating):
		«FOR vertex: network.vertices»
			«IF vertex instanceof Actor»
				«IF !(vertex.getAdapter(typeof(Actor)).hasAttribute("sbox")||vertex.getAdapter(typeof(Actor)).hasAttribute("only_cal"))»
					//	«(vertex as Actor).simpleName» --> «instanceClockDomain.get(vertex as Actor)»
				«ENDIF»
			«ENDIF»
		«ENDFOR»
		// ----------------------------------------------------------------------------
		'''
	}
	
	/**
	 * Print the configurator
	 */
	def printConfig(List<SboxLut> luts) {
		'''
		// Network Configurator
		configurator config_0 (
			.sel(sel),
			.ID(ID)
		);
		'''
	}
	
	/**
	 * Print the logic necessary to manage the clock gating technique: enable generator and clock gating cells
	 */
	def printEnableGenerator() {// Clock Gating Cell «id» id deve essere riferito solo ai domini di clock
	//Si può fare come per i segnali di power 
	//«FOR lr: powerSets»
	//		.iso_en«clockDomainsIndex.get(lr)»(iso_en«clockDomainsIndex.get(lr)»),
	// usando però l'insieme clockSet (che ancora non esiste)
		'''
		// Enable Generator
		enable_generator en_gen_0 (
			«FOR sysSigId : netSysSignals.keySet SEPARATOR ","»
			«IF modSysSignals.get(ACTOR).get(sysSigId).containsKey(CLOCK)»
			.clock_in(«netSysSignals.get(sysSigId).get(NETP)»)«ENDIF»
			«ENDFOR»
			.clocks_en(clocks_en),					
			.ID(ID)
		);
«««		«FOR id : clockDomainIndex.values»
«««		«IF id != 0»
«««		// Clock Gating Cell «id»
«««		clock_gating_cell cgc_«id» (
«««			.ck_gated(ck_gated_«id»),
«««			.en(clocks_en[«id»]),
«««			.clk(«clockSignal»)
«««		);
«««		«ENDIF»
«««		«ENDFOR»
		
		«FOR lr: powerSets» «IF logicRegionsSeqMap.get(lr)»
		// Clock Gating Cell «powerSetsIndex.get(lr)» (switches off LR «clockDomainsIndex.get(lr)»)
		clock_gating_cell cgc_«powerSetsIndex.get(lr)» (
			.ck_gated(ck_gated_«clockDomainsIndex.get(lr)»),
			.en(clocks_en[«powerSetsIndex.get(lr)»]),
			«FOR sysSigId : netSysSignals.keySet»
			«IF modSysSignals.get(ACTOR).get(sysSigId).containsKey(CLOCK)»
			.clk(«netSysSignals.get(sysSigId).get(NETP)»)«ENDIF»
			«ENDFOR»
		);
		«ENDIF»
		«ENDFOR»
		'''
	}
	
	/**
	 * Print the logic necessary to manage the power gating technique: power controller and clock gating cells
	 */
	def printPowerController(){
		'''
		//Power Controller
		PowerController powerController_0(
			// Input Signal(s)
			.ID(ID),
			.reference_count(reference_count),
		
			// Output Signal(s)			
			«FOR lr: powerSets»
			.sw_ack«clockDomainsIndex.get(lr)»(sw_ack«clockDomainsIndex.get(lr)»),
			.status«clockDomainsIndex.get(lr)»(status«clockDomainsIndex.get(lr)»),
			.iso_en«clockDomainsIndex.get(lr)»(iso_en«clockDomainsIndex.get(lr)»),
			«IF logicRegionsSeqMap.get(lr)»
			.rtn_en«clockDomainsIndex.get(lr)»(rtn_en«clockDomainsIndex.get(lr)»),
			.en_cg«clockDomainsIndex.get(lr)»(en_cg«clockDomainsIndex.get(lr)»),
			«ENDIF»
			.pw_switch_en«clockDomainsIndex.get(lr)»(pw_switch_en«clockDomainsIndex.get(lr)»),			
			
			«ENDFOR»
			// System Signal(s)
			«FOR sysSigId : netSysSignals.keySet SEPARATOR ","»
			«IF modSysSignals.get(ACTOR).get(sysSigId).containsKey(CLOCK)»
			.clk(«netSysSignals.get(sysSigId).get(NETP)»)«ELSE»
			««« TODO: necessary to bring inside the info about the reset activity (low or high)
			.rst(!«netSysSignals.get(sysSigId).get(NETP)»)«ENDIF»
			«ENDFOR»
		);
		
		
		/*fake_switches are inserted for behavioural and post synthesis simulation 
		and verification (when real switches have not been insterted yet.
		Remove these fake switches before synthesis and implementation!
		*/
		«FOR lr: powerSets»
		fake_switch fake_sw_«clockDomainsIndex.get(lr)» (
			.nsleep_in(pw_switch_en«clockDomainsIndex.get(lr)»),
			.nsleep_out(sw_ack«clockDomainsIndex.get(lr)»),
			// System Signal(s)
			«FOR sysSigId : netSysSignals.keySet SEPARATOR ","»
			«IF modSysSignals.get(ACTOR).get(sysSigId).containsKey(CLOCK)»
			.aclk(«netSysSignals.get(sysSigId).get(NETP)»)«ELSE»
			.aresetn(«netSysSignals.get(sysSigId).get(NETP)»)«ENDIF»
			«ENDFOR»
				);
		«ENDFOR»
		
		
		«FOR lr: powerSets» «IF logicRegionsSeqMap.get(lr)»
		// Clock Gating Cell «clockDomainsIndex.get(lr)»
		clock_gating_cell cgc_«clockDomainsIndex.get(lr)» (
			.ck_gated(ck_gated_«clockDomainsIndex.get(lr)»),
			.en(en_cg«clockDomainsIndex.get(lr)»),
			«FOR sysSigId : netSysSignals.keySet»
			«IF modSysSignals.get(ACTOR).get(sysSigId).containsKey(CLOCK)»
			.clk(«netSysSignals.get(sysSigId).get(NETP)»)«ENDIF»
			«ENDFOR»
		);
		«ENDIF»
		«ENDFOR»
		'''
	}
	
	/**
	 * return the list of combinatorial ports (does not associate a "valid" signal to the port signals)
	 */
	def computeCombPorts(List<Port> ports) {
		var combInputs = new ArrayList<Port>();
		for(Port input : ports) {
			if(input.isNative()) {
				combInputs.add(input);
			}
		}
		return combInputs;
	}
	
	/**
	 * return the list of sequential ports (associates a "valid" signal to the port signals)
	 */	
	def computeSeqPorts(List<Port> ports) {
		var combInputs = new ArrayList<Port>();
		for(Port input : ports) {
			if(!input.isNative()) {
				combInputs.add(input);
			}
		}
		return combInputs;
	}
	
	/**
	 * TODO \todo add description
	 */
	def printParm(Var parm, int size) {
		
		var String result = "";

		result = "." + parm.name + "(" + (evaluator.evaluateAsInteger(parm.initialValue)) + ")";
		
		if(idParm == size-1) {
			idParm = 0; 
			lastParm = true;
		} else {
			idParm = idParm + 1;
		}
		if(!lastParm) {
			result = result + ","
		} else {
			lastParm = false;
			idParm = 0;
		}
		return result;
		
	}

	/**
	 * For each connection,
	 * if the connection has already been printed, remove
	 * the "printed" attribute from its source port or vertex.
	 * 
	 * TODO \todo to check. There is a similar function in PlatformComposer.removeAllPrintFlags()
	 * Do we need both?
	 */	
	def removeAllPrintFlags() {
		
		for(Connection connection : network.getConnections())
			if(connection.sourcePort == null) {
				if(connection.source.hasAttribute("printed")) {
					connection.source.removeAttribute("printed");	
				}
			} else {
				if(connection.sourcePort.hasAttribute("printed")) {
					connection.sourcePort.removeAttribute("printed");	
				}
			}	
	}	
	
	/**
	 * Return the simple name of an actor.
	 */
	def getActorName(Actor actor) {
		
		var String[] splitName = actor.getName().split("_");
		var String result = "";
		
		result = splitName.get(0);
		
		if(splitName.size > 2)
			for(int i : 1 .. splitName.size-2) {
				result = result + "_" + splitName.get(i);
			}
		
		return result;		
	}
	
	/**
	 * return the simple name of a SBox
	 */
	def getSboxActorName(Actor actor) {
		
		var String result;
		
		if(actor.getAttribute("type").getStringValue().equals("1x2")) {
			/*if(actor.getInput("in1").getType().isBool()) {
				result = "Sbox1x2bool";
			} else if(actor.getInput("in1").getType().isInt()) {
				result = "Sbox1x2int";
			} else if(actor.getInput("in1").getType().isFloat()) {
				result = "Sbox1x2float";
			} else {
				result = "Sbox1x2";
			}*/
			result = "sbox1x2";
		} else {
			/*if(actor.getInput("in1").getType().isBool()) {
				result = "Sbox2x1bool";
			} else if(actor.getInput("in1").getType().isInt()) {
				result = "Sbox2x1int";
			} else if(actor.getInput("in1").getType().isFloat()) {
				result = "Sbox2x1float";
			} else {
				result = "Sbox2x1";
			}*/ 
			result = "sbox2x1";
		}
		
		return result;
	}
	
	
	
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////	
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////	
	
	def String getModName(String module) {
		if (modNames.containsKey(module)) {
			return modNames.get(module) + "_"
		} else {
			return ""
		}
	}
	
	def int getCommSigSize(String module, Actor actor, String commSigId, Port port) {
		if (modCommSignals.get(module).get(commSigId).get(SIZE).equals("variable")) {
			return port.type.sizeInBits
		} else if (modCommSignals.get(module).get(commSigId).get(SIZE).equals("broadcast")) {
			if (actor != null) {
			 	if (actor.outgoingPortMap.containsKey(port)) {
					if (actor.outgoingPortMap.get(port).get(0).hasAttribute("broadcast")) {
						actor.outgoingPortMap.get(port).size
					} else {
						1
					}
				} else {
					1
				}
			} else if (port != null) {
				if(port.outgoing.size != 0) {
					if ((port.outgoing.get(0) as Connection).hasAttribute("broadcast")) {
						port.outgoing.size
					} else {
						1
					}
				
				} else {
					1
				}
			} else {
				1
			}
		} else {	
			return Integer.parseInt(modCommSignals.get(module).get(commSigId).get(SIZE))
		}
	}
	
	def int getSysSigSize(String module, String commSigId) {
		if(module == null) {
			return Integer.parseInt(netSysSignals.get(commSigId).get(SIZE))
		} else {
			return Integer.parseInt(modSysSignals.get(module).get(commSigId).get(SIZE))
		}
	}
	
	def String getSigName(String module, String commSigId, Port port) {
		if (!modCommSignals.get(module).get(commSigId).get(CH).equals("")) {
			return port.label + "_" + modCommSignals.get(module).get(commSigId).get(CH)
		} else {
			return port.label
		}
	}
	
	def String getSysSigDimension(String module, String sysSigId) {
		if (getSysSigSize(module,sysSigId) != 1) {
			return "[" + (getSysSigSize(module,sysSigId)-1) + " : 0] " 
		} else {
			return ""
		}
	}
	
	def String getCommSigDimension(String module, Actor actor, String commSigId, Port port) {
		if (getCommSigSize(module,actor,commSigId,port) != 1) {
			return "[" + (getCommSigSize(module,actor,commSigId,port)-1) + " : 0] " 
		} else {
			return ""
		}
	}
	
	def boolean isInputSide(String module, String commSigId) {
		if( (modCommSignals.get(module).get(commSigId).get(KIND).equals("input")
			&& modCommSignals.get(module).get(commSigId).get(DIR).equals("direct"))
			|| (modCommSignals.get(module).get(commSigId).get(KIND).equals("output")
			&& modCommSignals.get(module).get(commSigId).get(DIR).equals("reverse")) ) {
			return true		
		} else {
			return false
		}
	}
	
	def boolean isOutputSide(String module, String commSigId) {
		if( (modCommSignals.get(module).get(commSigId).get(KIND).equals("output")
			&& modCommSignals.get(module).get(commSigId).get(DIR).equals("direct"))
			|| (modCommSignals.get(module).get(commSigId).get(KIND).equals("input")
			&& modCommSignals.get(module).get(commSigId).get(DIR).equals("reverse")) ) {
			return true		
		} else {
			return false
		}
	}
	
	/**
	 * Print top module interface.
	 */
	def printInterface(List<SboxLut> luts) {
		
		var String pred;
		var String succ;
		if (modNames.containsKey(PRED)) {
			pred = PRED;
		} else {
			pred = ACTOR;	
	 	}
		if (modNames.containsKey(SUCC)) {
			succ = SUCC;
		} else {
			succ = ACTOR;	
	 	}
	 	
		'''
		module multi_dataflow (
			«FOR input : network.inputs»
			«FOR commSigId : modCommSignals.get(pred).keySet»
			«IF isInputSide(pred,commSigId)»
			«modCommSignals.get(pred).get(commSigId).get(KIND)» «getCommSigDimension(pred,null,commSigId,input)»«getSigName(pred,commSigId,input)»,
			«ENDIF»
			«ENDFOR»
			
			«ENDFOR»
			«FOR output : network.outputs»
			«FOR commSigId : modCommSignals.get(succ).keySet»
			«IF isOutputSide(succ,commSigId)»
			«modCommSignals.get(succ).get(commSigId).get(KIND)»  «getCommSigDimension(succ,null,commSigId,output)»«getSigName(succ,commSigId,output)»,
			«ENDIF»
			«ENDFOR»
			«ENDFOR»	
			
			«IF !luts.empty»
			input [7:0] ID,
			«ENDIF»
			«IF enablePowerGating»
			input [17:0] reference_count, //to set the time necessary for be sure power is off or on
			
			«FOR lr: powerSets»
			output	status«clockDomainsIndex.get(lr)»,
			«ENDFOR»
			«ENDIF»			
					
			«FOR sysSigId : netSysSignals.keySet SEPARATOR ","»
			«netSysSignals.get(sysSigId).get(KIND)» «getSysSigDimension(null,sysSigId)»«netSysSignals.get(sysSigId).get(NETP)»
			«ENDFOR»
		);	
		'''
	}	
	
	/**
	 * print top module internal signals
	 */
	def printInternalSignals(List<SboxLut> luts) {
		
		var String pred;
		var String succ;
		if (modNames.containsKey(PRED)) {
			pred = PRED;
		} else {
			pred = ACTOR;	
	 	}
		if (modNames.containsKey(SUCC)) {
			succ = SUCC;
		} else {
			succ = ACTOR;	
	 	}
		
		'''	
		«IF !luts.empty»
		// Sboxes Config Wire(s)
		wire [«luts.size - 1» : 0] sel;
		«ENDIF»
				
		«IF enableClockGating»
		// Enable Generator Wire(s)
		wire [«powerSetsIndex.size - 1» : 0] clocks_en;
		«ENDIF»
		
		«IF enablePowerGating»
		//Power controller Wires
		wire [17:0] reference_count;
		
		«FOR lr: powerSets»
		wire	sw_ack«clockDomainsIndex.get(lr)»;
		wire	status«clockDomainsIndex.get(lr)»;
		wire	iso_en«clockDomainsIndex.get(lr)»;
		«IF logicRegionsSeqMap.get(lr)»
		wire	rtn_en«clockDomainsIndex.get(lr)»;
		wire	en_cg«clockDomainsIndex.get(lr)»;
		«ENDIF»
		wire	pw_switch_en«clockDomainsIndex.get(lr)»;
		«ENDFOR»
		«ENDIF»
		
		// Actors Wire(s)
		«FOR actor : network.getChildren().filter(typeof(Actor))»
			
		// actor «actor.simpleName»
		«IF !actor.hasAttribute("sbox")»
			«FOR input : actor.inputs»
			«IF modNames.containsKey(PRED)»
			«FOR commSigId : modCommSignals.get(PRED).keySet»
			«IF isInputSide(PRED,commSigId)»
			wire «getCommSigDimension(PRED,actor,commSigId,input)»«getModName(PRED)»«actor.label»_«getSigName(PRED,commSigId,input)»;
			«ENDIF»
			«ENDFOR»
			«ENDIF»
			«FOR commSigId : modCommSignals.get(ACTOR).keySet»
			«IF isInputSide(ACTOR,commSigId)»
			wire «getCommSigDimension(ACTOR,actor,commSigId,input)»«getModName(ACTOR)»«actor.label»_«getSigName(ACTOR,commSigId,input)»;
			«ENDIF»
			«ENDFOR»
			«ENDFOR»
			«FOR output : actor.outputs»
			«FOR commSigId : modCommSignals.get(ACTOR).keySet»
			«IF isOutputSide(ACTOR,commSigId)»
			wire «getCommSigDimension(ACTOR,actor,commSigId,output)»«getModName(ACTOR)»«actor.label»_«getSigName(ACTOR,commSigId,output)»;
			«ENDIF»
			«ENDFOR»
			«IF modNames.containsKey(SUCC)»
			«FOR commSigId : modCommSignals.get(SUCC).keySet»
			«IF isOutputSide(SUCC,commSigId)»
			wire «getCommSigDimension(SUCC,actor,commSigId,output)»«getModName(SUCC)»«actor.label»_«getSigName(SUCC,commSigId,output)»;
			«ENDIF»
			«ENDFOR»
			«ENDIF»
			«ENDFOR»
		«ELSE»
«««			«FOR input : actor.inputs»
«««			«FOR commSigId : modCommSignals.get(ACTOR).keySet»
«««			«IF isInputSide(ACTOR,commSigId) && !input.label.equals("sel")»
«««			// wire «getCommSigDimension(ACTOR,actor,commSigId,input)»«getModName(ACTOR)»«actor.label»_«getSigName(ACTOR,commSigId,input)»;
«««			«ENDIF»
«««			«ENDFOR»
«««			«ENDFOR»
«««			«FOR output : actor.outputs»
«««			«FOR commSigId : modCommSignals.get(ACTOR).keySet»
«««			«IF isOutputSide(ACTOR,commSigId)»
«««			// wire «getCommSigDimension(ACTOR,actor,commSigId,output)»«getModName(ACTOR)»«actor.label»_«getSigName(ACTOR,commSigId,output)»;
«««			«ENDIF»
«««			«ENDFOR»
«««			«ENDFOR»
			«FOR input : actor.inputs»
			«FOR commSigId : modCommSignals.get(pred).keySet»
			«IF isInputSide(pred,commSigId) && !input.label.equals("sel")»
			 wire «getCommSigDimension(ACTOR,actor,commSigId,input)»«getModName(ACTOR)»«actor.label»_«getSigName(pred,commSigId,input)»;
			«ENDIF»
			«ENDFOR»
			«ENDFOR»
			«FOR output : actor.outputs»
			«FOR commSigId : modCommSignals.get(ACTOR).keySet»
			«IF isOutputSide(succ,commSigId)»
			 wire «getCommSigDimension(ACTOR,actor,commSigId,output)»«getModName(ACTOR)»«actor.label»_«getSigName(succ,commSigId,output)»;
			«ENDIF»
			«ENDFOR»
			«ENDFOR»
			«ENDIF»	
		«ENDFOR»
		'''
	}
		
	def Integer getBufferSizeIntegerValue(Connection connection) {
		if(connection.hasAttribute("bufferSize")) {
			if(connection.getAttribute("bufferSize").getContainedValue() != null) {
				evaluator.evaluateAsInteger(connection.getAttribute("bufferSize").getContainedValue() as Expression);
			} else { 
				if (connection.getAttribute("bufferSize").getReferencedValue() != null) {
					return evaluator.evaluateAsInteger(connection.getAttribute("bufferSize").getReferencedValue() as Expression);
				} else {
			//		OrccLogger.debugln("CCC " + connection + "   " + connection.getAttributes());
					return evaluator.evaluateAsInteger(connection.getAttribute("bufferSize").getObjectValue() as Expression);
				}
			}
		} else {
			return null;
		}
	}
	
	
	def String getParameterValue(String module, Actor actor, Port port, String commParId) {
		if (modCommParms.get(module).get(commParId).get(VAL).equals("variable")) {
			port.type.sizeInBits.toString
		} else if (modCommParms.get(module).get(commParId).get(VAL).equals("bufferSize")) {
			if (actor.incomingPortMap.containsKey(port)) {
				if( actor.incomingPortMap.get(port).hasAttribute("bufferSize") ) {
					(getBufferSizeIntegerValue(actor.incomingPortMap.get(port))).toString
				} else {
					//TODO return default value
				//	OrccLogger.traceln("default buffersize");
					"64"
				}
			} else if (actor.outgoingPortMap.containsKey(port)) {
				if(actor.outgoingPortMap.get(port).get(0).hasAttribute("bufferSize")) {
					(getBufferSizeIntegerValue(actor.outgoingPortMap.get(port).get(0))).toString
				} else {
					//TODO return default value
			//		OrccLogger.traceln("default buffersize");
					"64"
				}
			}
		} else if (modCommParms.get(module).get(commParId).get(VAL).equals("broadcast")) {
			if (actor.outgoingPortMap.get(port).get(0).hasAttribute("broadcast")) {
				actor.outgoingPortMap.get(port).size.toString
			} else {
				"1"
			}
		} else{
			modCommParms.get(module).get(commParId).get(VAL)
		}
	}
	
	def String getActorPortSignal(String commSigId, Port port) {
		if(modCommSignals.get(ACTOR).get(commSigId).get(ACTP).equals("")) {
			port.label	
		} else {
			port.label + "_" + modCommSignals.get(ACTOR).get(commSigId).get(ACTP)
		}
	}
	
	def String getChannelSuffix(String module, String commSigId) {
		if(modCommSignals.get(module).get(commSigId).get(CH).equals("")) {
			""
		} else {
			"_" + modCommSignals.get(module).get(commSigId).get(CH)
		}
	}
	
	/**
	 * Print actors instantiation in top module.
	 */	
	def printActors(Map<String,Set<String>> clockSets) {
		
		var String pred;
		var String succ;
		if (modNames.containsKey(PRED)) {
			pred = PRED;
		} else {
			pred = ACTOR;	
	 	}
		if (modNames.containsKey(SUCC)) {
			succ = SUCC;
		} else {
			succ = ACTOR;	
	 	}
	 	
		// WARNING: qui serve un controllo in più, dopo le modifiche instanceClockDomain avrà solo attori relativi a domini di CG, quindi quel get.(actor) potrebbe essere null
		// TODO a seconda delle modifiche che verranno fatte durante CERBERO il parametri potrebbero dover essere manipolati in maniera differente
		'''
		«FOR actor : network.getChildren().filter(typeof(Actor))»
		«IF !actor.hasAttribute("sbox")»
		«IF modNames.containsKey(PRED)»
		«FOR input : actor.inputs»
		// «modNames.get(PRED)»_«actor.simpleName»_«input.label»
		«modNames.get(PRED)» «IF modCommParms.containsKey(PRED)»#(
		«FOR commParId : modCommParms.get(PRED).keySet SEPARATOR ","»	.«modCommParms.get(PRED).get(commParId).get(NAME)»(«getParameterValue(PRED,actor,input,commParId)»)
		«ENDFOR»
		) «ENDIF»«modNames.get(PRED)»_«actor.simpleName»_«input.label»(
			«FOR commSigId : modCommSignals.get(PRED).keySet»
			«IF isInputSide(PRED,commSigId)».«modCommSignals.get(PRED).get(commSigId).get(ACTP)»(«getModName(PRED)»«actor.label»_«getSigName(PRED,commSigId,input)»),«ENDIF»
			«IF isOutputSide(PRED,commSigId)».«modCommSignals.get(PRED).get(commSigId).get(ACTP)»(«getModName(ACTOR)»«actor.label»_«getSigName(ACTOR,commSigId,input)»),«ENDIF»
			«ENDFOR»
			
			// System Signal(s)
			«FOR sysSigId : modSysSignals.get(PRED).keySet SEPARATOR ","»
			«IF modSysSignals.get(PRED).get(sysSigId).containsKey(CLOCK) && (enableClockGating || enablePowerGating)»
			.«modSysSignals.get(PRED).get(sysSigId).get(ACTP)»(«IF powerSets.contains(instanceClockDomain.get(actor))»«clockSignal»ck_gated_«clockDomainsIndex.get(instanceClockDomain.get(actor))»«ELSE»«modSysSignals.get(PRED).get(sysSigId).get(NETP)»«ENDIF»)
 			«ELSE»
			.«modSysSignals.get(PRED).get(sysSigId).get(ACTP)»(«modSysSignals.get(PRED).get(sysSigId).get(NETP)»)
			«ENDIF»
			«ENDFOR»
		);
		«ENDFOR»
		«ENDIF»
		
		// actor «actor.simpleName»
		«getActorName(actor)» «IF !actor.parameters.empty»#(
			// Parameter(s)
		«FOR parm : actor.parameters»	«printParm(parm,actor.parameters.size)»
		«ENDFOR»
		)
		«ENDIF»
		actor_«actor.simpleName» (
			// Input Signal(s)
			«FOR input : actor.inputs SEPARATOR ","»«FOR commSigId : getActorInputCommSignals(actor) SEPARATOR ","»
			.«getActorPortSignal(commSigId,input)»(«getModName(ACTOR)»«actor.label»_«getSigName(ACTOR,commSigId,input)»)
			«ENDFOR»
			«ENDFOR»
			«IF !getActorOutputCommSignals(actor).empty»,«ENDIF»
			
			// Output Signal(s)
			«FOR output : actor.outputs SEPARATOR ","»«FOR commSigId : getActorOutputCommSignals(actor) SEPARATOR ","»
			.«getActorPortSignal(commSigId,output)»(«getModName(ACTOR)»«actor.label»_«getSigName(ACTOR,commSigId,output)»)
			«ENDFOR»
			«ENDFOR»
			«IF !getActorSysSignals(actor).empty»,«ENDIF»
			
			// System Signal(s)
			«FOR sysSigId : getActorSysSignals(actor) SEPARATOR ","»	
			«IF modSysSignals.get(ACTOR).get(sysSigId).containsKey(CLOCK) && (enableClockGating || enablePowerGating)»
«««			«IF modSysSignals.get(ACTOR).get(sysSigId).get(ACTP).equals(CLOCK) && (enableClockGating || enablePowerGating)»
			.«modSysSignals.get(ACTOR).get(sysSigId).get(ACTP)»(«IF powerSets.contains(instanceClockDomain.get(actor))»«clockSignal»ck_gated_«clockDomainsIndex.get(instanceClockDomain.get(actor))»«ELSE»«modSysSignals.get(ACTOR).get(sysSigId).get(NETP)»«ENDIF»)
			«ELSE»
			.«modSysSignals.get(ACTOR).get(sysSigId).get(ACTP)»(«modSysSignals.get(ACTOR).get(sysSigId).get(NETP)»)
			«ENDIF»
			«ENDFOR»
		);
		
		«ELSE»		
		
		// actor «actor.simpleName»
		«getSboxActorName(actor)» #(
			.SIZE(«actor.getInput("in1").getType.getSizeInBits»)
		)
		«actor.simpleName» (
			// Input Signal(s)
			«FOR input : actor.inputs»
			«FOR commSigId : modCommSignals.get(pred).keySet»
			«««todo put actp instead of ch
			«IF isInputSide(pred,commSigId) && !input.label.equals("sel")».«input.label»«getChannelSuffix(pred,commSigId)»(«actor.label»_«getSigName(pred,commSigId,input)»),«ENDIF»
			«ENDFOR»
			«ENDFOR»
			
			// Output Signal(s)
			«FOR output : actor.outputs»
			«FOR commSigId : modCommSignals.get(succ).keySet»
			«««todo put actp instead of ch
			«IF isOutputSide(succ,commSigId)».«output.label»«getChannelSuffix(succ,commSigId)»(«actor.label»_«getSigName(succ,commSigId,output)»),«ENDIF»
			«ENDFOR»
			«ENDFOR»
			
			// Selector
			.sel(sel[«actor.simpleName.split("_").get(1)»])	
		);
		«ENDIF»	
		
		«IF !actor.hasAttribute("sbox")»
		«IF modNames.containsKey(SUCC)»
		«FOR output : actor.outputs»
		// «modNames.get(SUCC)»_«actor.simpleName»_«output.label»
		«modNames.get(SUCC)»  «IF modCommParms.containsKey(PRED)»#(
		«FOR commParId : modCommParms.get(SUCC).keySet SEPARATOR ","»	.«modCommParms.get(SUCC).get(commParId).get(NAME)»(«getParameterValue(SUCC,actor,output,commParId)»)
		«ENDFOR»
		) «ENDIF»«modNames.get(SUCC)»_«actor.simpleName»_«output.label»(
			«FOR commSigId : modCommSignals.get(SUCC).keySet»
			«IF isInputSide(SUCC,commSigId)».«modCommSignals.get(SUCC).get(commSigId).get(ACTP)»(«getModName(ACTOR)»«actor.label»_«getSigName(ACTOR,commSigId,output)»),«ENDIF»
			«IF isOutputSide(SUCC,commSigId)».«modCommSignals.get(SUCC).get(commSigId).get(ACTP)»(«getModName(SUCC)»«actor.label»_«getSigName(SUCC,commSigId,output)»),«ENDIF»
			«ENDFOR»
			
			// System Signal(s)
			«FOR sysSigId : modSysSignals.get(SUCC).keySet SEPARATOR ","»
			«IF modSysSignals.get(SUCC).get(sysSigId).containsKey(CLOCK) && (enableClockGating || enablePowerGating)»
			.«modSysSignals.get(SUCC).get(sysSigId).get(ACTP)»(«IF powerSets.contains(instanceClockDomain.get(actor))»«clockSignal»ck_gated_«clockDomainsIndex.get(instanceClockDomain.get(actor))»«ELSE»«modSysSignals.get(SUCC).get(sysSigId).get(NETP)»«ENDIF»)
			«ELSE»
			.«modSysSignals.get(SUCC).get(sysSigId).get(ACTP)»(«modSysSignals.get(SUCC).get(sysSigId).get(NETP)»)
			«ENDIF»
			«ENDFOR»
		);
		«ENDFOR»
		«ENDIF»
		«ENDIF»
		«ENDFOR»
		'''
	}
	
	def List<String> getActorSysSignals(Actor actor) {
		var List<String> actorSysSignalsId = new ArrayList<String>();
		for(String sysSigId : modSysSignals.get(ACTOR).keySet) {
			if(modSysSignals.get(ACTOR).get(sysSigId).containsKey(FILTER)) {
				if(actor.hasAttribute(modSysSignals.get(ACTOR).get(sysSigId).get(FILTER))) {
					actorSysSignalsId.add(sysSigId);
				}
			} else {
				actorSysSignalsId.add(sysSigId);
			}
		}
		return actorSysSignalsId
	}

	def List<String> getActorCommSignals(Actor actor) {
		var List<String> actorCommSignalsId = new ArrayList<String>();
		for(String commSigId : modCommSignals.get(ACTOR).keySet) {
			if(modCommSignals.get(ACTOR).get(commSigId).containsKey(FILTER)) {
				if(actor.hasAttribute(modCommSignals.get(ACTOR).get(commSigId).get(FILTER))) {
					actorCommSignalsId.add(commSigId);
				}
			} else {
				actorCommSignalsId.add(commSigId);
			}
		}
		return actorCommSignalsId
	}
	
	
	def List<String> getActorInputCommSignals(Actor actor) {
		var List<String> actorInputCommSignalsId = new ArrayList<String>();
		for(String commSigId : getActorCommSignals(actor)) {
			if(isInputSide(ACTOR,commSigId)) {
				actorInputCommSignalsId.add(commSigId);
			}
		}
		return actorInputCommSignalsId
	}
	
	def List<String> getActorOutputCommSignals(Actor actor) {
		var List<String> actorOutputCommSignalsId = new ArrayList<String>();
		for(String commSigId : getActorCommSignals(actor)) {
			if(isOutputSide(ACTOR,commSigId)) {
				actorOutputCommSignalsId.add(commSigId);
			}
		}
		return actorOutputCommSignalsId
	}
	
	def String getTargetSignal(Connection connection, String pred, String commSigId) {
		
		var String prefix = ""
		if (connection.target instanceof Actor) {
			if(!(connection.target as Actor).hasAttribute("sbox")) {
				if(getModName(pred) != "") {
					prefix = getModName(pred)
				}	
			}
		}
		
		var String suffix = "";
		if(!modCommSignals.get(pred).get(commSigId).get(CH).equals("")) {
			suffix = "_" + modCommSignals.get(pred).get(commSigId).get(CH);	
		}
		
		if (connection.targetPort == null) {
			
			return prefix + connection.target.label + suffix
		} else {
			return prefix + connection.target.label + "_" + connection.targetPort.label + suffix
		}
	}
	
	def String getSourceSignal(Connection connection, String succ, String targetChannel) {
		
		var String prefix = ""
		var String suffix = ""
		
		if (connection.source instanceof Actor) {
			if(!(connection.source as Actor).hasAttribute("sbox")) {
				if(getModName(succ) != "") {
					prefix = getModName(succ)
				}	
			}
		}
		
		if (connection.hasAttribute("broadcast")) {
			for (commSigId : modCommSignals.get(succ).keySet) {
				if ( modCommSignals.get(succ).get(commSigId).get(CH).equals(targetChannel) ) {
					if ( modCommSignals.get(succ).get(commSigId).get(SIZE).equals("broadcast") ) {
						if (connection.sourcePort == null) {
							suffix = "[" + (connection.source as Port).outgoing.indexOf(connection) + "]"
						} else {
							suffix = "[" + (connection.source as Actor).outgoingPortMap.get(connection.sourcePort).indexOf(connection) + "]"
						}
						
					}
				}	
			}
		}
		
		
		
		if (connection.sourcePort == null) {
			for (commSigId : modCommSignals.get(succ).keySet) {
				var String suffix2 = "";
				if(!modCommSignals.get(succ).get(commSigId).get(CH).equals("")) {
					suffix2 = "_" + modCommSignals.get(succ).get(commSigId).get(CH);	
				}
				if ( modCommSignals.get(succ).get(commSigId).get(CH).equals(targetChannel) ) {
					return prefix + connection.source.label + suffix2 + suffix
				}
			}
		} else {
			for (commSigId : modCommSignals.get(succ).keySet) {
				var String suffix2 = "";
				if(!modCommSignals.get(succ).get(commSigId).get(CH).equals("")) {
					suffix2 = "_" + modCommSignals.get(succ).get(commSigId).get(CH);	
				}
				if ( modCommSignals.get(succ).get(commSigId).get(CH).equals(targetChannel) ) {
					return prefix + connection.source.label + "_" + connection.sourcePort.label + suffix2 + suffix
				}
			}
		}
	}

	/**
	 * print assignments to connect instances.
	 */
	def printAssignments() {
		
		removeAllPrintFlags();
		var String pred;
		var String succ;
		if (modNames.containsKey(PRED)) {
			pred = PRED;
		} else {
			pred = ACTOR;	
	 	}
		if (modNames.containsKey(SUCC)) {
			succ = SUCC;
		} else {
			succ = ACTOR;	
	 	}
		
		'''
		// Module(s) Assignments
		«FOR connection : network.connections»
		«FOR commSigId : modCommSignals.get(pred).keySet»
		«IF isInputSide(pred,commSigId)»
		«IF modCommSignals.get(pred).get(commSigId).get(KIND).equals("input")»
		assign «getTargetSignal(connection,pred,commSigId)» = «getSourceSignal(connection,succ,modCommSignals.get(pred).get(commSigId).get(CH))»;
		«ELSE»
		«IF connection.hasAttribute("broadcast")»
		assign «getSourceSignal(connection,succ,modCommSignals.get(pred).get(commSigId).get(CH))» =
		«IF connection.source instanceof Actor»
		«FOR broadConn : (connection.source as Actor).outgoingPortMap.get(connection.sourcePort) SEPARATOR " ||"»
		«getTargetSignal(broadConn,pred,commSigId)» 
		«ENDFOR»
		«ELSE»
		«FOR broadConn : (connection.source as Port).outgoing SEPARATOR " ||"»
		«getTargetSignal(broadConn as Connection,pred,commSigId)» 
		«ENDFOR»
		«ENDIF»;
		«ELSE»
		assign «getSourceSignal(connection,succ,modCommSignals.get(pred).get(commSigId).get(CH))» = «getTargetSignal(connection,pred,commSigId)»;
		«ENDIF»
		«ENDIF»
		«ENDIF»
		«ENDFOR»
		
		«ENDFOR»
		'''
	}
	
	
	/**
	 * return the SBox size
	 */
	def String getSboxSize(Actor actor) {
		return String.valueOf(actor.getInputs().get(0).getType().getSizeInBits());
	}
	
	/**
	 * return the SBox type (1x2 or 2x1)
	 */
	def String getSboxType(Actor actor) {
		return actor.getAttribute("type").getStringValue();
	}
	
	/**
	 * return the selector ID for the given SBox
	 */
	def String getSboxSelID(Actor actor) {
		return (actor.getSimpleName().split("_")).get(1);
	}
	
	/**
	 * Print the top module of the merged network.
	 * 
	 * <ul>
	 * <li> headerComments()
	 * <li> printInterface()
	 * <li> printInternalSignals()
	 * <li> printConfig()
	 * <li> printAssignments()
	 * </ul> 
	 * According with user options, also the following can be run.
	 * <ul>
	 * <li> printActors()
	 * <li> printEnableGenerator()
	 * <li> printPowerController()
	 * 
	 * </ul>
	 */
	def printNetwork(Network network, List<SboxLut> luts,
		 Map<String,Set<String>> clockSets, 
		 boolean enableClockGating,
		 boolean enablePowerGating,
		 Map<String,Map<String,String>> netSysSignals,
		 Map<String,String> modNames,
		 Map<String,Map<String,Map<String,String>>> modSysSignals,
		 Map<String,Map<String,Map<String,String>>> modCommSignals,
		 Map<String,Map<String,Map<String,String>>> modCommParms,
		 Map<String,Set<String>> logicRegions,
		 Map<String,Set<String>> netRegions,
		 Set<String> powerSets,
		 Map<String,Integer> powerSetsIndex,
		 Map<String,Boolean> logicRegionsSeqMap){
		 	
		 
		this.evaluator = new ExpressionEvaluator();
		 	
		this.netSysSignals = netSysSignals;
		this.modNames = modNames;
		this.modSysSignals = modSysSignals;
		this.modCommSignals = modCommSignals;
		this.modCommParms = modCommParms;

		this.clockSignal = clockSignal;
		
		// Initialize members
		this.network = network; 
		this.options = new HashMap<String,Object>();
		this.enableClockGating = enableClockGating;
		this.enablePowerGating = enablePowerGating;
		this.logicRegions = logicRegions;
		this.powerSets = powerSets;
		this.netRegions = netRegions;
		this.powerSetsIndex = powerSetsIndex;
		this.logicRegionsSeqMap = logicRegionsSeqMap;
		
		// ignorare
		networkPortFanout = new HashMap<Port, Integer>();
		networkPortConnectionFanout = new HashMap<Connection, Integer>();		
		portClockDomain = new HashMap<Port, String>();
		instanceClockDomain = new HashMap<Actor, String>();
		clockDomainsIndex = new HashMap<String, Integer>();
		connectionsClockDomain = new HashMap<Connection,List<Integer>>();
		
		computeNetworkClockDomains(network,clockSets);
		
		'''
		«headerComments()»
«««		«printClockInformation()»

		«printInterface(luts)»
		
		// internal signals
		// ----------------------------------------------------------------------------
		«printInternalSignals(luts)»
		// ----------------------------------------------------------------------------
		
		// body
		// ----------------------------------------------------------------------------
		«IF !luts.empty»
		«printConfig(luts)»
		«ENDIF»			
		
		«IF enableClockGating»
		«printEnableGenerator()»
		«ENDIF»
		
		«IF enablePowerGating»
		«printPowerController()»
		«ENDIF»
		
		«printActors(clockSets)»
		«printAssignments()»
		endmodule
		'''
	}
	
}
