package it.mdc.tool.utility;

import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import net.sf.orcc.df.Actor;
import net.sf.orcc.df.Argument;
import net.sf.orcc.df.DfFactory;
import net.sf.orcc.df.Instance;
import net.sf.orcc.df.Network;
import net.sf.orcc.df.Port;
import net.sf.orcc.util.Attribute;
import net.sf.orcc.graph.Edge;
import net.sf.orcc.graph.Vertex;
import net.sf.orcc.util.OrccLogger;
import it.mdc.tool.core.multiDataflowGenerator.ActorManager;
import it.mdc.tool.core.multiDataflowGenerator.Matcher;
import it.mdc.tool.core.multiDataflowGenerator.Unifier;
import it.mdc.tool.core.sboxManagement.SboxActorManager;
import it.mdc.tool.core.sboxManagement.SboxLut;
import it.mdc.tool.core.sboxManagement.SboxLutManager;
import it.mdc.tool.core.sboxManagement.*;
import net.sf.orcc.graph.visit.BFS;
import net.sf.orcc.ir.IrFactory;
import net.sf.orcc.ir.util.IrUtil;
import net.sf.orcc.df.Connection;

import java.util.LinkedList;

/**
 * 
 * This class implements the merging process of MDC. The merging process can merge
 * multiple networks that share actors and ports by introducing switching box (sbox)
 * actors.
 * 
 * @see it.unica.diee.mdc package
 */
public class NetworkMergerOld {
	
	/**
	 * Result merged network
	 */
	private Network result;
	
	private Boolean presMultInst;
	
	/**
	 * Matcher, unifier and searcher
	 */
	private Matcher matcher;
	private Unifier unifier;
	private SearcherOld searcher;

	/**
	 * Map number of sections of the merged networks
	 */
	private Map<Network,Integer> sectionMap;
	
	/**
	 * List of all sbox LUTs
	 */
	private List<SboxLut> sboxLuts;
	
	/**
	 * Current section of the merging network
	 */
	private int currentSection;
	
	/**
	 * Current merging network
	 */
	private Network currentNetwork;
	
	/**
	 * List of already merged networks
	 */
	private List<Network> mergedNetworks;
	
	/**
	 * Map of the instances for each network
	 */
	private Map<Network,Set<Instance>> networksInstances;
	
	/**
	 * Flag of initial step of the search connection process
	 */
	public static final int INIT_SEARCH = 0;
	
	/**
	 * First predecessor flag
	 */
	public static final int FIRST_PREDECESSOR = 0;

	/**
	 * The port flag values of sbox actors
	 */
	protected final static int INPUT_1 	= 0;
	protected final static int INPUT_2 	= 1;
	protected final static int OUTPUT_1 = 2;
	protected final static int OUTPUT_2 = 3;
	
	/**
	 * Flag value that represent all section of the network
	 */
	public static final int ALL_SECTIONS = 0;
	
	/**
	 * Managers of sbox, LUT and actors
	 */
	private SboxActorManager sboxActorManager;
	private SboxLutManager sboxLutManager;	
	private ActorManager actorManager;
	
	
	/**
	 * Constructor
	 */
	public NetworkMergerOld() {
		mergedNetworks = new ArrayList<Network>();		// instantiating list of already merged networks
		result = DfFactory.eINSTANCE.createNetwork();	// instantiating result network
		sectionMap = new HashMap<Network,Integer>();	// instantiating sections map
		matcher = new Matcher();						// instantiating matcher
		unifier = new Unifier();						// instantiating unifier
		searcher = new SearcherOld(unifier,matcher);		// instantiating unifier
		sboxLuts = new ArrayList<SboxLut>();			// instantiating list of sbox LUTs
		sboxActorManager = new SboxActorManager();
		sboxLutManager = new SboxLutManager();
		actorManager = new ActorManager();
		networksInstances = new HashMap<Network,Set<Instance>>();
		presMultInst = true;
	}

	/**
	 * Add a new actor in the network.
	 * 
	 * @param network
	 * @param actor
	 * @return the network with the actor added
	 */
	public Network addActorNewNetwork(Network network, Actor actor) {
		Instance instance = DfFactory.eINSTANCE.createInstance();
		instance.setEntity(actor);
		network.add((Vertex) instance);
		return network;
	}

	/**
	 * Add a connection in the result network.
	 * 
	 * @param c
	 */
	private void addConnection(Connection c){
		if(c != null){
			result.add(c);
		}
	
	}

	/**
	 * Add a new connection in the network.
	 * 
	 * @param network
	 * @param edge
	 */
	public void addConnectionNetwork(Network network, Edge edge) {
		network.add(edge.getSource(), edge.getTarget());
		return;
	}
	
	/**
	 * Add a list of connections in the result network.
	 * 
	 * @param connections
	 */
	private void addConnections(List<Connection> connections){
		if(!connections.isEmpty())
			for(Connection nextC : connections){
				result.add(nextC);
			}
		connections.removeAll(connections);
	}

