/*
 *
 */
 
package it.unica.diee.mdc.platformComposer;

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
import it.unica.diee.mdc.sboxManagement.SboxLut
import net.sf.orcc.ir.util.ExpressionEvaluator
import net.sf.orcc.ir.Var
import java.util.ArrayList

/*
 * A VHDL RVC-CAL FIFO-based Protocol Network printer
 * 
 * @author Carlo Sau
 */
class NetworkPrinterCustom {
	/**
	 * Protocol signals flags
	 */
	var int DIRECTION = 0;
	var int OUT_PORT = 1;
	var int SIZE = 2;
	var int IN_PORT = 3;
	var int IS_NATIVE = 4;
	var int PORT = 1;
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
	
	var List<String[]> signals;
	
	var List<String[]> extSignals;
	
	var List<String[]> seqSignals;
	
	var List<String[]> combSignals;
	
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
	
	def Map<String, Integer> getClockDomainIndex(){ //deve diventare getLogicRegionIndex
		return clockDomainsIndex; //deve diventare logicRegionIndex
	}
		
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
	
	def printConfig(List<SboxLut> luts) {
		'''
		// Network Configurator
		configurator config_0 (
			.sel(sel),
			.ID(ID)
		);
		'''
	}
	
	def printEnableGenerator() {// Clock Gating Cell «id» id deve essere riferito solo ai domini di clock
	//Si può fare come per i segnali di power 
	//«FOR lr: powerSets»
	//		.iso_en«clockDomainsIndex.get(lr)»(iso_en«clockDomainsIndex.get(lr)»),
	// usando però l'insieme clockSet (che ancora non esiste)
		'''
		// Enable Generator
		enable_generator en_gen_0 (
			.clock_in(«clockSignal»),
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
			.clk(«clockSignal»)
		);
		«ENDIF»
		«ENDFOR»
		'''
	}
	
	def printPowerController(){
		'''
		//Power Controller
		PowerController powerController_0(
			// Input Signal(s)
			.ID(ID),
		
			// Output Signal(s)			
			«FOR lr: powerSets»
			.iso_en«clockDomainsIndex.get(lr)»(iso_en«clockDomainsIndex.get(lr)»),
			«IF logicRegionsSeqMap.get(lr)»
			.rstr_en«clockDomainsIndex.get(lr)»(rstr_en«clockDomainsIndex.get(lr)»),
			.save_en«clockDomainsIndex.get(lr)»(save_en«clockDomainsIndex.get(lr)»),
			.en_cg«clockDomainsIndex.get(lr)»(en_cg«clockDomainsIndex.get(lr)»),
			«ENDIF»
			.pw_switch_en«clockDomainsIndex.get(lr)»(pw_switch_en«clockDomainsIndex.get(lr)»),			
			
			«ENDFOR»
			// External Signal(s)
			.rst(rst),
			// Clock Signal
			.clk(«clockSignal»)
		);
		
		«FOR lr: powerSets» «IF logicRegionsSeqMap.get(lr)»
		// Clock Gating Cell «clockDomainsIndex.get(lr)»
		clock_gating_cell cgc_«clockDomainsIndex.get(lr)» (
			.ck_gated(ck_gated_«clockDomainsIndex.get(lr)»),
			.en(en_cg«clockDomainsIndex.get(lr)»),
			.clk(«clockSignal»)
		);
		«ENDIF»
		«ENDFOR»
		'''
	}
	
