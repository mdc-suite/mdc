package it.mdc.tool.core.multiDataflowGenerator;

import static it.mdc.tool.core.sboxManagement.SboxLutManager.ALL_SECTIONS;

import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.eclipse.emf.ecore.EObject;

import net.sf.orcc.df.Actor;
import net.sf.orcc.df.Argument;
import net.sf.orcc.df.DfFactory;
import net.sf.orcc.df.Instance;
import net.sf.orcc.df.Network;
import net.sf.orcc.df.Port;
import net.sf.orcc.graph.Vertex;
import it.mdc.tool.core.sboxManagement.SboxActorManager;
import it.mdc.tool.core.sboxManagement.SboxLut;
import it.mdc.tool.core.sboxManagement.*;
import net.sf.orcc.graph.visit.BFS;
import net.sf.orcc.ir.Expression;
import net.sf.orcc.ir.IrFactory;
import net.sf.orcc.ir.Var;
import net.sf.orcc.ir.util.ExpressionEvaluator;
import net.sf.orcc.ir.util.IrUtil;
import net.sf.orcc.util.Attribute;
import net.sf.orcc.util.OrccLogger;
import net.sf.orcc.df.Connection;

import java.util.LinkedList;

/**
 * Class able to merge a set of dataflow networks by sharing the
 * common actors and placing switching modules (SBoxes) in order 
 * to properly forward tokens such as the multiDataflowNetwork 
 * implements all the merged dataflows.
 * The implemented algorithm is an Empiric Algorithm 
 * TODO describe the Empiric Algorithm
 * 
 * <i> Go back to it.mdc.tool.core.MDCBackend.doMergingProcess() </i>
 * 
 * @author Carlo Sau
 * 
 * @see it.unica.diee.mdc package
 */
public class EmpiricMerger extends Merger {
	
	/**
	 * Multi-dataflow network
	 */
	private Network multiDataflow;
		
	/**
	 * Map of the vertex mapping of each merged network
	 * within the multi-dataflow one.
	 */
	//private Map <String,Map<String,String>> networkVertexMap;
	
	/**
	 * Map of the merging network vertices
	 */
	private Map<Vertex,Vertex> verticesMap;

	/**
	 * Map of the merging network connections
	 */
	private Map<Connection,Connection> connectionsMap;
	
	/**
	 * Matcher instance
	 */
	private Matcher matcher;
	
	/**
	 * Unifier instance
	 */
	private Unifier unifier;
	
	/**
	 * Searcher instance
	 */
	private Searcher searcher;

	/**
	 * Map of the number of sections for each merged network
	 * (useful for future works about networks internal reconfiguration)
	 */
	private Map<Network,Integer> sectionMap;
	
	/**
	 * Current section of the merging network
	 */
	private int currentSection;
	
	/**
	 * Current merging network
	 */
	private Network currentNetwork;
	
	/**
	 * List of the already merged networks
	 */
	private List<Network> mergedNetworks;
	
	/**
	 * Map of the instances in the multi-dataflow network
	 * for each merged network
	 */
	private Map<String,Set<String>> networksInstances;
	
	/**
	 * Sbox actor manager instance
	 */
	private SboxActorManager sboxActorManager;
	
	/**
	 * Sbox Look-Up Table manager instance
	 */
	//private SboxLutManager sboxLutManager;	
	
	/**
	 * Actor manager instance
	 */
	private ActorManager actorManager;
	
	/**
	 * The constructor
	 */
	public EmpiricMerger() {
		mergedNetworks = new ArrayList<Network>();				// instantiating list of already merged networks
		multiDataflow = DfFactory.eINSTANCE.createNetwork();	// instantiating result network
		sectionMap = new HashMap<Network,Integer>();			// instantiating sections map
		matcher = new Matcher();								// instantiating matcher
		unifier = new Unifier();								// instantiating unifier
		searcher = new Searcher(unifier,matcher);			// instantiating unifier
		sboxActorManager = new SboxActorManager();
		//sboxLutManager = new SboxLutManager();
		actorManager = new ActorManager();
		networksInstances = new LinkedHashMap<String,Set<String>>();
		//networkVertexMap = new HashMap<String,Map<String,String>>();
	}

	/**
	 * Try to add the candidate connection in the mutli-dataflow network.
	 * 
	 * @param candidate
	 * 		the candidate connection
	 */
	private void addConnection(Connection candidate){
				
		if(verticesMap.get(candidate.getSource())!=null){
			candidate.setSource(verticesMap.get(candidate.getSource()));
		}
		
		if(verticesMap.get(candidate.getTarget())!=null){
			candidate.setTarget(verticesMap.get(candidate.getTarget()));
		}
	
		if(candidate != null){
			multiDataflow.add(candidate);
		}
	
	}

	/**
	 * Assign broadcast attribute to the connections of the given network
	 * 
	 * @param network
	 */
	private void assignBroadcastAttribute(Network network) {
		
		boolean isBroadcast = false;
		int broadcastSize = 0;
		
		for (Connection connection : network.getConnections()) {
			
			// broadcast flag
			isBroadcast = false;
	//		OrccLogger.traceln("bcass " + connection.getAttributes());
			
			if(!connection.hasAttribute("broadcast"))
				for(Connection otherConnection : network.getConnections())
					if(!connection.equals(otherConnection))
						if(connection.getSource().equals(otherConnection.getSource())){
							if((connection.getSourcePort() != null) && (otherConnection.getSourcePort() != null)) {		// source is an instance
								if(connection.getSourcePort().equals(otherConnection.getSourcePort())) {
									// connection is broadcast, assigning attribute and setting flag
									otherConnection.setAttribute("broadcast", currentNetwork.getName());
									broadcastSize++;
									isBroadcast = true;
								}
							
							} else {																					// source is an input port
								// connection is broadcast, assign attribute and set flag
								otherConnection.setAttribute("broadcast", currentNetwork.getName());
								broadcastSize++;
								isBroadcast = true;
							}
						}
	
			if(isBroadcast){
				// assign attribute to the referenced connection
				broadcastSize++;
				connection.setAttribute("broadcast", currentNetwork.getName());
				connection.setAttribute("broadcastSize", String.valueOf(broadcastSize));
				for(Connection otherConnection : network.getConnections())
					if(!connection.equals(otherConnection))
						if(connection.getSource().equals(otherConnection.getSource())){
							if((connection.getSourcePort() != null) && (otherConnection.getSourcePort() != null)) {		// source is an instance
								if(connection.getSourcePort().equals(otherConnection.getSourcePort())) {
									// connection is broadcast, assign attribute and set flag
									otherConnection.setAttribute("broadcastSize", String.valueOf(broadcastSize));
								}
							
							} else {																					// source is an input port
								// connection is broadcast, assign attribute and set flag
								otherConnection.setAttribute("broadcastSize", String.valueOf(broadcastSize));
							}
						}
				broadcastSize = 0;
			}
		}
	}