	/**
	 * Assign broadcast attribute to the connections of the network
	 * that are part of a broadcast
	 * 
	 * @param network
	 */
	private void assignBroadcastAttribute(Network network) {
		
		boolean isBroadcast = false;
		
		for (Connection connection : network.getConnections()) {
			
			// broadcast flag
			isBroadcast = false;
			
			if(!connection.hasAttribute("broadcast"))
				for(Connection otherConnection : network.getConnections())
					if(!connection.equals(otherConnection))
						if(connection.getSource().equals(otherConnection.getSource())){
							if((connection.getSourcePort() != null) && (otherConnection.getSourcePort() != null)) {		// source is an instance
								if(connection.getSourcePort().equals(otherConnection.getSourcePort())) {
									// connection is broadcast, assigning attribute and setting flag
									otherConnection.setAttribute("broadcast", currentNetwork.getName());
									isBroadcast = true;
								}
							
							} else {																					// source is an input port
								// connection is broadcast, assigning attribute and setting flag
								otherConnection.setAttribute("broadcast", currentNetwork.getName());
								isBroadcast = true;
							}
						}
	
			if(isBroadcast){
				// assigning attribute to the referenced connection
				connection.setAttribute("broadcast", currentNetwork.getName());
			}
		}
	}

	/**
	 * Sarch in the result network all connections between two given vertex and 
	 * return candidate connections that match those connections.
	 * 
	 * @param source
	 * 				the source vertex
	 * @param target
	 * 				the target vertex
	 * @param presMultInst
	 * 				the preserving multiple instances choice signal
	 * @return the list of connection between the source and the target vertex
	 */
	private List<Connection> candidateConnections(Vertex source, Vertex target){
	
		List<Connection> result = new ArrayList<Connection>();
		List<Connection> removables = new ArrayList<Connection>();
		Connection candidate = null;
		
		// source and target are instances
		if ((source.getAdapter(Instance.class) != null) && (target.getAdapter(Instance.class) != null)) {
			for(Connection nextCin : target.getAdapter(Instance.class).getIncomingPortMap().values()){
				if (!presMultInst) {																		// single instance for the same actor
					if(unifier.canUnify(nextCin.getSource(),source)) {
						candidate = DfFactory.eINSTANCE.createConnection(searcher.searchExistingVertex(source,this.result), nextCin.getSourcePort(), 
								searcher.searchExistingVertex(target,this.result), nextCin.getTargetPort());
						for (Attribute attr : nextCin.getAttributes()){
							if(attr.getName().equals("broadcast"))
								candidate.setAttribute("broadcast", attr.getStringValue());
							else
								candidate.setAttribute(attr.getName(), attr.getReferencedValue());
						}
						result.add(candidate);
						removables.add(nextCin);
						}
					} else {																				// multiple instances for the same actor
						if(unifier.canUnifyMultiple(nextCin.getSource(),source)) {
							candidate = DfFactory.eINSTANCE.createConnection(searcher.searchExistingVertexMultiple(source,this.result), nextCin.getSourcePort(), 
									searcher.searchExistingVertexMultiple(target,this.result), nextCin.getTargetPort());
							for (Attribute attr : nextCin.getAttributes()){
								if(attr.getName().equals("broadcast"))
									candidate.setAttribute("broadcast", attr.getStringValue());
								else
									candidate.setAttribute(attr.getName(), attr.getReferencedValue());
							}
							result.add(candidate);
							removables.add(nextCin);
						}
					}
				
			}
		}
		
		// source is a port, target is an instance
		if ((source.getAdapter(Port.class) != null) && (target.getAdapter(Instance.class) != null)) {
			for(Connection nextC : ((Instance) target).getIncomingPortMap().values()) {
						if(!presMultInst) {
							if(unifier.canUnify(nextC.getSource(),source)) {								// single instance for the same actor
							candidate = DfFactory.eINSTANCE.createConnection(searcher.searchExistingVertex(source,this.result), null, 
									searcher.searchExistingVertex(target,this.result), nextC.getTargetPort());
							for (Attribute attr : nextC.getAttributes()){
								if(attr.getName().equals("broadcast"))
									candidate.setAttribute("broadcast", attr.getStringValue());
								else
									candidate.setAttribute(attr.getName(), attr.getReferencedValue());
							}
							result.add(candidate);
							removables.add(nextC);
							break;
							}
						} else {
							if(unifier.canUnifyMultiple(nextC.getSource(),source)) {						// multiple instances for the same actor
								candidate = DfFactory.eINSTANCE.createConnection(searcher.searchExistingVertexMultiple(source,this.result), null, 
										searcher.searchExistingVertexMultiple(target,this.result), nextC.getTargetPort());
								for (Attribute attr : nextC.getAttributes()){
									if(attr.getName().equals("broadcast"))
										candidate.setAttribute("broadcast", attr.getStringValue());
									else
										candidate.setAttribute(attr.getName(), attr.getReferencedValue());
								}
								result.add(candidate);
								removables.add(nextC);
								break;
						}
					}
			}
		}
		
		// source is an instance, target is a port
		if ((source.getAdapter(Instance.class) != null) && (target.getAdapter(Port.class) != null)){
			for(List<Connection> nextCoutList : ((Instance) source).getOutgoingPortMap().values()){
				for(Connection nextCout : nextCoutList){
					if(!presMultInst) {																		// single instance for the same actor
						if(unifier.canUnify(nextCout.getTarget(),target)){
							candidate = DfFactory.eINSTANCE.createConnection(searcher.searchExistingVertex(source,this.result),nextCout.getSourcePort(), 
									searcher.searchExistingVertex(target,this.result), null);
							for (Attribute attr : nextCout.getAttributes()){
								if(attr.getName().equals("broadcast"))
									candidate.setAttribute("broadcast", attr.getStringValue());
								else
									candidate.setAttribute(attr.getName(), attr.getReferencedValue());
							}
							result.add(candidate);
							removables.add(nextCout);
							break;
						}
					} else {																				// multiple instances for the same actor
						if(unifier.canUnifyMultiple(nextCout.getTarget(),target)) {
							candidate = DfFactory.eINSTANCE.createConnection(searcher.searchExistingVertexMultiple(source,this.result),nextCout.getSourcePort(), 
									searcher.searchExistingVertexMultiple(target,this.result), null);
							for (Attribute attr : nextCout.getAttributes()){
								if(attr.getName().equals("broadcast"))
									candidate.setAttribute("broadcast", attr.getStringValue());
								else
									candidate.setAttribute(attr.getName(), attr.getReferencedValue());
							}
							result.add(candidate);
							removables.add(nextCout);
							break;
						}
					}
				}
				
			}
		}
		
		// source and target are ports
		if ((source.getAdapter(Port.class) != null) && (target.getAdapter(Port.class) != null)){
			result.add(DfFactory.eINSTANCE.createConnection(searcher.searchExistingVertex(source,this.result), null, 
					searcher.searchExistingVertex(target,this.result), null));
		}	
		for(Connection c : removables) {
			currentNetwork.remove(c);
			c.setSource(null);
			c.setSourcePort(null);
			c.setTarget(null);
			c.setTargetPort(null);
		}
		
		return result;
	}