	def printActors(Map<String,Set<String>> clockSets) {
		// WARNING: qui serve un controllo in più, dopo le modifiche instanceClockDomain avrà solo attori relativi a domini di CG, quindi quel get.(actor) potrebbe essere null
		'''
		«FOR actor : network.getChildren().filter(typeof(Actor))»
		// Actor «actor.simpleName»
		«IF !actor.hasAttribute("sbox")»«getActorName(actor)» «IF !actor.parameters.empty»#(
			// Parameter(s)
		«FOR parm : actor.parameters»	«printParm(parm,actor.parameters.size)»
		«ENDFOR»
		)
		«ENDIF»
		«actor.simpleName» (
			// Input Signal(s)
		«IF !computeCombPorts(actor.inputs).empty»
		«FOR combInput : computeCombPorts(actor.inputs) SEPARATOR ","»
		«FOR signal : combSignals SEPARATOR ","»	.«combInput.label»«IF !signal.get(IN_PORT).equals("")»_«signal.get(IN_PORT)»«ENDIF»(«actor.label»_«combInput.label»«IF !signal.get(IN_PORT).equals("")»_«signal.get(IN_PORT)»«ENDIF»)«ENDFOR»«ENDFOR»«IF (!computeSeqPorts(actor.inputs).isEmpty && !seqSignals.isEmpty) || (!computeCombPorts(actor.outputs).isEmpty && !combSignals.isEmpty) || (!computeSeqPorts(actor.outputs).isEmpty && !seqSignals.isEmpty) || !actor.hasAttribute("combinational")»,«ENDIF»
		«ENDIF»
		«IF !computeSeqPorts(actor.inputs).empty»
		«FOR seqInput : computeSeqPorts(actor.inputs) SEPARATOR ","»
		«FOR signal : seqSignals SEPARATOR ","»	.«seqInput.label»«IF !signal.get(IN_PORT).equals("")»_«signal.get(IN_PORT)»«ENDIF»(«actor.label»_«seqInput.label»«IF !signal.get(IN_PORT).equals("")»_«signal.get(IN_PORT)»«ENDIF»)«ENDFOR»«ENDFOR»«IF (!computeCombPorts(actor.outputs).isEmpty && !combSignals.isEmpty) || (!computeSeqPorts(actor.outputs).isEmpty && !seqSignals.isEmpty) || !actor.hasAttribute("combinational")»,«ENDIF»
		«ENDIF»
			// Output Signal(s)
		«IF !computeCombPorts(actor.outputs).empty»
		«FOR combOutput : computeCombPorts(actor.outputs) SEPARATOR ","»
		«FOR signal : combSignals SEPARATOR ","»	.«combOutput.label»«IF !signal.get(OUT_PORT).equals("")»_«signal.get(OUT_PORT)»«ENDIF»(«actor.label»_«combOutput.label»«IF !signal.get(OUT_PORT).equals("")»_«signal.get(OUT_PORT)»«ENDIF»)«ENDFOR»«ENDFOR»«IF (!computeSeqPorts(actor.outputs).isEmpty && !seqSignals.isEmpty) || !actor.hasAttribute("combinational")»,«ENDIF»
		«ENDIF»
«««		«IF !computeSeqPorts(actor.inputs).empty»
		«IF !computeSeqPorts(actor.outputs).empty»
		«FOR seqOutput : computeSeqPorts(actor.outputs) SEPARATOR ","»
		«FOR signal : seqSignals SEPARATOR ","»	.«seqOutput.label»«IF !signal.get(OUT_PORT).equals("")»_«signal.get(OUT_PORT)»«ENDIF»(«actor.label»_«seqOutput.label»«IF !signal.get(OUT_PORT).equals("")»_«signal.get(OUT_PORT)»«ENDIF»)«ENDFOR»«ENDFOR»«IF !actor.hasAttribute("combinational")»,«ENDIF»
		«ENDIF»
		«IF !actor.hasAttribute("combinational")»
			// External Signal(s)
		«FOR extSignal : extSignals»	.«extSignal.get(PORT)»(«extSignal.get(PORT)»),«ENDFOR»
			// Clock Signal
		«IF (!enableClockGating && !enablePowerGating)»	.«clockSignal»(«clockSignal»)«ENDIF»
«««		«IF (enableClockGating && !enablePowerGating)»	.«clockSignal»(ck_gated_«clockDomainsIndex.get(instanceClockDomain.get(actor))»)«ENDIF»
		«IF (enableClockGating || enablePowerGating)» «IF powerSets.contains(instanceClockDomain.get(actor))».«clockSignal»(ck_gated_«clockDomainsIndex.get(instanceClockDomain.get(actor))»)
		«ELSE».«clockSignal»(«clockSignal»)«ENDIF»«ENDIF»
		«ENDIF»
		);

		«ELSE»		
		«getSboxActorName(actor)» #(
			.DATA_SIZE(«actor.getInput("in1").getType.getSizeInBits»),
			.DATA_SIZE_1(«actor.getInput("in1").getType.getSizeInBits»),
			.DATA_SIZE_2(«actor.getInput("in1").getType.getSizeInBits»)
		)
		«actor.simpleName» (
			// Input Signal(s)
		«FOR input : actor.inputs»
		«FOR signal : signals»
		«IF verifyNative(signal, input)»	.«input.label»«IF !signal.get(IN_PORT).equals("")»_«signal.get(IN_PORT)»«ENDIF»(«actor.label»_«input.label»«IF !signal.get(IN_PORT).equals("")»_«signal.get(IN_PORT)»«ENDIF»),
		«ENDIF»
		«ENDFOR»
		«ENDFOR»
			// Output Signal(s)
		«FOR output : actor.outputs»
		«FOR signal : signals»
		«IF verifyNative(signal, output)»	.«output.label»«IF !signal.get(OUT_PORT).equals("")»_«signal.get(OUT_PORT)»«ENDIF»(«actor.label»_«output.label»«IF !signal.get(OUT_PORT).equals("")»_«signal.get(OUT_PORT)»«ENDIF»),
		«ENDIF»
		«ENDFOR»
		«ENDFOR»
			// Selector
			.sel(sel[«actor.simpleName.split("_").get(1)»])	
		);

		«ENDIF»	
		«ENDFOR»
		'''
	}
	