	/**
	 * Return the map of the sequential (not combinational) instances 
	 * in the multi-dataflow network for each input dataflow network.
	 * 
	 * @return
	 * 		the map of the input network sequential instances
	 */
	@Override
	public Map<String,Set<String>> getNetworksClkInstances() {
		
		Set<String> toRemove;
		
		for(String network : networksInstances.keySet()) {
			toRemove = new HashSet<String>();
			for(String netActor : networksInstances.get(network)) {
				for(Vertex mappedVertex : multiDataflow.getChildren()) {
					if(mappedVertex.getLabel().equals(netActor)) {
						if(mappedVertex.getAdapter(Actor.class).hasAttribute("combinational")) {
							toRemove.add(netActor);
						}
					}
				}
			}
			for(String actorToRemove : toRemove) {
				networksInstances.get(network).remove(actorToRemove);
			}
		}
		
		return networksInstances;
	}

	/**
	 * Return the map of the instances in the multi-dataflow network
	 * for each input dataflow network.
	 * 
	 * @return
	 * 		the map of the input network instances
	 */
	@Override
	public Map<String,Set<String>> getNetworksInstances() {
		return networksInstances;
	}
	
	/**
	 * Return the map of the vertex mapping of each merged network
	 * within the multi-dataflow one.
	 * 
	 * @return
	 * 		the map of the input network instances
	 */
	public Map<String,Map<String,String>> getNetworksVertexMap() {
		return networkVertexMap;
	}

	/**
	 * Return the sbox actor manager instance
	 * 
	 * @return
	 * 		the sbox actor manager instance.
	 */
	public SboxActorManager getSboxActorManager(){
		return sboxActorManager;
	}

	/**
	 * Return the sbox Look-Up Tables list.
	 * 
	 * @return
	 * 		the sbox LUTs list
	 */
	public List<SboxLut> getSboxLuts() {
		return sboxLutManager.getLuts();
	}

	/**
	 * Iterate on the input list of dataflow networks
	 * to compose the multi-dataflow network.
	 * 
	 * @param mergingNetworks
	 * 		the list of input dataflow networks
	 * @param path
	 * 		the backend output path (to set sbox CAL reference file)
	 * @return
	 * 		the mutli-dataflow network
	 */
	@Override
	public Network merge(List<Network> mergingNetworks, String path) throws IOException {
		 /// <b>Merging steps: </b>
		//sboxActorManager.initializeSboxCalFiles(path + ".cal_gen");

		/// <ul> <li> set the name of the result network
		multiDataflow.setName("multi_dataflow");
		
		/// <li> loop on the input set of networks
		for (int i=0; i<mergingNetworks.size(); i++) {
			
			/// <ol> <li> set current network to be combined			
			if(mergingNetworks.get(i) != null)
				currentNetwork = mergingNetworks.get(i);	
			
			///<li> combine the current network			
			mergeNetwork();
			
			///<li> merge network variables (static parameters)
			Boolean mergeThisVar = true;
			List<Var> mergingVars = new ArrayList<Var>();
			for(Var currVar : currentNetwork.getVariables()) {
				for(Var mergedVar : multiDataflow.getVariables()) {
					if(currVar.getName().equals(mergedVar.getName())) {
						mergeThisVar = false;
						break;
					}
				}
				if(mergeThisVar) {
					mergingVars.add(currVar);
				}
				mergeThisVar = true;	
			}
			for(Var parm : mergingVars) {
				multiDataflow.getVariables().add(parm);
			}
			
			///<li> merge network parameters (dynamic parameters)
			Boolean mergeThisParm = true;
			List<Var> mergingParms = new ArrayList<Var>();
			for(Var currParm : currentNetwork.getParameters()) {
				for(Var mergedParm : multiDataflow.getParameters()) {
					if(currParm.getName().equals(mergedParm.getName())) {
						mergeThisParm = false;
						break;
					}
				}
				if(mergeThisParm) {
					mergingParms.add(currParm);
				}
				mergeThisParm = true;	
			}
			for(Var parm : mergingParms) {
				multiDataflow.getParameters().add(parm);
			}
			
			///<li> add current network to the already combined networks </ol>
			mergedNetworks.add(currentNetwork);						
		}
		
		///  </ul>
							
		return multiDataflow;
	}