	/**
	 * 
	 * 
	 */
	public SboxActorManager getSboxActorManager(){
		return sboxActorManager;
	}

	/**
	 * Get the sbox LUTs of the result network.
	 * 
	 * @return
	 */
	public List<SboxLut> getSboxLuts() {
		return sboxLutManager.getLuts();
	}

	/**
	 * Get the section map of the merged networks. 
	 * 
	 * @return
	 */
	public Map<Network,Integer> getSectionMap() {
		return sectionMap;
	}

	/**
	 * Get the lists of instances of the merged networks.
	 * 
	 * @return
	 */
	public Map<Network,Set<Instance>> getNetworksClkInstances() {
	
		for(Network net : networksInstances.keySet())
			for(Vertex child : net.getChildren())
				if(child.getAdapter(Actor.class).hasAttribute("combinational"))
					networksInstances.get(net).remove(child.getAdapter(Instance.class));
		return networksInstances;
	}

	/**
	 * Get the lists of instances of the merged networks.
	 * 
	 * @return
	 */
	public Map<Network,Set<Instance>> getNetworksInstances() {
		return networksInstances;
	}


	/**
	 * Place a sbox 1x2 on the result network and return new candidate connection
	 * 
	 * @param candidate
	 * @param collision
	 * @param unifiables
	 * @return new candidate connection
	 */
	private Connection placeSbox1x2(Connection candidate, Connection collision, List<Connection> unifiables){
		
		// Sbox 1x2
		
		// creating sbox instance
		Instance sboxInstance = DfFactory.eINSTANCE.createInstance("sbox_" + sboxActorManager.getSboxCount() , null);
		sboxInstance.setAttribute("count", sboxActorManager.getSboxCount());
		
		// adding ID parameter (only for static implementation)
		/*Argument argID = DfFactory.eINSTANCE.createArgument(
				IrFactory.eINSTANCE.createVar(IrFactory.eINSTANCE.createTypeInt(32), "ID", true, 0), 
				IrFactory.eINSTANCE.createExprInt(sboxActorManager.getSboxCount()));
		sboxInstance.getArguments().add(argID);*/
		
		sboxActorManager.incrementSboxCount();
		
		// updating sbox lut
		if(presMultInst) {
			sboxLutManager.setLutValue(sboxInstance, currentNetwork, ALL_SECTIONS);
		} else {
			sboxLutManager.setLutValue(sboxInstance, currentNetwork, currentSection);
			sboxLutManager.resetPrevSectionsLut(sboxInstance, currentNetwork, currentSection);
		}
		for (Network mergedNet : mergedNetworks) {
			sboxLutManager.resetLutValue(sboxInstance, mergedNet, ALL_SECTIONS);
		}
		
		// making  connection: common source --> sbox
		Port inPort = DfFactory.eINSTANCE.createPort();
		if(collision.getSourcePort()!=null){
			inPort=IrUtil.copy(collision.getSourcePort());
		}else{
			inPort=IrUtil.copy(collision.getSource().getAdapter(Port.class));
		}
		inPort.setName("in1");
		sboxInstance.setEntity(sboxActorManager.getSboxActor1x2(inPort.getType()));
		sboxInstance.getActor().getInputs().add(inPort);
		
		Connection inConn = DfFactory.eINSTANCE.createConnection(collision.getSource(), collision.getSourcePort(), sboxInstance, sboxInstance.getActor().getInput("in1"));
	
		// making connection: sbox --> collision connection target
		Port outPort1 =  DfFactory.eINSTANCE.createPort();
		if(collision.getTargetPort()!=null){
			outPort1=IrUtil.copy(collision.getTargetPort());
		}else{
			outPort1=IrUtil.copy(collision.getTarget().getAdapter(Port.class));
		}
		outPort1.setName("out1");
		sboxInstance.getActor().getOutputs().add(outPort1);
		
		Connection outConn1 = DfFactory.eINSTANCE.createConnection(sboxInstance, sboxInstance.getActor().getOutput("out1"), collision.getTarget(), collision.getTargetPort());
		
		
		//ExprInt out1Size = getSize(collision);
			
		//outConn1.setAttribute("bufferSize",out1Size);
		if(collision.hasAttribute("broadcast"))
			outConn1.setAttribute("broadcast", collision.getAttribute("broadcast").getStringValue());
		
		
		if(collision.hasAttribute("broadcast")) {
			for(Connection connection : result.getConnections()) {
				if(!connection.equals(collision))
					if(!presMultInst) {
						if(matcher.matchSources(connection, collision) && connection.hasAttribute("broadcast")) {
							connection.setSource(sboxInstance);
							connection.setSourcePort(sboxInstance.getActor().getOutput("out1"));
						}
					} else {
						if(matcher.matchSourcesMultiple(connection, collision) && connection.hasAttribute("broadcast")) {
							connection.setSource(sboxInstance);
							connection.setSourcePort(sboxInstance.getActor().getOutput("out1"));
						}
					}
			}
		}
		
		// making connection: sbox --> candidate connection target
		Port outPort2 =  DfFactory.eINSTANCE.createPort();
		if(candidate.getTargetPort()!=null) {
			outPort2=IrUtil.copy(candidate.getTargetPort());
		} else {
			outPort2=IrUtil.copy(candidate.getTarget().getAdapter(Port.class));
		}
		outPort2.setName("out2");
		sboxInstance.getActor().getOutputs().add(outPort2);
		
		Connection outConn2;
		if(!presMultInst){
			outConn2 = DfFactory.eINSTANCE.createConnection(sboxInstance, sboxInstance.getActor().getOutput("out2"), searcher.searchExistingVertex(candidate.getTarget(),result), 
					candidate.getTargetPort());
		} else {
			outConn2 = DfFactory.eINSTANCE.createConnection(sboxInstance, sboxInstance.getActor().getOutput("out2"), searcher.searchExistingVertexMultiple(candidate.getTarget(),result), 
					candidate.getTargetPort());	
		}
		
		//ExprInt out2Size = getSize(candidate);
		
		//outConn2.setAttribute("bufferSize",out2Size);
		
		if(candidate.hasAttribute("broadcast"))
			outConn2.setAttribute("broadcast", candidate.getAttribute("broadcast").getStringValue());
		
		// assigning input connection size
		//inConn.setAttribute("bufferSize", getMax(out1Size, out2Size));
		if(!inPort.getType().isBool()){
			Argument arg = DfFactory.eINSTANCE.createArgument(
					IrFactory.eINSTANCE.createVar(IrFactory.eINSTANCE.createTypeInt(32), "SIZE", true, 0), 
					IrFactory.eINSTANCE.createExprInt(inPort.getType().getSizeInBits()));
			sboxInstance.getArguments().add(arg);
		}
	
		// adding connections and returning new candidate
		candidate = outConn2;
		result.add(sboxInstance);
		unifiables.add(outConn1);
		unifiables.add(inConn);
		//System.out.println("Splacing connection " + outConn1);
		//System.out.println("Splacing connection " + inConn);
		return candidate;
	}