	def computeCombPorts(List<Port> ports) {
		var combInputs = new ArrayList<Port>();
		for(Port input : ports) {
			if(input.isNative()) {
				combInputs.add(input);
			}
		}
		return combInputs;
	}
	
	def computeSeqPorts(List<Port> ports) {
		var combInputs = new ArrayList<Port>();
		for(Port input : ports) {
			if(!input.isNative()) {
				combInputs.add(input);
			}
		}
		return combInputs;
	}
	
	def printParm(Var parm, int size) {
		
		var String result = "";

		if(parm.value != null) {
			result = "." + parm.name + "(" + parm.value.toString().split(": ").get(1).split("\\)").get(0) + ")";
		} else {
			result = "." + parm.name + "(" + (new ExpressionEvaluator().evaluateAsInteger(parm.initialValue)) + ")";
		}
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
	
	def printAssignments() {
		
		removeAllPrintFlags();	
		
		'''
		// Module(s) Assignments
		«FOR connection : network.connections»
		«IF connection.sourcePort==null»
		«IF connection.targetPort==null»
		«FOR signal : signals»
		«IF verifyNative(signal,connection.source.getAdapter(Port),connection.target.getAdapter(Port))»
		«IF signal.get(DIRECTION).equals("dx")»
		assign «connection.target.label»«IF !signal.get(OUT_PORT).equals("")»_«signal.get(OUT_PORT)»«ENDIF» = «connection.source.label»«IF !signal.get(IN_PORT).equals("")»_«signal.get(IN_PORT)»«ENDIF»;
		«ELSE»
		«IF !connection.hasAttribute("broadcast")»
		assign «connection.source.label»«IF !signal.get(IN_PORT).equals("")»_«signal.get(IN_PORT)»«ENDIF» = «connection.target.label»«IF !signal.get(OUT_PORT).equals("")»_«signal.get(OUT_PORT)»«ENDIF»;
		«ENDIF»
		«ENDIF»
		«ENDIF»
		«ENDFOR»
		
		«ELSE»
		«FOR signal : signals»
		«IF verifyNative(signal,connection.source.getAdapter(Port),connection.targetPort)»
		«IF signal.get(DIRECTION).equals("dx")»
		assign «connection.target.label»_«connection.targetPort.label»«IF !signal.get(IN_PORT).equals("")»_«signal.get(IN_PORT)»«ENDIF» = «connection.source.label»«IF !signal.get(IN_PORT).equals("")»_«signal.get(IN_PORT)»«ENDIF»;
		«ELSE»
		«IF !connection.hasAttribute("broadcast")»
		assign «connection.source.label»«IF !signal.get(IN_PORT).equals("")»_«signal.get(IN_PORT)»«ENDIF» = «connection.target.label»_«connection.targetPort.label»«IF !signal.get(IN_PORT).equals("")»_«signal.get(IN_PORT)»«ENDIF»;
		«ENDIF»
		«ENDIF»
		«ENDIF»
		«ENDFOR»
		
		«ENDIF»
		
		«ELSE»
		«IF connection.targetPort==null»
		«FOR signal : signals»
		«IF verifyNative(signal,connection.sourcePort,connection.target.getAdapter(Port))»
		«IF signal.get(DIRECTION).equals("dx")»
		assign «connection.target.label»«IF !signal.get(OUT_PORT).equals("")»_«signal.get(OUT_PORT)»«ENDIF» = «connection.source.label»_«connection.sourcePort.label»«IF !signal.get(OUT_PORT).equals("")»_«signal.get(OUT_PORT)»«ENDIF»;
		«ELSE»
		«IF !connection.hasAttribute("broadcast")»
		assign «connection.source.label»_«connection.sourcePort.label»«IF !signal.get(OUT_PORT).equals("")»_«signal.get(OUT_PORT)»«ENDIF» = «connection.target.label»«IF !signal.get(OUT_PORT).equals("")»_«signal.get(OUT_PORT)»«ENDIF»;
		«ENDIF»
		«ENDIF»
		«ENDIF»
		«ENDFOR»
		
		«ELSE»
		«FOR signal : signals»
		«IF verifyNative(signal,connection.sourcePort,connection.targetPort)»
		«IF signal.get(DIRECTION).equals("dx")»
		assign «connection.target.label»_«connection.targetPort.label»«IF !signal.get(IN_PORT).equals("")»_«signal.get(IN_PORT)»«ENDIF» = «connection.source.label»_«connection.sourcePort.label»«IF !signal.get(OUT_PORT).equals("")»_«signal.get(OUT_PORT)»«ENDIF»;
		«ELSE»
		«IF !connection.hasAttribute("broadcast")»
		assign «connection.source.label»_«connection.sourcePort.label»«IF !signal.get(OUT_PORT).equals("")»_«signal.get(OUT_PORT)»«ENDIF» = «connection.target.label»_«connection.targetPort.label»«IF !signal.get(IN_PORT).equals("")»_«signal.get(IN_PORT)»«ENDIF»;
		«ENDIF»
		«ENDIF»
		«ENDIF»
		«ENDFOR»
		
		«ENDIF»
		«ENDIF»
		«ENDFOR»
			
		// Broadcast(s) Assignments
		«FOR connection : network.connections»
		«IF connection.hasAttribute("broadcast")»		
		«IF connection.sourcePort == null»	
		«IF !connection.source.hasAttribute("printed")»
		«FOR signal : signals»
		«IF verifyNative(signal,connection.source.getAdapter(Port))»
		«IF signal.get(DIRECTION).equals("sx") && signal.get(SIZE).equals("1")»
		assign «connection.source.label»«IF !signal.get(OUT_PORT).equals("")»_«signal.get(OUT_PORT)»«ENDIF» = «connection.source.label»«IF !signal.get(OUT_PORT).equals("")»_«signal.get(IN_PORT)»«ENDIF»_broadcast;
		assign «connection.source.label»«IF !signal.get(OUT_PORT).equals("")»_«signal.get(IN_PORT)»«ENDIF»_broadcast =
		«IF connection.target == null»	«connection.target.label»«IF !signal.get(IN_PORT).equals("")»_«signal.get(IN_PORT)»«ENDIF»
		«ELSE»	«connection.target.label»_«connection.targetPort.label»«IF !signal.get(IN_PORT).equals("")»_«signal.get(IN_PORT)»«ENDIF»
		«ENDIF»
		«FOR otherConnection : network.connections»
		«IF !otherConnection.equals(connection) && otherConnection.source.equals(connection.source)»
		«IF otherConnection.target == null»	& «otherConnection.target.label»«IF !signal.get(IN_PORT).equals("")»_«signal.get(IN_PORT)»«ENDIF»
		«ELSE»	& «otherConnection.target.label»_«otherConnection.targetPort.label»«IF !signal.get(IN_PORT).equals("")»_«signal.get(IN_PORT)»«ENDIF»
		«ENDIF»
		«ENDIF»
		«ENDFOR»;
		«ENDIF»
		«ENDIF»
		«ENDFOR»
		«connection.source.setAttribute("printed","")»		
		«ENDIF»
			
		«ELSE»		
		«IF !connection.sourcePort.hasAttribute("printed")»
		«FOR signal : signals»
		«IF verifyNative(signal,connection.sourcePort)»
		«IF signal.get(DIRECTION).equals("sx") && signal.get(SIZE).equals("1")»
		assign «connection.source.label»_«connection.sourcePort.label»«IF !signal.get(OUT_PORT).equals("")»_«signal.get(OUT_PORT)»«ENDIF» = «connection.source.label»_«connection.sourcePort.label»«IF !signal.get(OUT_PORT).equals("")»_«signal.get(OUT_PORT)»«ENDIF»_broadcast;
		assign «connection.source.label»_«connection.sourcePort.label»«IF !signal.get(OUT_PORT).equals("")»_«signal.get(OUT_PORT)»«ENDIF»_broadcast =
		«IF connection.target == null»	«connection.target.label»«IF !signal.get(IN_PORT).equals("")»_«signal.get(IN_PORT)»«ENDIF»
		«ELSE»	«connection.target.label»_«connection.targetPort.label»«IF !signal.get(IN_PORT).equals("")»_«signal.get(IN_PORT)»«ENDIF»
		«ENDIF»
		«FOR otherConnection : network.connections»
		«IF !otherConnection.equals(connection) && otherConnection.source.equals(connection.source) && otherConnection.sourcePort.equals(connection.sourcePort)»
		«IF otherConnection.target == null»	& «otherConnection.target.label»«IF !signal.get(IN_PORT).equals("")»_«signal.get(IN_PORT)»«ENDIF»
		«ELSE»	& «otherConnection.target.label»_«otherConnection.targetPort.label»«IF !signal.get(IN_PORT).equals("")»_«signal.get(IN_PORT)»«ENDIF»
		«ENDIF»
		«ENDIF»
		«ENDFOR»;
		«ENDIF»
		«ENDIF»
		«ENDFOR»
		«connection.sourcePort.setAttribute("printed","")»		
		«ENDIF»
		«ENDIF»
		«ENDIF»
		«ENDFOR»
		'''
	}
	
	def verifyNative(String[] signal, Port sourcePort, Port targetPort){
		return (!sourcePort.isNative() && !targetPort.isNative()) ||
					(sourcePort.isNative() && targetPort.isNative() && isNative(signal)); 
	}
	
	
	
	
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

	def printIOSignals(List<SboxLut> luts) {
		'''
		// Input(s)
		input «clockSignal»;
		«IF !luts.empty»
		input [7 : 0] ID;
		«ENDIF»
		«FOR extSignal : extSignals»
		«IF extSignal.get(DIRECTION).equals("dx")»
		input«IF getSize(extSignal, null)>1» [«getSize(extSignal, null)-1» : 0]«ENDIF» «extSignal.get(PORT)»;
		«ENDIF»
		«ENDFOR»
		«FOR input : network.inputs»
		«FOR signal : signals»
		«IF verifyNative(signal, input)»
		«IF signal.get(DIRECTION).equals("dx")»
		input«IF getSize(signal, input)>1» [«getSize(signal, input)-1» : 0]«ENDIF» «input.label»«IF !signal.get(IN_PORT).equals("")»_«signal.get(IN_PORT)»«ENDIF»;
		«ENDIF»
		«ENDIF»
		«ENDFOR»
		«ENDFOR»
		«FOR output : network.outputs»
		«FOR signal : signals»
		«IF verifyNative(signal, output)»
		«IF signal.get(DIRECTION).equals("sx")»
		input«IF getSize(signal, output)>1» [«getSize(signal, output)-1» : 0]«ENDIF» «output.label»«IF !signal.get(OUT_PORT).equals("")»_«signal.get(OUT_PORT)»«ENDIF»;
		«ENDIF»
		«ENDIF»
		«ENDFOR»		
		«ENDFOR»
		
		// Output(s)
		«FOR extSignal : extSignals»
		«IF extSignal.get(DIRECTION).equals("sx")»
		output«IF getSize(extSignal, null)>1» [«getSize(extSignal, null)-1» : 0]«ENDIF» «extSignal.get(PORT)»;
		«ENDIF»
		«ENDFOR»
		«FOR input : network.inputs»
		«FOR signal : signals»
		«IF verifyNative(signal, input)»
		«IF signal.get(DIRECTION).equals("sx")»
		output«IF getSize(signal, input)>1» [«getSize(signal, input)-1» : 0]«ENDIF» «input.label»«IF !signal.get(IN_PORT).equals("")»_«signal.get(IN_PORT)»«ENDIF»;
		«ENDIF»
		«ENDIF»
		«ENDFOR»
		«ENDFOR»
		«FOR output : network.outputs»
		«FOR signal : signals»
		«IF verifyNative(signal, output)»
		«IF signal.get(DIRECTION).equals("dx")»
		output«IF getSize(signal, output)>1» [«getSize(signal, output)-1» : 0]«ENDIF» «output.label»«IF !signal.get(OUT_PORT).equals("")»_«signal.get(OUT_PORT)»«ENDIF»;
		«ENDIF»
		«ENDIF»
		«ENDFOR»		
		«ENDFOR»
		«IF enablePowerGating»
		«FOR lr: powerSets»
		output	iso_en«clockDomainsIndex.get(lr)»;
		«IF logicRegionsSeqMap.get(lr)»
		output	rstr_en«clockDomainsIndex.get(lr)»;
		output	save_en«clockDomainsIndex.get(lr)»;
		«ENDIF»
		output	pw_switch_en«clockDomainsIndex.get(lr)»;		
		«ENDFOR»
		«ENDIF»
		'''
	}
	
	def printInternalSignals(List<SboxLut> luts) {
		'''
		
		// IO Wire(s)
		wire «clockSignal»;
		«IF !luts.empty»
		wire [7 : 0] ID;
		«ENDIF»
		«FOR extSignal : extSignals»
		wire«IF getSize(extSignal, null)>1» [«getSize(extSignal, null)-1» : 0]«ENDIF» «extSignal.get(PORT)»;
		«ENDFOR»
		«FOR input : network.inputs»
		«FOR signal : signals»
		«IF verifyNative(signal, input)»
		wire«IF getSize(signal, input)>1» [«getSize(signal, input)-1» : 0]«ENDIF» «input.label»«IF !signal.get(IN_PORT).equals("")»_«signal.get(IN_PORT)»«ENDIF»;
		«ENDIF»
		«ENDFOR»
		«ENDFOR»
		«FOR output : network.outputs»
		«FOR signal : signals»
		«IF verifyNative(signal, output)»
		wire«IF getSize(signal, output)>1» [«getSize(signal, output)-1» : 0]«ENDIF» «output.label»«IF !signal.get(OUT_PORT).equals("")»_«signal.get(OUT_PORT)»«ENDIF»;
		«ENDIF»
		«ENDFOR»		
		«ENDFOR»
		
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
		«FOR lr: powerSets»
		wire	iso_en«clockDomainsIndex.get(lr)»;
		«IF logicRegionsSeqMap.get(lr)»
		wire	rstr_en«clockDomainsIndex.get(lr)»;
		wire	save_en«clockDomainsIndex.get(lr)»;		
		wire	en_cg«clockDomainsIndex.get(lr)»;
		«ENDIF»
		wire	pw_switch_en«clockDomainsIndex.get(lr)»;
		
		«ENDFOR»
		«ENDIF»
		
		// Actors Wire(s)
		«FOR actor : network.getChildren().filter(typeof(Actor))»
		«FOR input : actor.inputs»
		«FOR signal : signals»
		«IF verifyNative(signal, input)»
		wire«IF getSize(signal, input)>1» [«getSize(signal, input)-1» : 0]«ENDIF» «actor.label»_«input.label»«IF !signal.get(IN_PORT).equals("")»_«signal.get(IN_PORT)»«ENDIF»;
		«ENDIF»
		«ENDFOR»
		«ENDFOR»
		«FOR output : actor.outputs»
		«FOR signal : signals»
		«IF verifyNative(signal, output)»
		wire«IF getSize(signal, output)>1» [«getSize(signal, output)-1» : 0]«ENDIF» «actor.label»_«output.label»«IF !signal.get(OUT_PORT).equals("")»_«signal.get(OUT_PORT)»«ENDIF»;
		«ENDIF»
		«ENDFOR»
		«ENDFOR»
		«ENDFOR»
		
		// Broadcast Wire(s)
		«FOR connection : network.connections»
		«IF connection.hasAttribute("broadcast")»	
		«IF connection.sourcePort == null»	
		«IF !connection.source.hasAttribute("printed")»
		«printPortBroad(connection)»
		«ENDIF»
		«ELSE»
		«IF !connection.sourcePort.hasAttribute("printed")»
		«printActorBroad(connection)»
		«ENDIF»
		«ENDIF»
		«ENDIF»
		«ENDFOR»
		'''
	}
	
	def printPortBroad(Connection connection) {
		
		connection.source.setAttribute("printed","");
		
		for(String[] signal : signals)
			if(verifyNative(signal,connection.source.getAdapter(Port))) {
				if( signal.get(DIRECTION).equals("sx") && signal.get(SIZE).equals("1")) {
					if (!signal.get(OUT_PORT).equals("")) {
						return "wire " + connection.source.label + "_" + signal.get(OUT_PORT ) + "_broadcast;";
					} else {		
						return "wire " + connection.source.label + "_broadcast;";
					}
				}
			}	
		return "";
	}
	
	def printActorBroad(Connection connection) {
		
		connection.sourcePort.setAttribute("printed","");
		
		for(String[] signal : signals)
			if(verifyNative(signal,connection.sourcePort)) {
				if( signal.get(DIRECTION).equals("sx") && signal.get(SIZE).equals("1")) {
					if (!signal.get(OUT_PORT).equals("")) {
						return "wire " + connection.source.label + "_" + connection.sourcePort.label + "_" + signal.get(OUT_PORT ) + "_broadcast;";
					} else {		
						return "wire " + connection.source.label + "_" + connection.sourcePort.label + "_broadcast;";
					}
				}
			}	
		return "";
	}
	
	def verifyNative(String[] signal, Port port) {
		return !(port.isNative()) || (port.isNative() && isNative(signal));
	}
	
	def isNative(String[] signal) {
		return signal.get(IS_NATIVE).equals("not_sync");
	}
	
	def getSize(String[] signal, Port port) {
		if(port!=null)
			if(signal.get(SIZE).equals("bufferSize"))
				return port.type.sizeInBits;
		return Integer.parseInt(signal.get(SIZE));
	}
	
	def printInterface(List<SboxLut> luts) {
		
		'''
		module multi_dataflow(
			«FOR input : network.inputs»«FOR signal : signals»
			«input.label»«IF !signal.get(IN_PORT).equals("")»_«signal.get(IN_PORT)»«ENDIF»,
			«ENDFOR»
			«ENDFOR»
			«FOR output : network.outputs»
			«FOR signal : signals»
			«output.label»«IF !signal.get(OUT_PORT).equals("")»_«signal.get(OUT_PORT)»«ENDIF»,
			«ENDFOR»		
			«ENDFOR»
			«FOR extSignal : extSignals»
			«extSignal.get(PORT)»,
			«ENDFOR»
			«IF !luts.empty»
			ID,
			«ENDIF»
			«IF enablePowerGating»
			«FOR lr: powerSets»
			iso_en«clockDomainsIndex.get(lr)»,
			«IF logicRegionsSeqMap.get(lr)»
			rstr_en«clockDomainsIndex.get(lr)»,
			save_en«clockDomainsIndex.get(lr)»,
			«ENDIF»
			pw_switch_en«clockDomainsIndex.get(lr)»,
			
			«ENDFOR»
			«ENDIF»			
			«clockSignal»	
		);	
		'''
	}
	
	
	def String getSboxSize(Actor actor) {
		return String.valueOf(actor.getInputs().get(0).getType().getSizeInBits());
	}
	
	def String getSboxType(Actor actor) {
		return actor.getAttribute("type").getStringValue();
	}
	
	def String getSboxSelID(Actor actor) {
		return (actor.getSimpleName().split("_")).get(1);
	}
	
	
	def printNetwork(Network network, List<SboxLut> luts,
		 Map<String,Set<String>> clockSets, 
		 boolean enableClockGating,
		 boolean enablePowerGating,
		 List<String[]> extSignals,
		 List<String[]> signals, 
		 String clockSignal, 
		 Map<String,Set<String>> logicRegions, 
		 Map<String,Set<String>> netRegions,
		 Set<String> powerSets,
		 Map<String,Integer> powerSetsIndex,
		 Map<String,Boolean> logicRegionsSeqMap){
		this.extSignals = extSignals;
		this.signals = signals;
		this.combSignals = computeCombSignals(signals);
		this.seqSignals = computeSeqSignals(signals);
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
		computeNetworkInputPortFanout(network);
		computeActorOutputPortFanout(network);
		computeNetworkClockDomains(network,clockSets);
		//
		
		//findSharedRegion();
		
		'''
		«headerComments()»
		«printClockInformation()»
		// ----------------------------------------------------------------------------
		// Module Interface
		// ----------------------------------------------------------------------------
		«printInterface(luts)»
		// ----------------------------------------------------------------------------
		
		// ----------------------------------------------------------------------------
		// Module Parameters
		// ----------------------------------------------------------------------------
		// ----------------------------------------------------------------------------
		
		// ----------------------------------------------------------------------------
		// Module Signals
		// ----------------------------------------------------------------------------
		«printIOSignals(luts)»
«««		«printInternalSignals(luts,clockSets.size)»
		«printInternalSignals(luts)»
		// ----------------------------------------------------------------------------
		
		// ----------------------------------------------------------------------------
		// Module Body
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
		// ----------------------------------------------------------------------------
		endmodule
		// ----------------------------------------------------------------------------
		// ----------------------------------------------------------------------------
		// ----------------------------------------------------------------------------
		'''
	}
	
	def computeSeqSignals(List<String[]> signals) {
		var seqSignals = new ArrayList<String[]>()
		for(String[] signal : signals) {
			if(!isNative(signal)) {
				seqSignals.add(signal);
			}
		}
		return seqSignals;
	}
	
	def computeCombSignals(List<String[]> signals) {
		var combSignals = new ArrayList<String[]>()
		for(String[] signal : signals) {
			if(isNative(signal)) {
				combSignals.add(signal);
			}
		}
		return combSignals;
	}
	
	
	
}