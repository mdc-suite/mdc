package it.unica.diee.mdc.merging;

import static it.unica.diee.mdc.sboxManagement.SboxLutManager.ALL_SECTIONS;
import it.unica.diee.mdc.sboxManagement.SboxActorManager;
import it.unica.diee.mdc.sboxManagement.SboxLut;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;

import dfg.DfgEdge;
import dfg.DfgFactory;
import dfg.DfgGraph;
import dfg.DfgVertex;
import net.sf.orcc.df.Actor;
import net.sf.orcc.df.Argument;
import net.sf.orcc.df.Connection;
import net.sf.orcc.df.DfFactory;
import net.sf.orcc.df.Instance;
import net.sf.orcc.df.Network;
import net.sf.orcc.df.Port;
import net.sf.orcc.graph.Vertex;
import net.sf.orcc.ir.IrFactory;
import net.sf.orcc.ir.util.IrUtil;
import net.sf.orcc.util.OrccLogger;

/**
 * Class able to merge a set of dataflow networks by sharing the
 * common actors and placing switching modules (SBoxes) in order 
 * to properly forward tokens such as the @multiDataflowNetwork 
 * implements all the merged dataflows.
 * The implemented merging algorithm is the Moreano's Heuristic.
 * 
 * @author csau
 *
 */
public class MoreanoMerger extends Merger {
	
	
	
	////////////////////////////////////////////////////////////////////////////////////////////////

	/**
	 * Current merged dataflow network
	 */
	private Network currentDataflowNetwork;


	/**
	 * Resulting multi-dataflow network
	 */
	private Network multiDataflowNetwork;

	/**
	 * SBox actor manager instance
	 */
	private SboxActorManager sboxActorManager;
	
	/**
	 * Inputs incremental counter
	 */
	private int inputCount;
	/**
	 * Outputs incremental counter
	 */
	private int outputCount;
	
	/**
	 * Map of the connection mapping of each merged network
	 * within the multi-dataflow one.
	 */
	private Map <String,Map<Connection,Connection>> networkConnectionMap;

	/**
	 * Map of the connection mapping of each merged network
	 * within the multi-dataflow one.
	 */
	private Map <String,List<String>> networkSboxMap;
	
	/**
	 * Compatibility graph for the Moreano's heuristic algorithm
	 */
	DfgGraph compatibilityGraph;

	/**
	 * Labeler instance
	 */
	Labeler labeler;
	
	////////////////////////////////////////////////////////////////////////////////////////////////

	/**
	 * The constructor
	 */
	public MoreanoMerger() {

		compatibilityGraph = DfgFactory.eINSTANCE.createDfgGraph();
		labeler = new Labeler();
		inputCount = 0;
		outputCount = 0;
		sboxActorManager = new SboxActorManager();
		networkConnectionMap = new HashMap <String,Map<Connection,Connection>>();
		networkSboxMap = new HashMap <String,List<String>>();

	}
	
	/**
	 * Verify if the given vertices of the compatibility graph are compatible
	 *  
	 * @param v1 the first vertex
	 * @param v2 the second vertex
	 * @return
	 */
	private boolean areCompatible(DfgVertex v1, DfgVertex v2) {

		// retrieve the nodes mappings
		@SuppressWarnings("unchecked")
		Map<String,Connection> m1 = (Map<String, Connection>) v1.getMappings();
		@SuppressWarnings("unchecked")
		Map<String,Connection> m2 = (Map<String, Connection>) v2.getMappings();

		
		if((m1.get(currentDataflowNetwork.getSimpleName()).getSource() ==
				m2.get(currentDataflowNetwork.getSimpleName()).getSource()) &&
				(m1.get(multiDataflowNetwork.getSimpleName()).getSource() !=
				m2.get(multiDataflowNetwork.getSimpleName()).getSource())) {
			// the sources of network 1 connections are the same
			//if(m1.get(currentDataflowNetwork.getSimpleName()).getSourcePort() == 
			//		m2.get(currentDataflowNetwork.getSimpleName()).getSourcePort()) {
				// the source ports of network 1 connections are the same
				return false;
			//}
		} else if((m1.get(currentDataflowNetwork.getSimpleName()).getTarget() ==
				m2.get(currentDataflowNetwork.getSimpleName()).getTarget()) &&
				(m1.get(multiDataflowNetwork.getSimpleName()).getTarget() !=
				m2.get(multiDataflowNetwork.getSimpleName()).getTarget())) {
			// the targets of network 1 connections are the same
			//if(m1.get(currentDataflowNetwork.getSimpleName()).getTargetPort() == 
			//		m2.get(currentDataflowNetwork.getSimpleName()).getTargetPort()) {
				// the target ports of network 1 connections are the same
				return false;
			//}
		} else if((m1.get(currentDataflowNetwork.getSimpleName()).getSource() !=
				m2.get(currentDataflowNetwork.getSimpleName()).getSource()) &&
				(m1.get(multiDataflowNetwork.getSimpleName()).getSource() ==
				m2.get(multiDataflowNetwork.getSimpleName()).getSource())) {
			// the sources of network 1 connections are the same
			//if(m1.get(multiDataflowNetwork.getSimpleName()).getSourcePort() == 
			//		m2.get(multiDataflowNetwork.getSimpleName()).getSourcePort()) {
				// the source ports of network 1 connections are the same
				return false;
			//}
		} else if((m1.get(currentDataflowNetwork.getSimpleName()).getTarget() !=
				m2.get(currentDataflowNetwork.getSimpleName()).getTarget()) &&
				(m1.get(multiDataflowNetwork.getSimpleName()).getTarget() ==
				m2.get(multiDataflowNetwork.getSimpleName()).getTarget())) {
			// the targets of network 1 connections are the same
			//if(m1.get(multiDataflowNetwork.getSimpleName()).getTargetPort() == 
			//		m2.get(multiDataflowNetwork.getSimpleName()).getTargetPort()) {
				// the target ports of network 1 connections are the same
				return false;
			//}
		} else if((m1.get(currentDataflowNetwork.getSimpleName()).getSource() ==
				m2.get(currentDataflowNetwork.getSimpleName()).getTarget()) &&
				(m1.get(multiDataflowNetwork.getSimpleName()).getSource() !=
				m2.get(multiDataflowNetwork.getSimpleName()).getTarget())) {
			// source and target of network 1 connections are the same and the network 2 ones are not the same
			return false;
		} else if((m1.get(currentDataflowNetwork.getSimpleName()).getSource() !=
				m2.get(currentDataflowNetwork.getSimpleName()).getTarget()) &&
				(m1.get(multiDataflowNetwork.getSimpleName()).getSource() ==
				m2.get(multiDataflowNetwork.getSimpleName()).getTarget())) {
			// source and target of network 2 connections are the same and the network 1 ones are not the same
			return false;
		} else if((m1.get(currentDataflowNetwork.getSimpleName()).getTarget() ==
				m2.get(currentDataflowNetwork.getSimpleName()).getSource()) &&
				(m1.get(multiDataflowNetwork.getSimpleName()).getTarget() !=
				m2.get(multiDataflowNetwork.getSimpleName()).getSource())) {
			// source and target of network 1 connections are the same and the network 2 ones are not the same
			return false;
		} else if((m1.get(currentDataflowNetwork.getSimpleName()).getTarget() !=
				m2.get(currentDataflowNetwork.getSimpleName()).getSource()) &&
				(m1.get(multiDataflowNetwork.getSimpleName()).getTarget() ==
				m2.get(multiDataflowNetwork.getSimpleName()).getSource())) {
			// source and target of network 2 connections are the same and the network 1 ones- are not the same
			return false;
		} 

		return true;
	}
	