	/**
	 * Place a sbox 2x1 on the result network and return new candidate connection
	 * 
	 * @param candidate
	 * @param collision
	 * @param unifiables
	 * @return	new candidate connection
	 */
	private Connection placeSbox2x1(Connection candidate, Connection collision, List<Connection> unifiables){
		
		// Sbox 2x1

		//System.out.println("Scandidate connection " + candidate);
		
		// creating sbox instance
		Instance sboxInstance = DfFactory.eINSTANCE.createInstance("sbox_" + sboxActorManager.getSboxCount() , null);
		sboxInstance.setAttribute("count", sboxActorManager.getSboxCount());
		
		// adding ID parameter (only for static implementation)
		/*Argument argID = DfFactory.eINSTANCE.createArgument(
				IrFactory.eINSTANCE.createVar(IrFactory.eINSTANCE.createTypeInt(32), "ID", true, 0), 
				IrFactory.eINSTANCE.createExprInt(sboxActorManager.getSboxCount()));
		sboxInstance.getArguments().add(argID);*/
		
		sboxActorManager.incrementSboxCount();
		
		// updating sbox lut
		if(presMultInst) {
			sboxLutManager.setLutValue(sboxInstance, currentNetwork, ALL_SECTIONS);
		} else {
			sboxLutManager.setLutValue(sboxInstance, currentNetwork, currentSection);
			sboxLutManager.resetPrevSectionsLut(sboxInstance, currentNetwork, currentSection);
		}
		for (Network mergedNet : mergedNetworks) {
			sboxLutManager.resetLutValue(sboxInstance, mergedNet, ALL_SECTIONS);
		}
	
		// making connection: collision connection source --> sbox
		Port inPort1 = DfFactory.eINSTANCE.createPort();
		if(collision.getSourcePort()!=null) {
			inPort1=IrUtil.copy(collision.getSourcePort());
		} else {
			inPort1=IrUtil.copy(collision.getSource().getAdapter(Port.class));
		}
		inPort1.setName("in1");
		sboxInstance.setEntity(sboxActorManager.getSboxActor2x1(inPort1.getType()));
		sboxInstance.getActor().getInputs().add(inPort1);
		
		Connection inConn1 = DfFactory.eINSTANCE.createConnection(collision.getSource(), collision.getSourcePort(), sboxInstance, sboxInstance.getActor().getInput("in1"));
		//ExprInt in1Size = getSize(collision);
		//inConn1.setAttribute("bufferSize",in1Size);
		if(collision.hasAttribute("broadcast"))
			inConn1.setAttribute("broadcast", collision.getAttribute("broadcast").getStringValue());
		
		// making connection: candidate conneciton source --> sbox
		Port inPort2 = DfFactory.eINSTANCE.createPort();
		if(candidate.getSourcePort()!=null) {
			inPort2=IrUtil.copy(candidate.getSourcePort());
		}else{
			inPort2=IrUtil.copy(candidate.getSource().getAdapter(Port.class));
		}
		inPort2.setName("in2");
		sboxInstance.getActor().getInputs().add(inPort2);
		
		Connection inConn2;
		if(!presMultInst){
			inConn2 = DfFactory.eINSTANCE.createConnection(searcher.searchExistingVertex(candidate.getSource(),result), candidate.getSourcePort(), 
					sboxInstance, sboxInstance.getActor().getInput("in2"));
		} else {
			inConn2 = DfFactory.eINSTANCE.createConnection(searcher.searchExistingVertexMultiple(candidate.getSource(),result), candidate.getSourcePort(), 
					sboxInstance, sboxInstance.getActor().getInput("in2"));
		}
		//ExprInt in2Size = getSize(candidate);	
		//inConn2.setAttribute("bufferSize",in2Size);
		if(candidate.hasAttribute("broadcast"))
			inConn2.setAttribute("broadcast", candidate.getAttribute("broadcast").getStringValue());
		candidate = inConn2;
		
		// making conneciton: sbox --> common target
		Port outPort = DfFactory.eINSTANCE.createPort();
		if(collision.getTargetPort()!=null) {
			outPort=IrUtil.copy(collision.getTargetPort());
		}else{
			outPort=IrUtil.copy(collision.getTarget().getAdapter(Port.class));
		}
		outPort.setName("out1");
		sboxInstance.getActor().getOutputs().add(outPort);
		
		Connection outConn = DfFactory.eINSTANCE.createConnection(sboxInstance, sboxInstance.getActor().getOutput("out1"), collision.getTarget(), collision.getTargetPort());
		
		// assigning output connection size
		//outConn.setAttribute("bufferSize", getMax(in1Size, in2Size));
		if(!inPort1.getType().isBool()){
			Argument arg = DfFactory.eINSTANCE.createArgument(
				IrFactory.eINSTANCE.createVar(IrFactory.eINSTANCE.createTypeInt(32), "SIZE", true, 0), 
				IrFactory.eINSTANCE.createExprInt(outPort.getType().getSizeInBits()));
			sboxInstance.getArguments().add(arg);
		}

		// adding connections and returning new candidate
		result.add(sboxInstance);
		unifiables.add(inConn1);
		unifiables.add(outConn);
		//System.out.println("Scandidate connection " + collision);
		//System.out.println("Scollision connection " + collision);
		//System.out.println("Splacing connection " + outConn);
		//System.out.println("Splacing connection " + inConn1);
		return candidate;
	}
	