	/**
	 * Try to merge connection between two given vertices. 
	 * If no connection is found a new connection is created. 
	 * If an existing connection involves the same ports a sbox 
	 * is placed in the result network.
	 * 
	 * @param source
	 * 		the source vertex
	 * @param target
	 * 		the target vertex
	 */
	private void mergeConnection(Vertex source, Vertex target) {
		/// <ul>		
		// connection(s) to be merged
		List<Connection> candidates = new LinkedList<Connection>();	
		
		/// <li> find connection(s) on the merging network
		for(Connection existingConnection : currentNetwork.getConnections()){
		//	OrccLogger.traceln("ext attr " + existingConnection.getAttributes());
			if(source.equals(existingConnection.getSource()) && 
					target.equals(existingConnection.getTarget()))
				candidates.add(existingConnection);
		}
				
		/// <li> search matching connection(s) on the result network 
		for(Connection candidate : candidates) {
			
		//	OrccLogger.traceln("cand attr " + candidate.getAttributes());

			if(!connectionsMap.containsKey(candidate)) {
				Connection unifiable;
				if(candidate.hasAttribute("broadcast")) {
					unifiable = searcher.getConnection(
						verticesMap.get(source),candidate.getSourcePort(),
						verticesMap.get(target),candidate.getTargetPort(),
						multiDataflow,Integer.parseInt(candidate.getAttribute("broadcastSize").getStringValue()));
				} else {
					unifiable = searcher.getConnection(
						verticesMap.get(source),candidate.getSourcePort(),
						verticesMap.get(target),candidate.getTargetPort(),
						multiDataflow,0);
				}
				if(unifiable!=null) {
					if(!candidate.hasAttribute("broadcast")) {
						connectionsMap.put(candidate,unifiable);
						sboxLutManager.addLutsExistingSboxes(matcher.getLuts(), currentNetwork, ALL_SECTIONS);
						for(Instance sbox : matcher.getLuts().keySet()) {
							networksInstances.get(currentNetwork.getSimpleName()).add(sbox.getLabel());
						}
						// update bufferSize parameter (worst case)
						if(hasBufferSize(candidate)) {
							if(hasBufferSize(unifiable)) {
					//			OrccLogger.debugln("connection " + candidate + " vs " + unifiable + "(" + getBufferSizeValue(candidate) + "," + getBufferSizeValue(unifiable) + ")");
								if(getBufferSizeIntegerValue(candidate) > getBufferSizeIntegerValue(unifiable)) {
					//				OrccLogger.debugln("UPD");
									unifiable.getAttribute("bufferSize").setEObjectValue(getBufferSizeValue(candidate));	// for network editor
									unifiable.getAttribute("bufferSize").setContainedValue(getBufferSizeValue(candidate));	// for platform-composer
								}
							} else {
					//			OrccLogger.debugln("UPD");
								unifiable.addAttribute("bufferSize");
								unifiable.getAttribute("bufferSize").setEObjectValue(getBufferSizeValue(candidate));	// for network editor
								unifiable.getAttribute("bufferSize").setContainedValue(getBufferSizeValue(candidate));	// for platform-composer
							}
					//		OrccLogger.debugln("cbs " + getBufferSizeValue(unifiable) + "   " + unifiable.getAttribute("bufferSize").getReferencedValue());
						}
						matcher.deleteLuts();	
					} else {
						boolean isNotUnifiable = false;
						Map<Connection,Connection> unifiableBroadcast = new HashMap<Connection,Connection>();	/// <ol> <li> try to find a unifiable broadcast
						unifiableBroadcast.put(candidate,unifiable);											/// <li> add the already found unifiable connection
						Map<Connection,EObject> unifiableBufferSize = new HashMap<Connection,EObject>();
						
						// update bufferSize parameter (worst case)
						if(hasBufferSize(candidate)) {
							if(hasBufferSize(unifiable)) {
								if(getBufferSizeIntegerValue(candidate) > getBufferSizeIntegerValue(unifiable)) {
									unifiableBufferSize.put(unifiable,getBufferSizeValue(candidate));
								}
							} else {
								unifiableBufferSize.put(unifiable,getBufferSizeValue(candidate));
							}
						}
						Map<Instance,Boolean> unifBroadLuts = matcher.getLuts();								/// <li> get the luts of unifiable broadcast
						matcher.deleteLuts();																	/// <li> reset matcher luts
						
						for(Connection otherCandidate : currentNetwork.getConnections()){						/// <li> for each other candidate
							if(otherCandidate.hasAttribute("broadcast") &&										/// <ol> <li>  if the other candidate is a broadcast 
									matcher.matchSourcesMultiple(candidate, otherCandidate) && 					///<b>and</b> its source matches with the candidate
									!otherCandidate.equals(candidate)) {										///<b>and</b> it isn't the candidate 
								Connection otherUnifiable = searcher.getConnection(				   				/// <b> search the other candidate unifiable </b> </ol>
										verticesMap.get(source),candidate.getSourcePort(),
										verticesMap.get(otherCandidate.getTarget()),
										otherCandidate.getTargetPort(),multiDataflow,
										Integer.parseInt(otherCandidate.getAttribute("broadcastSize").getStringValue()));
								if(otherUnifiable!=null) {														/// <li> for each other candidate
																												/// <ol> <li> if an other unifiable has been found
										for(Instance sbox : matcher.getLuts().keySet()){						/// <b> get the luts of the other unifiable </b> 
											if(unifBroadLuts.containsKey(sbox))									/// <li> if the unifiable has the same lut
												if(!matcher.getLuts().get(sbox)
														.equals(unifBroadLuts.get(sbox))) {						/// <b>and</b> if the related values are not equal
													isNotUnifiable = true;
													break;														/// <b> the broadcast is not unifiable </b>
												}
										}
										
										if(!isNotUnifiable) {
											
											// update bufferSize parameter (worst case)
											if(hasBufferSize(otherCandidate)) {
												if(hasBufferSize(otherUnifiable)) {
													if(getBufferSizeIntegerValue(otherCandidate) > getBufferSizeIntegerValue(otherUnifiable)) {
														unifiableBufferSize.put(otherUnifiable,getBufferSizeValue(otherCandidate));
													}
												} else {
													unifiableBufferSize.put(otherUnifiable,getBufferSizeValue(otherCandidate));
												}
											}
											unifiableBroadcast.put(otherCandidate, otherUnifiable);				/// <li> add the other unifiable </ol>  </ol>
											unifBroadLuts.putAll(matcher.getLuts());	
										}
										matcher.deleteLuts();
										isNotUnifiable = false;
								} else {
									unifiableBroadcast= new HashMap<Connection,Connection>();
									unifiableBufferSize = new HashMap<Connection,EObject>();
									break;
								}
							}
						}
						if(unifiableBroadcast.size()<=1) {
							matcher.deleteLuts();
						} else {
								connectionsMap.putAll(unifiableBroadcast);
								sboxLutManager.addLutsExistingSboxes(unifBroadLuts, currentNetwork, ALL_SECTIONS);
								for(Connection toBeUpdated : unifiableBufferSize.keySet()) {
									toBeUpdated.getAttribute("bufferSize").setEObjectValue(unifiableBufferSize.get(toBeUpdated));	// for network editor
									toBeUpdated.getAttribute("bufferSize").setContainedValue(unifiableBufferSize.get(toBeUpdated));	// for platform-composer
								}
								for(Instance sbox : matcher.getLuts().keySet()) {
									networksInstances.get(currentNetwork.getSimpleName()).add(sbox.getLabel());
								}
								matcher.deleteLuts();
						}
					}
				}
			}
		}
				
		/// <li> add new connection(s) to the result network
		for (Connection candidate : candidates) {
			
			if(!connectionsMap.containsKey(candidate)) {				
							
		/// <ol> <li> collision connections that have same source or target than candidate
				Connection collisionSrc = null;
				Connection collisionTgt = null;
						
				boolean sameBroadcast = false;
			
		/// <li> search source collision connections 
				for(Connection connection : multiDataflow.getConnections()) {
				
					if(candidate.hasAttribute("broadcast"))
						if(connection.hasAttribute("broadcast")){
							if(candidate.getAttribute("broadcast").getStringValue().equals(connection.getAttribute("broadcast").getStringValue()))
								if(matcher.matchSourcesMultiple(candidate, connection))
									sameBroadcast = true;	
						}
				
					if(!sameBroadcast)
						if(matcher.matchSourcesMultiple(candidate,connection)){
								collisionSrc = connection;
						}
				}			
				
		/// <li> source collision found: place a 1x2 sbox: placeSbox1x2()
				if(collisionSrc != null){				
				//	if(sboxActorManager.getSboxCount()==6) {
				//		OrccLogger.debugln("1x2 " + candidate + " vs " + collisionSrc);
				//		OrccLogger.debugln("1x2b " + collisionSrc.getAttribute("bufferSize") + " " + collisionSrc.getAttribute("bufferSize").getContainedValue() + " " + collisionSrc.getAttribute("bufferSize").getReferencedValue());

				//	}
					candidate = placeSbox1x2(candidate,collisionSrc);
			//		if(sboxActorManager.getSboxCount()==7) {
			//			OrccLogger.debugln("1x2 " + candidate + " vs " + collisionSrc);
			//		}
					collisionSrc = null;
				}
					
		/// <li> search target collision connections
				for(Connection nextC : multiDataflow.getConnections()){
					if(matcher.matchTargetsMultiple(candidate,nextC)){
							collisionTgt = nextC;
					}
				}
		/// <li> target collision founded: place a  2x1 sbox: placeSbox2x1()
				if(collisionTgt != null){
			//		if(sboxActorManager.getSboxCount()==5) {
				//		OrccLogger.debugln("2x1 " + candidate + " vs " + collisionTgt);
				//	}
					candidate = placeSbox2x1(candidate,collisionTgt);
			//		if(sboxActorManager.getSboxCount()==6) {
			//			OrccLogger.debugln("2x1 " + candidate + " vs " + collisionTgt);
			//			OrccLogger.debugln("2x1b " + collisionTgt.getAttribute("bufferSize") + " " + collisionTgt.getAttribute("bufferSize").getContainedValue() + " " + collisionTgt.getAttribute("bufferSize").getReferencedValue());
			//		}
				}
					
		/// <li> add current candidate connection to the result network: addConnection()
				addConnection(candidate);
			}
			
	  /// </ol> 
		} 
		/// </ul>
	}