	/**
	 * Verify if two connections are broadcast connections that can be mapped together
	 * 
	 * @param c1 a connection of the current dataflow network
	 * @param c2 a connection of the multi dataflow network
	 * @return
	 */
	private boolean areMapableBroadcasts(Connection c1, Connection c2) {

		// if only one of the two connections is broadcast return false
		if( (c1.hasAttribute("broadcast") && !c2.hasAttribute("broadcast")) ||
				(!c1.hasAttribute("broadcast") && c2.hasAttribute("broadcast")) )  {
			return false;
		}
		
		// id the broadcasts related to the connections have different sizes return false
		if(!c1.getAttribute("broadcastSize").getStringValue().equals(c2.getAttribute("broadcastSize").getStringValue())) {
			return false;
		}

		// initialize the list of connections 
		List<Connection> multiDataflowConnections = new ArrayList<Connection>();
		multiDataflowConnections.addAll(multiDataflowNetwork.getConnections());
		Connection removableConnection = null;

		// iterate on the current dataflow network connections
		for(Connection oc1 : currentDataflowNetwork.getConnections()) {
			if( oc1.hasAttribute("broadcast") && !oc1.equals(c1) ) {
				Label ol1_src = labeler.getLabel(oc1.getSource(), oc1.getSourcePort());
				Label l1_src = labeler.getLabel(c1.getSource(), c1.getSourcePort());
				Label ol1_tgt = labeler.getLabel(oc1.getTarget(), oc1.getTargetPort());
				boolean isMapable = false;
				if(ol1_src.equals(l1_src)) {	// the current dataflow connection belongs to the same broadcast of c1
					for(Connection oc2 : multiDataflowConnections) {
						if( oc2.hasAttribute("broadcast") && !oc2.equals(c2) ) {
							Label ol2_src = labeler.getLabel(oc2.getSource(), oc2.getSourcePort());
							Label l2_src = labeler.getLabel(c2.getSource(), c2.getSourcePort());
							Label ol2_tgt = labeler.getLabel(oc2.getTarget(), oc2.getTargetPort());
							if(ol2_src.equals(l2_src)) {	// the multi dataflow connection belongs to the same broadcast of c2
								if(ol2_src.equals(ol1_src) && ol2_tgt.equals(ol1_tgt)) {	// one of the broadcasts connections can be mapped
									isMapable = true;
									removableConnection = oc2;
									break;
								}
							}
						}
					}
					// if not all the broadcasts connections can be mapped return false
					if(!isMapable) {	
						return false;
					} else {
						// if the broadcast connection matches remove it from the current dataflow connections
						multiDataflowConnections.remove(removableConnection);
					}
				}
			}

		}

		return true;
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

			if(!connection.hasAttribute("broadcast"))
				for(Connection otherConnection : network.getConnections())
					if(!connection.equals(otherConnection))
						if(connection.getSource().equals(otherConnection.getSource())){
							if((connection.getSourcePort() != null) && 
									(otherConnection.getSourcePort() != null)) {		// source is an instance
								if(connection.getSourcePort().equals(otherConnection.getSourcePort())) {
									// connection is broadcast, assigning attribute and setting flag
									otherConnection.setAttribute("broadcast", network.getName());
									broadcastSize++;
									isBroadcast = true;
								}

							} else {	// source is an input port
								// connection is broadcast, assign attribute and set flag
								otherConnection.setAttribute("broadcast", network.getName());
								broadcastSize++;
								isBroadcast = true;
							}
						}

			if(isBroadcast){
				// assign attribute to the referenced connection
				broadcastSize++;
				connection.setAttribute("broadcast", network.getName());
				connection.setAttribute("broadcastSize", String.valueOf(broadcastSize));
				for(Connection otherConnection : network.getConnections())
					if(!connection.equals(otherConnection))
						if(connection.getSource().equals(otherConnection.getSource())){
							if((connection.getSourcePort() != null) && 
									(otherConnection.getSourcePort() != null)) {	// source is an instance
								if(connection.getSourcePort().equals(otherConnection.getSourcePort())) {
									// connection is broadcast, assign attribute and set flag
									otherConnection.setAttribute("broadcastSize", String.valueOf(broadcastSize));
								}

							} else {	// source is an input port
								// connection is broadcast, assign attribute and set flag
								otherConnection.setAttribute("broadcastSize", String.valueOf(broadcastSize));
							}
						}
				broadcastSize = 0;
			}
		}
	}


	/**
	 * Build a new multi dataflow network by merging the current dataflow network
	 * with the previous multi dataflow one, basing on the clique found by the 
	 * Moreano's heuristic on the compatibility graph.
	 * 
	 * @param maxClique the maximum clique found by Moreano's heuristic
	 */
	@SuppressWarnings("unchecked")
	private void buildMultiDataflow(Set<DfgVertex> maxClique) {

		//OrccLogger.traceln("merging net " + currentDataflowNetwork.getLabel());

		// initialize the current dataflow network vertex and connection mappings
		Map<String,String> vertexMap = new HashMap<String,String>();
		Map<Connection,Connection> connectionMap = new HashMap<Connection,Connection>();
		
		// initialize the not shared connection set
		Set<Connection> notSharedConnections = new HashSet<Connection>();
		
		// find not shared connections of current dataflow network
		for(Connection connection : currentDataflowNetwork.getConnections()) {
			if(!isSharedConnection(connection,maxClique)) {
				notSharedConnections.add(connection);
			}
		}
		//OrccLogger.traceln("non sh conns " + notSharedConnections);
		
		// add shared vertices to multi dataflow
		for(DfgVertex dfgVertex : maxClique) {
			Map<String,Connection> mappings = (Map<String, Connection>) dfgVertex.getMappings();
			Connection mappedConnection = mappings.get(multiDataflowNetwork.getSimpleName());
			Connection connection = mappings.get(currentDataflowNetwork.getSimpleName());
			Vertex mappedSource = mappedConnection.getSource();
			Vertex mappedTarget = mappedConnection.getTarget();
			Vertex source = connection.getSource();
			Vertex target = connection.getTarget();
			
			// assign shared attribute
			if(!mappedConnection.hasAttribute("shared")) {
				OrccLogger.traceln("\t shared " + mappedConnection + " to " + connection);
				mappedConnection.setAttribute("shared", "2");
			} else {
				String newValue = String.valueOf(Integer.parseInt(mappedConnection.getAttribute("shared").getStringValue()) + 1);
				mappedConnection.setAttribute("shared",newValue);
				OrccLogger.traceln("\t shared " + mappedConnection + " to " + connection);
			}
			
			if(!mappedSource.hasAttribute("shared")) {
				mappedSource.setAttribute("shared", "2");
			} else {
				String newValue = String.valueOf(Integer.parseInt(mappedSource.getAttribute("shared").getStringValue()) + 1);
				mappedSource.setAttribute("shared",newValue);
			}
			
			if(!mappedTarget.hasAttribute("shared")) {
				mappedTarget.setAttribute("shared", "2");
			} else {
				String newValue = String.valueOf(Integer.parseInt(mappedTarget.getAttribute("shared").getStringValue()) + 1);
				mappedTarget.setAttribute("shared",newValue);
			}
			
			// update current dataflow network vertex mapping
			if(!vertexMap.containsKey(source.getLabel())) {
				vertexMap.put(source.getLabel(),mappedSource.getLabel());
			}
			if(!vertexMap.containsKey(target.getLabel())) {
				vertexMap.put(target.getLabel(),mappedTarget.getLabel());
			}
			
			// update current dataflow network vertex mapping
			connectionMap.put(connection, mappedConnection);
		}

		// assign a mapping to the vertices that do not share connections
		mapNotSharingConnectionVertices(vertexMap);
				
		// add not shared vertices and connections on multi-dataflow network
		for(Connection connection : notSharedConnections) {
			OrccLogger.traceln("notsh c " + connection);
			Vertex source = connection.getSource();
			Vertex target = connection.getTarget();
			Port sourcePort = connection.getSourcePort();
			Port targetPort = connection.getTargetPort();
			
			Vertex mappedSource = null;
			Port mappedSourcePort = null;
			Vertex mappedTarget = null;
			Port mappedTargetPort = null;
			
			// add source vertex to the multi dataflow network
			if(!vertexMap.containsKey(source.getLabel())) {	// source has not been already mapped in the multi dataflow network
				if(source instanceof Port) {	// source is an input port
					mappedSource = DfFactory.eINSTANCE.createPort(source.getAdapter(Port.class));
					// TODO removed to share inputs by name for fair comparison with EmpiricMerger
					/*mappedSource.setLabel("input_" + inputCount);
					inputCount++;*/
					multiDataflowNetwork.addInput((Port)mappedSource);
				} else {	// source is an actor instance
					Actor sourceActor = source.getAdapter(Actor.class);
					String instanceName = sourceActor.getSimpleName();
					if(sourceActor.hasAttribute("count")) {
						instanceName = instanceName + "_" + sourceActor.getAttribute("count").getStringValue();
						sourceActor.setAttribute("count",String.valueOf((Integer.parseInt(sourceActor.getAttribute("count").getStringValue())+1)));
					} else {
						instanceName = instanceName + "_0";
						sourceActor.setAttribute("count","1");
					}
					mappedSource = IrUtil.copy(source);
					mappedSource.setLabel(instanceName);
					//mappedSourcePort = DfFactory.eINSTANCE.createPort(sourcePort);
					mappedSourcePort = mappedSource.getAdapter(Actor.class).getOutput(sourcePort.getName());
					//mappedSource.getAdapter(Actor.class).getOutputs().remove(sourcePort);
					//mappedSource.getAdapter(Actor.class).getOutputs().add(mappedSourcePort);
					multiDataflowNetwork.add(mappedSource);
				}
				vertexMap.put(source.getLabel(),mappedSource.getLabel());
			} else {	// source has been already mapped in the multi dataflow network
				mappedSource = multiDataflowNetwork.getVertex(vertexMap.get(source.getLabel()));		
				if(!(source instanceof Port)) {
					mappedSourcePort = mappedSource.getAdapter(Actor.class).getOutput(sourcePort.getName());
				} 
			}
			
			// add target vertex to the multi dataflow network
			if(!vertexMap.containsKey(target.getLabel())) {	// target has not been already mapped in the multi dataflow network
				if(target instanceof Port) {	// target is an output port
					mappedTarget = DfFactory.eINSTANCE.createPort(target.getAdapter(Port.class));
					// TODO removed to share outputs by name for fair comparison with EmpiricMerger
					/*mappedTarget.setLabel("output_" + outputCount);
					outputCount++;*/
					multiDataflowNetwork.addOutput((Port)mappedTarget);
				} else {	// target is an actor instance
					Actor targetActor = target.getAdapter(Actor.class);
					String instanceName = targetActor.getSimpleName();
					if(targetActor.hasAttribute("count")) {
						instanceName = instanceName + "_" + targetActor.getAttribute("count").getStringValue();
						targetActor.setAttribute("count",String.valueOf((Integer.parseInt(targetActor.getAttribute("count").getStringValue())+1)));
					} else {
						instanceName = instanceName + "_0";
						targetActor.setAttribute("count","1");
					}
					mappedTarget = IrUtil.copy(target);
					mappedTarget.setLabel(instanceName);
					//mappedTargetPort = DfFactory.eINSTANCE.createPort(targetPort);
					mappedTargetPort = mappedTarget.getAdapter(Actor.class).getInput(targetPort.getName());
					//mappedTarget.getAdapter(Actor.class).getInputs().remove(targetPort);
					//mappedTarget.getAdapter(Actor.class).getInputs().add(mappedTargetPort);
					multiDataflowNetwork.add(mappedTarget);
				}
				vertexMap.put(target.getLabel(),mappedTarget.getLabel());
			} else {	// target has been already mapped in the multi dataflow network
				mappedTarget = multiDataflowNetwork.getVertex(vertexMap.get(target.getLabel()));			
				if(!(target instanceof Port)) {
					mappedTargetPort = mappedTarget.getAdapter(Actor.class).getInput(targetPort.getName());
				}
			}
			
			// add connection to the multi dataflow network
			Connection mappedConnection = DfFactory.eINSTANCE.createConnection(mappedSource, mappedSourcePort, mappedTarget, mappedTargetPort);
			if(connection.hasAttribute("broadcast")) {
				mappedConnection.setAttribute("broadcast", multiDataflowNetwork.getName());
				mappedConnection.setAttribute("broadcastSize", connection.getAttribute("broadcastSize").getStringValue());
			}
			multiDataflowNetwork.add(mappedConnection);
			connectionMap.put(connection, mappedConnection);
			OrccLogger.traceln("added c " + mappedConnection);
		}
		
		// update vertex and connections mappings related to the current dataflow network
		networkVertexMap.put(currentDataflowNetwork.getSimpleName(), vertexMap);
		networkConnectionMap.put(currentDataflowNetwork.getLabel(), connectionMap);
		OrccLogger.traceln("**NET** " + currentDataflowNetwork);
		for(Connection conn : connectionMap.values()) {
			OrccLogger.traceln("\t " + conn);
		}
			
	}

	/**
	 * Map vertex that not share connections (not aligned with Moreano's but fair with
	 * EmpiricMerger)
	 * 
	 * @param vertexMap
	 */
	private void mapNotSharingConnectionVertices(Map<String,String> vertexMap) {

		//OrccLogger.traceln("vmapp " + vertexMap);
		
		for(Vertex vertex : currentDataflowNetwork.getVertices()) {
			if(!vertexMap.containsKey(vertex.getLabel())) {
				for(Vertex mappedVertex : multiDataflowNetwork.getVertices()) {
					if(!vertexMap.containsValue(mappedVertex.getLabel())) {
						if(labeler.getLabel(vertex,null).equals(labeler.getLabel(mappedVertex,null))) {
							mappedVertex.setAttribute("shared", "2");
							vertexMap.put(vertex.getLabel(), mappedVertex.getLabel());
							OrccLogger.traceln("map " + vertex + " to " + mappedVertex);
							break;
						}
					}
				}
			}
		}
		
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
	 * Verify if the current multi dataflow connection is mapped 
	 * within the given compatibility graph clique.
	 * 
	 * @param connection the connection to be verified
	 * @param maxClique	the considered clique
	 * @return
	 */
	@SuppressWarnings("unchecked")
	private boolean isSharedConnection(Connection connection,
			Set<DfgVertex> maxClique) {
		
		// iterate on all the clique vertices
		for (DfgVertex dfgVertex : maxClique) {
			
			// retrieve the vertex mappings
			Map<String,Connection> mappings = (Map<String, Connection>) dfgVertex.getMappings();
			
			// if the current dataflow mapped connection is equal to the given one return true
			Connection mappedConnection = mappings.get(currentDataflowNetwork.getSimpleName());
			if(connection.equals(mappedConnection)) {
				return true;
			}
		}
		return false;
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
	public Network merge(List<Network> mergingNetworks, String path) throws IOException {

		//OrccLogger.traceln("NETWORK MERGER DPN");

		// necessary to configure don't care SBoxes
		Map<Network,Integer> sectionMap = new HashMap<Network,Integer>();
		
		// loop on the input set of networks
		for (Network network : mergingNetworks) {

			//OrccLogger.traceln("\t\t merging loop");
			
			// initialize current dataflow network
			currentDataflowNetwork = network;
			
			// assign broadcasts to current dataflow network
			assignBroadcastAttribute(currentDataflowNetwork);
			
			if(multiDataflowNetwork == null) {	// initialize multi dataflow network
				multiDataflowNetwork = DfFactory.eINSTANCE.createNetwork();
				multiDataflowNetwork.setName("multi_dataflow");
				buildMultiDataflow(new HashSet<DfgVertex>());
			} else {	
				// merge the current dataflow network
				mergeNetwork();
				
				// clear compatibility graph
				compatibilityGraph = DfgFactory.eINSTANCE.createDfgGraph();
			}

			// necessary to configure don't care SBoxes
			sectionMap.put(currentDataflowNetwork, ALL_SECTIONS);
								
		}
		
		// place SBoxes on the multi dataflow network
		placeSboxes(mergingNetworks);
		
		// configure don't care SBoxes to false
		sboxLutManager.completeLutsMultiple(sectionMap);
		
		//OrccLogger.traceln("vmap " + networkVertexMap);
		//OrccLogger.traceln("cmap " + networkConnectionMap);
		//OrccLogger.traceln("smap " + networkSboxMap);		

		return multiDataflowNetwork;
	}

	/**
	 * Merge current dataflow network with the multi dataflow one
	 */
	private void mergeNetwork() {	
	
		//OrccLogger.traceln("\t\t merge network");
	
		// find compatibility graph nodes (feasible mappings)
		for(Connection c1 : currentDataflowNetwork.getConnections()) {
			for(Connection c2 : multiDataflowNetwork.getConnections()) {
				if(labeler.getLabel(c1.getSource(),c1.getSourcePort()).equals(labeler.getLabel(c2.getSource(),c2.getSourcePort()))) {
					if(labeler.getLabel(c1.getTarget(),c1.getTargetPort()).equals(labeler.getLabel(c2.getTarget(),c2.getTargetPort()))) {
						if( ( (c1.getSource().equals(c1.getTarget())) && (c2.getSource().equals(c2.getTarget())) ) ||
								( !(c1.getSource().equals(c1.getTarget())) && !(c2.getSource().equals(c2.getTarget())) ) ) {
							if( !(c1.hasAttribute("broadcast") || c2.hasAttribute("broadcast")) ||
									areMapableBroadcasts(c1,c2)) {
								// insert a node in the compatibility graph
								DfgVertex vertex = DfgFactory.eINSTANCE.createDfgVertex();
								Map<String,Connection> mappings = new HashMap<String,Connection>();
								mappings.put(currentDataflowNetwork.getSimpleName(),c1);
								mappings.put(multiDataflowNetwork.getSimpleName(),c2);
								vertex.setMappings(mappings);
								OrccLogger.traceln("adding vertex " + vertex);
								compatibilityGraph.getVertices().add(vertex);
							}
						}
					}
				}
			}
		}
	
	
		// build compatibility graph connections (compatible feasibile mappings)
		for(DfgVertex vertex1 : compatibilityGraph.getVertices()) {
			for(DfgVertex vertex2 :  compatibilityGraph.getVertices()) {
				if(vertex1 != vertex2 
						&& !vertex1.getNeighbors().contains(vertex2)) {
					if(areCompatible(vertex1,vertex2)) {
						DfgEdge edge = DfgFactory.eINSTANCE.createDfgEdge();
						edge.setVertex1(vertex1);
						edge.setVertex2(vertex2);
						vertex1.getNeighbors().add(vertex2);
						vertex2.getNeighbors().add(vertex1);
						compatibilityGraph.getEdges().add(edge);
					}
				}
			}
		}
	
		//OrccLogger.traceln("v " + compatibilityGraph.getVertices());
		//OrccLogger.traceln("e " + compatibilityGraph.getEdges());
		
		// find maximum clique on compatibility graph
		MaximalCliqueFinder cliquesFinder = new MaximalCliqueFinder(compatibilityGraph);
		Collection <Set<DfgVertex>> maxCliques = cliquesFinder.getBiggestMaximalCliques();
		Set<DfgVertex> maxClique = new HashSet<DfgVertex>();
		if(!maxCliques.isEmpty()) {
			maxClique = maxCliques.iterator().next();
		} else {
			//OrccLogger.traceln("\t\t no clique found");
		}
	
		//OrccLogger.traceln(maxClique);
		
		// build new multi dataflow network
		buildMultiDataflow(maxClique);
	
	}
	
	/**
	 * Place 1x2 SBoxes for a given source colliding connection
	 * 
	 * @param connection the source colliding connection
	 * @param involvedNetworkConnections the connections involved in collision for each network
	 * @return the connections to be added to the multiDataflow
	 */
	private Set<Connection> place1x2sboxes(Connection connection, Map<Network,Set<Connection>> involvedNetworkConnections) {

		for(Network net : involvedNetworkConnections.keySet()) {
			OrccLogger.traceln("net " + net);
			for(Connection conn : involvedNetworkConnections.get(net)) {
				OrccLogger.traceln("\t" + conn);
			}
		}
		
		// set of connections to be added (return object)
		Set<Connection> sbox1x2Connections = new HashSet<Connection>();
		
		// flag indicating if the current sets connections are shared together
		Boolean areShared = false;
		
		// initialize current source for the remaining collision connections
		Vertex source = connection.getSource();
		Port sourcePort = connection.getSourcePort();
		
		// iterator on the networks involved in collision
		Iterator<Network> involvedNetworksIterator = involvedNetworkConnections.keySet().iterator();
		
		// initialize the first set of networks involved in collision
		// it will contain more than one connection if this latter is shared
		Set<Network> firstNetworksSet = new HashSet<Network>();
		firstNetworksSet.add(involvedNetworksIterator.next());
		
		// iterate on networks involved in collision
		while(involvedNetworksIterator.hasNext()) {
			
			// initialize the second set of networks involved in collision
			// it will contain more than one connection if this latter is shared
			Set<Network> secondNetworksSet = new HashSet<Network>();
			secondNetworksSet.add(involvedNetworksIterator.next());

			OrccLogger.traceln("1st net " + firstNetworksSet.iterator().next());
			OrccLogger.traceln("2nd net " + secondNetworksSet.iterator().next());
			
			// if one of the two networks has already been processed skip the placing
			if(!(firstNetworksSet.iterator().next().hasAttribute("processed") ||
					secondNetworksSet.iterator().next().hasAttribute("processed")) ) {
				
				// initialize the sets of connections involved in collision
				Set<Connection> firstNetworkInvolvedConnections = involvedNetworkConnections.get(firstNetworksSet.iterator().next());
				Set<Connection> secondNetworkInvolvedConnections = involvedNetworkConnections.get(secondNetworksSet.iterator().next());
				
				// if first set involves shared connections add related networks to the corresponding networks set
				for(Connection involvedConnection : firstNetworkInvolvedConnections) {
					if(involvedConnection.hasAttribute("shared")) {
						OrccLogger.traceln("1st net conn is shared");
						for(Network network : involvedNetworkConnections.keySet()) {
							if(!firstNetworksSet.contains(network) &&
									involvedNetworkConnections.get(network).equals(firstNetworkInvolvedConnections)) {
								firstNetworksSet.add(network);
								OrccLogger.traceln("added net " + network);
							}
						}
					}
					// if the two sets are shared together set the flag
					if(secondNetworkInvolvedConnections.contains(involvedConnection)) {
						OrccLogger.traceln("are shared");
						areShared = true;
					}
				}
				
				// if second set involves shared connections add related networks to the corresponding networks set
				for(Connection involvedConnection : secondNetworkInvolvedConnections) {
					if(involvedConnection.hasAttribute("shared")) {
						OrccLogger.traceln("2nd net conn is shared");
						for(Network network : involvedNetworkConnections.keySet()) {
							if(!secondNetworksSet.contains(network) &&
									involvedNetworkConnections.get(network).equals(secondNetworkInvolvedConnections)) {
								secondNetworksSet.add(network);
								OrccLogger.traceln("added net " + network);
							}
						}
					}
					// (redundant) if the two sets are shared together set the flag
					if(firstNetworkInvolvedConnections.contains(involvedConnection)) {
						OrccLogger.traceln("are shared");
						areShared = true;
					}
				}
				
				// if the two sets are shared together skip the placing
				if(!areShared) {	// place 1x2 SBox
					
					// create a new SBox instance
					Instance sboxInstance = DfFactory.eINSTANCE.createInstance("sbox_" + sboxActorManager.getSboxCount() , null);
					sboxInstance.setAttribute("count", sboxActorManager.getSboxCount());
					OrccLogger.traceln("add sbox1x2_" + sboxActorManager.getSboxCount());
					sboxInstance.setAttribute("sbox", "");
					sboxActorManager.incrementSboxCount();
					
					// update SBox LUT
					for(Network firstNetwork : firstNetworksSet) {
						sboxLutManager.resetLutValue(sboxInstance, firstNetwork, ALL_SECTIONS);
						if(!networkSboxMap.containsKey(firstNetwork.getSimpleName())) {
							List<String> sboxes = new ArrayList<String>();
							sboxes.add(sboxInstance.getLabel());
							networkSboxMap.put(firstNetwork.getSimpleName(),sboxes);
						} else {
							networkSboxMap.get(firstNetwork.getSimpleName()).add(sboxInstance.getLabel());
						}
					}
					for(Network secondNetwork : secondNetworksSet) {
						sboxLutManager.setLutValue(sboxInstance, secondNetwork, ALL_SECTIONS);
						if(!networkSboxMap.containsKey(secondNetwork.getSimpleName())) {
							List<String> sboxes = new ArrayList<String>();
							sboxes.add(sboxInstance.getLabel());
							networkSboxMap.put(secondNetwork.getSimpleName(),sboxes);
						} else {
							networkSboxMap.get(secondNetwork.getSimpleName()).add(sboxInstance.getLabel());
						}
					}
					for(Network network : involvedNetworkConnections.keySet()) {
						if(!firstNetworksSet.contains(network) && !secondNetworksSet.contains(network)) {
							if(!network.hasAttribute("processed")) {
								sboxLutManager.setLutValue(sboxInstance, network, ALL_SECTIONS);
								if(!networkSboxMap.containsKey(network.getSimpleName())) {
									List<String> sboxes = new ArrayList<String>();
									sboxes.add(sboxInstance.getLabel());
									networkSboxMap.put(network.getSimpleName(),sboxes);
								} else {
									networkSboxMap.get(network.getSimpleName()).add(sboxInstance.getLabel());
								}
							}
						}
					}
					
					// create SBox ports
					Port inPort = DfFactory.eINSTANCE.createPort();
					Port outPort1 = DfFactory.eINSTANCE.createPort();
					Port outPort2 = DfFactory.eINSTANCE.createPort();
					if(sourcePort!=null) {
						inPort=IrUtil.copy(sourcePort);
						outPort1=IrUtil.copy(sourcePort);
						outPort2=IrUtil.copy(sourcePort);
					}else{
						inPort=IrUtil.copy(source.getAdapter(Port.class));
						outPort1=IrUtil.copy(source.getAdapter(Port.class));
						outPort2=IrUtil.copy(source.getAdapter(Port.class));
					}
					inPort.setName("in1");
					outPort1.setName("out1");
					outPort2.setName("out2");
					sboxInstance.setEntity(sboxActorManager.getSboxActor1x2(inPort.getType()));
					sboxInstance.getActor().getInputs().add(inPort);
					sboxInstance.getActor().getOutputs().add(outPort1);
					sboxInstance.getActor().getOutputs().add(outPort2);
					
					// create connection between current source and SBox
					Connection inConn = DfFactory.eINSTANCE.createConnection(source, sourcePort,
							sboxInstance, sboxInstance.getActor().getInput("in1"));
					sbox1x2Connections.add(inConn);
					
					// update current source for SBoxes cascades
					source = sboxInstance;
					sourcePort = outPort2;
					
					// update colliding connections source
					for(Connection involvedConnection : firstNetworkInvolvedConnections) {
						OrccLogger.traceln("1st_nic src change " + involvedConnection + " to " + sboxInstance.getName());
						involvedConnection.setSource(sboxInstance); 
						involvedConnection.setSourcePort(sboxInstance.getActor().getOutput("out1"));
					}
					for(Connection involvedConnection : secondNetworkInvolvedConnections) {
						OrccLogger.traceln("2nd_nic src change " + involvedConnection + " to " + sboxInstance.getName());
						involvedConnection.setSource(sboxInstance);
						involvedConnection.setSourcePort(sboxInstance.getActor().getOutput("out2"));
					}
						
					// assign SBox output connection size attribute
					if(!outPort1.getType().isBool()){
						Argument arg = DfFactory.eINSTANCE.createArgument(
							IrFactory.eINSTANCE.createVar(IrFactory.eINSTANCE.createTypeInt(32), "SIZE", true, 0), 
							IrFactory.eINSTANCE.createExprInt(inPort.getType().getSizeInBits()));
						sboxInstance.getArguments().add(arg);
					}
		
					// add SBox to multiDataflow
					multiDataflowNetwork.add(sboxInstance);
					
					// mark involved networks as processed
					for(Network network : firstNetworksSet) {
						network.setAttribute("processed", "");
					}
					
					// update first networks set
					firstNetworksSet = secondNetworksSet;
				}
				
				// reset flag
				areShared = false;
			}
			
			// if only the first set has been already processed update first set
			if(firstNetworksSet.iterator().next().hasAttribute("processed") &&
					!secondNetworksSet.iterator().next().hasAttribute("processed")) {
				firstNetworksSet = secondNetworksSet;
			}
			
		}
		
		// remove processed mark to the involved networks
		for(Network network : involvedNetworkConnections.keySet()) {
			network.removeAttribute("processed");
		}

		OrccLogger.traceln("add conns: " + sbox1x2Connections);
		
		return sbox1x2Connections;
		
	}
	/**
	 * Place 2x1 SBoxes for a given source colliding connection
	 * 
	 * @param connection the source colliding connection
	 * @param involvedNetworkConnections the connections involved in collision for each network
	 * @return the connections to be added to the multiDataflow
	 */
	private Set<Connection> place2x1sboxes(Connection connection, Map<Network,Set<Connection>> involvedNetworkConnections) {

		for(Network net : involvedNetworkConnections.keySet()) {
			OrccLogger.traceln("net " + net);
			for(Connection conn : involvedNetworkConnections.get(net)) {
				OrccLogger.traceln("\t" + conn);
			}
		}
		
		// set of connections to be added (return object)
		Set<Connection> sbox2x1Connections = new HashSet<Connection>();

		// flag indicating if the current sets connections are shared together
		Boolean areShared = false;

		// initialize current target for the remaining collision connections
		Vertex target = connection.getTarget();
		Port targetPort = connection.getTargetPort();

		// iterator on the networks involved in collision
		Iterator<Network> involvedNetworksIterator = involvedNetworkConnections.keySet().iterator();

		// initialize the first set of networks involved in collision
		// it will contain more than one connection if this latter is shared
		Set<Network> firstNetworksSet = new HashSet<Network>();
		firstNetworksSet.add(involvedNetworksIterator.next());

		// iterate on networks involved in collision
		while(involvedNetworksIterator.hasNext()) {

			// initialize the second set of networks involved in collision
			// it will contain more than one connection if this latter is shared
			Set<Network> secondNetworksSet = new HashSet<Network>();
			secondNetworksSet.add(involvedNetworksIterator.next());

			OrccLogger.traceln("1st net " + firstNetworksSet.iterator().next());
			OrccLogger.traceln("2nd net " + secondNetworksSet.iterator().next());

			// if one of the two networks has already been processed skip the placing
			if(!(firstNetworksSet.iterator().next().hasAttribute("processed") ||
					secondNetworksSet.iterator().next().hasAttribute("processed")) ) {

				// initialize the sets of connections involved in collision
				Set<Connection> firstNetworkInvolvedConnections = involvedNetworkConnections.get(firstNetworksSet.iterator().next());
				Set<Connection> secondNetworkInvolvedConnections = involvedNetworkConnections.get(secondNetworksSet.iterator().next());

				// if first set involves shared connections add related networks to the corresponding networks set
				for(Connection involvedConnection : firstNetworkInvolvedConnections) {
					if(involvedConnection.hasAttribute("shared")) {
						OrccLogger.traceln("1st net conn is shared");
						for(Network network : involvedNetworkConnections.keySet()) {
							if(!firstNetworksSet.contains(network) &&
									involvedNetworkConnections.get(network).equals(firstNetworkInvolvedConnections)) {
								firstNetworksSet.add(network);
								OrccLogger.traceln("added net " + network);
							}
						}
					}
					// if the two sets are shared together set the flag
					if(secondNetworkInvolvedConnections.contains(involvedConnection)) {
						OrccLogger.traceln("are shared");
						areShared = true;
					}
				}
				
				// if second set involves shared connections add related networks to the corresponding networks set
				for(Connection involvedConnection : secondNetworkInvolvedConnections) {
					if(involvedConnection.hasAttribute("shared")) {
						OrccLogger.traceln("2nd net conn is shared");
						for(Network network : involvedNetworkConnections.keySet()) {
							if(!secondNetworksSet.contains(network) &&
									involvedNetworkConnections.get(network).equals(secondNetworkInvolvedConnections)) {
								secondNetworksSet.add(network);
								OrccLogger.traceln("added net " + network);
							}
						}
					}
					// (redundant) if the two sets are shared together set the flag
					if(firstNetworkInvolvedConnections.contains(involvedConnection)) {
						OrccLogger.traceln("are shared");
						areShared = true;
					}
				}

				// if the two sets are shared together skip the placing
				if(!areShared) {	// place 2x1 SBox

					// create a new SBox instance
					Instance sboxInstance = DfFactory.eINSTANCE.createInstance("sbox_" + sboxActorManager.getSboxCount() , null);
					sboxInstance.setAttribute("count", sboxActorManager.getSboxCount());
					OrccLogger.traceln("add sbox2x1_" + sboxActorManager.getSboxCount());
					sboxInstance.setAttribute("sbox", "");
					sboxActorManager.incrementSboxCount();
					
					// update SBox LUT
					for(Network firstNetwork : firstNetworksSet) {
						sboxLutManager.resetLutValue(sboxInstance, firstNetwork, ALL_SECTIONS);	
						if(!networkSboxMap.containsKey(firstNetwork.getSimpleName())) {
							List<String> sboxes = new ArrayList<String>();
							sboxes.add(sboxInstance.getLabel());
							networkSboxMap.put(firstNetwork.getSimpleName(),sboxes);
						} else {
							networkSboxMap.get(firstNetwork.getSimpleName()).add(sboxInstance.getLabel());
						}
					}
					for(Network secondNetwork : secondNetworksSet) {
						sboxLutManager.setLutValue(sboxInstance, secondNetwork, ALL_SECTIONS);
						if(!networkSboxMap.containsKey(secondNetwork.getSimpleName())) {
							List<String> sboxes = new ArrayList<String>();
							sboxes.add(sboxInstance.getLabel());
							networkSboxMap.put(secondNetwork.getSimpleName(),sboxes);
						} else {
							networkSboxMap.get(secondNetwork.getSimpleName()).add(sboxInstance.getLabel());
						}
					}
					for(Network network : involvedNetworkConnections.keySet()) {
						if(!firstNetworksSet.contains(network) && !secondNetworksSet.contains(network)) {
							if(!network.hasAttribute("processed")) {
								sboxLutManager.setLutValue(sboxInstance, network, ALL_SECTIONS);
								if(!networkSboxMap.containsKey(network.getSimpleName())) {
									List<String> sboxes = new ArrayList<String>();
									sboxes.add(sboxInstance.getLabel());
									networkSboxMap.put(network.getSimpleName(),sboxes);
								} else {
									networkSboxMap.get(network.getSimpleName()).add(sboxInstance.getLabel());
								}
							}
						}
					}
					
					// create SBox ports
					Port outPort = DfFactory.eINSTANCE.createPort();
					Port inPort1 = DfFactory.eINSTANCE.createPort();
					Port inPort2 = DfFactory.eINSTANCE.createPort();
					if(targetPort!=null) {
						outPort=IrUtil.copy(targetPort);
						inPort1=IrUtil.copy(targetPort);
						inPort2=IrUtil.copy(targetPort);
					}else{
						outPort=IrUtil.copy(target.getAdapter(Port.class));
						inPort1=IrUtil.copy(target.getAdapter(Port.class));
						inPort2=IrUtil.copy(target.getAdapter(Port.class));
					}
					outPort.setName("out1");
					inPort1.setName("in1");
					inPort2.setName("in2");
					sboxInstance.setEntity(sboxActorManager.getSboxActor2x1(outPort.getType()));
					sboxInstance.getActor().getOutputs().add(outPort);
					sboxInstance.getActor().getInputs().add(inPort1);
					sboxInstance.getActor().getInputs().add(inPort2);

					// create connection between current SBox and target
					Connection outConn = DfFactory.eINSTANCE.createConnection(sboxInstance, 
							sboxInstance.getActor().getOutput("out1"), target, targetPort);
					sbox2x1Connections.add(outConn);

					// update current target for SBoxes cascades
					target = sboxInstance;
					targetPort = inPort2;

					// update colliding connections target
					for(Connection involvedConnection : firstNetworkInvolvedConnections) {
						OrccLogger.traceln("1st_nic tgt change " + involvedConnection + " to " + sboxInstance.getName());
						involvedConnection.setTarget(sboxInstance);
						involvedConnection.setTargetPort(sboxInstance.getActor().getInput("in1"));
					}
					for(Connection involvedConnection : secondNetworkInvolvedConnections) {
						OrccLogger.traceln("2nd_nic tgt change " + involvedConnection + " to " + sboxInstance.getName());
						involvedConnection.setTarget(sboxInstance);
						involvedConnection.setTargetPort(sboxInstance.getActor().getInput("in2"));
					}
						
					// assign SBox output connection size attribute
					if(!inPort1.getType().isBool()){
						Argument arg = DfFactory.eINSTANCE.createArgument(
							IrFactory.eINSTANCE.createVar(IrFactory.eINSTANCE.createTypeInt(32), "SIZE", true, 0), 
							IrFactory.eINSTANCE.createExprInt(outPort.getType().getSizeInBits()));
						sboxInstance.getArguments().add(arg);
					}
					
					// add SBox to multiDataflow
					multiDataflowNetwork.add(sboxInstance);

					// mark involved networks as processed
					for(Network network : firstNetworksSet) {
						network.setAttribute("processed", "");
					}

					// update first networks set
					firstNetworksSet = secondNetworksSet;
				}
				
				// reset flag
				areShared = false;
			}
			
			// if only the first set has been already processed update first set
			if(firstNetworksSet.iterator().next().hasAttribute("processed") &&
					!secondNetworksSet.iterator().next().hasAttribute("processed")) {
				firstNetworksSet = secondNetworksSet;
			}
		}

		// remove processed mark to the involved networks
		for(Network network : involvedNetworkConnections.keySet()) {
			network.removeAttribute("processed");
		}
		
		OrccLogger.traceln("add conns: " + sbox2x1Connections);
		
		return sbox2x1Connections;
		
	}

	/**
	 * Place SBoxes special actors within the multiDataflow
	 * 
	 * @param mergingNetworks
	 */
	private void placeSboxes(List<Network> mergingNetworks) {
		
		// set of connections to be added when a 1x2 SBox is inserted
		Set<Connection> sbox1x2Connections = new HashSet<Connection>();
		
		// set of connections to be added when a 2x1 SBox is inserted
		Set<Connection> sbox2x1Connections = new HashSet<Connection>();
		
		// map of connections involved in the current collision for each network
		Map<Network,Set<Connection>> involvedNetworkConnections = new HashMap<Network,Set<Connection>>();
		
		// iterate on all the connections
		for(Connection connection : multiDataflowNetwork.getConnections()) {

			OrccLogger.traceln("Connection " + connection);
			involvedNetworkConnections = new HashMap<Network,Set<Connection>>();
			
			// if connection is not shared but source and/or target are/is
			// there is a collision and one or more SBoxes have to be placed
			boolean fullySharedConnection = false;
			if(connection.hasAttribute("shared")) {
				if(Integer.parseInt(connection.getAttribute("shared").getStringValue()) == mergingNetworks.size()) {
					fullySharedConnection = true;
				}
			}
			
			if(!fullySharedConnection) {

				OrccLogger.traceln("non shared connection ");
				
				if(connection.getSource().hasAttribute("shared")) {	// source collision
					OrccLogger.traceln("Source collision! " + connection);
					
					// source is an input port
					if(connection.getSource() instanceof Port) {
						//OrccLogger.traceln("port");
						// find connections involved in the current collision for each network
						for(Network network : mergingNetworks) {
							Map<String,String> vertexMap = networkVertexMap.get(network.getSimpleName());
							if(vertexMap.containsValue(connection.getSource().getLabel())) {
								//OrccLogger.traceln("vertexmap " + vertexMap);
								Set<Connection> involvedConnections = new HashSet<Connection>();
								for(Connection networkConnection : network.getConnections()) {
									if((vertexMap.get(networkConnection.getSource().getLabel()).equals(connection.getSource().getLabel()))) {
										involvedConnections.add(networkConnectionMap.get(network.getLabel()).get(networkConnection));
										//OrccLogger.traceln("involved network " + network);
										//OrccLogger.traceln("involved connection " + networkConnection);
									}
								}
								involvedNetworkConnections.put(network, involvedConnections);
							}
						}
						// TODO add support for 1xN SBoxes
						// place 1x2 SBoxes (return new connections to be added)
						//OrccLogger.traceln("all invs " + involvedNetworkConnections);
						sbox1x2Connections.addAll(place1x2sboxes(connection, involvedNetworkConnections));
						
					// source is an actor instance
					} else {
						
						// find connections involved in the current collision for each network
						for(Network network : mergingNetworks) {
							Map<String,String> vertexMap = networkVertexMap.get(network.getSimpleName());
							if(vertexMap.containsValue(connection.getSource().getLabel())) {
								Set<Connection> involvedConnections = new HashSet<Connection>();
								for(Connection networkConnection : network.getConnections()) {
									if((vertexMap.get(networkConnection.getSource().getLabel()).equals(connection.getSource().getLabel())) &&
											(networkConnection.getSourcePort().getType().equals(connection.getSourcePort().getType()) &&
													networkConnection.getSourcePort().getName().equals(connection.getSourcePort().getName()) )) {
										involvedConnections.add(networkConnectionMap.get(network.getLabel()).get(networkConnection));
										//OrccLogger.traceln("involved network " + network);
										//OrccLogger.traceln("involved connection " + networkConnection);
									}
								}
								//OrccLogger.traceln(network + " invs " + involvedConnections);
								involvedNetworkConnections.put(network, involvedConnections);
							}
						}
						// TODO add support for 1xN SBoxes
						// place 1x2 SBoxes (return new connections to be added)
						//OrccLogger.traceln("all invs " + involvedNetworkConnections);
						sbox1x2Connections.addAll(place1x2sboxes(connection, involvedNetworkConnections));
					}
				}

				// empty the involved network connections map
				involvedNetworkConnections = new HashMap<Network,Set<Connection>>();
				
				if(connection.getTarget().hasAttribute("shared")) {	// target collision
					//OrccLogger.traceln("Target collision!");		

					// target is an output port
					if(connection.getTarget() instanceof Port) {

						// find connections involved in the current collision for each network
						for(Network network : mergingNetworks) {
							Map<String,String> vertexMap = networkVertexMap.get(network.getSimpleName());
							if(vertexMap.containsValue(connection.getTarget().getLabel())) {	
								Set<Connection> involvedConnections = new HashSet<Connection>();
								for(Connection networkConnection : network.getConnections()) {
									if((vertexMap.get(networkConnection.getTarget().getLabel()).equals(connection.getTarget().getLabel()))) {
										involvedConnections.add(networkConnectionMap.get(network.getLabel()).get(networkConnection));
										//OrccLogger.traceln("involved network " + network);
										//OrccLogger.traceln("involved connection " + networkConnection);
									}
								}
								involvedNetworkConnections.put(network, involvedConnections);
							}
						}
						// TODO add support for Nx1 SBoxes
						// place 2x1 SBoxes (return new connections to be added)
						//OrccLogger.traceln("all invs " + involvedNetworkConnections);
						sbox2x1Connections.addAll(place2x1sboxes(connection, involvedNetworkConnections));

					// target is an actor instance
					} else {

						// find connections involved in the current collision for each network
						for(Network network : mergingNetworks) {
							Map<String,String> vertexMap = networkVertexMap.get(network.getSimpleName());
							if(vertexMap.containsValue(connection.getTarget().getLabel())) {
								Set<Connection> involvedConnections = new HashSet<Connection>();
								for(Connection networkConnection : network.getConnections()) {
									if((vertexMap.get(networkConnection.getTarget().getLabel()).equals(connection.getTarget().getLabel())) &&
											(networkConnection.getTargetPort().getType().equals(connection.getTargetPort().getType()) && 
													networkConnection.getTargetPort().getName().equals(connection.getTargetPort().getName()) )) {
										involvedConnections.add(networkConnectionMap.get(network.getLabel()).get(networkConnection));
										//OrccLogger.traceln("involved network " + network);
										//OrccLogger.traceln("involved connection " + networkConnection);
									}
								}
								involvedNetworkConnections.put(network, involvedConnections);
							}
						}
						// TODO add support for Nx1 SBoxes
						// place 2x1 SBoxes (return new connections to be added)
						//OrccLogger.traceln("all invs " + involvedNetworkConnections);
						sbox2x1Connections.addAll(place2x1sboxes(connection, involvedNetworkConnections));
					}
				}
			}
		}
		
		// add new connections
		for(Connection connection : sbox1x2Connections) {
			//OrccLogger.traceln("adding 1x2 " + connection);
			multiDataflowNetwork.add(connection);
		}
		for(Connection connection : sbox2x1Connections) {
			//OrccLogger.traceln("adding 2x1 " + connection);
			multiDataflowNetwork.add(connection);
		}
		
	}

	@Override
	public Map<String, Set<String>> getNetworksClkInstances() {
		
		Map<String, Set<String>> networksClkInstances = new HashMap<String, Set<String>>();
		
		for(String network : networkVertexMap.keySet()) {
			Set<String> clkInstances = new HashSet<String>();
			clkInstances.addAll(networkVertexMap.get(network).values());
			networksClkInstances.put(network, clkInstances);
		}
		
		return networksClkInstances;
	}

	@Override
	public Map<String, Set<String>> getNetworksInstances() {
		
		// initialize the map with clock instances (normal actors)
		Map<String, Set<String>> networksInstances = getNetworksClkInstances();
		
		// update the map with sbox instances
		for(String network : networkSboxMap.keySet()) {
			Set<String> instances = networksInstances.get(network);
			instances.addAll(networkSboxMap.get(network));
			networksInstances.put(network, instances);
		}
		
		return networksInstances;
	}


}