	/**
	 * Merges the list of input dataflow networks into a resulting mutli-dataflow one
	 * 
	 * @param mergingNetworks
	 * 		the list of input networks to be merged
	 * @param path
	 * 		the path of the CAL files inside the project
	 * @return 
	 * 		the multi-dataflow network resulting by the merging process 
	 */
	public Network merge(List<Network> mergingNetworks, String path) throws IOException {
			
		if(path.contains("src"))
			sboxActorManager.initializeSboxCalFiles(path);
	
		// setting the name of the result network
		result.setName("multi_dataflow");
		
		// merging iteration
		for (int i=0; i<mergingNetworks.size(); i++) {
						
			// setting current merging network
			if(mergingNetworks.get(i) != null)
				currentNetwork = mergingNetworks.get(i);
			
			// merging operation on the current network	
			mergeNetwork(currentNetwork); 					
			
			// adding current network to the already merged networks
			mergedNetworks.add(currentNetwork);						
		}
		
		// flattening luts
		for(Network net : mergingNetworks)
			if(true)
				for(SboxLut sboxLut : sboxLuts)
					sboxLut.flatLut(net);
				
		return result;
	}

	/**
	 * Tries to merge connection between two given instances. If no connection 
	 * is found a new connection is created. If an existing connection interests the ports of 
	 * the new connection a sbox is placed in the result network.
	 * 
	 * @param source
	 * @param target
	 */
	private void mergeConnection(Vertex source, Vertex target, int predecessorNumber) {
				
		List<Connection> unifiables 	= new LinkedList<Connection>();	// connection(s) of the global graph that matches
		List<Connection> candidates 	= new LinkedList<Connection>();	// connection(s) of the target instance to be merge
		List<Connection> sboxables 		= new ArrayList<Connection>();	// connection(s) to be added after placing new sbox
		List<Connection> removables 	= new ArrayList<Connection>();	// connection(s) to be removed by not unifiables because matches
		List<Connection> notUnifiables 	= new ArrayList<Connection>();	// connection(s) to be added in the global graph because not matches
		Connection candidate = null;									// connection between instance to be added in the global graph
				
		// finding connection(s) on the merging network
		candidates = candidateConnections(source, target);
				
		// searching matching connection(s) on the result network
		for(Connection nextCandC : candidates) {
			if(!nextCandC.hasAttribute("broadcast"))
				if(!presMultInst && predecessorNumber==FIRST_PREDECESSOR) {							// one instance for the same actor
					if(searcher.searchExistingConnection(nextCandC,result) != null) {
						unifiables.add(nextCandC);
						// updating sbox luts
						sboxLutManager.addLutsExistingSboxes(matcher.getLuts(), currentNetwork, currentSection);
						matcher.deleteLuts();
					}
				} else {																			// multiple instances for the same actor
					if(searcher.searchExistingConnectionMultiple(nextCandC,result,sboxLutManager.getLuts(),currentNetwork) != null) {
						unifiables.add(nextCandC);
						// updating sbox luts
						sboxLutManager.addLutsExistingSboxes(matcher.getLuts(), currentNetwork, ALL_SECTIONS);
						matcher.deleteLuts();
					}
				}
		}
		
		// making not unifiable connections list
		notUnifiables = candidates;
		for(Connection nextCandC : notUnifiables){
			for(Connection nextUnifC : unifiables){
				if(!presMultInst && predecessorNumber==FIRST_PREDECESSOR){	// one instance for the same actor
					if(matcher.matchConnection(nextCandC, nextUnifC)){
						removables.add(nextCandC);
						break;
					}
				} else {													// multiple instances for the same actor
					if(matcher.matchConnectionMultiple(nextCandC, nextUnifC)){
						removables.add(nextCandC);
						break;
					}
				}
			}
		}		
		notUnifiables.removeAll(removables);
				
		// adding new connection(s) to the result network
		for (Connection nextCandC : notUnifiables) {
										
			// current candidate
			candidate = nextCandC;
			Connection oldCandidate = null;
				
			
			// collision connections that have same source or target than candidate
			Connection collisionSrc = null;
			Connection collisionTgt = null;
						
			boolean sameBroadcast = false;
	
			// searching source collision connections 
			for(Connection nextC : result.getConnections()) {
				if(candidate.hasAttribute("broadcast"))
					if(nextC.hasAttribute("broadcast")){
	
						if(candidate.getAttribute("broadcast").getStringValue().equals(nextC.getAttribute("broadcast").getStringValue()))
							if(!presMultInst) {
								if(matcher.matchSources(candidate, nextC))
									sameBroadcast = true;
							} else {
								if(matcher.matchSourcesMultiple(candidate, nextC))
									sameBroadcast = true;
							}
					}
				if(!sameBroadcast)
					if(!presMultInst && predecessorNumber==FIRST_PREDECESSOR){	// one instance for the same actor	
						if(matcher.matchSources(candidate,nextC)){
							collisionSrc = nextC;
						}
					} else {													// multiple instances for the same actor
						if(matcher.matchSourcesMultiple(candidate,nextC)){
							collisionSrc = nextC;
						}
					}
	
			}
	
		
			// source collision founded: placing a 1x2 sbox
			if(collisionSrc != null){
			
				candidate = placeSbox1x2(candidate,collisionSrc,sboxables);
				
				addConnections(sboxables);
				removeConnection(collisionSrc);
				if(nextCandC.hasAttribute("broadcast")) {
					for(Connection connection : currentNetwork.getConnections()) {
							if(!presMultInst) {
								if(matcher.matchSources(connection, nextCandC) && !matcher.matchTargets(connection, nextCandC) 
										&& connection.hasAttribute("broadcast")) {
									connection.setSource(candidate.getSource());
									connection.setSourcePort(candidate.getSourcePort());		
								}
							} else {
								if(matcher.matchSourcesMultiple(connection, nextCandC) && !matcher.matchTargetsMultiple(connection, nextCandC)
										&& connection.hasAttribute("broadcast")) {
									connection.setSource(candidate.getSource());
									connection.setSourcePort(candidate.getSourcePort());
								}
							}
					}
					// added for bug on two source collision triple broadcasts connections
					for(Connection connection : notUnifiables) {
						if(!presMultInst) {
							if(matcher.matchSources(connection, nextCandC) && !matcher.matchTargets(connection, nextCandC) 
									&& connection.hasAttribute("broadcast")) {
								connection.setSource(candidate.getSource());
								connection.setSourcePort(candidate.getSourcePort());		
							}
						} else {
							if(matcher.matchSourcesMultiple(connection, nextCandC) && !matcher.matchTargetsMultiple(connection, nextCandC)
									&& connection.hasAttribute("broadcast")) {
								connection.setSource(candidate.getSource());
								connection.setSourcePort(candidate.getSourcePort());
							}
						}
					}
				}
				collisionSrc = null;
			}
				
			// searching target collision connections
			for(Connection nextC : result.getConnections()){
				if(!presMultInst && predecessorNumber==FIRST_PREDECESSOR) {						// one instance for the same actor
					if(matcher.matchTargets(candidate,nextC)){
						collisionTgt = nextC;
					}
				} else {																		// multiple instances for the same actor
					if(matcher.matchTargetsMultiple(candidate,nextC)){
						collisionTgt = nextC;
					}
				}
			}
			// target collision founded: placing a  2x1 sbox
			if(collisionTgt != null){
				oldCandidate = candidate;
				candidate = placeSbox2x1(candidate,collisionTgt,sboxables);
				addConnections(sboxables);
				removeConnection(collisionTgt);
				collisionTgt.setSource(null);
				collisionTgt.setSourcePort(null);
				collisionTgt = null;
				if(sameBroadcast){
					oldCandidate.setSource(null);
					oldCandidate.setSourcePort(null);
					oldCandidate.setTarget(null);
					oldCandidate.setTargetPort(null);
					
				}
					
			}
			
			if(!candidate.equals(oldCandidate)) {
				if(oldCandidate!=null) {
					oldCandidate.setSource(null);
					oldCandidate.setSourcePort(null);
					oldCandidate.setTarget(null);
					oldCandidate.setTargetPort(null);
				}
			}
			
			
			
			// adding current candidate connection to the result network
			//System.out.println("placing connection " + candidate);
			addConnection(candidate);
			
		} 
	
	}