	/**
	 * Try to share the given candidate input port with an input
	 * port in the mutli-dataflow network. If no sharable port is 
	 * found, a copy of the candidate is created.
	 * 
	 * @param candidate
	 * 		the candidate input port
	 */
	private void mergeInputPort(Port candidate) {
		/// <ul>
		Port unifiable = null;
		
		/// <li> search a sharable port
		for (Port existing : multiDataflow.getInputs()) {
			if (unifier.canUnify(candidate, existing)){
				unifiable = existing;
				break;
			}
		}
		
		/// <li> if the candidate is not sharable 
		/// <b> a new port is added in the multi-dataflow network </b>
		if (unifiable == null) {
			unifiable = DfFactory.eINSTANCE.createPort(candidate);
			for(Port input : multiDataflow.getInputs())
				if(input.getName().equals(unifiable.getName()))
					unifiable.setName(unifiable.getName() + "_" + currentNetwork.getSimpleName());
		}
		
 
		verticesMap.put(candidate, unifiable);
		multiDataflow.addInput(unifiable);
		/// </ul>
	}

	/**
	 * Combine the current combining network with the multi-dataflow network
	 */
	private void mergeNetwork() {	
		/// <ul>
		//OrccLogger.traceln("mgd net " + currentNetwork.getName());
		
		// instantiate new vertices and connections maps
		verticesMap = new HashMap<Vertex,Vertex> ();
		connectionsMap = new HashMap<Connection,Connection> ();
		
		/// <li> merge inputs: mergeInputPort()
		for (Port candidate : currentNetwork.getInputs()) {
			mergeInputPort(candidate);
		}		
		
		/// <li> merge outputs mergeOutputPort()
		for (Port candidate : currentNetwork.getOutputs()) {
			mergeOutputPort(candidate);
		}
		
		/// <li> merge instances mergeVertex()
		networksInstances.put(currentNetwork.getSimpleName(), new HashSet<String>());		// instantiate a new network instance set
		for (Vertex candidate : currentNetwork.getChildren()){
			mergeVertex(candidate);
		}
		
		Map <String,String> newMap = new HashMap <String,String>();
		for(Vertex vertex : verticesMap.keySet()) {
			newMap.put(vertex.getLabel(),verticesMap.get(vertex).getLabel());
		}
		networkVertexMap.put(currentNetwork.getSimpleName(),newMap);
				
		// assign broadcast attribute to the connections
		assignBroadcastAttribute(currentNetwork);		
	
		// create virtual general root for the Breadth-First Search algorithm
		Port root = DfFactory.eINSTANCE.createPort(null,"root");
		currentNetwork.addInput(root);
		for(Port input : currentNetwork.getInputs()){
			currentNetwork.add(DfFactory.eINSTANCE.createConnection(root, null, input, null));
		}
		
		// run Breadth-First Search algorithm
		BFS bfsSearch = new BFS(root);
	
		// remove virtual general root
		currentNetwork.remove(root);
		currentNetwork.getInputs().remove(root);
		bfsSearch.getVertices().remove(root);
		
		// initialize section number (useful for future works about networks internal reconfiguration)	
		currentSection = 0;	
		
		// instante section list of vertex (useful for future works about networks internal reconfiguration)
		List<Vertex> networkSectionVertices = new ArrayList<Vertex>();	
		
		for(Vertex nextChild : bfsSearch.getVertices()){
			
			// do not analyze input ports
			if(!nextChild.getPredecessors().contains(root)) {					
	
				// list of child vertex predecessors
				List<Vertex> predecessors = nextChild.getPredecessors();	
				
				// add combined child to the network section vertices (useful for future works about networks internal reconfiguration)
				networkSectionVertices.add(nextChild);					
	
				// update section number (useful for future works about networks internal reconfiguration)
				for(Vertex nextPredecessor : predecessors){				
					if(networkSectionVertices.contains(nextPredecessor) 
							&& !nextPredecessor.getPredecessors().contains(nextChild)){
						networkSectionVertices.removeAll(networkSectionVertices);
						currentSection++;
					}
					
					// merge connection(s) between current child and current predecessor
					mergeConnection(nextPredecessor, nextChild);
																				
				}
				
				// add merged child to the network section vertices (useful for future works about networks internal reconfiguration)
				networkSectionVertices.add(nextChild);					
			}
		
		}
		
		// save the number of sections of the network (useful for future works about networks internal reconfiguration)
		sectionMap.put(currentNetwork, currentSection);
	
		// complete sbox LUTs (useful for future works about networks internal reconfiguration)
		sboxLutManager.completeLutsMultiple(sectionMap);
		
		/// </ul>	
	}

