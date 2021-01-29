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
	
	var ExpressionEvaluator evaluator;
	
	var Network network;
	
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
	

	
	var ProtocolManager protocolManager;
	
	/**********************************************************/
	var Boolean lastParm = false;
	
	var Boolean enableClockGating;
	
	var Boolean enablePowerGating;
	
	var Map<String,Object> options
	
	var Map<String,Set<String>> logicRegions;
	
	var Map<String,Set<String>> netRegions;
	
	var Set<String> powerSets;
	
	var Map<String,Integer> powerSetsIndex;
	
	var Map<String,Boolean> logicRegionsSeqMap;
	
	var Map<Connection, List<Integer>> connectionsClockDomain;
	
	var String DEFAULT_CLOCK_DOMAIN = "CLK";
	/**********************************************************/
	
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
		
	/**
	 * return the list of combinatorial ports (does not associate a "valid" signal to the port signals)
	 */
	/*def computeCombPorts(List<Port> ports) {
		var combInputs = new ArrayList<Port>();
		for(Port input : ports) {
			if(input.isNative()) {
				combInputs.add(input);
			}
		}
		return combInputs;
	}*/
	
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
				
		for (String clkId : clockSets.keySet()) {
			clockDomainsIndex.put(clkId.toString(), clkIndex);
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
	 * return the list of sequential ports (associates a "valid" signal to the port signals)
	 */	
	/*def computeSeqPorts(List<Port> ports) {
		var combInputs = new ArrayList<Port>();
		for(Port input : ports) {
			if(!input.isNative()) {
				combInputs.add(input);
			}
		}
		return combInputs;
	}*/
		
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
	 * TODO
	 */
	def List<Var> getActorStaticParms(Actor actor) {
		var List<Var> result = new ArrayList<Var>;
		for(actVar : actor.parameters) {
			if (getMatchingVariable(actVar) !== null) {
				result.add(actVar)
			}
		}
		for(actVar : actor.parameters) {
			if (getMatchingVariable(actVar) === null && getMatchingParameter(actVar) === null) {
				result.add(actVar)
			}
		}
		return result
	}
	
	/**
	 * TODO
	 */
	def List<Var> getActorDynamicParms(Actor actor) {
		var List<Var> result = new ArrayList<Var>;
		for(actVar : actor.parameters) {
			if (getMatchingParameter(actVar) !== null) {
				result.add(actVar)
			}
		}
		return result
	}
	
	def Integer getBufferSizeIntegerValue(Connection connection) {
		if(connection.hasAttribute("bufferSize")) {
			if(connection.getAttribute("bufferSize").getContainedValue() !== null) {
				evaluator.evaluateAsInteger(connection.getAttribute("bufferSize").getContainedValue() as Expression);
			} else { 
				if (connection.getAttribute("bufferSize").getReferencedValue() !== null) {
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
	
	/**
	 * Returns the Map which indicates the index of the given clock
	 */
	def Map<String, Integer> getClockDomainIndex(){ //deve diventare getLogicRegionIndex
		return clockDomainsIndex; //deve diventare logicRegionIndex
	}
	
	/**
	 * TODO
	 */
	def Var getMatchingParameter(Var actVar) {
		for(Var netVar : network.parameters) {
			if(actVar.name.equals(netVar.name))
				return netVar
		}
		return null
	}
	
	/**
	 * TODO
	 */
	def Var getMatchingVariable(Var actVar) {
		for(Var netVar : network.variables) {
			if(actVar.name.equals(netVar.name))
				return netVar
		}
		return null
	}
	
	def String getParameterValue(String module, Actor actor, Port port, String commParId) {
		if (protocolManager.modCommParms.get(module).get(commParId).get(ProtocolManager.VAL).equals("variable")) {
			port.type.sizeInBits.toString
		} else if (protocolManager.modCommParms.get(module).get(commParId).get(ProtocolManager.VAL).equals("bufferSize")) {
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
		} else if (protocolManager.modCommParms.get(module).get(commParId).get(ProtocolManager.VAL).equals("broadcast")) {
			if (actor.outgoingPortMap.get(port).get(0).hasAttribute("broadcast")) {
				actor.outgoingPortMap.get(port).size.toString
			} else {
				"1"
			}
		} else{
			protocolManager.modCommParms.get(module).get(commParId).get(ProtocolManager.VAL)
		}
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
	
	/**
	 * return the selector ID for the given SBox
	 */
	def String getSboxSelID(Actor actor) {
		return (actor.getSimpleName().split("_")).get(1);
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
	
	def String getSourceSignal(Connection connection, String succ, String targetChannel) {
		
		var String prefix = ""
		var String suffix = ""
		
		if (connection.source instanceof Actor) {
			if(!(connection.source as Actor).hasAttribute("sbox")) {
				if(protocolManager.getModName(succ) != "") {
					prefix = protocolManager.getModName(succ)
				}	
			}
		}
		
		if (connection.hasAttribute("broadcast")) {
			for (commSigId : protocolManager.modCommSignals.get(succ).keySet) {
				if ( protocolManager.modCommSignals.get(succ).get(commSigId).get(ProtocolManager.CH).equals(targetChannel) ) {
					if ( protocolManager.modCommSignals.get(succ).get(commSigId).get(ProtocolManager.SIZE).equals("broadcast") ) {
						if (connection.sourcePort === null) {
							suffix = "[" + (connection.source as Port).outgoing.indexOf(connection) + "]"
						} else {
							suffix = "[" + (connection.source as Actor).outgoingPortMap.get(connection.sourcePort).indexOf(connection) + "]"
						}
						
					}
				}	
			}
		}
		
		
		
		if (connection.sourcePort === null) {
			for (commSigId : protocolManager.modCommSignals.get(succ).keySet) {
				var String suffix2 = "";
				if(!protocolManager.modCommSignals.get(succ).get(commSigId).get(ProtocolManager.CH).equals("")) {
					suffix2 = "_" + protocolManager.modCommSignals.get(succ).get(commSigId).get(ProtocolManager.CH);	
				}
				if ( protocolManager.modCommSignals.get(succ).get(commSigId).get(ProtocolManager.CH).equals(targetChannel) ) {
					return prefix + connection.source.label + suffix2 + suffix
				}
			}
		} else {
			for (commSigId : protocolManager.modCommSignals.get(succ).keySet) {
				var String suffix2 = "";
				if(!protocolManager.modCommSignals.get(succ).get(commSigId).get(ProtocolManager.CH).equals("")) {
					suffix2 = "_" + protocolManager.modCommSignals.get(succ).get(commSigId).get(ProtocolManager.CH);	
				}
				if ( protocolManager.modCommSignals.get(succ).get(commSigId).get(ProtocolManager.CH).equals(targetChannel) ) {
					return prefix + connection.source.label + "_" + connection.sourcePort.label + suffix2 + suffix
				}
			}
		}
	}
	
	def String getTargetSignal(Connection connection, String pred, String commSigId) {
		
		var String prefix = ""
		if (connection.target instanceof Actor) {
			if(!(connection.target as Actor).hasAttribute("sbox")) {
				if(protocolManager.getModName(pred) != "") {
					prefix = protocolManager.getModName(pred)
				}	
			}
		}
		
		var String suffix = "";
		if(!protocolManager.modCommSignals.get(pred).get(commSigId).get(ProtocolManager.CH).equals("")) {
			suffix = "_" + protocolManager.modCommSignals.get(pred).get(commSigId).get(ProtocolManager.CH);	
		}
		
		if (connection.targetPort === null) {
			
			return prefix + connection.target.label + suffix
		} else {
			return prefix + connection.target.label + "_" + connection.targetPort.label + suffix
		}
	}	
	
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////	
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////	
	
	
	
	/**
	 * Print actors instantiation in top module.
	 */	
	def printActors(Map<String,Set<String>> clockSets) {
	 	
		// WARNING: qui serve un controllo in più, dopo le modifiche instanceClockDomain avrà solo attori relativi a domini di CG, quindi quel get.(actor) potrebbe essere null
		// TODO a seconda delle modifiche che verranno fatte durante CERBERO il parametri potrebbero dover essere manipolati in maniera differente
		'''
		«FOR actor : network.getChildren().filter(typeof(Actor))»
		«IF !actor.hasAttribute("sbox")»
		«IF protocolManager.modNames.containsKey(ProtocolManager.PRED)»
		«FOR input : actor.inputs»
		// «protocolManager.modNames.get(ProtocolManager.PRED)»_«actor.simpleName»_«input.label»
		«protocolManager.modNames.get(ProtocolManager.PRED)» «IF protocolManager.modCommParms.containsKey(ProtocolManager.PRED)»#(
		«FOR commParId : protocolManager.modCommParms.get(ProtocolManager.PRED).keySet SEPARATOR ","»	.«protocolManager.modCommParms.get(ProtocolManager.PRED).get(commParId).get(ProtocolManager.NAME)»(«getParameterValue(ProtocolManager.PRED,actor,input,commParId)»)
		«ENDFOR»
		) «ENDIF»«protocolManager.modNames.get(ProtocolManager.PRED)»_«actor.simpleName»_«input.label»(
			«FOR commSigId : protocolManager.modCommSignals.get(ProtocolManager.PRED).keySet»
			«IF protocolManager.isInputSide(ProtocolManager.PRED,commSigId)».«protocolManager.modCommSignals.get(ProtocolManager.PRED).get(commSigId).get(ProtocolManager.ACTP)»(«protocolManager.getModName(ProtocolManager.PRED)»«actor.label»_«protocolManager.getSigPrintName(ProtocolManager.PRED,commSigId,input)»),«ENDIF»
			«IF protocolManager.isOutputSide(ProtocolManager.PRED,commSigId)».«protocolManager.modCommSignals.get(ProtocolManager.PRED).get(commSigId).get(ProtocolManager.ACTP)»(«protocolManager.getModName(ProtocolManager.ACTOR)»«actor.label»_«protocolManager.getSigPrintName(ProtocolManager.ACTOR,commSigId,input)»),«ENDIF»
			«ENDFOR»
			
			// System Signal(s)
			«FOR sysSigId : protocolManager.modSysSignals.get(ProtocolManager.PRED).keySet SEPARATOR ","»
			«IF protocolManager.modSysSignals.get(ProtocolManager.PRED).get(sysSigId).containsKey(ProtocolManager.CLOCK) && (enableClockGating || enablePowerGating)»
			.«protocolManager.modSysSignals.get(ProtocolManager.PRED).get(sysSigId).get(ProtocolManager.ACTP)»(«IF powerSets.contains(instanceClockDomain.get(actor))»«clockSignal»ck_gated_«clockDomainsIndex.get(instanceClockDomain.get(actor))»«ELSE»«protocolManager.modSysSignals.get(ProtocolManager.PRED).get(sysSigId).get(ProtocolManager.NETP)»«ENDIF»)
 			«ELSE»
			.«protocolManager.modSysSignals.get(ProtocolManager.PRED).get(sysSigId).get(ProtocolManager.ACTP)»(«protocolManager.modSysSignals.get(ProtocolManager.PRED).get(sysSigId).get(ProtocolManager.NETP)»)
			«ENDIF»
			«ENDFOR»
		);
		«ENDFOR»
		«ENDIF»
		
		// actor «actor.simpleName»
		«getActorName(actor)» «IF !getActorStaticParms(actor).empty»#(
			// Parameter(s)
		«FOR parm : getActorStaticParms(actor) SEPARATOR ","»
			«printActorStaticParm(parm,actor.parameters.size)»
		«ENDFOR»
		)
		«ENDIF»
		actor_«actor.simpleName» (
			// Input Signal(s)
			«FOR input : actor.inputs SEPARATOR ","»«FOR commSigId : protocolManager.getActorInputCommSignals(actor) SEPARATOR ","»
			.«protocolManager.getActorPortPrintSignal(commSigId,input)»(«protocolManager.getModName(ProtocolManager.ACTOR)»«actor.label»_«protocolManager.getSigPrintName(ProtocolManager.ACTOR,commSigId,input)»)
			«ENDFOR»
			«ENDFOR»
			«IF !protocolManager.getActorOutputCommSignals(actor).empty»,«ENDIF»
			
			// Output Signal(s)
			«FOR output : actor.outputs SEPARATOR ","»«FOR commSigId : protocolManager.getActorOutputCommSignals(actor) SEPARATOR ","»
			.«protocolManager.getActorPortPrintSignal(commSigId,output)»(«protocolManager.getModName(ProtocolManager.ACTOR)»«actor.label»_«protocolManager.getSigPrintName(ProtocolManager.ACTOR,commSigId,output)»)
			«ENDFOR»
			«ENDFOR»
			«IF !getActorDynamicParms(actor).empty»,
			
			// Dynamic Parameter(s)
			«FOR parm : getActorDynamicParms(actor) SEPARATOR ","»
			«printActorDynamicParm(parm,actor.parameters.size)»
			«ENDFOR»
			«ENDIF»
			«IF !protocolManager.getActorSysSignals(actor).empty»,«ENDIF»
			
			// System Signal(s)
			«FOR sysSigId : protocolManager.getActorSysSignals(actor) SEPARATOR ","»	
			«IF protocolManager.modSysSignals.get(ProtocolManager.ACTOR).get(sysSigId).containsKey(ProtocolManager.CLOCK) && (enableClockGating || enablePowerGating)»
«««			«IF modSysSignals.get(ACTOR).get(sysSigId).get(ACTP).equals(CLOCK) && (enableClockGating || enablePowerGating)»
			.«protocolManager.modSysSignals.get(ProtocolManager.ACTOR).get(sysSigId).get(ProtocolManager.ACTP)»(«IF powerSets.contains(instanceClockDomain.get(actor))»«clockSignal»ck_gated_«clockDomainsIndex.get(instanceClockDomain.get(actor))»«ELSE»«protocolManager.modSysSignals.get(ProtocolManager.ACTOR).get(sysSigId).get(ProtocolManager.NETP)»«ENDIF»)
			«ELSE»
			.«protocolManager.modSysSignals.get(ProtocolManager.ACTOR).get(sysSigId).get(ProtocolManager.ACTP)»(«protocolManager.modSysSignals.get(ProtocolManager.ACTOR).get(sysSigId).get(ProtocolManager.NETP)»)
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
			«FOR commSigId : protocolManager.modCommSignals.get(protocolManager.getFirstMod()).keySet»
			«««todo put actp instead of ch
			«IF protocolManager.isInputSide(protocolManager.getFirstMod(),commSigId) && !input.label.equals("sel")».«input.label»«protocolManager.getChannelPrintSuffix(protocolManager.getFirstMod(),commSigId)»(«actor.label»_«protocolManager.getSigPrintName(protocolManager.getFirstMod(),commSigId,input)»),«ENDIF»
			«ENDFOR»
			«ENDFOR»
			
			// Output Signal(s)
			«FOR output : actor.outputs»
			«FOR commSigId : protocolManager.modCommSignals.get(protocolManager.getLastMod()).keySet»
			«««todo put actp instead of ch
			«IF protocolManager.isOutputSide(protocolManager.getLastMod(),commSigId)».«output.label»«protocolManager.getChannelPrintSuffix(protocolManager.getLastMod(),commSigId)»(«actor.label»_«protocolManager.getSigPrintName(protocolManager.getLastMod(),commSigId,output)»),«ENDIF»
			«ENDFOR»
			«ENDFOR»
			
			// Selector
			.sel(sel[«actor.simpleName.split("_").get(1)»])	
		);
		«ENDIF»	
		
		«IF !actor.hasAttribute("sbox")»
		«IF protocolManager.modNames.containsKey(ProtocolManager.SUCC)»
		«FOR output : actor.outputs»
		// «protocolManager.modNames.get(ProtocolManager.SUCC)»_«actor.simpleName»_«output.label»
		«protocolManager.modNames.get(ProtocolManager.SUCC)»  «IF protocolManager.modCommParms.containsKey(ProtocolManager.PRED)»#(
		«FOR commParId : protocolManager.modCommParms.get(ProtocolManager.SUCC).keySet SEPARATOR ","»	.«protocolManager.modCommParms.get(ProtocolManager.SUCC).get(commParId).get(ProtocolManager.NAME)»(«getParameterValue(ProtocolManager.SUCC,actor,output,commParId)»)
		«ENDFOR»
		) «ENDIF»«protocolManager.modNames.get(ProtocolManager.SUCC)»_«actor.simpleName»_«output.label»(
			«FOR commSigId : protocolManager.modCommSignals.get(ProtocolManager.SUCC).keySet»
			«IF protocolManager.isInputSide(ProtocolManager.SUCC,commSigId)».«protocolManager.modCommSignals.get(ProtocolManager.SUCC).get(commSigId).get(ProtocolManager.ACTP)»(«protocolManager.getModName(ProtocolManager.ACTOR)»«actor.label»_«protocolManager.getSigPrintName(ProtocolManager.ACTOR,commSigId,output)»),«ENDIF»
			«IF protocolManager.isOutputSide(ProtocolManager.SUCC,commSigId)».«protocolManager.modCommSignals.get(ProtocolManager.SUCC).get(commSigId).get(ProtocolManager.ACTP)»(«protocolManager.getModName(ProtocolManager.SUCC)»«actor.label»_«protocolManager.getSigPrintName(ProtocolManager.SUCC,commSigId,output)»),«ENDIF»
			«ENDFOR»
			
			// System Signal(s)
			«FOR sysSigId : protocolManager.modSysSignals.get(ProtocolManager.SUCC).keySet SEPARATOR ","»
			«IF protocolManager.modSysSignals.get(ProtocolManager.SUCC).get(sysSigId).containsKey(ProtocolManager.CLOCK) && (enableClockGating || enablePowerGating)»
			.«protocolManager.modSysSignals.get(ProtocolManager.SUCC).get(sysSigId).get(ProtocolManager.ACTP)»(«IF powerSets.contains(instanceClockDomain.get(actor))»«clockSignal»ck_gated_«clockDomainsIndex.get(instanceClockDomain.get(actor))»«ELSE»«protocolManager.modSysSignals.get(ProtocolManager.SUCC).get(sysSigId).get(ProtocolManager.NETP)»«ENDIF»)
			«ELSE»
			.«protocolManager.modSysSignals.get(ProtocolManager.SUCC).get(sysSigId).get(ProtocolManager.ACTP)»(«protocolManager.modSysSignals.get(ProtocolManager.SUCC).get(sysSigId).get(ProtocolManager.NETP)»)
			«ENDIF»
			«ENDFOR»
		);
		«ENDFOR»
		«ENDIF»
		«ENDIF»
		«ENDFOR»
		'''
	}
	
	/**
	 * TODO
	 */
	def printActorDynamicParm(Var parm, int size) {
		
		var String result = "";
		var String value = "";
		for(Var netParm : network.parameters) {
			if(netParm.name.equals(parm.name)) {
				value = netParm.name;
			}
		}
		if(value.equals("")) {
			value = evaluator.evaluateAsInteger(parm.initialValue).toString;
		}
		result = "." + parm.name + "(" + value + ")";
		
		return result;
		
	}
	
	/**
	 * TODO
	 */
	def printActorStaticParm(Var parm, int size) {
		
		var String result = "";
		var String value = "";
		for(Var netParm : network.variables) {
			if(netParm.name.equals(parm.name)) {
				value = netParm.name;
			}
		}
		if(value.equals("")) {
			value = evaluator.evaluateAsInteger(parm.initialValue).toString;
		}
		result = "." + parm.name + "(" + value + ")";
		
		return result;
		
	}

	/**
	 * print assignments to connect instances.
	 */
	def printAssignments() {
		
		'''
		// Module(s) Assignments
		«FOR connection : network.connections»
		«FOR commSigId : protocolManager.modCommSignals.get(protocolManager.getFirstMod()).keySet»
		«IF protocolManager.isInputSide(protocolManager.getFirstMod(),commSigId)»
		«IF protocolManager.modCommSignals.get(protocolManager.getFirstMod()).get(commSigId).get(ProtocolManager.KIND).equals("input")»
		assign «getTargetSignal(connection,protocolManager.getFirstMod(),commSigId)» = «getSourceSignal(connection,protocolManager.getLastMod(),protocolManager.modCommSignals.get(protocolManager.getFirstMod()).get(commSigId).get(ProtocolManager.CH))»;
		«ELSE»
		«IF connection.hasAttribute("broadcast")»
		«IF connection.source instanceof Actor»
		«IF !connection.sourcePort.hasAttribute("printed")»
		assign «getSourceSignal(connection,protocolManager.getLastMod(),protocolManager.modCommSignals.get(protocolManager.getFirstMod()).get(commSigId).get(ProtocolManager.CH))» =
		«FOR broadConn : (connection.source as Actor).outgoingPortMap.get(connection.sourcePort) SEPARATOR " ||"»
		«getTargetSignal(broadConn,protocolManager.getFirstMod(),commSigId)» 
		«ENDFOR»;
		«connection.sourcePort.setAttribute("printed","")»
		«ENDIF»
		«ELSE»
		«IF !connection.source.hasAttribute("printed")»
		assign «getSourceSignal(connection,protocolManager.getLastMod(),protocolManager.modCommSignals.get(protocolManager.getFirstMod()).get(commSigId).get(ProtocolManager.CH))» =		
		«FOR broadConn : (connection.source as Port).outgoing SEPARATOR " ||"»
		«getTargetSignal(broadConn as Connection,protocolManager.getFirstMod(),commSigId)» 
		«ENDFOR»;
		«connection.source.setAttribute("printed","")»
		«ENDIF»
		«ENDIF»
		«ELSE»
		assign «getSourceSignal(connection,protocolManager.getLastMod(),protocolManager.modCommSignals.get(protocolManager.getFirstMod()).get(commSigId).get(ProtocolManager.CH))» = «getTargetSignal(connection,protocolManager.getFirstMod(),commSigId)»;
		«ENDIF»
		«ENDIF»
		«ENDIF»
		«ENDFOR»
		
		«ENDFOR»
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
			«FOR sysSigId : protocolManager.netSysSignals.keySet SEPARATOR ","»
			«IF protocolManager.modSysSignals.get(ProtocolManager.ACTOR).get(sysSigId).containsKey(ProtocolManager.CLOCK)»
			.clock_in(«protocolManager.netSysSignals.get(sysSigId).get(ProtocolManager.NETP)»)«ENDIF»
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
			«FOR sysSigId : protocolManager.netSysSignals.keySet»
			«IF protocolManager.modSysSignals.get(ProtocolManager.ACTOR).get(sysSigId).containsKey(ProtocolManager.CLOCK)»
			.clk(«protocolManager.netSysSignals.get(sysSigId).get(ProtocolManager.NETP)»)«ENDIF»
			«ENDFOR»
		);
		«ENDIF»
		«ENDFOR»
		'''
	}

	/**
	 * Print the header of the Verilog file
	 */
	def printHeaderComments(){
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
	 * Print top module interface.
	 */
	def printInterface(List<SboxLut> luts) {
		
		'''
		module multi_dataflow «IF !network.variables.empty»#(
			// Static Parameter(s)
			«FOR param : network.variables SEPARATOR ","»
			parameter «IF param.type.sizeInBits != 1»[«param.type.sizeInBits-1»:0] «ENDIF»«param.name» = «evaluator.evaluateAsInteger(param.initialValue as Expression)»
			«ENDFOR»
		) «ENDIF»(
			// Input(s)
			«FOR input : network.inputs»
			«FOR commSigId : protocolManager.modCommSignals.get(protocolManager.firstMod).keySet»
			«IF protocolManager.isInputSide(protocolManager.firstMod,commSigId)»
			«protocolManager.modCommSignals.get(protocolManager.firstMod).get(commSigId).get(ProtocolManager.KIND)» «protocolManager.getCommSigPrintRange(protocolManager.firstMod,null,commSigId,input)»«protocolManager.getSigPrintName(protocolManager.firstMod,commSigId,input)»,
			«ENDIF»
			«ENDFOR»
			
			// Output(s)
			«ENDFOR»
			«FOR output : network.outputs»
			«FOR commSigId : protocolManager.modCommSignals.get(protocolManager.lastMod).keySet»
			«IF protocolManager.isOutputSide(protocolManager.lastMod,commSigId)»
			«protocolManager.modCommSignals.get(protocolManager.lastMod).get(commSigId).get(ProtocolManager.KIND)»  «protocolManager.getCommSigPrintRange(protocolManager.lastMod,null,commSigId,output)»«protocolManager.getSigPrintName(protocolManager.lastMod,commSigId,output)»,
			«ENDIF»
			«ENDFOR»
			«ENDFOR»	
			
			// Dynamic Parameter(s)
			«IF (!network.parameters.empty)»
			«FOR param : network.parameters»
			input [«param.type.sizeInBits-1»:0] «param.name»,
			«ENDFOR»
			«ENDIF»
			
			// Configuration ID
			«IF !luts.empty»
			input [7:0] ID,
			«ENDIF»
			
			«IF enablePowerGating»
			input [17:0] reference_count, //to set the time necessary for be sure power is off or on
			
			«FOR lr: powerSets»
			output	status«clockDomainsIndex.get(lr)»,
			«ENDFOR»
			«ENDIF»			
			
			// System Signal(s)		
			«FOR sysSigId : protocolManager.netSysSignals.keySet SEPARATOR ","»
			«protocolManager.netSysSignals.get(sysSigId).get(ProtocolManager.KIND)» «protocolManager.getSysSigPrintRange(null,sysSigId)»«protocolManager.netSysSignals.get(sysSigId).get(ProtocolManager.NETP)»
			«ENDFOR»
		);	
		'''
	}	
	
	/**
	 * print top module internal signals
	 */
	def printInternalSignals(List<SboxLut> luts) {
	
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
			«IF protocolManager.modNames.containsKey(ProtocolManager.PRED)»
			«FOR commSigId : protocolManager.modCommSignals.get(ProtocolManager.PRED).keySet»
			«IF protocolManager.isInputSide(ProtocolManager.PRED,commSigId)»
			wire «protocolManager.getCommSigPrintRange(ProtocolManager.PRED,actor,commSigId,input)»«protocolManager.getModName(ProtocolManager.PRED)»«actor.label»_«protocolManager.getSigPrintName(ProtocolManager.PRED,commSigId,input)»;
			«ENDIF»
			«ENDFOR»
			«ENDIF»
			«FOR commSigId : protocolManager.modCommSignals.get(ProtocolManager.ACTOR).keySet»
			«IF protocolManager.isInputSide(ProtocolManager.ACTOR,commSigId)»
			wire «protocolManager.getCommSigPrintRange(ProtocolManager.ACTOR,actor,commSigId,input)»«protocolManager.getModName(ProtocolManager.ACTOR)»«actor.label»_«protocolManager.getSigPrintName(ProtocolManager.ACTOR,commSigId,input)»;
			«ENDIF»
			«ENDFOR»
			«ENDFOR»
			«FOR output : actor.outputs»
			«FOR commSigId : protocolManager.modCommSignals.get(ProtocolManager.ACTOR).keySet»
			«IF protocolManager.isOutputSide(ProtocolManager.ACTOR,commSigId)»
			wire «protocolManager.getCommSigPrintRange(ProtocolManager.ACTOR,actor,commSigId,output)»«protocolManager.getModName(ProtocolManager.ACTOR)»«actor.label»_«protocolManager.getSigPrintName(ProtocolManager.ACTOR,commSigId,output)»;
			«ENDIF»
			«ENDFOR»
			«IF protocolManager.modNames.containsKey(ProtocolManager.SUCC)»
			«FOR commSigId : protocolManager.modCommSignals.get(ProtocolManager.SUCC).keySet»
			«IF protocolManager.isOutputSide(ProtocolManager.SUCC,commSigId)»
			wire «protocolManager.getCommSigPrintRange(ProtocolManager.SUCC,actor,commSigId,output)»«protocolManager.getModName(ProtocolManager.SUCC)»«actor.label»_«protocolManager.getSigPrintName(ProtocolManager.SUCC,commSigId,output)»;
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
			«FOR commSigId : protocolManager.modCommSignals.get(protocolManager.firstMod).keySet»
			«IF protocolManager.isInputSide(protocolManager.firstMod,commSigId) && !input.label.equals("sel")»
			 wire «protocolManager.getCommSigPrintRange(ProtocolManager.ACTOR,actor,commSigId,input)»«protocolManager.getModName(ProtocolManager.ACTOR)»«actor.label»_«protocolManager.getSigPrintName(protocolManager.firstMod,commSigId,input)»;
			«ENDIF»
			«ENDFOR»
			«ENDFOR»
			«FOR output : actor.outputs»
			«FOR commSigId : protocolManager.modCommSignals.get(ProtocolManager.ACTOR).keySet»
			«IF protocolManager.isOutputSide(protocolManager.lastMod,commSigId)»
			 wire «protocolManager.getCommSigPrintRange(ProtocolManager.ACTOR,actor,commSigId,output)»«protocolManager.getModName(ProtocolManager.ACTOR)»«actor.label»_«protocolManager.getSigPrintName(protocolManager.lastMod,commSigId,output)»;
			«ENDIF»
			«ENDFOR»
			«ENDFOR»
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
			«FOR sysSigId : protocolManager.netSysSignals.keySet SEPARATOR ","»
			«IF protocolManager.modSysSignals.get(ProtocolManager.ACTOR).get(sysSigId).containsKey(ProtocolManager.CLOCK)»
			.clk(«protocolManager.netSysSignals.get(sysSigId).get(ProtocolManager.NETP)»)«ELSE»
			««« TODO: necessary to bring inside the info about the reset activity (low or high)
			.rst(!«protocolManager.netSysSignals.get(sysSigId).get(ProtocolManager.NETP)»)«ENDIF»
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
			«FOR sysSigId : protocolManager.netSysSignals.keySet SEPARATOR ","»
			«IF protocolManager.modSysSignals.get(ProtocolManager.ACTOR).get(sysSigId).containsKey(ProtocolManager.CLOCK)»
			.aclk(«protocolManager.netSysSignals.get(sysSigId).get(ProtocolManager.NETP)»)«ELSE»
			.aresetn(«protocolManager.netSysSignals.get(sysSigId).get(ProtocolManager.NETP)»)«ENDIF»
			«ENDFOR»
				);
		«ENDFOR»
		
		
		«FOR lr: powerSets» «IF logicRegionsSeqMap.get(lr)»
		// Clock Gating Cell «clockDomainsIndex.get(lr)»
		clock_gating_cell cgc_«clockDomainsIndex.get(lr)» (
			.ck_gated(ck_gated_«clockDomainsIndex.get(lr)»),
			.en(en_cg«clockDomainsIndex.get(lr)»),
			«FOR sysSigId : protocolManager.netSysSignals.keySet»
			«IF protocolManager.modSysSignals.get(ProtocolManager.ACTOR).get(sysSigId).containsKey(ProtocolManager.CLOCK)»
			.clk(«protocolManager.netSysSignals.get(sysSigId).get(ProtocolManager.NETP)»)«ENDIF»
			«ENDFOR»
		);
		«ENDIF»
		«ENDFOR»
		'''
	}
	
	/**
	 * Print parameter within parameter list
	 * 
	 * @parm
	 * 				involved variable
	 * @size
	 * 				overall number of parameters
	 * @return		
	 * 				parameter to be printed within list
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
		 Map<String,Set<String>> logicRegions,
		 Map<String,Set<String>> netRegions,
		 Set<String> powerSets,
		 Map<String,Integer> powerSetsIndex,
		 Map<String,Boolean> logicRegionsSeqMap,
		 ProtocolManager protocolManager){
		 	
		 
		this.evaluator = new ExpressionEvaluator();
		 	
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
		this.protocolManager = protocolManager;
		
		
		// to be ignored
		networkPortFanout = new HashMap<Port, Integer>();
		networkPortConnectionFanout = new HashMap<Connection, Integer>();		
		portClockDomain = new HashMap<Port, String>();
		instanceClockDomain = new HashMap<Actor, String>();
		clockDomainsIndex = new HashMap<String, Integer>();
		connectionsClockDomain = new HashMap<Connection,List<Integer>>();
		
		
		computeNetworkClockDomains(network,clockSets);
		
		'''
		«printHeaderComments()»
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
			if(connection.sourcePort === null) {
				if(connection.source.hasAttribute("printed")) {
					connection.source.removeAttribute("printed");	
				}
			} else {
				if(connection.sourcePort.hasAttribute("printed")) {
					connection.sourcePort.removeAttribute("printed");	
				}
			}	
	}
	
}