	/**
	 * Try to merge the candidate vertex with a vertex in the given vertex list. If
	 * no vertex is found, a copy of candidate is created. Multiple instances for the same actor
	 * are preserved.
	 * 
	 * @param candidate
	 * 				the candidate vertex
	 * @param vertices
	 * 				the given vertex list
	 */
	private void mergeMultipleVertex(Vertex candidate) {
		
				
		Vertex unifiable = null;
		List<Vertex> unifiables = new ArrayList<Vertex>();
				
		if(! ( candidate.getAdapter(Instance.class).hasAttribute("don't merge") ) ){
		
			// finding all unifiables vertices for the given instance
			for (Vertex existing : result.getChildren()) {
				if (unifier.canUnifyMultiple(candidate, existing) && !existing.hasAttribute(currentNetwork.getName()) && !existing.getAdapter(Instance.class).hasAttribute("don't merge")){
					unifiables.add(existing.getAdapter(Instance.class));
				}
			}
			
			// finding best unifiable vertex for the given instance
			if(!unifiables.isEmpty()) {
				if(unifiables.size() != 1) {

					unifiable = searcher.searchBestVertex(candidate,unifiables);
				} else {
					unifiable = unifiables.get(0);
				}
				unifiable.setAttribute(currentNetwork.getName(), (Object) null);
				candidate.setAttribute("count", unifiable.getAttribute("count").getObjectValue());
			}
			
		
		}

		// the vertex is not unifiable: add new vertex to the result network		
		if (unifiable == null) {
			if(candidate.getAdapter(Port.class) != null){
				unifiable = DfFactory.eINSTANCE.createPort((Port) candidate);
			} else {
				unifiable = candidate.getAdapter(Instance.class);
				actorManager.incrActorCount(((Instance) unifiable).getAdapter(Actor.class));
				actorManager.renameInstance((Instance) unifiable, result);
				unifiable.setAttribute(currentNetwork.getName(), (Object) null);
				candidate.setAttribute("count", unifiable.getAttribute("count").getObjectValue());
			}
		}
		result.add(unifiable);
		if(unifiable.getAdapter(Instance.class) != null) {
			networksInstances.get(currentNetwork).add(unifiable.getAdapter(Instance.class));
			
		}
		
	}
	