	/**
	 * Try to share the given candidate output port with an output
	 * port in the mutli-dataflow network. If no sharable port is 
	 * found, a copy of the candidate is created.
	 * 
	 * @param candidate
	 * 		the candidate output port
	 */
	private void mergeOutputPort(Port candidate) {
		/// <ul>
		Port unifiable = null;
		
		/// <li> search a sharable port
		for (Port existing : multiDataflow.getOutputs()) {
			if (unifier.canUnify(candidate, existing)){
				unifiable = existing;
				break;
			}
		}
		
		/// <li> if the candidate is not sharable <b> a new port is added in the multi-dataflow network	</b>
		if (unifiable == null) {
			unifiable = DfFactory.eINSTANCE.createPort(candidate);
			for(Port output : multiDataflow.getOutputs())
				if(output.getName().equals(unifiable.getName()))
					unifiable.setName(unifiable.getName() + "_" + currentNetwork.getSimpleName());
		}
		verticesMap.put(candidate, unifiable);
		multiDataflow.addOutput(unifiable);
		/// </ul>
	}

	/**
	 * Try to share the given candidate vertex with a vertex in the 
	 * mutli-dataflow network. If no sharable vertex is found, a copy
	 * of the candidate is created.
	 * 
	 * @param candidate
	 * 		the candidate vertex
	 */
	private void mergeVertex(Vertex candidate) {
		/// <ul>
				
		Vertex unifiable = null;
		List<Vertex> unifiables = new ArrayList<Vertex>();
		
		if(!(candidate.getAdapter(Instance.class).hasAttribute("don't merge"))){
		
			/// <li> search all the sharable vertices
			for (Vertex existing : multiDataflow.getChildren()) {
				if (unifier.canUnifyMultiple(candidate, existing) 
						&& !existing.hasAttribute(currentNetwork.getName()) 
						&& !existing.getAdapter(Instance.class).hasAttribute("don't merge")){
					unifiables.add(existing);
				}
			}
			
			/// <li> find best sharable vertex
			if(!unifiables.isEmpty()) {
				if(unifiables.size() != 1) {
					unifiable = searcher.findBestVertex(candidate,unifiables);
				} else {
					unifiable = unifiables.get(0);
				}
				unifiable.setAttribute(currentNetwork.getName(), (Object) null);
				candidate.setAttribute("count", unifiable.getAttribute("count").getObjectValue());
			}
			
		
		}
	
		/// <li> if the candidate is not sharable <b> a new vertex is added in the multi-dataflow network	</b>	
		if (unifiable == null) {
			if(candidate.getAdapter(Port.class) != null){
				unifiable = DfFactory.eINSTANCE.createPort((Port) candidate);
			} else {
				unifiable = IrUtil.copy(candidate.getAdapter(Instance.class));
				actorManager.incrActorCount(((Instance) unifiable).getAdapter(Actor.class));
				actorManager.renameInstance((Instance) unifiable, multiDataflow);
				unifiable.setAttribute(currentNetwork.getName(), (Object) null);
				candidate.setAttribute("count", unifiable.getAttribute("count").getObjectValue());
			}
		}
		multiDataflow.add(unifiable);
		verticesMap.put(candidate, unifiable);
		if(unifiable.getAdapter(Instance.class) != null) {
			networksInstances.get(currentNetwork.getSimpleName()).add(unifiable.getLabel());
			
		}
	/// </ul>
	}

