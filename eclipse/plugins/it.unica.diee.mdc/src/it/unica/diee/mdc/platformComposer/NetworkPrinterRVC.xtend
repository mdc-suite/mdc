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
import it.unica.diee.mdc.sboxManagement.SboxLutimport net.sf.orcc.util.OrccLogger

import net.sf.orcc.util.OrccLogger

/**
 * A VHDL RVC-CAL FIFO-based Protocol Network printer
 * 
 * @author Carlo Sau
 */
class NetworkPrinterRVC {
	
	static var String DEFAULT_LOGIC_REGION = "DEFAULT";
	
	var Network network;
	
	var boolean lrEn;
	var String lrPowerSaving;
		
	var Map<String,Object> options
	
	var Map<String,String> clockDomainsMap;
	
	/**
	 * Map which contains the Clock Domain of a port
	 */
	var Map<Port, String> portLogicRegion;

	/**
	 * Map which contains the Clock Domain of an instance
	 */
	var Map<Actor, String> instanceLogicRegion;

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

	var Map<String, Integer> logicRegionsID;

	
	/**
	 * Count the fanout of the actor's output port
	 * 
	 * @param network
	 */
	 
	var Map<String,String> clockDomainsID;
	
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
	
	def computeClockDomainsMap(Network network, Map<String,Set<String>> clockDomains) {
		
		var maxFreqRatio = 100.0;
		var clockDomainID = 0;
		
		for(String domain : clockDomains.keySet()){
			
			for(String actor : clockDomains.get(domain)) {
				clockDomainsMap.put(actor,domain);
			}
			
			if(Float.parseFloat(domain)<maxFreqRatio) {
				maxFreqRatio = Float.parseFloat(domain);	
			}
			clockDomainsID.put(domain,clockDomainID.toString());
			clockDomainID = clockDomainID+1;
		}
		
		if(maxFreqRatio==100.0) {
			maxFreqRatio=1.0;
			clockDomainsID.put("1.0","DEFAULT");
		}
		
		for(Port input : network.inputs) {
			clockDomainsMap.put(input.name,maxFreqRatio.toString());
		}
		
		for(Port output : network.outputs) {
			clockDomainsMap.put(output.name,maxFreqRatio.toString());
		}
		
		for(Actor actor : network.children.filter(typeof(Actor))){
			if(!clockDomainsMap.containsKey(actor.name)) {
				clockDomainsMap.put(actor.name,maxFreqRatio.toString());
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
	
	def Map<String, Integer> getLogicRegionID(){
		return logicRegionsID;
	}
	
	def void computeLogicRegions(Network network,
			 Map<String,Set<String>> logicRegions) {


		// Fill the the portClockDomain with "CLK" for the I/O of the network
		for (Port port : network.getInputs()) {
			portLogicRegion.put(port, DEFAULT_LOGIC_REGION);
		}

		for (Port port : network.getOutputs()) {
			portLogicRegion.put(port, DEFAULT_LOGIC_REGION);
		}

		// For each instance on the network give the clock domain specified by
		// the mapping configuration tab or if not give the default clock domain
		var int logicRegionID = 0;
		logicRegionsID.put(DEFAULT_LOGIC_REGION, logicRegionID);
		logicRegionID = logicRegionID + 1;

		for (String clkId : logicRegions.keySet()) {
			logicRegionsID.put(clkId.toString(), logicRegionID);
			logicRegionID = logicRegionID + 1;
		}

		for (Vertex vertex : network.getVertices()) {
			if (vertex instanceof Actor) {
				var Actor actor = vertex as Actor;
				if (!logicRegions.isEmpty()) {
					for(String lrID : logicRegions.keySet()) {
						for(String instance : logicRegions.get(lrID)){						
							if (instance.equals(actor.getName())) {
								var String id = lrID.toString();
								instanceLogicRegion.put(actor, id);
							} else if (!instanceLogicRegion.containsKey(actor)) {
								instanceLogicRegion.put(actor, DEFAULT_LOGIC_REGION);
							}
						}
					}
				} else {
					instanceLogicRegion.put(actor, DEFAULT_LOGIC_REGION);
				}
			}
		}
					
	}
	
	def headerComments(){
		var dateFormat = new SimpleDateFormat("yyyy/MM/dd HH:mm:ss");
		var date = new Date();
		'''

		-- ----------------------------------------------------------------------------
		-- Multi-Dataflow Composer - Platform Composer
		-- Network: « network.simpleName» 
		-- Date: «dateFormat.format(date)»
		-- ----------------------------------------------------------------------------
		'''	
	}
	
	def printClockInformation(){
		'''
		-- ----------------------------------------------------------------------------
		-- Information about the Network "«network.simpleName»"
		-- Clock Domains:
		«FOR freqRatio : clockDomainsID.keySet»
		-- 		clockDomainID=«clockDomainsID.get(freqRatio)» periodRatio=«freqRatio» (ms/ms_max)
		«ENDFOR»
		--
		-- Logic Regions:
		«FOR ID : logicRegionsID.keySet»
		--		logicRegionID=«ID» logicRegion=«logicRegionsID.get(ID)»
		«ENDFOR»
		«IF lrEn»-- Selected Power Saving Technique for Logic Regions: «lrPowerSaving»«ENDIF»
		--
		-- Summary [clockDomainID,logicRegionID]:
		-- Network input port(s):
		«FOR port: network.inputs»
			--	«port.name» --> [«clockDomainsID.get(clockDomainsMap.get(port.name))»,«portLogicRegion.get(port)»]
		«ENDFOR»
		-- Network output port(s):
		«FOR port: network.outputs»
			-- 	«port.name» --> [«clockDomainsID.get(clockDomainsMap.get(port.name))»,«portLogicRegion.get(port)»]
		«ENDFOR»
		-- Actor(s):
		«FOR vertex: network.vertices»
			«IF vertex instanceof Actor»
				«IF !(isSbox(vertex)||isOnlyCal(vertex.getAdapter(typeof(Actor))))»
					--	«(vertex as Actor).simpleName» --> [«clockDomainsID.get(clockDomainsMap.get(vertex.label))»,«instanceLogicRegion.get(vertex as Actor)»]
				«ENDIF»
			«ENDIF»
		«ENDFOR»
		'''
	}
	
	def printLibrary(){
		var Boolean systemActors = false;
		for(Actor actor: network.children.filter(typeof(Actor))){
			if (actor.native){
				systemActors = true;
			}
		}
		'''
		library ieee;
		library SystemBuilder;
		library SystemMdc;
		
		use ieee.std_logic_1164.all;
		'''
	}
	
	def printEntity(){
		'''
		entity «network.simpleName» is
		port(
			 -- XDF Network Input(s)
			 «FOR port: network.inputs»
			 	«addDeclarationPort(port,"in","out",true)»
			 «ENDFOR»
			 -- XDF Network Output(s)
			 «FOR port: network.outputs»
			 	«addDeclarationPort(port,"out","in",true)»
			 «ENDFOR»
			 -- Multi-Dataflow config ID
			 ID : in std_logic_vector(7 downto 0);
			 -- Clock(s) and Reset
			 CLK : in std_logic«IF !clockDomainsID.empty»_vector(«clockDomainsID.size  - 1» downto 0)«ENDIF»;
			 RESET : in std_logic);
		end entity «network.simpleName»;
		'''
		
	}
	
	def addDeclarationPort(Port port, String dirA, String dirB, Boolean printRdy){
		'''
		«IF port.type.bool || port.type.sizeInBits == 1»
		«port.name»_data : «dirA» std_logic;
		«ELSE»
		«port.name»_data : «dirA» std_logic_vector(«port.type.sizeInBits - 1» downto 0);
		«ENDIF»
		«port.name»_send : «dirA» std_logic;
		«port.name»_ack : «dirB» std_logic;
		«IF printRdy»
		«port.name»_rdy : «dirB» std_logic;
		«ENDIF»
		«port.name»_count : «dirA» std_logic_vector(15 downto 0);
		'''
	}
	
	def printArchitecture(List<SboxLut> luts){
		'''
		architecture rtl of «network.simpleName» is
			-- --------------------------------------------------------------------------
			-- Internal Signals
			-- --------------------------------------------------------------------------
		
			-- Clock(s) and Reset(s) signal
			«FOR domainID : clockDomainsID.values»
			signal clocks«getClockDomainLabel(domainID)»: std_logic_vector(«logicRegionsID.size  - 1» downto 0);
			signal resets«getClockDomainLabel(domainID)»: std_logic_vector(«logicRegionsID.size  - 1» downto 0);
			«IF lrEn && lrPowerSaving=="CLOCK_GATING"»signal clocks«getClockDomainLabel(domainID)»_en: std_logic_vector(«logicRegionsID.size  - 1» downto 0);«ENDIF»
			«ENDFOR»

			
			-- Switching Boxes Selector signal
			signal sel : std_logic_vector(«luts.size  - 1» downto 0);
		
			-- Network Input Port(s)
			«FOR port: network.inputs»
				«printSignal(port,"","ni",0,true)»
			«ENDFOR»
			
			-- Network Input Port Fanout(s)
			«FOR port: network.inputs»
				«printSignal(port,"","nif",networkPortFanout.get(port),true)»
			«ENDFOR»
			
			-- Network Output Port(s) 
			«FOR port: network.outputs»
				«printSignal(port,"","no",0,true)»
			«ENDFOR»
			
			-- Actors Input/Output and Output fanout signals
			«FOR actor: network.children.filter(typeof(Actor)) SEPARATOR "\n"»
				«IF !isOnlyCal(actor)»
					«IF !isSbox(actor)»
						«FOR port: actor.inputs SEPARATOR "\n"»
							«printSignal(port,actor.simpleName+"_","ai",0,false)»
						«ENDFOR»
					«ELSEIF isSbox2x1(actor)»
						«FOR port: actor.inputs SEPARATOR "\n"»
							«printSignal(port,actor.simpleName+"_","ai",0,false)»
						«ENDFOR»
					«ENDIF»
					«FOR port: actor.outputs SEPARATOR "\n"»
						«IF !isSbox2x1(actor)»
							«printSignal(port,actor.simpleName+"_","ao",0,true)»
							«OrccLogger.traceln(port + " " + actor + " " + actor.getAdapter((typeof(Entity))))»
							«printSignal(port,actor.simpleName+"_","aof",actor.getAdapter((typeof(Entity))).getOutgoingPortMap().get(port).size,true)»
						«ENDIF»
					«ENDFOR»
				«ENDIF»
			«ENDFOR»
					
			-- --------------------------------------------------------------------------
			-- Network Instances
			-- --------------------------------------------------------------------------
			«printArchitectureComponents(luts)»
		
		begin
			-- Reset Controller(s)
			«FOR domainID : clockDomainsID.values»
			rcon«getClockDomainLabel(domainID)»: entity SystemBuilder.resetController(behavioral)
			generic map(count => «logicRegionsID.size»)
			port map( 
			         clocks => clocks«getClockDomainLabel(domainID)», 
			         reset_in => reset, 
			         resets => resets«getClockDomainLabel(domainID)»);
			         
			«ENDFOR»
			
			-- config_«network.simpleName»
			i_configurator : component configurator
			port map(
			-- Instance config_«network.simpleName» Input
			ID => ID,
			-- Instance config_«network.simpleName» Output(s)
			sel => sel);
			
			«IF !(lrEn && lrPowerSaving=="CLOCK_GATING")»
			«FOR domainID : clockDomainsID.values»
			clocks«getClockDomainLabel(domainID)»(0) <= CLK(«getClockDomainIndex(domainID)»);
			«ENDFOR»
			«ELSE»
			-- Enable Generator(s)
			«FOR domainID : clockDomainsID.values»
			i_enable_generator«getClockDomainLabel(domainID)»: component enable_generator
			port map( 
				clocks_en => clocks«getClockDomainLabel(domainID)»_en,
				clock_in => CLK(«getClockDomainIndex(domainID)»),
				ID => ID);
				
			«ENDFOR»
			
			-- Clock Gates
			«FOR domainID : clockDomainsID.values»
			clk_gates«getClockDomainLabel(domainID)»: entity SystemMdc.clk_gates(behavioral)
			generic map(
				count => «logicRegionsID.size»)
			port map(
				clocks => clocks«getClockDomainLabel(domainID)»,
				clocks_en => clocks«getClockDomainLabel(domainID)»_en,
				clock_in => CLK(«getClockDomainIndex(domainID)»));
				
			«ENDFOR»
		«ENDIF»
		
			-- --------------------------------------------------------------------------
			-- Actor instances
			-- --------------------------------------------------------------------------
			«printInstanceConnection(luts)»
			
			-- --------------------------------------------------------------------------
			-- Nework Input Fanouts
			-- --------------------------------------------------------------------------
			«FOR port: network.inputs»
				«addFannout(port, "ni", "nif", null)»
			«ENDFOR»
		
			-- --------------------------------------------------------------------------
			-- Actor Output Fanouts
			-- --------------------------------------------------------------------------
			«FOR actor: network.children.filter(typeof(Actor)) SEPARATOR "\n"»
				«FOR port: actor.getAdapter((typeof(Entity))).getOutgoingPortMap().keySet»
					«IF !isSbox2x1(actor)»
						«addFannout(port, "ao", "aof", actor)»
					«ENDIF»
				«ENDFOR»		
			«ENDFOR»
		
			-- --------------------------------------------------------------------------
			-- Queues
			-- --------------------------------------------------------------------------
			«FOR connection: network.connections SEPARATOR "\n"»
				«IF connection.source instanceof Port»
					«IF connection.target instanceof Actor»
						«IF !(isSbox(connection.target)||isOnlyCal(connection.target.getAdapter(typeof(Actor))))»
							«addQueue(connection.source as Port, connection.targetPort, null, connection.target as Actor, connection, "ai", "nif")»
						«ELSEIF isSbox2x1(connection.target.getAdapter(typeof(Actor)))»
							«addQueue(connection.source as Port, connection.targetPort, null, connection.target as Actor, connection, "ai", "nif")»
						«ENDIF»		
					«ENDIF»
				«ELSEIF connection.source instanceof Actor»
					«IF connection.target instanceof Port»
						«IF !isSbox2x1(connection.source)»
							«addQueue(connection.sourcePort, connection.target as Port, connection.source as Actor, null, connection, "no", "aof")»
						«ENDIF»
					«ELSEIF connection.target instanceof Actor»
						«IF !(isSbox(connection.target.getAdapter(typeof(Actor)))||isOnlyCal(connection.target.getAdapter(typeof(Actor))))»
							«IF !isSbox2x1(connection.source.getAdapter(typeof(Actor)))»
								«addQueue(connection.sourcePort, connection.targetPort, connection.source as Actor, connection.target as Actor, connection, "ai", "aof")»
							«ENDIF»
						«ELSEIF isSbox2x1(connection.target.getAdapter(typeof(Actor)))»
							«IF !isSbox2x1(connection.source.getAdapter(typeof(Actor)))»
								«addQueue(connection.sourcePort as Port, connection.targetPort, connection.source as Actor, connection.target as Actor, connection, "ai", "aof")»
							«ENDIF»
						«ENDIF»
					«ENDIF»
				«ENDIF»
			«ENDFOR»
		
			-- --------------------------------------------------------------------------
			-- Network port(s) instantiation
			-- --------------------------------------------------------------------------
			
			-- Output Port(s) Instantiation
			«FOR port: network.outputs»
				«port.name»_data <= no_«port.name»_data;
				«port.name»_send <= no_«port.name»_send;
				no_«port.name»_ack <= «port.name»_ack;
				no_«port.name»_rdy <= «port.name»_rdy;
				«port.name»_count <= no_«port.name»_count;
			«ENDFOR»
			
			-- Input Port(s) Instantiation
			«FOR port: network.inputs»
				ni_«port.name»_data <= «port.name»_data;
				ni_«port.name»_send <= «port.name»_send;
				«port.name»_ack <= ni_«port.name»_ack;
				«port.name»_rdy <= ni_«port.name»_rdy;
				ni_«port.name»_count <= «port.name»_count;
			«ENDFOR»
		end architecture rtl;
		'''
	}
	
	def String getClockDomainLabel(String domainID) {
		if(domainID.equals("DEFAULT")) {
			return "";
		} else {
			return domainID;
		}
	}
	
	def String getClockDomainIndex(String domainID) {
		if(domainID.equals("DEFAULT")) {
			return "0";
		} else {
			return domainID;
		}
	}
	
	
	def printSignal(Port port, String owner, String prefix, Integer fanout, Boolean printRdy){
		var String dataSize;
		if(port.type.bool || (port.type.sizeInBits == 1)){
			dataSize = "std_logic";
		}else{
			dataSize = "std_logic_vector("+(port.type.sizeInBits - 1)+" downto 0)";
		}
		var String fanoutSize;
		if(fanout == 0){
			fanoutSize = "std_logic";
		}else{
			fanoutSize = "std_logic_vector("+(fanout - 1)+" downto 0)";
		}
		'''
		«IF port.native»
			signal «port.name»_data : «dataSize»;
		«ELSE»
			signal «prefix»_«owner»«port.name»_data : «dataSize»;
			signal «prefix»_«owner»«port.name»_send : «fanoutSize»;
			signal «prefix»_«owner»«port.name»_ack : «fanoutSize»;
			«IF printRdy»signal «prefix»_«owner»«port.name»_rdy : «fanoutSize»;«ENDIF»
			signal «prefix»_«owner»«port.name»_count : std_logic_vector(15 downto 0);
		«ENDIF»
		'''
	}
	
	def printDoubleQueueSignal(Port port, String owner, String prefix,Integer fanout){
		var String fanoutSize;
		if(fanout == 1){
			fanoutSize = "std_logic";
		}else{
			fanoutSize = "std_logic_vector("+(fanout - 1)+" downto 0)";
		}
		'''
		signal «owner»«port.name»_full :  «fanoutSize»;
		signal «owner»«port.name»_almost_full :  «fanoutSize»;
		'''
	}
	
	def printArchitectureComponents(List<SboxLut> luts){
		'''
		component configurator is
		port(
			 -- Instance cfg_«network.simpleName» Input
		 	 ID : in std_logic_vector(7 downto 0);
			 -- Instance config_«network.simpleName» Output(s)
			 sel : out std_logic_vector(«luts.size - 1» downto 0));
		end component configurator;
		
				
		«IF lrEn && lrPowerSaving=="CLOCK_GATING"»
		component enable_generator is
		port(
			 -- Instance enable_generator Inputs
		 	 ID : in std_logic_vector(7 downto 0);
		 	 clock_in : in std_logic;
			 -- Instance enable generator Output(s)
			 clocks_en : out std_logic_vector(«logicRegionsID.size-1» downto 0));
		end component enable_generator;
		«ENDIF»
		
		«FOR actor: network.children.filter(typeof(Actor)) SEPARATOR "\n"»
			«IF !(actor.native || isSbox(actor) ||isOnlyCal(actor))»
				component «actor.simpleName» is
				port(
				     -- Instance «actor.simpleName» Input(s)
				     «FOR port: actor.inputs»
				     	«addDeclarationPort(port,"in","out", false)»
				     «ENDFOR»
				     -- Instance «actor.simpleName» Output(s)
				     «FOR port: actor.outputs»
				     	«addDeclarationPort(port,"out","in", true)»
				     «ENDFOR»
				     clk: in std_logic;
				     reset: in std_logic);
				end component «actor.simpleName»;

			«ENDIF»
		«ENDFOR»
		'''
	}
	
	def printLogicOrVector(Integer fanout){
			var String fanoutSize;
		if(fanout == 1){
			fanoutSize = "std_logic";
		}else{
			fanoutSize = "std_logic_vector("+(fanout - 1)+" downto 0)";
		}
		'''«fanoutSize»'''
	}
	
	
	def printInstanceConnection(List<SboxLut> luts){
		'''
		«FOR actor: network.children.filter(typeof(Actor)) SEPARATOR "\n"»
			«IF !isOnlyCal(actor)»
				«IF actor.native»
					«IF isSbox(actor)»
					i_«actor.simpleName» : entity SystemMdc.Sbox«getSboxType(actor)»int(behavioral)
					generic map(
						size => «getSboxSize(actor)»)
					«ELSE»
					-- «actor.simpleName» (System Actor)
					i_«actor.simpleName» : entity SystemActors.«actor.simpleName»(behavioral)
						«IF !actor.parameters.empty»
						generic map(
							-- Not currently supported
						)
						«ENDIF»
					«ENDIF»
				«ELSE»
					i_«actor.simpleName» : component «actor.simpleName»
				«ENDIF»
				port map(
					-- Instance «actor.simpleName» Input(s)
					«IF isSbox(actor)»
						«FOR connection : network.connections»
							«IF connection.target.equals(actor)»
								«IF !connection.targetPort.native»
									«IF connection.source instanceof Actor»
										«IF !isSbox2x1(actor)»
											«addSignalConnection(connection.source.getAdapter(typeof(Actor)), connection.sourcePort, "aof", connection.targetPort.name, false, networkPortConnectionFanout.get(connection), true)»
										«ELSEIF !isSbox2x1(connection.source.getAdapter(typeof(Actor)))»
											«addSignalConnection(actor, connection.targetPort, "ai", "In", true, null, false)»
										«ELSE»
											«addSignalConnection(actor, connection.targetPort, "ai", "In", true, null, false)»
										«ENDIF»
									«ELSE»
										«IF !isSbox2x1(actor)»
											«addSignalConnection(null, connection.source.getAdapter(typeof(Port)), "nif", connection.targetPort.name, false, networkPortConnectionFanout.get(connection), true)»
										«ELSE»
											«addSignalConnection(actor, connection.targetPort, "ai", "In", true, null, false)»
										«ENDIF»
									«ENDIF»
								«ENDIF»
							«ENDIF»
						«ENDFOR»
					«ELSE»
						«FOR port: actor.inputs SEPARATOR "\n"»
							«addSignalConnection(actor, port, "ai", "In", true, null, false)»
						«ENDFOR»
					«ENDIF»
					-- Instance «actor.simpleName» Output(s)
					«FOR port: actor.outputs SEPARATOR "\n"»
						«IF isSbox2x1(actor)»
							«FOR connection : network.connections»
								«IF connection.source.equals(actor)»
									«IF connection.target instanceof Actor»
										«addSignalConnection(connection.target.getAdapter(typeof(Actor)),connection.targetPort,"ai", connection.sourcePort.name, false, null, true)»
									«ELSE»
										«addSignalConnection(null,connection.target.getAdapter(typeof(Port)),"no", connection.sourcePort.name, false, null, true)»
									«ENDIF»
								«ENDIF»
							«ENDFOR»
						«ELSE»
							«addSignalConnection(actor, port, "ao", "Out", true, null, true)»
						«ENDIF»
					«ENDFOR»
				    «IF isSbox(actor)»
				    -- Instance «actor.simpleName» Selector
				    sel => sel(«getSboxSelID(actor)»));
					«ELSE»
				    -- Clock and Reset
				    clk => clocks«getClockDomainLabel(clockDomainsID.get(clockDomainsMap.get(actor.name)))»(«logicRegionsID.get(instanceLogicRegion.get(actor))»),
				    reset => resets«getClockDomainLabel(clockDomainsID.get(clockDomainsMap.get(actor.name)))»(«logicRegionsID.get(instanceLogicRegion.get(actor))»));
					«ENDIF»
			«ENDIF»
		«ENDFOR»
		'''
	}
	
	def String getSboxSize(Actor actor) {
		return String.valueOf(actor.getInputs().get(0).getType().getSizeInBits());
	}
	
	def String getSboxType(Actor actor) {
		return actor.getAttribute("type").getStringValue();
	}
	
	def boolean isSbox(Vertex vertex) {
		var Actor actor = vertex.getAdapter(typeof(Actor))
		if(actor != null) {
			return isSbox(actor)
		}
		return false
	}
	
	def boolean isSbox(Actor actor) {
		return actor.hasAttribute("sbox")
	}
	
	def boolean isSbox2x1(Vertex vertex) {
		var actor = vertex.getAdapter(typeof(Actor))
		return isSbox2x1(actor)
	}
	
	def boolean isSbox1x2(Vertex vertex) {
		var actor = vertex.getAdapter(typeof(Actor))
		return isSbox1x2(actor)
	}
	
	def boolean isSbox2x1(Actor actor) {
		if(actor != null) {
			if(isSbox(actor)) {
				if(actor.getAttribute("type").getStringValue().equals("2x1"))
					return true
			}
		}
		return false
	}
	
	def boolean isSbox1x2(Actor actor) {
		if(actor != null) {
			if(isSbox(actor)) {
				if(actor.getAttribute("type").getStringValue().equals("1x2"))
					return true
			}
		}
		return false
	}
	
	def boolean isOnlyCal(Actor actor) {
		if(actor != null) {
			return actor.hasAttribute("only_cal")
		}
		return false
	}
	
	def String getSboxSelID(Actor actor) {
		return (actor.getSimpleName().split("_")).get(1);
	}
	
	def addSignalConnection(Actor actor, Port port, String prefix, String dir, Boolean instConnection, Integer fanoutIndex, Boolean printRdy){
		var String owner = "";
		var String fanoutIndexString = "";
		if(actor != null){
			owner = actor.simpleName+"_";
		}
		if(fanoutIndex != null){
			fanoutIndexString = "("+fanoutIndex+")";
		}
		var String boolType = "";
		if((port.type.bool || (port.type.sizeInBits == 1)) && !instConnection){
			boolType = "(0)";
		}
		
		'''
		«IF port.native»
			«port.name»_data => «prefix»_«actor.simpleName»_«port.name»_data
		«ELSE»
			«IF instConnection»«port.name»«ELSE»«dir»«ENDIF»_data«boolType» => «prefix»_«owner»«port.name»_data,
			«IF instConnection»«port.name»«ELSE»«dir»«ENDIF»_send => «prefix»_«owner»«port.name»_send«fanoutIndexString»,
			«IF instConnection»«port.name»«ELSE»«dir»«ENDIF»_ack => «prefix»_«owner»«port.name»_ack«fanoutIndexString»,
			«IF printRdy»
				«IF instConnection»«port.name»«ELSE»«dir»«ENDIF»_rdy => «IF dir.equals("out1") && actor!=null»'0'«ELSE»«prefix»_«owner»«port.name»_rdy«fanoutIndexString»«ENDIF»,
			«ENDIF»
			«IF instConnection»«port.name»«ELSE»«dir»«ENDIF»_count => «prefix»_«owner»«port.name»_count,
		«ENDIF»
		'''
	}

	def addFannout(Port port, String prefixIn, String prefixOut, Actor actor){
		var Integer fanoutDegree = 1;
		var String instanceName = "";
		if(actor != null){
			// Actor Output port fanout
			fanoutDegree = actor.getAdapter((typeof(Entity))).getOutgoingPortMap().get(port).size;
			instanceName = actor.simpleName + "_";
		}else{
			// Network Input port fanout
			fanoutDegree = networkPortFanout.get(port);
		}
		var Integer lrIndx = 0;
		var String cdIndx = "";
		if(actor != null){
			lrIndx = logicRegionsID.get(instanceLogicRegion.get(actor));
			if(!clockDomainsID.empty) {
				cdIndx = cdIndx + getClockDomainLabel((clockDomainsID.get(clockDomainsMap.get(actor.name))));
			}
		}else{
			lrIndx = logicRegionsID.get(portLogicRegion.get(port));
			if(!clockDomainsID.empty) {
				cdIndx = cdIndx + getClockDomainLabel(clockDomainsID.get(clockDomainsMap.get(port.name)));
			}
		}
		'''
		f_«prefixIn»_«instanceName»«port.name» : entity SystemBuilder.Fanout(behavioral)
		generic map (fanout => «fanoutDegree», width => «port.type.sizeInBits»)
		port map(
			-- Fanout In
			«addSignalConnection(actor, port, prefixIn,"In", false, null, true)»
			-- Fanout Out
			«addSignalConnection(actor, port, prefixOut,"Out", false, null, true)»
			-- Clock & Reset
			clk => clocks«cdIndx»(«lrIndx»),
			reset => resets«cdIndx»(«lrIndx»));
		'''
	}
	
	def addQueue(Port srcPort, Port tgtPort, Actor srcInstance, Actor tgtInstance, Connection connection, String prefixIn, String prefixOut){
		var Integer fifoSize = 64;
		if(!prefixIn.equals("no") && connection.size != null){
			fifoSize = connection.size;
		}
		var Integer lrIndx = 0
		var String cdWrIndx = ""
		var String cdRdIndx = ""
		var boolean async_queues = false;
		
		if(srcInstance != null) {
			if(!clockDomainsID.empty) {
				if(isSbox1x2(srcInstance)) {
					cdWrIndx = findSourceDomain(srcInstance)
				} else {
					cdWrIndx = getClockDomainLabel(clockDomainsID.get(clockDomainsMap.get(srcInstance.name)))		
				}	
			}
		}else{
			if(!clockDomainsID.empty) {
				cdWrIndx = getClockDomainLabel(clockDomainsID.get(clockDomainsMap.get(srcPort.name)))
			}
		}
		if(tgtInstance != null){
			if(isSbox2x1(tgtInstance)) {
				lrIndx = findTargetRegion(tgtInstance)
			} else {
				lrIndx = logicRegionsID.get(instanceLogicRegion.get(tgtInstance));
			}
			if(!clockDomainsID.empty) {
				if(isSbox2x1(tgtInstance)) {
					cdRdIndx = findTargetDomain(tgtInstance)
				} else {
					cdRdIndx = getClockDomainLabel(clockDomainsID.get(clockDomainsMap.get(tgtInstance.name)))
				}
			}
		}else{
			lrIndx = logicRegionsID.get(portLogicRegion.get(tgtPort));
			if(!clockDomainsID.empty) {
				cdRdIndx = getClockDomainLabel(clockDomainsID.get(clockDomainsMap.get(tgtPort.name)))
			}
		}
		var String queueType = "Queue";
		if ((!clockDomainsID.empty && cdWrIndx!=cdRdIndx)||async_queues){
			queueType = "Queue_Async";
		}
		'''
		q_«prefixIn»_«IF tgtInstance !=null»«tgtInstance.simpleName»_«ENDIF»«tgtPort.name» : entity SystemBuilder.«queueType»(behavioral)
		generic map (length => «fifoSize», width => «tgtPort.type.sizeInBits»)
		port map(
			-- Queue Out
			«addSignalConnection(tgtInstance, tgtPort, prefixIn,"Out", false, null, false)»
			-- Queue In
			«addSignalConnection(srcInstance, srcPort, prefixOut,"In", false, networkPortConnectionFanout.get(connection), true)»
			-- Clock & Reset
			«IF !clockDomainsID.empty && ((cdWrIndx!=cdRdIndx)||async_queues)»
				clk_i => clocks«cdWrIndx»(«lrIndx»),
				reset_i => resets«cdWrIndx»(«lrIndx»),
				clk_o => clocks«cdRdIndx»(«lrIndx»),
				reset_o => resets«cdRdIndx»(«lrIndx»)
			«ELSE»		
				clk => clocks«cdWrIndx»(«lrIndx»),
				reset => resets«cdWrIndx»(«lrIndx»)
			«ENDIF»
		);
		'''
	}
	
	def int findTargetRegion(Actor actor) {
		var Actor target = actor.outgoingPortMap.get(actor.getPort("out1")).get(0).target.getAdapter(typeof(Actor));
		if(target != null) {
			return logicRegionsID.get(instanceLogicRegion.get(target))
		} else { 
			return logicRegionsID.get(DEFAULT_LOGIC_REGION)
		}
	}
	
	def String findSourceDomain(Actor actor) {
		var Vertex source = actor.incomingPortMap.get(actor.getPort("in1")).source;
		if(source.getAdapter(typeof(Actor)) != null) {
			return getClockDomainLabel(clockDomainsID.get(clockDomainsMap.get(source.getAdapter(typeof(Actor)).name)))	
		} else {
			return getClockDomainLabel(clockDomainsID.get(clockDomainsMap.get(source.getAdapter(typeof(Port)).name)))	
		}
		
	}
	
	def String findTargetDomain(Actor actor) {
		var Vertex target = actor.outgoingPortMap.get(actor.getPort("out1")).get(0).target;
		if(target.getAdapter(typeof(Actor)) != null) {
			return getClockDomainLabel(clockDomainsID.get(clockDomainsMap.get(target.getAdapter(typeof(Actor)).name)))
		} else {
			return getClockDomainLabel(clockDomainsID.get(clockDomainsMap.get(target.getAdapter(typeof(Port)).name)))
		}
	}
	
	def printNetwork(Network network, List<SboxLut> luts, Map<String,Object> options, Map<String,Set<String>> logicRegions, 
		Map<String,Set<String>> clockDomains){
			
		// Initialize members
		this.network = network; 
		this.options = options;
		
		// Compute Fanouts
		networkPortFanout = new HashMap<Port, Integer>();
		networkPortConnectionFanout = new HashMap<Connection, Integer>();
		computeNetworkInputPortFanout(network);
		computeActorOutputPortFanout(network);
		
		// Compute Logic Regions
		portLogicRegion = new HashMap<Port, String>();
		instanceLogicRegion = new HashMap<Actor, String>();
		logicRegionsID = new HashMap<String, Integer>();
		computeLogicRegions(network,logicRegions);
		lrEn = options.get("it.unica.diee.mdc.computeLogicRegions") as Boolean;
		lrPowerSaving = options.get("it.unica.diee.mdc.lrPowerSaving") as String;
		
		// Compute Clock Domains
		clockDomainsMap = new HashMap<String,String>();
		clockDomainsID = new HashMap<String,String>();
		computeClockDomainsMap(network,clockDomains); 
		'''
		«headerComments()»
		
		«printClockInformation()»
		
		«printLibrary()»
		
		-- ----------------------------------------------------------------------------
		-- Entity Declaration
		-- ----------------------------------------------------------------------------
		«printEntity()»
		
		-- ----------------------------------------------------------------------------
		-- Architecture Declaration
		-- ----------------------------------------------------------------------------
		«printArchitecture(luts)»
		-- ----------------------------------------------------------------------------
		-- ----------------------------------------------------------------------------
		-- ----------------------------------------------------------------------------
		'''
	}
	
	
	
}