	/**
	 * Merges the given network with the partial resulting one 
	 * 
	 * @param mergingNetwork
	 * 		input network to be merged
	 */
	private void mergeNetwork(Network mergingNetwork) {	
	
		// merge inputs
		for (Port candidate : mergingNetwork.getInputs()) {
			mergeInputPort(candidate);
		}
		
		// merge outputs
		for (Port candidate : mergingNetwork.getOutputs()) {
			mergeOutputPort(candidate);
		}
		
		// merge instances
		networksInstances.put(currentNetwork, new HashSet<Instance>());	// creating a list with the network instances (necessary for clock gating)
		for (Vertex candidate : mergingNetwork.getChildren()){
			if(!presMultInst){													
				mergeVertex(candidate);				// one instance for the same actor
			} else {															
				mergeMultipleVertex(candidate);		// multiple instances for the same actor
			}
		}
		
				
		// assign broadcast attribute to broadcast connections
		assignBroadcastAttribute(mergingNetwork);		
	
		// create virtual general root for the BFS algorithm
		Port root = DfFactory.eINSTANCE.createPort(null,"root");
		result.addInput(root);
		for(Port input : mergingNetwork.getInputs()){
			result.add(DfFactory.eINSTANCE.createConnection(root, null, input, null));
		}
		
		// run bread first search algorithm
		BFS bfsSearch = new BFS(root);
	
		// remove virtual general root from the vertex list
		result.remove(root);
		result.getInputs().remove(root);
		bfsSearch.getVertices().remove(root);
		
		currentSection = 0;												// initializing section number		
		List<Vertex> networkSectionVertices = new ArrayList<Vertex>();	// instantiating section list of vertex
		
		for(Vertex nextChild : bfsSearch.getVertices()){
			int predecessorIndex = FIRST_PREDECESSOR;					// initializing predecessor index
			if(!nextChild.getPredecessors().contains(root)) {		// do not analyze input ports			
				
				List<Vertex> predecessors = nextChild.getPredecessors();	// list of child vertex predecessors
								
					networkSectionVertices.add(nextChild);					// adding merged child to the network section vertices
	
					for(Vertex nextPredecessor : predecessors){				// updating section number
						if(networkSectionVertices.contains(nextPredecessor) 
								&& !nextPredecessor.getPredecessors().contains(nextChild)){
							networkSectionVertices.removeAll(networkSectionVertices);
							currentSection++;
					}
						mergeConnection(nextPredecessor, nextChild, predecessorIndex);	// merge connection(s) child and predecessor
						predecessorIndex++;																// updating predecessor index
					}
				networkSectionVertices.add(nextChild);					// adding merged child to the network section vertices
			}	
		
		}
		
		// save number of sections of the network
		sectionMap.put(currentNetwork, currentSection);
	
		// complete sbox LUTs
		if(presMultInst) {
			sboxLutManager.completeLutsMultiple(sectionMap);
		} else {
			sboxLutManager.completeLuts(sectionMap);
		}
		
		
	}