	/**
	 * Place a 1-input 2-outputs sbox due to the conflict between candidate and
	 * collision connections. Return the new candidate connection. 
	 * 
	 * @param candidate
	 * 		the candidate connection
	 * @param collision
	 * 		the collision connection
	 * @return
	 * 		new candidate connection
	 */
	private Connection placeSbox1x2(Connection candidate, Connection collision) {
					
		// create a new sbox instance
		Instance sboxInstance = DfFactory.eINSTANCE.createInstance("sbox_" + sboxActorManager.getSboxCount() , null);
		sboxInstance.setAttribute("count", sboxActorManager.getSboxCount());
		sboxInstance.setAttribute("sbox", "");
		sboxActorManager.incrementSboxCount();
		
		// update sbox lut
		sboxLutManager.setLutValue(sboxInstance, currentNetwork, ALL_SECTIONS);	
		networksInstances.get(currentNetwork.getSimpleName()).add(sboxInstance.getLabel());
		
		// calculate values of the connection between the common source and the sbox
		Port inPort = DfFactory.eINSTANCE.createPort();
		if(collision.getSourcePort()!=null){
			inPort=IrUtil.copy(collision.getSourcePort());
		}else{
			inPort=IrUtil.copy(collision.getSource().getAdapter(Port.class));
		}
		inPort.setName("in1");
		sboxInstance.setEntity(sboxActorManager.getSboxActor1x2(inPort.getType()));
		sboxInstance.getActor().getInputs().add(inPort);

		// create connection between the common source and the sbox
		Connection inConn = DfFactory.eINSTANCE.createConnection(collision.getSource(), 
				collision.getSourcePort(), sboxInstance, sboxInstance.getActor().getInput("in1"));

		// calculate values of the connection between the sbox and the collision connection target
		Port outPort1 =  DfFactory.eINSTANCE.createPort();
		if(collision.getTargetPort()!=null){
			outPort1=IrUtil.copy(collision.getTargetPort());
		}else{
			outPort1=IrUtil.copy(collision.getTarget().getAdapter(Port.class));
		}
		outPort1.setName("out1");
		sboxInstance.getActor().getOutputs().add(outPort1);
			
		// update broadcast attribute
		if(collision.hasAttribute("broadcast")) {
			for(Connection connection : multiDataflow.getConnections()) {
				if(!connection.equals(collision))
					if(matcher.matchSourcesMultiple(connection, collision) && connection.hasAttribute("broadcast")) {
						connection.setSource(sboxInstance);
						connection.setSourcePort(sboxInstance.getActor().getOutput("out1"));
					}
			}
		}
		
		// update collision connection
		collision.setSource(sboxInstance);
		collision.setSourcePort(sboxInstance.getActor().getOutput("out1"));
		
		// calculate values of the connection between the sbox and the candidate connection target
		Port outPort2 =  DfFactory.eINSTANCE.createPort();
		if(candidate.getTargetPort()!=null) {
			outPort2=IrUtil.copy(candidate.getTargetPort());
		} else {
			outPort2=IrUtil.copy(candidate.getTarget().getAdapter(Port.class));
		}
		outPort2.setName("out2");
		sboxInstance.getActor().getOutputs().add(outPort2);
		
		// update broadcast attribute
		if(candidate.hasAttribute("broadcast")) {
			for(Connection connection : currentNetwork.getConnections()) {
				if(matcher.matchSourcesMultiple(connection, candidate) && !matcher.matchTargetsMultiple(connection, candidate)
							&& connection.hasAttribute("broadcast")) {
					connection.setSource(sboxInstance);
					connection.setSourcePort(sboxInstance.getActor().getOutput("out2"));
				}
			}
		}
		
		// update candidate connection
		candidate.setSource(sboxInstance);
		candidate.setSourcePort(sboxInstance.getActor().getOutput("out2"));
		if(verticesMap.get(candidate.getTarget())!=null)
			candidate.setTarget(verticesMap.get(candidate.getTarget()));

		// assign sbox input connection size attribute
		if(!inPort.getType().isBool()){
			Argument arg = DfFactory.eINSTANCE.createArgument(
					IrFactory.eINSTANCE.createVar(IrFactory.eINSTANCE.createTypeInt(32), "SIZE", true, 0), 
					IrFactory.eINSTANCE.createExprInt(inPort.getType().getSizeInBits()));
			sboxInstance.getArguments().add(arg);
		}

		// propagate bufferSize
		if(hasBufferSize(candidate)) {
			if(hasBufferSize(collision)) {
				if(getBufferSizeIntegerValue(candidate) > 
				getBufferSizeIntegerValue(collision)) {
					inConn.setAttribute("bufferSize",getBufferSizeValue(candidate));	// for network editor
					inConn.getAttribute("bufferSize").setContainedValue(getBufferSizeValue(candidate));	// for platform-composer

				} else {
					inConn.setAttribute("bufferSize",getBufferSizeValue(collision));	// for network editor
					inConn.getAttribute("bufferSize").setContainedValue(getBufferSizeValue(collision));	// for platform-composer
				}
			} else {
				inConn.setAttribute("bufferSize",getBufferSizeValue(candidate));	// for network editor
				inConn.getAttribute("bufferSize").setContainedValue(getBufferSizeValue(candidate));	// for platform-composer
			}
		} else {
			if(hasBufferSize(collision)) {
				inConn.setAttribute("bufferSize",getBufferSizeValue(collision));	// for network editor
				inConn.getAttribute("bufferSize").setContainedValue(getBufferSizeValue(collision));	// for platform-composer
			}
		}
//		OrccLogger.debugln("iC " + inConn);
//		OrccLogger.debugln("iC " + inConn.getAttribute("bufferSize") + " C " + inConn.getAttribute("bufferSize").getContainedValue() + " R " + inConn.getAttribute("bufferSize").getReferencedValue());
//		if(inConn.getAttribute("bufferSize").getContainedValue()==null && inConn.getAttribute("bufferSize").getReferencedValue()==null) {
//			OrccLogger.debugln("conn " + inConn);
//		}
		
		// update multi-dataflow network
		multiDataflow.add(sboxInstance);
		addConnection(inConn);
		for (Network mergedNet : mergedNetworks) {
			sboxLutManager.resetLutValue(sboxInstance, mergedNet, ALL_SECTIONS);
			if(leftSearch(mergedNet,sboxInstance)/*||rightSearch(mergedNet,sboxInstance)*/) {
				networksInstances.get(mergedNet.getSimpleName()).add(sboxInstance.getLabel());
			}
		}
		return candidate;
	}

	/**
	 * Place a 2-inputs 1-output sbox due to the conflict between candidate and
	 * collision connections. Return the new candidate connection. 
	 * 
	 * @param candidate
	 * 		the candidate connection
	 * @param collision
	 * 		the collision connection
	 * @return
	 * 		new candidate connection
	 */
	private Connection placeSbox2x1(Connection candidate, Connection collision) {
		
		// create a new sbox instance
		Instance sboxInstance = DfFactory.eINSTANCE.createInstance("sbox_" + sboxActorManager.getSboxCount() , null);
		sboxInstance.setAttribute("count", sboxActorManager.getSboxCount());
		sboxInstance.setAttribute("sbox", "");
		sboxActorManager.incrementSboxCount();
		
		// update sbox lut
		sboxLutManager.setLutValue(sboxInstance, currentNetwork, ALL_SECTIONS);
		networksInstances.get(currentNetwork.getSimpleName()).add(sboxInstance.getLabel());
	
		// calculate values of the connection between the collision connection source and the sbox
		Port inPort1 = DfFactory.eINSTANCE.createPort();
		if(collision.getSourcePort()!=null) {
			inPort1=IrUtil.copy(collision.getSourcePort());
		} else {
			inPort1=IrUtil.copy(collision.getSource().getAdapter(Port.class));
		}
		inPort1.setName("in1");
		sboxInstance.setEntity(sboxActorManager.getSboxActor2x1(inPort1.getType()));
		sboxInstance.getActor().getInputs().add(inPort1);
			
		// calculate values of the connection between the candidate connection source and the sbox
		Port inPort2 = DfFactory.eINSTANCE.createPort();
		if(candidate.getSourcePort()!=null) {
			inPort2=IrUtil.copy(candidate.getSourcePort());
		}else{
			inPort2=IrUtil.copy(candidate.getSource().getAdapter(Port.class));
		}
		inPort2.setName("in2");
		sboxInstance.getActor().getInputs().add(inPort2);
		
		// update candidate connection
		if(verticesMap.get(candidate.getSource())!=null)
			candidate.setSource(verticesMap.get(candidate.getSource()));
		candidate.setTarget(sboxInstance);
		candidate.setTargetPort(sboxInstance.getActor().getInput("in2"));
		
		// calculate values of the connection between the sbox and the collision connection target
		Port outPort = DfFactory.eINSTANCE.createPort();
		if(collision.getTargetPort()!=null) {
			outPort=IrUtil.copy(collision.getTargetPort());
		}else{
			outPort=IrUtil.copy(collision.getTarget().getAdapter(Port.class));
		}
		outPort.setName("out1");
		sboxInstance.getActor().getOutputs().add(outPort);
		
		// create connection between the sbox and the collision connection target
		Connection outConn = DfFactory.eINSTANCE.createConnection(sboxInstance, 
				sboxInstance.getActor().getOutput("out1"), collision.getTarget(), collision.getTargetPort());

		// update collision connection
		collision.setTarget(sboxInstance);
		collision.setTargetPort(sboxInstance.getActor().getInput("in1"));
		
		// assign sbox output connection size attribute
		if(!inPort1.getType().isBool()){
			Argument arg = DfFactory.eINSTANCE.createArgument(
				IrFactory.eINSTANCE.createVar(IrFactory.eINSTANCE.createTypeInt(32), "SIZE", true, 0), 
				IrFactory.eINSTANCE.createExprInt(outPort.getType().getSizeInBits()));
			sboxInstance.getArguments().add(arg);
		}

		// propagate bufferSize
		if(hasBufferSize(candidate)) {
			if(hasBufferSize(collision)) {
				if(getBufferSizeIntegerValue(candidate) > getBufferSizeIntegerValue(collision)) {
					outConn.setAttribute("bufferSize",getBufferSizeValue(candidate));	// for network editor
					outConn.getAttribute("bufferSize").setContainedValue(getBufferSizeValue(candidate));	// for platform-composer
				} else {
					outConn.setAttribute("bufferSize",getBufferSizeValue(collision));	// for network editor
					outConn.getAttribute("bufferSize").setContainedValue(getBufferSizeValue(collision));	// for platform-composer
				}
			} else {
				outConn.setAttribute("bufferSize",getBufferSizeValue(candidate));	// for network editor
				outConn.getAttribute("bufferSize").setContainedValue(getBufferSizeValue(candidate));	// for platform-composer
			}
		} else {
			if(hasBufferSize(collision)) {
				outConn.setAttribute("bufferSize",getBufferSizeValue(collision));	// for network editor
				outConn.getAttribute("bufferSize").setContainedValue(getBufferSizeValue(collision));	// for platform-composer
			}
		}
//		OrccLogger.debugln("oC " + outConn);
//		OrccLogger.debugln("oC " + outConn.getAttribute("bufferSize") + " C " + outConn.getAttribute("bufferSize").getContainedValue() + " R " + outConn.getAttribute("bufferSize").getReferencedValue());
//		if(outConn.getAttribute("bufferSize").getContainedValue()==null && outConn.getAttribute("bufferSize").getReferencedValue()==null) {
//			OrccLogger.debugln("conn " + outConn);
//		}
		
		// update multi-dataflow network
		multiDataflow.add(sboxInstance);
		addConnection(outConn);
		for (Network mergedNet : mergedNetworks) {
			sboxLutManager.resetLutValue(sboxInstance, mergedNet, ALL_SECTIONS);
			if(leftSearch(mergedNet,sboxInstance)/*||rightSearch(mergedNet,sboxInstance)*/) {
				networksInstances.get(mergedNet.getSimpleName()).add(sboxInstance.getLabel());
			}
		}
		return candidate;
	}
	
	/**
	 * Left direction. Search all of the 2x1 and 1x2 sboxes with the same selector.
	 * */
	// ricerca vs sinistra --> tutte le 2x1 e le 1x2 solo se il selettore Ã¨ concorde
	private boolean leftSearch(Network net, Instance sboxInstance) {
		
		Connection in1 = sboxInstance.getIncomingPortMap().get(sboxInstance.getActor().getInput("in1"));
		if(in1.getSource() instanceof Port) {
			
			for(Port inputPort: net.getInputs()){
				if(unifier.canUnify(inputPort,in1.getSource().getAdapter(Port.class))) {
					//System.out.println(inputPort.getName() + " = " + in1.getSource().getAdapter(Port.class).getName());
					return true;
				} else {
					//System.out.println(inputPort.getName() + " != " + in1.getSource().getAdapter(Port.class).getName());
				}
			}
			if(net.getInputs().contains(in1.getSource().getAdapter(Port.class))) {		
				return true;
			}
		} else {
			if(!in1.getSource().getAdapter(Actor.class).hasAttribute("sbox")) {
				if(networksInstances.get(net.getSimpleName()).contains(in1.getSource().getLabel())) {
					return true;
				}
			} else {	// source is sbox
				// source is 2x1 sbox --> no control on LUT
				if(in1.getSource().getAdapter(Actor.class).getAttribute("type").getStringValue().equals("2x1")) {
					if(leftSearch(net,in1.getSource().getAdapter(Instance.class))) {
						return true;
					}
				} else { // source is 1x2 sbox --> control on LUT
					if(in1.getSourcePort().getName().equals("out1") && sboxLutManager.getLut(in1.getSource().getAdapter(Instance.class)).getLutValue(net,0)==false) {
						if(leftSearch(net,in1.getSource().getAdapter(Instance.class))) {
							return true;
						}
					} else if(in1.getSourcePort().getName().equals("out2") && sboxLutManager.getLut(in1.getSource().getAdapter(Instance.class)).getLutValue(net,0)==true) {
						if(leftSearch(net,in1.getSource().getAdapter(Instance.class))) {
							return true;
						}
					}
				}
			}
		}
		
		if(sboxInstance.getAdapter(Actor.class).getAttribute("type").getStringValue().equals("2x1")) {
			Connection in2 = sboxInstance.getIncomingPortMap().get(sboxInstance.getActor().getInput("in2"));
			
			if(in2.getSource() instanceof Port) {
				for(Port inputPort: net.getInputs()){
					if(unifier.canUnify(inputPort,in2.getSource().getAdapter(Port.class))) {
						//System.out.println(inputPort.getName() + " = " + in2.getSource().getAdapter(Port.class).getName());
						return true;
					} else {
						//System.out.println(inputPort.getName() + " != " + in2.getSource().getAdapter(Port.class).getName());
					}
				}
				if(net.getInputs().contains(in2.getSource().getAdapter(Port.class))) {
					return true;
				}
			} else {
				if(!in2.getSource().getAdapter(Actor.class).hasAttribute("sbox")) {
					if(networksInstances.get(net.getSimpleName()).contains(in2.getSource().getLabel())) {
						return true;
					}
				} else { // source is sbox
					if(in2.getSource().getAdapter(Actor.class).getAttribute("type").getStringValue().equals("2x1")) {
						if(leftSearch(net,in2.getSource().getAdapter(Instance.class))) {
							return true;
						}
					} else { // source is 1x2 sbox --> control on LUT
						if(in2.getSourcePort().getName().equals("out1") && sboxLutManager.getLut(in2.getSource().getAdapter(Instance.class)).getLutValue(net,0)==false) {
							if(leftSearch(net,in2.getSource().getAdapter(Instance.class))) {
								return true;
							}
						} else if(in2.getSourcePort().getName().equals("out2") && sboxLutManager.getLut(in2.getSource().getAdapter(Instance.class)).getLutValue(net,0)==true) {
							if(leftSearch(net,in2.getSource().getAdapter(Instance.class))) {
								return true;
							}
						}
					}
				}
			}
		}
		return false;
	}