	/**
	 * Try to merge the candidate port with a port in the given port list. If
	 * no port is found, a copy of candidate is created. A mapping from candidate to an existing 
	 * (or newly-created) port is added to portMap.
	 * 
	 * @param candidate
	 * @param ports
	 */
	private void mergeInputPort(Port candidate) {
		Port unifiable = null;
		for (Port existing : result.getInputs()) {
			if (unifier.canUnify(candidate, existing)){
				unifiable = existing;
				break;
			}
		}
		if (unifiable == null) {
			unifiable = DfFactory.eINSTANCE.createPort(candidate);
		}
		result.addInput(unifiable);
	}
	
	/**
	 * Try to merge the candidate port with a port in the given port list. If
	 * no port is found, a copy of candidate is created. A mapping from candidate to an existing 
	 * (or newly-created) port is added to portMap.
	 * 
	 * @param candidate
	 * @param ports
	 */
	private void mergeOutputPort(Port candidate) {
		Port unifiable = null;
		for (Port existing : result.getOutputs()) {
			if (unifier.canUnify(candidate, existing)){
				unifiable = existing;
				break;
			}
		}
		if (unifiable == null) {
			unifiable = DfFactory.eINSTANCE.createPort(candidate);
		}
		result.addOutput(unifiable);
	}
	
	/**
	 * Try to merge the candidate vertex with a vertex in the given vertex list. If
	 * no vertex is found, a copy of candidate is created. Multiple instances for the same actor
	 * aren't preserved.
	 * 
	 * @param candidate
	 * 				the candidate vertex
	 * @param vertices
	 * 				the given vertex list
	 */			
	private void mergeVertex(Vertex candidate) {
		
		Vertex unifiable = null;
	
		// search matching vertex in the given list
		for (Vertex existing : result.getChildren()) {
			if (unifier.canUnify(candidate, existing)){
				if(existing.getAdapter(Instance.class) != null) {
					unifiable = existing.getAdapter(Instance.class);
					break;
				} else {
					unifiable = existing.getAdapter(Port.class);
					break;
				}
			}
		}
		
		// no matching vertex found, creating new vertex
		if (unifiable == null) 
			if(candidate.getAdapter(Port.class) != null){
				unifiable = DfFactory.eINSTANCE.createPort((Port) candidate);
			} else {
				unifiable = candidate.getAdapter(Instance.class);
				actorManager.incrActorCount(((Instance) unifiable).getAdapter(Actor.class));
				actorManager.renameInstance((Instance) unifiable, result);
			}
		
		result.add(unifiable);
		
		// if vertex is an instance, it is added to the instance list for clock gating
		if(unifiable.getAdapter(Instance.class) != null) {
			networksInstances.get(currentNetwork).add(unifiable.getAdapter(Instance.class));
		}
	}

	/**
	 * Removes a connection by the result network.
	 * 
	 * @param c
	 */
	private void removeConnection(Connection c){
		if(c != null){
			result.remove(c);
		}
	}
	
	/**
	 * Print the passed text through the ORCC logger.
	 * 
	 * @param text 
	 * 			the string to be print
	 */
	final public void write(String text) {
		OrccLogger.traceln(text);
	}

}