	/**
	 * Right direction. Search all of the 2x1 and 1x2 sboxes with the same selector.
	 * */
	@SuppressWarnings("unused")
	@Deprecated
	private boolean rightSearch(Network net, Instance sboxInstance) {
		System.out.println("net instances: " + net.getAllActors());
				
		System.out.println("Rightsearch: mergednet " + net + "  sboxInstance " + sboxInstance);
		
		System.out.println(sboxInstance.getOutgoingPortMap().get(sboxInstance.getActor().getOutput("out1")));
		
		for(Connection out1 : sboxInstance.getOutgoingPortMap().get(sboxInstance.getActor().getOutput("out1"))){
			System.out.println("out1.getTarget(): " + out1.getTarget() );
			
			if(out1.getTarget() instanceof Port) {
				if(net.getOutputs().contains(out1.getTarget().getAdapter(Port.class))) {
					System.out.println(net.getName() + " contains " + (out1.getTarget().getAdapter(Port.class)));
					System.out.println("return true");
					return true;
				}
			} else {
				if(!out1.getTarget().getAdapter(Actor.class).hasAttribute("sbox")) {
					if(networksInstances.get(net.getSimpleName()).contains(out1.getTarget().getLabel())) {
						System.out.println("return true");
						return true;
					}
				} else {	// source is sbox
					// target is 1x2 sbox --> no control on LUT
					if(out1.getTarget().getAdapter(Actor.class).getAttribute("type").getStringValue().equals("1x2")) {
						System.out.println("out1.gettarget is " + out1.getTarget().getAdapter(Actor.class).getAttribute("type").getStringValue());
						if(rightSearch(net,out1.getTarget().getAdapter(Instance.class))) {
							System.out.println("return true");
							return true;
						}
					} else { // target is 2x1 sbox --> control on LUT						
						if(out1.getTargetPort().getName().equals("in1") && sboxLutManager.getLut(out1.getTarget().getAdapter(Instance.class)).getLutValue(net,0)==false) {
							System.out.println("out1.getTargetPort().getName().equals(in1) & lut false");
							if(rightSearch(net,out1.getTarget().getAdapter(Instance.class))) {
								System.out.println("return true");
								return true;
							}
						} else if(out1.getTargetPort().getName().equals("in2") && sboxLutManager.getLut(out1.getTarget().getAdapter(Instance.class)).getLutValue(net,0)==true) {
							System.out.println("out1.getTargetPort().getName().equals(in2) & lut true");
							if(rightSearch(net,out1.getTarget().getAdapter(Instance.class))) {
								System.out.println("return true");
								return true;
							}
						}
					}
				}
			}
		}
		
		if(sboxInstance.getAdapter(Actor.class).getAttribute("type").getStringValue().equals("1x2")) {
			
			System.out.println(sboxInstance.getOutgoingPortMap().get(sboxInstance.getActor().getOutput("out2")));
									
			for(Connection out2 : sboxInstance.getOutgoingPortMap().get(sboxInstance.getActor().getOutput("out2"))){
				System.out.println("out2.getTarget(): " + out2.getTarget());
				System.out.println("out2: " + out2);
				
				if(out2.getTarget() instanceof Port) {
					if(net.getOutputs().contains(out2.getTarget().getAdapter(Port.class))) {
						System.out.println(net.getName() + " contains " + (out2.getTarget().getAdapter(Port.class)));
						System.out.println("return true");
						return true;
					}
				} else {
					if(!out2.getTarget().getAdapter(Actor.class).hasAttribute("sbox")) {
						if(networksInstances.get(net.getSimpleName()).contains(out2.getTarget().getLabel())) {
							System.out.println(net.getName() + " contains " + out2.getTarget().getLabel());
							System.out.println("return true");
							return true;
						}
					} else {	// source is sbox
						// target is 1x2 sbox --> no control on LUT
						if(out2.getTarget().getAdapter(Actor.class).getAttribute("type").getStringValue().equals("1x2")) {
							System.out.println("out2.gettarget is " + out2.getTarget().getAdapter(Actor.class).getAttribute("type").getStringValue());
							if(rightSearch(net,out2.getTarget().getAdapter(Instance.class))) {
								System.out.println("return true");
								return true;
							}
						} else { // target is 2x1 sbox --> control on LUT
							if(out2.getTargetPort().getName().equals("in1") && sboxLutManager.getLut(out2.getTarget().getAdapter(Instance.class)).getLutValue(net,0)==false) {
								System.out.println("out2.getTargetPort().getName().equals(in1) & lut false");
								if(rightSearch(net,out2.getTarget().getAdapter(Instance.class))) {
									System.out.println("return true");
									return true;
								}
							} else if(out2.getTargetPort().getName().equals("in2") && sboxLutManager.getLut(out2.getTarget().getAdapter(Instance.class)).getLutValue(net,0)==true) {
								System.out.println("out2.getTargetPort().getName().equals(in2) & lut true");
								if(rightSearch(net,out2.getTarget().getAdapter(Instance.class))) {
									System.out.println("return true");
									return true;
								}
							}
						}
					}
				}
			}
		}
		System.out.println("return false");
		return false;
	}


}
